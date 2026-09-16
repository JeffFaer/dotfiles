#!/usr/bin/env bash

set -euo pipefail
[[ -v DEBUG ]] && set -x

dir="$(dirname "${BASH_SOURCE[0]}")"
mapfile -t hooks < <(git help hooks | col -b | sed -nre 's/^   ([0-9a-z-]+)$/\1/p')
for hook in "${hooks[@]}"; do
    if [[ -e "${dir}/${hook}" ]]; then
        continue
    fi

    ln -s "${dir}/run-local-hook" "${dir}/${hook}"
done
