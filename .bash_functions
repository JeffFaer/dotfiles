# $1: user prompt
#
# Prompts the user for a single letter (y or n).
# returns true if the user enters Y or y
# returns false otherwise
user_permission() {
    local reply
    read -p "$1[yN]" -n 1 -r reply
    echo

    [[ "$reply" =~ ^[yY]$ ]]
}
export -f user_permission

# $1: a string
# $2+: an array
#
# Prints the result of joining the array with $1
join() {
    local e
    local is_first="1"
    for e in "${@:2}"; do
        if [ "$is_first" != "1" ]; then
            echo -n "$1"
        fi

        echo -n "$e"
        is_first=0
    done
    echo
}
export -f join

# $1: An element to search for
# $2+: An array
#
# prints the 0 based index of the element in the array.
# prints -1 and returns 1 if the element is not found.
index_of() {
    local e
    local i=0
    for e in "${@:2}"; do
        [ "$e" == "$1" ] && echo $i && return 0
        ((i++))
    done

    echo "-1"
    return 1
}
export -f index_of

# $1: an element to search for
# $2+: an array
#
# returns true is $1 is in the array
# returns false otherwise
contains_in() {
    index_of "$@" > /dev/null
}
export -f contains_in

# $1: an element
# $2: an index
# $3: the name of an array variable
#
# Inserts $1 at index $2 in $3
# array=( "a 1" "b 2" "c 3" )
# insert "foo bar" 2 "array"
# echo "${array[@]}"   # a 1 b 2 foo bar c 3
# echo "${array[2]}"   # foo bar
# echo "${#array[@]}"  # 4
insert() {
    eval $3=\( \"\${$3[@]:0:$2}\" \"$1\" \"\${$3[@]:$2}\" \)
}
export -f insert

# $1: an index
# $2: the name of an array variable
#
# Removes the the index of the array, shifting all other elements as necessary.
remove_index() {
    eval $2=\( \"\${$2[@]:0:$1}\" \"\${$2[@]:$1+1}\" \)
}
export -f remove_index

# $1: an element
# $2: the name of an array variable
#
# Removes the first occurance of the element.
remove_first() {
    local tmp
    eval tmp=\( \"\${$2[@]}\" \)
    local i=$(index_of $1 "${tmp[@]}")
    if [ "$i" != "-1" ]; then
        remove_index $i $2
    else
        return 1
    fi
}
export -f remove_first

# Runs maven in the parent directory which contains pom.xml
smart_mvn() {
    (mvnd && mvn "$@")
}
export -f smart_mvn

# Works exactly the same way as cd except when invoking without
# any arguments. cd will take you to $HOME, mvnd will take you
# to the closest directory, including $PWD, that contains pom.xml
mvnd() {
    if [ "$#" -eq "0" ]; then
        # Find the maven directory
        local cwd="$PWD"
        while [ ! -f "$cwd/pom.xml" ]; do
            local next_cwd=$(dirname "$cwd")
            if [ "$next_cwd" -ef "$cwd" ]; then
                # We've hit the root
                break
            fi
            cwd="$next_cwd"
        done

        if [ ! -f "$cwd/pom.xml" ]; then
            echo "There is no Maven project in the hierarchy."
            return 1
        fi

        set -- "$cwd"
    fi

    cd "$@"
}
export -f mvnd

# $1: A regex to find on the $PATH
#
# Prints the path of the files it finds.
find_path() {
    find ${PATH//:/ } -regextype posix-extended -regex ".*?$1.*?"
}
export -f find_path

# This function has two forms:
# progress clear
#   - Clears the progress bar from the output line
# progress show MIN MAX
#   - Shows the progress bar MIN/MAX percent complete.
#
# You do not need to clear before showing twice in a row.
progress() {
    local action=$1

    local length=50
    if [ "$action" == "show" ]; then
        local current=$2
        local max=$3
        local progress=$(echo "$length * $current / $max" | bc -l)
        progress=$(printf "%.0f" $progress)
        local to_complete=
        let to_complete=$length-$progress

        local fill=$(printf "%${progress}s")
        local empty=$(printf "%${to_complete}s")

        printf "\r${fill// /\#}${empty// /-}"
    elif [ "$action" == "clear" ]; then
        for i in $(seq 1 $length); do
            printf "\b"
        done
        for i in $(seq 1 $length); do
            printf " "
        done
        for i in $(seq 1 $length); do
            printf "\b"
        done
    fi
}
export -f progress

# cd to a temporary directory.
cdt() {
    cd $(mktemp -d)
}
export -f cdt

# $1+: packages to install
#
# Determine if the given packages are installed. If they are not, try to install
# them.
install_packages() {
    local install=()
    for package in "$@"; do
        dpkg -s "$package" |& grep -qP '^Status.+(?<!-)installed'\
            || install+=( "$package" )
    done

    if [ "${#install[@]}" -gt "0" ]; then
        local prompt="Would you like to install: "
        prompt+="${install[*]}?"
        if user_permission "$prompt"; then
            echo "Installing ${install[*]}"
            sudo apt-get update -qq
            sudo apt-get install "${install[@]}" -yqq
        else
            return 1
        fi
    fi
}
export -f install_packages

# $1: Command name to alias
# $2+: Things to append to the alias.
#
# Adds an alias for $1 which appends the remaining arguments to an existing
# alias. If there is no existing alias, then the arguments are appended to the
# command itself.
alias_append() {
    alias $1="${BASH_ALIASES[$1]:-$1} ${*:2}"
}
export -f alias_append

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
