#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

if ! command -v gnome-terminal &>/dev/null; then
    echo "gnome-terminal not installed, not setting it up."
    exit
fi
if [[ -z "${DISPLAY:-}" ]]; then
    echo "No DISPLAY, not setting up gnome-terminal."
    exit
fi
if ! command -v gconftool &> /dev/null; then
    echo "No gconftool, not setting up gnome-terminal."
    exit
fi

echo "Setting up gnome-terminal"
default="$(gsettings get org.gnome.Terminal.ProfilesList default)"
if [[ "${default}" =~ \'?([-0-9a-f]+)\'? ]]; then
    default="${BASH_REMATCH[1]}"
fi
schema="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${default}/"
gsettings set "${schema}" use-custom-command true
gsettings set "${schema}" custom-command "env TERM=xterm-256color bash"
