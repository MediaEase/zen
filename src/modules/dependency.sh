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
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/dependencies.yaml"
    local action="$1"
    local software_name="${2:-}"
    local option="$3"
    declare -g cmd_options=""
    declare -g dependencies_string

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
            zen::dependency::apt::install::inline "${dependencies_string}" "$cmd_options" && return
            ;;
        update|upgrade|check)
            cmd_options="-yqq $action"
            ;;
        *)
            mflibs::status::error "$(zen::i18n::translate 'common.invalid_action' "$action")"
            return 1
            ;;
    esac
}

# @function zen::dependency::apt::install::inline
# @description Installs APT dependencies inline with progress display.
# @arg $dependencies_string string Space-separated list of dependencies to install.
# @stdout On success, displays the number of installed packages; on failure, shows failed package names.
# @note This function uses apt-get for installation and checks for existing installations with dpkg-query.
#       It provides visual feedback with colored output: red for failures and green for the count of successful installations.
# @example
#   zen::dependency::apt::install::inline "package1 package2 package3"
zen::dependency::apt::install::inline() {
    IFS=' ' read -r -a dependencies <<< "$dependencies_string"
    local dep_install_output
    local failed_deps=()
    local installed_count=0
    mflibs::shell::text::white "$(zen::i18n::translate 'dependency.install_required_dependencies')"
    for dep in "${dependencies[@]}"; do
        if [[ $(dpkg-query -W -f='${Status}' "${dep}" 2>/dev/null | grep -c "ok installed") -ne 1 ]]; then
            # shellcheck disable=SC2154
            if [[ $verbose -eq 1 ]]; then
                mflibs::log "Installing ${dep}..."
                dep_install_output=$(apt-get "${cmd_options}" "${dep}" 2>&1)
                mflibs::log "$dep_install_output"
            else
                echo -n "${dep} | "
                dep_install_output=$(apt-get "${cmd_options}" "${dep}" 2>&1)
            fi
            if [[ $(dpkg-query -W -f='${Status}' "${dep}" 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
                ((installed_count++))
            else
                failed_deps+=("${dep}")
                echo -ne "\033[0;38;5;203m✗ \033[0m"
            fi
        fi
    done
    echo -e "\n\033[0;38;5;34mNumber of packages successfully installed: ${installed_count}\033[0m"
    if [[ ${#failed_deps[@]} -gt 0 ]]; then
        echo -e "\033[0;38;5;208m⚠ Failed to install the following dependencies: ${failed_deps[*]}\033[0m"
    fi
    mflibs::status::success "$(zen::i18n::translate 'dependency.installation_complete')"
}

# @function zen::dependency::apt::update
# @description Updates package lists and upgrades installed packages.
# @global None.
# @noargs
# @stdout Executes apt-get update, upgrade, autoremove, and autoclean commands.
# @note Handles locked dpkg situations and logs command execution.
zen::dependency::apt::update() {
    mflibs::shell::text::white "$(zen::i18n::translate 'dependency.updating_system')"
    # check if fuser is installed 
    if command -v fuser >/dev/null 2>&1; then
        if fuser "/var/lib/dpkg/lock" >/dev/null 2>&1; then
            mflibs::shell::text::yellow "$(zen::i18n::translate 'dependency.dpkg_locked')"
            mflibs::shell::text::yellow "$(zen::i18n::translate 'dependency.dpkg_locked_info')"
            rm -f /var/cache/debconf/{config.dat,passwords.dat,templates.dat}
            rm -f /var/lib/dpkg/updates/0*
            find /var/lib/dpkg/lock* /var/cache/apt/archives/lock* -exec rm -rf {} \;
            mflibs::log "dpkg --configure -a"
        fi
    fi
    mflibs::log "apt-get -yqq update"
    mflibs::log "apt-get -yqq upgrade"
    mflibs::log "apt-get -yqq autoremove"
    mflibs::log "apt-get -yqq autoclean"

    if ! apt-get check >/dev/null 2>&1; then
        mflibs::shell::text::red "$(zen::i18n::translate 'dependency.apt_check_failed')"
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
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/dependencies.yaml"
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

# @function zen::dependency::external::install
# @description Installs all external dependencies for a specified application as defined in the YAML configuration.
# @global MEDIAEASE_HOME Path to MediaEase configurations.
# @arg $1 string The name of the application for which to install external dependencies.
# @stdout Executes custom installation commands for each external dependency of the specified application.
# @note Iterates over the external dependencies for the given application in the YAML file and creates temporary scripts to execute their install commands.
zen::dependency::external::install() {
    local app_name="$1"
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/dependencies.yaml"
    if [[ -z "$app_name" ]]; then
        echo "Application name not specified."
        return 1
    fi
    # Parsing each external dependency
    mflibs::shell::text::white "$(zen::i18n::translate "dependency.installing_external_dependencies" "$app_name")"
    local entries
    entries=$(yq e ".${app_name}.external[] | to_entries[]" "$dependencies_file")
    local software_name install_command
    while IFS= read -r line; do
        if [[ $line == key* ]]; then
            software_name=$(echo "$line" | awk '{print $2}')
        elif [[ $line == value* ]]; then
            install_command=$(yq e ".${app_name}.external[] | select(has(\"$software_name\")) | .${software_name}.install" "$dependencies_file")
            local temp_script="temp_install_$software_name.sh"
            echo "#!/bin/bash" > "$temp_script"
            echo "$install_command" >> "$temp_script"
            chmod +x "$temp_script"
            mflibs::log "./$temp_script"
            local install_status=$?
            rm "$temp_script" 2>/dev/null

            if [[ $install_status -ne 0 ]]; then
                echo "Installation failed for $software_name in $app_name with status $install_status"
                return 1
            fi
        fi
    done <<< "$entries"
    mflibs::status::success "$(zen::i18n::translate "dependency.external_dependencies_installed" "$app_name")"
}

# @function zen::apt::add_source
# @description Adds a new APT source and its GPG key from a YAML configuration.
# @arg $1 string Name of the source as specified in the YAML configuration.
# @global MEDIAEASE_HOME Path to MediaEase configurations.
# @stdout Adds new APT source and GPG key based on the YAML configuration.
# shellcheck disable=SC2155
# Disable SC2155 because if the command fails, it will exit the script.
# @example
#   zen::apt::add_source "php"
zen::apt::add_source() {
    local source_name="$1"
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/apt_sources.yaml"
    
    [[ -z "$source_name" ]] && { echo "Source name is required."; return 1; }

    local source_url_template=$(yq e ".sources.${source_name}.url" "$dependencies_file")
    local source_url=$(eval echo "$source_url_template")
    local arch=$(yq e ".sources.${source_name}.options.arch" "$dependencies_file")
    local include_deb_src=$(yq e ".sources.${source_name}.options.deb-src" "$dependencies_file" | grep -v 'null')
    local gpg_key_url=$(yq e ".sources.${source_name}.options.gpg-key" "$dependencies_file" | grep -v 'null')
    local recv_keys=$(yq e ".sources.${source_name}.options.recv-keys" "$dependencies_file" | grep -v 'null')
    local trusted_key_url=$(yq e ".sources.${source_name}.options.trusted-key" "$dependencies_file" | grep -v 'null')

    [[ -z "$source_url" ]] && { echo "URL for $source_name not found in YAML file."; return 1; }
    [[ -n "$arch" && "$arch" != "null" && "$arch" != "$(dpkg --print-architecture)" ]] && { echo "Architecture $arch does not match the current system architecture."; return 1; }
    if [[ -n "$gpg_key_url" ]]; then
        wget -qO- "$gpg_key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/${source_name}.gpg" || { echo "Failed to process GPG key for $source_name"; }
        echo "deb [signed-by=/usr/share/keyrings/${source_name}.gpg] $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
        [[ "$include_deb_src" == "true" ]] && echo "deb-src [signed-by=/usr/share/keyrings/${source_name}.gpg] $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
    else
        echo "deb $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
        [[ "$include_deb_src" == "true" ]] && echo "deb-src $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
    fi
    if [[ -n "$recv_keys" ]]; then
        sudo gpg --no-default-keyring --keyring "/usr/share/keyrings/${source_name}.gpg" --keyserver keyserver.ubuntu.com --recv-keys "$recv_keys" || { echo "Failed to receive keys for $source_name"; }
    fi
    if [[ -n "$trusted_key_url" ]]; then
        wget -qO- "$trusted_key_url" | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${source_name}.gpg" || { echo "Failed to process trusted key for $source_name"; }
    fi

    mflibs::status::success "$(zen::i18n::translate "dependency.apt_source_added" "$source_name")"
}

# @function zen::apt::remove_source
# @description Removes an APT source and its GPG key.
# @arg $1 string Name of the source to be removed.
# @stdout Removes specified APT source and its GPG key.
zen::apt::remove_source() {
    local source_name="$1"

    if [[ -z "$source_name" ]]; then
        echo "Source name is required."
        return 1
    fi
    local files_to_remove=(
        "/etc/apt/sources.list.d/${source_name}.list"
        "/usr/share/keyrings/${source_name}.gpg"
        "/etc/apt/trusted.gpg.d/${source_name}.gpg"
    )

    for file in "${files_to_remove[@]}"; do
        rm -f "$file"
    done

    mflibs::status::success "$(zen::i18n::translate "dependency.apt_source_removed" "$source_name")"
}


# @function zen::apt::update_source
# @description Updates APT sources based on the apt_sources.yaml file.
# @global MEDIAEASE_HOME Path to MediaEase configurations.
# @stdout Updates APT sources and GPG keys based on the YAML configuration.
# @note Recreates source list files and GPG keys for each source defined in the YAML file.
zen::apt::update_source() {
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/apt_sources.yaml"
    local source_names
    source_names=$(yq e '.sources | keys' "$dependencies_file")

    for source_name in $source_names; do
        source_url=$(yq e ".sources.${source_name}.url" "$dependencies_file" | grep -v 'null')
        [[ -z "$source_url" ]] && { echo "URL for $source_name not found in YAML file."; continue; }
        include_deb_src=$(yq e ".sources.${source_name}.options.deb-src" "$dependencies_file" | grep -v 'null')
        gpg_key_url=$(yq e ".sources.${source_name}.options.gpg-key" "$dependencies_file" | grep -v 'null')
        if [[ -n "$gpg_key_url" ]]; then
            wget -qO- "$gpg_key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/${source_name}.gpg" || { echo "Failed to process GPG key for $source_name"; continue; }
            echo "deb [signed-by=/usr/share/keyrings/${source_name}.gpg] $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
            [[ "$include_deb_src" == "true" ]] && echo "deb-src $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
        else
            echo "deb $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
            [[ "$include_deb_src" == "true" ]] && echo "deb-src $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
        fi
        trusted_key_url=$(yq e ".sources.${source_name}.options.trusted-key" "$dependencies_file" | grep -v 'null')
        if [[ -n "$trusted_key_url" ]]; then
            wget -qO- "$trusted_key_url" | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${source_name}.gpg" || { echo "Failed to process trusted key for $source_name"; continue; }
        fi
        recv_keys=$(yq e ".sources.${source_name}.options.recv-keys" "$dependencies_file" | grep -v 'null')
        if [[ -n "$recv_keys" ]]; then
            sudo gpg --no-default-keyring --keyring "/usr/share/keyrings/${source_name}.gpg" --keyserver keyserver.ubuntu.com --recv-keys "$recv_keys" || { echo "Failed to receive keys for $source_name"; continue; }
        fi
        unset source_url include_deb_src gpg_key_url trusted_key_url recv_keys
    done
}

