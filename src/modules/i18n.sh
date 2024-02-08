#!/usr/bin/env bash
################################################################################
# @file_name: i18n.sh
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
# zen::i18n::load_locale_file
#
# Loads the appropriate locale file based on the specified language code. It sets
# the system locale settings for the application and loads the corresponding YAML
# file containing translations.
#
# Arguments:
#   lang - A language code (e.g., 'en' for English, 'fr' for French).
# Globals:
#   MEDIAEASE_HOME - Base directory of the MediaEase application.
# Outputs:
#   Sets system locale settings and environment variables for language and locale
#   file path. Writes error/warning messages to stderr.
# Returns:
#   1 if the specified language is not supported or if the locale file is not found.
# Notes:
#   The function validates the language code and sets up the environment for
#   internationalization support. It also dynamically generates the locale file
#   path based on the provided language code.
################################################################################
zen::i18n::load_locale_file() {
    local lang="$1"
    local locale_setting
    declare -A system_lang=(
        ["en"]="en_US.utf8"
        ["fr"]="fr_FR.utf8"
    )
    if [[ -z "${system_lang[$lang]}" ]]; then
        mflibs::status::warn "${lang} is not a valid language file, loading default language (en)"
        exit 1
    fi

    locale_setting="${system_lang[$lang]}"
    if ! locale -a | grep -q "${locale_setting%.*}"; then
        echo "LANGUAGE=\"$locale_setting\"" >/etc/default/locale
        echo "LC_ALL=\"$locale_setting\"" >>/etc/default/locale
        echo "$locale_setting UTF-8" >/etc/locale.gen
        mflibs::log "locale-gen $locale_setting"
    fi

    if [[ -z "$MEDIAEASE_HOME" ]]; then
        MEDIAEASE_HOME="$(dirname "$(readlink -f "$0")")"
    fi
    MEDIAEASE_HOME="${MEDIAEASE_HOME%/}"
    local locale_file="${MEDIAEASE_HOME}/translations/locales_${lang}.yaml"
    if [[ -f "$locale_file" ]]; then
        export LANG="$locale_setting"
        export LC_ALL="$locale_setting"
        export LANGUAGE="$locale_setting"
        export MEDIAEASE_LOCALE_FILE="$locale_file"
        mflibs::status::success "$(zen::i18n::translate "common.lang_loaded" "${lang}")"
    else
        mflibs::status::error "Locale file not found: $locale_file"
    fi
}

################################################################################
# zen::i18n::translate
#
# Translates a specified key into the selected language using the loaded locale
# file. It dynamically replaces placeholders in the translation string with
# provided arguments, enabling flexible and context-aware translations.
#
# Arguments:
#   key - The translation key to look up in the locale file.
#   args - Additional arguments to be substituted into the translation string.
# Globals:
#   MEDIAEASE_LOCALE_FILE - The path to the currently loaded locale file.
# Outputs:
#   The translated string. If no translation is found, outputs the original key.
# Returns:
#   None.
# Notes:
#   The function uses 'yq' to parse the YAML locale file. It handles the case
#   where no translation is found by returning the original key. Placeholders
#   in the form of '{arg0}', '{arg1}', etc., in the translation strings are
#   replaced by the respective arguments passed to the function.
################################################################################
zen::i18n::translate() {
    local key="$1"
    shift
    local args=("$@")
    local locale_file_path="$MEDIAEASE_LOCALE_FILE"
    local translation
    translation=$(yq e ".${key}" "$locale_file_path" 2>/dev/null)
    local i=0
    if [[ -z "$translation" || "$translation" == "null" ]]; then
        translation="$key"
    else
        local i=0
        for arg in "${args[@]}"; do
            local placeholder="{arg${i}}"
            translation="${translation//$placeholder/$arg}"
            ((i++))
        done
        translation="${translation%\"}"
        translation="${translation#\"}"
        translation="$(tr '[:lower:]' '[:upper:]' <<< "${translation:0:1}")${translation:1}"
    fi

    printf '%s' "$translation"
}

