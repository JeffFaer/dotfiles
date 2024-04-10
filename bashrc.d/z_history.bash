#!/usr/bin/env bash

# Flush and reload bash history before every command.
bashrc::flush_history() {
    history -a
}
# This should be one of the last preexecs so that other preexecs (like tvs) can
# add stuff to history before we flush.
preexec_functions+=("bashrc::flush_history")
