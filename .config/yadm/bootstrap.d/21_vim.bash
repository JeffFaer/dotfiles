#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

source "$(dirname "${BASH_SOURCE[0]}")/bootstrap_lib.bash"

if ! command -v vim &>/dev/null; then
    echo "Vim not found"
    exit
fi

echo "Installing Vundle plugins"
vim +PluginInstall +qall

echo "Installing supporting software"
bootstrap::install_packages shellcheck || true

if bootstrap::should_run "airline"; then
    echo "Setting up Airline"
    if bootstrap::install_packages fonts-powerline; then
        fc-cache -f
    else
        echo "Cannot setup Airline until those packages are installed."
    fi
fi

if bootstrap::should_run "ycm"; then
    echo "Setting up YCM"
    if bootstrap::install_packages build-essential cmake python3-dev; then
        cd ~/.vim/bundle/YouCompleteMe
        python3 install.py --all
    else
        echo "Cannot setup YCM until those packages are installed."
    fi
fi
