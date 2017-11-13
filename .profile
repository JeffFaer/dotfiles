# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

if [[ -n $BASH_VERSION && -f $HOME/.bashrc ]]; then
    . "$HOME/.bashrc"
fi

export EDITOR=vim

add_to_path() {
    if [[ -d $1 && :$PATH != *:$1* ]]; then
        PATH="$1:$PATH"
    fi
}
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/bin"
add_to_path "$HOME/scripts"
