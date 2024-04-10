# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# A list of variables and functions that should be unset at the end of bashrc.
__bashrc_cleanup=()

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
export HISTSIZE=-1  # Number of lines in the bash session's in-memory history.
export HISTFILESIZE=100000  # Number of lines in the history file.

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi

########################################################
## Everything above this point was Ubuntu boilerplate ##
########################################################


# Ignore these commands in history.
HISTIGNORE=clear:history:ls
export HISTTIMEFORMAT="[%F %T %z] "
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.personal_bash_history

# Replace !!, !<text>, !?<text>, !# commands inline before executing.
shopt -s histverify

# ** globs directories
shopt -s globstar

# vi mode for Bash/Readline
set -o vi

# Allow Ctrl-S to look forward in history
stty -ixon

if [[ -d "${HOME}/bashrc.d/" ]]; then
  for f in "${HOME}/bashrc.d/"*; do
    if [[ -f "${f}" ]]; then
      # shellcheck disable=SC1090
      source "${f}"
    fi
  done
  unset f
fi
