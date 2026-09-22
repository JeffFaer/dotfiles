#!/usr/bin/env bash

set -euo pipefail
[[ -v DEBUG ]] && set -x

# $1 = previous HEAD
# $2 = new HEAD
# $3 = flag (1 = branch checkout, 0 = file checkout)

remote=""
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [[ -n "${branch}" ]]; then
    remote=( "$(git config --get "branch.${branch}.remote" 2>/dev/null || true)" )
fi
if [[ -z "${remote}" ]]; then
    upstream="$(git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null || true)"
    if [[ -n "${upstream}" ]]; then
        remote="${upstream%%/*}"
    fi
fi

if [[ -n "${remote}" ]]; then
    remotes=( "${remote}" )
else
    mapfile -t remotes < <(git remote || true)
    if (( ${#remotes[@]} > 1 )); then
        echo "Couldn't determine current remote. Defaulting to all remotes."
    fi
fi

for remote in "${remotes[@]}"; do
    refspecs=()
    mapfile -t refspecs < <(git config --get-all "remote.${remote}.fetch" || true)

    for r in "${refspecs[@]}"; do
        # Only target explicit branch refspecs (ignore wildcard refspecs containing '*')
        if [[ "${r}" == *"*"* ]]; then
            continue
        fi

        # Extract local branch name (e.g. "+refs/heads/foo:refs/remotes/origin/foo" -> "foo")
        pattern="${r%%:*}"
        branch="${pattern#+refs/heads/}"

        # If the local branch no longer exists, remove its refspec entry
        if ! git show-ref --verify --quiet "refs/heads/${branch}"; then
            escaped="$(sed 's/[^^a-zA-Z0-9_]/\\&/g' <<< "${r}")"
            git config --unset "remote.${remote}.fetch" "^${escaped}$"
            echo "Pruned stale refspec for deleted branch: ${branch}"
        fi
    done
done
