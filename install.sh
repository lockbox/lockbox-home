#!/usr/bin/env bash

# path to `.dotfiles`
# copied from: https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONFIG_DIR="$ROOT_DIR/configs"

# appends the bash hook to bashrc
function addBashHook() {
    echo ". $ROOT_DIR/bashrc_ext" >> "$HOME/.bashrc"
}

# runs the configuration install script for all available
# configs
function installConfigs() {
    for d in "$CONFIG_DIR"/*/; do
        local D_INSTALL="$d/install.sh" # install script

        if [ -f "$D_INSTALL" ]; then
            . "$D_INSTALL"
            true;
        fi
    done

}

# Takes a dest VAR and a value to set during runtime
function addRuntimeEnv() {
    local VARIABLE="$1"
    local VALUE="$2"
    local ENV_FILE="$ROOT_DIR/env_ext"

    echo "export $VARIABLE=$VALUE" >> "$ENV_FILE"
}

function main() {
    installConfigs
}


#####
# Exports for children to use
#####
export ROOT_DIR
export CONFIG_DIR
export addRuntimeEnv

main