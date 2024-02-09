#!/usr/bin/env bash
# @file modules/dependency.sh
# @project MediaEase
# @version 1.0.0
# @description Contains a library of functions used in the MediaEase Project for managing dependencies.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

################################################################################
# @function zen::dependency::apt::manage
# @description Manages APT dependencies for the specified software.
# @global MEDIAEASE_HOME Path to MediaEase configurations.
# @arg $1 string The APT action to perform (install, update, upgrade, check, etc.).
# @arg $2 string Name of the software for dependency management.
# @arg $3 string Additional options (reinstall, non-interactive, inline).
# @stdout Executes various apt-get commands based on input parameters.
# @return Exit status of the last executed apt-get command.
# @note Handles APT actions, reinstall, and non-interactive mode.
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

# @function zen::dependency::apt::install::inline
# @description Installs APT dependencies inline with progress display.
# @arg $@ string Space-separated list of dependencies to install.
# @stdout Installs dependencies with colored success/failure indicators.
# @note Uses zen::dependency::apt::manage and 'tput' for colored output.
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

# @function zen::dependency::apt::update
# @description Updates package lists and upgrades installed packages.
# @global None.
# @noargs
# @stdout Executes apt-get update, upgrade, autoremove, and autoclean commands.
# @note Handles locked dpkg situations and logs command execution.
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

# @function zen::dependency::apt::remove
# @description Removes APT dependencies not needed by other software.
# @global MEDIAEASE_HOME Path to MediaEase configurations.
# @arg $1 string Name of the software for dependency removal.
# @stdout Removes unused APT dependencies of the specified software.
# @note Reads dependencies from a YAML file; checks for exclusive use.
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

# @function zen::dependency::external::build
# @description Installs external dependencies based on YAML configuration.
# @global MEDIAEASE_HOME Path to MediaEase configurations.
# @arg $1 string Name of the software for external dependency installation.
# @stdout Executes custom installation commands for external dependencies.
# @return 0 if successful, 1 otherwise.
# @note Parses YAML file for installation commands; uses 'eval' for execution.
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

# @function zen::dependency::python::build
# @description Installs Python dependencies based on YAML configuration.
# @global MEDIAEASE_HOME Path to MediaEase configurations.
# @arg $1 string Name of the software for Python dependency installation.
# @stdout Installs Python packages using pip.
# @return 0 if successful, 1 otherwise.
# @note Extracts package names from YAML file; handles installation failures.
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
