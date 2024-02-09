#!/usr/bin/env bash
# @file modules/python.sh
# @brief A library for managing Python virtual environments.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::python::venv::create
# @description Creates a Python virtual environment in the specified path.
# @arg $1 string The filesystem path where the virtual environment should be created.
# @global user Associative array containing user-specific information.
# @return 1 if no path is specified or if the directory change fails.
# @note The virtual environment is created from the perspective of the specified user.
# shellcheck disable=SC2154
# Disabling SC2154 because the variable is defined in the main script
zen::python::venv::create() {
    local path="$1"
    local username="${user[username]}"

    if [[ -z "$path" ]]; then
        mflibs::shell::text::red "$(zen::i18n::translate "python.venv.create.no_path")"
        return 1
    fi
    
    cd "$path" || return 1
    sudo -u "$username" python3 -m venv venv
}

# @function zen::python::venv::install
# @description Installs Python packages in a virtual environment from a requirements file.
# @arg $1 string The path to the virtual environment.
# @arg $2 string The path to the requirements file.
# @arg $3 string Space-separated string of packages to pre-install.
# @global user Associative array containing user-specific information.
# @return 1 if no path is specified, or if an error occurs during installation.
# @note Activates the virtual environment and installs packages as the specified user.
#      Reports success or failure for the installation of prebuild packages and requirements.
zen::python::venv::install() {
    local path="$1"
    local requirements_file="$2"
    local prebuild="$3"
    local username="${user[username]}"
    app_name=$(basename "$path")

    if [[ -z "$path" ]]; then
        mflibs::shell::text::red "$(zen::i18n::translate "python.venv.install.no_path")"
        return 1
    fi

    cd "$path" || return 1
    if [[ -n "$prebuild" ]]; then
        if ! sudo -u "$username" bash -c "source venv/bin/activate && pip install --upgrade --exists-action s $prebuild"; then
            mflibs::status::error "$(zen::i18n::translate "python.venv.install.depend_error" "$app_name")"
            return 1
        fi
    fi

    if [[ -f "$requirements_file" ]]; then
        if ! sudo -u "$username" bash -c "source venv/bin/activate && pip install --exists-action s -r '$requirements_file'"; then
            mflibs::status::error "$(zen::i18n::translate "python.venv.install.requirements_error" "$app_name")"
            return 1
        fi
    fi

    mflibs::status::success "$(zen::i18n::translate "python.venv.install.success" "$app_name")"
}
