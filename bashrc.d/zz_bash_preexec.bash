#!/usr/bin/env bash

if [[ ${#preexec_functions[@]} -eq 0 && ${#precmd_functions[@]} -eq 0 ]]; then
    return
fi

if [[ -n "${__bashrc_instrument_preexec}" ]]; then 
  old_preexec_functions=( "${preexec_functions[@]}" )
  old_precmd_functions=( "${precmd_functions[@]}" )
  preexec_functions=()
  precmd_functions=()
  __bashrc_cleanup+=( "fn" )
  for fn in "${old_preexec_functions[@]}"; do
    eval "instrumented_${fn}() { TIMEFORMAT=\"${fn} \$@: %3R\" && time \"${fn}\" \"\$@\"; }"
    preexec_functions+=( "instrumented_${fn}" )
  done
  for fn in "${old_precmd_functions[@]}"; do
    eval "instrumented_${fn}() { TIMEFORMAT=\"${fn} \$@: %3R\" && time \"${fn}\" \"\$@\"; }"
    precmd_functions+=( "instrumented_${fn}" )
  done

  unset old_preexec_functions
  unset old_precmd_functions
  unset fn
fi

source ~/src/bash-preexec/bash-preexec.sh
