#!/usr/bin/env bash

set -euo pipefail
[[ -v DEBUG ]] && set -x

cd "$(git rev-parse --show-toplevel)"
if [[ -z "$(git config --get status.showUntrackedFiles)" ]]; then
    git config status.showUntrackedFiles no
fi
git config bash.showUntrackedFiles "$(git config status.showUntrackedFiles)"
