#!/usr/bin/env bash
################################################################################
# @file_name: common.sh
# @version: 1
# @project_name: zen
# @description: a library for common functions
#
# @author: Thomas Chauveau (tomcdj71)
# @author_contact: thomas.chauveau.pro@gmail.com
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2024, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# zen::common::git::clone
#
# Clones a Git repository into the specified directory. This function clones
# the specified branch of the repository, or the default branch if none is
# specified.
#
# Arguments:
#   repo_url - The full URL of the Git repository to clone.
#   target_dir - The target directory where the repository will be cloned.
#   branch (optional) - The specific branch to clone. Defaults to the main branch
#                       if not specified.
# Outputs:
#   Clones the repository into the target directory.
# Returns:
#   0 on successful cloning, 1 on failure.
# Notes:
#   If the target directory already exists, the function will warn and exit
#   without performing the clone. It also adjusts permissions based on the
#   target directory's location.
################################################################################
zen::common::git::clone() {
    local repo_name="$1"
    local target_dir="$2"
    local branch="${3}"
    local repo_url
    repo_url="https://github.com/$repo_name"
    if [ -d "$target_dir" ]; then
        mflibs::status::warn "$(zen::i18n::translate "common.repository_already_exists" "$repo_url")"
        return 0
    fi

    if [ -z "$branch" ]; then
        branch=$(git ls-remote --symref "$repo_url" HEAD | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
    fi

    if mflibs::log "git clone --branch $branch $repo_url $target_dir"; then
        mflibs::status::success "$(zen::i18n::translate "common.repository_cloned" "$repo_url")"
        if [[ "$target_dir" == /opt/* ]]; then
            local username
            username=$(echo "$target_dir" | cut -d'/' -f3)
            local group
            zen::common::fix::permissions "$target_dir" "$username" "$group" "755" "644"
        else 
            zen::common::fix::permissions "$target_dir" "www-data" "www-data" "755" "644"
        fi
    else
        mflibs::status::error "$(zen::i18n::translate "common.repository_clone_failed" "$repo_url")"
        return 1
    fi
}

################################################################################
# zen::common::git::get_release
#
# Retrieves a release from a GitHub repository and extracts it into the
# specified directory. This function can handle both stable and prerelease
# versions, and supports various file formats for the release archive.
#
# Arguments:
#   target_dir - The directory where the release will be extracted.
#   repo_url - The full URL of the GitHub repository.
#   is_prerelease - Boolean indicating whether to retrieve a prerelease (true)
#                   or a stable release (false).
#   release_name - The name or pattern of the release file to be retrieved.
# Outputs:
#   Downloads and extracts the specified release into the target directory.
# Returns:
#   0 on successful retrieval and extraction, 1 on failure.
# Notes:
#   The function cleans up the downloaded archive after extraction and sets
#   appropriate permissions for the extracted files.
################################################################################
zen::common::git::get_release(){
    local target_dir="$1"
    local repo_name="$2"
    local is_prerelease="$3"
    local release_name="$4"
    local repo_url
    mflibs::shell::text::white "$(zen::i18n::translate "common.getting_release" "$repo_name")"
    repo_url="https://api.github.com/repos/$repo_name/releases"
    release_url="$(curl -s "$repo_url" | jq -r "[.[] | select(.prerelease == $is_prerelease)] | first | .assets[] | select(.name | endswith(\"$release_name\")).browser_download_url")"
    declare -g release_version
    release_version=$(echo "$release_url" | grep -oP '(?<=/download/)[^/]+(?=/[^/]+$)')
    mflibs::shell::text::white::sl "$(zen::i18n::translate "common.release_found" "$repo_name"): $(mflibs::shell::text::cyan "$release_version")"
    [[ -d $target_dir ]] && rm -rf "$target_dir"
    mflibs::dir::mkcd "$target_dir"
    local file_extension="${release_url##*.}"
    wget -q "$release_url"
    local downloaded_file
    downloaded_file="$(basename "$release_url")"
    case "$file_extension" in
        zip)
            unzip -q "$downloaded_file"
            ;;
        tar)
            tar -xf "$downloaded_file" --strip-components=1
            ;;
        gz)
            tar -xvzf "$downloaded_file" --strip-components=1 > /dev/null 2>&1
            ;;
        *)
            mflibs::status::error "$(zen::i18n::translate "common.unsupported_file_type" "$file_extension")"
            return 1
            ;;
    esac
    rm -f "$downloaded_file"
    if [[ "$target_dir" == /opt/* ]]; then
        local username
        username=$(echo "$target_dir" | cut -d'/' -f3)
        local group
        zen::common::fix::permissions "$target_dir" "$username" "$group" "755" "644"
    else 
        zen::common::fix::permissions "$target_dir" "www-data" "www-data" "755" "644"
    fi
    mflibs::shell::text::green "$(zen::i18n::translate "common.release_downloaded" "$repo_name")"
}

################################################################################
# zen::common::environment::get::variable
#
# Retrieves the value of a specified environment variable. If the variable is
# not set, the function outputs an error message.
#
# Arguments:
#   var_name - The name of the environment variable to retrieve.
# Outputs:
#   The value of the specified environment variable.
# Returns:
#   Echoes the variable's value if set, otherwise prints an error message.
################################################################################
zen::common::environment::get::variable() {
    local var_name="$1"
    if [[ -n "${!var_name}" ]]; then
        echo "${!var_name}"
    else
        mflibs::status::error "$(zen::i18n::translate "common.env_var_not_found" "$var_name")"
    fi
}

################################################################################
# zen::common::fix::permissions
#
# Fixes the permissions of a specified path for a given user and group. This
# function recursively changes ownership and sets permissions for directories
# and files within the given path.
#
# Arguments:
#   path - The file system path whose permissions need to be fixed.
#   user - The user to whom ownership of the files/directories should be set.
#   group - The group to whom ownership of the files/directories should be set.
#   dir_permissions - The permissions to apply to directories (e.g., '755').
#   file_permissions - The permissions to apply to files (e.g., '644').
# Returns:
#   0 if permissions were successfully changed, 1 if the path doesn't exist.
################################################################################
zen::common::fix::permissions() {
    local path="$1"
    local user="$2"
    local group="$3"
    local dir_permissions="$4"
    local file_permissions="$5"

    if [ ! -e "$path" ]; then
        mflibs::status::error "$(zen::i18n::translate "common.path_not_found" "$path")"
        return 1
    fi

    chown -R "$user:$group" "$path"
    find "$path" -type d -exec chmod "$dir_permissions" {} +
    find "$path" -type f -exec chmod "$file_permissions" {} +
}

################################################################################
# zen::common::setting::load
#
# Loads settings from the database into a globally accessible associative array.
# This function is designed to retrieve application settings stored in a
# database and make them available within the script.
#
# Globals:
#   settings - An associative array that will be populated with the settings.
# Returns:
#   Populates the 'settings' global associative array with settings from the database.
# Notes:
#   This function relies on 'zen::database::load_config' for parsing the SQL
#   query results and populating the 'settings' array.
# shellcheck disable=SC2034
# Disable reason: 'settings' is used in other functions
################################################################################
zen::common::setting::load(){
    declare -A -g settings
    setting_columns=("id" "site_name" "root_url" "site_description" "backdrop" "logo" "default_quota" "net_interface" "registration_enabled" "welcome_email")
    zen::database::load_config "$(zen::database::select "*" "setting" "")"  "settings" 0 "setting_columns"
}

################################################################################
# zen::common::capitalize::first
#
# Capitalizes the first letter of the given string. This function is useful
# for formatting output or user input where capitalization is required.
#
# Arguments:
#   input_string - The string to be capitalized.
# Returns:
#   The transformed string with the first letter capitalized.
################################################################################
zen::common::capitalize::first() {
    local input_string="$1"
    local capitalized_string

    capitalized_string="${input_string^}"
    echo "$capitalized_string"
}

################################################################################
# zen::common::dashboard::log
#
# Passes shell output to the dashboard log. This function is used for logging
# messages to a file that can be displayed on a dashboard or web interface.
#
# Arguments:
#   string - The message string to be logged.
# Returns:
#   None. Writes the message to the dashboard log file.
# Notes:
#   Creates the dashboard log file if it does not exist and sets appropriate
#   permissions. Formats newlines in the log message as HTML line breaks.
################################################################################
zen::common::dashboard::log() {
	if [[ ! -f "/srv/zen/logs/dashboard" ]]; then
		mkdir -p /srv/zen/logs
		touch /srv/zen/logs/dashboard
		chown www-data:www-data /srv/zen/logs/dashboard
	fi
	echo "${1:-null}" | sed -z "s/\n/<br>\n/" >/srv/zen/logs/dashboard
}

################################################################################
# zen::common:shell::color::randomizer
#
# Selects a random color code for output styling.
#
# No arguments.
# Outputs:
#   Echoes a random color code (yellow, magenta, cyan).
# Notes:
#   Used to randomize the color of text output in the shell for visual variety.
################################################################################
zen::common:shell::color::randomizer(){
    local color
    color=$((RANDOM % 3))
    case $color in
        0) echo "yellow";;
        1) echo "magenta";;
        2) echo "cyan";;
    esac
}
