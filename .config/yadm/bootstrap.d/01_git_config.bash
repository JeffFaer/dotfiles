#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

yadm gitconfig bash.showUntrackedFiles "$(yadm gitconfig status.showUntrackedFiles)"
