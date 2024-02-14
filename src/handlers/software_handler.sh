#!/usr/bin/env bash
# @file handlers/software_handler.sh
# @project MediaEase
# @version 1.0.0
# @description A handler for software management commands.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::software::handle_action
# @description Handles the specified action for the given software.
# @arg $1 string The action to be performed (add, remove, backup, update, reset).
# @arg $2 string The username associated with the application.
# @arg $3 string The name of the application.
# @stdout Executes the appropriate action for the specified software.
# @note Sources the script for the specified software and executes the appropriate
#       action function. Checks if the software is already installed and handles
#       multi-user scenarios. Manages dependencies and software installation.
# shellcheck disable=SC2154,SC1090
# @example
#   zen::software::handle_action "add" "jason" "radarr"
zen::software::handle_action() {
    local action="$1"
    declare -g app_name="$2"
    declare -g app_name_sanitized

    # shellcheck disable=SC2034
    declare -A -g api_service
    app_name_sanitized=$(zen::common::capitalize::first "$app_name")

    # Determine the script path
    declare -g script_path software_config_file
    # shellcheck disable=SC2034
    if [[ -f "/opt/MediaEase/scripts/src/software/official/$app_name/$app_name" ]]; then
        script_path="/opt/MediaEase/scripts/src/software/official/$app_name/$app_name"
        software_config_file="/opt/MediaEase/scripts/src/software/official/$app_name/config.yaml"
    elif [[ -f "/opt/MediaEase/scripts/src/software/experimental/$app_name/$app_name" ]]; then
        script_path="/opt/MediaEase/scripts/src/software/experimental/$app_name/$app_name"
        software_config_file="/opt/MediaEase/scripts/src/software/experimental/$app_name/config.yaml"
    else
        mflibs::status::error "$(zen::i18n::translate "software.software_name_not_found" "$app_name")"
        exit 1
    fi
    # Source the script and call the appropriate action
    source "$script_path"
    declare -g shell_color
    shell_color=$(zen::common::shell::color::randomizer)
    zen::software::infobox "$app_name_sanitized" "$shell_color" "$action" "intro"
    is_installed_by_user=$(zen::software::is::installed "$app_name" "${user[id]}" | wc -l)
    is_installed_by_others=$(zen::software::is::installed "$app_name" "*" | wc -l)
    if [[ "$bypass_mode" != true ]]; then
        if [[ $is_installed_by_user -gt 0 ]]; then
            mflibs::status::info "$(zen::i18n::translate "software.application_already_installed_by_user" "$app_name_sanitized" "${user[username]}") $(zen::i18n::translate "software.application_fallback_action" "update")"
            mflibs::shell::text::white "$(zen::i18n::translate "software.update_app" "$app_name_sanitized")"
            action="update"
        fi
    fi
    if [[ "$action" == "add" ]]; then
        zen::dependency::apt::update > /dev/null 2>&1
        zen::dependency::apt::manage "upgrade" > /dev/null 2>&1
        mflibs::shell::text::white "$(zen::i18n::translate 'dependency.installing_dependencies')"
        zen::dependency::apt::manage "install" "$app_name" "inline"  > /dev/null 2>&1
        mflibs::shell::text::green "$(zen::i18n::translate 'dependency.dependencies_installed')"
    fi
    if [[ "$action" == "update" ]]; then
        zen::dependency::apt::update > /dev/null 2>&1
        zen::dependency::apt::manage "upgrade"
    fi
    if [[ "$action" == "remove" ]]; then
        if [[ $is_installed_by_others -gt 0 ]]; then
            zen::dependency::apt::manage "remove" "$app_name" "inline"
        fi
    fi
    if declare -f "zen::software::$app_name::$action" >/dev/null; then
        "zen::software::$app_name::$action"
    else
        mflibs::status::error "$(zen::i18n::translate "software.action_handler_not_found" "$app_name" "$action")"
        return 1
    fi
    zen::software::infobox "$app_name_sanitized" "$shell_color" "$action" "outro"
}

# @function zen::args::process
# @description Processes command-line arguments for software management commands.
# @arg $@ array Command-line arguments.
# @stdout Parses action, username, application name, and options from the arguments.
#       Calls zen::software::handle_action with the parsed arguments.
# @note Processes options like bypass mode and handles invalid or missing arguments.
# @example
#   zen::args::process "$@"
zen::args::process() {
    declare -g function_process username="" app_name="" options=""
    declare -a invalid_option
    if [[ $# -lt 2 ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.insufficient_arguments")"
        exit 1
    fi
    function_process="${1}"
    shift
    while (( "$#" )); do
        case "$1" in
            -u) username="$2"; zen::user::load "$2"; shift 2 ;;
            -o) options="$2"; shift 2 ;;
            --bypass) bypass_mode=true; shift ;;
            *) if [[ -z "$app_name" ]]; then app_name="$1"; else invalid_option+=("$1"); fi; shift ;;
        esac
    done
    if [[ -z "$username" || -z "$app_name" ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.missing_arguments")"
        exit 1
    fi
    if [[ ${#invalid_option[@]} -gt 0 ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.invalid_options" "${invalid_option[*]}")"
        exit 1
    fi
    [[ -n "$bypass_mode" ]] && declare -g bypass_mode
    zen::software::options::process "$options"
    zen::software::handle_action "$function_process" "$app_name" "$software_branch" "$software_email" "$software_domain" "$software_key" "$bypass_mode"
}

# Main execution flow
# Processes the command-line arguments and calls the appropriate function.
zen::args::process "$@"
