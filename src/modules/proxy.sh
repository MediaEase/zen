#!/usr/bin/env bash

################################################################################
# @description: Generates a proxy configuration file for a given application.
# @arg: $1: app_name - The name of the application.
# @arg: $2: port - The port number the application is running on.
# @arg: $3: url_base - The base URL for the application.
# shellcheck disable=SC2154
# @disable reason : build entries variables are global variables and are created in other functions
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
# @description: Adds a directive to a proxy configuration file.
# @arg: $1: app_name - The name of the application.
# @arg: $2: username - The username associated with the application.
# @arg: $3: directive - The directive to add to the configuration file.
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
# @description: Removes a proxy configuration file for a given application.
# @arg: $1: app_name - The name of the application.
# @arg: $2: username - The username associated with the application.
################################################################################
zen::proxy::remove() {
    local app_name="$1"
    local username="$2"
    local caddy_file
    caddy_file=$(zen::software::get_config_key_value "$software_config_file" '.arguments.files[] | select(has("proxy")).proxy' "${user[username]}" "$app_name")
    [[ -f "$caddy_file" ]] && rm -f "$caddy_file"
}
