#!/usr/bin/env bash
################################################################################
# @file_name: i18n
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
# @function_name: zen::i18n::load_locale_file
# @description: Loads the appropriate locale file based on the specified language.
#               Sets system locale settings and loads corresponding YAML file for translations.
# @param: lang - The language code (e.g., 'en' for English, 'fr' for French).
# @globals: MEDIAEASE_HOME - Set to the base directory of the MediaEase application.
# @output: Writes error/warning messages to stderr.
#          Sets system locale settings and environment variables for language and locale file path.
# @return_code: 1 if the specified language is not supported or locale file is not found.
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
# @function_name: zen::i18n::translate
# @description: Translates a given key into the selected language using the loaded locale file.
#               Dynamically replaces placeholders in the translation string with provided arguments.
# @param: key - The translation key to look up in the locale file.
# @param: args - Additional arguments that are substituted into the translation string.
# @globals: None
# @output: The translated string or the original key if no translation is found.
# @return_code: None
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

