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

########################################################
## Everything above this point was Ubuntu boilerplate ##
########################################################

# Ignore these commands in history
HISTIGNORE=clear:history:ls
# replace !!, !<text>, !?<text>, !# commands inline before executing
shopt -s histverify

# Allow Ctrl-S to look forwards in history
stty -ixon

##################
# Command Prompt #
##################
declare -A tput_color
declare -A ps_color
declare -A func_color

tput_color[red]=$(tput setaf 1)
tput_color[white]=$(tput setaf 7)
tput_color[blue]=$(tput setaf 4)
tput_color[black]=$(tput setaf 0)
tput_color[green]=$(tput setaf 2)
tput_color[end]=$(tput sgr0)

if [ $(tput colors) -gt 8 ]; then
    tput_color[gray]=$(tput setaf 8)
else
    tput_color[gray]=${tput_color[black]}
fi

for color in "${!tput_color[@]}"; do
    ps_color[$color]="\[${tput_color[$color]}\]"
    func_color[$color]="\001${tput_color[$color]}\002"
done

exit_status() {
    local status=$?

    if [ $status -eq 0 ]; then
        echo "${func_color[green]}:)"
    else
        echo "${func_color[red]}:("
    fi
}

PS1_PRE=""
PS1_PRE="${PS1_PRE}${ps_color[red]}\u"
PS1_PRE="${PS1_PRE}${ps_color[gray]}@"
PS1_PRE="${PS1_PRE}${ps_color[white]}\h"
PS1_PRE="${PS1_PRE}${ps_color[gray]}:"
PS1_PRE="${PS1_PRE}${ps_color[blue]}\w"
PS1_PRE="${PS1_PRE}${ps_color[black]}["
PS1_PRE="${PS1_PRE}\$(exit_status)"
PS1_PRE="${PS1_PRE}${ps_color[black]}]"
PS1_POST=""
PS1_POST="${PS1_POST}${ps_color[gray]}\n\$ "
PS1_POST="${PS1_POST}${ps_color[end]}"

__smart_git_ps1() {
    if git rev-parse &> /dev/null\
        && [ "$(git config status.showUntrackedFiles)" == "no"\
             -a -z "$(git ls-files)" ]; then
        # if we don't care about untracked files and there are no
        # tracked files in this directory, don't show git_ps1
        export PS1="$1$2"
    else
        __git_ps1 "$@"
    fi
}

if command -v git &> /dev/null\
    && [ "$(type -t __git_ps1)" == "function" ]; then
    export PROMPT_COMMAND="__smart_git_ps1 \"$PS1_PRE\" \"$PS1_POST\" \
        \"(%s${ps_color[black]})${ps_color[end]}\""
    export GIT_PS1_SHOWDIRTYSTATE=true
    export GIT_PS1_SHOWUPSTREAM="verbose"
    export GIT_PS1_SHOWCOLORHINTS=true
else
    export PS1="${PS1_PRE}${PS1_POST}"
fi

unset tput_color ps_color ${!PS1_*}

# Functions
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

