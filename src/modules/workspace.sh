#!/usr/bin/env bash
# @file modules/workspace.sh
# @project MediaEase
# @version 1.4.5
# @brief A library for managing Python virtual environments.
# @description Contains a library of functions used in the MediaEase Project for managing virtual environments.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @function zen::workspace::venv::create
# Creates a Python virtual environment at the specified path under a specific user context.
# @description This function creates a Python virtual environment in a specified filesystem path,
# running the process under the context of a given user. If no user is specified, it defaults to `root`.
# The function ensures the path is valid, navigates to it, and creates the virtual environment using `uv venv`.
# @arg $1 string The filesystem path where the virtual environment should be created.
# @arg $2 string (optional) The username under whose context the virtual environment should be created. Defaults to 'root' if not provided.
# @global user Associative array containing user-specific information (e.g., 'username').
# @return 1 If no path is specified or if the directory change fails.
# @exitcode 0 On successful creation of the virtual environment.
# @exitcode 1 On failure due to missing path, directory change failure, or failure during virtual environment creation.
# @caution Ensure the specified path is correct and accessible to avoid failures.
# @important The virtual environment is created under the specified user context, so make sure the user has necessary permissions.
# shellcheck disable=SC2154
# Disabling SC2154 because the variable 'user' is defined in the main script
zen::workspace::venv::create() {
	local path="$1"
	local username=${2:-root}
	local instant_build=${3:-false}
	if [[ -z "$path" ]]; then
		mflibs::shell::text::red "$(zen::i18n::translate "errors.virtualization.venv_create_no_path")"
		return 1
	fi
	zen::workspace::install_uv "$username"
	mflibs::shell::text::white "$(zen::i18n::translate "messages.virtualization.install_venv_requirements" "$app_name")"
	cd "$path" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.change_directory" "$path")" && return 1
	local passthrough="sudo -u $username"
	if ! mflibs::log "$passthrough uv venv"; then
		mflibs::status::error "$(zen::i18n::translate "errors.virtualization.venv_create")"
		return 1
	fi
	mflibs::shell::text::green "$(zen::i18n::translate "success.virtualization.install_venv" "$app_name")"
	if [[ "$instant_build" == "true" ]]; then
		zen::workspace::venv::build "$path" "$path/requirements.txt" "$username"
	fi
	return 0
}

# @function zen::workspace::venv::build
# Installs Python packages in a virtual environment from a requirements file.
# @description This function activates a specified Python virtual environment and installs packages.
# It reads a requirements file and optional pre-installed packages, installing them as required.
# It reports on the success or failure of installing these packages.
# @arg $1 string The path to the virtual environment.
# @arg $2 string The path to the requirements file.
# @arg $3 string (optional) Username to execute commands under. Defaults to 'root' if not specified.
# @global user Associative array containing user-specific information.
# @return 1 if no path is specified, or if an error occurs during installation.
# @exitcode 0 Success in installing packages.
# @exitcode 1 Failure due to missing path or installation error.
# @note Ensure that the path and requirements file are correct to avoid installation errors.
zen::workspace::venv::build() {
	local path="$1"
	local requirements_path="${2:-$path/requirements.txt}"
	local username="${3:-root}"
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/dependencies.yaml"
	local python_dependencies

	if [[ -z "$path" ]]; then
		mflibs::status::warn "$(zen::i18n::translate "errors.virtualization.remove_venv")"
	fi
	zen::workspace::install_uv "$username"
	local passthrough="sudo -u $username"
	mflibs::log "$passthrough source $path/.venv/bin/activate"
	mflibs::shell::text::green "$(zen::i18n::translate "messages.virtualization.activate_venv")"
	# Install Python dependencies from dependencies.yaml file
	python_dependencies=$(yq e ".${app_name}.python" "$dependencies_file" 2>/dev/null)
	if [[ -z "$python_dependencies" ]]; then
		mflibs::shell::text::red "$(zen::i18n::translate "errors.virtualization.no_dependencies_found" "$app_name")"
	fi
	mflibs::shell::text::white "$(zen::i18n::translate "messages.virtualization.install_venv_requirements" "$app_name")"
	local exit_status=0
	IFS=' ' read -ra DEPS <<<"$python_dependencies"
	for dependency in "${DEPS[@]}"; do
		mflibs::log "$passthrough uv pip install --quiet ${dependency}"
		local result=$?
		if [[ "$result" -ne 0 ]]; then
			mflibs::status::error "$(zen::i18n::translate "errors.virtualization.dependency_install" "$dependency")"
			exit_status=1
		fi
	done
	mflibs::shell::text::green "$(zen::i18n::translate "success.virtualization.install_venv_requirements" "$app_name")"

	# Install requirements from requirements.txt file
	if [[ $exit_status -eq 0 && -f "$requirements_path" ]]; then
		mflibs::shell::text::white "$(zen::i18n::translate "messages.virtualization.install_venv_requirements" "$app_name")"
		mflibs::log "$passthrough uv pip install --quiet --requirement $requirements_path"
		local result=$?
		if [[ "$result" -ne 0 ]]; then
			mflibs::status::error "$(zen::i18n::translate "errors.virtualization.remove_venv_requirements" "$software_name")"
			exit_status=1
		fi
		mflibs::shell::text::green "$(zen::i18n::translate "success.virtualization.install_venv_requirements" "$software_name")"
	fi

	# Deactivate the virtual environment
	mflibs::log "$passthrough deactivate"

	if [[ $exit_status -eq 0 ]]; then
		mflibs::status::success "$(zen::i18n::translate "success.virtualization.install_venv" "$software_name")"
	fi

	return $exit_status
}

# @function zen::workspace::venv::remove
# Removes a Python virtual environment.
# @description This function removes an existing Python virtual environment from the specified filesystem path.
# It ensures that the path is valid and performs the removal under the context of a specified user.
# The function also handles the uninstallation of any packages installed within the virtual environment.
# @arg $1 string The filesystem path where the virtual environment should be removed.
# @global user Associative array containing user-specific information (particularly 'username').
# @return 1 if no path is specified or if the directory change fails.
# @exitcode 0 Success in removing the virtual environment.
# @exitcode 1 Failure due to missing path or directory change failure.
# @note Make sure to backup any important data before removing the virtual environment.
zen::workspace::venv::remove() {
	local path="$1"
	if [[ -z "$path" ]]; then
		mflibs::shell::text::red "$(zen::i18n::translate "errors.virtualization.venv_create_no_path")"
	fi
	zen::workspace::install_uv "$username"
	cd "$path" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.change_directory" "$path")"
	# shellcheck disable=SC1091
	source venv/bin/activate
	if ! uv pip uninstall --requirement requirements.txt; then
		mflibs::status::error "$(zen::i18n::translate "errors.virtualization.remove_venv" "$app_name")"
	fi
	cd .. >/dev/null || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.change_directory" "..")"
	rm -rf "$path"

	mflibs::status::success "$(zen::i18n::translate "success.virtualization.remove_venv" "$app_name")"
}

# @function zen::workspace::venv::update
# @description Updates an existing Python virtual environment, installing or upgrading dependencies from the dependencies.yaml file and requirements.txt.
# @arg $1 string The path to the project directory where the virtual environment is located.
# @arg $2 string (optional) Username to execute commands under. Defaults to 'root' if not specified.
# @global user An associative array containing user-specific information.
# @return 1 if no path is specified, or if an error occurs during installation.
# @exitcode 0 Success in updating the virtual environment.
zen::workspace::venv::update() {
	local path="$1"
	local username="${2:-root}"
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/dependencies.yaml"
	local python_dependencies
	local requirements_path="$path/requirements.txt"
	if [[ -z "$path" ]]; then
		mflibs::status::warn "$(zen::i18n::translate "errors.virtualization.remove_venv")"
	fi
	zen::workspace::install_uv "$username"
	local passthrough="sudo -u $username"
	mflibs::log "$passthrough source $path/.venv/bin/activate"
	mflibs::shell::text::green "$(zen::i18n::translate "messages.virtualization.activate_venv")"
	python_dependencies=$(yq e ".${app_name}.python" "$dependencies_file" 2>/dev/null)
	if [[ -z "$python_dependencies" ]]; then
		mflibs::shell::text::red "$(zen::i18n::translate "errors.virtualization.no_dependencies_found" "$app_name")"
	fi
	mflibs::shell::text::white "$(zen::i18n::translate "messages.virtualization.install_venv_requirements" "$app_name")"
	local exit_status=0
	IFS=' ' read -ra DEPS <<<"$python_dependencies"
	for dependency in "${DEPS[@]}"; do
		mflibs::log "$passthrough uv pip install --quiet --upgrade ${dependency}"
		local result=$?
		if [[ "$result" -ne 0 ]]; then
			mflibs::status::error "$(zen::i18n::translate "errors.virtualization.dependency_install" "$dependency")"
			exit_status=1
		fi
	done
	mflibs::shell::text::green "$(zen::i18n::translate "success.virtualization.install_venv_requirements" "$app_name")"
	if [[ $exit_status -eq 0 && -f "$requirements_path" ]]; then
		mflibs::shell::text::white "$(zen::i18n::translate "messages.virtualization.install_venv_requirements" "$app_name")"
		mflibs::log "$passthrough uv pip install --quiet --upgrade --requirement $requirements_path"
		local result=$?
		if [[ "$result" -ne 0 ]]; then
			mflibs::status::error "$(zen::i18n::translate "errors.virtualization.remove_venv_requirements" "$software_name")"
			exit_status=1
		fi
		mflibs::shell::text::green "$(zen::i18n::translate "success.virtualization.install_venv_requirements" "$software_name")"
	fi
	mflibs::log "$passthrough deactivate"

	if [[ $exit_status -eq 0 ]]; then
		mflibs::status::success "$(zen::i18n::translate "success.virtualization.install_venv" "$software_name")"
	fi
	return $exit_status
}

# @function zen::workspace::install_uv
# @description Installs the `uv` tool for the specified user if it is not already installed.
# @arg $1 string (optional) The username under whose context to install `uv`. Defaults to 'root' if not specified.
# @return 1 if `uv` installation fails.
# @exitcode 0 Success in installing `uv` or if `uv` is already installed.
# @note This function will ensure `uv` is available for the specified user, installing it if necessary.
zen::workspace::install_uv() {
	local username=${1:-root}
	local passthrough="sudo -u $username"
	local user_home
	user_home=$(eval echo ~"$username")
	if ! $passthrough command -v uv &>/dev/null; then
		mflibs::shell::text::yellow "$(zen::i18n::translate "messages.virtualization.install_uv")"
		mflibs::log "$passthrough curl -LsSf https://astral.sh/uv/install.sh | $passthrough env UV_INSTALL_DIR=$user_home/bin/uv sh"
		if ! $passthrough command -v uv &>/dev/null; then
			mflibs::status::error "$(zen::i18n::translate "errors.virtualization.uv_install_failed")"
			return 1
		fi
		mflibs::log "$passthrough uv python install 3.9 3.10 3.11 3.12"
		mflibs::shell::text::green "$(zen::i18n::translate "success.virtualization.uv_installed")"
	fi

	return 0
}
