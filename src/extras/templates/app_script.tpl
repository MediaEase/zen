#!/usr/bin/env bash
# @file software/{{ SOFTWARE_NAME_LOWERED }}/{{ SOFTWARE_NAME_LOWERED }}.sh
# @version: 1.0.0
# @project MediaEase
# @description {{ SOFTWARE_NAME }} handler
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::software::{{ SOFTWARE_NAME_LOWERED }}::add
# @alias Install {{ SOFTWARE_NAME }}
# @description Adds {{ SOFTWARE_NAME }} for a user, including downloading, configuring, and starting the service.
# @global app_name The name of the application ({{ SOFTWARE_NAME }}).
# @global app_name_sanitized A sanitized version of the application name for display.
# @global software_config_file Path to the software's configuration file.
# @global user An associative array containing user-specific information.
# @note Disables SC2154 because the variable is defined in the main script.
# shellcheck disable=SC2154
# @example
#   zen software add {{ SOFTWARE_NAME_LOWERED }} -u <username>
zen::software::{{ SOFTWARE_NAME_LOWERED }}::add() {
}

################################################################################
# @function zen::software::{{ SOFTWARE_NAME_LOWERED }}::config
# @internal
# @description Configures {{ SOFTWARE_NAME }} for a user, including setting up configuration files and proxy settings.
# @arg $1 string Indicates whether to use a prerelease version of {{ SOFTWARE_NAME }}.
# @global user An associative array containing user-specific information.
# @example
#   zen::software::{{ SOFTWARE_NAME_LOWERED }}::config
zen::software::{{ SOFTWARE_NAME_LOWERED }}::config() {
}

# @function zen::software::{{ SOFTWARE_NAME_LOWERED }}::update
# @alias Update {{ SOFTWARE_NAME }}
# @description Updates {{ SOFTWARE_NAME }} for a user, including stopping the service, downloading the latest release, and restarting.
# @global user An associative array containing user-specific information.
# @global software_config_file Path to the software's configuration file.
# @example
#   zen software update {{ SOFTWARE_NAME_LOWERED }} -u <username>
zen::software::{{ SOFTWARE_NAME_LOWERED }}::update() {
}

# @function zen::software::{{ SOFTWARE_NAME_LOWERED }}::remove
# @alias Remove {{ SOFTWARE_NAME }}
# @description Removes {{ SOFTWARE_NAME }} for a user, including disabling and deleting the service and cleaning up files.
# @global user An associative array containing user-specific information.
# @example
#   zen software remove {{ SOFTWARE_NAME_LOWERED }} -u <username>
zen::software::{{ SOFTWARE_NAME_LOWERED }}::remove() {
}

# @function zen::software::{{ SOFTWARE_NAME_LOWERED }}::backup
# @alias Backup {{ SOFTWARE_NAME }}
# @description Creates a backup for {{ SOFTWARE_NAME }} settings for a user.
# @note This function is currently a placeholder and needs implementation.
# @example
#   zen software backup {{ SOFTWARE_NAME_LOWERED }} -u <username>
zen::software::{{ SOFTWARE_NAME_LOWERED }}::backup() {

}

# @function zen::software::{{ SOFTWARE_NAME_LOWERED }}::reset
# @description Resets {{ SOFTWARE_NAME }} settings for a user.
# @note This function is currently a placeholder and needs implementation.
# @example
#   zen software reset {{ SOFTWARE_NAME_LOWERED }} -u <username>
zen::software::{{ SOFTWARE_NAME_LOWERED }}::reset() {
	
}

# @function zen::software::{{ SOFTWARE_NAME_LOWERED }}::reinstall
# @description Reinstalls {{ SOFTWARE_NAME }} for a user.
# @note This function is currently a placeholder and needs implementation.
# @example
#   zen software reinstall {{ SOFTWARE_NAME_LOWERED }} -u <username>
zen::software::{{ SOFTWARE_NAME_LOWERED }}::reinstall() {
}
