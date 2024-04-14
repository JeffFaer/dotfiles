#!/usr/bin/env bash

export FZF_DEFAULT_OPTS='--bind "ctrl-y:execute-silent(cat {+f} | cut -f 2- | xclip -sel clip)"'
[[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
