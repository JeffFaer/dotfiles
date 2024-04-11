#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

(( $# != 1 )) && exit 1
session_name="$1"

# Bash needs HISTTIMEFORMAT as a shell variable, not an environment variable.
HISTTIMEFORMAT="${HISTTIMEFORMAT:-}"
history -s "# tmux client-detached ${session_name}"
history -a
