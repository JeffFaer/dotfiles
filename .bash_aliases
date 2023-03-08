# keep-sorted start
alias cp="cp -i"
alias du="du -h"
alias from-clipboard="xclip -o"
alias gcc="gcc -ansi -Wall -g -O0 -Wwrite-strings -Wshadow -pedantic-errors -fstack-protector-all"
alias mv="mv -i"
alias to-clipboard="xclip -sel clip"
alias ulimit="ulimit -S"
alias vim="vim --servername vim"
# keep-sorted end

if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi

    alias grep='grep --color=auto'
    alias ls="ls --color=auto"
fi

alias_append ls "-h"
