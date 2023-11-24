#!/usr/bin/env bash
# IMPORTS:
# - CONFIG_DIR
#
# install script for zellij config.kdl, a brute-force approach.
#
# This script:
# - creates the config directory if it does not exist
# - Removes the old config file if it does exist
# - Symlinks the config file to `./config.kdl`

# Make "$HOME/.config/zellij" if it does not
# exist
ZELLIJ_CFG_DIR="$HOME/.config/zellij"
if [ ! -d "$ZELLIJ_CFG_DIR" ]; then
    mkdir -p "$ZELLIJ_CFG_DIR"
fi

# Remove the old config file if it does exist
ZELLIJ_CFG_FILE="$ZELLIJ_CFG_DIR/config.kdl"
if [ -f "$ZELLIJ_CFG_FILE" ]; then
    rm -rf "$ZELLIJ_CFG_FILE"
fi

# install a symlink to `./config.kdl`
CFG_FILE="$CONFIG_DIR/zellij/config.kdl"
ln -sf "$CFG_FILE" "$ZELLIJ_CFG_FILE"