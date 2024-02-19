#!/usr/bin/bash
# @function zen::vault::init
# @internal
# @description Initializes the vault by setting up the salt and secret key.
# @global credentials_file Path to the credentials file.
# @note Creates a salt file if not present and sets up the credentials
# @note $vault_name is a global variable
zen::vault::init() {
    local salt hash
    declare salt_file="/root/.mediaease/config"
    declare vault_base_dir="/etc/.mediaease"

    if [[ -f "$salt_file" ]]; then
        salt=$(head -n 1 "$salt_file")
        printf "Salt found\n"
    else
        zen::vault::create
    fi

    # Hashing to determine vault path
    # vault_name is a global variable
    # shellcheck disable=SC2154 
    hash=$(echo -n "${vault_name}${salt}" | sha256sum | cut -d' ' -f1)
    local vault_dir="${vault_base_dir}/${hash:0:32}"
    local vault_file="${hash:32}.yaml"

    declare -g credentials_file="${vault_dir}/${vault_file}"

    if [[ -f "$credentials_file" ]]; then
        mflibs::status::info "$(zen::i18n::translate "vault.credentials_file_found")"
    else
        mflibs::status::error "$(zen::i18n::translate "vault.credentials_file_not_found")"
        return 1
    fi

    export credentials_file
}

# @function zen::vault::create
# @internal
# @description Creates the vault, including the generation and storage of the salt key.
# @global vault_name The name of the vault.
# @note The salt key is stored in a file and the vault is created in the /etc/.mediaease directory.
zen::vault::create() {
    local user_salt salt hash vault_dir vault_file
    declare salt_file="/root/.mediaease/config"
    declare vault_base_dir="/etc/.mediaease"

    read -r -sp "Enter your salt key: " user_salt
    echo

    # Encode user provided salt in base64 and store it
    salt=$(echo -n "$user_salt" | base64)
    echo "$salt" > "$salt_file"
    chmod 600 "$salt_file"
    chattr +i "$salt_file"
    mflibs::status::info "$(zen::i18n::translate "vault.salt_stored")"

    # Hashing to determine vault path
    hash=$(echo -n "${vault_name}${salt}" | sha256sum | cut -d' ' -f1)
    vault_dir="${vault_base_dir}/${hash:0:32}"
    vault_file="${hash:32}.yaml"

    # Create the vault directory and file
    mkdir -p "$vault_dir"
    chmod 700 "$vault_dir"
    declare -g credentials_file="${vault_dir}/${vault_file}"
    touch "$credentials_file"
    zen::vault::permissions "add"

    mflibs::status::success "$(zen::i18n::translate "vault.vault_created")"
}

# @function zen::vault::permissions
# @internal
# @description Updates the permissions of the credentials file.
# @arg $1 string The action to be performed on the file.
# @note Adds or removes permissions based on the action provided.
# @example zen::vault::permissions "add"
# @example zen::vault::permissions "remove"
zen::vault::permissions(){
    local action="$1"
    
    if [[ "$action" == "add" ]]; then
        mflibs::status::info "$(zen::i18n::translate "vault.adding_permissions")"
        mflibs::log "chown -R root:root $credentials_file"
        mflibs::log "chmod -R 700 $credentials_file"
        mflibs::log "chattr +i $credentials_file"
    elif [[ "$action" == "remove" ]]; then
        mflibs::status::info "$(zen::i18n::translate "vault.removing_permissions")"
        mflibs::log "chattr -i $credentials_file"
        mflibs::log "chmod -R 755 $credentials_file"
        mflibs::log "chown -R root:root $credentials_file"
    else
        mflibs::status::error "$(zen::i18n::translate "vault.invalid_action" "$action")"
        return 1
    fi

    mflibs::status::success "$(zen::i18n::translate "vault.permissions_updated")"
}
