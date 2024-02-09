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
# @description Generates a Caddy proxy configuration file for an application.
# @arg $1 string The name of the application.
# @arg $2 number The port on which the application is running.
# @arg $3 string The base URL for routing to the application.
# @global software_config_file string Path to the software's configuration file.
# @stdout Creates or overwrites a Caddy configuration file.
# @note Checks if the application is multi-user; adjusts file path and headers.
# shellcheck disable=SC2154
# Disabling SC2154 because the variable is defined in the main script
################################################################################
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
    cat <<EOF > "${caddy_file}"
route ${url_base}/* {
    reverse_proxy 127.0.0.1:$port {
        header_up -Accept-Encoding
        header_down -x-webkit-csp
        header_down -content-security-policy
    }
}
EOF
}

# @function zen::proxy::add_directive
# @description Adds a directive to an application's Caddy proxy configuration.
# @arg $1 string The name of the application.
# @arg $2 string The username associated with the application (multi-user mode).
# @arg $3 string The directive to be added to the proxy configuration.
# @global software_config_file string Path to the software's configuration file.
# @stdout Appends the directive to the application's proxy configuration file.
zen::proxy::add_directive() {
    local app_name="$1"
    local username="$2"
    local directive="$3"
    local caddy_file
    caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")

    # Append the directive to the file
    echo "$directive" >> "${caddy_file}"
}

# @function zen::proxy::remove
# @description Removes the proxy configuration file for a specified application.
# @arg $1 string The name of the application.
# @arg $2 string The username associated with the application (multi-user mode).
# @global software_config_file string Path to the software's configuration file.
# @stdout Deletes the Caddy configuration file for the specified application.
zen::proxy::remove() {
    local app_name="$1"
    local username="$2"
    local caddy_file
    caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")
    [[ -f "$caddy_file" ]] && rm -f "$caddy_file"
}
