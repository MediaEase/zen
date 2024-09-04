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
# @caution Ensure that the code or string provided is kept secure and not easily guessable.
# @important This function is useful for securing sensitive operations by requiring user verification.
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
    read -r reply </dev/tty
    if [[ "$reply" == "$string" ]]; then
      return 0
    else
      mflibs::shell::text::red "$(zen::i18n::translate "prompts.common.invalid_input" "$reply")"
    fi
  done
}

# @function zen::prompt::password
# @description: Prompts the user to input a password. The input is hidden from the terminal.
# @example:
#   zen::prompt::password "Enter your password:" "password"
# @arg $1: string - Custom prompt message.
# @arg $2: string - The password the user must input.
# @stdout: Custom prompt message and hidden password input.
# @exitcode 0: Correct password entered.
# @exitcode 1: Incorrect input, continues prompting.
# @caution Ensure that the password provided is kept secure and not easily guessable.
# @important This function is useful for securing sensitive operations by requiring user verification.
zen::prompt::password() {
  local prompt="${1:-}"
  local password="${2:-}"

  while true; do
    printf "%s %s" "$(mflibs::shell::text::cyan::sl " ➜ ")" "$prompt"
    zen::vault::pass::decode "$password"
    mflibs::shell::text::cyan " ➜ "
    read -r reply </dev/tty
    if [[ "$reply" == "$password" ]]; then
      return 0
    else
      mflibs::shell::text::red "$(zen::i18n::translate "prompts.common.invalid_input" "$reply")"
    fi
  done
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
  local reply

  while true; do
    printf "%s %s" "$(mflibs::shell::text::cyan::sl " ➜ ")" "$prompt"
    if [[ "$filter" == "password" ]]; then
      read -r -s reply </dev/tty
      echo ""
    else
      read -r reply </dev/tty
    fi

    if [[ -n "$filter" ]]; then
      if zen::validate::input "$filter" "$reply"; then
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

# @function zen::validate::input
# @description: Validates user input based on a specific filter.
# @arg $1: string - Filter for the input (e.g., 'email', 'url', 'ip', 'ipv4', 'ipv6', 'mac', 'hostname', 'fqdn', 'domain', 'numeric', 'group').
# @arg $2: string - The user's input to validate.
# @exitcode 0: Successful execution, valid input.
# @exitcode 1: Invalid input.
# @example
#   zen::validate::input "email" "contact@me.com" # returns 0
# @example
#   zen::validate::input "email" "contact@me" # returns 1
# @example
#   zen::validate::input "url" "https://example.com" # returns 0
# @example
#   zen::validate::input "url" "example.com" # returns 1
# @example
#   zen::validate::input "ip" "192.168.1.1" # returns 0
# @example
#   zen::validate::input "ip" "256.256.256.256" # returns 1
# @example
#   zen::validate::input "ipv4" "192.168.1.1" # returns 0
# @example
#   zen::validate::input "ipv4" "256.256.256.256" # returns 1
# @example
#   zen::validate::input "ipv6" "2001:0db8:85a3:0000:0000:8a2e:0370:7334" # returns 0
# @example
#   zen::validate::input "ipv6" "2001:0db8:85a3::8a2e:0370:7334" # returns 1
# @example
#   zen::validate::input "mac" "00:1A:2B:3C:4D:5E" # returns 0
# @example
#   zen::validate::input "mac" "00:1A:2B:3C:4D:5E:6F" # returns 1
# @example
#   zen::validate::input "hostname" "example-hostname" # returns 0
# @example
#   zen::validate::input "hostname" "example_hostname" # returns 1
# @example
#   zen::validate::input "fqdn" "example.com" # returns 0
# @example
#   zen::validate::input "fqdn" "example..com" # returns 1
# @example
#   zen::validate::input "domain" "example.com" # returns 0
# @example
#   zen::validate::input "domain" "example" # returns 1
# @example
#   zen::validate::input "group" "media" # returns 0
# @example
#   zen::validate::input "group" "unsupported_group" # returns 1
# @example
#   zen::validate::input "github" "https://github.com/MediaEase/shdoc" # returns 0
# @example
#   zen::validate::input "github" "MediaEase/shdoc" # returns 0
# @example
#   zen::validate::input "docs" "https://example.com/docs" # returns 0
# @example
#   zen::validate::input "docs" "https://example.com/documentation" # returns 1
# @example
#   zen::validate::input "port_range" "8000-9000" # returns 0
# @example
#   zen::validate::input "port_range" "8000:9000" # returns 1
# @example
#   zen::validate::input "numeric" "12345" # returns 0
# @example
#   zen::validate::input "numeric" "12345a" # returns 1
# @example
#   zen::validate::input "password" "password1234" # returns 0
zen::validate::input() {
  local filter="$1"
  local input="$2"
  case "$filter" in
  email)
    [[ "$input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && return 0
    ;;
  url)
    [[ "$input" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} ]] && return 0
    ;;
  ip)
    [[ "$input" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && return 0
    ;;
  ipv4)
    [[ "$input" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && return 0
    ;;
  ipv6)
    [[ "$input" =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$ ]] && return 0
    ;;
  mac)
    [[ "$input" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] && return 0
    ;;
  hostname)
    [[ "$input" =~ ^[a-zA-Z0-9._@-]+$ ]] && return 0
    ;;
  fqdn)
    [[ "$input" =~ ^([a-zA-Z0-9.-]+\.)+[a-zA-Z]{2,}$ ]] && return 0
    ;;
  domain)
    [[ "$input" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && return 0
    ;;
  group)
    [[ "$input" =~ ^(full|automation|media|remote|download)$ ]] && return 0
    ;;
  github)
    [[ "$input" =~ ^(https://(github|gitlab)\.com/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+|[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+)$ ]] && return 0
    ;;
  docs)
    [[ "$input" =~ ^https://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/docs ]] && return 0
    ;;
  port_range)
    [[ "$input" =~ ^[0-9]+-[0-9]+$ ]] && return 0
    ;;
  numeric)
    [[ "$input" =~ ^[0-9]+$ ]] && return 0
    ;;
  password | username)
    [[ ! $input =~ ['!@#$%^&*()_+=<>?[]|`"'] ]] && return 0
    if [[ "$filter" == "username" && ${#input} -ge 3 ]]; then
      return 0
    elif [[ "$filter" == "password" && ${#input} -ge 6 ]]; then
      return 0
    fi
    ;;
  *)
    return 1
    ;;
  esac
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
