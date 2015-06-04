#!/usr/bin/env bash

set -e

git config status.showUntrackedFiles no
git submodule update --init --recursive

vim +PluginInstall +qall

install=""
for package in "build-essential" "cmake" "python-dev"; do
    dpkg -s "$package" &> /dev/null || install="$install $package"
done

if [ -n "$install" ]; then
    sudo apt-get install $install -y
fi

cd ~/.vim/bundle/YouCompleteMe
./install.sh --clang-completer

