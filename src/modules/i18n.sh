#!/usr/bin/env bash
# @file modules/i18n.sh
# @project MediaEase
# @version 1.0.0
# @description Contains a library of internationalization functions used in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::i18n::load_locale_file
# @description Loads the appropriate locale file based on the specified language code.
# @arg $1 string Language code (e.g., 'en' for English, 'fr' for French).
# @global MEDIAEASE_HOME Base directory of MediaEase application.
# @stdout Sets system locale settings and environment variables for language and locale file path.
# @return 1 if language not supported or locale file not found.
# @note Validates language code, sets up environment for internationalization.
#      Dynamically generates locale file path based on language code.
# @example
#      zen::i18n::load_locale_file "fr"
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
    local locale_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/translations/locales_${lang}.yaml"
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

# @function zen::i18n::translate
# @description Translates a specified key into the selected language using the loaded locale file.
# @arg $1 string Translation key to look up in the locale file.
# @arg $@ array Additional arguments for placeholder substitution.
# @global MEDIAEASE_LOCALE_FILE Path to the currently loaded locale file.
# @stdout Translated string or original key if no translation found.
# @return None.
# @note Uses 'yq' to parse YAML locale file, handles missing translations,
#       replaces placeholders in translation strings with arguments.
# @example
#      zen::i18n::translate "common.greeting" "Thomas"
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

