#!/usr/bin/env bash
# @file software/rutorrent/rutorrent.sh
# @version: 1.0.0
# @project MediaEase
# @description ruTorrent handler
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::software::rutorrent::add
# @description Adds a ruTorrent for a user, including downloading, configuring, and staruting the service.
# @global software_config_file Path to the software's configuration file.
# @global user An associative array containing user-specific information.
# @note Disables SC2154 because the variable is defined in the main script.
# shellcheck disable=SC2154
zen::software::rutorrent::add() {
    local plugins
    local all_users
    # build rutorrent only if the software is not installed by other users
    if [[ $is_installed_by_others -eq 0 ]]; then
        zen::common::git::clone "Novik/ruTorrent.git" "/srv/rutorrent" "main" "true"
        # configure rutorrent main settings
        mflibs::status::info "$(zen::i18n::translate "software.configuring" "ruTorrent")"
        sed -i -e "s|//\$topDirectory = '/';|\$topDirectory = '/home/${user[username]}';|g" \
            -e "s|\$scgi_host = \"127.0.0.1\";|\$scgi_host = \"unix:///tmp/${user[username]}.rtorrent.socket\";|g" \
            -e "s|\$scgi_port = 5000;|\$scgi_port = 0;|g" \
            -e "s|\$localHostedMode = false;|\$localHostedMode = true;|g" \
            "/srv/rutorrent/conf/config.php"
        mflibs::status::success "$(zen::i18n::translate "software.configured" "ruTorrent")"
        zen::software::rutorrent::plugins::resolve
        zen::software::rutorrent::fix::quota
    else
        mflibs::status::info "$(zen::i18n::translate "software.already_installed_by_others" "ruTorrent")"
        zen::software::rutorrent::fix::quota
    fi
}

# @function zen::software::rutorrent::plugins::resolve
# @description Resolves the ruTorrent plugins by downloading and configuring them.
# @global is_installed_by_others Boolean flag indicating if the software is installed by other users.
# @global user An associative array containing user-specific information.
# @global software_config_file Path to the software's configuration file.
# @global sqlite3_db Path to the SQLite3 database file.
# @stdout Outputs the status of the plugin configuration.
# @exitcode 0 Success.
# @exitcode 1 Failure due to plugin download or configuration errors.
zen::software::rutorrent::plugins::resolve() {
    if ! $is_installed_by_others; then
        mflibs::status::info "$(zen::i18n::translate "software.configuring" "ruTorrent plugins")"
        rm -rf "/srv/rutorrent/plugins/{filemanager, ratiocolor, geoip2, fileshare, pausewebui, filemanager, mobile, rutorrent-discord}"
        local plugins
        plugins=(
            "Ardakilic/rutorrent-pausewebui"
            "autodl-community/autodl-rutorrent"
            "Gyran/rutorrent-ratiocolor"
            "katlogic/rutorrent-login"
            "Micdu70/geoip2-rutorrent"
            "Micdu70/rutorrent-trackerstatus"
            "nelu/rutorrent-fileshare"
            "nelu/rutorrent-filemanager"
            "nelu/rutorrent-filemanager-share"
            "radonthetyrant/rutorrent-discord"
            "wimleers/rutorrent-stats"
            "xombiemp/rutorrentMobile"
        )
        for plugin in "${plugins[@]}"; do
            local plugin_name
            plugin_name=$(echo "$plugin" | cut -d'/' -f2 | sed 's/^rutorrent-//')
            if [[ -d "/srv/rutorrent/plugins/$plugin_name" ]]; then
                rm -rf "/srv/rutorrent/plugins/$plugin_name"
            fi
            zen::common::git::clone "$plugin" "/srv/rutorrent/plugins/$plugin_name" "main"
        done
        # configure rutorrent plugins
        cp -pR "/srv/rutorrent/plugins/diskspace/action.php" "/srv/rutorrent/plugins/diskspace/action.php.bak"
        cp -pR "/opt/MediaEase/scripts/src/software/official/rutorrent/diskspace-plugin/action.tpl" "/srv/rutorrent/plugins/diskspace/action.php"
        # configure ratio color plugin
        sed -i "s/changeWhat = \"cell-background\";/changeWhat = \"font\";/g" /srv/rutorrent/plugins/ratiocolor/init.js
        # configure create plugin
        sed -i -e 's/useExternal = false;/useExternal = "mktorrent";/' \
            -e 's/pathToCreatetorrent = '\'''\''/pathToCreatetorrent = '\''\/usr\/bin\/mktorrent'\''/' \
            "/srv/rutorrent/plugins/create/conf.php"
        # configure spectrogram plugin
        sed -i "s/\$pathToExternals\['sox'\] = ''/\$pathToExternals\['sox'\] = '\/usr\/bin\/sox'/g" /srv/rutorrent/plugins/spectrogram/conf.php
    fi
    mflibs::status::success "$(zen::i18n::translate "software.configured" "ruTorrent plugins")"
}

# @function zen::software::rutorrent::fix::quota
# @description Fixes the quota issue for ruTorrent.
# @global sqlite3_db Path to the SQLite3 database file.
# @global user An associative array containing user-specific information.
# @stdout Outputs the status of the quota fix.
# @exitcode 0 Success.
# @exitcode 1 Failure due to file access or copy errors.
zen::software::rutorrent::fix::quota() {
    mflibs::status::info "$(zen::i18n::translate "software.configuring" "quota")"
    # fix the quota issue
    all_users=$(zen::database::query "SELECT username FROM users;")
    for user in $all_users; do
        if [[ ! -f /srv/rutorrent/conf/users/${user}/config.php ]]; then
            mkdir -p "/srv/rutorrent/conf/users/${user}/"
            cp -pR "/opt/MediaEase/scripts/src/software/official/rutorrent/multi-user-fix/config.php" "/srv/rutorrent/conf/users/${user}/config.php"
            sed -i "s|{{USERNAME}}|${user}|g" "/srv/rutorrent/conf/users/${user}/config.php"
        fi
    done
    mflibs::status::success "$(zen::i18n::translate "software.configured" "quota")"
}
