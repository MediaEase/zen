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
    prompt=$(mflibs::shell::text::green::sl "[Y]";mflibs::shell::text::white::sl " $(zen::i18n::translate "common.or" | tr '[:upper:]' '[:lower:]') ";mflibs::shell::text::red::sl "[N] ";mflibs::shell::text::white::sl "(default : ";mflibs::shell::text::green::sl "Y";mflibs::shell::text::white::sl " ): ")
    default=Y
  elif [[ "${2:-}" = "N" ]]; then
    prompt=$(mflibs::shell::text::green::sl "[Y]";mflibs::shell::text::white::sl " $(zen::i18n::translate "common.or" | tr '[:upper:]' '[:lower:]') ";mflibs::shell::text::red::sl "[N] ";mflibs::shell::text::white::sl "(default : ";mflibs::shell::text::red::sl "N";mflibs::shell::text::white::sl " ): ")
    default=N
  else
    prompt="y/n/c"
    default=
  fi
  while true; do
    printf "%s %s" "$1" "$prompt"
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

# @function zen::prompt::raid
# @description: Presents a list of RAID levels to the user and allows them to select one.
#               This function dynamically generates a list of RAID options based on the input array.
# @arg $1: string (optional) - Custom prompt message, with a default value provided via internationalization.
# @arg $2: string - The name of the variable to store the user's selection.
# @arg $3 onwards: array (passed by reference) - Array of RAID levels to present as choices.
# @stdout: Custom prompt message followed by a dynamically generated list of RAID levels for selection.
# @exitcode 0: Successful execution, a valid RAID level is selected.
# @exitcode 1: Invalid selection or no RAID levels provided.
# @example:
#   zen::prompt::raid "Choose a RAID level:" chosen_level raid_levels[@]
zen::prompt::raid() {
  local prompt="${1:-"\e[1;36m$(zen::i18n::translate "common.your_choice")\e[0m"}"
  local -n output_var="${2:-}"
  local choices=("${@:3}")
  local choice
  local choice_num
  echo -e "${prompt}"
  for index in "${!choices[@]}"; do
    echo -e "    \e[96m$((index + 1)))\e[0m RAID${choices[index]}"
  done
  while true; do
    printf "%s : " "$(mflibs::shell::text::white::sl " $(zen::i18n::translate "common.your_choice") ")"
    read -r choice_num < /dev/tty
    if [[ "$choice_num" =~ ^[0-9]+$ ]] && (( choice_num >= 1 && choice_num <= ${#choices[@]} )); then
      choice="${choices[choice_num - 1]}"
      break
    else
      echo -e "\e[31m$(zen::i18n::translate "common.invalid_input")\e[0m"
    fi
  done
  # shellcheck disable=SC2034
  output_var="$choice"
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
    printf "%s %s" "$(mflibs::shell::text::cyan::sl " ➜ ")" "$prompt"
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
