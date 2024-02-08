#!/usr/bin/env bash

################################################################################
# @description: output functions for zen
# @noargs
################################################################################
zen::output::install::sources::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::install::sources::header)"
	zen::update::lock::timeout "$(zen::lang::install::sources::header)" "16"
}

zen::output::install::dependencies::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::install::dependencies::header)"
	zen::update::lock::timeout "$(zen::lang::install::dependencies::header)" "32"
}

zen::output::install::build::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::install::build::header)"
	zen::update::lock::timeout "$(zen::lang::install::build::header)" "48"
}

zen::output::install::xmlrpc::build::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::install::xmlrpc::header)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::install::xmlrpc::header)" "50"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::mktorrent::build::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::install::mktorrent::header)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::install::mktorrent::header)" "54"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::libtorrent::build::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::install::libtorrent::header)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::install::libtorrent::header)" "58"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::rtorrent::build::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::install::rtorrent::header)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::install::rtorrent::header)" "60"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::configure::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::install::configure::header)"
	zen::update::lock::timeout "$(zen::lang::install::configure::header)" "64"
}

zen::output::install::start::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::install::start::header)"
	zen::update::lock::timeout "$(zen::lang::install::start::header)" "80"
}

zen::output::install::backup::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::install::backup::header)"
	zen::update::lock::timeout "$(zen::lang::install::backup::header)" "96"
}

zen::output::database() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::database)"
	zen::update::lock::timeout
}

zen::output::remove::stop::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::remove::stop::header)"
	zen::update::lock::timeout "$(zen::lang::remove::stop::header)" "20"
}

zen::output::remove::dependencies::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::remove::dependencies::header)"
	zen::update::lock::timeout "$(zen::lang::remove::dependencies::header)" "40"
}

zen::output::remove::files::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::remove::files::header)"
	zen::update::lock::timeout "$(zen::lang::remove::files::header)" "60"
}

zen::output::remove::complete::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::green "$(zen::lang::remove::complete::header)"
	zen::update::lock::timeout "$(zen::lang::remove::complete::header)" "100"
	rm -f "${zen_base_path}/config/.dialog_lock"
}

zen::output::update::files::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::white "$(zen::lang::update::files::header)"
	zen::update::lock::timeout
}

zen::output::reinstall::complete::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::green "$(zen::lang::reinstall::complete::header)"
	zen::update::lock::timeout "$(zen::lang::reinstall::complete::header)" "100"
	rm -f "${zen_base_path}/config/.dialog_lock"
}

zen::output::update::complete::header() {
	[[ -z ${dialog_menu} ]] && mflibs::shell::text::green "$(zen::lang::update::complete::header)"
	zen::update::lock::timeout "$(zen::lang::update::complete::header)" "100"
	rm -f "${zen_base_path}/config/.dialog_lock"
}

zen::output::install::mu::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::mu::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::mu::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::admin::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::admin::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::admin::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::airsonic::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::airsonic::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::airsonic::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::calibre::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::calibre::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::calibre::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::flaresolverr::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::flaresolverr::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::flaresolverr::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::jellyfin::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::jellyfin::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::jellyfin::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::notifiarr::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::notifiarr::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::notifiarr::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::novnc::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::novnc::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::novnc::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::overseerr::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::overseerr::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::overseerr::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::plex::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::plex::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::plex::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::pyload::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::pyload::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::pyload::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::quassel::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::quassel::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::quassel::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::rtorrent::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::rtorrent::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::rtorrent::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::rutorrent::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::rutorrent::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::rutorrent::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::install::vpnzip::access::header() {
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::software::vpnzip::access)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::software::vpnzip::access)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

################################################################################
# output functions for zen updater. extends the functions above
################################################################################

zen::output::update::ntp() {
	#checking with ntp server...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::ntp)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::ntp)" "4"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::apt() {
	#running apt updates...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::apt)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::apt)" "8"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::initial::dependencies() {
	#checking for initial dependencies...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::initial::dependencies)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::initial::dependencies)" "12"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::download::v3() {
	#downloading zen pro...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::download::v3)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::download::v3)" "16"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::zen::dependencies() {
	#checking for zen dependencies...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::zen::dependencies)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::zen::dependencies)" "20"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::base::dependencies() {
	#installing base dependencies:
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white::sl "$(zen::lang::update::base::dependencies)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::base::dependencies)" "24"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::web::dependencies() {
	#installing web dependencies:
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white::sl "$(zen::lang::update::web::dependencies)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::web::dependencies)" "28"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::python::dependencies() {
	#installing python dependencies:
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white::sl "$(zen::lang::update::python::dependencies)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::python::dependencies)" "32"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::dependencies::log() {
	#saving installed dependencies...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::dependencies::log)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::dependencies::log)" "36"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::pip() {
	#updating pip...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::pip)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::pip)" "40"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::lshell() {
	#updating lshell...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::lshell)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::lshell)" "44"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::iris() {
	#updating iris...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::iris)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::iris)" "48"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::libraries() {
	#updating zen libraries...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::libraries)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::libraries)" "52"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::cron() {
	#updating cron jobs...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::cron)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::cron)" "56"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::sudo() {
	#updating sudo configurations...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::sudo)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::sudo)" "60"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::curl() {
	#updating curl...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::curl)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::curl)" "64"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::php::check() {
	#checking php...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::php::check)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::php::check)" "68"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::zencommands() {
	#configuring zen pro commands...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::zencommands)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::zencommands)" "72"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::dashboard() {
	#updating zen dashboard...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::dashboard)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::dashboard)" "76"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::database() {
	#updating zen database...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::database)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::database)" "80"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::autocomplete() {
	#updating zen autocomplete...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::autocomplete)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::autocomplete)" "84"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::permissions() {
	#configuring permissions...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::permissions)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::permissions)" "90"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::clean() {
	#cleaning update files...
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::white "$(zen::lang::update::clean)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::clean)" "95"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}

zen::output::update::complete() {
	#zen updated!
	if [[ -z ${dialog_menu} ]]; then
		mflibs::shell::text::green "$(zen::lang::update::complete)"
	else
		declare -xgi dialog_access=1
		zen::update::lock::timeout "$(zen::lang::update::complete)" "100"
		rm -f "${zen_base_path}/config/.dialog_lock"
	fi
}
