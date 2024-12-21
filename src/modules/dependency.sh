#!/usr/bin/env bash
# @file modules/dependency.sh
# @project MediaEase
# @version 1.5.9
# @description Contains a library of functions used in the MediaEase Project for managing dependencies.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::dependency::apt::manage
# Manages APT dependencies for specified software.
# @description This function manages APT (Advanced Packaging Tool) dependencies based on the input action, software name, and additional options.
# It processes various APT actions like install, update, upgrade, and check. The function uses a YAML file for dependency definitions.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string APT action to perform (install, update, upgrade, check, etc.).
# @arg $2 string Name of the software for dependency management.
# @arg $3 string Additional options (reinstall, non-interactive, inline).
# @stdout Executes apt-get commands based on input parameters.
# @return Exit status of the last executed apt-get command.
# @note Handles APT actions, reinstall, and non-interactive mode.
# @warning `yq` tool is required for parsing YAML files.
zen::dependency::apt::manage() {
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/dependencies.yaml"
	local action="$1"
	local software_name="${2:-}"
	local option="$3"
	local current_os="${4:-}"
	declare -g cmd_options
	declare -g dependencies_string
	declare -g os_specific_dependencies_string

	# Extracting dependencies from the YAML file
	if [[ -n "$software_name" ]]; then
		dependencies_string=$(yq e ".${software_name}.apt" "$dependencies_file")
		if [[ -z "$dependencies_string" ]]; then
			mflibs::status::error "$(zen::i18n::translate "errors.dependency.dependencies_missing" "$software_name")"
			return 1
		fi
	fi

	# Extracting OS-specific dependencies if a valid OS is provided
	if [[ -n "$current_os" ]]; then
		os_specific_dependencies_string=$(yq e ".${software_name}.${current_os}.apt" "$dependencies_file")
		if [[ -n "$os_specific_dependencies_string" ]]; then
			dependencies_string="${dependencies_string} ${os_specific_dependencies_string}"
		fi
	fi

	case "$action" in
	install)
		# shellcheck disable=SC2154
		cmd_options=(-y"${quiet_flag}" --allow-unauthenticated)
		[[ "$option" == "reinstall" ]] && cmd_options+=(--reinstall)
		zen::dependency::apt::install::inline "${dependencies_string}" "${cmd_options[@]}" && return
		;;
	update | upgrade | check)
		cmd_options=("$action" -y"${quiet_flag}")
		apt-get "${cmd_options[@]}" && return
		;;
	*)
		mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_action" "$action")"
		return 1
		;;
	esac
}

# @function zen::dependency::apt::install::inline
# Installs APT dependencies inline with progress display.
# @description This function installs APT dependencies inline, showing the progress. It uses apt-get for installation and dpkg-query to check existing installations.
# Visual feedback is provided with colored output: red for failures and green for successful installations.
# @arg $1 string space-separated list of dependencies to install.
# @stdout On success, displays the number of installed packages; on failure, shows failed package names.
# @note The function checks for existing installations before proceeding with installation.
# @example
#   zen::dependency::apt::install::inline "package1 package2 package3"
zen::dependency::apt::install::inline() {
	mflibs::status::header "$(zen::i18n::translate "headers.dependency.dependencies_install")"
	local dependencies_string="$1"
	local cmd_options=("${@:2}")
	IFS=' ' read -r -a dependencies <<<"$dependencies_string"
	local failed_deps=()
	local installed_count=0
	local last_index=$((${#dependencies[@]} - 1))

	for i in "${!dependencies[@]}"; do
		local dep="${dependencies[i]}"
		if [[ $(dpkg-query -W -f='${Status}' "${dep}" 2>/dev/null | grep -c "ok installed") -ne 1 ]]; then
			# shellcheck disable=SC2154
			if [[ $verbose -eq 1 ]]; then
				mflibs::shell::text::white "$(zen::i18n::translate "headers.dependency.dependency_install" "${dep}")"
				if apt-get install "${cmd_options[@]}" "${dep}"; then
					mflibs::shell::text::green "$(zen::i18n::translate "success.dependency.dependency_install" "${dep}")"
					((installed_count++))
				else
					mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.dependency_install" "${dep}")"
					failed_deps+=("${dep}")
				fi
			else
				if ! apt-get install "${cmd_options[@]}" "${dep}" >/tmp/dep_install_output 2>&1; then
					printf "%s %s %s$(tput setaf 1)✗ $(tput sgr0)" "${dep} " "$(tput sgr0)"
					failed_deps+=("${dep}")
				else
					((installed_count++))
					printf "%s %s %s" "$(tput setaf 4)" "${dep}" "$(tput sgr0)"
				fi
				if [[ $i -ne $last_index ]]; then
					printf "%s|%s" "$(tput setaf 7)" "$(tput sgr0)"
				fi
			fi
		fi
	done
	printf "\n"
	mflibs::status::info "$(zen::i18n::translate "messages.dependency.install_count" "$installed_count")"
	if [[ ${#failed_deps[@]} -gt 0 ]]; then
		mflibs::status::warn "$(zen::i18n::translate "errors.dependency.dependencies_install" "${failed_deps[*]}")"
	fi
	mflibs::status::success "$(zen::i18n::translate "success.dependency.dependencies_install")"
}

# @function zen::dependency::apt::get_string
# Retrieves a comma-separated string of APT dependencies for a given software name from a YAML file.
# @description This function reads a YAML file containing APT dependencies for various software and returns a comma-separated string of dependencies for the specified software name.
# It uses `yq` to parse the YAML file and converts spaces to commas.
# @arg $1 string The name of the software whose dependencies are to be retrieved.
# @arg $2 string The separator to use (comma or space). Defaults to space if not provided.
# @stdout Outputs a string of APT dependencies separated by the specified separator.
# @warning `yq` tool is required for parsing YAML files.
# @example
#   dependencies=$(zen::dependency::apt::get_string "plex" ",")
#   echo "$dependencies" # Outputs: "curl,libssl-dev,ffmpeg"
zen::dependency::apt::get_string() {
	local software_name="$1"
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/dependencies.yaml"
	local separator="${2:- }"
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/dependencies.yaml"
	local dependencies_string
	dependencies_string=$(yq e ".${software_name}.apt" "$dependencies_file")
	if [[ "$separator" == "," ]]; then
		dependencies_string=$(echo "$dependencies_string" | tr ' ' ',')
	fi
	echo "$dependencies_string"
}

# @function zen::dependency::apt::pin
# Manages the list of pinned APT packages by adding or removing packages.
# @description This function modifies the list of APT packages pinned in a preference file.
# It can add a package with an optional version specification or remove an existing package entry.
# The function ensures that the preference file does not contain unnecessary blank lines after modifications.
# @arg $1 string The action to perform ("add" or "remove").
# @arg $2 string The package name to add or remove.
# @arg $3 string Optional: The version to pin the package to (e.g., ">= 2.8.4"). If not specified, the package will be pinned without a version constraint.
# @note The preference file is located at /etc/apt/preferences.d/mediaease.
# @example
#   zen::dependency::apt::pin add "curl" ">= 7.68.0"
#   zen::dependency::apt::pin remove "curl"
zen::dependency::apt::pin() {
	local action="$1"
	local package="$2"
	local pin_spec="${3:-}"
	local preference_file="/etc/apt/preferences.d/mediaease"
	local preference_content
	local updated_content=""
	local entry_found=false
	[[ -f "$preference_file" ]] || touch "$preference_file"
	preference_content=$(<"$preference_file")
	if [[ "$pin_spec" == ">= "* || "$pin_spec" == "<= "* ]]; then
		pin_spec="version ${pin_spec:2}*"
	elif [[ "$pin_spec" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
		pin_spec="version $pin_spec*"
	elif [[ "$pin_spec" != *"release"* ]]; then
		pin_spec="version $pin_spec"
	fi
	while IFS= read -r line; do
		if [[ "$line" == "Package: $package" ]]; then
			entry_found=true
			if [[ "$action" == "remove" ]]; then
				# Skip this package entry (Package, Pin, Pin-Priority)
				read -r line # Skip Pin line
				read -r line # Skip Pin-Priority line
			elif [[ "$action" == "add" ]]; then
				updated_content+="Package: $package\n"
				if [[ -n "$pin_spec" ]]; then
					updated_content+="Pin: $pin_spec\n"
				fi
				updated_content+="Pin-Priority: 1001\n"
			fi
		elif [[ "$line" =~ ^(Package:|Pin:|Pin-Priority:) ]]; then
			if [[ "$entry_found" == true && "$action" == "remove" ]]; then
				continue
			fi
			updated_content+="$line\n"
		else
			updated_content+="$line\n"
		fi
	done <<<"$preference_content"
	if [[ "$action" == "add" ]] && [[ $entry_found == false ]]; then
		[[ -n "$updated_content" ]] && updated_content+="\n"
		updated_content+="Package: $package\n"
		if [[ -n "$pin_spec" ]]; then
			updated_content+="Pin: $pin_spec\n"
		fi
		updated_content+="Pin-Priority: 1001\n"
	fi
	echo -e "$updated_content" >"$preference_file"
}

# @function zen::dependency::apt::update
# Updates package lists and upgrades installed packages.
# @description This function performs system updates using apt-get commands. It updates the package lists and upgrades the installed packages.
# Additionally, it handles locked dpkg situations and logs command execution for troubleshooting.
# @global None.
# @noargs
# @stdout Executes apt-get update, upgrade, autoremove, and autoclean commands.
# @note The function checks for and resolves locked dpkg situations before proceeding.
# @caution Ensure that no other package management operations are running concurrently.
zen::dependency::apt::update() {
	mflibs::status::header "$(zen::i18n::translate "headers.dependency.apt_update")"
	# check if fuser is installed
	if command -v fuser >/dev/null 2>&1; then
		if fuser "/var/lib/dpkg/lock" >/dev/null 2>&1; then
			mflibs::status::warn "$(zen::i18n::translate "errors.dependency.dpkg_locked")"
			mflibs::status::warn "$(zen::i18n::translate "headers.dependency.dpkg_locked_info")"
			rm -f /var/cache/debconf/{config.dat,passwords.dat,templates.dat}
			rm -f /var/lib/dpkg/updates/0*
			find /var/lib/dpkg/lock* /var/cache/apt/archives/lock* -exec rm -rf {} \;
			dpkg --configure -a
			mflibs::log "dpkg --configure -a"
		fi
	fi
	mflibs::log "apt-get -y${quiet_flag} update"
	mflibs::log "apt-get -y${quiet_flag} autoremove"
	mflibs::log "apt-get -y${quiet_flag} autoclean"

	if ! /usr/lib/dpkg/methods/apt/update /var/lib/dpkg/ >/dev/null 2>&1; then
		mflibs::status::error "$(zen::i18n::translate "errors.dependency.apt_update")"
	fi
	if ! apt-get check >/dev/null 2>&1; then
		mflibs::status::error "$(zen::i18n::translate "errors.dependency.apt_check")"
	fi

	mflibs::status::success "$(zen::i18n::translate "success.dependency.apt_update")"
}

# @function zen::dependency::apt::remove
# Removes APT dependencies not needed by other software.
# @description This function removes APT dependencies that are no longer needed by other installed software.
# It reads dependencies from a YAML file and checks for exclusive use before removing them.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string Name of the software for dependency removal.
# @stdout Removes unused APT dependencies of the specified software.
# @note The function considers dependencies listed for the specified software in the YAML configuration.
# @caution Ensure that the dependencies are not required by other software before removal.
zen::dependency::apt::remove() {
	local software_name="$1"
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/dependencies.yaml"
	local installed_count
	installed_count=$(zen::software::is::installed "$software_name" "*" | wc -l)
	if [[ $installed_count -le 1 ]]; then
		local software_dependencies
		software_dependencies=$(yq e ".${software_name}.apt" "$dependencies_file" 2>/dev/null)
		local zen_dependencies
		zen_dependencies=$(yq e ".mediaease.apt" "$dependencies_file" 2>/dev/null)
		local remove_dependencies
		remove_dependencies=$(comm -23 <(tr ' ' '\n' <<<"$software_dependencies" | sort -u) <(tr ' ' '\n' <<<"$zen_dependencies" | sort -u) | tr '\n' ' ')

		mflibs::log "apt-get remove -y $remove_dependencies"
		mflibs::log "apt-get purge -y $remove_dependencies"
		mflibs::log "apt-get autoremove -y"
		mflibs::log "apt-get autoclean -y"
	fi
}

# @function zen::dependency::external::install
# Installs all external dependencies for a specified application.
# @description This function installs external dependencies for a specified application as defined in a YAML configuration file.
# It creates temporary scripts for each external dependency's install command and executes them.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string The name of the application for which to install external dependencies.
# @stdout Executes installation commands for each external dependency of the specified application.
# @note Iterates over the external dependencies in the YAML file and executes their install commands.
# @warning Ensure the external dependencies do not conflict with existing installations.
zen::dependency::external::install() {
	local app_name="$1"
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/dependencies.yaml"
	if [[ -z "$app_name" ]]; then
		mflibs::status::error "errors.dependency.external_dependencies_missing"
	fi
	# Parsing each external dependency
	mflibs::status::header "$(zen::i18n::translate "headers.dependency.external_dependencies_install" "$app_name")"
	local entries
	entries=$(yq e ".${app_name}.external[] | to_entries[]" "$dependencies_file")
	local software_name install_command
	while IFS= read -r line; do
		if [[ $line == key* ]]; then
			software_name=$(echo "$line" | awk '{print $2}')
		elif [[ $line == value* ]]; then
			install_command=$(yq e ".${app_name}.external[] | select(has(\"$software_name\")) | .${software_name}.install" "$dependencies_file")
			local temp_script="temp_install_$software_name.sh"
			echo "#!/bin/bash" >"$temp_script"
			echo "export BASH_XTRACEFD=2" >>"$temp_script"
			echo "$install_command" >>"$temp_script"
			chmod +x "$temp_script"
			mflibs::log "./$temp_script"
			local install_status=$?
			rm "$temp_script" 2>/dev/null

			if [[ $install_status -ne 0 ]]; then
				mflibs::status::error "$(zen::i18n::translate "errors.dependency.external_dependencies_install" "$software_name" "$app_name" "$install_status")"
			fi
		fi
	done <<<"$entries"
	mflibs::status::success "$(zen::i18n::translate "success.dependency.external_dependencies_install" "$app_name")"
}

# @function zen::dependency::apt::add_source
# # Adds a new APT source and its GPG key.
# @description This function adds new APT sources and their corresponding GPG keys from a YAML configuration file.
# It handles different options like architecture, inclusion of source repositories, and GPG key processing.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @arg $1 string|array Name of the source(s) as specified in the YAML configuration.
# @stdout Adds new APT source(s) and GPG key(s) based on the YAML configuration.
# @note The function evaluates and applies settings from the YAML configuration for the specified source(s).
# @caution Ensure the GPG key is from a trusted source to avoid security risks.
# @important The architecture specified must match the system architecture.
# @example
#   zen::dependency::apt::add_source "php"
#   zen::dependency::apt::add_source "php" "nginx"
zen::dependency::apt::add_source() {
	local sources=("$@")
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/apt_sources.yaml"
	local counter=0
	local total_sources=${#sources[@]}
	for source_name in "${sources[@]}"; do
		local debug
		[[ " ${MFLIBS_LOADED[*]} " =~ debug ]] && debug=1
		local failed=false
		[[ $debug -eq 1 ]] && printf "Debug: Processing source: %s\n" "$source_name"
		if [[ -z "$source_name" ]]; then
			failed=true
			mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.source_name_missing")"
		fi
		local source_url_template source_url arch include_deb_src gpg_key_url recv_keys trusted_key_url
		source_url_template=$(yq e ".sources.${source_name}.url" "$dependencies_file")
		source_url=$(eval echo "$source_url_template")
		arch=$(yq e ".sources.${source_name}.options.arch" "$dependencies_file")
		include_deb_src=$(yq e ".sources.${source_name}.options.deb-src" "$dependencies_file" | grep -v 'null')
		gpg_key_url=$(yq e ".sources.${source_name}.options.gpg-key" "$dependencies_file" | grep -v 'null')
		[[ $debug -eq 1 ]] && printf "Debug: Source URL: %s, Arch: %s, Include Deb-src: %s, GPG Key URL: %s\n" "$source_url" "$arch" "$include_deb_src" "$gpg_key_url"
		if yq e ".sources.${source_name}.options.recv-keys" "$dependencies_file" | grep -qv 'null'; then
			recv_keys=$(yq e ".sources.${source_name}.options.recv-keys" "$dependencies_file")
		fi
		if yq e ".sources.${source_name}.options.trusted-key" "$dependencies_file" | grep -qv 'null'; then
			trusted_key_url=$(yq e ".sources.${source_name}.options.trusted-key" "$dependencies_file")
		fi
		if [[ -z "$source_url" ]]; then
			failed=true
			mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.source_url_missing" "$source_name")"
		fi
		if [[ -n "$arch" && "$arch" != "null" && "$arch" != "$(dpkg --print-architecture)" ]]; then
			failed=true
			mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.apt_architecture_mismatch" "$arch" "$(dpkg --print-architecture)")"
		fi
		if [[ "$failed" == false ]]; then
			if [[ -n "$gpg_key_url" ]]; then
				local gpg_key_file
				gpg_key_file="/usr/share/keyrings/${source_name}.gpg"
				[[ -f "$gpg_key_file" ]] && {
					sudo rm "$gpg_key_file"
					[[ $debug -eq 1 ]] && printf "Debug: Removed existing GPG key file: %s\n" "$gpg_key_file"
				}
				wget -qO- "$gpg_key_url" | sudo gpg --dearmor -o "$gpg_key_file" || {
					mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.apt_gpg_key_add" "$source_name")"
					failed=true
				}
				printf "deb [signed-by=%s] %s\n" "$gpg_key_file" "$source_url" >"/etc/apt/sources.list.d/${source_name}.list"
				[[ $debug -eq 1 ]] && printf "Debug: Added GPG key for %s\n" "$source_name"
				[[ "$include_deb_src" == "true" ]] && {
					printf "deb-src [signed-by=%s] %s\n" "$gpg_key_file" "$source_url" >>"/etc/apt/sources.list.d/${source_name}.list"
				}
			else
				printf "deb %s\n" "$source_url" >"/etc/apt/sources.list.d/${source_name}.list"
				[[ "$include_deb_src" == "true" ]] && {
					printf "deb-src %s\n" "$source_url" >>"/etc/apt/sources.list.d/${source_name}.list"
				}
			fi
			if [[ -n "$recv_keys" && "$recv_keys" != "null" ]]; then
				sudo gpg --no-default-keyring --keyring "/usr/share/keyrings/${source_name}.gpg" --keyserver keyserver.ubuntu.com --recv-keys "$recv_keys" || {
					mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.apt_recv_keys" "$source_name")"
					failed=true
				}
				[[ $debug -eq 1 ]] && printf "Debug: Received keys for %s\n" "$source_name"
			fi
			if [[ -n "$trusted_key_url" ]]; then
				[[ -f "$gpg_key_file" ]] && {
					sudo rm "/etc/apt/trusted.gpg.d/${source_name}.gpg"
					[[ $debug -eq 1 ]] && printf "Debug: Removed existing trusted key file for %s source\n" "$source_name"
				}
				wget -qO- "$trusted_key_url" | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${source_name}.gpg" || {
					mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.apt_trusted_key_add" "$source_name")"
					failed=true
					[[ $debug -eq 1 ]] && printf "Debug: Failed to add trusted key for %s from %s\n" "$source_name" "$trusted_key_url"
				}
			fi
		else
			mflibs::status::error "$(zen::i18n::translate "errors.dependency.apt_add_source" "$source_name")"
		fi
		if [[ $debug -eq 0 ]]; then
			if [[ "$failed" == false ]]; then
				mflibs::shell::icon::check::green
				mflibs::shell::text::white::sl "$source_name"
			else
				mflibs::shell::icon::cross::red
				mflibs::shell::text::white::sl "$source_name"
			fi
			[[ $counter -lt $((total_sources - 1)) && "$failed" == false ]] && printf " | "
		else
			status_icon=$(
				if [[ "$failed" == false ]]; then
					printf "Debug: Successfully added %s source" "$source_name"
				else
					printf "Debug: Failed to add %s source" "$source_name"
				fi
			)
			printf "%s\n" "$status_icon"
		fi
		[[ "$failed" == false ]] && counter=$((counter + 1))
	done
	printf "\n"
	mflibs::status::info "$(zen::i18n::translate "messages.dependency.add_source_count" "$counter" "$total_sources")"
}

# @function zen::dependency::apt::remove_source
# Removes an APT source and its GPG key.
# @description This function removes an APT source and its GPG key.
# It deletes the corresponding source list files and GPG keys for the specified source.
# @arg $1 string Name of the source to be removed.
# @stdout Removes specified APT source and its GPG key.
# @caution Removing a source can impact system stability if other packages depend on it.
zen::dependency::apt::remove_source() {
	local source_name="$1"

	if [[ -z "$source_name" ]]; then
		printf "Source name is required.\n"
		return 1
	fi
	local files_to_remove=(
		"/etc/apt/sources.list.d/${source_name}.list"
		"/usr/share/keyrings/${source_name}.gpg"
		"/etc/apt/trusted.gpg.d/${source_name}.gpg"
	)

	for file in "${files_to_remove[@]}"; do
		rm -f "$file"
	done

	mflibs::status::success "$(zen::i18n::translate "success.dependency.apt_source_remove" "$source_name")"
}

# @function zen::dependency::apt::update_source
# Updates APT sources based on a YAML configuration.
# @description This function updates APT sources based on the definitions in the apt_sources.yaml file.
# It recreates source list files and GPG keys for each source defined in the configuration.
# @global MEDIAEASE_HOME string Path to MediaEase configurations.
# @stdout Updates APT sources and GPG keys based on the YAML configuration.
# @note The function iterates over all sources defined in the YAML file and applies their configurations.
zen::dependency::apt::update_source() {
	local dependencies_file="${MEDIAEASE_HOME}/zen/src/apt_sources.yaml"
	local source_names
	source_names=$(yq e '.sources | keys' "$dependencies_file")

	for source_name in $source_names; do
		source_url=$(yq e ".sources.${source_name}.url" "$dependencies_file" | grep -v 'null')
		[[ -z "$source_url" ]] && {
			printf "URL for %s not found in YAML file.\n" "$source_name"
			continue
		}
		include_deb_src=$(yq e ".sources.${source_name}.options.deb-src" "$dependencies_file" | grep -v 'null')
		gpg_key_url=$(yq e ".sources.${source_name}.options.gpg-key" "$dependencies_file" | grep -v 'null')
		if [[ -n "$gpg_key_url" ]]; then
			local gpg_key_file
			gpg_key_file="/usr/share/keyrings/${source_name}.gpg"
			[[ -f "$gpg_key_file" ]] && sudo rm "$gpg_key_file"
			wget -qO- "$gpg_key_url" | sudo gpg --dearmor -o "$gpg_key_file" || {
				mflibs::status::error "$(zen::i18n::translate "errors.dependency.apt_gpg_key_add" "$source_name")"
			}
			echo "deb [signed-by=$gpg_key_file] $source_url" >"/etc/apt/sources.list.d/${source_name}.list"
			[[ "$include_deb_src" == "true" ]] && echo "deb-src [signed-by=$gpg_key_file] $source_url" >>"/etc/apt/sources.list.d/${source_name}.list"
		else
			echo "deb $source_url" >"/etc/apt/sources.list.d/${source_name}.list"
			[[ "$include_deb_src" == "true" ]] && echo "deb-src $source_url" >>"/etc/apt/sources.list.d/${source_name}.list"
		fi
		trusted_key_url=$(yq e ".sources.${source_name}.options.trusted-key" "$dependencies_file" | grep -v 'null')
		if [[ -n "$trusted_key_url" ]]; then
			wget -qO- "$trusted_key_url" | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${source_name}.gpg" || {
				mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.apt_trusted_key_add" "$source_name")"
				continue
			}
		fi
		recv_keys=$(yq e ".sources.${source_name}.options.recv-keys" "$dependencies_file" | grep -v 'null')
		if [[ -n "$recv_keys" ]]; then
			sudo gpg --no-default-keyring --keyring "/usr/share/keyrings/${source_name}.gpg" --keyserver keyserver.ubuntu.com --recv-keys "$recv_keys" || {
				mflibs::shell::text::red "$(zen::i18n::translate "errors.dependency.apt_recv_keys" "$source_name")"
				continue
			}
		fi
		unset source_url include_deb_src gpg_key_url trusted_key_url recv_keys
	done
}
