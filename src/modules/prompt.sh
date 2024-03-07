#!/usr/bin/env bash
# @file modules/prompt.sh
# @project MediaEase
# @version 1.0.0
# @description Contains a library of internationalization functions used in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

################################################################################
# @description: prompt for yes or no
# @example:
#   mflibs::shell::prompt::yn "hi"
# @arg $1: string
################################################################################
mflibs::shell::prompt::yn() {
  declare prompt default reply
  if [[ "${2:-}" = "Y" ]]; then
    prompt=$(mflibs::shell::text::green::sl "[Y]";mflibs::shell::text::white::sl " $(zen::i18n::translate "common.or" | tr '[:upper:]' '[:lower:]') ";mflibs::shell::text::red::sl "[N] ";mflibs::shell::text::white::sl "[C] (default : ";mflibs::shell::text::green::sl "Y";mflibs::shell::text::white::sl " ):")
    default=Y
  elif [[ "${2:-}" = "N" ]]; then
    prompt=$(mflibs::shell::text::green::sl "[Y]";mflibs::shell::text::white::sl " $(zen::i18n::translate "common.or" | tr '[:upper:]' '[:lower:]') ";mflibs::shell::text::red::sl "[N] ";mflibs::shell::text::white::sl "[C] (default : ";mflibs::shell::text::red::sl "N";mflibs::shell::text::white::sl " ):")
    default=N
  else
    prompt="y/n/c"
    default=
  fi
  while true; do
    printf "%s %s %s" "$1" "$(mflibs::shell::text::cyan " ➜ ")" "$prompt"
    read -r reply < /dev/tty
    if [[ -z "$reply" ]]; then
      reply=$default
    fi

    case "$reply" in
      Y* | y*) return 0 ;;
      N* | n*) return 1 ;;
    esac
  done
}

################################################################################
# @description: prompt for a choice
# @example:
#   mflibs::shell::prompt::yn::choices "choices" "output_var" "prompt"
# @arg $1: array
# @arg $2: string
# @arg $3: string
################################################################################
mflibs::shell::prompt::yn::choices() {
    declare -a choice_list=("${!1}")
    declare -n output_var=$2
    declare prompt="${3:-"$(zen::i18n::translate "common.choices")"}"

    mflibs::shell::text::cyan "$prompt"
    select choice in "${choice_list[@]}"; do
        if [[ -n "$choice" ]]; then
            output_var=$choice
            export output_var
            break
        else
            mflibs::shell::text::red "$(zen::i18n::translate "common.invalid_input" "$REPLY")"
        fi
    done
}

###############################################################################
# @description: prompt for a code input
# @example:
#   mflibs::shell::prompt::yn::code "prompt" "code"
# @arg $1: string
# @arg $2: string
# @arg $3: string
###############################################################################
mflibs::shell::prompt::yn::code() {
  local prompt="${1:-}"
  local string="${2:-}"
  local context="${3:-code}"

  while true; do
    printf "%s " "$prompt"
    
    if [[ "$context" == "code" ]]; then
      mflibs::shell::text::red::sl "$string"
    elif [[ "$context" == "password" ]]; then
      zen::vault::pass::decode "$string"
    fi
    mflibs::shell::text::cyan " ➜ "
    read -r reply < /dev/tty
    if [[ "$reply" == "$string" ]]; then
      return 0
    else
      mflibs::shell::text::red "$(zen::i18n::translate "common.invalid_input" "$reply")"
    fi
  done
}
