#!/usr/bin/env bash

set -e

git config status.showUntrackedFiles no
git submodule update --init --recursive

vim +PluginInstall +qall

# Airline setup
echo "Setting up Airline fonts"
wget -P ~/.local/share/fonts/ https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf -q

if [ -n "$XDG_CONFIG_HOME" ]; then
    fontconfig="$XDG_CONFIG_HOME/fontconfig/conf.d/"
else
    fontconfig="$HOME/.fonts.conf.d/"
fi
wget -P "$fontconfig" https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf -q

fc-cache -f

# YCM setup
echo "Setting up YCM"
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

