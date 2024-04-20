# Adds an alias for $1 which appends the remaining arguments to an existing
# alias. If there is no existing alias, then the arguments are appended to the
# command itself.
#
# $1: Command name to alias
# $2+: Things to append to the alias.
alias_append() {
    alias $1="${BASH_ALIASES[$1]:-$1} ${*:2}"
}
__bashrc_cleanup+=("alias_append")

# keep-sorted start
alias cp="cp -i"
alias du="du -h"
alias from-clipboard="xclip -o"
alias gcc="gcc -ansi -Wall -g -O0 -Wwrite-strings -Wshadow -pedantic-errors -fstack-protector-all"
alias mv="mv -i"
alias to-clipboard="xclip -sel clip"
alias tvs="tmux-vcs-sync"
alias ulimit="ulimit -S"
alias vim="vim --servername vim"
alias yadm="yadm --yadm-repo ~/.git"
# keep-sorted end

if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi

    alias grep='grep --color=auto'
    alias ls="ls --color=auto"
fi

alias_append ls "-h"

bashrc::alias_aware_completion_loader() {
    local completion_loader="_completion_loader"
    local cmd="$1"
    local expanded="$(alias -x "${cmd}")"
    if [[ "${expanded}" == "${cmd}" ]]; then
        # ${cmd} is not an alias.
        "${completion_loader}" "${cmd}"
        return
    fi

    local arr=()
    eval "$(dotfiles::shlex arr "${expanded}")"

    local i
    for ((i="${#arr[@]}"-1; i >= 0; i--)) do
        # The command we want to use for our completion depends on whether the
        # alias is using pipes, boolean operators, or command lists.
        # This assumes there's spaces around pipes and boolean operators, but
        # semicolons are only expected to have trailing space.
        case "${arr[i]}" in
            "|"|"||"|"&&"|*";")
                break
                ;;
        esac
    done
    local alias=( "${arr[@]:i+1}" )

    "${completion_loader}" "${alias[0]}"
    if (( $? != 124 )); then
        printf "\n%s failed\n" "${completion_loader} ${alias[0]}" 1>&2
        "${completion_loader}" "${cmd}"
        return
    fi

    local compspec
    if ! compspec="$(complete -p "${alias[0]}")"; then
        "${completion_loader}" "${cmd}"
        return
    fi

    # compspec="complete -o default -F funcname ${alias[0]}"
    local comp_func="${compspec##* -F }"
    # comp_func="funcname ${alias[0]}"
    comp_func="${comp_func%% *}"
    # comp_func="funcname"

    if [[ -z "${comp_func}" ]]; then
        ${compspec} "${cmd}"
        return 124
    fi

    # Make ${alias[@]} available after this function exits.
    local alias_name="__bashrc_alias_aware_completion_loader_${cmd}"
    declare -gn global_alias="${alias_name}"
    global_alias=( "${alias[@]}" )

    # Create a wrapper function to invoke ${comp_func} with the expanded alias.
    local func_name="${FUNCNAME[0]}::${cmd}"
    local func="
${func_name}() {
  (( COMP_CWORD += $((${#alias[@]}-1)) ))
  COMP_WORDS=( \"\${${alias_name}[@]}\" \"\${COMP_WORDS[@]:1}\" )
  (( COMP_POINT -= \${#COMP_LINE} ))
  COMP_LINE=\"\${COMP_LINE/${cmd}/\${${alias_name}[*]}}\"
  (( COMP_POINT += \${#COMP_LINE} ))
  ${comp_func} \"${alias[0]}\" \"\${COMP_WORDS[COMP_CWORD]}\" \"\${COMP_WORDS[COMP_CWORD-1]}\"
}"
    eval "${func}"
    compspec="${compspec/ -F ${comp_func} / -F ${func_name} }"
    # Remove ${alias[0]} from the end of compspec.
    compspec="${compspec% *}"
    ${compspec} "${cmd}"
    return 124
}
complete -D -F bashrc::alias_aware_completion_loader
