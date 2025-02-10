#!/usr/bin/env bash
# @file extras/scripts/raid.sh
# @project MediaEase
# @version 1.3.10
# @brief Automatically creates a RAID array and mounts it to the specified mount point.
# @description This script facilitates the creation and mounting of a RAID array.
# It includes functions to process command-line arguments, detect system disks, format and create the RAID array, and mount it.
# The script checks for minimum disk requirements, validates RAID levels and filesystem types, and provides feedback to the user.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @section RAID Processing Functions
# @description Functions related to processing RAID array creation.

# @function raid::process::args
# @description This function handles the parsing and validation of command-line arguments passed to the script.
# It sets global variables for RAID level, mount point, filesystem type, and disk name.
# The function also checks for valid RAID levels and filesystem types, and ensures there are enough disks for the chosen RAID level.
# If the arguments are incorrect or insufficient, it provides feedback and exits.
# @arg $1 string The desired RAID level (0, 5, 6, 10).
# @arg $2 string Optional. The mount point for the RAID array. Default: /home.
# @arg $3 string Optional. The filesystem type for the RAID array. Default: ext4.
# @arg $4 string Optional. The name of the RAID array. Default: md0.
# @exitcode 0 Success.
# @exitcode 1 Error due to incorrect number of arguments, invalid RAID level, invalid filesystem type, insufficient number of disks, or user cancellation.
raid::process::args() {
	# Check if the number of arguments is not equal to 4
	if [ "$#" -ne 4 ]; then
		echo "Usage: $0 [RAID_LEVEL] [MOUNT_POINT] [FILESYSTEM_TYPE] [DISK_NAME]"
	fi
	# Declare global variables and set their default values if not provided
	declare -g raid_level=$1
	declare -g mount_point=${2:-/home}
	declare -g filesystem_type=${3:-ext4}
	declare -g disk_name=${4:-md10}
	# Define valid RAID levels and filesystem types
	local raid_levels=("0" "5" "6" "10")
	local types=("ext4" "btrfs" "xfs")
	# Check if the RAID level is valid and set the minimum disks required for the RAID
	case $raid_level in
	0) min_disks=2 ;;
	5) min_disks=3 ;;
	6) min_disks=4 ;;
	10) min_disks=4 ;;
	*)
		mflibs::status::error "$(zen::i18n::translate "errors.filesystem.raid_level_invalid" "${raid_levels[@]}")"
		;;
	esac
	# Check if the filesystem type is valid
	case $filesystem_type in
	ext4 | btrfs | xfs) ;;
	*)
		mflibs::status::error "$(zen::i18n::translate "errors.filesystem.filesystem_type_invalid" "${types[@]}")"
		;;
	esac
	# Call the disk detection function to initialize related variables
	mflibs::status::header "$(zen::i18n::translate "header.filesystem.init_raid_creation")"
	raid::disk::detection
	# Check if the number of disks is less than the minimum required for the chosen RAID level
	if [ "$NUMBER_DISKS" -lt "$min_disks" ]; then
		mflibs::shell::text::red "$(zen::i18n::translate "errors.filesystem.insufficient_disks_for_raid" "$raid_level" "$NUMBER_DISKS" "$min_disks")" >&2
		# Calculate possible RAID levels based on the number of disks available
		local possible_raids=()
		if [ "$NUMBER_DISKS" -ge 4 ] && ((NUMBER_DISKS % 2 == 0)); then
			possible_raids+=("10")
		fi
		if [ "$NUMBER_DISKS" -ge 4 ]; then
			possible_raids+=("6")
		fi
		if [ "$NUMBER_DISKS" -ge 3 ]; then
			possible_raids+=("5")
		fi
		if [ "$NUMBER_DISKS" -ge 2 ]; then
			possible_raids+=("0")
		fi
		# Suggest alternative RAID levels to the user based on available disks
		if [ ${#possible_raids[@]} -gt 0 ]; then
			local prompt_message
			prompt_message=$(mflibs::shell::text::yellow::sl "➜ $(zen::i18n::translate "prompts.filesystem.select_raid_level" "${possible_raids[*]}")")
			zen::prompt::raid "$prompt_message" raid_level "${possible_raids[@]}"
			mflibs::status::info "$(zen::i18n::translate "messages.filesystem.select_raid_level" "$raid_level")"
		else
			mflibs::status::error "$(zen::i18n::translate "errors.filesystem.raid_not_possible" "$NUMBER_DISKS")"
		fi
	fi
	# If valid selections are made, proceed with RAID setup
	raid::format::disk
	raid::create::mdadm::disk
	raid::mount::mdadm::disk
}

# @function raid::disk::detection
# Detects and lists disks for RAID array creation.
# @description This function identifies the root device and then enumerates all other storage devices that are not part of any existing RAID array.
# This detection is crucial to determine which disks are available for formatting and inclusion in the new RAID array.
# The function sets global variables for the disks to be formatted and their count.
# @stdout Informs about the system disk, disks to be formatted, and their count.
raid::disk::detection() {
	ROOT_DEVICE=$(findmnt -n -o SOURCE --target / | cut -d'[' -f1)
	SYSTEM_DISK=$(lsblk -no PKNAME "$ROOT_DEVICE")
	# if system_disk is md* then we need to get the /dev/sd* disks or /dev/nvme* disks
	SYSTEM_DISKS=()
	if [[ $SYSTEM_DISK == md* ]]; then
		while read -r line; do
			SYSTEM_DISKS+=("${line//[0-9]/}")
		done < <(mdadm --detail "/dev/$SYSTEM_DISK" | grep 'active sync' | awk '{print $7}')
	else
		SYSTEM_DISKS+=("$SYSTEM_DISK")
	fi

	mflibs::status::info "$(zen::i18n::translate "messages.filesystem.system_on_disk" "${SYSTEM_DISKS[*]}")"
	mflibs::status::info "$(zen::i18n::translate "prompts.filesystem.select_raid_level" "$raid_level")"

	DISKS_TO_FORMAT=()
	for disk in $(lsblk -nd -o NAME,TYPE | awk '{print $1}'); do
		disk_type=$(lsblk -no TYPE "/dev/$disk")
		if [[ "$disk_type" == "disk" ]]; then
			if [[ ! " ${SYSTEM_DISKS[*]} " =~ ${disk} ]]; then
				DISKS_TO_FORMAT+=("/dev/$disk")
			fi
		fi
	done
	DISK_ARRAY=("${DISKS_TO_FORMAT[@]}")
	NUMBER_DISKS=${#DISKS_TO_FORMAT[@]}
	mflibs::status::info "$(zen::i18n::translate "messages.filesystem.disks_to_format" "${DISKS_TO_FORMAT[*]}" "$disk_name" "$filesystem_type")"
	mflibs::shell::icon::warning::yellow
	mflibs::shell::text::yellow "$(zen::i18n::translate "messages.filesystem.number_of_disks" "$NUMBER_DISKS")"
	mflibs::shell::icon::warning::yellow
	mflibs::shell::text::yellow "$(zen::i18n::translate "messages.filesystem.future_disk" "$disk_name")"
}

# @function raid::format::disk
# Formats disks for RAID array creation.
# @description This function prompts the user to confirm disk formatting and proceeds to wipe and partition each disk in preparation for RAID array creation.
# It ensures that each disk is properly prepared and partitioned with the specified filesystem type.
# @stdout Guides the user through disk formatting process and reports on the status of each disk.
raid::format::disk() {
	local prompt_message
	prompt_message=$(
		mflibs::shell::icon::arrow::yellow
		mflibs::shell::text::yellow "$(zen::i18n::translate "prompts.common.continue_label") ?"
	)
	zen::prompt::yn "$prompt_message" N || mflibs::status::warn "$(zen::i18n::translate "errors.filesystem.raid_aborted")"

	mflibs::status::header "$(zen::i18n::translate "headers.filesystem.partition_empty_disks")"
	for disk in "${DISKS_TO_FORMAT[@]}"; do
		mflibs::log "wipefs -a $disk" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_formatting" "$disk")"
		mflibs::log "parted -s $disk mklabel msdos mkpart primary $filesystem_type 1 100%" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.create_partitions" "$disk")"
		sleep 3
	done
	mflibs::status::success "$(zen::i18n::translate "success.filesystem.partitions_create")"
	sleep 5
}

# @function raid::create::mdadm::disk
# Creates a RAID array using mdadm.
# @description This function creates a RAID array with the specified RAID level using the mdadm utility.
# It handles different RAID levels and configures the RAID array accordingly.
# The RAID array is created using the disks that were formatted in the previous step.
# @stdout Details the RAID creation process and reports any errors encountered.
raid::create::mdadm::disk() {
	mflibs::status::header "$(zen::i18n::translate "headers.filesystem.create_disk" "$raid_level" "$disk_name")"
	local command
	command=$(echo y | mdadm --create --verbose "/dev/$disk_name" --level="$raid_level" --raid-devices="$NUMBER_DISKS" "${DISK_ARRAY[@]}")
	mflibs::log "$command" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_creation")"
	sleep 5
	mflibs::status::info "$(zen::i18n::translate "headers.filesystem.format_disk" "$disk_name" "$filesystem_type")"
	if [[ "$filesystem_type" == "btrfs" ]]; then
		mflibs::log "mkfs.btrfs -L mediaease -f /dev/$disk_name" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_partition")"
		if [ ! -d "/mnt" ]; then
			mflibs::log "mkdir -p /mnt" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.create_mount_point")"
		fi
		mflibs::log "mount /dev/$disk_name /mnt" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_mount" "$disk_name" "/mnt")"
		declare -g subvolume
		if [[ $mount_point == "/home" ]]; then
			subvolume="home"
		elif [[ $mount_point == "/" ]]; then
			subvolume="root"
		else
			subvolume="data"
		fi
		mflibs::log "btrfs subvolume create /mnt/$subvolume" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.create_subvolume")"
		mflibs::log "btrfs subvolume create /mnt/home" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.create_subvolume")"
		mflibs::log "umount /mnt" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_unmount")"
	elif [[ "$filesystem_type" == "xfs" ]]; then
		mflibs::log "mkfs.xfs -L mediaease -f /dev/$disk_name" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_partition")"
	else
		mflibs::log "mkfs.ext4 -L mediaease -F /dev/$disk_name" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_partition")"
	fi
	mflibs::status::success "$(zen::i18n::translate "success.filesystem.disk_partition" "$disk_name" "$filesystem_type")"
	mflibs::status::info "$(zen::i18n::translate "headers.filesystem.disk_ready" "$disk_name")"
	sleep 5
}

# @function raid::mount::mdadm::disk
# Mounts the RAID array to a specified mount point.
# @description After creating the RAID array, this function mounts it to the provided mount point.
# It also updates the /etc/fstab file to ensure the RAID array is mounted automatically on boot.
# @stdout Indicates the mounting process of the RAID array and updates the /etc/fstab file.
raid::mount::mdadm::disk() {
	local RAID_UUID
	RAID_UUID=$(blkid -o value -s UUID "/dev/$disk_name")
	if mdadm --detail --scan | grep -q "/dev/$disk_name"; then
		mflibs::status::header "$(zen::i18n::translate "headers.filesystem.mount" "$disk_name" "$mount_point")"
		local mount_options="defaults"
		case "$filesystem_type" in
		btrfs)
			mount_options="$mount_options,nofail,x-systemd.growfs,noatime,lazytime,compress-force=zstd,space_cache=v2,autodefrag,nodiscard,subvol=$subvolume"
			;;
		xfs)
			mount_options="$mount_options,nofail,noatime,nodiratime,discard,allocsize=4M"
			;;
		ext4)
			mount_options="$mount_options,nofail,noatime,nodiratime,discard,data=writeback,barrier=0"
			;;
		esac
		local pass=0
		[[ $mount_point == "/home" ]] && pass=2
		local fstab_entry="UUID=$RAID_UUID $mount_point $filesystem_type $mount_options 0 $pass"
		if grep -Fxq "$fstab_entry" /etc/fstab; then
			mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_already_mounted" "$disk_name" "$mount_point")"
		else
			{
				echo "# MediaEase RAID"
				echo "$fstab_entry"
				echo "# MediaEase RAID"
			} >>/etc/fstab
			[ ! -d "$mount_point" ] && mkdir -p "$mount_point"
			systemctl daemon-reload
			mflibs::log "mount -a" || mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_mount" "$disk_name" "$mount_point")"
			mflibs::status::success "$(zen::i18n::translate "success.filesystem.disk_mount" "$disk_name" "$mount_point")"
		fi
	else
		mflibs::status::error "$(zen::i18n::translate "errors.filesystem.disk_created_but_not_mounted" "$disk_name")"
	fi
}

raid::process::args "$@"
