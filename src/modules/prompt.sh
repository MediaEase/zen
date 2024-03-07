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

# @function zen::prompt::yn
# @description: prompt for yes or no
# @example:
#   zen::prompt::yn "hi" "Y"
# @example:
#   zen::prompt::yn "hi" "N"
# @arg $1: string
# @arg $2: string
# @stdout: "hi ➜ [Y] or [N] (default : Y):" or "hi ➜ [Y] or [N] (default : N):"
# @exitcode 0: if yes
# @exitcode 1: if no
zen::prompt::yn() {
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

# @function zen::prompt::choices
# @description: Presents a list of choices to the user and allows them to select one.
# @example:
#   possible_choices=("option1" "option2" "option3")
#   zen::prompt::choices possible_choices[@] selected_choice "Please select an option:"
# @arg $1: array (passed by reference) - Array of choices to present.
# @arg $2: string - The name of the variable to store the user's selection.
# @arg $3: string (optional) - Custom prompt message.
# @stdout: Custom prompt message followed by a list of choices.
# @exitcode 0: Successful execution, selection made.
# @exitcode 1: No valid choices available or invalid selection.
zen::prompt::choices() {
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

# @function zen::prompt::code
# @description: Prompts the user to input a specific code or string. Can be used for verification purposes.
# @example:
#   zen::prompt::code "Enter the secret code:" "1234" "code"
# @arg $1: string - Custom prompt message.
# @arg $2: string - The specific code or string the user must input.
# @arg $3: string (optional) - Context of the prompt ('code' for general code, 'password' for password input).
# @stdout: Custom prompt message and additional context-specific prompt (if applicable).
# @exitcode 0: Correct code or string entered.
# @exitcode 1: Incorrect input, continues prompting.
zen::prompt::code() {
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
