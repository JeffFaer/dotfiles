#!/usr/bin/env bash

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=-1  # Number of lines in the bash session's in-memory history.
export HISTFILESIZE=100000  # Number of lines in the history file.

# Ignore these commands in history.
HISTIGNORE=clear:history:ls
export HISTTIMEFORMAT="[%F %T %z] "
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.personal_bash_history

# Replace !!, !<text>, !?<text>, !# commands inline before executing.
shopt -s histverify

# Flush bash history before every command.
bashrc::flush_history() {
    history -a
}
# This should be one of the last preexecs so that other preexecs (like tvs) can
# add stuff to history before we flush.
preexec_functions+=("bashrc::flush_history")
