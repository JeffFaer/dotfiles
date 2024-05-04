#!/usr/bin/env bash

set -euo pipefail
[[ -v DEBUG ]] && set -x

(( $# != 2 )) && exit 1
client_last_session="$1"
session_name="$2"

# Bash needs HISTTIMEFORMAT as a shell variable, not an environment variable.
HISTTIMEFORMAT="${HISTTIMEFORMAT:-}"
if [[ -z "${client_last_session}" ]]; then
    history -s "# tmux client-attached ${session_name}"
else
    history -s "# tmux client-session-changed ${client_last_session} -> ${session_name}"
fi
history -a
