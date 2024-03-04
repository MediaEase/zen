#!/usr/bin/env bash
# @file modules/user.sh
# @project MediaEase
# @version 1.0.0
# @description A library for internationalization functions.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::user::create
# @description Creates a new system user with specified attributes.
# @arg $1 string The username for the new user.
# @arg $2 string The password for the new user.
# @arg $3 string Indicates if the user should have admin privileges ('true' or 'false').
# @return 0 if the user is created successfully, 1 otherwise.
# @note For non-admin users, the shell is restricted; admin users get sudo privileges without a password requirement.
zen::user::create() {
    local username="$1"
    local password="$2"
    local is_admin="$3" # true or false
    local theshell="/bin/bash"

    # If the user is not an admin, restrict the shell
    [ "$is_admin" == false ] && theshell="/bin/rbash"
    mflibs::status::header "$(zen::i18n::translate "user.creating_user" "$username")"
    mflibs::log "useradd ${username} -m -G www-data -s ${theshell}"
    if [[ -n "${password}" ]]; then
        zen::user::password::set "${username}" "${password}"
        zen::vault::pass::store "${username}.main" "${password}"
    else
        password=$(zen::user::password::generate 16)
        zen::user::password::set "${username}" "${password}"
        zen::vault::pass::store "${username}.main" "${password}"
    fi
    [ "$is_admin" == true ] && echo "${username} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
    mkdir -p /home/"${username}"/.config /home/"${username}"/.mediaease/backups /opt/"${username}"
    setfacl -R -m u:"${username}":rwx /home/"${username}" /opt/"${username}"
    mflibs::status::success "$(zen::i18n::translate "user.user_created" "$username")"
}

# @function zen::user::groups::upgrade
# @description Adds a user to a specified system group.
# @arg $1 string The username of the user to add to the group.
# @arg $2 string The name of the group to which the user should be added.
# @return 0 if the user is added to the group successfully, 1 otherwise.
# @note Handles different groups including sudo, media, download, and streaming.
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

# @function zen::user::groups::create_groups
# @description Creates default system groups for application usage.
# @return 0 if the groups are created successfully, 1 otherwise.
# @note Creates predefined groups like media, download, streaming, and default.
zen::user::groups::create_groups() {
    local groups=("full" "download" "streaming" "automation")
    mflibs::status::header "$(zen::i18n::translate "user.creating_default_groups")"
    for group in "${groups[@]}"; do
        if ! grep -q "^${group}:" /etc/group; then
            mflibs::log "groupadd ${group}"
        fi
    done
    mflibs::status::success "$(zen::i18n::translate "user.default_groups_created")"
}

# @function zen::user::check
# @description Checks if the currently loaded user is a valid MediaEase user.
# @global username The username of the user to check.
# @global users_all An array of all users on the system.
# @return Exits with 1 if the user is not found or is not a MediaEase user.
# shellcheck disable=SC2154
# Disable SC2154 because the variable is defined in the main script
zen::user::check() {
    [[ -z ${username} && ${function_process} != "help" ]] && { mflibs::status::error "$(zen::i18n::translate "user.user_not_found" "${username}")" && zen::lock::cleanup && exit 1; }
    [[ ${users_all[*]} != *"${username}"* ]] && { mflibs::status::error "$(zen::i18n::translate "user.user_not_mediaease_user" "${username}")" && zen::lock::cleanup && exit 1; }
}

# @function zen::user::is::admin
# @description Checks if the currently loaded user is an administrator.
# @return 0 if the user is an admin, 1 otherwise.
# @note User must be loaded with zen::user::load before calling this function.
zen::user::is::admin() {
    [[ "${user['roles']}" == *'"ROLE_ADMIN"'* ]] && { mflibs::status::info "$(zen::i18n::translate "user.user_is_admin")" || mflibs::status::error "$(zen::i18n::translate "user.user_is_not_admin")"; zen::lock::cleanup; exit 1;}
    return 1
}

# @function zen::multi::check::id
# @description Retrieves the ID of a specified user from the system.
# @arg $1 string The username for which to retrieve the ID.
# @return The ID of the user if found.
zen::multi::check::id() {
    [[ -n $1 ]] && zen::database::select "id" "user" "username='${1}'"
}

# @function zen::user::load
# @description Loads a specified user's data into a globally accessible associative array.
# @arg $1 string The username of the user to load.
# @global user An associative array populated with the user's data.
# @return Exits with 1 if the user is not found.
# @note Queries the database and populates the 'user' array with the user's data.
# shellcheck disable=SC2034
# Disable SC2034 because the variable is defined in the main script
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

# @function zen::user::ban
# @description Bans a user either permanently or for a specified duration.
# @arg $1 string The username to ban.
# @arg $2 string Optional duration in days for the ban.
zen::user::ban() {
    local username="$1"
    local duration="$2"

    if [[ -n "$duration" ]]; then
        mflibs::status::info "$(zen::i18n::translate "user.banning_user" "$username" "$duration")"
        zen::database::update "user" "is_banned=1, ban_end_date=DATE_ADD(NOW(), INTERVAL $duration DAY)" "username='$username'"
    else
        mflibs::status::info "$(zen::i18n::translate "user.banning_user" "$username")"
        zen::database::update "user" "is_banned=1" "username='$username'"
    fi
}

# @section Password Management
# @function zen::user::password::generate
# @description Generates a random password of a specified length.
# @arg $1 int The length of the password to generate.
# @return A randomly generated password.
zen::user::password::generate() {
    local length="$1"
    tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "${length}" | head -n 1
}

# @function zen::user::password::set
# @description Sets a password for a specified user.
# @arg $1 string The username of the user for whom to set the password.
# @arg $2 string The password to set for the user.
# @return 0 if the password is set successfully, 1 otherwise.
# @note The password is also added to the system's htpasswd file for HTTP authentication.
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
