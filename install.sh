#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUG:-}" ]] && set -x

source="$(dirname "${BASH_SOURCE[0]}")"
target="${PWD}"

mv "${source}/.git" "${target}/"
rm -r "${source}"

# Restore deleted files.
# deleted files exist in git, but not on the local FS, so they should be safe to
# restore.
mapfile -t deleted_files < <(git ls-files --deleted)

if [[ "${#deleted_files[@]}" -gt 0 ]]; then
    git restore "${deleted_files[@]}"
fi

# Bootstrap with yadm.
git submodule update --init --recursive -- src/yadm
./bin/yadm bootstrap

if ! git diff --quiet; then
    echo
    echo "There are unresolved conflicts. Run git diff to see them."
    exit 1
fi
