#!/usr/bin/env bash
# @file modules/proxy.sh
# @project MediaEase
# @version 1.2.2
# @description Contains a library of functions used in the MediaEase Project for managing proxies.
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @function zen::proxy::generate
# Generates a Caddy proxy configuration file for an application.
# @description This function creates a Caddy configuration file for a specified application.
# It generates the configuration file based on the application name, port number, and base URL.
# The configuration will differ based on whether the application is in multi-user mode or not.
# @arg $1 string The name of the application.
# @arg $2 number The port on which the application is running.
# @arg $3 string The base URL for routing to the application.
# @arg $4 boolean Whether to reload Caddy after generating the configuration.
# @global software_config_file string The path to the software's configuration file, used to determine multi-user mode.
# @stdout Creates or overwrites a Caddy configuration file.
# @exitcode 0 Success.
# @exitcode 1 Failure due to directory creation errors or file writing errors.
# @caution Ensure the application name and port are correct to avoid misconfiguration.
# @important The Caddy configuration will be different in multi-user mode.
# shellcheck disable=SC2154
# Disabling SC2154 because the variable is defined in the main script
zen::proxy::generate() {
	local app_name="$1"
	local port="$2"
	local url_base="$3"
	local reload="${4:-true}"
	local caddy_file
	is_multi=$(zen::software::get_config_key_value "$software_config_file" '.arguments.multi_user')
	[[ ! -d "$(dirname "$caddy_file")" ]] && mkdir -p "$(dirname "$caddy_file")"
	if [ "$is_multi" == "true" ]; then
		caddy_file="/etc/caddy/softwares/${user[username]}.$app_name.caddy"
	else
		caddy_file="/etc/caddy/softwares/$app_name.caddy"
	fi
	[[ ! -d "$(dirname "$caddy_file")" ]] && mkdir -p "$(dirname "$caddy_file")"
	cat <<EOF >"${caddy_file}"
	route ${url_base}* {
		reverse_proxy 127.0.0.1:$port {
			header_up -Accept-Encoding
			header_down -x-webkit-csp
			header_down -content-security-policy
		}
	}
EOF
	mflibs::log "/usr/bin/caddy fmt --overwrite $caddy_file >/dev/null 2>&1"
	mflibs::log "/usr/bin/caddy validate -c /etc/caddy/Caddyfile >/dev/null 2>&1"
	if [ "$reload" == "true" ]; then
		mflibs::log "/usr/bin/caddy reload -c /etc/caddy/Caddyfile >/dev/null 2>&1"
	fi
}

# @function zen::proxy::add_directive
# Adds a directive to an application's Caddy proxy configuration.
# @description This function appends a new directive to the Caddy proxy configuration of a specified application.
# It is useful for adding custom rules or modifications to the existing proxy settings.
# @arg $1 string The name of the application.
# @arg $2 string The username associated with the application (used in multi-user mode).
# @arg $3 string The directive to be added to the proxy configuration.
# @arg $4 string The position at which to add the directive ('in', 'before', 'after') - Default 'in' (the reverse_proxy block).
# @arg $5 boolean Whether to reload Caddy after adding the directive - Default false.
# @global software_config_file string The path to the software's configuration file, used to determine the file location.
# @stdout Appends the specified directive to the application's Caddy configuration file.
# @exitcode 0 Success.
# @exitcode 1 Failure due to file access or append errors.
# @note Use this function to add custom rules like security headers or rate limiting.
zen::proxy::add_directive() {
	local app_name="$1"
	local username="$2"
	local directive="$3"
	local position="${4:-in}"
	local reload="${5:-false}"
	local caddy_file
	caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")
	case "$position" in
	in)
		awk -v dir="$directive" '
                /reverse_proxy.*{/ {
                    print; getline; print "    " dir; print; next
                }
                1' "$caddy_file" >"${caddy_file}.tmp"
		;;
	before)
		awk -v dir="$directive" '
                !inserted && /reverse_proxy/ {
                    print dir; inserted=1
                }
                {print}' "$caddy_file" >"${caddy_file}.tmp"
		;;
	after)
		awk -v dir="$directive" '
                /reverse_proxy.*{/ {print; in_block=1; next}
                in_block && /}/ {print; print dir; in_block=0; next}
                {print}' "$caddy_file" >"${caddy_file}.tmp"
		;;
	*)
		mflibs::status::error "$(zen::i18n::translate "errors.network.invalid_position" "$position" "'in', 'before', 'after'")"
		;;
	esac

	mv "${caddy_file}.tmp" "$caddy_file"

	if [ "$reload" == "true" ]; then
		mflibs::log "/usr/bin/caddy reload -c /etc/caddy/Caddyfile >/dev/null 2>&1"
	fi
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
# @caution Removing the proxy configuration will make the application inaccessible through the proxy.
zen::proxy::remove() {
	local app_name="$1"
	local username="$2"
	local caddy_file
	caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")
	[[ -f "$caddy_file" ]] && rm -f "$caddy_file"
}
