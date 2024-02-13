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


dir="$(dirname "${BASH_SOURCE[0]}")"
for f in "${dir}/bash_completion.d/"*sh; do
    # shellcheck disable=SC1090
    source "${f}"
done
