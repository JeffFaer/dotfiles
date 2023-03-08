#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

git submodule update --init --recursive -- src/yadm
./bin/yadm bootstrap
