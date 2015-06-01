#/usr/bin/env bash

git config status.showUntrackedFiles no
git submodule update --init --recursive

vim +PluginInstall +qall

cd ~/.vim/bundle/YouCompleteMe
./install.sh --clang-completer

