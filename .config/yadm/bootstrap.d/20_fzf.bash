#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

~/src/fzf/install --no-zsh --no-fish --completion --key-bindings --no-update-rc
