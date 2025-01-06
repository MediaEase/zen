#!/usr/bin/env bash
# @file modules/permission.sh
# @project MediaEase
# @version 1.0.8
# @description Contains a library of functions to manage file permissions in the MediaEase project.
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @section Permission Functions
# @description The following functions handle setting file permissions.

# @function zen::permission::fix
# Sets permissions for a specified path.
# @description This function sets the permissions of a given path to the specified values.
# It validates the existence of the path and the format of the permissions before applying them.
# It can handle both files and directories, applying different permissions as needed.
# @arg $1 string Path.
# @arg $2 string File permissions (numeric or symbolic).
# @arg $3 string Directory permissions (numeric or symbolic).
# @arg $4 string User.
# @arg $5 string Group.
# @exitcode 0 on success.
# @exitcode 1 if missing arguments.
# @exitcode 2 if the path does not exist.
# @exitcode 3 if the permission format is invalid.
# @caution Ensure that the user and group have the necessary permissions to modify the specified path.
# @important Incorrect permissions can lead to security vulnerabilities or application failures.
# @example
#   zen::permission::fix "/path/to/directory" "644" "755" "username" "groupname"
zen::permission::fix() {
    local path=$1
    local file_permission=$2
    local dir_permission=$3
    local user=$4
    local group=${5:-$user}

    if [[ -z "$path" || -z "$file_permission" || -z "$dir_permission" || -z "$user" ]]; then
        [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: ${FUNCNAME[0]} is missing arguments\n" >&2
        return 1
    fi
    if [[ ! -e "$path" ]]; then
        [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo -ne "[$(tput setaf 1)2$(tput sgr0)]: $path does not exist\n" >&2
        return 2
    fi

    if ! [[ "$file_permission" =~ ^[0-7]{3,4}$ || "$file_permission" =~ ^[ugoa]*[-+=]?[rwxXst]*$ ]]; then
        [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo -ne "[$(tput setaf 1)3$(tput sgr0)]: Invalid file permission format '$file_permission'\n" >&2
        return 3
    fi

    if ! [[ "$dir_permission" =~ ^[0-7]{3,4}$ || "$dir_permission" =~ ^[ugoa]*[-+=]?[rwxXst]*$ ]]; then
        [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo -ne "[$(tput setaf 1)3$(tput sgr0)]: Invalid directory permission format '$dir_permission'\n" >&2
        return 3
    fi

    chown -R "$user:$group" "$path"

    if [[ -d "$path" ]]; then
        find "$path" -type d -exec chmod "$dir_permission" {} +
        find "$path" -type f -exec chmod "$file_permission" {} +
    else
        chmod "$file_permission" "$path"
    fi

    return 0
}

# @function zen::permission::add
# Creates a chmod function for symbolic permissions.
# @description This function dynamically creates a chmod function for the given symbolic or numeric permissions.
# @arg $1 string File permissions (numeric or symbolic).
# @arg $2 string Directory permissions (numeric or symbolic).
# @arg $3 string Symbolic function name.
# @example
#   zen::permission::add "644" "755" "read_exec"
# @note Useful for creating reusable permission setting functions.
zen::permission::add() {
    local file_permission=$1
    local dir_permission=$2
    local symbolic_function_name=$3

    eval "
        zen::permission::$symbolic_function_name() {
            zen::permission::fix \"\$1\" \"$file_permission\" \"$dir_permission\" \"\$2\" \"\${3:-\$2}\"
        }
    "
}

# Define a mapping of symbolic function names to file and directory permissions
declare -A permission_mapping=(
    ["read_exec"]="644 755"
    ["exec_exec"]="755 755"
    ["private"]="600 700"
    ["full"]="777 777"
    ["readonly"]="555 555"
    ["all_exec"]="a+x a+x"
    ["user_exec"]="u+x u+x"
)

# Create functions for each symbolic permission
for symbolic in "${!permission_mapping[@]}"; do
    IFS=' ' read -r -a permissions <<<"${permission_mapping[$symbolic]}"
    zen::permission::add "${permissions[0]}" "${permissions[1]}" "$symbolic"
done

# Example usage:
# zen::permission::read_exec /path/to/directory username groupname
# zen::permission::exec_exec /path/to/file username groupname
# zen::permission::user_exec /path/to/file username groupname
