###################
#  CLI Functions  #
###################

# Runs maven in the parent directory which contains pom.xml
smart_mvn() {
    (mvnd && mvn "$@")
}

# A twist on cd specifically for maven projects.
#
# When executed with arguments, works exactly the same way as cd.
# When executed without arguments, it moves to the closest directory that
# contains pom.xml (which could be $PWD).
mvnd() {
    if [[ $# -eq 0 ]]; then
        # Find the maven directory
        local cwd="$PWD"
        while [[ ! -f "${cwd}/pom.xml" ]]; do
            local next_cwd=$(dirname "${cwd}")
            if [[ "${next_cwd}" -ef "${cwd}" ]]; then
                # We've hit the root
                break
            fi
            cwd="${next_cwd}"
        done

        if [[ ! -f "${cwd}/pom.xml" ]]; then
            echo "There is no Maven project in the hierarchy."
            return 1
        fi

        set -- "${cwd}"
    fi

    cd "$@"
}

# cd to a temporary directory.
cdt() {
    cd "$(mktemp -d)"
}

# Adds -x to the alias builtin, which attempts to expand the alias into a
# command that bash would execute.
#
#   - It handles multiple layers of aliases
#     alias foo=bar
#     alias bar=baz
#     alias -x foo -> baz
#   - It handles recursive aliases
#     alias du=du -h
#     alias -x du -> du -h
#   - It handles aliases with special characters
#     alias foo="bar 'arg with spaces'"
#     alias -x foo -> bar arg\ with\ spaces
#   - You can pass extra arguments to alias -x:
#     alias foo="bar 'arg 1'"
#     alias -x foo 'arg 2' -> bar arg\ 1 arg\ 2
#
# You will probably want to use this with eval/dotfiles::shlex:
#   $ alias foo="bar 'arg 1'"
#   $ dotfiles::print_args $(alias -x foo)
#   1: bar
#   2: arg\
#   3: 1
#   $ eval dotfiles::print_args $(alias -x foo)
#   1: bar
#   2: arg 1
#   $ arr=( $(alias -x foo) )
#   $ dotfiles::print_args "${arr[@]}"
#   1: bar
#   2: arg\
#   3: 1
#   $ eval "$(dotfiles::shlex arr "$(alias -x foo)")"
#   $ dotfiles::print_args "${arr[@]}"
#   1: bar
#   2: arg 1
alias() {
    if [[ "$1" != "-x" ]]; then
        builtin alias "$@"
        return
    fi

    local cmd=( "${@:2}" )
    local -A expanded
    while true; do
        if [[ -n "${expanded["${cmd[0]}"]}" ]]; then
            break
        fi

        expanded["${cmd[0]}"]=1
        local alias="${BASH_ALIASES["${cmd[0]}"]}"
        if [[ -z "${alias}" ]]; then
            break
        fi

        local arr
        eval "$(dotfiles::shlex arr "${alias}")"
        cmd=( "${arr[@]}" "${cmd[@]:1}" )
    done

    local res
    res="$(printf "%q " "${cmd[@]}")"
    echo "${res% }"
}

########################
#  Exported Functions  #
########################

# Prompts the user for a single letter (y or n).
#
# $1: user prompt
#
# returns true if the user enters Y or y
# returns false otherwise
dotfiles::user_permission() {
    local reply
    read -p "$1[yN]" -n 1 -r reply
    echo

    [[ "${reply}" =~ ^[yY]$ ]]
}
export -f dotfiles::user_permission

# Splits $2+ into an array roughly following bash word splitting logic,
# supporting quotes and escape sequences.
#
# $1 is the name of the array that should hold the resulting array.
#
# prints a declare statement that's safe to eval that creates the array.
dotfiles::shlex() {
    local arr="$(printf "%q" "$1")"
    echo "${@:2}" \
      | xargs bash -c "declare -a ${arr}=(\"\$@\"); declare -p ${arr}" dotfiles::shlex
}
export -f dotfiles::shlex

# Prints each argument in order with a numbered label.
dotfiles::print_args() {
    echo "0: $0"
    local i=1
    for arg in "$@"; do
        echo "$i: $arg"
        ((i++))
    done
}
export -f dotfiles::print_args

# Determines if a function is exported.
#
# $1: The function name
dotfiles::is_function_exported() {
    [[ "$(declare -Fp "$1")" = "declare -"*x*" $1" ]]
}
export -f dotfiles::is_function_exported
