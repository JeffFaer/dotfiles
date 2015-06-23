#!/usr/bin/env bash

set -e

git config status.showUntrackedFiles no
git submodule update --init --recursive

vim +PluginInstall +qall

# Airline setup
echo "Setting up Airline fonts"
base_url=https://github.com/Lokaltog/powerline/raw/develop/font

font_url=${base_url}/PowerlineSymbols.otf
font_dir=$HOME/.local/share/fonts/

font_conf_url=${base_url}/10-powerline-symbols.conf
if [ -n "$XDG_CONFIG_HOME" ]; then
    font_conf_dir="$XDG_CONFIG_HOME/fontconfing/conf.d/"
else
    font_conf_dir="$HOME/.fonts.conf.d/"
fi

wget -P "$font_dir" "$font_url" -q
wget -P "$font_conf_dir" "$font_conf_url" -q
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

