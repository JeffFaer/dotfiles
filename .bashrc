# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

HISTIGNORE=clear:history:ls
# replace !!, !<text>, !?<text>, !# commands inline before executing
shopt -s histverify

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
    export TERM=xterm-256color
fi

stty -ixon

# setup a pretty command prompt
TPUT_RED=$(tput setaf 1)
TPUT_WHITE=$(tput setaf 7)
TPUT_BLUE=$(tput setaf 4)
TPUT_BLACK=$(tput setaf 0)
TPUT_GREEN=$(tput setaf 2)
TPUT_END=$(tput sgr0)

if [ $(tput colors) -gt 8 ]; then
    TPUT_GRAY=$(tput setaf 8)
else
    TPUT_GRAY=$TPUT_BLACK
fi

for tput in ${!TPUT_*}; do
    color=${tput#TPUT_}
    declare PS_${color}="\[${!tput}\]"
    declare F_${color}="\001${!tput}\002"
done

exit_status() {
    local status=$?

    if [ $status -eq 0 ]; then
        echo "${F_GREEN}:)"
    else
        echo "${F_RED}:("
    fi
}

PS1_PRE=""
PS1_PRE="${PS1_PRE}${PS_RED}\u"
PS1_PRE="${PS1_PRE}${PS_GRAY}@"
PS1_PRE="${PS1_PRE}${PS_WHITE}\h"
PS1_PRE="${PS1_PRE}${PS_GRAY}:"
PS1_PRE="${PS1_PRE}${PS_BLUE}\w"
PS1_PRE="${PS1_PRE}${PS_BLACK}["
PS1_PRE="${PS1_PRE}\$(exit_status)"
PS1_PRE="${PS1_PRE}${PS_BLACK}]"
PS1_POST=""
PS1_POST="${PS1_POST}${PS_GRAY}\n\$ "
PS1_POST="${PS1_POST}${PS_END}"

if [ "$(type -t __git_ps1)" == "function" ]; then
    export PROMPT_COMMAND="__git_ps1 \"$PS1_PRE\" \"$PS1_POST\" \
        \"(%s${PS_BLACK})\""
    export GIT_PS1_SHOWDIRTYSTATE=true
    export GIT_PS1_SHOWUPSTREAM="verbose"
    export GIT_PS1_SHOWCOLORHINTS=true
else
    export PS1="${PS1_PRE}${PS1_POST}"
fi

unset ${!TPUT_*} ${!PS_*} ${!PS1_*}

