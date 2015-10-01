# Takes one parameter:
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

# Takes two parameters:
# $1: a string
# $2+: an array
#
# prints the result of joining the array with $1
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

# Takes two parameters:
# $1: an element to search for
# $2+: an array
#
# returns true is $1 is in the array
# returns false otherwise
contains_in() {
    local e
    for e in "${@:2}"; do
        [ "$e" == "$1" ] && return 0
    done
    return 1
}
export -f contains_in

# Takes three parameters:
# $1: an element
# $2: an index
# $3: the name of an array variable
#
# Prints the result of inserting $1 at index $2 in $3
# array=( "a 1" "b 2" "c 3" )
# insert "foo bar" 2 "array"
# echo "${array[@]}"   # a 1 b 2 foo bar c 3
# echo "${array[2]}"   # foo bar
# echo "${#array[@]}"  # 4
insert() {
    eval $3=\( \"\${$3[@]:0:$2}\" \"$1\" \"\${$3[@]:$2}\" \)
}
export -f insert

# Runs maven in the parent directory which contains pom.xml
smart-mvn() {
    (mvnd && mvn "$@")
}
export -f smart-mvn

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
            echo "There's no maven project in the hierarchy."
            return 1
        fi

        set -- "$cwd"
    fi

    cd "$@"
}
export -f mvnd

# Takes one parameter:
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

        printf "\r${fill// /#}${empty// /-}"
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

