#!/usr/bin/env bash

set -e
set -u

# Keep plugins separate from command_help to keep order.
plugins=(airline bats ycm)
all_commands=(all none "${plugins[@]}")

declare -A command_help
command_help[all]="Install, and setup all plugins."
command_help[none]="Install, and don't setup any plugins."
command_help[airline]="Set up the vim-airline plugin."
command_help[bats]="Set up the Batch unit tester."
command_help[ycm]="Set up the YouCompleteMe plugin."

install::help() {
    local IFS=','
    local cmds="$(echo "${all_commands[*]}")"
    unset IFS

    echo "$0 [-h|--help] [${cmds}]"
    echo "-h|--help      Displays this message."
    local cmd
    for cmd in "${all_commands[@]}"; do
        printf "%-15s%s\n" "${cmd}" "${command_help["${cmd}"]}"
    done
    exit 1
}

install::shortlist() {
    local IFS=$'\n'
    local fns=( $(compgen -A function "install::") )
    unset IFS

    local cmds=()
    local fn
    for fn in "${fns[@]}"; do
        fn="${fn#install::}"
        if [[ "${fn}" = "shortlist" || "${fn}" = _* ]]; then
            continue
        fi
        cmds+=( "${fn}" )
    done
    echo "${cmds[*]}"
    exit 0
}

install::all() {
    local p
    for p in "${plugins[@]}"; do
        install::_maybe_execute "$p"
    done
}

install::none() {
    :
}

install::airline() {
    echo "Setting up Airline"
    echo "Setting up fonts"
    local base_url="https://github.com/Lokaltog/powerline/raw/develop/font"

    local font_url="${base_url}/PowerlineSymbols.otf"
    local font_dir="${target}/.local/share/fonts/"

    local font_conf_url="${base_url}/10-powerline-symbols.conf"
    local font_conf_dir
    if [[ -n "${XDG_CONFIG_HOME+1}" ]]; then
        font_conf_dir="${XDG_CONFIG_HOME}/fontconfing/conf.d/"
    else
        font_conf_dir="${target}/.fonts.conf.d/"
    fi

    wget -P "${font_dir}" "${font_url}" -q
    wget -P "${font_conf_dir}" "${font_conf_url}" -q
    fc-cache -f
}

install::bats() {
    echo "Installing Bats to /usr/local/"
    sudo ~/src/bats-core/install.sh /usr/local
}

install::ycm() {
    echo "Setting up YCM"
    if install::_install_packages build-essential cmake python3-dev; then
        cd "$target/.vim/bundle/YouCompleteMe"
        python3 install.py --all
    else
        echo "Those packages must be installed before you can install YCM."
    fi
}

install::_maybe_execute() {
    local -Ag executed_commands
    if [[ -z "${executed_commands["$1"]+1}" ]]; then
        executed_commands["$1"]=1
        install::"$1"
    fi
}

# Determine if all of the given packages are installed.
install::_packages_installed() {
    local package
    for package in "$@"; do
        if ! dpkg -s "$package" |& grep -qP '^Status.+(?<!-)installed'; then
            return 1
        fi
    done
}

# Try to install any packages that are not already installed.
install::_install_packages() {
    local install=()
    local package
    for package in "$@"; do
        if ! install::_packages_installed "$package"; then
            install+=( "$package" )
        fi
    done

    if [[ ${#install[@]} -gt 0 ]]; then
        local prompt="Would you like to install: "
        prompt+="${install[*]}?"
        if dotfiles::user_permission "$prompt"; then
            echo "Installing ${install[*]}"
            sudo apt-get update -qq
            sudo apt-get install "${install[@]}" -yqq
        else
            return 1
        fi
    fi
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
            install::_help
            exit 1
            ;;
    esac
done

target=$HOME
git_dir=$(dirname $0)
git_dir=$(readlink -f $git_dir)

# Our .bashrc might not be in place yet, source functions.
if [[ "$(type -t dotfiles::user_permission)" != function ]]; then
    . "${git_dir}/.bash_functions"
fi

# Validate positional arguments.
for arg in "$@"; do
    if [[ "${arg}" = _* || "$(type -t "install::${arg}")" != "function" ]]; then
        echo "Unknown arg: $arg"
        echo
        install::help
        exit 1
    fi

    case "${arg}" in
        help)
            install::help
            exit 1
            ;;
        shortlist)
            install::shortlist
            exit 0
            ;;
    esac
done

to_install=(xclip)
if [[ -n $DISPLAY ]]; then
    to_install+=( gconf-editor meld )
fi
install::_install_packages "${to_install[@]}" || true

# We're running .install.sh from a directory other than $target.
# We need to move the dotfiles into $target.
if [[ ! $git_dir -ef $target ]]; then
    remove_dir_or_die() {
        echo "$1 already exists as a directory"
        if dotfiles::user_permission "Would you like to remove it now?"; then
            echo "Removing $1"
            rm -rf "$1"
        else
            echo "You must remove it before continuing"
            exit 1
        fi
    }

    if [[ -d $target/.git ]]; then
        remove_dir_or_die "$target/.git"
    fi

    conflicts=()
    files_to_move=()
    for ls_file in $(git --git-dir="$git_dir/.git" ls-files); do
        tracked_file="$git_dir/$ls_file"
        target_file="$target/$ls_file"
        if [[ -d $tracked_file && -d $target_file ]]; then
            # We're tracking a submodule and the directory already exists in the
            # target.
            remove_dir_or_die "$target_file"
        elif [[ -f $target_file ]]; then
            # Either the two files are the same, or there are conflicts we need
            # to resolve.
            cmp --silent "$target_file" "$tracked_file"\
                || conflicts+=( "$ls_file" )
        else # $target_file doesn't exist, we can move with no conflicts.
            files_to_move+=( "$ls_file" )
        fi
    done

    # Resolve conflicts first.
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        prompt="There are conflicts (${conflicts[*]}). Would you like to "
        prompt+="resolve them now (move changes you want to keep to the left)?"
        if dotfiles::user_permission "$prompt"; then
            _meld_builder() {
                local build
                if [[ -z $1 ]]; then
                    build+="$2"
                fi

                build+=" --diff \"$3\" \"$4\""

                echo "$build"
            }

            _default_builder() {
                local build
                if [[ -n $1 ]]; then
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

            if [[ $mergetool == meld ]]; then
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

if [[ -n $DISPLAY ]] && command -v gconftool &> /dev/null; then
    echo "Setting up gnome-terminal"
    gconftool --set /apps/gnome-terminal/profiles/Default/custom_command \
        --type=string "env TERM=xterm-256color bash"
    gconftool --set /apps/gnome-terminal/profiles/Default/use_custom_command \
        --type=bool true
fi

echo "Setting up git"
git config status.showUntrackedFiles no
git config bash.showUntrackedFiles false
git submodule update --init --recursive

vim +PluginInstall +qall

for cmd in "$@"; do
    install::_maybe_execute "${cmd}"
done
