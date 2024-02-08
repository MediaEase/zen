#!/usr/bin/env bash
################################################################################
# @file_name: service.sh
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
# zen::service::generate
#
# Generates a systemd service file for an application. This function creates a
# service file with necessary directives and configurations based on the app's
# requirements and the system's environment.
#
# Arguments:
#   app_name - The name of the application.
#   is_child - Flag indicating if the service is for multiple users.
# Globals:
#   software_config_file - Path to the software's configuration file.
# Outputs:
#   Creates a systemd service file for the application.
# Notes:
#   The function handles both single-user and multi-user service scenarios. It
#   dynamically determines the service name and configures it based on the
#   application's needs and user settings.
# shellcheck disable=SC2154
# Disable reason : build entries variables are global variables and are created in other functions
################################################################################
zen::service::generate() {
    local app_name="$1"
    local is_child="$2"

    mflibs::shell::text::white "$(zen::i18n::translate "service.generating_service" "$app_name")"
    is_multi=$(zen::software::get_config_key_value "$software_config_file" '.arguments.multi_user')
    service_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("service")).service' "${user[username]}" "$app_name")
    caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")
    backup_path=$(zen::software::get_config_key_value "$software_config_file" '.arguments.paths[] | select(has("backup")).backup' "${user[username]}" "$app_name")
    data_path=$(zen::software::get_config_key_value "$software_config_file" '.arguments.paths[] | select(has("data")).data' "${user[username]}" "$app_name")
    [ "$is_multi" == "true" ] && service_name="$app_name@${user[username]}.service" || service_name="$app_name.service"
    local -a service_directives
    readarray -t service_directives < <(yq e ".arguments.service_directives[]" "$software_config_file")

    local service_content=(
        "[Unit]"
        "Description=$app_name_sanitized Daemon"
        "After=syslog.target network.target"
        ""
        "[Service]"
        "User=%i"
        "Group=%i"
        ""
    )
    for directive in "${service_directives[@]}"; do
        directive=${directive//\$app_name/$app_name}
        service_content+=("$directive")
    done


    if [ "$is_multi" == "true" ]; then
        service_content+=(
            ""
            "[Install]"
            "WantedBy=multi-user.target"
        )
    fi

    # Write the content to the service file
    printf "%s\n" "${service_content[@]}" > "$service_file"
    mflibs::shell::text::green "$(zen::i18n::translate "service.service_file_created" "$app_name" "$service_name")"
    mflibs::log "systemctl daemon-reload"
    # if not bypass_mode; then
    zen::service::manage "enable" "$service_name"
    if [[ -z "$bypass_mode" || "$bypass_mode" != true ]]; then
        zen::service::build::add_entry "name" "$service_name"
        zen::service::build::add_entry "caddyfile_path" "$caddy_file"
        zen::service::build::add_entry "default_port" "$default_port"
        zen::service::build::add_entry "ssl_port" "$ssl_port"
        zen::service::build::add_entry "data_path" "$data_path"
        zen::service::build::add_entry "backup_path" "$backup_path"
        zen::service::build::add_entry "root_url" "${url_base}"
        zen::service::build::add_entry "apikey" "$apikey"
        zen::service::validate "$is_child" "$app_name_sanitized"
    else
        mflibs::shell::text::yellow "$(zen::i18n::translate "service.service_bypassed" "$app_name")"
    fi
}

################################################################################
# zen::service::manage
#
# Manages the state of a systemd service. This function allows for starting,
# stopping, restarting, enabling, disabling, and checking the status of a service.
#
# Arguments:
#   action - The action to perform (start, stop, restart, enable, disable, status).
#   service_name - The name of the service to manage.
# Outputs:
#   Performs the specified action on the systemd service.
# Returns:
#   Exits with a status code if an invalid action is provided.
# Notes:
#   This function is a wrapper around systemctl commands, providing an easier
#   interface for service management within the script.
################################################################################
zen::service::manage() {
    local action=$1
    local service_name=$2
    case $action in
    start | stop | restart)
        systemctl "$action" "$service_name"
        zen::service::manage "status" "$service_name"
        ;;
    enable)
        systemctl daemon-reload
        systemctl enable "$service_name" --now > /dev/null 2>&1
        zen::service::manage "start" "$service_name"
        ;;
    disable)
        systemctl stop "$service_name"
        systemctl disable "$service_name"
        systemctl daemon-reload
        zen::service::manage "status" "$service_name"
        ;;
    status)
        if systemctl is-active --quiet "$service_name"; then
            mflibs::shell::text::green "$(zen::i18n::translate 'service.service_running' "$service_name")"
        else
            mflibs::shell::text::red "$(zen::i18n::translate 'service.service_not_running' "$service_name")"
        fi
        ;;
    *)
        mflibs::status::error "$(zen::i18n::translate 'common.invalid_action' "$action" "$service_name")"
        exit 1
        ;;
    esac
}

################################################################################
# zen::service::build::add_entry
#
# Adds an entry to the api_service associative array. This function is used
# to build up the service configuration dynamically.
#
# Arguments:
#   key - The key of the entry to add.
#   value - The value of the entry.
# Globals:
#   api_service - An associative array used to build the service configuration.
# Outputs:
#   Adds a key-value pair to the api_service associative array.
# Returns:
#   1 if the key already exists in the array, otherwise 0.
################################################################################
zen::service::build::add_entry() {
    local key="$1"
    local value="$2"

    if [[ -n "${api_service[$key]}" ]]; then
        mflibs::status::error "$(zen::i18n::translate "service.build_entry_exists" "$key")"
        return 1
    fi
    api_service["$key"]="$value"
}

################################################################################
# zen::service::validate
#
# Validates the api_service associative array and inserts the data into the
# database. This function ensures that the service configuration is valid and
# prepares it for storage.
#
# Arguments:
#   is_child - Flag indicating if the service is a child service.
#   app_name_sanitized - The sanitized name of the application.
# Globals:
#   None.
# Outputs:
#   Validates service configuration and inserts it into the database.
# Notes:
#   The function constructs JSON objects for the service configuration and
#   uses database functions to store the configuration. It is typically called
#   after building the service configuration using `zen::service::build::add_entry`.
################################################################################
zen::service::validate() {
    local is_child="$1"
    local app_name_sanitized="$2"
    mflibs::shell::text::white "$(zen::i18n::translate "service.validating_service" "$app_name_sanitized")"
    local json_ports json_configuration application_id parent_service_id json_result json_string

    # Assuming api_service[port_type] contains a simple string or number
    json_ports=$(jq -n \
        --arg default_port "${api_service[default_port]}" \
        --arg ssl_port "${api_service[ssl_port]}" \
        '[{"default": ($default_port | tonumber), "ssl": ($ssl_port | tonumber)}]')
    # Configuration JSON
    json_configuration=$(jq -n \
        --arg data_path "${api_service[data_path]}" \
        --arg backup_path "${api_service[backup_path]}" \
        --arg caddyfile_path "${api_service[caddyfile_path]}" \
        --arg root_url "${api_service[root_url]}" \
        '[{"data_path": $data_path, "backup_path": $backup_path, "caddyfile_path": $caddyfile_path, "root_url": $root_url}]')
    # Application JSON
    application_id=$(zen::database::select "id" "application" "altname = '$app_name'")
    # keep only the first result
    application_id=$(echo "$application_id" | head -n 1)
    if [[ "$is_child" == "true" ]]; then
        parent_service_id=$(zen::database::select "id" "service" "id = (SELECT MAX(id) FROM application)")
    else 
        parent_service_id="null"
    fi
    # Construct the final JSON
    local json_result
    json_result=$(jq -n \
        --arg name "${api_service[name]}" \
        --arg apikey "${api_service[apikey]}" \
        --arg user_id "${user[id]}" \
        --argjson ports "$json_ports" \
        --argjson configuration "$json_configuration" \
        --arg application_id "$application_id" \
        --arg parent_service_id "$parent_service_id" \
        '{
            "name": $name,
            "version": "0.0.0",
            "status": "active",
            "apikey": $apikey,
            "ports": $ports,
            "configuration": $configuration,
            "application_id": $application_id,
            "parent_service_id": $parent_service_id,
            "user_id": $user_id
        }')
    # Convert JSON result to a string to store in the database
    local json_string
    json_string=$(echo "$json_result" | jq -c .)

    # Call the zen::database::insert function
    zen::database::insert "services" "name, version, status, apikey, ports, configuration, application_id, parent_service_id, user_id" "'$json_string'"
    mflibs::shell::text::green "$(zen::i18n::translate "service.service_validated" "$app_name_sanitized")"
}
