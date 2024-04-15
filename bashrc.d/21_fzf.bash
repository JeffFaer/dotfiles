#!/usr/bin/env bash

if [[ ! -f ~/.fzf.bash ]]; then
    return
fi

export FZF_DEFAULT_OPTS='--bind="ctrl-y:execute-silent(cat {+f} | xclip -sel clip)"'
# `cut -f3-` so that we only get the command part of the history entry. See
# bashrc::fzf_history in this file for more details.
export FZF_CTRL_R_OPTS='--bind="ctrl-y:execute-silent(cut -f3- {+f} | xclip -sel clip)"'
source ~/.fzf.bash

export FZF_COMPLETION_AUTO_COMMON_PREFIX=true
export FZF_COMPLETION_AUTO_COMMON_PREFIX_PART=true
source ~/src/fzf-tab-completion/bash/fzf-bash-completion.sh
bind -x '"\t": fzf_bash_completion'

# I want duplicate history entries in my HISTFILE, but I don't want to see them
# in fzf completion. I also would like to see the date of the history entry in
# my HISTTIMEFORMAT.
# This is cribbed from `fzf --bash`.
bashrc::fzf_history_keybind() {
    # Each history line is <entry number>\t<timestamp>\t<command>.
    # Tabs are our delimiter. We'd prefer to search in the command instead of
    # either other field. When I press enter, I only want to receive the
    # command.
    local opts=(
        --height="${FZF_TMUX_HEIGHT:-40%}"
        --bind='"ctrl-z:ignore"'
        "${FZF_DEFAULT_OPTS-}"
        --scheme=history
        --delimiter='\\t'
        --nth="3..,.."
        --bind='"ctrl-r:toggle-sort"'
        --bind='"enter:become(echo {3..})"'
        "${FZF_CTRL_R_OPTS-}"
        +m
        --read0
    )

    READLINE_LINE=$(ORS="\\0" bashrc::fzf_history \
        | FZF_DEFAULT_OPTS="${opts[*]}" $(__fzfcmd) --query "$READLINE_LINE"
    ) || return
    if [[ -z "$READLINE_POINT" ]]; then
        echo "$READLINE_LINE"
    else
        READLINE_POINT=0x7fffffff
    fi
}

bashrc::fzf_history() {
    # Attempt to differentiate between commands that spanned multiple lines and
    # separate history entries.
    # For instance, if I ran a command:
    #
    # $ echo "foo \
    # #456 \
    # 123 bar"
    #
    # That'll show up in HISTFILE as
    # #455
    # 122 echo "foo \
    # #456
    # 123 bar"
    #
    # which looks like it could be two separate history entries.
    local rand="${RANDOM}"
    local tab=$'\t'
    local ORS="${ORS:-"\\n"}"
    HISTTIMEFORMAT="${rand}${tab}%s${tab}" history | tac | awk "
        # Do some manual line parsing so that the command is copied exactly
        # how it is in history, weird spacing and all.
        BEGIN { FS=\"\n\" ; OFS=\"\t\" ; ORS=\"${ORS}\" }
        function Print(n, ts, cmd) {
            if (!cmd) {
                return
            }
            # Remove leading and trailing whitespace before deduplicating.
            key=cmd
            gsub(/^[ \t]+|[ \t]+$/, \"\", key)
            if (seen[key]++) {
                return
            }
            ts=strftime(\"${HISTTIMEFORMAT% *}\", ts)
            print n, ts, cmd
        }
        /^[ \t]*[0-9]+[ \t]+${rand}\t[0-9]+\t/ {
            line=\$0

            if (!match(line, /^[ \t]*[0-9]+/)) { exit 1 }
            n=substr(line,RSTART,RLENGTH)
            line=substr(line, RSTART+RLENGTH)

            match(line, /^[ \t]+${rand}\t/)
            line=substr(line, RSTART+RLENGTH)

            if (match(line, /^[0-9]+\t/)) {
                ts=substr(line,RSTART,RLENGTH-1)
                line=substr(line, RSTART+RLENGTH)
            }

            if (cmd) {
                # multi-line command.
                cmd=line RS cmd
            } else {
                cmd=line
            }
            Print(n, ts, cmd)
            n=ts=cmd=\"\"
            next
        }
        {
            if (n) {
                Print(n, ts, cmd)
                n=ts=cmd=\"\"
            }
            if (cmd) {
                # multi-line command.
                cmd=\$0 RS cmd
            } else {
                cmd=\$0
            }
        }
        END { Print(n, ts, cmd) }"
}

bind -m emacs-standard -x '"\C-r": bashrc::fzf_history_keybind'
bind -m vi-command -x '"\C-r": bashrc::fzf_history_keybind'
bind -m vi-insert -x '"\C-r": bashrc::fzf_history_keybind'
