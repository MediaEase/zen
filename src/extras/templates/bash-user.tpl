#!/bin/bash
# Set options
EDITOR=nano
USER=$(whoami)
TMPDIR="$HOME/.tmp/"
HOSTNAME=$(hostname -s)
IDUSER=$(id -u)
LS_COLORS='rs=0:di=01;33:ln=00;36:mh=00;pi=40;33:so=00;35:do=00;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;05;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.log=02;34:*.torrent=02;37:*.conf=02;34:*.sh=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.tlz=00;31:*.txz=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.dz=00;31:*.gz=00;31:*.lz=00;31:*.xz=00;31:*.bz2=00;31:*.tbz=00;31:*.tbz2=00;31:*.bz=00;31:*.tz=00;31:*.tcl=00;31:*.deb=00;31:*.rpm=00;31:*.jar=00;31:*.rar=00;31:*.ace=00;31:*.zoo=00;31:*.cpio=00;31:*.7z=00;31:*.rz=00;31:*.jpg=00;35:*.jpeg=00;35:*.gif=00;35:*.bmp=00;35:*.pbm=00;35:*.pgm=00;35:*.ppm=00;35:*.tga=00;35:*.xbm=00;35:*.xpm=00;35:*.tif=00;35:*.tiff=00;35:*.png=00;35:*.svg=00;35:*.svgz=00;35:*.mng=00;35:*.pcx=00;35:*.mov=00;35:*.mpg=00;35:*.mpeg=00;35:*.m2v=00;35:*.mkv=00;35:*.ogm=00;35:*.mp4=00;35:*.m4v=00;35:*.mp4v=00;35:*.vob=00;35:*.qt=00;35:*.nuv=00;35:*.wmv=00;35:*.asf=00;35:*.rm=00;35:*.rmvb=00;35:*.flc=00;35:*.avi=00;35:*.fli=00;35:*.flv=00;35:*.gl=00;35:*.dl=00;35:*.xcf=00;35:*.xwd=00;35:*.yuv=00;35:*.cgm=00;35:*.emf=00;35:*.axv=00;35:*.anx=00;35:*.ogv=00;35:*.ogx=00;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:'
TERM=xterm
TPUT=$(which tput)
BC=$(which bc)

export EDITOR USER TMPDIR HOSTNAME IDUSER LS_COLORS TERM TPUT BC

# Check for necessary utilities
if [ -z "$TPUT" ]; then
    echo "tput is missing, please install it (yum install tput/apt-get install tput)"
fi
if [ -z "$BC" ]; then
    echo "bc is missing, please install it (yum install bc/apt-get install bc)"
fi

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

_red_bold='\e[1;31m'
_green_bold='\e[1;32m'
_blue_bold='\e[1;34m'
_white_bold='\e[1;37m'
_yellow_bold='\e[1;33m'
_red_bg='\e[41m'
_nc='\e[m'
_alert=${_white_bold}${_red_bg}

function disk::usage {
    du -sh "$PWD" 2>/dev/null | awk '{print $1}' | sed 's/,/./' | sed 's/\([0-9.]*\)\([KMGTPEZY]\)/\1 \2b/'
}

function disk::color {
    local used
    used=$(df -P "$PWD" | awk 'NR==2 {sub(/%/,""); print $5}')
    if [ "${used}" -ge 95 ]; then
        echo -ne "${_alert}"
    elif [ "${used}" -ge 90 ]; then
        echo -ne "${_yellow_bold}"
    else
        echo -ne "${_green_bold}"
    fi
}

case $TERM in
rxvt* | screen* | cygwin)
    PS1='\u@ \w\$ '
    ;;
xterm* | linux* | *vt100* | cons25)
    PS1='\['"$(tput setaf 4)"'\]\u \[\033[01;37m\]\w \[\033[01;37m\](\[$(disk::color)\]$(disk::usage)\[\033[01;37m\]) \[\033[00m\]\$ '
    ;;
*)
    PS1='\['"$(tput setaf 4)"'\]\u \[\033[01;37m\]\w \[\033[01;37m\](\[$(disk::color)\]$(disk::usage)\[\033[01;37m\]) \[\033[00m\]\$ '
    ;;
esac

if [ -e /etc/bash_completion ] && ! shopt -oq posix; then
    # shellcheck source=/etc/bash_completion
    # shellcheck disable=SC1091
    source /etc/bash_completion
fi

if [ -e ~/.custom ]; then
    # shellcheck source=/home/thomas/.custom
    # shellcheck disable=SC1091
    source ~/.custom
fi
