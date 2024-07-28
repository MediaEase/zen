#!/bin/bash
# Set options
ulimit -S -c 0
set -o notify
set -o ignoreeof
shopt -s cdspell cdable_vars checkhash checkwinsize sourcepath no_empty_cmd_completion cmdhist histappend histreedit histverify extglob
shopt -u mailwarn
unset MAILCHECK
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export TERM=xterm
export EDITOR=nano

# Automatic setting of $DISPLAY
function get::xserver {
    case $TERM in
    xterm)
        XSERVER=$(who am i | awk '{print $NF}' | tr -d ')''(')
        XSERVER=${XSERVER%%:*}
        ;;
    esac
}

if [ -z "${DISPLAY:=""}" ]; then
    get::xserver
    if [[ -z ${XSERVER} || ${XSERVER} == $(hostname) || ${XSERVER} == "unix" ]]; then
        DISPLAY=":0.0" # Display on local host
    else
        DISPLAY=${XSERVER}:0.0 # Display on remote host
    fi
fi
export DISPLAY
# shellcheck source=/dev/null
[[ -f /etc/bashrc ]] && . "/etc/bashrc"

# colors
_red_bold='\e[1;31m'
_green_bold='\e[1;32m'
_blue_bold='\e[1;34m'
_white_bold='\e[1;37m'
_yellow_bold='\e[1;33m'
_red_bg='\e[41m'
_nc='\e[m'
_alert=${_white_bold}${_red_bg}

# Function to determine user color
function user_color {
    if [[ "${USER}" == "root" ]]; then
        echo -en "${_red_bold}"
    else
        echo -en "${_green_bold}"
    fi
}

# Function to strip color codes for length calculation
function strip_color_codes {
    local input="$1"
    echo -e "$input" | sed -r 's/\x1B\[[0-9;]*[mK]//g'
}

# Display login message
login_message="You are logged in as: $(user_color)${USER}friofoirfoer${_nc}"
login_message_length=$(strip_color_codes "$login_message" | wc -c)
padding_length=$((66 - login_message_length - 2))
padding=$(printf "%*s" "$padding_length" "")

echo -e "\n${_blue_bold}+----------------------- MediaEase Server -----------------------+${_nc}"
echo -e "${_blue_bold}|${_nc} ${login_message}${padding// / }${_blue_bold}|${_nc}"
echo -e "${_blue_bold}+----------------------------------------------------------------+${_nc}"
echo -e "${_blue_bold}|${_nc} Prompt Style Options:                                          ${_blue_bold}|${_nc}"
echo -e "${_blue_bold}|${_nc}  - ${_green_bold}custom_on${_nc}: Color-coded Disk usage (default)                 ${_blue_bold}|${_nc}"
echo -e "${_blue_bold}|${_nc}  - ${_green_bold}custom_off${_nc}: Revert to the default prompt                    ${_blue_bold}|${_nc}"
echo -e "${_blue_bold}+----------------------------------------------------------------+${_nc}\n"

# Function to display exit message
function on::exit {
    echo -e "${_blue_bold}Thank you for using MediaEase. Have a great day!${_nc}"
}
trap on::exit EXIT

function disk::usage {
    df -BM "$PWD" | awk 'NR==2 {print $4}'
}

function disk::color {
    local used
    used=$(df -P "$PWD" | awk 'NR==2 {sub(/%/,""); print $5}')
    if [ "${used}" -ge 95 ]; then
        echo -en "${_alert}"
    elif [ "${used}" -ge 90 ]; then
        echo -en "${_yellow_bold}"
    else
        echo -en "${_green_bold}"
    fi
}

function custom_on {
    PROMPT_COMMAND="history -a"
    case ${TERM} in
    *term | rxvt | linux)
        PS1="\[\033[01;37m\][\A] \[\$(user_color)\]\u\[\033[01;37m\]@\[\033[01;34m\]\h \[\033[01;37m\][Free: \[\$(disk::color)\]\$(disk::usage)\[\033[01;37m\]] \[\033[00m\]\$ "
        ;;
    *)
        PS1="[\u@\h \A][\w] "
        ;;
    esac
}

function custom_off {
    PROMPT_COMMAND="history -a"
    debian_chroot="${debian_chroot:+($debian_chroot)}"
    PS1="${debian_chroot}\h:\w\$ "
    export LS_OPTIONS='--color=auto'
    eval "$(dircolors)"
}

transfer() {
    if [ $# -eq 0 ]; then
        printf "No arguments specified.\nUsage:\n  transfer <file|directory>\n  ... | transfer <file_name>" >&2
        return 1
    fi

    if tty -s; then
        file="$1"
        file_name=$(basename "$file")

        if [ ! -e "$file" ]; then
            printf "%s: No such file or directory" "$file" >&2
            return 1
        fi

        if [ -d "$file" ]; then
            file_name="$file_name.zip"
            (cd "$file" && zip -r -q - .) | curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name" | tee /dev/null
        else
            curl --progress-bar --upload-file "$file" "https://transfer.sh/$file_name" | tee /dev/null
        fi
    else
        file_name=$1
        curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name" | tee /dev/null
    fi
}

custom_on
custom_off

custom_on
export custom_on

# Aliases and completions
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Load bash completions if available
if [[ -f "/usr/share/bash-completion.d/zen" ]]; then
    # shellcheck source=/dev/null
    . "/usr/share/bash-completion.d/zen"
fi

# History settings
PROMPT_COMMAND="history -n; history -a"
unset HISTFILESIZE
HISTSIZE=2000
HISTFILESIZE=4000
HISTCONTROL=ignoreboth
HISTIGNORE='ls:bg:fg:history'
HISTTIMEFORMAT='%F %T '
export HISTTIMEFORMAT
export HISTCONTROL HISTIGNORE HISTSIZE HISTFILESIZE
# used for setting locale see /etc/default/locale in debian
# shellcheck disable=SC1091
[[ -r "/etc/default/locale" ]] && . "/etc/default/locale" && export LC_ALL
eval "$(pyenv virtualenv-init -)"
