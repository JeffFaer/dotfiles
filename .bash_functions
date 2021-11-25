# Prompts the user for a single letter (y or n).
#
# $1: user prompt
#
# returns true if the user enters Y or y
# returns false otherwise
user_permission() {
    local reply
    read -p "$1[yN]" -n 1 -r reply
    echo

    [[ "$reply" =~ ^[yY]$ ]]
}
export -f user_permission

# Runs maven in the parent directory which contains pom.xml
smart_mvn() {
    (mvnd && mvn "$@")
}
export -f smart_mvn

# A twist on cd specifically for maven projects.
#
# When executed with arguments, works exactly the same way as cd.
# When executed without arguments, it moves to the closest directory that
# contains pom.xml (which could be $PWD).
mvnd() {
    if [[ $# -eq 0 ]]; then
        # Find the maven directory
        local cwd="$PWD"
        while [[ ! -f $cwd/pom.xml ]]; do
            local next_cwd=$(dirname "$cwd")
            if [[ $next_cwd -ef $cwd ]]; then
                # We've hit the root
                break
            fi
            cwd="$next_cwd"
        done

        if [[ ! -f $cwd/pom.xml ]]; then
            echo "There is no Maven project in the hierarchy."
            return 1
        fi

        set -- "$cwd"
    fi

    cd "$@"
}
export -f mvnd

# cd to a temporary directory.
cdt() {
    cd $(mktemp -d)
}
export -f cdt

# Adds an alias for $1 which appends the remaining arguments to an existing
# alias. If there is no existing alias, then the arguments are appended to the
# command itself.
#
# $1: Command name to alias
# $2+: Things to append to the alias.
alias_append() {
    alias $1="${BASH_ALIASES[$1]:-$1} ${*:2}"
}
export -f alias_append

# Determines which completion is used for the aliased command and applies it to
#
# the alias itself.
# $1: The command that is aliased.
# $2?: The command whose completion should be copied. If not provided, it will
# be determined from the first word of the alias.
alias_completion() {
    local command=$1
    local alias=$2
    if [[ $# -eq 1 ]]; then
        local alias_spec=$(alias "$command")
        if [[ $? -ne 0 || -z $alias_spec ]]; then
            return 1
        fi

        local alias_command=$(sed -re "s/alias $command='(.+)'/\1/"\
            <<< "$alias_spec")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        local words=( $alias_command )
        alias=${words[0]}
    fi

    local completion=$(complete -p "$alias" 2>/dev/null)
    if [[ $? -ne 0 || -z "$completion" ]]; then
        return 1
    fi

    eval $(sed -re "s/$alias$/$command/" <<< "$completion")
}
export -f alias_completion

# Prints each argument in order with a numbered label.
print_args() {
    echo "0: $0"
    local i=1
    for arg in "$@"; do
        echo "$i: $arg"
        ((i++))
    done
}
export -f print_args

# Runs mkdir -p and cd on the argument.
mkcd() {
    mkdir -p "$@" && cd "$@"
}
export -f mkcd

# $1: The variable that should contain the current column.
#
# Sets $1 to the column that the cursor is on.
current_column() {
    local unused

    echo -ne "\033[6n"
    read -sd\[ unused
    read -sd\; unused
    read -sdR $1
}
export -f current_column
