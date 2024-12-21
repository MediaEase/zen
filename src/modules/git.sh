#!/usr/bin/env bash
# @file modules/git.sh
# @project MediaEase
# @version 1.2.3
# @description Contains a library of common functions used in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @section Git Functions
# @description The following functions handle Git operations.

# @function zen::git::clone
# Clones a Git repository into the specified directory.
# @description This function clones a Git repository from a given URL into a specified directory.
# It checks if the directory already exists to avoid re-cloning. Optionally, a specific branch can be cloned.
# @arg $1 string Full URL of the Git repository to clone.
# @arg $2 string Target directory where the repository will be cloned.
# @arg $3 string Specific branch to clone (optional).
# @arg $4 bool Recursively clone submodules (optional).
# @exitcode 0 on successful cloning.
# @exitcode 1 on failure.
# @stdout Informs about the cloning process and results.
zen::git::clone() {
    local repo_name="$1"
    local target_dir="$2"
    local branch="$3"
    local recurse_submodules="${4:-false}"
    local repo_url
    repo_url="https://github.com/$repo_name"
    if [ -z "$branch" ]; then
        branch=$(git ls-remote --symref "$repo_url" HEAD | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
    fi
    if [ "$recurse_submodules" == "true" ]; then
        recurse_submodules="--recurse-submodules"
    else
        recurse_submodules=""
    fi
    mflibs::shell::text::white "$(zen::i18n::translate "headers.git.clone_repo" "$repo_name")"
    if mflibs::log "git clone --branch $branch $repo_url $target_dir $recurse_submodules >/dev/null 2>&1"; then
        local username
        local group
        if [[ "$target_dir" == /opt/* && "$target_dir" != /opt/MediaEase* ]]; then
            username=$(echo "$target_dir" | cut -d'/' -f3)
            group=$(getent group | grep "^$username:" | cut -d: -f1)
        elif [[ "$target_dir" == /root/* ]]; then
            username="root"
            group="root"
        else
            username="www-data"
            group="www-data"
        fi
        mflibs::log "$(git config --global --add safe.directory "$target_dir")"
        [[ $username != "root" && $target_dir != /root/* ]] && zen::permission::read_exec "$target_dir" "$username" "$group"
        [[ "$target_dir" == /opt/MediaEase* ]] && zen::permission::read_exec "$target_dir" "www-data" "www-data"
    else
        mflibs::status::error "$(zen::i18n::translate "errors.git.clone_repo" "$repo_name")"
    fi
    mflibs::shell::text::green "$(zen::i18n::translate "success.git.clone_repo" "$repo_name")"
}

# @function zen::git::get_release
# Retrieves and extracts a release from a GitHub repository.
# @description This function downloads and extracts a specific release (stable or prerelease) from a GitHub repository.
# It supports various file types for the release archive and sets appropriate permissions for the extracted files.
# @tip Check the release file type (alpha, beta, rc, ...) to ensure it is supported before downloading.
# @arg $1 string Directory where the release will be extracted.
# @arg $2 string Full URL of the GitHub repository.
# @arg $3 bool Retrieve a prerelease (true) or stable release (false).
# @arg $4 string Name or pattern of the release file to be retrieved.
# @exitcode 0 on successful retrieval and extraction.
# @exitcode 1 on failure.
# @stdout Details the process of downloading and extracting the release.
zen::git::get_release() {
    local target_dir="$1"
    local repo_name="$2"
    local is_prerelease="$3"
    local release_name="$4"
    local repo_url="https://api.github.com/repos/$repo_name/releases"
    local release_url
    mflibs::shell::text::white "$(zen::i18n::translate "messages.git.download_release" "$repo_name")"
    if [[ "$release_name" == "source" ]]; then
        local tag_name
        tag_name=$(curl -s "$repo_url" | jq -r "[.[] | select(.prerelease == $is_prerelease)] | first | .tag_name")
        if [[ -z "$tag_name" ]]; then
            mflibs::shell::text::red "$(zen::i18n::translate "errors.git.no_tag_found" "$repo_name")"
            return 1
        fi
        release_url="https://github.com/$repo_name/archive/refs/tags/$tag_name.tar.gz"
        release_version="$tag_name"

    else
        release_url=$(curl -s "$repo_url" | jq -r "[.[] | select(.prerelease == $is_prerelease)] | first | .assets[] | select(.name | endswith(\"$release_name\")).browser_download_url")
        release_version=$(echo "$release_url" | grep -oP '(?<=/download/)[^/]+(?=/[^/]+$)')
    fi
    if [[ -z "$release_url" ]]; then
        mflibs::shell::text::red "$(zen::i18n::translate "errors.git.no_release_found" "$repo_name")"
        return 1
    fi
    mflibs::shell::text::white::sl "$(mflibs::shell::text::cyan "$(zen::i18n::translate "messages.git.found_release" "$repo_name"): $release_version")"
    [[ -d $target_dir ]] && rm -rf "$target_dir"
    mflibs::dir::mkcd "$target_dir"
    wget -q "$release_url"
    local downloaded_file
    downloaded_file="$(basename "$release_url")"
    mflibs::file::extract "$downloaded_file"
    rm -f "$downloaded_file"
    if [[ "$target_dir" == /opt/* ]]; then
        local username
        username=$(echo "$target_dir" | cut -d'/' -f3)
        local group
        group=$(getent group | grep "^$username:" | cut -d: -f1)
        zen::permission::read_exec "$target_dir" "$username" "$group"
    else
        zen::permission::read_exec "$target_dir" "www-data" "www-data"
    fi
    mflibs::shell::text::green "$(zen::i18n::translate "success.git.download_release" "$repo_name")"
}

# @function zen::git::download_folder
# Downloads a specific folder from a GitHub repository.
# @description This function downloads a specified folder from a given GitHub repository and saves it to a local path.
# @arg $1 string Local path where the file should be saved.
# @arg $2 string Name of the repository (e.g., "git/core").
# @arg $3 string Branch of the repository to download from (default: "main").
# @arg $4 string Path to the remote folder in the repository.
# @exitcode 0 on successful download.
# @exitcode 1 on failure.
# @stdout Informs about the downloading process and results.
zen::git::download_folder() {
    local local_path="$1"
    local repo_name="$2"
    local branch="${3:-main}"
    local remote_folder="$4"
    local destination_folder="${repo_name##*/}"

    if ! command -v git &>/dev/null; then
        mflibs::status::error "$(zen::i18n::translate "errors.common.missing_required_tools")"
    fi
    cd "$local_path" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.change_directory" "/tmp")"
    mflibs::log "git init $destination_folder --initial-branch=$branch"
    cd "$destination_folder" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.change_directory" "/tmp/binaries")"
    mflibs::log "git remote remove origin"
    mflibs::log "git remote add origin https://github.com/$repo_name.git"
    mflibs::log "git config core.sparseCheckout true"
    echo "$remote_folder/*" >>.git/info/sparse-checkout
    mflibs::log "git pull --depth=1 origin $branch"
    if [[ -d "$remote_folder" && -n $(ls -A "$remote_folder") ]]; then
        mflibs::shell::text::green "$(zen::i18n::translate "success.common.download_folder" "$remote_folder" "$local_path")"
    else
        mflibs::status::error "$(zen::i18n::translate "errors.common.download_folder" "$remote_folder" "$local_path")"
    fi
}

# @function zen::git::tree
# Lists the files in a given repository and branch.
# @description This function lists the files in a specified repository and branch using the GitHub API.
# @tip Use appropriate filters to list only the files you are interested in.
# @arg $1 string Remote path to the directory in the repository.
# @arg $2 string Name of the repository (e.g., "MediaEase/binaries").
# @arg $3 string Branch name (e.g., "main").
# @exitcode 0 on successful retrieval and listing.
# @exitcode 1 on failure.
# @stdout Lists the files in the specified directory.
zen::git::tree() {
    local remote_path="$1"
    local repo_name="$2"
    local branch="${3:-main}"
    local api_url="https://api.github.com/repos/$repo_name/contents/$remote_path?ref=$branch"

    # Check if curl and jq are installed
    if ! command -v curl &>/dev/null || ! command -v jq &>/dev/null; then
        mflibs::status::error "$(zen::i18n::translate "errors.common.missing_required_tools")"
    fi

    # Fetch and list the files
    local response
    response=$(curl -s "$api_url")

    # Check if response is empty or not a valid array
    if [ -z "$response" ] || ! echo "$response" | jq -e . >/dev/null 2>&1; then
        mflibs::status::error "$(zen::i18n::translate "errors.network.invalid_api_response" "$response")"
    fi

    echo "$response" | jq -r '.[] | "\(.type)\t\(.name)"' | while IFS=$'\t' read -r type name; do
        if [[ $type == "file" ]]; then
            mflibs::shell::text::green "$name"
        elif [[ $type == "dir" ]]; then
            mflibs::shell::text::blue "$name/"
        fi
    done
}

# @function zen::git::download_from_binaries
# Downloads a file from the MediaEase binaries repository.
# @description This function downloads a file from the MediaEase binaries repository and saves it to a local path.
# Supports partial name matching via the GitHub API if an exact match is not provided.
# If multiple versions are available and no version is provided, it will download the latest version.
# @arg $1 string Partial or full name of the file to download.
# @arg $2 string Version of the file to download (optional).
# @arg $3 string Branch of the repository to download from (default: "main").
# @exitcode 0 on successful download.
# @exitcode 1 on failure.
# @stdout Informs about the downloading process and results.
zen::git::download_from_binaries() {
    local file_name="$1"
    local version="${2:-}"
    local branch="${3:-main}"
    local repo_name="MediaEase/binaries"
    local remote_folder="release_assets/"
    local api_url="https://api.github.com/repos/$repo_name/contents/$remote_folder?ref=$branch"
    local download_url
    daclare -g temp_binaries_path
    temp_binaries_path="$(mktemp -d)"
    if [[ -n "$version" ]]; then
        download_url=$(curl -s "$api_url" | jq -r --arg name "$file_name" --arg ver "$version" '.[] | select(.name | contains($name) and contains($ver)) | .download_url' | head -n 1) || mflibs::status::error "$(zen::i18n::translate "errors.common.no_file_found" "$file_name" "$version")"
    else
        download_url=$(curl -s "$api_url" | jq -r --arg name "$file_name" '.[] | select(.name | contains($name)) | .name' | sort -V | tail -n 1 | xargs -I {} curl -s "$api_url" | jq -r --arg name "{}" '.[] | select(.name == $name) | .download_url') || mflibs::status::error "$(zen::i18n::translate "errors.common.no_file_found" "$file_name" "$version")"
    fi
    file_path=$(basename "$file_name" | cut -d'_' -f1)
    file_path="${file_path//[0-9]/}"
    wget -q -O "$temp_binaries_path/$file_path" "$download_url" || {
        mflibs::status::error "$(zen::i18n::translate "errors.common.download_file" "$file_path" "$temp_binaries_path")"
    }
    mflibs::file::extract "$temp_binaries_path/$file_path"
    mflibs::status::success "$(zen::i18n::translate "info.common.download_success" "$file_path" "$temp_binaries_path")"
}
