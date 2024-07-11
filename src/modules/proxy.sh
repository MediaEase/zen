#!/usr/bin/env bash
# @file modules/proxy.sh
# @project MediaEase
# @version 1.0.0
# @description Contains a library of functions used in the MediaEase Project for managing proxies.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::proxy::generate
# Generates a Caddy proxy configuration file for an application.
# @description This function creates a Caddy configuration file for a specified application.
# It generates the configuration file based on the application name, port number, and base URL.
# The configuration will differ based on whether the application is in multi-user mode or not.
# @arg $1 string The name of the application.
# @arg $2 number The port on which the application is running.
# @arg $3 string The base URL for routing to the application.
# @global software_config_file string The path to the software's configuration file, used to determine multi-user mode.
# @stdout Creates or overwrites a Caddy configuration file.
# @exitcode 0 Success.
# @exitcode 1 Failure due to directory creation errors or file writing errors.
# shellcheck disable=SC2154
# Disabling SC2154 because the variable is defined in the main script
zen::proxy::generate() {
	local app_name="$1"
	local port="$2"
	local url_base="$3"
	local caddy_file
	is_multi=$(zen::software::get_config_key_value "$software_config_file" '.arguments.multi_user')
	[[ ! -d "$(dirname "$caddy_file")" ]] && mkdir -p "$(dirname "$caddy_file")"
	if [ "$is_multi" == "true" ]; then
		caddy_file="/etc/caddy/softwares/${user[username]}.$app_name.caddy"
	else
		caddy_file="/etc/caddy/softwares/$app_name.caddy"
	fi
	[[ ! -d "$(dirname "$caddy_file")" ]] && mkdir -p "$(dirname "$caddy_file")"
	# Write configuration to the file
	cat <<EOF >"${caddy_file}"
	route ${url_base}* {
		reverse_proxy 127.0.0.1:$port {
			header_up -Accept-Encoding
			header_down -x-webkit-csp
			header_down -content-security-policy
		}
	}
EOF
}

# @function zen::proxy::add_directive
# Adds a directive to an application's Caddy proxy configuration.
# @description This function appends a new directive to the Caddy proxy configuration of a specified application.
# It is useful for adding custom rules or modifications to the existing proxy settings.
# @arg $1 string The name of the application.
# @arg $2 string The username associated with the application (used in multi-user mode).
# @arg $3 string The directive to be added to the proxy configuration.
# @global software_config_file string The path to the software's configuration file, used to determine the file location.
# @stdout Appends the specified directive to the application's Caddy configuration file.
# @exitcode 0 Success.
# @exitcode 1 Failure due to file access or append errors.
zen::proxy::add_directive() {
	local app_name="$1"
	local username="$2"
	local directive="$3"
	local caddy_file
	caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")

	# Append the directive to the file
	echo "$directive" >>"${caddy_file}"
}

# @function zen::proxy::remove
# Removes the proxy configuration file for a specified application.
# @description This function deletes the Caddy proxy configuration file associated with a given application.
# It's used when an application's proxy is no longer needed or when the application is being uninstalled or moved.
# @arg $1 string The name of the application.
# @arg $2 string The username associated with the application (used in multi-user mode).
# @global software_config_file string The path to the software's configuration file, used to determine the file location.
# @stdout Deletes the Caddy configuration file for the specified application.
# @exitcode 0 Success.
# @exitcode 1 Failure due to file not found or deletion errors.
zen::proxy::remove() {
	local app_name="$1"
	local username="$2"
	local caddy_file
	caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")
	[[ -f "$caddy_file" ]] && rm -f "$caddy_file"
}
