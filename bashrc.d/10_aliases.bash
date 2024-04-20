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

# Determines which completion is used for the aliased command and applies it to
# the alias itself.
#
# $1: The command that is aliased.
# $2?: The command whose completion should be copied. If not provided, it will
# be determined from the first word of the alias.
alias_completion() {
    local command="$1"
    local alias="$2"
    if [[ $# -eq 1 ]]; then
        local alias_spec
        if ! alias_spec="$(alias "${command}")" \
            || [[ -z "${alias_spec}" ]]; then
            return 1
        fi

        local alias_command
        if ! alias_command="$(
            sed -re "s/alias ${command}='(.+)'/\1/" <<< "${alias_spec}")"; then
            return 1
        fi

        local words
        read -r -a words <<< "${alias_command}"
        alias=${words[0]}
    fi

    local completion
    if ! completion=$(complete -p "${alias}" 2>/dev/null) \
        || [[ -z "${completion}" ]]; then
        return 1
    fi

    # shellcheck disable=SC2046
    eval $(sed -re "s/${alias}\$/${command}/" <<< "${completion}")
}
__bashrc_cleanup+=("alias_completion")

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

alias_completion tvs

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
