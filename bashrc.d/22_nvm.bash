#!/usr/bin/env bash

if [[ -z "$(type -t nvm 2>/dev/null)" ]]; then
    return
fi

bashrc::nvm_precmd() {
    if [[ "${PWD}" == "${_NVM_PREV_PWD}" ]]; then
        return
    fi
    _NVM_PREV_PWD="${PWD}"

    local nvmrc="$(nvm_find_nvmrc)"
    if [[ -n "${nvmrc}" ]]; then
        if [[ "${nvmrc}" == "${_NVM_PREV_NVMRC}" ]]; then
            return
        fi
        _NVM_PREV_NVMRC="${nvmrc}"
        _NVM_AUTOLOAD_ACTIVE=1

        if nvm version "$(cat "${nvmrc}")" &>/dev/null; then
            nvm use
        else
            nvm install
        fi
    elif ((_NVM_AUTOLOAD_ACTIVE)); then
        _NVM_AUTOLOAD_ACTIVE=0
        _NVM_PREV_NVMRC=
        nvm deactivate
    fi
}
precmd_functions+=("bashrc::nvm_precmd")
