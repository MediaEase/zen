#!/usr/bin/env bash
# @file extras/scripts/raid.sh
# @project MediaEase
# @version 1.0.0
# @description Automatically creates a RAID array and mounts it to the specified mount point.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function raid::process::args
# @description Processes command-line arguments for creating a new RAID array.
# @arg $1 string The RAID level to be created (0, 5, 6, 10).
# @arg $2 string The mount point for the RAID array (default: /home).
# @arg $3 string The filesystem type for the RAID array (default: ext4).
# @arg $4 string The name of the RAID array (default: md0).
# @stdout Parses the RAID level, mount point, filesystem type, and disk name from the arguments.
# @note Processes command-line arguments and performs necessary operations.
function raid::process::args() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: $0 [RAID_LEVEL] [MOUNT_POINT] [FILESYSTEM_TYPE] [DISK_NAME]"
        exit 1
    fi

    declare -g raid_level=$1
    declare -g mount_point=${2:-/home}
    declare -g filesystem_type=${3:-ext4}
    declare -g disk_name=${4:-md0}
    local raid_levels=("0" "5" "6" "10")
    local types=("ext4" "btrfs")

    case $raid_level in
        0) min_disks=2 ;;
        5) min_disks=3 ;;
        6) min_disks=4 ;;
        10) min_disks=4 ;;
        *) mflibs::status::error "$(zen::i18n::translate "raid.invalid_raid_level" "${raid_levels[@]}")"; exit 1 ;;
    esac
    case $filesystem_type in
        ext4|btrfs) ;;
        *) mflibs::status::error "$(zen::i18n::translate "raid.invalid_filesystem_type" "${types[@]}")"; exit 1 ;;
    esac

    raid::disk::detection

    if [ "$NUMBER_DISKS" -lt "$min_disks" ]; then
        mflibs::status::error "$(zen::i18n::translate "raid.not_enough_disks" "$raid_level" "$min_disks")" >&2

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
# @description Detects the system disk and the disks to be formatted for creating a new RAID array.
# @stdout Prints the system disk and the disks to be formatted.
function raid::disk::detection() {
    ROOT_DEVICE=$(findmnt -n -o SOURCE --target /)
    if [[ $ROOT_DEVICE == /dev/md* ]]; then
        SYSTEM_DISK=$ROOT_DEVICE
    else
        SYSTEM_DISK=$(lsblk -no PKNAME "$ROOT_DEVICE")
    fi

    mflibs::status::info "$(zen::i18n::translate "raid.system_disk" "$SYSTEM_DISK")"
    DISKS_TO_FORMAT=()
    for disk in $(lsblk -nd -o NAME,TYPE | awk '$2 == "disk" {print $1}'); do
        disk_path="/dev/$disk"
        if [[ $disk_path != "$SYSTEM_DISK" ]] && ! grep -q "$disk_path" /proc/mdstat; then
            DISKS_TO_FORMAT+=("$disk_path")
        fi
    done
    DISK_ARRAY=("${DISKS_TO_FORMAT[@]}")
    NUMBER_DISKS=${#DISKS_TO_FORMAT[@]}
    
    # Warning outputs
    mflibs::status::info "$(zen::i18n::translate "raid.disk_to_format" "${DISKS_TO_FORMAT[*]}" "${DISK_ARRAY[*]}")"
    mflibs::shell::text::yellow "$(zen::i18n::translate "raid.number_of_disks" "$NUMBER_DISKS")"
    mflibs::shell::text::yellow "$(zen::i18n::translate "raid.future_disk" "${DISK_ARRAY[*]}")"
}

# @function raid::format::disk
# @description Formats the disks to be used for creating a new RAID array.
# @stdout Prompts the user to confirm formatting the disks and formats the disks if the user confirms.
function raid::format::disk(){
    echo ""
    mflibs::shell::icon::warning::yellow;mflibs::shell::text::yellow::sl "Continue ? [";mflibs::shell::text::green::sl "Y";mflibs::shell::text::yellow::sl "] or [";mflibs::shell::text::red::sl "N";mflibs::shell::text::yellow::sl "] (default : ";mflibs::shell::text::red::sl "N";mflibs::shell::text::yellow::sl " )"
    echo -ne "[Y] >";mflibs::shell::text::green " Continue"
    echo -ne "[N] >";mflibs::shell::text::red " Cancel"
    echo -en "> "
    read -r startraid
    case $startraid in
        [yY]) formatdisk=1 ;;
        [nN] | "") formatdisk=0 ;;
        *) formatdisk=0 ;;
    esac

    if [[ $formatdisk = 1 ]]; then
        mflibs::status::header "$(zen::i18n::translate "raid.creating_partitions_empty_disks")"
        for disk in "${DISKS_TO_FORMAT[@]}"; do
            wipefs -a "$disk" &> /dev/null || { mflibs::status::error "$(zen::i18n::translate "raid.error_formatting_disk" "$disk")"; continue; }
            parted -s "$disk" mklabel msdos mkpart primary "$filesystem_type" 1 100% &> /dev/null || { mflibs::status::error "$(zen::i18n::translate "raid.error_creating_partition" "$disk")"; continue; }
            sleep 3
        done
        mflibs::status::success "$(zen::i18n::translate "raid.disk_partitions_created")"
    else
        mflibs::status::error "$(zen::i18n::translate "raid.disk_partitions_not_created")"
    fi
    sleep 5
}

# @function raid::create::mdadm::disk
# @description Creates a new RAID array using the formatted disks.
# @stdout Creates a new RAID array and formats it with the specified filesystem type.
function raid::create::mdadm::disk(){
    local data_raid_level
    local metadata_raid_level
    local fs_type_upper
    case $raid_level in
        0) 
            data_raid_level="RAID0"
            metadata_raid_level="DUP"
            ;;
        1 | "1c3" | "1c4")
            data_raid_level="RAID$raid_level"
            metadata_raid_level="RAID$raid_level"
            ;;
        5)
            data_raid_level="RAID5"
            metadata_raid_level="RAID1"
            ;;
        6)
            data_raid_level="RAID6"
            metadata_raid_level="RAID1c3"
            ;;
        10)
            data_raid_level="RAID10"
            metadata_raid_level="RAID1"
            ;;
        *)
            mflibs::status::error "$(zen::i18n::translate "raid.invalid_raid_level" "${raid_levels[@]}")"
            return 1
            ;;
    esac
    mflibs::status::header "$(zen::i18n::translate "raid.creating_raid_disk" "$disk_name" "$raid_level")"
    mdadm --create --verbose "/dev/$disk_name" --level="$raid_level" --raid-devices="$NUMBER_DISKS" "${DISK_ARRAY[@]}" >/dev/null 2>&1 || { mflibs::status::error "$(zen::i18n::translate "raid.error_creating_raid_disk")"; }
    sleep 5
	if [[ "$filesystem_type" == "btrfs" ]]; then
        mkfs.btrfs -L mediaease-data --data "$data_raid_level" --metadata "$metadata_raid_level" "/dev/$disk_name" >/dev/null 2>&1 || { mflibs::status::error "$(zen::i18n::translate "raid.error_partitioning_raid_disk")"; }
    else
        mkfs.ext4 -L mediaease-data -F "/dev/$disk_name" >/dev/null 2>&1 || { mflibs::status::error "$(zen::i18n::translate "raid.error_partitioning_raid_disk")"; }
    fi
    fs_type_upper=$(echo "$filesystem_type" | tr '[:lower:]' '[:upper:]')
    mflibs::status::info "$(zen::i18n::translate "raid.formatting_raid_disk" "$disk_name" "$fs_type_upper")"
    mkfs."$filesystem_type" -F "/dev/$disk_name" >/dev/null 2>&1 || { mflibs::status::error "$(zen::i18n::translate "raid.error_partitioning_raid_disk")"; }
    mflibs::status::success "$(zen::i18n::translate "raid.disk_partitioned" "$disk_name" "$filesystem_type")"
    sleep 5
	
    mflibs::status::success "$(zen::i18n::translate "raid.raid_disk_created" "$disk_name")"
}

# @function raid::mount::mdadm::disk
# @description Mounts the RAID array to the specified mount point.
# @stdout Mounts the RAID array to the specified mount point and adds an entry to /etc/fstab.
function raid::mount::mdadm::disk(){
    local RAID_UUID
    RAID_UUID=$(find /dev/disk/by-uuid/ -maxdepth 1 -type l -name 'md*' -printf '%l\n' | sed 's/ ->.*//')
	
    if mdadm --detail --scan | grep -q "/dev/$disk_name"; then
        mflibs::status::header "$(zen::i18n::translate "raid.mounting_raid_disk" "$disk_name" "$mount_point")"
        if grep -Fxq "UUID=$RAID_UUID LABEL=mediaease-data $mount_point $filesystem_type defaults 0 0" /etc/fstab; then
            mflibs::status::error "$(zen::i18n::translate "raid.disk_already_mounted" "$disk_name" "$mount_point")"
        else
            {
                echo "# MediaEase RAID"
                echo "UUID=$RAID_UUID LABEL=mediaease-data $mount_point $filesystem_type defaults 0 0"
                echo "# MediaEase RAID"
            } >> /etc/fstab
            mount -a || { mflibs::status::error "$(zen::i18n::translate "raid.error_mounting_raid_disk" "$disk_name" "$mount_point")"; }
            mflibs::status::success "$(zen::i18n::translate "raid.disk_mounted" "$disk_name" "$mount_point")"
        fi
    else
        mflibs::status::error "$(zen::i18n::translate "raid.created_not_mounted" "$disk_name")"
    fi
}

raid::process::args "$@"
