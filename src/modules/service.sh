#!/usr/bin/env bash

################################################################################
# @description: Generates a systemd service file for an application.
# @arg: $1: app_name - The name of the application.
# @arg: $2: multi_user - Flag indicating if the service is for multiple users.
# @arg: $3: app_specific_directives - Array of application-specific directives.
# shellcheck disable=SC2154
# @disable reason : build entries variables are global variables and are created in other functions
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
# @description: Manages a systemd service (start, stop, restart, enable, disable, status)
# @arg $1: action (start, stop, restart, enable, disable, status)
# @arg $2: service_name
# @usage: zen::software::service "start" "service_name"
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
# @description: Adds an entry to the api_service associative array
# @arg $1: key
# @arg $2: value
# @usage: zen::service::build::add_entry "key" "value"
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
# @description: Validates the api_service associative array and inserts the data into the database
# @arg $1: is_child - Flag indicating if the service is a child service.
# @arg $2: app_name_sanitized - The sanitized name of the application.
# @usage: zen::service::validate "true" "app_name_sanitized"
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
