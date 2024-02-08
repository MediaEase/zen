#!/usr/bin/env bash

################################################################################
# File: python.sh
# Version: 1
# Project: zen
# Description: A library for managing Python virtual environments.
#
# Author: Thomas Chauveau (tomcdj71)
# Contact: thomas.chauveau.pro@gmail.com
#
# License: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2024, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# zen::python::venv::create
#
# Creates a Python virtual environment in the specified path.
#
# Arguments:
#   path - The filesystem path where the virtual environment should be created.
# Globals:
#   user - An associative array containing user-specific information.
# Returns:
#   1 if no path is specified or if the directory change fails.
# Notes:
#   The virtual environment is created from the perspective of the specified user.
# shellcheck disable=SC2154
# Disabling SC2154 because the variable is defined in the main script
################################################################################
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

################################################################################
# zen::python::venv::install
#
# Installs Python packages in a virtual environment from a requirements file and
# optionally pre-installs specified packages.
#
# Arguments:
#   path - The path to the virtual environment.
#   requirements_file - Path to the requirements file.
#   prebuild - Space-separated string of packages to pre-install.
# Globals:
#   user - An associative array containing user-specific information.
# Returns:
#   1 if no path or requirements file is specified, or if an error occurs during installation.
# Notes:
#   Activates the virtual environment and installs packages as the specified user.
#   Reports success or failure for the installation of prebuild packages and requirements.
################################################################################
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

    if [[ -z "$requirements_file" ]]; then
        mflibs::shell::text::red "$(zen::i18n::translate "python.venv.install.no_requirements")"
        return 1
    fi

    cd "$path" || return 1
    if [[ -n "$prebuild" ]]; then
        if ! sudo -u "$username" bash -c "source venv/bin/activate && pip install --upgrade --exists-action s $prebuild"; then
            mflibs::status::error "$(zen::i18n::translate "python.venv.install.depend_error" "$app_name")"
            return 1
        fi
    fi

    if ! sudo -u "$username" bash -c "source venv/bin/activate && pip install --exists-action s -r '$requirements_file'"; then
        mflibs::status::error "$(zen::i18n::translate "python.venv.install.requirements_error" "$app_name")"
        return 1
    fi

    mflibs::status::success "$(zen::i18n::translate "python.venv.install.success" "$app_name")"
}
