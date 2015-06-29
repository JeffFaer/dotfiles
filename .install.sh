#!/usr/bin/env bash

set -e

# Positional arguments
declare -A setup_stages
setup_stages[airline]="sets up the vim-airline plugin"
setup_stages[ycm]="sets up the YouCompleteMe plugin"
allowed_args=(all none shortlist "${!setup_stages[@]}")

usage() {
    echo "$0 [-h|--help] [$(join ',' "${allowed_args[@]}")]"
    echo "-h|--help      displays this message"
    echo "all            install and do all setup stages (default)"
    echo "none           install but do no extra setup"
    for stage in "${!setup_stages[@]}"; do
        printf "%-15s%s\n" "$stage" "${setup_stages[$stage]}"
    done
    exit 1
}

ARGS=$(getopt -o 'h' --long 'help' -n "$(basename $0)" -- "$@")
eval set -- "$ARGS"

# Handle help flags
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

target=$HOME
# Our .bashrc might not be in place yet,
# we need our functions
git_dir=$(dirname $0)
git_dir=$(readlink -f $git_dir)
. "${git_dir}/.bash_functions"

# validate positional arguments
for arg in "$@"; do
    if ! contains_in "$arg" "${allowed_args[@]}"; then
        echo "Unknown arg: $arg"
        exit 1
    fi
done

if contains_in "shortlist" "$@"; then
    echo "${allowed_args[*]}"
    exit 0
fi

# look through all positional arguments and set the correct
# setup variable for it
declare -A setup
if [ "$#" -eq "0" ] || contains_in "all" "$@"; then
    setup[all]=1
fi
for stage in "${!setup_stages[@]}"; do
    if [ -n "${setup[all]}" ] || contains_in "$stage" "$@"; then
        setup[$stage]=1
    fi
done

# the dot files aren't in the target yet
# let's fix that
if [ ! "$git_dir" -ef "$target" ]; then
    remove_dir_or_die() {
        echo "$1 already exists as a directory"
        if user_permission "Would you like to remove it now?"; then
            echo "Removing $1"
            rm -rf "$1"
        else
            echo "You must remove it before continuing"
            exit 1
        fi
    }

    if [ -d "$target/.git" ]; then
        remove_dir_or_die "$target/.git"
    fi

    conflicts=""
    for ls_file in $(git --git-dir="$git_dir/.git" ls-files); do
        tracked_file="$git_dir/$ls_file"
        target_file="$target/$ls_file"
        if [ -d "$tracked_file" ] && [ -d "$target_file" ]; then
            # submodule
            remove_dir_or_die "$target_file"
        elif [ -f "$target_file" ]; then
            # save potential conflicts for later.
            cmp --silent "$target_file" "$tracked_file"\
                || conflicts+=" $ls_file"
        elif [ -e "$tracked_file" ]; then
            mkdir -p $(dirname "$target_file")
            mv "$tracked_file" "$target_file"
        fi
        # else we've already moved it
    done

    if [ -n "$conflicts" ]; then
        prompt="There are conflicts (${conflicts# }). Would you like to "
        prompt+="resolve them now (move changes you want to keep to the left)?"
        if user_permission "$prompt"; then
            _meld_builder() {
                local build=""
                if [ -z "$1" ]; then
                    build+="$2"
                fi

                build+=" --diff \"$3\" \"$4\""

                echo "$build"
            }

            _default_builder() {
                local build=""
                if [ -n "$1" ]; then
                    build+="; "
                fi
                build+="$2 \"$3\" \"$4\""

                echo "$build"
            }
            # we can't make git config fail gracefully, so we have to ||
            # it because of set -e
            mergetool=$(git config merge.tool || echo)
            if ! command -v "$mergetool" &> /dev/null; then
                # default to vimdiff
                mergetool="vimdiff"
            fi

            if [ "$mergetool" == "meld" ]; then
                command_builder=_meld_builder
            else
                command_builder=_default_builder
            fi
            conflict_command=""
            for conflict in $conflicts; do
                target_file="$target/$conflict"
                tracked_file="$git_dir/$conflict"

                conflict_command+=$($command_builder "$conflict_command" \
                    "$mergetool" "$target_file" "$tracked_file")
            done

            eval $conflict_command
        else
            echo "You must resolve conflicts before continuing."
            exit 1
        fi
    fi

    mv "$git_dir/.git/" "$target"
    cd "$target"

    # clean up the old directory
    rm -rf "$git_dir"
fi

git config status.showUntrackedFiles no
git submodule update --init --recursive

vim +PluginInstall +qall

# Airline setup
if [ -n "${setup[airline]}" ]; then
    echo "Setting up Airline"
    echo "Setting up fonts"
    base_url="https://github.com/Lokaltog/powerline/raw/develop/font"

    font_url="${base_url}/PowerlineSymbols.otf"
    font_dir="$target/.local/share/fonts/"

    font_conf_url="${base_url}/10-powerline-symbols.conf"
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
if [ -n "${setup[ycm]}" ]; then
    echo "Setting up YCM"
    install=""
    for package in "build-essential" "cmake" "python-dev"; do
        dpkg -s "$package" 2>&1 |\
            grep -P '^Status.+(?<!-)installed' &> /dev/null\
            || install+=" $package"
    done

    if [ -n "$install" ]; then
        echo "Installing$install"
        sudo apt-get update -qq
        sudo apt-get install $install -yqq
    fi

    cd "$target/.vim/bundle/YouCompleteMe"
    ./install.sh --clang-completer
fi

