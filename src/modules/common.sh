#!/usr/bin/env bash
################################################################################
# @description: Clones a Git repository into a specified directory.
# @arg: $1: repo_url - URL of the Git repository to clone.
# @arg: $2: target_dir - Target directory for the clone.
# @arg: $3 (optional): branch - The name of the branch to clone.
# @return: Exit code 0 on success, 1 on failure.
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
# @description: Retrieves a release from a GitHub repository and extracts it into a specified directory.
# @arg: $1: target_dir - Target directory for the release.
# @arg: $2: repo_url - URL of the GitHub repository.
# @arg: $3: is_prerelease - Whether to retrieve a prerelease (true) or a stable release (false).
# @arg: $4: release_name - Name of the release file to retrieve.
# @return: Exit code 0 on success, 1 on failure.
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
# @description: Retrieves the value of an environment variable.
# @arg: $1: var_name - Name of the environment variable.
# @return: Value of the variable, or an error message if not set.
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
# @description: Fixes permissions of a path for a given user and group.
# @arg: $1: path - Path whose permissions need to be fixed.
# @arg: $2: user - User owner of the files/directories.
# @arg: $3: group - Group owner of the files/directories.
# @arg: $4: dir_permissions - Permissions to apply to directories.
# @arg: $5: file_permissions - Permissions to apply to files.
# @return: Exit code 0 on success, 1 on failure.
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
# @description: Loads the settings from the database into an associative array
# @return: settings - Associative array containing the settings.
# shellcheck disable=SC2034
################################################################################
zen::common::setting::load(){
    declare -A -g settings
    setting_columns=("id" "site_name" "root_url" "site_description" "backdrop" "logo" "default_quota" "net_interface" "registration_enabled" "welcome_email")
    zen::database::load_config "$(zen::database::select "*" "setting" "")"  "settings" 0 "setting_columns"
}

################################################################################
# @description: Capitalizes the first letter of a string.
# @arg: $1: input_string - The string to be transformed.
# @return: Transformed string with the first letter capitalized.
################################################################################
zen::common::capitalize::first() {
    local input_string="$1"
    local capitalized_string

    capitalized_string="${input_string^}"
    echo "$capitalized_string"
}

################################################################################
# @description: passes shell output to dashboard
# @arg: $1: string
# @return: none
################################################################################
zen::common::dashboard::log() {
	if [[ ! -f "/srv/zen/logs/dashboard" ]]; then
		mkdir -p /srv/zen/logs
		touch /srv/zen/logs/dashboard
		chown www-data:www-data /srv/zen/logs/dashboard
	fi
	echo "${1:-null}" | sed -z "s/\n/<br>\n/" >/srv/zen/logs/dashboard
}
