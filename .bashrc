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

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

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

# ** globs directories
shopt -s globstar

# vi mode for Bash/Readline
set -o vi

if [[ -d "${HOME}/bashrc.d/" ]]; then
  for f in "${HOME}/bashrc.d/"*; do
    if [[ -f "${f}" ]]; then
      # shellcheck disable=SC1090
      source "${f}"
    fi
  done
  unset f
fi
