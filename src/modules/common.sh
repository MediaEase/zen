#!/usr/bin/env bash
# @file modules/common.sh
# @project MediaEase
# @version 1.0.0
# @description Contains a library of common functions used in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @section Git Functions
# @description The following functions handle Git operations.

# @description Clones a Git repository into the specified directory.
# @arg $1 string Full URL of the Git repository to clone.
# @arg $2 string Target directory where the repository will be cloned.
# @arg $3 string Specific branch to clone (optional).
# @exitcode 0 on successful cloning.
# @exitcode 1 on failure.
# @stdout Clones the repository into the target directory.
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
        if [[ "$target_dir" == /opt/* && "$target_dir" != /opt/pyenv* && "$target_dir" != /opt/MediaEase* ]]; then
            local username
            username=$(echo "$target_dir" | cut -d'/' -f3)
            local group
            zen::common::fix::permissions "$target_dir" "$username" "$group" "755" "644"
        else 
            zen::common::fix::permissions "$target_dir" "www-data" "www-data" "755" "644"
        fi
        if [[ "$target_dir" == /opt/pyenv* && "$target_dir" == /opt/MediaEase* ]]; then
            zen::common::fix::permissions "$target_dir" "www-data" "www-data" "755" "644"
        fi
    else
        mflibs::status::error "$(zen::i18n::translate "common.repository_clone_failed" "$repo_url")"
        return 1
    fi
}


# @description Retrieves and extracts a release from a GitHub repository.
# @arg $1 string Directory where the release will be extracted.
# @arg $2 string Full URL of the GitHub repository.
# @arg $3 bool Retrieve a prerelease (true) or stable release (false).
# @arg $4 string Name or pattern of the release file to be retrieved.
# @exitcode 0 on successful retrieval and extraction.
# @exitcode 1 on failure.
# @stdout Downloads and extracts the specified release into the target directory.
# @notes
# The function cleans up the downloaded archive after extraction and sets
# appropriate permissions for the extracted files.
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
    mflibs::shell::text::white::sl "$(mflibs::shell::text::cyan "$(zen::i18n::translate "common.release_found" "$repo_name"): $release_version")"
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

# @section Environment Functions
# @description The following functions are used for environment variable management.

# @description Retrieves the value of a specified environment variable.
# @arg $1 string Name of the environment variable to retrieve.
# @exitcode 0 if the variable is found.
# @exitcode 1 if the variable is not found.
# @stdout Value of the specified environment variable.
zen::common::environment::get::variable() {
    local var_name="$1"
    if [[ -n "${!var_name}" ]]; then
        echo "${!var_name}"
    else
        mflibs::status::error "$(zen::i18n::translate "common.env_var_not_found" "$var_name")"
    fi
}

# @description Fixes permissions of a specified path for a user and group.
# @arg $1 string File system path whose permissions need fixing.
# @arg $2 string User for file/directory ownership.
# @arg $3 string Group for file/directory ownership.
# @arg $4 string Permissions for directories (e.g., '755').
# @arg $5 string Permissions for files (e.g., '644').
# @exitcode 0 if successful.
# @exitcode 1 if the path doesn't exist.
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

# @section Setting Functions
# @description The following functions are used for managing application settings.

# @description Loads settings from the database into a global associative array.
# @global settings Associative array populated with settings from the database.
# @exitcode 0 on successful loading.
# @exitcode 1 on failure.
# shellcheck disable=SC2034
# Disable reason: 'settings' is used in other functions
################################################################################
zen::common::setting::load(){
    declare -A -g settings
    setting_columns=("id" "site_name" "root_url" "site_description" "backdrop" "logo" "default_quota" "net_interface" "registration_enabled" "welcome_email")
    zen::database::load_config "$(zen::database::select "*" "setting" "")"  "settings" 0 "setting_columns"
}

# @description Capitalizes the first letter of a given string.
# @arg $1 string String to be capitalized.
# @stdout Transformed string with the first letter capitalized.
zen::common::capitalize::first() {
    local input_string="$1"
    local capitalized_string

    capitalized_string="${input_string^}"
    echo "$capitalized_string"
}

# @description Logs messages to a file for dashboard display.
# @arg $1 string Message to be logged.
# @stdout None.
# @notes Creates and manages the dashboard log file.
zen::common::dashboard::log() {
	if [[ ! -f "/srv/zen/logs/dashboard" ]]; then
		mkdir -p /srv/zen/logs
		touch /srv/zen/logs/dashboard
		chown www-data:www-data /srv/zen/logs/dashboard
	fi
	echo "${1:-null}" | sed -z "s/\n/<br>\n/" >/srv/zen/logs/dashboard
}

# @description Selects a random color code for shell output styling.
# @stdout Echoes a random color code (yellow, magenta, cyan).
zen::common::shell::color::randomizer(){
    local color
    color=$((RANDOM % 3))
    case $color in
        0) echo "yellow";;
        1) echo "magenta";;
        2) echo "cyan";;
    esac
}
