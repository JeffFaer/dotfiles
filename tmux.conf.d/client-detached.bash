#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

(( $# != 1 )) && exit 1
session_name="$1"

set -o history
history -s "# tmux client-detached ${session_name}"
