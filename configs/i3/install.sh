#!/usr/bin/env bash
# Imports:
# - CONFIG_DIR
#
# installs a symlink to the i3 configuration file at `./config`
#
# This script:
# - creates the config directory if it does not exist
# - Removes the old config file if it does exist
# - Symlinks the config file to `./config`

# Make "$HOME/.config/i3" if it does not
# exist
I3_CFG_DIR="$HOME/.config/i3"
if [ ! -d "$I3_CFG_DIR" ]; then
    mkdir -p "$I3_CFG_DIR"
fi

# Remove the old config file if it does exist
I3_CFG_FILE="$I3_CFG_DIR/config"
if [ -f "$I3_CFG_FILE" ]; then
    rm -rf "$I3_CFG_FILE"
fi

# install a symlink to `./config`
CFG_FILE="$CONFIG_DIR/i3/config"
ln -sf "$CFG_FILE" "$I3_CFG_FILE"
