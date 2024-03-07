#!/usr/bin/env bash
# @file extras/scripts/raid.sh
# @project MediaEase
# @version 1.0.0
# @brief Automatically creates a RAID array and mounts it to the specified mount point.
# @description This script facilitates the creation and mounting of a RAID array.
# It includes functions to process command-line arguments, detect system disks, format and create the RAID array, and mount it.
# The script checks for minimum disk requirements, validates RAID levels and filesystem types, and provides feedback to the user.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

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
        exit 1
    fi
    # Declare global variables and set their default values if not provided
    declare -g raid_level=$1
    declare -g mount_point=${2:-/home}
    declare -g filesystem_type=${3:-ext4}
    declare -g disk_name=${4:-md0}
    # Define required packages for RAID array creation
    declare -g raid_packages=("mdadm" "parted" "util-linux")
    # Define valid RAID levels and filesystem types
    local raid_levels=("0" "5" "6" "10")
    local types=("ext4" "btrfs")
    # Check if the RAID level is valid and set the minimum disks required for the RAID
    case $raid_level in
        0) min_disks=2 ;;
        5) min_disks=3 ;;
        6) min_disks=4 ;;
        10) min_disks=4 ;;
        *) mflibs::status::error "$(zen::i18n::translate "raid.invalid_raid_level" "${raid_levels[@]}")"; exit 1 ;;
    esac
    # Check if the filesystem type is valid
    case $filesystem_type in
        ext4|btrfs) ;;
        *) mflibs::status::error "$(zen::i18n::translate "raid.invalid_filesystem_type" "${types[@]}")"; exit 1 ;;
    esac
    # Call the disk detection function to initialize related variables
    raid::disk::detection
    # Check if the number of disks is less than the minimum required for the chosen RAID level
    if [ "$NUMBER_DISKS" -lt "$min_disks" ]; then
        mflibs::status::error "$(zen::i18n::translate "raid.not_enough_disks" "$raid_level" "$min_disks")" >&2
        # Calculate possible RAID levels based on the number of disks available
        local possible_raids=()
        if [ "$NUMBER_DISKS" -ge 4 ] && (( NUMBER_DISKS % 2 == 0 )); then
            possible_raids+=("10")
        fi
        if [ "$NUMBER_DISKS" -ge 4 ]; then
            possible_raids+=("6")
        fi
        if (( NUMBER_DISKS % 3 == 0 )) && [ "$NUMBER_DISKS" -ge 3 ]; then
            possible_raids+=("5")
        fi
        if [ "$NUMBER_DISKS" -ge 2 ]; then
            possible_raids+=("0")
        fi
        # Suggest alternative RAID levels to the user based on available disks
        if [ ${#possible_raids[@]} -gt 0 ]; then
            mflibs::shell::text::yellow "$(zen::i18n::translate "raid.raid_possible" "${possible_raids[*]}")"
            echo "Proceed with RAID${possible_raids[0]} (Y), abort (N), or choose (C)?"
            read -r user_confirmation
            case $user_confirmation in
                [Yy])
                    raid_level=${possible_raids[0]}
                    ;;
                [Cc])
                    mflibs::shell::text::yellow "$(zen::i18n::translate "raid.choose_raid_level" "${possible_raids[*]}")"
                    read -r chosen_raid
                    if [[ " ${possible_raids[*]} " =~ ${chosen_raid} ]]; then
                        raid_level=$chosen_raid
                    else
                        mflibs::status::warn "Invalid selection."; exit 1
                    fi
                    ;;
                *)
                    mflibs::status::warn "$(zen::i18n::translate "raid.creation_aborted")"; exit 1
                    ;;
            esac
        else
            mflibs::status::error "$(zen::i18n::translate "raid.no_raid_possible" "$NUMBER_DISKS")"; exit 1
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
    zen::dependency::apt::install::inline "${raid_packages[*]}"
    ROOT_DEVICE=$(findmnt -n -o SOURCE --target / | cut -d'[' -f1)
    SYSTEM_DISK=$(lsblk -no PKNAME "$ROOT_DEVICE")

    mflibs::status::info "$(zen::i18n::translate "raid.system_disk" "$SYSTEM_DISK")"
    mflibs::status::info "$(zen::i18n::translate "raid.selected_raid_level" "$raid_level")"
    DISKS_TO_FORMAT=()
    for disk in $(lsblk -nd -o NAME,TYPE | awk -v sysdisk="$SYSTEM_DISK" '$2 == "disk" && $1 != sysdisk {print $1}'); do
        DISKS_TO_FORMAT+=("/dev/$disk")
    done
    DISK_ARRAY=("${DISKS_TO_FORMAT[@]}")
    NUMBER_DISKS=${#DISKS_TO_FORMAT[@]}
    mflibs::status::info "$(zen::i18n::translate "raid.disk_to_format" "${DISKS_TO_FORMAT[*]}" "$disk_name")"
    mflibs::shell::icon::warning::yellow;mflibs::shell::text::yellow "$(zen::i18n::translate "raid.number_of_disks" "$NUMBER_DISKS")"
    mflibs::shell::icon::warning::yellow;mflibs::shell::text::yellow "$(zen::i18n::translate "raid.future_disk" "${DISK_ARRAY[*]}")"
}

# @function raid::format::disk
# Formats disks for RAID array creation.
# @description This function prompts the user to confirm disk formatting and proceeds to wipe and partition each disk in preparation for RAID array creation.
# It ensures that each disk is properly prepared and partitioned with the specified filesystem type.
# @stdout Guides the user through disk formatting process and reports on the status of each disk.
raid::format::disk(){
    echo ""
    local prompt_message
    prompt_message=$(mflibs::shell::icon::ask::yellow;mflibs::shell::text::yellow "$(zen::i18n::translate "common.continue_prompt") ?")
    mflibs::shell::prompt "$prompt_message" N || { mflibs::status::warn "$(zen::i18n::translate "raid.creation_aborted")"; exit 1; }

    mflibs::status::header "$(zen::i18n::translate "raid.creating_partitions_empty_disks")"
    for disk in "${DISKS_TO_FORMAT[@]}"; do
        mflibs::log "wipefs -a $disk" || { mflibs::status::error "$(zen::i18n::translate "raid.error_formatting_disk" "$disk")"; zen::dependency::apt::remove "${raid_packages[@]}"; exit 1; }
        mflibs::log "parted -s $disk mklabel msdos mkpart primary $filesystem_type 1 100%" || { mflibs::status::error "$(zen::i18n::translate "raid.error_creating_partition" "$disk")"; zen::dependency::apt::remove "${raid_packages[@]}"; exit 1; }
        sleep 3
    done
    mflibs::status::success "$(zen::i18n::translate "raid.disk_partitions_created")"
    sleep 5
}

# @function raid::create::mdadm::disk
# Creates a RAID array using mdadm.
# @description This function creates a RAID array with the specified RAID level using the mdadm utility.
# It handles different RAID levels and configures the RAID array accordingly.
# The RAID array is created using the disks that were formatted in the previous step.
# @stdout Details the RAID creation process and reports any errors encountered.
raid::create::mdadm::disk(){
    local data_raid_level
    local metadata_raid_level
    case $raid_level in
        0) 
            data_raid_level="RAID$raid_level"
            metadata_raid_level="DUP"
            ;;
        1 | "1c3" | "1c4")
            data_raid_level="RAID$raid_level"
            metadata_raid_level="RAID$raid_level"
            ;;
        5)
            data_raid_level="RAID$raid_level"
            metadata_raid_level="RAID1"
            ;;
        6)
            data_raid_level="RAID$raid_level"
            metadata_raid_level="RAID1c3"
            ;;
        10)
            data_raid_level="RAID$raid_level"
            metadata_raid_level="RAID1"
            ;;
        *)
            mflibs::status::error "$(zen::i18n::translate "raid.invalid_raid_level" "${raid_levels[@]}")"
            return 1
            ;;
    esac
    mflibs::status::header "$(zen::i18n::translate "raid.creating_raid_disk" "$raid_level" "$disk_name")"
    mflibs::log "mdadm --create --verbose /dev/$disk_name --level=$raid_level --raid-devices=$NUMBER_DISKS ${DISK_ARRAY[*]}" || { mflibs::status::error "$(zen::i18n::translate "raid.error_creating_raid_disk")"; zen::dependency::apt::remove "${raid_packages[@]}"; exit 1; }
    sleep 5
    mflibs::status::info "$(zen::i18n::translate "raid.formatting_raid_disk" "$disk_name" "$filesystem_type")"
	if [[ "$filesystem_type" == "btrfs" ]]; then
        mflibs::log "mkfs.btrfs -L mediaease --data $data_raid_level --metadata $metadata_raid_level /dev/$disk_name" || { mflibs::status::error "$(zen::i18n::translate "raid.error_partitioning_raid_disk")"; zen::dependency::apt::remove "${raid_packages[@]}"; exit 1; }
    else
        mflibs::log "mkfs.ext4 -L mediaease -F /dev/$disk_name" || { mflibs::status::error "$(zen::i18n::translate "raid.error_partitioning_raid_disk")"; zen::dependency::apt::remove "${raid_packages[@]}"; exit 1; }
    fi
    mflibs::status::success "$(zen::i18n::translate "raid.disk_partitioned" "$disk_name" "$filesystem_type")"
    sleep 5
}

# @function raid::mount::mdadm::disk
# Mounts the RAID array to a specified mount point.
# @description After creating the RAID array, this function mounts it to the provided mount point.
# It also updates the /etc/fstab file to ensure the RAID array is mounted automatically on boot.
# @stdout Indicates the mounting process of the RAID array and updates the /etc/fstab file.
raid::mount::mdadm::disk(){
    local RAID_UUID
    RAID_UUID=$(blkid -o value -s UUID "/dev/$disk_name")
    if mdadm --detail --scan | grep -q "/dev/$disk_name"; then
        mflibs::status::header "$(zen::i18n::translate "raid.mounting_raid_disk" "$disk_name" "$mount_point")"
        if grep -Fxq "UUID=$RAID_UUID $mount_point $filesystem_type defaults 0 0" /etc/fstab; then
            mflibs::status::error "$(zen::i18n::translate "raid.disk_already_mounted" "$disk_name" "$mount_point")"
        else
            {
                echo "# MediaEase RAID"
                echo "UUID=$RAID_UUID $mount_point $filesystem_type defaults 0 0"
                echo "# MediaEase RAID"
            } >> /etc/fstab
            [ ! -d "$mount_point" ] && mkdir -p "$mount_point"
            mount -a || { mflibs::status::error "$(zen::i18n::translate "raid.error_mounting_raid_disk" "$disk_name" "$mount_point")"; }
            mflibs::status::success "$(zen::i18n::translate "raid.disk_mounted" "$disk_name" "$mount_point")"
        fi
    else
        mflibs::status::error "$(zen::i18n::translate "raid.created_not_mounted" "$disk_name")"
    fi
}


raid::process::args "$@"
