#!/usr/bin/env bash
################################################################################
# @file_name: software.sh
# @version: 1.0.0
# @project_name: MediaEase
# @description: a library for internationalization functions
#
# @author: Thomas Chauveau (tomcdj71)
# @author_contact: thomas.chauveau.pro@gmail.com
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2024, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# zen::software::is::installed
#
# Checks if a specific software is installed for a given user.
#
# Arguments:
#   software - Name (altname) of the software.
#   user_id - User ID to check the software installation for (use "*" to check for all users).
# Returns:
#   0 if the software is installed, 1 otherwise.
# Notes:
#   Queries the database to check for an entry in the 'service' table for a given
#   user and software. Use '*' for user_id to check across all users.
# Usage:
#   zen::software::is::installed "software_name" "user_id"
#   [[ $(zen::software::is::installed "subsonic" 6) ]] && echo "yes" || echo "no"
################################################################################
zen::software::is::installed() {
    local software="$1"
    local user_id="$2"

    if [[ -z "$software" ]]; then
        mflibs::status::error "$(zen::i18n::translate "software.software_name_not_found")"
        return 1
    fi
    
    local select_clause="a.name, a.altname, GROUP_CONCAT(srv.name) as services, srv.application_id, GROUP_CONCAT(srv.ports) as ports, srv.user_id"
    local table_with_alias="application a"
    local inner_join_clause="service srv ON a.id = srv.application_id"
    local where_clause="a.altname = '${software}'"
    local additional_clauses=""

    if [[ "$user_id" != "*" ]]; then
        if [[ -z "$user_id" ]]; then
            mflibs::status::error "$(zen::i18n::translate "common.user_id_not_found")"
            return 1
        fi
        additional_clauses="AND srv.user_id = ${user_id} "
    fi

    additional_clauses+="GROUP BY srv.user_id;"
    local distinct_flag="1"
    zen::database::select::inner_join "$select_clause" "$table_with_alias" "$inner_join_clause" "$where_clause" "$additional_clauses" "$distinct_flag"
}

################################################################################
# zen::software::port_randomizer
#
# Generates a random port number within a specified range for a given application.
#
# Arguments:
#   app_name - Name of the application.
#   port_type - Type of port to generate (default, ssl).
#   software_config_file - Path to the configuration file.
# Returns:
#   A randomly selected port number within the specified range.
# Usage:
#   zen::software::port_randomizer "app_name" "port_type" "config_file"
################################################################################
zen::software::port_randomizer() {
    local app_name="$1"
    local port_type="$2"
    local port_range
    local port_low
    local port_high
    local retries=10

    port_range=$(yq e ".arguments.ports[] | select(.${port_type} != null) | .${port_type}" "$software_config_file")
    if [[ -z "$port_range" ]]; then
        mflibs::status::error "$(zen::i18n::translate "software.no_port_range_found" "$app_name")"
        return 1
    fi

    port_low=$(echo "$port_range" | tr -d '[]' | cut -d'-' -f1)
    port_high=$(echo "$port_range" | tr -d '[]' | cut -d'-' -f2)

    while ((retries > 0)); do
        local port=$((port_low + RANDOM % (port_high - port_low + 1)))
        if ! netstat -tuln | grep -q ":$port "; then
            echo "$port"
            return 0
        fi
        ((retries--))
    done

    mflibs::status::error "$(zen::i18n::translate "software.port_unavailable" "$app_name")"
    return 1
}

################################################################################
# zen::software::infobox
#
# Builds the header or footer for the software installer, providing contextual
# information about the installation process.
#
# Arguments:
#   app_name - The name of the application.
#   shell_color - The color to use for the text.
#   action - The action being performed (add, update, backup, reset, remove, reinstall).
#   infobox_type - "intro" for header, "outro" for footer.
#   username (optional) - The username to display in the infobox.
#   password (optional) - The password to display in the infobox.
# Usage:
#   zen::software::infobox "app_name" "shell_color" "action" "infobox_type"
################################################################################
zen::software::infobox() {
    local app_name="$1"
    local shell_color="$2"
    local action="$3"
    local infobox_type="$4"
    local username="$5"
    local password="$6"
    local shell
    local translated_string
    local app_name_sanitized
    app_name_sanitized=$(zen::common::capitalize::first "$app_name")
    case "$shell_color" in
        yellow)
            shell="mflibs::shell::text::yellow"
            ;;
        magenta)
            shell="mflibs::shell::text::magenta"
            ;;
        cyan)
            shell="mflibs::shell::text::cyan"
            ;;
        *)
            local colors=("mflibs::shell::text::cyan" "mflibs::shell::text::magenta" "mflibs::shell::text::yellow")
            local random_index=$(( RANDOM % ${#colors[@]} ))
            shell="${colors[random_index]}"
            ;;
    esac

    case "$infobox_type" in
        intro)
            case "$action" in
                add|update|backup|reset|remove|reinstall)
                    translated_string=$(zen::i18n::translate "software.header_info_$action" "$app_name_sanitized")
                    ;;
                *)
                    translated_string="Action: $action"
                    ;;
            esac
            $shell "################################################################################"
            $shell "# $(zen::common::capitalize::first "$app_name") Install Wizard"
            $shell "# $(date)"
            $shell "# $translated_string"
            $shell "################################################################################"
            ;;
        outro)
            case "$action" in
                add|update|backup|reset|remove|reinstall)
                    outro=$(zen::i18n::translate "software.footer_info_$action" "$app_name_sanitized")
                    # shellcheck disable=SC2154
                    [ "$action" != "remove" ] && access_link=$(zen::i18n::translate "software.access_link" "$app_name_sanitized" "$url_base")
                    [ "$action" != "remove" ] && docs_link=$(zen::i18n::translate "software.docs_link" "$app_name_sanitized" "$url_base")
                    ;;
                *)
                    translated_string="Action completed: $action"
                    ;;
            esac
            settings=$(zen::common::setting::load)
            root_url=${settings[root_url]}
            $shell "################################################################################"
            $shell "# $(zen::common::capitalize::first "$app_name") Install Wizard"
            $shell "# $(date)"
            $shell "# $outro"
            [ "$action" != "remove" ] && $shell "# ------------------------------------------------------------------------------"
            [[ -n "$docs_link" && "$action" == "add" ]] && $shell "# $root_url/$docs_link"
            [[ -n "$mediaease_link" && "$action" == "add" ]] && $shell "# $mediaease_link"
            [[ -n "$homepage_link" && "$action" == "add" ]] && $shell "# $homepage_link"
            [[ -n "$access_link" ]] && $shell "# $access_link"
            [[ -n "$username" ]] && $shell "# Username: $username"
            [[ -n "$password" ]] && $shell "# Password: $password"
            $shell "################################################################################"
            ;;
        *)
            echo "Invalid infobox type: $infobox_type"
            return 1
            ;;
    esac
    echo ""
}

################################################################################
# zen::software::options::process
#
# Processes software options from a comma-separated string. This function parses
# options like branch, email, domain, and key from a string and sets them as variables.
#
# Arguments:
#   options - A string of options in the format "option1=value1,option2=value2".
# Usage:
#   zen::software::options::process "branch=beta,email=test@example.com"
# shellcheck disable=SC2034
# Disable SC2034 because the variables are exported and used in other functions
################################################################################
zen::software::options::process() {
    local options="$1"
    software_branch="" software_email="" software_domain="" software_key=""

    IFS=',' read -ra options_array <<< "$options"
    for option in "${options_array[@]}"; do
        IFS='=' read -ra option_array <<< "$option"
        local option_name="${option_array[0]}"
        local option_value="${option_array[1]}"
        case "$option_name" in
            branch)
                software_branch="$option_value"
                ;;
            email)
                software_email="$option_value"
                ;;
            domain)
                software_domain="$option_value"
                ;;
            key)
                software_key="$option_value"
                ;;
            *)
                mflibs::status::error "$(zen::i18n::translate "common.invalid_option" "$option_name")"
                exit 1
                ;;
        esac
    done

    # Check if the variables are not empty, export it
    for var in software_branch software_email software_domain software_key; do
        if [[ -n "${!var}" ]]; then
            export "${var?}"
        fi
    done
}

################################################################################
# zen::software::backup::create
#
# Handles the creation of software backups. This function generates a backup
# of the specified software and stores it in a designated directory.
#
# Arguments:
#   app_name - The name of the application.
# Usage:
#   zen::software::backup::create "app_name"
# shellcheck disable=SC2154
# Disable SC2154 because the variable is defined in the main script
################################################################################
zen::software::backup::create() {
    local app_name="$1"
    local backup_dir="/home/${user[username]}/.mediaease/backups/$app_name"
    backup_file="$backup_dir/$app_name-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p "$backup_dir"

    local files_to_backup=()
    readarray -t files_to_backup < <(yq e ".arguments.files[].*" "$software_config_file" | sed "s/%i/${user[username]}/g; s/\$app_name/$app_name/g")

    if [ ${#files_to_backup[@]} -eq 0 ]; then
        mflibs::status::error "$(zen::i18n::translate "software.no_files_for_backup" "$app_name")"
        return 1
    fi

    mflibs::shell::text::white "$(zen::i18n::translate "software.creating_backup" "$app_name")"
    if tar -czf "$backup_file" "${files_to_backup[@]}" >/dev/null 2>&1; then
        mflibs::shell::text::green "$(zen::i18n::translate "software.backup_created" "$backup_file")"
    else
        mflibs::status::error "$(zen::i18n::translate "software.backup_failed" "$app_name")"
        return 1
    fi
}

################################################################################
# zen::software::get_config_key_value
#
# Retrieves the value of a specified key or expression from a YAML configuration file.
# This function is used to parse and extract specific settings from the software's
# configuration file.
#
# Arguments:
#   software_config_file - Path to the YAML configuration file.
#   yq_expression - The 'yq' expression to evaluate in the configuration file.
# Returns:
#   The value of the specified key or expression.
# Usage:
#   zen::software::get_config_key_value "config_file_path" "yq_expression"
################################################################################
zen::software::get_config_key_value() {
    local software_config_file="$1"
    local yq_expression="$2"
    local username="$3"
    local app_name="$4"

    if [[ -z "$software_config_file" ]]; then
        mflibs::status::error "$(zen::i18n::translate "software.config_file_not_found")"
        return 1
    fi

    if [[ ! -f "$software_config_file" ]]; then
        mflibs::status::error "$(zen::i18n::translate "software.config_file_not_found")"
        return 1
    fi

    local key_value
    key_value=$(yq e "$yq_expression" "$software_config_file")
    if [[ -z "$key_value" ]]; then
        mflibs::status::error "$(zen::i18n::translate "software.invalid_config_expression" "$yq_expression")"
        return 1
    fi

    key_value="${key_value//%i/$username}"
    key_value="${key_value//\$app_name/$app_name}"

    echo "$key_value"
    return 0
}

################################################################################
# zen::software::autogen
#
# Automatically generates random values for keys specified in the 'autogen' section
# of the software configuration file. This function is useful for auto-generating
# API keys, port numbers, and other configuration parameters.
#
# No arguments.
# Usage:
#   zen::software::autogen
# shellcheck disable=SC2034
# Disable SC2034 because the variables are exported and used in other functions
################################################################################
zen::software::autogen() {
    local autogen_keys
    readarray -t autogen_keys < <(yq e ".arguments.autogen[]" "$software_config_file")

    for key in "${autogen_keys[@]}"; do
        case "$key" in
            apikey)
                declare -g apikey
                apikey=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
                ;;
            ssl_port)
                declare -g ssl_port
                ssl_port=$(zen::software::port_randomizer "$app_name" "ssl")
                ;;
            default_port)
                declare -g default_port
                default_port=$(zen::software::port_randomizer "$app_name" "default")
                ;;
            password)
                declare -g password
                password=$(zen::user::password::generate 16)
                ;;
            *)
                echo "Unknown key for autogeneration: $key"
                ;;
        esac
    done

    for var in apikey ssl_port default_port password; do
        if [[ -n "${!var}" ]]; then
            export "${var?}"
        fi
    done
}
