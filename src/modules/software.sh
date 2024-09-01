#!/usr/bin/env bash
# @file modules/software.sh
# @project MediaEase
# @version 1.0.0
# @description Contains a library of functions used in the MediaEase Project for managing software.
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::software::is::installed
# Checks if a specific software is installed for a given user.
# @description This function checks if a specific software is installed for a given user by querying the database.
# @arg $1 string Name (altname) of the software.
# @arg $2 string User ID to check the software installation for.
# @return 0 if the software is installed, 1 otherwise.
# @note Ensures both software name and user ID are provided; if user ID is '*', checks for any user.
# @example
#   zen::software::is::installed "software_name" "user_id"
# @example
#   [[ $(zen::software::is::installed "subsonic" 6) ]] && echo "yes" || echo "no"
zen::software::is::installed() {
	local software="$1"
	local user_id="$2"

	if [[ -z "$software" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.software.software_name_missing" "$software")"
	fi

	local select_clause="a.name, a.altname, GROUP_CONCAT(srv.name) as services, srv.application_id, GROUP_CONCAT(srv.ports) as ports, srv.user_id"
	local table_with_alias="application a"
	local inner_join_clause="service srv ON a.id = srv.application_id"
	local where_clause="a.altname = '${software}'"
	local additional_clauses=""

	if [[ "$user_id" != "*" ]]; then
		if [[ -z "$user_id" ]]; then
			mflibs::status::error "$(zen::i18n::translate "errors.user.user_id_missing")"
		fi
		additional_clauses="AND srv.user_id = ${user_id} "
	fi

	additional_clauses+="GROUP BY srv.user_id;"
	local distinct_flag="1"
	zen::database::select::inner_join "$select_clause" "$table_with_alias" "$inner_join_clause" "$where_clause" "$additional_clauses" "$distinct_flag"
}

# @function zen::software::port_randomizer
# Generates a random port number within a specified range for an application.
# @description This function generates a random port number within a specified range for an application, checking if the port is available.
# @arg $1 string Name of the application.
# @arg $2 string Type of port to generate (default, ssl).
# @return A randomly selected port number within the specified range.
# @example
#   zen::software::port_randomizer "app_name" "port_type"
# @note If 'port_range' is specified as the port type, a range of ports is generated.
zen::software::port_randomizer() {
	local app_name="$1"
	local port_type="$2"
	local port_range
	local port_low
	local port_high
	local retries=10
	local interval=1500
	local use_range=false
	if [[ "$port_type" == "port_range" ]]; then
		use_range=true
		port_type="default"
	fi

	port_range=$(yq e ".arguments.ports[] | select(.${port_type} != null) | .${port_type}" "$software_config_file")
	if [[ -z "$port_range" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.network.port_range_missing" "$app_name")"
	fi

	port_low=$(echo "$port_range" | tr -d '[]' | cut -d'-' -f1)
	port_high=$(echo "$port_range" | tr -d '[]' | cut -d'-' -f2)

	if [[ "$use_range" == true ]]; then
		while ((retries > 0)); do
			local start_port=$((port_low + RANDOM % ((port_high - port_low + 1) - interval)))
			local end_port=$((start_port + interval))

			local range_is_free=true
			for ((port = start_port; port <= end_port; port++)); do
				if netstat -tuln | grep -q ":$port "; then
					range_is_free=false
					break
				fi
			done

			if [[ "$range_is_free" == true ]]; then
				echo "${start_port}-${end_port}"
				return 0
			fi

			((retries--))
		done

		mflibs::status::error "$(zen::i18n::translate "errors.network.port_in_use" "$app_name")"
	else
		while ((retries > 0)); do
			local port=$((port_low + RANDOM % (port_high - port_low + 1)))
			if ! netstat -tuln | grep -q ":$port "; then
				echo "$port"
				return 0
			fi
			((retries--))
		done

		mflibs::status::error "$(zen::i18n::translate "errors.network.port_in_use" "$app_name")"
	fi
}

# @function zen::software::infobox
# Builds the header or footer for the software installer.
# @description This function builds the header or footer for the software installer, displaying relevant information.
# @arg $1 string Name of the application.
# @arg $2 string Color to use for the text.
# @arg $3 string Action being performed (add, update, backup, reset, remove, reinstall).
# @arg $4 string "intro" for header, "outro" for footer.
# @arg $5 string (optional) Username to display in the infobox.
# @arg $6 string (optional) Password to display in the infobox.
# @example
#   zen::software::infobox "app_name" "shell_color" "action" "infobox_type"
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
		local random_index=$((RANDOM % ${#colors[@]}))
		shell="${colors[random_index]}"
		;;
	esac

	case "$infobox_type" in
	intro)
		case "$action" in
		add | update | backup | reset | remove | reinstall)
			translated_string=$(zen::i18n::translate "headers.software.$action" "$app_name_sanitized")
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
		add | update | backup | reset | remove | reinstall)
			outro=$(zen::i18n::translate "footers.software.$action" "$app_name_sanitized")
			# shellcheck disable=SC2154
			[ "$action" != "remove" ] && access_link=$(zen::i18n::translate "links.software.access_url" "$app_name_sanitized" "$url_base")
			[ "$action" != "remove" ] && docs_link=$(zen::i18n::translate "links.software.documentation" "$app_name_sanitized" "$url_base")
			[ "$action" != "remove" ] && mediaease_link=$(zen::i18n::translate "links.software.mediaease" "$app_name_sanitized" "$url_base")
			[ "$action" != "remove" ] && homepage_link=$(zen::i18n::translate "links.software.homepage" "$app_name_sanitized" "$url_base")
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
		printf "Invalid infobox type specified %s\n" "$infobox_type"
		mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_infobox_type" "$infobox_type")"
		;;
	esac
	printf "\n"
}

# @function zen::software::options::process
# Processes software options from a comma-separated string.
# @description This function processes software options from a comma-separated string, exporting variables for further use.
# @arg $1 string String of options in "option1=value1,option2=value2" format.
# @note Variables are exported and used in other functions.
# shellcheck disable=SC2034
# Disable SC2034 because the variables are exported and used in other functions
# @example
#   zen::software::options::process "branch=beta,email=test@example.com"
zen::software::options::process() {
	local options="$1"
	software_branch="" software_email="" software_domain="" software_key=""

	IFS=',' read -ra options_array <<<"$options"
	for option in "${options_array[@]}"; do
		IFS='=' read -ra option_array <<<"$option"
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
			mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_option" "$option_name")"
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

# @function zen::software::backup::create
# Handles the creation of software backups.
# @description This function handles the creation of software backups, ensuring the backup directory exists and backing up specified files.
# @arg $1 string Name of the application.
# @note Variable is defined in the main script.
# shellcheck disable=SC2154
# Disable SC2154 because the variables are exported and used in other functions
# @example
#   zen::software::backup::create "app_name"
zen::software::backup::create() {
	local app_name="$1"
	local backup_dir="/home/${user[username]}/.mediaease/backups/$app_name"
	backup_file="$backup_dir/$app_name-$(date +%Y%m%d-%H%M%S).tar.gz"
	mkdir -p "$backup_dir"

	local files_to_backup=()
	readarray -t files_to_backup < <(yq e ".arguments.files[].*" "$software_config_file" | sed "s/%i/${user[username]}/g; s/\$app_name/$app_name/g")

	if [ ${#files_to_backup[@]} -eq 0 ]; then
		mflibs::status::error "$(zen::i18n::translate "errors.backup.no_backup_files" "$app_name")"
	fi

	mflibs::shell::text::white "$(zen::i18n::translate "headers.backup.create" "$app_name")"
	if tar -czf "$backup_file" "${files_to_backup[@]}" >/dev/null 2>&1; then
		mflibs::shell::text::green "$(zen::i18n::translate "success.backup.create" "$backup_file")"
	else
		mflibs::status::error "$(zen::i18n::translate "errors.backup.no_backup_files" "$app_name")"
	fi
}

# @function zen::software::get_config_key_value
# Retrieves a key/value from a YAML configuration file.
# @description This function retrieves a key/value from a YAML configuration file using a specified 'yq' expression.
# @arg $1 string Path to the YAML configuration file.
# @arg $2 string 'yq' expression to evaluate in the configuration file.
# @return The value of the specified key or expression.
# @example
#   zen::software::get_config_key_value "config_file_path" "yq_expression"
# @note This function will replace placeholders '%i' and '$app_name' with actual values.
zen::software::get_config_key_value() {
	local software_config_file="$1"
	local yq_expression="$2"
	local username="$3"
	local app_name="$4"

	if [[ -z "$software_config_file" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.software.config_file_missing")"
	fi

	if [[ ! -f "$software_config_file" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.software.config_file_missing")"
	fi

	local key_value
	key_value=$(yq e "$yq_expression" "$software_config_file")
	if [[ -z "$key_value" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.software.config_syntax_invalid" "$yq_expression")"
	fi

	key_value="${key_value//%i/$username}"
	key_value="${key_value//\$app_name/$app_name}"

	echo "$key_value"
	return 0
}

# @function zen::software::autogen
# Automatically generates random values for specified keys.
# @description This function automatically generates random values for specified keys, such as API keys, ports, and passwords.
# @note Variables are exported and used in other functions.
# shellcheck disable=SC2034
# Disable SC2034 because the variables are exported and used in other functions
# @example
#   zen::software::autogen
zen::software::autogen() {
	local autogen_keys
	readarray -t autogen_keys < <(yq e ".arguments.autogen[]" "$software_config_file")

	for key in "${autogen_keys[@]}"; do
		case "$key" in
		apikey)
			declare -g apikey
			apikey=$(
				head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32
				echo ''
			)
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
		port_range)
			declare -g port_range
			port_range=$(zen::software::port_randomizer "$app_name" "port_range")
			;;
		*)
			mflibs::status::error "$(zen::i18n::translate "errors.software.autogen_key_invalid" "$key")"
			;;
		esac
	done

	for var in apikey ssl_port default_port password; do
		if [[ -n "${!var}" ]]; then
			export "${var?}"
		fi
	done
}

# @function zen::software::create
# @description Prompts the user for details to create a new software entry.
# @stdout Collects software details and creates the software entry.
# shellcheck disable=SC2154
# Disable SC2154 because the variables are exported and used in other functions
# @example
#   zen::software::create
zen::software::create() {
	mflibs::shell::text::white "$(zen::i18n::translate "headers.software.create_entry")"
	zen::prompt::input "$(zen::i18n::translate "prompts.software.name")" "" software_name
	if [[ -z "$software_name" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.software.software_name_missing" "$software_name")"
	fi
	software_name_sanitized=$(zen::common::capitalize::first "$software_name")
	software_name_lowered=$(zen::common::lowercase "$software_name")
	zen::prompt::input "$(zen::i18n::translate "prompts.software.category_group")" "" group
	zen::prompt::input "$(zen::i18n::translate "prompts.software.repo_url")" "github" software_repo
	zen::prompt::input "$(zen::i18n::translate "prompts.software.docs_url")" "url" software_docs
	zen::prompt::input "$(zen::i18n::translate "prompts.software.homepage_url")" "url" homepage
	zen::prompt::yn "$(zen::i18n::translate "prompts.software.is_multi_user")" multi_user
	zen::prompt::yn "$(zen::i18n::translate "prompts.software.uses_port")" use_port
	if [[ "$use_port" == "yes" ]]; then
		zen::prompt::input "$(zen::i18n::translate "prompts.software.use_random_port")" "" use_random_port
		if [[ "$use_random_port" == "yes" ]]; then
			zen::prompt::input "$(zen::i18n::translate "prompts.software.port_range")" "port_range" port_range
			zen::prompt::input "$(zen::i18n::translate "prompts.software.ssl_port_range")" "port_range" ssl_port_range
		else
			zen::prompt::input "$(zen::i18n::translate "prompts.software.default_port")" "numeric" default_port
			zen::prompt::input "$(zen::i18n::translate "prompts.software.ssl_port")" "numeric" ssl_port
		fi
	fi
	zen::prompt::yn "$(zen::i18n::translate "prompts.software.uses_service")" use_service
	if [[ "$use_service" == "yes" ]]; then
		zen::prompt::input "$(zen::i18n::translate "prompts.software.service_directives")" "" service_directives
	fi
	zen::prompt::yn "$(zen::i18n::translate "prompts.software.compatible_with_autogen")" use_autogen
	if [[ "$use_autogen" == "yes" ]]; then
		declare -a autogen_keys
		declare -a selected_autogen_keys
		declare -a selected_autogen_keys_yaml
		autogen_keys=("Api Key" "SSL Port" "Default Port" "Password" "Port Range")
		selected_autogen_keys=()
		zen::prompt::multi_select "$(zen::i18n::translate "prompts.software.select_autogen_keys")" selected_autogen_keys autogen_keys[@]
		selected_autogen_keys_yaml=()
		for key in "${selected_autogen_keys[@]}"; do
			mapfile -t autogen_key_array <<<"$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')"
			selected_autogen_keys_yaml+=("${autogen_key_array[@]}")
		done
	fi

	# Generate the software entry
	software_dir="/opt/MediaEase/MediaEase/zen/src/software/experimental/$software_name_lowered"
	mflibs::dir::mkcd "$software_dir"
	cat <<EOL >"$software_dir/config.yaml"
arguments:
  app_name: $software_name_sanitized
  altname: $software_name_lowered
  description: $software_name_lowered._description
  pro_only: true
  logo_path: $software_name_lowered.png
  group: $group
  details:
    docs: $software_docs
    github: $software_repo
    homepage: $homepage
  multi_user: $([ "$multi_user" == "yes" ] && echo "true" || echo "false")
  ports:
    - default: ${port_range:-"12001-13999"}
    - ssl: ${ssl_port_range:-"35001-35999"}
  service_directives:
    - ${service_directives//, / }
  files:
    - service: /etc/systemd/system/$software_name_lowered@.service
    - proxy: /etc/caddy/softwares/%i.$software_name_lowered.caddy
  paths:
    - backup: /home/%i/.mediaease/backups/$software_name_lowered
    - data: /home/%i/.config/$software_name_lowered
    - install: /opt/%i/$software_name_sanitized
  autogen:
    - ${selected_autogen_keys_yaml[@]}
EOL
	convert -background none -resize 128x128 "/opt/MediaEase/MediaEase/zen/src/extras/templates/app_logo.png" "$software_dir/$software_name_lowered.png"
	cp -pR /opt/MediaEase/MediaEase/zen/src/extras/templates/app_script.tpl "$software_dir/$software_name_lowered"
	sed -i "s/{{ SOFTWARE_NAME }}/$software_name_sanitized/g; s/{{ SOFTWARE_NAME_LOWERED }}/$software_name_lowered/g" "$software_dir/$software_name_lowered"
	declare -A translation_files
	for file in /opt/MediaEase/MediaEase/HarmonyUI/translations/messages.*.yaml; do
		local string="$software_name_lowered._description"
		yq e ".\"$string\" = \"Placeholder to describe $software_name_lowered\"" "$file" -i
		translation_files["$file"]="updated"
	done
	cd /srv/harmonyui || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.directory_change" "/srv/harmonyui")"
	username="$(zen::database::select "username" "users" "roles LIKE '%ROLE_ADMIN%'")"
	su -c "symfony console harmony:scan:apps" "$username"
	mflibs::shell::text::yellow "################################################################################"
	mflibs::shell::text::yellow "# $(zen::i18n::translate "success.software.create" "$software_name_sanitized")"
	mflibs::shell::text::yellow "# $(zen::i18n::translate "messages.software.find_generated_files" "$software_dir")"
	mflibs::shell::text::yellow "# $(zen::i18n::translate "messages.software.generated_files" "$software_dir/config.yaml" "$software_dir/$software_name_lowered")"
	mflibs::shell::text::yellow "# $(zen::i18n::translate "messages.software.update_configuration")"
	mflibs::shell::text::yellow "# $(zen::i18n::translate "messages.software.warn_about_translation_files")"
	mflibs::shell::text::yellow "# $(zen::i18n::translate "messages.software.update_translation_files")"
	for file in "${!translation_files[@]}"; do
		mflibs::shell::text::yellow "# - $file"
	done
	mflibs::shell::text::yellow "# "
	mflibs::shell::text::yellow "$(zen::i18n::translate "messages.software.learn_more")"
	mflibs::shell::text::yellow "# https://mediaease.github.io/docs/mediaease/components/zen/README.md"
	mflibs::shell::text::yellow "################################################################################"
}
