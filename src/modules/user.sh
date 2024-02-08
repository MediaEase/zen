#!/bin/bash
################################################################################
# @file_name: user.sh
# @version: 1.0.0
# @project_name: MediaEase
# @description: a library for internationalization functions
#
# @author: Thomas Chauveau (tomcdj71)
# @author_contact: thomas.chauveau.pro@gmail.com
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2024, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# zen::user::create
#
# Creates a new system user with specified attributes.
#
# Arguments:
#   username - The username for the new user.
#   password - The password for the new user.
#   is_admin - Indicates if the user should have admin privileges ('true' or 'false').
# Returns:
#   0 if the user is created successfully, 1 otherwise.
# Notes:
#   If the user is not an admin, the shell is restricted. For admin users, sudo
#   privileges are added without a password requirement.
################################################################################
zen::user::create() {
    local username="$1"
    local password="$2"
    local is_admin="$3" # true or false
    local theshell="/bin/bash"

    # If the user is not an admin, restrict the shell
    [ "$is_admin" == "false" ] && theshell="/bin/rbash"
    mflibs::status::info "$(zen::i18n::translate "user.creating_user" "$username")"
    mflibs::log "useradd ${username} -m -G www-data -s ${theshell}"
    if [[ -n "${password}" ]]; then
        zen::user::password::set "${username}" "${password}"
    else
        password=$(zen::user::password::generate 16)
        zen::user::password::set "${username}" "${password}"
    fi
    [ "$is_admin" == "true" ] && echo "${username} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
    mkdir -p /home/"${username}"/.config /home/"${username}"/.mediaease/backups /opt/"${username}"
    setfacl -R -m u:"${username}":rwx /home/"${username}" /opt/"${username}"
    mflibs::status::success "$(zen::i18n::translate "user.user_created" "$username")"
}

################################################################################
# zen::user::password::set
#
# Sets a password for a specified user.
#
# Arguments:
#   username - The username of the user for whom to set the password.
#   password - The password to set for the user.
# Returns:
#   0 if the password is set successfully, 1 otherwise.
# Notes:
#   The password is also added to the system's htpasswd file for HTTP authentication.
################################################################################
zen::user::password::set() {
    local username="$1"
    local password="$2"
    mflibs::status::info "$(zen::i18n::translate "user.setting_password_for" "$username")"
    echo "${username}:${password}" | chpasswd 2>/dev/null
    printf "%s:\$(openssl passwd -apr1 %s)\n" "$username" "$password" >> /etc/htpasswd
    mkdir -p /etc/htpasswd.d
    printf "%s:\$(openssl passwd -apr1 %s)\n" "$username" "$password" >> /etc/htpasswd.d/htpasswd."${username}"
    mflibs::status::success "$(zen::i18n::translate "user.password_set" "$username")"
}

################################################################################
# zen::user::password::generate
#
# Generates a random password of a specified length.
#
# Arguments:
#   length - The length of the password to generate.
# Returns:
#   A randomly generated password.
################################################################################
zen::user::password::generate() {
    local length="$1"
    tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "${length}" | head -n 1
}

################################################################################
# zen::user::groups::upgrade
#
# Adds a user to a specified system group.
#
# Arguments:
#   username - The username of the user to add to the group.
#   group - The name of the group to which the user should be added.
# Returns:
#   0 if the user is added to the group successfully, 1 otherwise.
# Notes:
#   Handles different groups including sudo, media, download, and streaming.
################################################################################
zen::user::groups::upgrade() {
    local username="$1"
    local group="$2"

    if [[ "$group" == "sudo" ]]; then
        mflibs::status::info "$(zen::i18n::translate "user.adding_user_to_group" "$username" "$group")"
        mflibs::log "usermod -aG sudo ${username}"
        mflibs::log "echo \"${username} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers"
    elif [[ "$group" == "media" ]]; then
        mflibs::status::info "$(zen::i18n::translate "user.adding_user_to_group" "$username" "$group")"
        mflibs::log "usermod -aG media ${username}"
    elif [[ "$group" == "download" ]]; then
        mflibs::status::info "$(zen::i18n::translate "user.adding_user_to_group" "$username" "$group")"
        mflibs::log "usermod -aG download ${username}"
    elif [[ "$group" == "streaming" ]]; then
        mflibs::status::info "$(zen::i18n::translate "user.adding_user_to_group" "$username" "$group")"
        mflibs::log "usermod -aG streaming ${username}"
    elif [[ "$group" == "default" ]]; then
        mflibs::status::info "$(zen::i18n::translate "user.adding_user_to_group" "$username" "$group")"
        mflibs::log "usermod -aG default ${username}"
    else
        mflibs::status::error "$(zen::i18n::translate "user.invalid_group" "$group")"
        return 1
    fi
    mflibs::status::success "$(zen::i18n::translate "user.user_added_to_group" "$username" "$group")"
}

################################################################################
# zen::user::groups::create_groups
#
# Creates default system groups for application usage.
#
# No arguments.
# Returns:
#   0 if the groups are created successfully, 1 otherwise.
# Notes:
#   Creates a set of predefined groups like media, download, streaming, and default.
################################################################################
zen::user::groups::create_groups() {
    local groups=("media" "download" "streaming" "default")
    mflibs::status::info "$(zen::i18n::translate "user.creating_default_groups")"
    for group in "${groups[@]}"; do
        if ! grep -q "^${group}:" /etc/group; then
            mflibs::log "groupadd ${group}"
        fi
    done
    mflibs::status::success "$(zen::i18n::translate "user.default_groups_created")"
}

################################################################################
# zen::user::check
#
# Checks if a specified user exists and is a valid MediaEase user.
#
# Arguments:
#   username - The username of the user to check.
# Returns:
#   Exits with 1 if the user is not found or is not a valid MediaEase user.
# Notes:
#   This function is used to validate user existence before performing user-specific operations.
# shellcheck disable=SC2154
# Disable SC2154 because the variable is defined in the main script
################################################################################
zen::user::check() {
    [[ -z ${username} && ${function_process} != "help" ]] && { mflibs::status::error "$(zen::i18n::translate "user.user_not_found" "${username}")" && zen::lock::cleanup && exit 1; }
    [[ ${users_all[*]} != *"${username}"* ]] && { mflibs::status::error "$(zen::i18n::translate "user.user_not_mediaease_user" "${username}")" && zen::lock::cleanup && exit 1; }
}

################################################################################
# zen::user::is::admin
#
# Checks if the currently loaded user is an administrator.
#
# No arguments.
# Returns:
#   0 if the user is an admin, 1 otherwise.
# Usage:
#   if [[ $(zen::user::is::admin) ]]; then echo "I'm Admin!"; else echo "I'm not Admin!"; fi
# Prerequisites:
#   User must be loaded with zen::user::load before calling this function.
################################################################################
zen::user::is::admin() {
    [[ "${user['roles']}" == *'"ROLE_ADMIN"'* ]] && { mflibs::status::info "$(zen::i18n::translate "user.user_is_admin")" || mflibs::status::error "$(zen::i18n::translate "user.user_is_not_admin")"; zen::lock::cleanup; exit 1;}
    return 1
}

################################################################################
# zen::multi::check::id
#
# Retrieves the ID of a specified user from the system.
#
# Arguments:
#   username - The username for which to retrieve the ID.
# Returns:
#   The ID of the user if found.
################################################################################
zen::multi::check::id() {
	[[ -n $1 ]] && zen::database::select "id" "user" "username='${1}'"
}

################################################################################
# zen::user::load
#
# Loads a specified user's data into a globally accessible associative array.
#
# Arguments:
#   username - The username of the user to load.
# Globals:
#   user - An associative array that will be populated with the user's data.
# Returns:
#   Exits with 1 if the user is not found.
# Notes:
#   This function queries the database and populates the 'user' global array with
#   the user's data. It's used to access user-specific information in other functions.
# shellcheck disable=SC2034
# Disable SC2034 because the variable is defined in the main script
################################################################################
zen::user::load(){
    declare -A -g user
    local username="$1"
    local where_clause="username = '$username'"
    user_columns=("id" "group_id" "preference_id" "username" "roles" "password" "email" "is_verified" "apikey")
    zen::database::load_config "$(zen::database::select "*" "user" "$where_clause")" "user" 3 "user_columns"
    if [[ -z "${user[username]}" ]]; then
        mflibs::shell::text::red "$(zen::i18n::translate "user.user_not_found" "${username}")"
        zen::lock::cleanup
        exit 1
    # else 
        # mflibs::shell::text::green "$(zen::i18n::translate "user.user_found" "${username}")"
    fi
}
