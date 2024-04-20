#!/usr/bin/env bash

if [[ -z "${TMUX}" ]]; then
    return
fi

bashrc::tmux_preexec() {
    # shellcheck disable=SC2046
    eval $(tmux show-environment -s)
}
preexec_functions+=("bashrc::tmux_preexec")

if [[ -n "$(command -v tmux-vcs-sync)" ]]; then
    bashrc::tvs_preexec() {
        [[ -n "${STOP_TVS}" ]] && return
        if ! git ls-files --error-unmatch &>/dev/null; then
            return
        fi
        if tmux-vcs-sync update --fail-noop; then
            # This is being executed in a pre-exec, so the command being
            # executed is already in history. Let's rewrite history to include
            # the tmux-vcs-sync call.
            local last_cmd=()
            eval "$(dotfiles::shlex last_cmd "$(fc -n -l -0)")"
            history -d -1
            history -s tmux-vcs-sync update
            history -s "${last_cmd[@]}"
        fi
    }
    preexec_functions+=("bashrc::tvs_preexec")
fi
