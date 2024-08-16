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

# @function zen::common::git::clone
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
zen::common::git::clone() {
	local repo_name="$1"
	local target_dir="$2"
	local branch="${3}"
	local recurse_submodules="${4:-false}"
	local repo_url
	repo_url="https://github.com/$repo_name"
	if [ -d "$target_dir" ]; then
		mflibs::status::warn "$(zen::i18n::translate "errors.common.env_variable_missing" "$repo_url")"
		return 0
	fi

	if [ -z "$branch" ]; then
		branch=$(git ls-remote --symref "$repo_url" HEAD | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
	fi

	if [ "$recurse_submodules" == "true" ]; then
		recurse_submodules="--recurse-submodules"
	else
		recurse_submodules=""
	fi

	if mflibs::log "git clone --branch $branch $repo_url $target_dir $recurse_submodules"; then
		mflibs::status::success "$(zen::i18n::translate "messages.common.release_found" "$repo_url")"

		local username
		local group

		if [[ "$target_dir" == /opt/* && "$target_dir" != /opt/pyenv* && "$target_dir" != /opt/MediaEase* ]]; then
			username=$(echo "$target_dir" | cut -d'/' -f3)
			group=$(getent group | grep "^$username:" | cut -d: -f1)
		else
			username="www-data"
			group="www-data"
		fi

		zen::permission::fix "$target_dir" "755" "644" "$username" "$group"

		if [[ "$target_dir" == /opt/pyenv* || "$target_dir" == /opt/MediaEase* ]]; then
			zen::permission::fix "$target_dir" "755" "644" "www-data" "www-data"
		fi
	else
		mflibs::status::error "$(zen::i18n::translate "errors.common.repository_clone" "$repo_url")"
		return 1
	fi
}

# @function zen::common::git::get_release
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
zen::common::git::get_release() {
	local target_dir="$1"
	local repo_name="$2"
	local is_prerelease="$3"
	local release_name="$4"
	local repo_url
	mflibs::shell::text::white "$(zen::i18n::translate "messages.common.downloading_release" "$repo_name")"
	repo_url="https://api.github.com/repos/$repo_name/releases"
	release_url="$(curl -s "$repo_url" | jq -r "[.[] | select(.prerelease == $is_prerelease)] | first | .assets[] | select(.name | endswith(\"$release_name\")).browser_download_url")"
	declare -g release_version
	release_version=$(echo "$release_url" | grep -oP '(?<=/download/)[^/]+(?=/[^/]+$)')
	mflibs::shell::text::white::sl "$(mflibs::shell::text::cyan "$(zen::i18n::translate "messages.common.release_found" "$repo_name"): $release_version")"
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
	mflibs::shell::text::green "$(zen::i18n::translate "success.common.release_downloaded" "$repo_name")"
}

# @function zen::common::git::download_file
# Downloads a specific file from a GitHub repository.
# @description This function downloads a specified file from a given GitHub repository and saves it to a local path.
# @arg $1 string Local path where the file should be saved.
# @arg $2 string Name of the repository (e.g., "git/core").
# @arg $3 string Branch of the repository to download from.
# @arg $4 string Path to the remote file in the repository.
# @exitcode 0 on successful download.
# @exitcode 1 on failure.
# @stdout Informs about the downloading process and results.
zen::common::git::download_file() {
	local local_path="$1"
	local repo_name="$2"
	local branch="$3"
	local remote_file="$4"
	local repo_url="https://raw.githubusercontent.com/$repo_name/$branch/$remote_file"

	# Check if curl is installed
	if ! command -v curl &>/dev/null; then
		mflibs::status::error "$(zen::i18n::translate "errors.dependency.dependency_missing" "cUrl")"
	fi

	# Download the file
	if curl -o "$local_path" "$repo_url"; then
		mflibs::status::success "$(zen::i18n::translate "success.common.file_downloaded" "$repo_url" "$local_path")"
	else
		mflibs::status::error "$(zen::i18n::translate "errors.common.file_download" "$repo_url")"
	fi
}

# @function zen::common::git::tree
# Lists the files in a given repository and branch.
# @description This function lists the files in a specified repository and branch using the GitHub API.
# @tip Use appropriate filters to list only the files you are interested in.
# @arg $1 string Remote path to the directory in the repository.
# @arg $2 string Name of the repository (e.g., "MediaEase/binaries").
# @arg $3 string Branch name (e.g., "main").
# @exitcode 0 on successful retrieval and listing.
# @exitcode 1 on failure.
# @stdout Lists the files in the specified directory.
zen::common::git::tree() {
	local remote_path="$1"
	local repo_name="$2"
	local branch="$3"
	local api_url="https://api.github.com/repos/$repo_name/contents/$remote_path?ref=$branch"

	# Check if curl and jq are installed
	if ! command -v curl &>/dev/null || ! command -v jq &>/dev/null; then
		mflibs::status::error "$(zen::i18n::translate "errors.common.required_tools_missing")"
	fi

	# Fetch and list the files
	local response
	response=$(curl -s "$api_url")

	# Check if response is empty or not a valid array
	if [ -z "$response" ] || ! echo "$response" | jq -e . >/dev/null 2>&1; then
		mflibs::status::error "$(zen::i18n::translate "common.invalid_api_response" "$response")"
	fi

	echo "$response" | jq -r '.[] | "\(.type)\t\(.name)"' | while IFS=$'\t' read -r type name; do
		if [[ $type == "file" ]]; then
			mflibs::shell::text::green "$name"
		elif [[ $type == "dir" ]]; then
			mflibs::shell::text::blue "$name/"
		fi
	done
}

# @section Environment Functions
# @description The following functions are used for environment variable management.

# @function zen::common::environment::get::variable
# Retrieves the value of a specified environment variable.
# @description This function fetches the value of a specified environment variable, displaying an error if not found.
# @arg $1 string Name of the environment variable to retrieve.
# @exitcode 0 if the variable is found.
# @exitcode 1 if the variable is not found.
# @stdout Value of the specified environment variable.
zen::common::environment::get::variable() {
	local var_name="$1"
	if [[ -n "${!var_name}" ]]; then
		echo "${!var_name}"
	else
		mflibs::status::error "$(zen::i18n::translate "errors.common.env_variable_missing" "$var_name")"
	fi
}

# @function zen::common::environment::set::variable
# Exports a variable and adds it to the .bash_profile.
# @description This function exports a given variable and its value, appending it to the root user's .bash_profile if it's not already present.
# It ensures that the variable will be set and available in future shell sessions for the root user.
# The function splits the input into a variable name and value, then checks and appends the export statement to .bash_profile.
# @note If the variable is already exported in the .bash_profile, this function does not duplicate it.
# @important Only use this function for variables that should persist across sessions for the root user.
# @arg $1 string The variable assignment in 'NAME=VALUE' format.
# @stdout None.
zen::common::environment::set::variable() {
	local var_name="${1%%=*}"
	local var_value="${1#*=}"
	local bashrc_file="/root/.bash_profile"

	if ! grep -q "export $var_name=" "$bashrc_file"; then
		echo "export $var_name=\"$var_value\"" >>"$bashrc_file"
	fi
}

# @section Setting Functions
# @description The following functions are used for managing application settings.

# Loads settings from the database into a global associative array.
# @description This function loads various settings from the database and populates a global associative array with these settings.
# The function is crucial for configuring the application based on database-stored preferences.
# @global settings Associative array populated with settings from the database.
# @exitcode 0 on successful loading.
# @exitcode 1 on failure.
# shellcheck disable=SC2034
# Disable reason: 'settings' is used in other functions
zen::common::setting::load() {
	declare -A -g settings
	setting_columns=("id" "site_name" "root_url" "site_description" "default_quota" "net_interface" "registration_enabled" "welcome_email_enabled" "brand" "favicon" "appstore" "splashscreen" "email_verification_enabled" "default_log_level" "log_refresh_delay")
	zen::database::load_config "$(zen::database::select "*" "setting" "")" "settings" 0 "setting_columns"
}

# Logs messages to a file for dashboard display.
# @description This function logs given messages to a file, which can be used for displaying logs on a dashboard.
# It creates and manages the log file, ensuring it's owned by the appropriate user.
# @arg $1 string Message to be logged.
# @stdout None.
zen::common::dashboard::log() {
	if [[ ! -f "/srv/zen/logs/dashboard" ]]; then
		mkdir -p /srv/zen/logs
		touch /srv/zen/logs/dashboard
		chown www-data:www-data /srv/zen/logs/dashboard
	fi
	echo "${1:-null}" | sed -z "s/\n/<br>\n/" >/srv/zen/logs/dashboard
}

# @section String/Shell extra Functions
# @description The following functions are used for shell operations.

# @function zen::common::capitalize::first
# Capitalizes the first letter of a given string.
# @description This function transforms a string by capitalizing its first letter, useful for formatting display text.
# @tip Use this function to format user-visible strings consistently.
# @arg $1 string String to be capitalized.
# @stdout Transformed string with the first letter capitalized.
zen::common::capitalize::first() {
	local input_string="$1"
	local capitalized_string

	capitalized_string="${input_string^}"
	echo "$capitalized_string"
}

# @function zen::common::lowercase
# Converts a string to lowercase.
# @description This function converts a given string to lowercase, ensuring consistent formatting for display text.
# @arg $1 string String to be converted to lowercase.
# @stdout Transformed string in lowercase.
zen::common::lowercase() {
	local input_string="$1"
	local lowercase_string

	lowercase_string="${input_string,,}"
	echo "$lowercase_string"
}

# @function zen::common::shell::color::randomizer
# Selects a random color code for shell output styling.
# @description This function randomly selects a color code for styling shell outputs, adding visual diversity to command line interfaces.
# @note This function is useful for creating visually distinct outputs.
# @stdout Random color code.
zen::common::shell::color::randomizer() {
	local color
	color=$((RANDOM % 3))
	case $color in
	0) echo "yellow" ;;
	1) echo "magenta" ;;
	2) echo "cyan" ;;
	esac
}

# @function zen::common::make::install
# Compiles and installs a project using the make build system.
# @description This function handles the compilation and installation of a project that uses the make build system.
# It utilizes all available processors to speed up the compilation and allows specification of additional make arguments and installation directory.
# @usage zen::common::make::install "source_directory" "installation_directory" "make_arguments" "make_install_arguments"
# @note This function optimizes build speed by using parallel build options based on the number of available processors.
# @arg $1 string Source directory where the makefile is located and where the build process should occur.
# @arg $2 string Installation directory where the built project should be installed. This is optional and, if specified, is used in the `make install` command with the DESTDIR prefix.
# @arg $3 string Additional arguments to pass to the make command during the build process (optional).
# @arg $4 string Additional arguments for the make install command, allowing further customization of the install process (optional).
# @exitcode 0 on successful build and installation.
# @exitcode 1 on failure during either the build or install step.
# @stdout Information and status updates about each step of the build and installation process.
zen::common::make::install() {
	local source_dir="$1"
	local install_dir="$2"
	local make_args="$3"
	local make_install_args="$4"
	local nproc_args
	nproc_args="-j$(nproc)"
	cd "$source_dir" || mflibs::status::error "$(zen::i18n::translate "errors.common.directory_change" "$source_dir")"
	if mflibs::log "make $nproc_args $make_args"; then
		[ -n "$install_dir" ] && make_install_args="DESTDIR=$install_dir $make_install_args"
		if mflibs::log "make install $make_install_args"; then
			mflibs::status::success "$(zen::i18n::translate "success..common.make_install" "$source_dir")"
		else
			mflibs::status::error "$(zen::i18n::translate "errors.common.make_install" "$source_dir")"
		fi
	else
		mflibs::status::error "$(zen::i18n::translate "errors.common.make" "$source_dir")"
	fi
}

# @function zen::common::scons::install
# Installs a project using the scons build system.
# @description This function handles the configuration, building, and installation of a project that utilizes scons as its build system.
# It supports building in debug mode and allows specifying a custom installation directory.
# @usage zen::common::scons::install "source_directory" "installation_directory" "debug_flag"
# @note This function assumes the presence of scons in the system and relies on proper configuration of the project for scons.
# @arg $1 string Source directory of the project to be built.
# @arg $2 string Installation directory where the project should be installed (optional).
# @arg $3 string Debug build flag; if set to 'true', the project will be built in debug mode (optional).
# @exitcode 0 on successful execution.
# @exitcode 1 on failure at any step (configuration, building, or installation).
# @stdout Information about the process steps and their success or failure.
zen::common::scons::install() {
	local source_dir="$1"
	local install_dir="$2"
	local debug_build="${3:-false}"
	local scons_install_args
	local debug_flag
	debug_flag=$([[ "$debug_build" == "true" ]] && echo "1" || echo "0")
	cd "$source_dir" || mflibs::status::error "$(zen::i18n::translate "errors.common.directory_change" "$source_dir")"
	if ! mflibs::log "scons config"; then
		mflibs::status::error "$(zen::i18n::translate "errors.common.scons_config" "$source_dir")"
	fi
	if ! mflibs::log "scons DEBUG=$debug_flag"; then
		mflibs::status::error "$(zen::i18n::translate "errors.common.scons_build" "$source_dir")"
	fi

	[ -n "$install_dir" ] && scons_install_args="--prefix=$install_dir"
	if ! mflibs::log "scons $scons_install_args DEBUG=$debug_flag install"; then
		mflibs::status::error "$(zen::i18n::translate "errors.common.scons_install" "$source_dir")"
	fi
	mflibs::status::success "$(zen::i18n::translate "errors.common.scons_install" "$source_dir")"
}

# @function zen::common::bashrc::append
# Appends given lines to the .bashrc file for a specified user.
# @description This function appends specified lines to the .bashrc file for a specified user, ensuring that each line is present
# in future shell sessions. It is useful for adding custom environment variables or aliases to the shell environment.
# @arg $1 array Lines to be appended to the .bashrc file.
# @arg $2 string (optional) Username whose .bashrc file will be modified. Defaults to the current user if not provided.
# @exitcode 0 on successful appending.
# @exitcode 1 on failure.
# @stdout None.
zen::common::bashrc::append() {
	local -n lines="$1"
	local user="${2:-$USER}"
	local bashrc_file

	if [ "$user" = "root" ]; then
		bashrc_file="/root/.bashrc"
	else
		bashrc_file="/home/$user/.bashrc"
	fi

	if [ -f "$bashrc_file" ]; then
		for line in "${lines[@]}"; do
			if ! grep -qF "$line" "$bashrc_file"; then
				echo "$line" >>"$bashrc_file"
			fi
		done
	else
		mflibs::status::error "$(zen::i18n::translate "errors.common.bashrc_missing" "$bashrc_file")"
		return 1
	fi
}
