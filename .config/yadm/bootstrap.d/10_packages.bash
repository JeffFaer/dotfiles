#!/usr/bin/env bash

set -euo pipefail
[[ -v DEBUG ]] && set -x

source "$(dirname "${BASH_SOURCE[0]}")/bootstrap_lib.bash"

packages=( xclip )
if [[ -n "${DISPLAY:-}" ]]; then
    packages+=( libglib2.0-bin meld )
fi
bootstrap::install_packages "${packages[@]}"
