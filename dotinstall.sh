#!/usr/bin/env bash

set -e

git config status.showUntrackedFiles no
git submodule update --init --recursive

vim +PluginInstall +qall

install=""
for package in "build-essential" "cmake" "python-dev"; do
    dpkg -s "$package" 2>&1 | grep -P '^Status.+(?<!-)installed' &> /dev/null ||
        install="$install $package"
done

if [ -n "$install" ]; then
    echo "Installing$install"
    sudo apt-get update -qq
    sudo apt-get install $install -yqq
fi

cd ~/.vim/bundle/YouCompleteMe
./install.sh --clang-completer

