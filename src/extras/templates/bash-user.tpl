export EDITOR=nano
USER=$(whoami)
export TMPDIR="$HOME/.tmp/"
HOSTNAME=$(hostname -s)
IDUSER=$(id -u)
export PROMPT_COMMAND='echo -ne "\033]0;${USER}(${IDUSER})@${HOSTNAME}: ${PWD}\007"'
export LS_COLORS='rs=0:di=01;33:ln=00;36:mh=00:pi=40;33:so=00;35:do=00;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;05;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.log=02;34:*.torrent=02;37:*.conf=02;34:*.sh=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.tlz=00;31:*.txz=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.dz=00;31:*.gz=00;31:*.lz=00;31:*.xz=00;31:*.bz2=00;31:*.tbz=00;31:*.tbz2=00;31:*.bz=00;31:*.tz=00;31:*.tcl=00;31:*.deb=00;31:*.rpm=00;31:*.jar=00;31:*.rar=00;31:*.ace=00;31:*.zoo=00;31:*.cpio=00;31:*.7z=00;31:*.rz=00;31:*.jpg=00;35:*.jpeg=00;35:*.gif=00;35:*.bmp=00;35:*.pbm=00;35:*.pgm=00;35:*.ppm=00;35:*.tga=00;35:*.xbm=00;35:*.xpm=00;35:*.tif=00;35:*.tiff=00;35:*.png=00;35:*.svg=00;35:*.svgz=00;35:*.mng=00;35:*.pcx=00;35:*.mov=00;35:*.mpg=00;35:*.mpeg=00;35:*.m2v=00;35:*.mkv=00;35:*.ogm=00;35:*.mp4=00;35:*.m4v=00;35:*.mp4v=00;35:*.vob=00;35:*.qt=00;35:*.nuv=00;35:*.wmv=00;35:*.asf=00;35:*.rm=00;35:*.rmvb=00;35:*.flc=00;35:*.avi=00;35:*.fli=00;35:*.flv=00;35:*.gl=00;35:*.dl=00;35:*.xcf=00;35:*.xwd=00;35:*.yuv=00;35:*.cgm=00;35:*.emf=00;35:*.axv=00;35:*.anx=00;35:*.ogv=00;35:*.ogx=00;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:'
export TERM=xterm
export TPUT=$(which tput)
export BC=$(which bc)

# Check for necessary utilities
if [ -z "$TPUT" ]; then
    echo "tput is missing, please install it (yum install tput/apt-get install tput)"
fi
if [ -z "$BC" ]; then
    echo "bc is missing, please install it (yum install bc/apt-get install bc)"
fi

COLDBLUE="\e[0;38;5;33m"
SCOLDBLUE="\[\e[0;38;5;33m\]"

dirsize="$HOME/bin/dirsize"
chmod u+x "$dirsize"

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

set::prompt() {
    local DG LG NC DS
    if [ "$(id -u)" -eq 0 ]; then
        DG="$(tput bold; tput setaf 1)"
        LG="$(tput bold; tput setaf 4)"
        NC="$(tput sgr0)"
    else
        DG="$(tput bold; tput setaf 0)"
        LG="$(tput setaf 4)"
        DS="$(tput setaf 2)"
        NC="$(tput sgr0)"
    fi
    PS1='[\[$LG\]\u\[$NC\]@\[$LG\]\h\[$NC\]]:(\[$LG\]\[$BN\]$($dirsize)\[$NC\])\w\$ '
}

case $TERM in
    rxvt*|screen*|cygwin)
        PS1='\u@\h\w'
        ;;
    xterm*|linux*|*vt100*|cons25)
        set::prompt
        ;;
    *)
        set::prompt
        ;;
esac

if [ -e /etc/bash_completion ] && ! shopt -oq posix; then
    source /etc/bash_completion
fi

if [ -e ~/.custom ]; then
    source ~/.custom
fi

# PYENV
export PYENV_ROOT="$HOME/.config/pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# PYENV
