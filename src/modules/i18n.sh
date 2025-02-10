#!/usr/bin/env bash
# @file modules/i18n.sh
# @project MediaEase
# @version 1.0.35
# @description Contains a library of internationalization functions used in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @function zen::i18n::load_locale_file
# @description Loads the appropriate locale file based on the specified language code.
# @arg $1 string Language code (e.g., 'en' for English, 'fr' for French).
# @global MEDIAEASE_HOME Base directory of MediaEase application.
# @stdout Sets system locale settings and environment variables for language and locale file path.
# @return 1 if language not supported or locale file not found.
# @note Validates language code, sets up environment for internationalization. Dynamically generates locale file path based on language code.
# @example
#      zen::i18n::load_locale_file "fr"
zen::i18n::load_locale_file() {
	local lang="$1"
	MEDIAEASE_HOME="$(grep MEDIAEASE_HOME /etc/environment | cut -d'=' -f2 | sed 's/"//g')"
	local locale_file="${MEDIAEASE_HOME}/zen/src/translations/locales_${lang}.yaml"
	if [[ -f "$locale_file" ]]; then
		local locale_setting
		export MEDIAEASE_LOCALE_FILE="$locale_file"
		zen::i18n::generate::system_locale "$lang"
		zen::i18n::set::timezone "$lang"
		[[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && mflibs::status::success "$(zen::i18n::translate "messages.common.language_loaded" "${lang}")"
	else
		mflibs::status::error "Locale file not found: $locale_file"
	fi
}

# @function zen::i18n::generate::system_locale
# @description Generates system locale settings based on the specified language code.
# @arg $1 string Language code (e.g., 'en' for English, 'fr' for French).
# @global locale_setting
# @stdout Sets system locale settings based on language code.
# @return 1 if language code not supported.
# @note Validates language code, sets system locale settings based on language code.
# @example
#      zen::i18n::generate::system_locale "fr"
zen::i18n::generate::system_locale() {
	local lang="$1"
	declare -A system_lang=(
		["en"]="en_US.UTF-8"
		["fr"]="fr_FR.UTF-8"
	)
	if [[ -z "${system_lang[$lang]}" ]]; then
		mflibs::status::warn "${lang} is not a valid language, loading default language (en)"
	fi
	declare -g locale_setting
	locale_setting="${system_lang[$lang]}"

	# Check if the intended locale is already in use
	local current_locale
	current_locale=$(locale | grep 'LANG=' | cut -d= -f2)
	[[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo "Current locale: $current_locale"
	[[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo "Desired locale: $locale_setting"
	if [[ "$current_locale" != "$locale_setting" ]]; then
		[[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo "Updating locale settings..."
		echo "LANG=\"$locale_setting\"" >/etc/default/locale
		echo "LC_ALL=\"$locale_setting\"" >>/etc/default/locale
		echo "LANGUAGE=\"$locale_setting\"" >>/etc/default/locale
		locale_base=$(echo "$locale_setting" | cut -d. -f1)
		locale_encoding=$(echo "$locale_setting" | cut -d. -f2)
		tmpfile=$(mktemp)
		while IFS= read -r line; do
			if [[ "$line" =~ ^#\ *en_[A-Z]{2}.UTF-8\ UTF-8 ]]; then
				echo "${BASH_REMATCH[0]:2}" >>"$tmpfile"
			elif [[ "$line" =~ ^en_[A-Z]{2}.UTF-8\ UTF-8 ]]; then
				if [[ "$locale_base" != "${BASH_REMATCH[0]:0:5}" ]]; then
					echo "# ${BASH_REMATCH[0]}" >>"$tmpfile"
				else
					echo "$line" >>"$tmpfile"
				fi
			elif [[ "$line" =~ ^#\ *$locale_base\ $locale_encoding ]]; then
				echo "$locale_base $locale_encoding" >>"$tmpfile"
			else
				echo "$line" >>"$tmpfile"
			fi
		done </etc/locale.gen
		if ! grep -q "^$locale_base $locale_encoding" "$tmpfile"; then
			echo "$locale_base $locale_encoding" >>"$tmpfile"
		fi
		mv "$tmpfile" /etc/locale.gen
		export LANG="$locale_setting"
		export LC_ALL="$locale_setting"
		export LANGUAGE="$locale_setting"
		mflibs::log "locale-gen $locale_setting >/dev/null 2>&1"
		mflibs::log "update-locale LANG=\"$locale_setting\" LC_ALL=\"$locale_setting\" LANGUAGE=\"$locale_setting\" >/dev/null 2>&1"
	fi
}

# @function zen::i18n::set::timezone
# @description Sets the system timezone based on the specified language code.
# @arg $1 string Language code (e.g., 'en' for English, 'fr' for French).
# @global TIMEZONE
# @stdout Sets system timezone based on language code.
# @return None.
# @note Validates language code, sets system timezone based on language code.
# @example
#      zen::i18n::set::timezone "fr"
zen::i18n::set::timezone() {
	local lang="$1"
	if command -v tzdata >/dev/null; then
		default_timezone="UTC"
		declare -A lang_to_timezone=(
			["en"]="America/New_York"
			["fr"]="Europe/Paris"
		)
		local intended_timezone="${lang_to_timezone[$lang]:-$default_timezone}"

		# Read the current timezone setting
		local current_timezone
		if [[ -f "/etc/timezone" ]]; then
			current_timezone=$(cat /etc/timezone)
		else
			current_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
		fi

		# Update the timezone only if it's different from the intended timezone
		if [[ "$current_timezone" != "$intended_timezone" ]]; then
			IFS='/' read -r AREA LOCATION <<<"$intended_timezone"
			rm -f /etc/localtime
			ln -s "/usr/share/zoneinfo/$intended_timezone" /etc/localtime
			echo "tzdata tzdata/Areas select $AREA" | debconf-set-selections
			echo "tzdata tzdata/Zones/$AREA select $LOCATION" | debconf-set-selections
			dpkg-reconfigure -f noninteractive tzdata
		fi
	fi
}

# @function zen::i18n::translate
# @description Translates a specified key into the selected language using the loaded locale file.
# @arg $1 string Translation key to look up in the locale file.
# @arg $@ array Additional arguments for placeholder substitution.
# @global MEDIAEASE_LOCALE_FILE Path to the currently loaded locale file.
# @stdout Translated string or original key if no translation found.
# @return None.
# @note Uses 'yq' to parse YAML locale file, handles missing translations, replaces placeholders in translation strings with arguments.
# @example
#      zen::i18n::translate "common.greeting" "Thomas"
zen::i18n::translate() {
	local key="$1"
	shift
	local args=("$@")
	local locale_file_path="$MEDIAEASE_LOCALE_FILE"
	local translation
	translation=$(yq e ".${key}" "$locale_file_path" 2>/dev/null)
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
		if [[ ! "$translation" =~ ^\{arg0\} ]] && [[ ! "$key" == *".dependency."* ]]; then
			translation="$(tr '[:lower:]' '[:upper:]' <<<"${translation:0:1}")${translation:1}"
		fi
	fi
	printf '%s' "$translation"
}
