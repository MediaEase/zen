#!/usr/bin/env bash
# @file zen/src/tools/quota.sh
# @project MediaEase
# @description Quota installation and management tool
# @version 1.1.11
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @function zen::tools::quota::install
# @description Installs and configures user disk quotas on the system.
zen::tools::quota::install() {
    mflibs::shell::text::white "Current disk partitions:"
    lsblk
    echo ""
    local mount_point
    mflibs::shell::text::yellow "Select the mount point for user quotas:"
    echo "1) / (root)"
    echo "2) /home"
    local choice
    zen::prompt::input "$(mflibs::shell::text::white "Enter your choice (default 1):")" "numeric" choice
    choice="${choice:-1}"
    case "$choice" in
    1 | "")
        mount_point="/"
        ;;
    2)
        mount_point="/home"
        ;;
    *)
        mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_choice")"
        exit 1
        ;;
    esac
    mflibs::shell::text::white "Using mount point: $mount_point"
    echo "ZEN_QUOTA_MOUNT_POINT=\"$mount_point\"" >>/etc/environment
    export ZEN_QUOTA_MOUNT_POINT="$mount_point"
    mflibs::shell::text::white "Installing quota package..."
    zen::dependency::apt::manage "install" "quota"
    mflibs::shell::text::white "Backing up /etc/fstab to /etc/fstab.bak..."
    cp /etc/fstab /etc/fstab.bak
    mflibs::shell::text::white "Modifying /etc/fstab to enable quotas..."
    local fstab_entry
    fstab_entry=$(grep -E "^.*[[:space:]]+${mount_point}[[:space:]]" /etc/fstab)
    if [[ -z "$fstab_entry" ]]; then
        mflibs::status::error "Mount point $mount_point not found in /etc/fstab. Aborting."
        exit 1
    fi
    local new_fstab_entry
    if [[ "$fstab_entry" == *"defaults"* ]]; then
        new_fstab_entry=${fstab_entry//defaults/defaults,usrjquota=aquota.user,jqfmt=vfsv1}
    else
        new_fstab_entry=${fstab_entry// /,usrjquota=aquota.user,jqfmt=vfsv1 }
    fi
    sed -i "s|$fstab_entry|$new_fstab_entry|" /etc/fstab
    mflibs::shell::text::white "Remounting $mount_point with new options..."
    mflibs::log "mount -o remount $mount_point"
    mflibs::shell::text::white "Running quotacheck..."
    mflibs::log "quotacheck -auMF vfsv1"
    mflibs::shell::text::white "Enabling quotas..."
    mflibs::log "quotaon -uv $mount_point"
    mflibs::shell::text::white "Starting quota service..."
    systemctl start quota
    systemctl enable quota
    mflibs::shell::text::white "Configuring sudoers for quota command..."
    cat >/etc/sudoers.d/zen_quota <<EOF
# Allow specific users or services to run 'quota' command without password
# Replace 'www-data' with the appropriate user if needed
Cmnd_Alias QUOTA = /usr/bin/quota
www-data ALL=(ALL) NOPASSWD: QUOTA
EOF
    mflibs::shell::text::green "Use 'zen tools quota set [username] [quota]' to set quotas per user."
    mflibs::status::success "Quota installation and configuration completed successfully."
}

# @function zen::tools::quota::set
# @description Sets disk quota for a specific user.
# @arg $1 string Username
# @arg $2 string Quota limit (e.g., '10G' for 10 Gigabytes, 'max' for maximum available)
# @example
#   zen tools quota set username 10G
zen::tools::quota::set() {
    local username="$1"
    local size="$2"
    if [[ -f /etc/environment ]]; then
        # shellcheck disable=SC1091
        source /etc/environment
    fi
    if [[ -z "$ZEN_QUOTA_MOUNT_POINT" ]]; then
        mflibs::status::error "Mount point is not set. Please run 'zen tools quota install' first."
        exit 1
    fi
    if [[ -z "$username" ]]; then
        zen::prompt::input "$(mflibs::shell::text::white "Enter username:")" "username" username
    else
        if ! zen::common::validate "username" "$username"; then
            mflibs::status::error "$(zen::i18n::translate "errors.common.invalid_username" "$username")"
            exit 1
        fi
    fi
    if ! id -u "$username" >/dev/null 2>&1; then
        mflibs::status::error "User '$username' does not exist. Exiting."
        exit 1
    fi
    if [[ -z "$size" ]]; then
        zen::prompt::input "$(mflibs::shell::text::white "Enter quota size for user (e.g., 500GB, 2TB, max):")" "" size
    fi
    if [[ "$size" == "max" ]]; then
        mlfibs::status::warning "Using 'max' size. This may exceed actual available disk space."
    elif [[ "$size" =~ ^[0-9]+(M|G|T)B$ ]]; then
        :
    else
        mflibs::status::error "Invalid quota size format. Use integers followed by MB, GB, TB, or 'max'."
        exit 1
    fi
    local block_size
    case "$size" in
    max)
        local mount_point
        mount_point=$(cat /install/.quota.lock)
        local filesystem
        filesystem=$(df "$mount_point" --output=source | tail -1)
        local one_k_blocks
        one_k_blocks=$(df "$filesystem" --output=size | tail -1)
        block_size="$one_k_blocks"
        ;;
    *TB)
        local quota_size=${size%TB}
        block_size=$((quota_size * 1024 * 1024 * 1024))
        ;;
    *GB)
        local quota_size=${size%GB}
        block_size=$((quota_size * 1024 * 1024))
        ;;
    *MB)
        local quota_size=${size%MB}
        block_size=$((quota_size * 1024))
        ;;
    esac
    mflibs::shell::text::white "Setting quota for user '$username' to '$size'..."
    mflibs::log "setquota -u $username $block_size $block_size 0 0 -a"
    mflibs::status::success "Quota set successfully for user '$username'."
}

# @function zen::tools::quota::status
# @description Displays quota usage for a specific user.
# @arg $1 string Username
zen::tools::quota::status() {
    local username="$1"
    if [[ -z "$username" ]]; then
        mflibs::status::error "Usage: zen tools quota status [username]"
        exit 1
    fi
    mflibs::status::info "Quota status for user '$username':"
    mflibs::log "quota -u $username"
}

# Main handler for 'zen tools quota' command
zen::tools::quota::handle() {
    local action="$1"
    shift

    case "$action" in
    install)
        zen::tools::quota::install "$@"
        ;;
    set)
        zen::tools::quota::set "$@"
        ;;
    status)
        zen::tools::quota::status "$@"
        ;;
    *)
        mflibs::status::error "Invalid action '$action'. Available actions: install, set, status"
        exit 1
        ;;
    esac
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    zen::tools::quota::handle "$@"
fi
