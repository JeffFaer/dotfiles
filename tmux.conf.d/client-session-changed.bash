#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

(( $# != 2 )) && exit 1
client_last_session="$1"
session_name="$2"

set -o history

if [[ -z "${client_last_session}" ]]; then
    history -s "# tmux client-attached ${session_name}"
else
    history -s "# tmux client-session-changed ${client_last_session} -> ${session_name}"
fi
