#!/usr/bin/env bash

set -e

allowed_args=(all airline ycm none)
join() {
    local IFS="$1"
    shift 1
    echo "$*"
}
usage() {
    echo "$0 [-h|--help] [$(join ',' "${allowed_args[@]}")]"
    echo "-h|--help      displays this message"
    echo "all            sets up all plugins (default)"
    echo "airline        sets up the vim-airline plugin"
    echo "ycm            sets up the YouCompleteMe plugin"
    echo "none           install, but do not set up plugins"
    exit 1
}
ARGS=$(getopt -o 'h' --long 'help' -n "$(basename $0)" -- "$@")
eval set -- "$ARGS"

while true; do
    case "$1" in
        --)
            shift 1;
            break
            ;;
        *)
            shift 1;
            usage
            ;;
    esac
done

# Checks to see if $1 matches one of the other arguments
contained_in() {
    for e in "${@:2}"; do
        [ "$e" == "$1" ] && return 0
    done

    return 1
}
for arg in "$@"; do
    if ! contained_in "$arg" "${allowed_args[@]}"; then
        echo "Unknown arg: $arg"
        exit 1
    fi
done

if [ "$#" -eq "0" ] || contained_in "all" "$@"; then
    setup_airline=1
    setup_ycm=1
fi
if contained_in "airline" "$@"; then
    setup_airline=1
fi
if contained_in "ycm" "$@"; then
    setup_ycm=1
fi

git_dir=$(dirname $0)
git_dir=$(readlink -f $git_dir)
target=$HOME

if [ ! "$git_dir" -ef "$target" ]; then
    if [ -d "$target/.git" ]; then
        echo "There's already a git repo at $target"
        echo "Remove it and try again!"
        exit 1
    fi

    conflicts=
    for ls_file in $(git --git-dir="$git_dir/.git" ls-files); do
        tracked_file="$git_dir/$ls_file"
        target_file="$target/$ls_file"
        if [ -d "$tracked_file" -a -d "$target_file" ]; then
            # submodule
            echo "$target_file already exists as a directory"
            read -p "Would you like to remove it now?[yN]" -n 1
            echo

            if [[ "$REPLY" =~ ^[yY]$ ]]; then
                rm -rf "$target_file"
            else
                echo "You must remove it before continuing"
                exit 1
            fi
        elif [ -f "$target_file" ]; then
            # save conflicts for later.
            conflicts="$conflicts $ls_file"
        elif [ -e "$tracked_file" ]; then
            mkdir -p $(dirname "$target_file")
            mv "$tracked_file" "$target_file"
        fi
        # else we've already moved it
    done

    mergetool=$(git config merge.tool || echo 'vimdiff')
    for conflict in $conflicts; do
        target_file="$target/$conflict"
        tracked_file="$git_dir/$conflict"
        cmp --silent "$target_file" "$tracked_file"\
            || ${mergetool} "$target_file" "$tracked_file"
    done

    mv "$git_dir/.git/" "$target"
    cd "$target"

    rm -rf "$git_dir"
fi

git config status.showUntrackedFiles no
git submodule update --init --recursive

vim +PluginInstall +qall

# Airline setup
if [ -n "$setup_airline" ]; then
    echo "Setting up Airline"
    echo "Setting up fonts"
    base_url="https://github.com/Lokaltog/powerline/raw/develop/font"

    font_url="${base_url}/PowerlineSymbols.otf"
    font_dir="$target/.local/share/fonts/"

    font_conf_url=${base_url}/10-powerline-symbols.conf
    if [ -n "$XDG_CONFIG_HOME" ]; then
        font_conf_dir="$XDG_CONFIG_HOME/fontconfing/conf.d/"
    else
        font_conf_dir="$target/.fonts.conf.d/"
    fi

    wget -P "$font_dir" "$font_url" -q
    wget -P "$font_conf_dir" "$font_conf_url" -q
    fc-cache -f
fi

# YCM setup
if [ -n "$setup_ycm" ]; then
    echo "Setting up YCM"
    install=""
    for package in "build-essential" "cmake" "python-dev"; do
        dpkg -s "$package" 2>&1 |\
            grep -P '^Status.+(?<!-)installed' &> /dev/null\
            || install="$install $package"
    done

    if [ -n "$install" ]; then
        echo "Installing$install"
        sudo apt-get update -qq
        sudo apt-get install $install -yqq
    fi

    cd "$target/.vim/bundle/YouCompleteMe"
    ./install.sh --clang-completer
fi

