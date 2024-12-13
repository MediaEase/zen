#!/usr/bin/env bash
# @file modules/prompt.sh
# @project MediaEase
# @version 1.8.3
# @description Contains a library of internationalization functions used in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::prompt::yn
# @description: prompt for yes or no
# @example:
#   zen::prompt::yn "➜ Are you okay?" "Y"
# @example:
#   zen::prompt::yn "➜ Are you okay?" "N"
# @arg $1: string
# @arg $2: string
# @stdout: "➜ hi [Y] or [N] (default : Y):" or "➜ hi [Y] or [N] (default : N):"
# @exitcode 0: if yes
# @exitcode 1: if no
# @tip Use this function to prompt the user for confirmation before performing an action.
zen::prompt::yn() {
  declare prompt default reply
  if [[ "${2:-}" = "Y" ]]; then
    prompt=$(
      mflibs::shell::text::green::sl " [Y] "
      mflibs::shell::text::cyan::sl "$(zen::i18n::translate "prompts.common.or_label" | tr '[:upper:]' '[:lower:]')"
      mflibs::shell::text::red::sl " [N] "
      mflibs::shell::text::cyan::sl "($(zen::i18n::translate "prompts.common.default") : "
      mflibs::shell::text::green::sl "[Y]"
      mflibs::shell::text::cyan::sl "): "
    )
    default=Y
  elif [[ "${2:-}" = "N" ]]; then
    prompt=$(
      mflibs::shell::text::green::sl " [Y] "
      mflibs::shell::text::cyan::sl "$(zen::i18n::translate "prompts.common.or_label" | tr '[:upper:]' '[:lower:]')"
      mflibs::shell::text::red::sl " [N]"
      mflibs::shell::text::cyan::sl "($(zen::i18n::translate "prompts.common.default") : "
      mflibs::shell::text::red::sl "[N]"
      mflibs::shell::text::cyan::sl "): "
    )
    default=N
  else
    prompt="y/n/c"
    default=
  fi
  while true; do
    printf "%s %s" "$1" "$prompt"
    read -r reply </dev/tty
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
# @tip Use this function to help users select from multiple RAID configuration options.
zen::prompt::raid() {
  local prompt="${1:-"\e[1;36m$(zen::i18n::translate "prompts.common.choice_prompt")\e[0m"}"
  local -n output_var="${2:-}"
  local choices=("${@:3}")
  local choice
  local choice_num
  echo -e "${prompt}"
  for index in "${!choices[@]}"; do
    echo -e "    \e[96m$((index + 1)))\e[0m RAID${choices[index]}"
  done
  while true; do
    printf "%s : " "$(mflibs::shell::text::white::sl " $(zen::i18n::translate "prompts.common.choice_prompt") ")"
    read -r choice_num </dev/tty
    if [[ "$choice_num" =~ ^[0-9]+$ ]] && ((choice_num >= 1 && choice_num <= ${#choices[@]})); then
      choice="${choices[choice_num - 1]}"
      break
    else
      echo -e "\e[31m$(zen::i18n::translate "prompts.common.invalid_input")\e[0m"
    fi
  done
  # shellcheck disable=SC2034
  output_var="$choice"
}

# @function zen::prompt::input
# @description: Safely prompts the user for input and stores the result in a variable. The prompt message is customizable. We can filter things like email, URL, etc.
#               This function is useful for validating user input and ensuring that the input matches a specific format.
# @example:
#   zen::prompt::input "Enter your email address:" "email" email
# @arg $1: string - Custom prompt message.
# @arg $2: string (optional) - Filter for the input (e.g., 'email', 'url', 'ip', 'ipv4', 'ipv6', 'mac', 'hostname', 'fqdn', 'domain', 'github', 'docs', 'port_range', ).
# @arg $3: string - The variable to store the user's input.
# @stdout: Custom prompt message and user input.
# @exitcode 0: Successful execution, valid input.
# @exitcode 1: Invalid input, continues prompting.
zen::prompt::input() {
  local prompt="${1:-}"
  local filter="${2:-}"
  local output_var_name="${3:-}"
  local code_to_match reply

  if [[ "$filter" == "code" ]]; then
    code_to_match=$(shuf -i 100000-999999 -n 1)
  fi
  if [[ "$filter" == "code" ]]; then
    if (( RANDOM % 2 )); then
      code_to_match=$(shuf -i 100000-999999 -n 1)
    else
      code_to_match=$(tr -dc 'A-Za-z' </dev/urandom | head -c 6)
    fi
  fi

  while true; do
    if [[ "$filter" == "code" ]]; then
      printf "%s %s [%s]: " "$(mflibs::shell::text::cyan::sl " ➜ ")" "$prompt" " $code_to_match "
    else
      printf "%s %s: " "$(mflibs::shell::text::cyan::sl " ➜ ")" "$prompt"
    fi

    if [[ "$filter" == "password" ]]; then
      read -r -s reply </dev/tty
      echo ""
    else
      read -r reply </dev/tty
    fi

    if [[ "$filter" == "code" ]]; then
      if [[ "$reply" == "$code_to_match" ]]; then
        return 0
      else
        mflibs::shell::text::red "$(zen::i18n::translate "prompts.common.invalid_input" "$reply")"
      fi
    elif [[ -n "$filter" ]]; then
      if zen::common::validate "$filter" "$reply"; then
        export "$output_var_name"="$reply"
        return 0
      else
        mflibs::shell::text::red "✗ $(zen::i18n::translate "prompts.common.invalid_input" "$reply")"
      fi
    else
      export "$output_var_name"="$reply"
      return 0
    fi
  done
}

# @function zen::prompt::multi_select
# @description: Presents a list of options to the user and allows them to select multiple items.
# @arg $1: string (optional) - Custom prompt message.
# @arg $2: string - The name of the variable to store the user's selections.
# @arg $3 onwards: array (passed by reference) - Array of options to present as choices.
# @stdout: Custom prompt message followed by a dynamically generated list of options for selection.
# @exitcode 0: Successful execution, valid selection.
# @exitcode 1: Invalid selection or no options provided.
# @example:
#   zen::prompt::multi_select "Select options:" selected_options options[@]
zen::prompt::multi_select() {
  local prompt="${1:-"Select options:"}"
  local -n output_var="${2:-}"
  local choices=("${@:3}")
  local selected=()
  local choice_num

  echo -e "${prompt}"
  for index in "${!choices[@]}"; do
    echo -e "    \e[96m$((index + 1)))\e[0m ${choices[index]}"
  done
  echo -e "Enter the numbers of your choices, separated by spaces (e.g., 1 2 3):"

  while true; do
    printf "%s : " "$(mflibs::shell::text::white::sl " $(zen::i18n::translate "prompts.common.choice_prompt") ")"
    read -r -a choice_nums </dev/tty

    local valid=true
    selected=()
    for choice_num in "${choice_nums[@]}"; do
      if [[ "$choice_num" =~ ^[0-9]+$ ]] && ((choice_num >= 1 && choice_num <= ${#choices[@]})); then
        selected+=("${choices[choice_num - 1]}")
      else
        valid=false
        break
      fi
    done

    if $valid; then
      break
    else
      echo -e "\e[31m$(zen::i18n::translate "prompts.common.invalid_input")\e[0m"
    fi
  done
  export output_var="${selected[*]}"
}
