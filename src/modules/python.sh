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
        mflibs::shell::text::red "$(zen::i18n::translate "python.venv_create.no_path")"
        return 1
    fi
    mflibs::shell::text::white "$(zen::i18n::translate "python.venv_create_creating" "$app_name")"
    
    cd "$path" || return 1
    sudo -u "${username}" python3 -m venv venv || return 1
    mflibs::shell::text::green "$(zen::i18n::translate "python.venv_create_success" "$app_name")"
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
zen::python::venv::build() {
    local path="$1"
    local dependencies_file="${MEDIAEASE_HOME}/MediaEase/scripts/src/dependencies.yaml"
    local python_dependencies
    local requirements_path="$path/requirements.txt"

    if [[ -z "$path" ]]; then
        mflibs::shell::text::red "$(zen::i18n::translate "python.venv_install_no_path")"
        return 1
    fi

    # Activate the virtual environment
    # shellcheck disable=SC1091
    source "$path/venv/bin/activate"
    mflibs::shell::text::green "$(zen::i18n::translate "python.venv_install_activated")"
    # Install Python dependencies from dependencies.yaml file
    python_dependencies=$(yq e ".${app_name}.python" "$dependencies_file" 2>/dev/null)
    if [[ -z "$python_dependencies" ]]; then
        mflibs::status::error "$(zen::i18n::translate 'dependency.no_python_dependencies_found' "$app_name")"
        deactivate
        return 1
    fi
    mflibs::shell::text::white "$(zen::i18n::translate "python.venv_install_required_dependencies" "$app_name")"
    local exit_status=0
    IFS=' ' read -ra DEPS <<< "$python_dependencies"
    for dependency in "${DEPS[@]}"; do
        mflibs::log "pip install --quiet --use-pep517 ${dependency}"
        local result=$?
        if [[ "$result" -ne 0 ]]; then
            mflibs::status::error "$(zen::i18n::translate 'dependency.python_dependency_install_failed' "$dependency")"
            exit_status=1
        fi
    done
    mflibs::shell::text::green "$(zen::i18n::translate "python.venv_install_required_dependencies_success" "$app_name")"

    # Install requirements from requirements.txt file
    if [[ $exit_status -eq 0 && -f "$requirements_path" ]]; then
        mflibs::shell::text::white "$(zen::i18n::translate "python.venv_install_requirements" "$app_name")"
        mflibs::log "pip install --use-pep517 --quiet --exists-action s -r $requirements_path"
        if [[ $? -ne 0 ]]; then
            mflibs::status::error "$(zen::i18n::translate "python.venv_install_requirements_error" "$software_name")"
            exit_status=1
        fi
        mflibs::shell::text::green "$(zen::i18n::translate "python.venv_install_requirements_success" "$software_name")"
    fi

    # Deactivate the virtual environment
    deactivate

    if [[ $exit_status -eq 0 ]]; then
        mflibs::status::success "$(zen::i18n::translate "python.venv_install_success" "$software_name")"
    fi

    return $exit_status
}

# @function zen::python::venv::remove
# @description Removes a Python virtual environment from the filesystem.
# @arg $1 string The filesystem path where the virtual environment should be removed.
# @global user Associative array containing user-specific information.
# @return 1 if no path is specified or if the directory change fails.
# @note The virtual environment is removed from the perspective of the specified user.
zen::python::venv::remove(){
    local path="$1"
    if [[ -z "$path" ]]; then
        mflibs::shell::text::red "$(zen::i18n::translate "python.venv_remove_no_path")"
        return 1
    fi

    cd "$path" || return 1
    if ! sudo -u "${user[username]}" bash -c "source venv/bin/activate && pip uninstall -y -r requirements.txt"; then
        mflibs::status::error "$(zen::i18n::translate "python.venv_remove_error" "$app_name")"
        return 1
    fi
    cd ..
    rm -rf "$path"

    mflibs::status::success "$(zen::i18n::translate "python.venv_remove_success" "$app_name")"
}

zen::python::add::profile(){
    local target_file="$1"
    {
        printf "export PYENV_ROOT=\"/opt/pyenv\"\n"
        printf "export PATH=\"/opt/pyenv/bin:\$PATH\"\n"
        printf "eval \"\$(pyenv init -)\"\n"
        printf "eval \"\$(pyenv virtualenv-init -)\"\n"
        printf "source %s/.cargo/env\n" "$HOME"
    } >> "$target_file"
}
