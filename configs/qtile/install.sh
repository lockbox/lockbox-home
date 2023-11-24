#!/usr/bin/env bash
# Imports:
# - CONFIG_DIR
#
# installs a symlink to the qtile configuration file at `./config.py`
#
# This script:
# - creates the config directory if it does not exist
# - Removes the old config file if it does exist
# - Symlinks the config file to `./config.py`

# Make "$HOME/.config/qtile" if it does not
# exist
QTILE_CFG_DIR="$HOME/.config/qtile"
if [ ! -d "$QTILE_CFG_DIR" ]; then
    mkdir -p "$QTILE_CFG_DIR"
fi

# Remove the old config file if it does exist
QTILE_CFG_FILE="$QTILE_CFG_DIR/config.py"
if [ -f "$QTILE_CFG_FILE" ]; then
    rm -rf "$QTILE_CFG_FILE"
fi

# install a symlink to `./config.py`
CFG_FILE="$CONFIG_DIR/qtile/config.py"
ln -sf "$CFG_FILE" "$QTILE_CFG_FILE"