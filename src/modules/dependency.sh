#!/usr/bin/env bash

################################################################################
# @description: Manages apt dependencies based on the specified action.
#               Supports actions like install, update, upgrade, check, etc.
# @arg: $1: action - The action to be performed (install, update, upgrade, check, etc.)
# @arg: $2: software_name - The name of the software whose dependencies are to be managed.
# @arg: $3: option - Additional options like 'reinstall', 'non-interactive', 'inline' (optional).
# @output: Executes the apt-get command based on the given parameters.
# @return_code: Returns the exit status of the apt-get command.
# @notes: Handles errors and specific use cases like reinstall and non-interactive mode.
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
# @description: Installs dependencies inline, displaying each dependency with a colored indicator based on success or failure.
# @arg: $@: A list of dependencies to install.
# @output: Installs each dependency and echoes the dependency name with a color indicator.
# @notes: Utilizes zen::dependency::apt::manage for installation. Colors are indicated by GREEN and RED variables.
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
# @description: updates server
# @noargs
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
# @description: Removes dependencies for a specific software if it's no longer needed.
# @arg: $1: software_name - The name of the software to remove dependencies for.
# @usage: zen::dependency::apt::remove "radarr"
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
# @description: Builds and installs external dependencies from a YAML configuration file.
# @arg: $1: software_name - The name of the software to install external dependencies for.
# @output: Executes the installation commands for external dependencies.
# @return_code: Returns 0 if all dependencies are installed successfully, 1 otherwise.
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
