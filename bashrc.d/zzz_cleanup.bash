#!/usr/bin/env bash

# shellcheck disable=SC2154
for var in "${__bashrc_cleanup[@]}"; do
    unset "${var}"
done

unset var
unset __bashrc_cleanup
