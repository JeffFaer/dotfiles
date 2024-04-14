if [[ "$(type -t dotfiles::user_permission)" != function ]]; then
    source "${HOME}/bashrc.d/01_functions.bash"
fi

# Determines if particularly expensive bootstrapping code should be run.
bootstrap::should_run() {
    if ! [[ "${BOOTSTRAP:-}" == *all* || "${BOOTSTRAP:-}" == *"$1"* ]]; then
        echo "*** Re-run with BOOTSTRAP=$1 if you want to install it. ***"
        return 1
    fi
}

# Try to install any packages that are not already installed.
bootstrap::install_packages() {
    local install=()
    local package
    for package in "$@"; do
        if ! bootstrap::_already_installed "${package}"; then
            install+=( "${package}" )
        fi
    done

    if [[ ${#install[@]} -eq 0 ]]; then
        return
    fi

    local prompt="Would you like to install: "
    prompt+="${install[*]}?"
    if dotfiles::user_permission "${prompt}"; then
        echo "Installing ${install[*]}"
        sudo apt-get update -qq
        sudo apt-get install "${install[@]}" -yqq
    else
        return 1
    fi
}

# Determines if the given package is installed.
bootstrap::_already_installed() {
    local package="$1"
    dpkg -s "${package}" |& grep -qP '^Status.+(?<!-)installed'
}
