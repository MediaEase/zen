#!/bin/bash

################################################################################
# @description: Create a new user
# @arg: $1: username
# @arg: $2: password
# @arg: $3: is_admin
# @return_code: Returns 0 if the user is created, 1 otherwise
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
# @description: Set a password for a user
# @arg: $1: username
# @arg: $2: password
# @return_code: Returns 0 if the password is set, 1 otherwise
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
# @description: Generate a random password
# @arg: $1: length
# @return_code: Returns 0 if the password is generated, 1 otherwise
################################################################################
zen::user::password::generate() {
    local length="$1"
    tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "${length}" | head -n 1
}

################################################################################
# @description: Add a user to a system group
# @arg: $1: username
# @arg: $2: group
# @return_code: Returns 0 if the user is added to the group, 1 otherwise
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
# @description: Create default groups
# @noargs
# @return_code: Returns 0 if the groups are created, 1 otherwise
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
# @description: zen user commands
# @arg: $1: username
# shellcheck disable=SC2154
################################################################################
zen::user::check() {
    [[ -z ${username} && ${function_process} != "help" ]] && { mflibs::status::error "$(zen::i18n::translate "user.user_not_found" "${username}")" && zen::lock::cleanup && exit 1; }
    [[ ${users_all[*]} != *"${username}"* ]] && { mflibs::status::error "$(zen::i18n::translate "user.user_not_mediaease_user" "${username}")" && zen::lock::cleanup && exit 1; }
}

################################################################################
# @description: Check if the user is an admin
# @return_code: Returns 0 if the user is an admin, 1 otherwise
# @usage : if [[ $(zen::user::is::admin) ]]; then echo "I'm Admin !" ; else echo "I'm not Admin !" ; fi
# @prerequesites : zen::user::load "$username"
# shellcheck disable=SC2154
################################################################################
zen::user::is::admin() {
    [[ "${user['roles']}" == *'"ROLE_ADMIN"'* ]] && { mflibs::status::info "$(zen::i18n::translate "user.user_is_admin")" || mflibs::status::error "$(zen::i18n::translate "user.user_is_not_admin")"; zen::lock::cleanup; exit 1;}
    return 1
}

################################################################################
# @description: zen user commands
# @arg: $1: username
# shellcheck disable=SC2154
################################################################################
zen::multi::check::id() {
	[[ -n $1 ]] && zen::database::select "id" "user" "username='${1}'"
}

################################################################################
# @description: zen user commands
# @arg: $1: username
# shellcheck disable=SC2034
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
