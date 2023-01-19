if ! command -v tmux &> /dev/null; then
    return
fi

# $1: suggestion to escape.
_tmux::completion::escape_suggestion() {
    local escaped=$(printf "%q" "$1")
    # Double up each backslash for completion.
    escaped="${escaped//\\/\\\\}"
    # Add an extra backslash for dollar signs.
    # Otherwise, the variable will be expanded.
    escaped="${escaped//\$/\\\$}"
    echo "${escaped}"
}

# Generates a list of suggestions and appends them to COMPREPLY.
#
# $1: $cur
# $2: Prefix e.g. #{client_
# $3: Suffix e.g. }
# $4+: infixes
#
# This function handles escaping each suggestion and $cur.
_tmux::completion::format_suggestions() {
    local cur="$1"
    local prefix="$2"
    local suffix="$3"

    local suggestions=()
    local infix
    local suggestion
    for infix in "${@:4}"; do
        suggestion="${prefix}${infix}${suffix}"
        suggestion="$(_tmux::completion::escape_suggestion "${suggestion}")"
        suggestions+=( "${suggestion}" )
    done

    # Escape cur for compgen.
    local cur="$(printf "%q" "${cur}")"

    local IFS=$'\n'
    suggestions=( $(compgen -W "${suggestions[*]}" -- "${cur}") )
    unset IFS

    COMPREPLY+=( "${suggestions[@]}" )
}

_tmux::completion::suggest_commands() {
    local IFS=$'\n'
    local commands=( $(tmux list-commands -F "#{command_list_name}") )
    unset IFS

    _tmux::completion::format_suggestions "$1" "" "" "${commands[@]}"
}

_tmux::completion::num_sessions() {
    tmux ls 2>/dev/null | wc -l
    return 0
}

_tmux::completion::suggest_sessions() {
    local IFS=$'\n'
    local sessions=( $(tmux ls -F '#{session_name}' 2>/dev/null) )
    unset IFS

    local escaped_sessions=()
    local session
    for session in "${sessions[@]}"; do
        # Escape @ symbols, otherwise tmux thinks we want a window.
        escaped_sessions+=( "${session//@/\\@}" )
    done

    _tmux::completion::format_suggestions "$1" "" "" "${escaped_sessions[@]}"
}

_tmux::completion::num_clients() {
    tmux lsc 2>/dev/null | wc -l
    return 0
}

_tmux::completion::suggest_clients() {
    local IFS=$'\n'
    local clients=( $(tmux lsc -F '#{client_tty}' 2>/dev/null) )
    unset IFS

    _tmux::completion::format_suggestions "$1" "" "" "${clients[@]}"
}

_tmux::completion::num_windows() {
    tmux lsw 2>/dev/null | wc -l
    return 0
}

_tmux::completion::suggest_windows() {
    local IFS=$'\n'
    local windows=( $(tmux lsw -a -F '#{window_name}' 2>/dev/null) )
    unset IFS
    _tmux::completion::format_suggestions "$1" "" "" "${windows[@]}"
}

_tmux::completion::suggest_client_format() {
    local format_names=( "activity" "activity_string" "created"\
        "created_string" "cwd" "height" "last_session" "prefix"\
        "readonly" "session" "termname" "tty" "utf8" "width" )
    _tmux::completion::format_suggestions "$1" "#{client_" "}" "${format_names[@]}"
}

_tmux::completion::suggest_session_format() {
    local format_names=( "attached" "created" "created_string" "group"\
        "grouped" "height" "id" "name" "width" "windows" )
    _tmux::completion::format_suggestions "$1" "#{session_" "}" "${format_names[@]}"
}

_tmux::completion::suggest_window_format() {
    local format_names=( "active" "find_matches" "flags" "height" "id"\
        "index" "layout" "name" "panes" "width" "wrap_flag" )
    _tmux::completion::format_suggestions "$1" "#{window_" "}" "${format_names[@]}"
}

# Creates an extglob which must match $1, but additionally any letters found in
# sequence from $2.
_tmux::completion::match_command() {
    local glob=$1
    local closing_parens=""

    local i
    for ((i=0; i < ${#2}; i++)); do
        glob+="?(${2:$i:1}"
        closing_parens+=")"
    done

    echo "${glob}${closing_parens}"
}

_tmux::completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    # What has the user already typed?
    local cmd
    local -A enabled_options

    # What options can we suggest?
    local -A options

    # Figure out what our command is.
    local i
    # Start at i=1 so we can skip tmux.
    for ((i=1; i<$COMP_CWORD; i++)); do
        local word="${COMP_WORDS[i]}"

        case "${word}" in
            -c|-f|-L|-S)
                # These tmux options take a parameter. Skip the parameter.
                ((i++))
                ;;
            -*)
                # Skip this option, we don't care.
                :
                ;;
            *)
                cmd="${word}"
                break
                ;;
        esac
    done

    # Figure out what options have already been enabled.
    for ((; i<$COMP_CWORD; i++)); do
        local word=${COMP_WORDS[i]}

        if [[ $word == -* ]]; then
            enabled_options["${word}"]=1
        fi
    done

    # There is no command yet.
    if [[ -z "${cmd}" ]]; then
        if tmux has-session &> /dev/null; then
            _tmux::completion::suggest_commands "${cur}"
        else
            # There are no existing sessions.

            # Commands that can be run with no existing session.
            local initial_commands=( "start-server" "new-session" )
            COMPREPLY=( $(compgen -W "${initial_commands[*]}" -- "${cur}") )
        fi

        return 0
    fi

    # Remember if extglob is enabled or not so we can reset back to its original
    # state.
    local old_extglob=$(shopt -p extglob)
    shopt -s extglob

    case "${cmd}" in
        $(_tmux::completion::match_command a ttach-session))
            case "${prev}" in
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    options[-d]="detach other clients"
                    options[-r]="readonly"
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="target session"
                    fi
                    ;;
            esac ;;
        $(_tmux::completion::match_command det ach-client))
            case "${prev}" in
                -s) _tmux::completion::suggest_sessions "${cur}" ;;
                -t) _tmux::completion::suggest_clients "${cur}" ;;
                *)
                    options[-P]="SIGHUP"
                    options[-a]="kill all but -t"
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-s]="target session"
                    fi
                    if [[ $(_tmux::completion::num_clients) -gt 1 ]]; then
                        options[-t]="target client"
                    fi
                    ;;
            esac ;;
        $(_tmux::completion::match_command h as-session))
            case "${prev}" in
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="target session"
                    fi
                    ;;
            esac ;;
        $(_tmux::completion::match_command kill-ses sion))
            case "${prev}" in
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    options[-a]="kill all but -t"
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="target session"
                    fi
                    ;;
            esac ;;
        killw|$(_tmux::completion::match_command kill-w indow))
           case "${prev}" in
               -t) _tmux::completion::suggest_windows "${cur}" ;;
               *)
                   options[-a]="kill all but -t"
                   if [[ $(_tmux::completion::num_windows) -gt 1 ]]; then
                       options[-t]="target window"
                   fi
                   ;;
           esac ;;
        lsc|$(_tmux::completion::match_command list-cl ients))
            case "${prev}" in
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                -F) _tmux::completion::suggest_client_format "${cur}" ;;
                *)
                    options[-F]="format string"
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="target session"
                    fi
                    ;;
            esac ;;
        ls|$(_tmux::completion::match_command list-s essions))
            case "${prev}" in
                -F) _tmux::completion::suggest_session_format "${cur}" ;;
                *) options[-F]="format string" ;;
            esac ;;
        lsw|$(_tmux::completion::match_command list-w indows))
            case "${prev}" in
                -F) _tmux::completion::suggest_window_format "${cur}" ;;
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    options[-a]="all windows"
                    options[-F]="format string"
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="target session"
                    fi
                    ;;
            esac ;;
        lockc|$(_tmux::completion::match_command lock-c lient))
            case "${prev}" in
                -t) _tmux::completion::suggest_clients "${cur}" ;;
                *)
                    if [[ $(_tmux::completion::num_clients) -gt 1 ]]; then
                        options[-t]="target client"
                    fi
                    ;;
            esac ;;
        locks|$(_tmux::completion::match_command lock-s ession))
            case "${prev}" in
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="target session"
                    fi
                    ;;
            esac ;;
        $(_tmux::completion::match_command new -session))
            case "${prev}" in
                -s)
                    if ((${enabled_options["-A"]})); then
                        _tmux::completion::suggest_sessions "${cur}"
                    fi
                    ;;
                -F) _tmux::completion::suggest_session_format "${cur}" ;;
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    options[-A]="attach to -s if it exists"
                    options[-d]="create detached"
                    options[-P]="print session info"
                    options[-s]="session name"
                    if ((${enabled_options["-A"]})); then
                        options[-D]="detach other clients"
                    fi
                    if ! ((${enabled_options["-t"]})); then
                        options[-n]="window name"
                    fi
                    if ((${enabled_options["-P"]})); then
                        options[-F]="format string"
                    fi
                    if ((${enabled_options["-d"]})); then
                        options[-x]="window width"
                        options[-y]="window height"
                    fi
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="group with target session"
                    fi
                    ;;
            esac ;;
        $(_tmux::completion::match_command ref resh-client))
            case "${prev}" in
                -t) _tmux::completion::suggest_clients "${cur}" ;;
                *)
                    options[-S]="only update status bar"
                    if [[ $(_tmux::completion::num_clients) -gt 1 ]]; then
                        options[-t]="target client"
                    fi
                    ;;
            esac ;;
        $(_tmux::completion::match_command rename-s ession))
            case "${prev}" in
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                        options[-t]="target session"
                    fi
                    ;;
            esac ;;
        showmsgs|$(_tmux::completion::match_command show-m essages))
            case "${prev}" in
                -t) _tmux::completion::suggest_clients "${cur}" ;;
                *)
                    if [[ $(_tmux::completion::num_clients) -gt 1 ]]; then
                        options[-t]="target client"
                    fi
                    ;;
            esac ;;
        $(_tmux::completion::match_command so urce-file)) _filedir ;;
        suspendc|$(_tmux::completion::match_command su spend-client))
            case "${prev}" in
                -t) _tmux::completion::suggest_clients "${cur}" ;;
                *)
                    if [[ $(_tmux::completion::num_clients) -gt 1 ]]; then
                        options[-t]="target client"
                    fi
                    ;;
            esac ;;
        switchc|$(_tmux::completion::match_command swi tch-client))
            case "${prev}" in
                -c) _tmux::completion::suggest_clients "${cur}" ;;
                -t) _tmux::completion::suggest_sessions "${cur}" ;;
                *)
                    options[-r]="readonly"
                    if ((${enabled_options["-l"]})) \
                        || ((${enabled_options["-n"]})) \
                        || ((${enabled_options["-p"]})) \
                        || ((${enabled_options["-t"]})); then
                        :
                    else
                        options[-l]="go to last session"
                        options[-n]="go to next session"
                        options[-p]="go to prev session"
                        if [[ $(_tmux::completion::num_sessions) -gt 1 ]]; then
                            options[-t]="target session"
                        fi
                    fi
                    if [[ $(_tmux::completion::num_clients) -gt 1 ]]; then
                        options[-c]="target client"
                    fi
                    ;;
            esac ;;
    esac
    eval ${old_extglob}

    if [[ ${#options[@]} -gt 0 ]]; then
        local -A proposed_options
        local opt
        for opt in "${!options[@]}"; do
            # Don't propose anything that's already enabled.
            if ((${enabled_options["${opt}"]})); then
                continue
            fi

            proposed_options["${opt}"]=1
        done

        # Use compgen to narrow down the choices.
        local compgen_options=( $(compgen -W "${!proposed_options[*]}" -- "${cur}") )

        if [[ ${#compgen_options[@]} -gt 0 ]]; then
            if [[ ${COMP_TYPE} -eq 63 ]]; then # ? = 63
                # Provide option help text.
                local i
                for ((i = 0; i < ${#compgen_options[@]}; i++)); do
                    local opt="${compgen_options[i]}"
                    compgen_options[i]="${opt}: ${options[$opt]}"
                done
            fi

            COMPREPLY+=( "${compgen_options[@]}" )
        fi
    fi
}

complete -F _tmux::completion tmux
