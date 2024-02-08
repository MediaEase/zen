#!/usr/bin/env bash

################################################################################
# @file_name: dependency.sh
# @version: 1
# @project_name: zen
# @description: a library for managing dependencies
#
# @author: Thomas Chauveau (tomcdj71)
# @author_contact: thomas.chauveau.pro@gmail.com
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2024, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# zen::dependency::apt::manage
#
# Manages APT dependencies for the specified software. This function supports a 
# range of actions like install, update, upgrade, check, etc. It reads 
# dependencies from a YAML file and performs the specified action.
#
# Globals:
#   MEDIAEASE_HOME - The root directory for MediaEase configurations.
# Arguments:
#   action - The APT action to perform (install, update, upgrade, check, etc.).
#   software_name - The name of the software whose dependencies are managed.
#   option - Additional options such as 'reinstall', 'non-interactive', 'inline'.
# Outputs:
#   Executes various apt-get commands based on input parameters.
# Returns:
#   The exit status of the last executed apt-get command.
# Notes:
#   This function handles various APT actions and caters to specific use cases
#   like reinstall and non-interactive mode. It uses the 'mflibs::status::error'
#   function for error reporting.
################################################################################
zen::dependency::apt::manage() {
    local dependencies_file="${MEDIAEASE_HOME}/dependencies.yaml"
    local action="$1"
    local software_name="${2:-}"
    local option="$3"
    local cmd_options=""
    local dependencies_string

    # Extracting dependencies from the YAML file
    if [[ -n "$software_name" ]]; then
        dependencies_string=$(yq e ".${software_name}.apt" "$dependencies_file")
        if [[ -z "$dependencies_string" ]]; then
            mflibs::status::error "$(zen::i18n::translate 'dependency.no_dependencies_found' "$software_name")"
            return 1
        fi
    fi

    case "$action" in
        install)
            cmd_options="-yqq --allow-unauthenticated install"
            [[ "$option" == "reinstall" ]] && cmd_options+=" --reinstall"
            ;;
        update|upgrade|check)
            cmd_options="-yqq $action"
            ;;
        *)
            mflibs::status::error "$(zen::i18n::translate 'common.invalid_action' "$action")"
            return 1
            ;;
    esac
    [[ "$option" == "non-interactive" ]] && cmd_options="-o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" $cmd_options"
    [[ "$option" == "inline" ]] && zen::dependency::apt::install::inline "${dependencies_string}" && return

    DEBIAN_FRONTEND=noninteractive apt-get "${cmd_options}" "${dependencies_string}"
    local result=$?
    if [[ "$result" -ne 0 ]]; then
        mflibs::status::error "$(zen::i18n::translate 'dependency.apt_command_failed' "$action")"
        return $result
    fi
    mflibs::status::success "$(zen::i18n::translate 'dependency.apt_command_success' "$action")"
}

################################################################################
# zen::dependency::apt::install::inline
#
# Installs APT dependencies inline, displaying the installation progress for
# each dependency. It uses colored indicators to show the success or failure
# of each installation.
#
# Arguments:
#   A space-separated list of dependencies to install.
# Outputs:
#   Installs each dependency and outputs the dependency name with a colored
#   indicator for installation success or failure.
# Notes:
#   This function leverages zen::dependency::apt::manage for the installation.
#   It uses 'tput' for coloring the output. GREEN and RED color codes are used
#   to indicate success and failure respectively.
################################################################################
zen::dependency::apt::install::inline() {
    local input_string="$*"
    IFS=' ' read -r -a dependencies <<< "$input_string"
    for dep in "${dependencies[@]}"; do
        export DEBIAN_FRONTEND=noninteractive 
        if [[ $(dpkg-query -W -f='${Status}' "${dep}" 2>/dev/null | grep -c "ok installed") != "1" ]]; then
            if mflibs::log "apt-get -yqq install ${dep}"; then
                echo -n -e "$(tput setaf 2)$dep$(tput setaf 7)"
            else
                echo -n -e "$(tput setaf 1)$dep$(tput setaf 7)"
            fi
        fi
    done
}

################################################################################
# zen::dependency::apt::update
#
# Updates the server's package lists and upgrades all installed packages. It
# also performs auto-removal and auto-cleaning of packages.
#
# Globals:
#   None.
# Arguments:
#   None.
# Outputs:
#   Executes apt-get update, upgrade, autoremove, and autoclean commands.
# Notes:
#   The function handles locked dpkg situations by attempting to unlock and
#   reconfigure dpkg. It uses 'mflibs::log' for logging command execution.
################################################################################
zen::dependency::apt::update() {
    mflibs::shell::text::white "$(zen::i18n::translate 'dependency.updating_system')"
    if fuser "/var/lib/dpkg/lock" >/dev/null 2>&1; then
        mflibs::shell::text::yellow "$(zen::i18n::translate 'dependency.dpkg_locked')"
        mflibs::shell::text::yellow "$(zen::i18n::translate 'dependency.dpkg_locked_info')"
        lsof -t /var/lib/apt/lists/lock | xargs kill
        rm -f /var/cache/debconf/{config.dat,passwords.dat,templates.dat}
        rm -f /var/lib/dpkg/updates/0*
        find /var/lib/dpkg/lock* /var/cache/apt/archives/lock* -exec rm -rf {} \;
        mflibs::log "dpkg --configure -a"
    fi
    mflibs::log "apt-get -yqq update"
    mflibs::log "apt-get -yqq upgrade"
    mflibs::log "apt-get -yqq autoremove"
    mflibs::log "apt-get -yqq autoclean"

    if ! apt-get check >/dev/null 2>&1; then
        mflibs::shell::text::red "$(zen::i18n::translate 'dependency.apt_check_failed')"
        quickbox::lock::cleanup
        exit 1
    fi
    mflibs::shell::text::green "$(zen::i18n::translate "dependency.system_updated")"
}

################################################################################
# zen::dependency::apt::remove
#
# Removes APT dependencies associated with a given software if they are no
# longer needed. It checks if the software is the only one using these
# dependencies before removal.
#
# Globals:
#   MEDIAEASE_HOME - The root directory for MediaEase configurations.
# Arguments:
#   software_name - The name of the software whose APT dependencies are to be
#                   removed.
# Outputs:
#   Removes the unused APT dependencies of the specified software.
# Notes:
#   The function reads dependencies from a YAML file and performs removal only
#   if they are not used by other software or essential for MediaEase.
################################################################################
zen::dependency::apt::remove() {
    local software_name="$1"
    local dependencies_file="${MEDIAEASE_HOME}/src/dependencies.yaml"
    local installed_count
    installed_count=$(zen::software::is::installed "$software_name" "*" | wc -l)
    if [[ $installed_count -le 1 ]]; then
        local software_dependencies
        software_dependencies=$(yq e ".${software_name}.apt" "$dependencies_file" 2>/dev/null)
        local zen_dependencies
        zen_dependencies=$(yq e ".mediaease.apt" "$dependencies_file" 2>/dev/null)
        local remove_dependencies
        remove_dependencies=$(comm -23 <(tr ' ' '\n' <<<"$software_dependencies" | sort -u) <(tr ' ' '\n' <<<"$zen_dependencies" | sort -u) | tr '\n' ' ')

        mflibs::log "apt-get remove -y $remove_dependencies"
        mflibs::log "apt-get purge -y $remove_dependencies"
        mflibs::log "apt-get autoremove -y"
        mflibs::log "apt-get autoclean -y"
    fi
}

################################################################################
# zen::dependency::external::build
#
# Installs external dependencies for a specified software based on a YAML
# configuration. It supports custom install commands for each dependency.
#
# Globals:
#   MEDIAEASE_HOME - The root directory for MediaEase configurations.
# Arguments:
#   software_name - The name of the software whose external dependencies are
#                   to be installed.
# Outputs:
#   Executes custom installation commands for external dependencies.
# Returns:
#   0 if all dependencies are installed successfully, 1 otherwise.
# Notes:
#   This function parses a YAML file to get the installation commands for
#   external dependencies. It uses 'eval' for executing these commands.
################################################################################
zen::dependency::external::build() {
    local software_name="$1"
    local dependencies_file="${MEDIAEASE_HOME}/src/dependencies.yaml"
    local external_dependencies
    local install_command

    external_dependencies=$(yq e ".${software_name}.external" "$dependencies_file" 2>/dev/null)
    if [[ -z "$external_dependencies" ]]; then
        mflibs::status::error "$(zen::i18n::translate 'dependency.no_external_dependencies_found' "$software_name")"
        return 1
    fi

    local exit_status=0
    for dependency in $(echo "$external_dependencies" | yq e 'keys[]' -); do
        install_command=$(echo "$external_dependencies" | yq e ".${dependency}.install" -)
        if [[ -n "$install_command" ]]; then
            eval "$install_command"
            local result=$?
            if [[ "$result" -ne 0 ]]; then
                mflibs::status::error "$(zen::i18n::translate 'dependency.external_dependency_install_failed' "$dependency")"
                exit_status=1
            fi
        else
            mflibs::status::error "$(zen::i18n::translate 'dependency.no_install_command_found' "$dependency")"
            exit_status=1
        fi
    done

    return $exit_status
}

################################################################################
# zen::dependency::python::build
#
# Builds and installs Python dependencies for a specified software based on a
# YAML configuration. It uses 'pip' for installing each dependency.
#
# Globals:
#   MEDIAEASE_HOME - The root directory for MediaEase configurations.
# Arguments:
#   software_name - The name of the software whose Python dependencies are to
#                   be installed.
# Outputs:
#   Installs Python packages using pip.
# Returns:
#   0 if all Python dependencies are installed successfully, 1 otherwise.
# Notes:
#   The function extracts Python package names from a YAML file and uses 'pip'
#   for their installation. It handles installation failures for each package.
################################################################################
zen::dependency::python::build(){
    local software_name="$1"
    local dependencies_file="${MEDIAEASE_HOME}/src/dependencies.yaml"
    local python_dependencies

    python_dependencies=$(yq e ".${software_name}.python" "$dependencies_file" 2>/dev/null)
    if [[ -z "$python_dependencies" ]]; then
        mflibs::status::error "$(zen::i18n::translate 'dependency.no_python_dependencies_found' "$software_name")"
        return 1
    fi

    local exit_status=0
    IFS=' ' read -ra DEPS <<< "$python_dependencies"
    for dependency in "${DEPS[@]}"; do
        pip install "$dependency"
        local result=$?
        if [[ "$result" -ne 0 ]]; then
            mflibs::status::error "$(zen::i18n::translate 'dependency.python_dependency_install_failed' "$dependency")"
            exit_status=1
        fi
    done

    return $exit_status
}
