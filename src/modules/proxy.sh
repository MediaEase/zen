#!/usr/bin/env bash
################################################################################
# @file_name: proxy.sh
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
# zen::proxy::generate
#
# Generates a Caddy proxy configuration file for a specified application. This
# function creates a configuration file that routes requests to the application
# running on a given port.
#
# Arguments:
#   app_name - The name of the application for which the proxy is being configured.
#   port - The port number on which the application is running.
#   url_base - The base URL for routing to the application.
# Globals:
#   software_config_file - Global variable containing the path to the software's
#                          configuration file.
# Outputs:
#   Creates or overwrites a Caddy configuration file for the application.
# Notes:
#   The function checks if the application is multi-user and adjusts the file path
#   accordingly. It disables certain headers for proper reverse proxy functionality.
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

################################################################################
# zen::proxy::add_directive
#
# Adds a specific directive to the Caddy proxy configuration file of an
# application. This allows for customizing the proxy settings for individual
# applications.
#
# Arguments:
#   app_name - The name of the application.
#   username - The username associated with the application (used in multi-user mode).
#   directive - The directive to be added to the proxy configuration.
# Globals:
#   software_config_file - Global variable containing the path to the software's
#                          configuration file.
# Outputs:
#   Appends the specified directive to the application's proxy configuration file.
################################################################################
zen::proxy::add_directive() {
    local app_name="$1"
    local username="$2"
    local directive="$3"
    local caddy_file
    caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")

    # Append the directive to the file
    echo "$directive" >> "${caddy_file}"
}

################################################################################
# zen::proxy::remove
#
# Removes the proxy configuration file for a specified application. This is typically
# used when an application is uninstalled or when its proxy configuration is no longer needed.
#
# Arguments:
#   app_name - The name of the application.
#   username - The username associated with the application (used in multi-user mode).
# Globals:
#   software_config_file - Global variable containing the path to the software's
#                          configuration file.
# Outputs:
#   Deletes the Caddy configuration file for the specified application.
################################################################################
zen::proxy::remove() {
    local app_name="$1"
    local username="$2"
    local caddy_file
    caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")
    [[ -f "$caddy_file" ]] && rm -f "$caddy_file"
}
