#!/usr/bin/env bash

set -e

# Declare plugin installers in an associative array.
declare -A setup_stages
setup_stages[airline]="Set up the vim-airline plugin."
setup_stages[bats]="Set up Bash unit tester."
setup_stages[pandoc]="Set up pandoc."
setup_stages[ycm]="Set up the YouCompleteMe plugin."
allowed_args=(all none shortlist "${!setup_stages[@]}")

usage() {
    echo "$0 [-h|--help] [$(join ',' "${allowed_args[@]}")]"
    echo "-h|--help      Displays this message."
    echo "all            Install and do all setup stages (default)."
    echo "none           Install but do no extra setup."
    for stage in "${!setup_stages[@]}"; do
        printf "%-15s%s\n" "$stage" "${setup_stages[$stage]}"
    done
    exit 1
}

ARGS=$(getopt -o 'h' --long 'help' -n "$(basename $0)" -- "$@")
eval set -- "$ARGS"

# Handle flags.
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
git_dir=$(dirname $0)
git_dir=$(readlink -f $git_dir)

# Our .bashrc might not be in place yet, source functions.
if [ "$(type -t contains_in)" != "function" ]; then
    . "${git_dir}/.bash_functions"
fi

# Validate positional arguments.
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

# Figure out which plugins we want to install from the positional arguments.
declare -A setup
if [ "$#" -eq "0" ] || contains_in "all" "$@"; then
    setup[all]=1
fi
for stage in "${!setup_stages[@]}"; do
    if [ -n "${setup[all]}" ] || contains_in "$stage" "$@"; then
        setup[$stage]=1
    fi
done

if [ -n "$DISPLAY" ]; then
    install_packages gconf-editor || true
    install_packages meld || true
fi

# We're running .install.sh from a directory other than $target.
# We need to move the dotfiles into $target.
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

    conflicts=()
    files_to_move=()
    for ls_file in $(git --git-dir="$git_dir/.git" ls-files); do
        tracked_file="$git_dir/$ls_file"
        target_file="$target/$ls_file"
        if [ -d "$tracked_file" ] && [ -d "$target_file" ]; then
            # We're tracking a submodule and the directory already exists in the
            # target.
            remove_dir_or_die "$target_file"
        elif [ -f "$target_file" ]; then
            # Either the two files are the same, or there are conflicts we need
            # to resolve.
            cmp --silent "$target_file" "$tracked_file"\
                || conflicts+=( "$ls_file" )
        else # $target_file doesn't exist, we can move with no conflicts.
            files_to_move+=( "$ls_file" )
        fi
    done

    # Resolve conflicts first.
    if [ "${#conflicts[@]}" -gt "0" ]; then
        prompt="There are conflicts (${conflicts[*]}). Would you like to "
        prompt+="resolve them now (move changes you want to keep to the left)?"
        if user_permission "$prompt"; then
            _meld_builder() {
                local build
                if [ -z "$1" ]; then
                    build+="$2"
                fi

                build+=" --diff \"$3\" \"$4\""

                echo "$build"
            }

            _default_builder() {
                local build
                if [ -n "$1" ]; then
                    build+="; "
                fi
                build+="$2 \"$3\" \"$4\""

                echo "$build"
            }
            # git config will not fail gracefully because of set -e
            mergetool=$(git config merge.tool || true)
            if ! command -v "$mergetool" &> /dev/null; then
                # Default to meld or vimdiff.
                if command -v "meld" &> /dev/null; then
                    mergetool="meld"
                else
                    mergetool="vimdiff"
                fi
            fi

            if [ "$mergetool" == "meld" ]; then
                command_builder=_meld_builder
            else
                command_builder=_default_builder
            fi
            conflict_command=""
            for conflict in "${conflicts[@]}"; do
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

    # Move all non-conflicting files.
    for move in "${files_to_move[@]}"; do
        target_file="$target/$move"
        tracked_file="$git_dir/$move"

        mkdir -p $(dirname "$target_file")
        mv "$tracked_file" "$target_file"
    done

    mv "$git_dir/.git/" "$target"
    cd "$target"

    # Clean up the old directory.
    rm -rf "$git_dir"
fi

if [ -n "$DISPLAY" ] && command -v gconftool &> /dev/null; then
    echo "Setting up gnome-terminal"
    gconftool --set /apps/gnome-terminal/profiles/Default/custom_command \
        --type=string "env TERM=xterm-256color bash"
    gconftool --set /apps/gnome-terminal/profiles/Default/use_custom_command \
        --type=bool true
    gconftool --set /apps/gnome-terminal/profiles/Default/login_shell \
        --type=bool true
fi

echo "Setting up git"
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

# pandoc setup
if [ -n "${setup[pandoc]}" ]; then
    echo "Setting up pandoc"
    install_packages pandoc texlive texlive-xetex
fi

# YCM setup
if [ -n "${setup[ycm]}" ]; then
    echo "Setting up YCM"
    if install_packages build-essential cmake python-dev python3-dev; then
        cd "$target/.vim/bundle/YouCompleteMe"
        python3 install.py --clang-completer
    else
        echo "Those packages must be installed before you can install YCM."
    fi
fi

# Bats setup
if [ -n "${setup[bats]}" ]; then
    echo "Installing Bats to /usr/local/"
    sudo ~/src/bats/install.sh /usr/local
fi
