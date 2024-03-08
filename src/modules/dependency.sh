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
# Manages APT dependencies for specified software.
# @description This function manages APT (Advanced Packaging Tool) dependencies based on the input action, software name, and additional options.
# It processes various APT actions like install, update, upgrade, and check. The function uses a YAML file for dependency definitions.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string APT action to perform (install, update, upgrade, check, etc.).
# @arg $2 string Name of the software for dependency management.
# @arg $3 string Additional options (reinstall, non-interactive, inline).
# @stdout Executes apt-get commands based on input parameters.
# @return Exit status of the last executed apt-get command.
# @note Handles APT actions, reinstall, and non-interactive mode.
zen::dependency::apt::manage() {
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/dependencies.yaml"
    local action="$1"
    local software_name="${2:-}"
    local option="$3"
    declare -g cmd_options
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
            # shellcheck disable=SC2154
            if [[ $verbose -eq 1 ]]; then
                cmd_options=("$action" -y --allow-unauthenticated)
            else
                cmd_options=("$action" -yqq --allow-unauthenticated)
            fi
            [[ "$option" == "reinstall" ]] && cmd_options+=(--reinstall)
            zen::dependency::apt::install::inline "${dependencies_string}" "${cmd_options[@]}" && return
            ;;
        update|upgrade|check)
            # shellcheck disable=SC2154
            if [[ $verbose -eq 1 ]]; then
                cmd_options=("$action" -y)
            else
                cmd_options=("$action" -yqq)
            fi
            apt-get "${cmd_options[@]}" && return
            ;;
        *)
            mflibs::status::error "$(zen::i18n::translate 'common.invalid_action' "$action")"
            return 1
            ;;
    esac
}

# @function zen::dependency::apt::install::inline
# Installs APT dependencies inline with progress display.
# @description This function installs APT dependencies inline, showing the progress. It uses apt-get for installation and dpkg-query to check existing installations.
# Visual feedback is provided with colored output: red for failures and green for successful installations.
# @arg $dependencies_string string Space-separated list of dependencies to install.
# @stdout On success, displays the number of installed packages; on failure, shows failed package names.
# @note The function checks for existing installations before proceeding with installation.
# @example
#   zen::dependency::apt::install::inline "package1 package2 package3"
zen::dependency::apt::install::inline() {
    local dependencies_string="$1"
    local cmd_options=("${@:2}")
    IFS=' ' read -r -a dependencies <<< "$dependencies_string"
    local failed_deps=()
    local installed_count=0
    local last_index=$(( ${#dependencies[@]} - 1 ))

    for i in "${!dependencies[@]}"; do
        local dep="${dependencies[i]}"
        if [[ $(dpkg-query -W -f='${Status}' "${dep}" 2>/dev/null | grep -c "ok installed") -ne 1 ]]; then
            # shellcheck disable=SC2154
            if [[ $verbose -eq 1 ]]; then
                if apt-get install "${cmd_options[@]}" "${dep}" > /tmp/dep_install_output 2>&1; then
                    ((installed_count++))
                else
                    mflibs::log "$(mflibs::shell::text::red "Failed to install ${dep}.")"
                    failed_deps+=("${dep}")
                fi
            else
                if ! apt-get install "${cmd_options[@]}" "${dep}" > /tmp/dep_install_output 2>&1; then
                    printf "%s$(tput setaf 1)✗ $(tput sgr0)" "${dep}"
                    failed_deps+=("${dep}")
                else
                    ((installed_count++))
                    printf "%s" "${dep}"
                fi
                if [[ $i -ne $last_index ]]; then
                    printf " | "
                fi
            fi
        fi
    done
    mflibs::status::info "$(zen::i18n::translate 'dependency.installed_count' "$installed_count")"
    if [[ ${#failed_deps[@]} -gt 0 ]]; then
        mflibs::status::warn "$(zen::i18n::translate 'dependency.failed_dependencies' "${failed_deps[*]}")"
    fi
    mflibs::status::success "$(zen::i18n::translate 'dependency.installation_complete')"
}

# @function zen::dependency::apt::update
# Updates package lists and upgrades installed packages.
# @description This function performs system updates using apt-get commands. It updates the package lists and upgrades the installed packages.
# Additionally, it handles locked dpkg situations and logs command execution for troubleshooting.
# @global None.
# @noargs
# @stdout Executes apt-get update, upgrade, autoremove, and autoclean commands.
# @note The function checks for and resolves locked dpkg situations before proceeding.
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
            dpkg --configure -a
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
# Removes APT dependencies not needed by other software.
# @description This function removes APT dependencies that are no longer needed by other installed software.
# It reads dependencies from a YAML file and checks for exclusive use before removing them.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string Name of the software for dependency removal.
# @stdout Removes unused APT dependencies of the specified software.
# @note The function considers dependencies listed for the specified software in the YAML configuration.
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
# Installs all external dependencies for a specified application.
# @description This function installs external dependencies for a specified application as defined in a YAML configuration file.
# It creates temporary scripts for each external dependency's install command and executes them.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string The name of the application for which to install external dependencies.
# @stdout Executes installation commands for each external dependency of the specified application.
# @note Iterates over the external dependencies in the YAML file and executes their install commands.
zen::dependency::external::install() {
    local app_name="$1"
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/dependencies.yaml"
    if [[ -z "$app_name" ]]; then
        printf "Application name is required.\n"
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
                printf "Installation failed for %s in %s with status %d\n" "$software_name" "$app_name" "$install_status"
                return 1
            fi
        fi
    done <<< "$entries"
    mflibs::status::success "$(zen::i18n::translate "dependency.external_dependencies_installed" "$app_name")"
}

# @function zen::apt::add_source
# # Adds a new APT source and its GPG key.
# @description This function adds a new APT source and its corresponding GPG key from a YAML configuration file.
# It handles different options like architecture, inclusion of source repositories, and GPG key processing.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string Name of the source as specified in the YAML configuration.
# @stdout Adds new APT source and GPG key based on the YAML configuration.
# @note The function evaluates and applies settings from the YAML configuration for the specified source.
# @example
#   zen::apt::add_source "php"
# shellcheck disable=SC2155
# Disable SC2155 because if the command fails, it will exit the script.
zen::apt::add_source() {
    local source_name="$1"
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/apt_sources.yaml"
    
    [[ -z "$source_name" ]] && { printf "Source name is required.\n"; return 1; }

    local source_url_template=$(yq e ".sources.${source_name}.url" "$dependencies_file")
    local source_url=$(eval echo "$source_url_template")
    local arch=$(yq e ".sources.${source_name}.options.arch" "$dependencies_file")
    local include_deb_src=$(yq e ".sources.${source_name}.options.deb-src" "$dependencies_file" | grep -v 'null')
    local gpg_key_url=$(yq e ".sources.${source_name}.options.gpg-key" "$dependencies_file" | grep -v 'null')
    local recv_keys=$(yq e ".sources.${source_name}.options.recv-keys" "$dependencies_file" | grep -v 'null')
    local trusted_key_url=$(yq e ".sources.${source_name}.options.trusted-key" "$dependencies_file" | grep -v 'null')

    [[ -z "$source_url" ]] && { printf "URL for %s not found in YAML file.\n" "$source_name"; return 1; }
    [[ -n "$arch" && "$arch" != "null" && "$arch" != "$(dpkg --print-architecture)" ]] && { printf "Architecture %s not supported for %s\n" "$arch" "$source_name"; return 1; }
    if [[ -n "$gpg_key_url" ]]; then
        wget -qO- "$gpg_key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/${source_name}.gpg" || { printf "Failed to process GPG key for %s\n" "$source_name"; }
        echo "deb [signed-by=/usr/share/keyrings/${source_name}.gpg] $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
        [[ "$include_deb_src" == "true" ]] && echo "deb-src [signed-by=/usr/share/keyrings/${source_name}.gpg] $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
    else
        echo "deb $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
        [[ "$include_deb_src" == "true" ]] && echo "deb-src $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
    fi
    if [[ -n "$recv_keys" ]]; then
        sudo gpg --no-default-keyring --keyring "/usr/share/keyrings/${source_name}.gpg" --keyserver keyserver.ubuntu.com --recv-keys "$recv_keys" || { printf "Failed to receive keys for %s\n" "$source_name"; }
    fi
    if [[ -n "$trusted_key_url" ]]; then
        wget -qO- "$trusted_key_url" | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${source_name}.gpg" || { printf "Failed to process trusted key for %s\n" "$source_name"; }
    fi

    mflibs::status::success "$(zen::i18n::translate "dependency.apt_source_added" "$source_name")"
}

# @function zen::apt::remove_source
# Removes an APT source and its GPG key.
# @description This function removes an APT source and its GPG key.
# It deletes the corresponding source list files and GPG keys for the specified source.
# @arg $1 string Name of the source to be removed.
# @stdout Removes specified APT source and its GPG key.
zen::apt::remove_source() {
    local source_name="$1"

    if [[ -z "$source_name" ]]; then
        printf "Source name is required.\n"
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
# Updates APT sources based on a YAML configuration.
# @description This function updates APT sources based on the definitions in the apt_sources.yaml file.
# It recreates source list files and GPG keys for each source defined in the configuration.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @stdout Updates APT sources and GPG keys based on the YAML configuration.
# @note The function iterates over all sources defined in the YAML file and applies their configurations.
zen::apt::update_source() {
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/apt_sources.yaml"
    local source_names
    source_names=$(yq e '.sources | keys' "$dependencies_file")

    for source_name in $source_names; do
        source_url=$(yq e ".sources.${source_name}.url" "$dependencies_file" | grep -v 'null')
        [[ -z "$source_url" ]] && { printf "URL for %s not found in YAML file.\n" "$source_name"; continue; }
        include_deb_src=$(yq e ".sources.${source_name}.options.deb-src" "$dependencies_file" | grep -v 'null')
        gpg_key_url=$(yq e ".sources.${source_name}.options.gpg-key" "$dependencies_file" | grep -v 'null')
        if [[ -n "$gpg_key_url" ]]; then
            wget -qO- "$gpg_key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/${source_name}.gpg" || { printf "Failed to process GPG key for %s\n" "$source_name"; continue; }
            echo "deb [signed-by=/usr/share/keyrings/${source_name}.gpg] $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
            [[ "$include_deb_src" == "true" ]] && echo "deb-src $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
        else
            echo "deb $source_url" > "/etc/apt/sources.list.d/${source_name}.list"
            [[ "$include_deb_src" == "true" ]] && echo "deb-src $source_url" >> "/etc/apt/sources.list.d/${source_name}.list"
        fi
        trusted_key_url=$(yq e ".sources.${source_name}.options.trusted-key" "$dependencies_file" | grep -v 'null')
        if [[ -n "$trusted_key_url" ]]; then
            wget -qO- "$trusted_key_url" | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${source_name}.gpg" || { printf "Failed to process trusted key for %s\n" "$source_name"; continue; }
        fi
        recv_keys=$(yq e ".sources.${source_name}.options.recv-keys" "$dependencies_file" | grep -v 'null')
        if [[ -n "$recv_keys" ]]; then
            sudo gpg --no-default-keyring --keyring "/usr/share/keyrings/${source_name}.gpg" --keyserver keyserver.ubuntu.com --recv-keys "$recv_keys" || { printf "Failed to receive keys for %s\n" "$source_name"; continue; }
        fi
        unset source_url include_deb_src gpg_key_url trusted_key_url recv_keys
    done
}

