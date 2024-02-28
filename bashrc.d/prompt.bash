#!/usr/bin/env bash

# Settings that might be overridden by local.bash.

hostname_color="${hostname_color:-white}"
# Each entry in this array should be a function that accepts a path. If the
# function can abbreviate the given path, it should print the abbreviated path
# and return 0, otherwise it should return a non-zero value.
[[ -z "${directory_abbreviaters:-}" ]] && directory_abbreviaters=()
unicode_face_width="${unicode_face_width:-1}"


declare -A color

color[black]=$(tput setaf 0)
color[red]=$(tput setaf 1)
color[green]=$(tput setaf 2)
color[yellow]=$(tput setaf 3)
color[blue]=$(tput setaf 4)
color[magenta]=$(tput setaf 5)
color[cyan]=$(tput setaf 6)
color[white]=$(tput setaf 7)
color[end]='[m'

num_colors=$(tput colors)
load_color() {
    if [[ "${num_colors}" -gt "$1" ]]; then
        tput setaf "$1"
    else
        echo "${color[$2]}"
    fi
}
__bashrc_cleanup+=("num_colors" "load_color")

color[gray]=$(load_color 8 black)
color[bright_green]=$(load_color 10 green)
color[deep_blue]=$(load_color 20 blue)
color[purple]=$(load_color 135 magenta)
color[brown]=$(load_color 94 yellow)
color[deep_green]=$(load_color 28 green)
color[orange]=$(load_color 208 yellow)
color[dark_gray]=$(load_color 237 gray)
color[plum]=$(load_color 219 magenta)

bashrc::abbreviated_dirs() {
    local dirs
    mapfile -t dirs < <(dirs -p)

    local i
    for i in "${!dirs[@]}"; do
        local dir="${dirs[$i]}"

        local abbreviated
        if abbreviated="$(bashrc::abbreviate_dir "${dir}")"; then
            dirs["$i"]="${abbreviated}"
        fi
    done

    echo "${dirs[*]}"
}

bashrc::abbreviate_dir() {
    local dir="$1"

    for abbreviater in "${directory_abbreviaters[@]}"; do
        local path
        if path=$("${abbreviater}" "$dir"); then
            echo "${path}"
            return
        fi
    done

    echo "${dir}"
    return 1
}

bashrc::exit_status() {
    local status=${1:-$?}

    local c
    local face
    if [[ $status -eq 0 ]]; then
        c=green
        face="☺"
    else
        c=red
        face="☹"
    fi

    local face_padding=$((unicode_face_width - 1))
    printf "%s%s%${face_padding}s\n" "${color[$c]}" "${face}" ""
}

# @returns 0 if git and __git_ps1 both exist.
# @prints nothing
bashrc::git_exists() {
    command -v git &> /dev/null && [[ "$(type -t __git_ps1)" == function ]]
}

# @returns 0 if git status should be shown
# @prints nothing
bashrc::show_git_ps1() (
    is_git_dir() {
        git rev-parse &> /dev/null
    }
    shows_untracked_files() {
        [[ "$(git config status.showUntrackedFiles)" != no ]]
    }
    has_tracked_files() {
        [[ -n "$(git ls-files)" ]]
    }

    bashrc::git_exists && is_git_dir \
      && (shows_untracked_files || has_tracked_files)
)

bashrc::elapsed_preexec() {
    __bashrc_elapsed_start=$(date +%s%N)
}
# Insert this first so the elapsed time also includes preexecs.
preexec_functions=("bashrc::elapsed_preexec" "${preexec_functions[@]}")

bashrc::elapsed_precmd() {
    if [[ -z "${__bashrc_elapsed_start}" ]]; then
        return
    fi

    # shellcheck disable=SC2155
    local now_nanos="$(date +%s%N)"
    local elapsed_nanos=$(( now_nanos - __bashrc_elapsed_start ))
    __bashrc_elapsed_start=""

    local elapsed_millis=$(( elapsed_nanos / 1000000 ))
    local elapsed_seconds=$(( elapsed_millis / 1000 ))
    local elapsed_minutes=$(( elapsed_seconds / 60 ))
    local elapsed_hours=$(( elapsed_minutes / 60 ))

    elapsed_millis=$((elapsed_millis % 1000))
    elapsed_seconds=$((elapsed_seconds % 60))
    elapsed_minutes=$((elapsed_minutes % 60))

    local elapsed
    if [[ ${elapsed_hours} -ne 0 ]]; then
        elapsed+="${elapsed_hours}h"
    fi
    if [[ ${elapsed_minutes} -ne 0 ]]; then
        elapsed+="${elapsed_minutes}m"
    fi
    elapsed+="$(printf "%d.%03ds" ${elapsed_seconds} ${elapsed_millis})"

    local status=""
    status+="${color[dark_gray]}${elapsed}"
    status+="${color[end]}"

    echo
    bashrc::echo_right_adjusted "${status}"
}
bashrc::echo_right_adjusted() {
    # shellcheck disable=SC2155
    local len="$(bashrc::length_without_colors "$*")"
    echo -n "[${COLUMNS}C" # Go to the end of the line.
    echo -n "[$((len - 1))D" # Go back a little bit
    echo "$*"
}
# Determines the length of $* without any color control sequences included.
bashrc::length_without_colors() {
    echo -n "$*" | sed -re "s/\[[^m]+?m//g" | wc -m
}
precmd_functions+=("bashrc::elapsed_precmd")

bashrc::status_line() {
    local previous_status=$?
    # shellcheck disable=SC2155
    local now="$(date +%Y-%m-%dT%H:%M:%S)"

    local status=""
    status+="${color[red]}${USER}"
    status+="${color[gray]}@"
    status+="${color[${hostname_color}]}${HOSTNAME}"
    status+="${color[gray]}:"
    # shellcheck disable=SC2030
    status+="${color[blue]}$(color[end]=${color[blue]}; bashrc::abbreviated_dirs)"
    # shellcheck disable=SC2031
    status+="${color[gray]}["
    status+="$(bashrc::exit_status ${previous_status})"
    # shellcheck disable=SC2031
    status+="${color[gray]}]"
    # shellcheck disable=SC2031
    status+="${color[end]}"

    if bashrc::show_git_ps1; then
        # shellcheck disable=SC2031
        status+="$(__git_ps1 \
            "${color[gray]}(${color[end]}%s${color[gray]})${color[end]}")"
    fi

    local right_adjusted_status=""
    # shellcheck disable=SC2031
    right_adjusted_status+="${color[dark_gray]}${now}"
    # shellcheck disable=SC2031
    right_adjusted_status+="${color[end]}"

    # shellcheck disable=SC2155
    local left_len="$(bashrc::length_without_colors "${status}")"
    # shellcheck disable=SC2155
    local right_len="$(bashrc::length_without_colors "${right_adjusted_status}")"
    if [[ $((left_len + right_len)) -ge ${COLUMNS} ]]; then
        echo "${status} ${right_adjusted_status}"
    else
        echo -n "${status}"
        bashrc::echo_right_adjusted "${right_adjusted_status}"
    fi
}
precmd_functions+=("bashrc::status_line")

# Use our version of __git_ps1 until I get around to contributing it back
# upstream.
if bashrc::git_exists; then
    # shellcheck source=/dev/null
    source ~/.git-prompt.sh
fi

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUPSTREAM="verbose"
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWSTASHSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true

# shellcheck disable=SC2031
export PS1="\[${color[gray]}\]$\[${color[end]}\] "
