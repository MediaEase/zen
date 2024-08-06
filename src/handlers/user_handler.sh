#!/usr/bin/env bash

# @file: handlers/user_handler.sh
# @project MediaEase
# @version 1.0.0
# @description A handler for user management commands.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::user::handle_action
# @description Handles the specified action for user management.
# @arg $1 string The action to be performed (add, remove, ban, etc.).
# @arg $2 string The username.
# @arg $3 string Additional parameters like email, password, quota.
# @stdout Executes the appropriate action for user management.
# @note Processes user-related actions and performs necessary operations.
# @example
#   zen::user::handle_action "add" "username" "email" "password" "quota"
# @example
#   zen::user::handle_action "remove" "username"
# @example
#   zen::user::handle_action "ban" "username" "duration"
# @example
#   zen::user::handle_action "unban" "username"
# @example
#   zen::user::handle_action "set" "username" "key" "value"
zen::user::handle_action() {
	local action="$1"
	local username="$2"
	local email="$3"
	local password="$4"
	local quota="$5"
	local duration="$6"
	local key="$7"
	local value="$8"

	case "$action" in
	add)
		zen::user::add "$username" "$email" "$password" "$quota"
		;;
	remove)
		zen::user::remove "$username"
		;;
	ban)
		if [[ -n "$duration" ]]; then
			zen::user::ban "$username" "$duration"
		else
			zen::user::ban "$username"
		fi
		;;
	unban)
		zen::user::unban "$username"
		;;
	set)
		zen::user::set "$username" "$key" "$value"
		;;
	*)
		mflibs::status::error "$(zen::i18n::translate "user.invalid_action" "$action")"
		exit 1
		;;
	esac
}

# @function zen::user::args::process
# @description Processes command-line arguments for user management commands.
# @arg $@ array Command-line arguments.
# @stdout Parses action, username, and other options from the arguments.
# @note Processes options like -e for email, -p for password, -q for quota in any order.
zen::user::args::process() {
	declare -g user_action username email password quota duration key value

	if [[ $# -lt 2 ]]; then
		mflibs::status::error "$(zen::i18n::translate "user.insufficient_arguments")"
		exit 1
	fi

	user_action="$1"
	shift
	username="$1"
	shift

	while (("$#")); do
		case "$1" in
		-e)
			email="$2"
			shift 2
			;;
		-p)
			password="$2"
			shift 2
			;;
		-q)
			quota="$2"
			shift 2
			;;
		-d)
			duration="$2"
			shift 2
			;;
		-k)
			key="$2"
			shift 2
			;;
		-v)
			value="$2"
			shift 2
			;;
		*)
			mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_option" "$1")"
			exit 1
			;;
		esac
	done

	zen::user::handle_action "$user_action" "$username" "$email" "$password" "$quota" "$duration" "$key" "$value"
}

# Main execution flow
zen::user::args::process "$@"
