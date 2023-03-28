#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

if [[ -z "$(git config --get status.showUntrackedFiles)" ]]; then
    git config status.showUntrackedFiles no
fi
git config bash.showUntrackedFiles "$(git config status.showUntrackedFiles)"
