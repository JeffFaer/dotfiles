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
# prints the result of joining the array
# with $1
join() {
    local IFS="$1"
    echo "${*:2}"
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

# Runs maven in the parent directory which contains pom.xml
smart-mvn() {
    local old_pwd="$PWD"
    local return_value=""
    while [ "$PWD" != "/" ] && [ ! -f "pom.xml" ]; do
        cd ..
    done

    if [ "$PWD" == "/" ] && [ ! -f "pom.xml" ]; then
        echo "There's no maven project in the hierarchy."
        return_value=1
    else
        mvn "$@"
        return_value=$?
    fi

    cd "$old_pwd"
    return $return_value
}
export -f smart-mvn

