#!/usr/bin/env bash

################################################################################
# @description: checks and updates the lock file
# @noargs
# shellcheck disable=SC2034 disable=SC2154
################################################################################
zen::lock::handle() {
	if [[ -f "${zen_base_path}/config/.lock" ]]; then
		declare counter
		zen_lock=$(cat "${zen_base_path}"/config/.lock)
		mflibs::shell::text::yellow "$(zen::lang::lock::handle)"
		mflibs::shell::misc::nl
		while [[ -f "${zen_base_path}/config/.lock" ]]; do
			if [[ $(pgrep -fc "/usr/local/bin/zen (install|remove|reinstall)") -gt "1" || $(pgrep -fc "/opt/zen/bin/zen (install|remove|reinstall)") -gt "1" ]]; then
				if [[ $(($(date +%s) - $(stat -c %Z /opt/zen/config/.lock))) -gt 30 ]]; then
					counter=$((counter + 1))
					if [[ ${counter} -eq 10 ]]; then
						zen::apt::update
						zen::lock::cleanup
						break
					fi
				else
					break
				fi
				sleep 4
			else
				break
			fi
		done
	fi
	zen::lock::update::timeout "$@"
}

zen::lock::update::timeout() {
	echo "${software_title:-null}" >"${zen_base_path}/config/.lock"
	if [[ -n $1 ]]; then
		echo "XXX
$1
XXX
$2" >"${zen_base_path}/config/.dialog_lock"
	fi
}

################################################################################
# @description: remove lock file
# @noargs
################################################################################
zen::lock::cleanup() {
	rm -f "${zen_base_path}/config/.lock"
}
