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
        xterm )
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
_black_bold='\e[1;30m'
_red_bold='\e[1;31m'
_green_bold='\e[1;32m'
_blue_bold='\e[1;34m'
_white_bold='\e[1;37m'
_red_bg='\e[41m'
_nc='\e[m'
_alert=${_white_bold}${_red_bg}
date=$(date)

echo ""
echo -e "${_blue_bold}|========================================================================|${_nc}"
echo -e "${_blue_bold}|------------------------------------------------------------------------|${_nc}"
echo -e "${_blue_bold}|  ###################  Welcome to MediaEase Server  ################### |${_nc}"
echo -e "${_blue_bold}|------------------------------------------------------------------------|${_nc}"
echo -e "${_blue_bold}|${_white_bold}       You are logged in as ${_red_bold}root${_nc}${_blue_bold}                                        |${_nc}"
echo -e "${_blue_bold}|${_white_bold}       Current date and time: ${_green_bold}${date}${_nc}${_blue_bold}           |${_nc}"
echo -e "${_blue_bold}|========================================================================|${_nc}"
echo -e "${_blue_bold}|========================================================================|${_nc}"
echo -e "${_blue_bold}|------------------------------------------------------------------------|${_nc}"
echo -e "${_blue_bold}|  Select a command prompt style by typing one of the following commands |${_nc}"
echo -e "${_blue_bold}|------------------------------------------------------------------------|${_nc}"
echo -e "${_blue_bold}|  ${_green_bold}command_on${_nc}${_blue_bold}                                                            |${_nc}"
echo -e "${_blue_bold}|  This prompt shows the last command used & more                        |${_nc}"
echo -e "${_blue_bold}|  ${_green_bold}power_on${_nc} (default)${_blue_bold}                                                    |${_nc}"
echo -e "${_blue_bold}|  This prompt shows colorful system data - CPU, load, etc.              |${_nc}"
echo -e "${_blue_bold}|  ${_green_bold}basic_on${_nc}${_blue_bold}                                                              |${_nc}"
echo -e "${_blue_bold}|  This prompt shows color-coded load & CPU average                      |${_nc}"
echo -e "${_blue_bold}|  ${_green_bold}custom_off${_nc}${_blue_bold}                                                            |${_nc}"
echo -e "${_blue_bold}|  This turns off custom prompts and reverts to the default              |${_nc}"
echo -e "${_blue_bold}|========================================================================|${_nc}"
echo ""

# Function to display exit message
function on::exit {
    echo -e "${_blue_bold}Thank you for using MediaEase. Have a great day!${_nc}"
}
trap on::exit EXIT

NCPU=$(grep -c 'processor' /proc/cpuinfo)
SLOAD=$(( 100 * NCPU ))
MLOAD=$(( 200 * NCPU ))
XLOAD=$(( 400 * NCPU ))

function load {
    local SYSLOAD
    SYSLOAD=$(cut -d " " -f1 /proc/loadavg | tr -d '.')
    echo $((10#$SYSLOAD))
}

function load_color {
    local SYSLOAD
    SYSLOAD=$(load)
    if [ "${SYSLOAD}" -gt "${XLOAD}" ]; then
        echo -en "${_alert}"
    elif [ "${SYSLOAD}" -gt "${MLOAD}" ]; then
        echo -en "${_alert}"
    elif [ "${SYSLOAD}" -gt "${SLOAD}" ]; then
        echo -en "${_green_bold}"
    else
        echo -en "${_blue_bold}"
    fi
}

function disk_color {
    if [ ! -w "${PWD}" ]; then
        echo -en "${_alert}"
    elif [ -s "${PWD}" ]; then
        local used
        used=$(command df -P "$PWD" | awk 'END {print $5} {sub(/%/,"")}')
        if [ "${used}" -gt 95 ]; then
            echo -en "${_alert}"
        elif [ "${used}" -gt 90 ]; then
            echo -en "${_green_bold}"
        else
            echo -en "${_blue_bold}"
        fi
    else
        echo -en "${_nc}"
    fi
}

function job_color {
    if [ "$(jobs -s | wc -l)" -gt "0" ]; then
        echo -en "${_green_bold}"
    elif [ "$(jobs -r | wc -l)" -gt "0" ]; then
        echo -en "${_blue_bold}"
    fi
}

function command_on {
    export PROMPT_COMMAND='export H1="$(history 1 | sed -e "s/^[\ 0-9]*//; s/[\d0\d31\d34\d39\d96\d127]*//g; s/\(.\{1,50\}\).*$/\1/g")"; history -a; echo -e "sgr0\ncnorm\nrmso" | tput -S'
    PS1='\n\[\e[1;30m\][\j:\!\[\e[1;30m\]]\[\e[0;36m\] \T \d \[\e[1;30m\][\[\e[1;34m\]\u@\H\[\e[1;30m\]:\[\e[0;37m\]`tty 2>/dev/null` \[\e[0;32m\]+${SHLVL}\[\e[1;30m\]] \[\e[1;37m\]\w\[\e[0;37m\]\[\033]0;[ ${H1}... ] \w - \u@\H +$SHLVL @`tty 2>/dev/null` - [ `uptime` ]\007\]\n\[\]\$ '
}

function power_on {
    export AA_P="export PVE=\"\\033[m\\033[38;5;2m\"\$(( \`sed -n \"s/MemFree:[\\t ]\\+\\([0-9]\\+\\) kB/\\1/p\" /proc/meminfo\` / 1024 ))\"\\033[38;5;22m/\"\$((\`sed -n \"s/MemTotal:[\\t ]\\+\\([0-9]\\+\\) kB/\\1/p\" /proc/meminfo\`/ 1024 ))MB\"\\t\\033[m\\033[38;5;55m\$(< /proc/loadavg)\\033[m\";echo -en \"\""
    export PROMPT_COMMAND="history -a;((\$SECONDS % 10==0 ))&&eval \"\$AA_P\";echo -en \"\$PVE\";"
    PS1="\\[\\e[m\\n\\e[1;30m\\][\$\$:\$PPID \\j:\\!\\[\\e[1;30m\\]]\\[\\e[0;36m\\] \\T \\d \\[\\e[1;30m\\][\\[\\e[1;34m\\]\\u@\\H\\[\\e[1;30m\\]\\[\\e[1;30m\\]] \\[\\e[1;37m\\]\\w\\[\\e[0;37m\\] \\n(\$SHLVL:\\!)\\\$ "
    export PVE="\\033[m\\033[38;5;2m813\\033[38;5;22m/1024MB\\t\\033[m\\033[38;5;55m0.25 0.22 0.18 1/66 26820\\033[m" && eval "$AA_P"
}

function basic_on() {
PROMPT_COMMAND="history -a"
case ${TERM} in
    *term | rxvt | linux)
        PS1="\[\$(load_color)\][\A\[${_nc}\] \[\$(load_color)\][\A\[${_nc}\] \[${SU}\]\u\[${_nc}\]@\[${CNX}\]\h\[${_nc}\] \[\$(disk_color)\]\W]\[${_nc}\] \[\$(job_color)\]>\[${_nc}\] \[\e]0;[\u@\h] \w\a\]"
        ;;
    *)
        PS1="(\A \u@\h \W) > "
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

transfer(){
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
