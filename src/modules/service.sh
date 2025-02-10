#!/usr/bin/env bash
# @file modules/service.sh
# @project MediaEase
# @version 1.0.32
# @description Contains a library of functions used in the MediaEase Project for managing services.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase
# systemd service files for applications within MediaEase.
# @notes Handles both single-user and multi-user service scenarios, and dynamically
# determines service names and configurations based on application needs and user settings.

# @function zen::service::generate
# @description Generates a systemd service file for an application.
# @arg $1 string The name of the application.
# @arg $2 bool Flag indicating if the service is for multiple users.
# @arg $3 bool Flag indicating if the service should be started immediately (optional).
# @global software_config_file Path to the software's configuration file.
# @stdout Creates a systemd service file for the application.
# @note Handles both single-user and multi-user service scenarios.
# shellcheck disable=SC2154
# Disabling SC2154 because the variable is defined in the main script
# @example
#    zen::service::generate "app_name" "false" "true"
zen::service::generate() {
	local app_name="$1"
	local is_child="$2"
	local start="$3"
	[[ -z "$start" ]] && start=true

	mflibs::shell::text::white "$(zen::i18n::translate "messages.service.generate" "$app_name")"
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
		directive=${directive//\{\{default_port\}\}/$default_port}
		directive=${directive//\{\{ssl_port\}\}/$ssl_port}
		if [[ "$directive" == User=* ]]; then
			for i in "${!service_content[@]}"; do
				if [[ "${service_content[i]}" == "User=%i" ]]; then
					service_content[i]="User=${directive#User=}"
				fi
			done
		elif [[ "$directive" == Group=* ]]; then
			for i in "${!service_content[@]}"; do
				if [[ "${service_content[i]}" == "Group=%i" ]]; then
					service_content[i]="Group=${directive#Group=}"
				fi
			done
		fi
		service_content+=("$directive")
	done

	if [[ "$is_multi" == "true" ]]; then
		service_content+=(
			""
			"[Install]"
			"WantedBy=multi-user.target"
		)
	fi

	# Write the content to the service file
	printf "%s\n" "${service_content[@]}" >"$service_file"
	mflibs::shell::text::green "$(zen::i18n::translate "success.service.generate_systemd" "$app_name" "$service_name")"
	mflibs::log "systemctl daemon-reload"
	# if not bypass_mode; then
	zen::service::manage "enable" "$service_name"
	# if no_start
	if [[ "$start" == true ]]; then
		zen::service::manage "start" "$service_name"
	fi
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
		mflibs::shell::text::yellow "$(zen::i18n::translate "messages.software.bypass_active" "$app_name")"
	fi
	export service_name
}

# @function zen::service::manage
# @description Manages the state of a systemd service.
# @arg $1 string The action to perform (start, stop, restart, enable, disable, status).
# @arg $2 string The name of the service to manage.
# @stdout Performs the specified action on the systemd service.
# @return Exits with a status code if an invalid action is provided.
# @note Wrapper around systemctl commands for service management.
# @return 0 if the service is successfully started, stopped, or restarted
# @return 1 if an invalid action is provided
# @example
#    zen::service::manage "start" "app_name.service"
zen::service::manage() {
	local action=$1
	local service_name=$2

	check_service_status() {
		if systemctl is-active --quiet "$service_name"; then
			mflibs::status::info "$(zen::i18n::translate "success.service.run" "$service_name")"
			return 0
		else
			mflibs::shell::text::red "$(zen::i18n::translate "errors.service.not_running" "$service_name")"
		fi
	}

	case $action in
	start)
		mflibs::status::info "$(zen::i18n::translate "messages.service.start" "$service_name")"
		if ! zen::service::manage "status" "$service_name"; then
			if systemctl start "$service_name"; then
				mflibs::status::success "$(zen::i18n::translate "success.service.start" "$service_name")"
			else
				mflibs::shell::text::red "$(zen::i18n::translate "errors.service.start" "$service_name")"
			fi
		fi
		;;
	stop)
		mflibs::status::info "$(zen::i18n::translate "messages.service.stop" "$service_name")"
		if zen::service::manage "status" "$service_name"; then
			if systemctl stop "$service_name"; then
				mflibs::status::success "$(zen::i18n::translate "success.service.stop" "$service_name")"
			else
				mflibs::shell::text::red "$(zen::i18n::translate "errors.service.stop" "$service_name")"
			fi
		fi
		;;
	restart | reload)
		mflibs::status::info "$(zen::i18n::translate "messages.service.${action}" "$service_name")"
		if systemctl "$action" "$service_name"; then
			mflibs::status::success "$(zen::i18n::translate "success.service.${action}" "$service_name")"
		else
			mflibs::shell::text::red "$(zen::i18n::translate "errors.service.$action" "$service_name")"
		fi
		;;
	enable)
		systemctl daemon-reload
		mflibs::status::info "$(zen::i18n::translate "messages.service.enable" "$service_name")"
		if systemctl enable "$service_name" --now >/dev/null 2>&1; then
			mflibs::status::success "$(zen::i18n::translate "success.service.enable" "$service_name")"
		else
			mflibs::shell::text::red "$(zen::i18n::translate "errors.service.enable" "$service_name")"
		fi
		;;
	disable)
		mflibs::status::info "$(zen::i18n::translate "messages.service.disable" "$service_name")"
		if systemctl stop "$service_name" && systemctl disable "$service_name"; then
			systemctl daemon-reload
			mflibs::status::success "$(zen::i18n::translate "success.service.disable" "$service_name")"
		else
			mflibs::shell::text::red "$(zen::i18n::translate "errors.service.disable" "$service_name")"
		fi
		;;
	status)
		check_service_status
		;;
	*)
		mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_action" "$action" "$service_name")"
		return 1
		;;
	esac
}

# @function zen::service::build::add_entry
# @description Adds an entry to the api_service associative array.
# @arg $1 string The key of the entry to add.
# @arg $2 string The value of the entry.
# @global api_service Associative array used for service configuration.
# @stdout Adds a key-value pair to the api_service associative array.
# @return 1 if the key already exists in the array, otherwise 0.
zen::service::build::add_entry() {
	local key="$1"
	local value="$2"

	if [[ -n "${api_service[$key]}" ]]; then
		mflibs::status::error "$(zen::i18n::translate "messages.service.entry_exists" "$key")"
	fi
	api_service["$key"]="$value"
}

# @function zen::service::validate
# @description Validates the api_service associative array and inserts data into the database.
# @arg $1 bool Flag indicating if the service is a child service.
# @arg $2 string The sanitized name of the application.
# @stdout Validates service configuration and inserts it into the database.
# @note Constructs JSON objects for service configuration and stores them in the database.
# @example
#    zen::service::validate "true" "app_name_sanitized"
zen::service::validate() {
	local is_child="$1"
	local app_name_sanitized="$2"
	mflibs::shell::text::white "$(zen::i18n::translate "messages.service.validate" "$app_name_sanitized")"
	local json_ports json_configuration application_id parent_service_id json_result

	# Assuming api_service[default_port] and api_service[ssl_port] contain simple strings or numbers
	json_ports=$(jq -n \
		--arg default_port "${api_service[default_port]:-0}" \
		--arg ssl_port "${api_service[ssl_port]:-0}" \
		'[{"default": ($default_port | tonumber), "ssl": ($ssl_port | tonumber)}]')
	# Configuration JSON
	json_configuration=$(jq -n \
		--arg data_path "${api_service[data_path]:-"none"}" \
		--arg backup_path "${api_service[backup_path]:-"none"}" \
		--arg caddyfile_path "${api_service[caddyfile_path]:-"none"}" \
		--arg root_url "${api_service[root_url]:-"none"}" \
		'[{"data_path": $data_path, "backup_path": $backup_path, "caddyfile_path": $caddyfile_path, "root_url": $root_url}]')
	# Application JSON
	application_id=$(zen::database::select "id" "application" "altname = '$app_name_sanitized'")
	application_id=$(echo "$application_id" | head -n 1)

	if [[ "$is_child" == "true" ]]; then
		parent_service_id=$(zen::database::select "id" "service" "id = (SELECT MAX(id) FROM service)")
	else
		parent_service_id="null"
	fi

	# Construct the final JSON
	json_result=$(jq -n \
		--arg name "${api_service[name]}" \
		--arg version "0.0.0" \
		--arg status "active" \
		--arg apikey "${api_service[apikey]}" \
		--arg user_id "${user[id]}" \
		--argjson ports "$json_ports" \
		--argjson configuration "$json_configuration" \
		--arg application_id "$application_id" \
		--arg parent_service_id "$parent_service_id" \
		'{
			"name": $name,
			"version": $version,
			"status": $status,
			"apikey": $apikey,
			"ports": $ports,
			"configuration": $configuration,
			"application_id": $application_id,
			"parent_service_id": $parent_service_id,
			"user_id": $user_id
		}')
	# Extract the individual fields from JSON except for JSON objects (ports and configuration)
	local name version status apikey application_id parent_service_id user_id

	read -r name version status apikey application_id parent_service_id user_id <<<"$(echo "$json_result" | jq -r '.name, .version, .status, .apikey, .application_id, .parent_service_id, .user_id')"

	# Escape single quotes in the string values
	name=${name//\'/\'\'}
	version=${version//\'/\'\'}
	status=${status//\'/\'\'}
	apikey=${apikey//\'/\'\'}
	application_id=${application_id//\'/\'\'}
	parent_service_id=${parent_service_id//\'/\'\'}
	user_id=${user_id//\'/\'\'}

	# Convert JSON objects to strings for SQL insertion
	ports=$(echo "$json_ports" | jq -c .)
	configuration=$(echo "$json_configuration" | jq -c .)

	# Call the zen::database::insert function
	zen::database::insert "service" "name, version, status, apikey, ports, configuration, application_id, parent_service_id, user_id" "'$name', '$version', '$status', '$apikey', '$ports', '$configuration', '$application_id', '$parent_service_id', '$user_id'"
	mflibs::shell::text::green "$(zen::i18n::translate "success.service.validate" "$app_name_sanitized")"
}
