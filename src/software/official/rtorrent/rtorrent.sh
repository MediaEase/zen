#!/usr/bin/env bash
# @file software/rtorrent/rtorrent.sh
# @version: 1.0.0
# @project MediaEase
# @description rTorrent handler
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::software::rtorrent::add
# @description Adds a rTorrent for a user, including downloading, configuring, and starting the service.
# @global software_config_file Path to the software's configuration file.
# @global user An associative array containing user-specific information.
# @note Disables SC2154 because the variable is defined in the main script.
# shellcheck disable=SC2154
#zen::common::git::download_file "/tmp/libtorrent-rakshasa_0.9.8.deb" "MediaEase/binaries" "main" "dist/current/libtorrent-rakshasa_0.9.8.deb"
# zen::common::git::download_file "/tmp/rtorrent_0.9.8.deb" "MediaEase/binaries" "main" "dist/current/rtorrent_0.9.8.deb"
# zen::common::git::download_file "/tmp/xmlrpc-c_1.51.0.deb" "MediaEase/binaries" "main" "dist/current/xmlrpc-c_1.51.0.deb"
zen::software::rtorrent::add() {
    if [[ ! -d "/srv/rutorrent" ]]; then
        # download latest precompiled release
        rtorrent_binaries=("xmlrpc-c" "libtorrent-rakshasa" "rtorrent")
        repo_files=$(zen::common::git::tree "MediaEase/binaries" "main" "dist/current")
        while IFS= read -r file; do
            for binary in "${rtorrent_binaries[@]}"; do
                if [[ $file == *"$binary"* ]]; then
                    if [[ $file == *"0.9.8"* || $file == *"xmlrpc-c"* ]]; then
                        zen::common::git::download_file "/tmp/$file" "$repo_name" "$remote_path/$file"
                    fi
                fi
            done
        done <<<"$repo_files"
        for binary in "xmlrpc-c" "libtorrent-rakshasa" "rtorrent"; do
            for deb_file in /tmp/*; do
                if [[ $deb_file == *"$binary"* ]]; then
                    mflibs::shell::text::yellow "$(zen::i18n::translate "software.unpacking_deb_file" "$deb_file")"
                    if sudo dpkg -i "$deb_file"; then
                        mflibs::shell::text::green "$(zen::i18n::translate "software.deb_file_installed" "$deb_file")"
                    else
                        mflibs::shell::text::error "$(zen::i18n::translate "software.deb_file_install_failed" "$deb_file")"
                    fi
                fi
            done
        done
    fi
    # configure the app. This will  also generate the proxy file
    zen::software::rtorrent::config
    # generate the service file, this will also start it
    zen::service::generate "$app_name" "false" "true"
    # create a backup file
    zen::software::backup::create "$app_name" "$software_config_file"
}

################################################################################
# @function zen::software::rtorrent::config
# @description Configures rTorrent for a user, including setting up configuration files and proxy settings.
# @global user An associative array containing user-specific information.
zen::software::rtorrent::config() {
    mflibs::shell::text::white "$(zen::i18n::translate "software.configuring_application" "$app_name")"
    zen::software::autogen
    mkdir -p "/home/${user[username]}/.config/${app_name}"
    cp -pR "/opt/MediaEase/scripts/src/software/official/rtorrent/.rtorrent.rc.tpl" "/home/${user[username]}/.config/${app_name}/.rtorrent.rc"
    cp -pR "/opt/MediaEase/scripts/src/software/official/rtorrent/.rtorrent.rc.tpl" "/home/${user[username]}/.rtorrent.rc"
    # configure the rtorrent.rc file
    sed -i -e "s|{{USERNAME}}|${user[username]}|g" \
        -e "s|{{PORT_RANGE}}|${port_range}|g" \
        "/home/${user[username]}/.config/${app_name}/.rtorrent.rc"
    mkdir -p "/home/${user[username]}/download-clients/rtorrent/{downloads,log,.session,.watch}"
    # generate the proxy configuration
    zen::common::fix::permissions "/home/${user[username]}/.config/${app_name}" "${user[username]}" "${user[username]}" "755" "644"
    # we can't use the zen::proxy::generate function because rtorrent is a bit different
    zen::software::rtorrent::proxy::generate "/etc/caddy/softwares/${user[username]}.scgi.caddy"

    mflibs::shell::text::green "$(zen::i18n::translate "software.application_configured" "$app_name")"
}

# @function zen::software::rtorrent::update
# @description Updates rTorrent for a user, including stopping the service, downloading the latest release, and restarting.
# @global user An associative array containing user-specific information.
# @global software_config_file Path to the software's configuration file.
zen::software::rtorrent::update() {
    local service_name
    is_multi=$(zen::software::get_config_key_value "$software_config_file" '.arguments.multi_user')
    [ "$is_multi" == "true" ] && service_name="$app_name@${user[username]}.service" || service_name="$app_name.service"
    zen::service::manage "stop" "$service_name"
    rm -rf "/opt/${user[username]}/$app_name"
    is_prerelease="false"
    [[ "$software_branch" == "beta" ]] && is_prerelease="true"
    # grab the correct release
    zen::common::git::get_release "/opt/${user[username]}/$app_name" "rTorrent/rTorrent" "$is_prerelease" "linux-core-x64.tar.gz"
    zen::service::manage "start" "$service_name"
}

# @function zen::software::rtorrent::proxy::generate
# @description Generates the Caddy proxy configuration for rTorrent.
# @global user An associative array containing user-specific information.
# @global software_config_file Path to the software's configuration file.
zen::software::rtorrent::proxy::generate() {
    local caddy_file
    # Write configuration to the file
    cat <<EOF >"${caddy_file}"
	route {
        # SCGI Configuration for rTorrent
        @scgi {
            path /{{USERNAME}}/*
        }
        reverse_proxy @scgi unix//var/run/{{USERNAME}}/.rtorrent.sock {
            transport http {
                dial_timeout 10s
                read_timeout 30s
                write_timeout 30s
            }
        }
        basicauth {
            /{{USERNAME}}/* {
                file /etc/htpasswd.d/htpasswd.{{USERNAME}}
            }
        }

        # Download Index Configuration
        @downloads {
            path /{{USERNAME}}.rtorrent.downloads*
        }
        root @downloads /home/{{USERNAME}}/torrents/rtorrent
        file_server @downloads browse
        basicauth {
            /{{USERNAME}}.rtorrent.downloads* {
                file /etc/htpasswd.d/htpasswd.{{USERNAME}}
            }
        }

        @phpDownloads {
            path /{{USERNAME}}.rtorrent.downloads/*.php
        }
        php_fastcgi @phpDownloads unix//run/php/php8.1-fpm.sock
    }
EOF
    sed -i -e "s|{{USERNAME}}|${user[username]}|g" "${caddy_file}"
}

# @function zen::software::rtorrent::remove
# @description Removes rTorrent for a user, including disabling and deleting the service and cleaning up files.
# @global user An associative array containing user-specific information.
zen::software::rtorrent::remove() {
    local service_name
    is_multi=$(zen::software::get_config_key_value "$software_config_file" '.arguments.multi_user')
    [ "$is_multi" == "true" ] && service_name="$app_name@${user[username]}.service" || service_name="$app_name.service"

    zen::service::manage "disable" "$service_name"
    rm -f "$service_file"
    zen::proxy::remove "$app_name" "${user[username]}"
    rm -rf /opt/"${user[username]}"/"$app_name"
    rm -rf /home/"${user[username]}"/.config/"$app_name"
    rm -rf /home/"${user[username]}"/tmp/"$app_name"
}
