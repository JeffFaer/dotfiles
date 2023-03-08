#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

git config bash.showUntrackedFiles "$(git config status.showUntrackedFiles)"
