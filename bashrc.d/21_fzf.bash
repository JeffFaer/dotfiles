#!/usr/bin/env bash

export FZF_DEFAULT_OPTS='--bind "ctrl-y:execute-silent(cut -f 3- {+f} | xclip -sel clip)"'
[[ -f ~/.fzf.bash ]] && source ~/.fzf.bash

export FZF_COMPLETION_AUTO_COMMON_PREFIX=true
export FZF_COMPLETION_AUTO_COMMON_PREFIX_PART=true
source ~/src/fzf-tab-completion/bash/fzf-bash-completion.sh
bind -x '"\t": fzf_bash_completion'

# I want duplicate history entries in my HISTFILE, but I don't want to see them
# in fzf completion.
# This is cribbed from `fzf --bash`.
bashrc::fzf_history() {
    local output opts
    opts="--height ${FZF_TMUX_HEIGHT:-40%} --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} -n2..,.. --scheme=history --bind=ctrl-r:toggle-sort ${FZF_CTRL_R_OPTS-} +m"
    output=$(HISTTIMEFORMAT='%s ' history | tac | awk "
        # Do some manual line parsing so that the command is copied exactly
        # how it is in history, weird spacing and all.
        BEGIN { FS=\"\n\" ; OFS=\"\t\"}
        {
            line=\$0

            if (!match(line, /[0-9]+/)) { print \"Unexpected line\", line > /dev/stderr; exit 1 }
            n=substr(line,RSTART,RLENGTH)
            line=substr(line, RSTART+RLENGTH)

            if (!match(line, /[0-9]+ /)) { print \"Unexpected line\", line > /dev/stderr; exit 1 }
            ts=substr(line,RSTART,RLENGTH-1)
            line=substr(line, RSTART+RLENGTH)

            cmd=line
            if (!seen[cmd]++) {
                print n, strftime(\"${HISTTIMEFORMAT% *}\", ts), cmd
            }
        }" |
        FZF_DEFAULT_OPTS="$opts" $(__fzfcmd) --query "$READLINE_LINE"
    ) || return
    READLINE_LINE=${output#*$'\t'}
    if [[ -z "$READLINE_POINT" ]]; then
      echo "$READLINE_LINE"
    else
      READLINE_POINT=0x7fffffff
    fi
}

bind -m emacs-standard -x '"\C-r": bashrc::fzf_history'
bind -m vi-command -x '"\C-r": bashrc::fzf_history'
bind -m vi-insert -x '"\C-r": bashrc::fzf_history'
