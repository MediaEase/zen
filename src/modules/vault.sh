#!/usr/bin/env bash
# @file modules/vault.sh
# @project MediaEase
# @version 1.1.50
# @description A library for managing the secure vault in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @section Vault Functions
# @description The following functions handle the creation and management of the vault.
# @warning The vault is a secure storage location for sensitive information. Ensure that the vault is secure and that only authorized users have access to it.
# @important This module is purely internal. No modifications are allowed for security reasons. All functions are noted as '@internal' so the documentation generator will ignore them.

# @function zen::vault::init
# @internal
# @description Initializes the vault by setting up the salt and secret key.
# @global credentials_file Path to the credentials file.
# @note Creates a salt file if not present and sets up the credentials
# @note $vault_name is a global variable
zen::vault::init() {
	local hash
	declare salt_file="/root/.mediaease/config"
	declare vault_base_dir="/etc/.mediaease"

	if [[ -f "$salt_file" ]]; then
		salt=$(head -n 1 "$salt_file")
	else
		zen::vault::create
	fi

	if [[ ! -f "$credentials_file" ]]; then
		# Hashing to determine vault path
		# vault_name is a global variable
		# shellcheck disable=SC2154
		hash=$(echo -n "${vault_name}${salt}" | sha256sum | cut -d' ' -f1)
		local vault_dir="${vault_base_dir}/${hash:0:32}"
		local vault_file="${hash:32}.yaml"
		declare -g credentials_file="${vault_dir}/${vault_file}"
		export credentials_file
	fi
	[[ " ${MFLIBS_LOADED[*]} " =~ DEBUG ]] && mflibs::status::success "$(zen::i18n::translate "success.security.init_vault")"
}

# @function zen::vault::create
# @internal
# @description Creates the vault, including the generation and storage of the salt key.
# @global vault_name The name of the vault.
# @note The salt key is stored in a file and the vault is created in the /etc/.mediaease directory.
zen::vault::create() {
	local salt hash vault_dir vault_file
	declare salt_file="/root/.mediaease/config"
	declare vault_base_dir="/etc/.mediaease"
	mflibs::status::header "$(zen::i18n::translate "messages.security.create_vault")"
	if [[ -z "$user_salt" ]]; then
		read -r -sp "Enter your salt key: " user_salt
		printf "\n"
	fi

	# Encode user provided salt in base64 and store it
	salt=$(echo -n "$user_salt" | base64)
	echo "$salt" >"$salt_file"
	chmod 600 "$salt_file"
	chattr +i "$salt_file"
	mflibs::status::info "$(zen::i18n::translate "success.security.store_salt")"

	# Hashing to determine vault path
	hash=$(echo -n "${vault_name}${salt}" | sha256sum | cut -d' ' -f1)
	vault_dir="${vault_base_dir}/${hash:0:32}"
	vault_file="${hash:32}.yaml"

	# Create the vault directory and file
	mkdir -p "$vault_dir"
	chmod 700 "$vault_dir"
	declare -g credentials_file
	credentials_file="${vault_dir}/${vault_file}"
	touch "$credentials_file"
	zen::vault::permissions "add"
	export credentials_file

	mflibs::status::success "$(zen::i18n::translate "success.security.create_vault")"
}

# @function zen::vault::string::encode
# @description Encodes a given string using base64 encoding.
# @arg $1 string "The string to be encoded."
# @return "Encoded string in base64 format."
# @exitcode 0 "If the string is encoded successfully."
# @exitcode 1 "If no string is provided."
# @example
#    zen::vault::string::encode "value"
zen::vault::string::encode() {
	local string="${1}"
	if [[ -z "$string" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.security.no_string_to_encode")"
	fi
	local encoded_string
	encoded_string=$(echo -n "$string" | base64)
    encoded_string="${encoded_string%%=*}"
    echo -n "$encoded_string"
}

# @function zen::vault::key::decode
# @internal
# @description Finds and decodes the hashed value from the vault.
# @arg $1 string "The key for the value entry."
# @return "Decoded value if successful."
# @exitcode 1 "If the key is not found."
# @example
#    zen::vault::key::decode "username.type"
zen::vault::key::decode() {
	local key="$1"
	local name type
	local encoded_name encoded_type hashed_key hashed_value
	IFS='.' read -r name type <<<"$key"
	encoded_name=$(zen::vault::string::encode "$name")
	encoded_type=$(zen::vault::string::encode "$type")
	hashed_key="${encoded_name}.${encoded_type}"
	hashed_value=$(yq e ".$hashed_key" "$credentials_file")
	if [[ -n "$hashed_value" ]]; then
		local padded_value
		padded_value=$(echo "$hashed_value" | awk '{ while (length($0) % 4 != 0) $0 = $0 "="; print }')
		echo -n "$padded_value" | base64 --decode | head -n 1
	else
		mflibs::status::error "$(zen::i18n::translate "errors.security.key_not_decodable")"
	fi
}

# @function zen::vault::key::store
# @description Stores a new value in the vault.
# @arg $1 string "The key for the value entry."
# @arg $2 string "The value to store."
# @global credentials_file "Path to the credentials file."
# @exitcode 0 "If the value is stored successfully."
# @exitcode 1 "If the key already exists."
# @example
#    zen::vault::key::store "username.type" "value"
zen::vault::key::store() {
	local key="$1"
	local value="$2"
	local username type hashed_value hashed_username hashed_key
	username=$(echo "$key" | cut -d'.' -f1)
	type=$(echo "$key" | cut -d'.' -f2)
	hashed_type=$(zen::vault::string::encode "$type")
	hashed_username=$(zen::vault::string::encode "$username")
	hashed_key=".$hashed_username.$hashed_type"
	mflibs::status::info "$(zen::i18n::translate "messages.security.store_key" "$username" "$type")"
	if [[ $(yq e "$hashed_key" "$credentials_file") != "null" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.security.key_already_exists" "$key")"
	fi
	zen::vault::permissions "remove"
	hashed_value=$(zen::vault::string::encode "$value")
	yq e -i ".\"$hashed_username\".\"$hashed_type\" = \"$hashed_value\"" "$credentials_file"
	zen::vault::permissions "add"
	mflibs::status::success "$(zen::i18n::translate "success.security.store_key")"
}

# @function zen::vault::key::update
# @description Updates an existing value in the vault.
# @arg $1 string "The key for the value entry."
# @arg $2 string "The new value to update."
# @global credentials_file "Path to the credentials file."
# @exitcode 0 "If the value is updated successfully."
# @exitcode 1 "If the key is not found."
# @example
#    zen::vault::key::update "username.type" "value"
zen::vault::key::update() {
	local key="$1"
	local value="$2"
	local hashed_key hashed_value
	hashed_key=$(zen::vault::string::encode "$key")
	hashed_value=$(zen::vault::string::encode "$value")

	if yq e ".$hashed_key" "$credentials_file" &>/dev/null; then
		zen::vault::permissions "remove"
		yq e -i ".$hashed_key = \"$hashed_value\"" "$credentials_file"
		zen::vault::permissions "add"
	else
		mflibs::status::error "$(zen::i18n::translate "errors.security.key_missing")"
	fi
}

# @function zen::vault::key::reveal
# @description Reveals the value associated with a given key from the vault.
# @arg $1 string "The key whose value is to be revealed."
# $arg $2 string "The context of the key."
# @return "Reveals the associated value if successful."
# @example
#    zen::vault::key::reveal "username.type"
# @example
#    zen::vault::key::reveal "username.type" "context" # Optionally pass a context to reveal protected values.
zen::vault::key::reveal() {
	local key="$1"
	local context=${2:-main}
	if [[ "$key" == system.* && "$context" != "mediaease" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.security.key_not_revealable")"
	elif [[ "$key" != system.* && "$context" != "main" ]]; then
		mflibs::status::error "$(zen::i18n::translate "errors.security.invalid_context")"
	else
		declare -g VAULT_PASSWORD
		VAULT_PASSWORD=$(zen::vault::key::decode "$@")
		[[ "$context" == "main" ]] && printf "Password for %s is : %s\n" "$key" "$VAULT_PASSWORD"
		[[ "$context" == "mediaease" ]] && echo -n "$VAULT_PASSWORD"
		export VAULT_PASSWORD
	fi
}

# @function zen::vault::permissions
# @description Updates the permissions of the credentials file.
# @arg $1 string "The action to be performed on the file."
# @global credentials_file "Path to the credentials file."
# @exitcode 0 "If the permissions are updated successfully."
# @exitcode 1 "If an invalid action is provided."
# @example
#    zen::vault::permissions "add"
# @example
#    zen::vault::permissions "remove"
zen::vault::permissions() {
	local action="$1"

	if [[ "$action" == "add" ]]; then
		mflibs::log "chown -R root:root $credentials_file"
		mflibs::log "chmod -R 700 $credentials_file"
		mflibs::log "chattr +i $credentials_file"
	elif [[ "$action" == "remove" ]]; then
		mflibs::log "chattr -i $credentials_file"
		mflibs::log "chmod -R 755 $credentials_file"
		mflibs::log "chown -R root:root $credentials_file"
	else
		mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_action" "$action")"
	fi
}
