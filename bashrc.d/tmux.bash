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
        if ! git ls-files --error-unmatch &>/dev/null; then
            return
        fi
        if tmux-vcs-sync update --fail-noop; then
            history -s tmux-vcs-sync update
        fi
    }
    preexec_functions+=("bashrc::tvs_preexec")
fi
