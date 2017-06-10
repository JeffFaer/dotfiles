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
shopt -s globstar

# vi mode for Bash/Readline
set -o vi

# Allow Ctrl-S to look forward in history
stty -ixon

# Functions
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Bash settings local to a machine
if [ -f ~/.bash_local ]; then
    . ~/.bash_local
fi

##################
# Command Prompt #
##################
declare -A color
declare -A tput_color

tput_color[red]=$(tput setaf 1)
tput_color[white]=$(tput setaf 7)
tput_color[blue]=$(tput setaf 4)
tput_color[black]=$(tput setaf 0)
tput_color[green]=$(tput setaf 2)
tput_color[yellow]=$(tput setaf 3)
tput_color[magenta]=$(tput setaf 5)
tput_color[end]=$(tput sgr0)

num_colors=$(tput colors)
load_color() {
    if [ $num_colors -gt $1 ]; then
        tput setaf $1
    else
        echo "${tput_color[$2]}"
    fi
}

tput_color[gray]=$(load_color 8 black)
tput_color[bright_green]=$(load_color 10 green)
tput_color[deep_blue]=$(load_color 20 blue)
tput_color[purple]=$(load_color 135 magenta)
tput_color[brown]=$(load_color 94 yellow)
tput_color[deep_green]=$(load_color 28 green)

# Set up colors for PS1 string literals.
for c in "${!tput_color[@]}"; do
    color[$c]="\[${tput_color[$c]}\]"
done

exit_status() {
    local status=$?

    if [ $status -eq 0 ]; then
        echo "${color[green]}☺ "
    else
        echo "${color[red]}☹ "
    fi
}

PS1_PRE=""
PS1_PRE+="${color[red]}\u"
PS1_PRE+="${color[gray]}@"
PS1_PRE+="${color[${hostname_color:-white}]}\H"
PS1_PRE+="${color[gray]}:"
PS1_PRE+="${color[blue]}\w"
PS1_PRE+="${color[gray]}["
PS1_PRE+="\$(exit_status)"
PS1_PRE+="${color[gray]}]"
PS1_POST=""
PS1_POST+="${color[gray]}\n\$"
PS1_POST+="${color[end]} "

__smart_git_ps1() {
    if git rev-parse &> /dev/null\
        && [ "$(git config status.showUntrackedFiles)" == "no" ]\
        && [ -z "$(git ls-files)" ]; then
        # if we don't care about untracked files and there are no
        # tracked files in this directory, don't show git_ps1
        export PS1="$1$2"
    else
        __git_ps1 "$@"
    fi
}

if command -v git &> /dev/null\
    && [ "$(type -t __git_ps1)" == "function" ]; then
    prompt="__smart_git_ps1"
    prompt+=" \"$PS1_PRE\""
    prompt+=" \"$PS1_POST\""
    prompt+=" \"(%s${color[gray]})${color[end]}\""
    export PROMPT_COMMAND=$prompt

    export GIT_PS1_SHOWDIRTYSTATE=true
    export GIT_PS1_SHOWUPSTREAM="verbose"
    export GIT_PS1_SHOWCOLORHINTS=true
    export GIT_PS1_SHOWSTASHSTATE=true
else
    export PS1="${PS1_PRE}${PS1_POST}"
fi

# Set up colors for PS1 functions calls.
for c in "${!tput_color[@]}"; do
    color[$c]="\001${tput_color[$c]}\002"
done

unset num_colors tput_color ${!PS1_*}
