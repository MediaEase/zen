#!/bin/bash
# shellcheck disable=SC1091
base_dir="/home/thomas/Dev/SelfHosted-GitLab/Organizations/MediaEase/scripts/modules"
source "$base_dir/logger"
source "$base_dir/file"
file::load_locale_file "en"
source "$base_dir/i18n"
source "$base_dir/app_functions"
source "$base_dir/apt_functions"
source "$base_dir/users"
