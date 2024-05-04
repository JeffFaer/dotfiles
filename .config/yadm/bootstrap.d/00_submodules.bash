#!/usr/bin/env bash

set -euo pipefail
[[ -v DEBUG ]] && set -x

echo "Init submodules"

# Because Git submodule commands cannot operate without a work tree, they must
# the top level directory of the repo.
cd "$(git rev-parse --show-toplevel)"
git submodule update --recursive --init
