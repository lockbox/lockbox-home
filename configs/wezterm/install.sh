#!/usr/bin/env bash
# Imports:
# - CONFIG_DIR
#
# installs a symlink to the wezterm configuration file at `./wezterm.lua`
#
# This script:
# - creates the config directory if it does not exist
# - Removes the old config file if it does exist
# - Symlinks the config file to `./wezterm.lua`

# Make "$HOME/.config/wezterm" if it does not
# exist
wezterm_CFG_DIR="$HOME/.config/wezterm"
if [ ! -d "$wezterm_CFG_DIR" ]; then
    mkdir -p "$wezterm_CFG_DIR"
fi

# Remove the old config file if it does exist
wezterm_CFG_FILE="$wezterm_CFG_DIR/wezterm.lua"
if [ -f "$wezterm_CFG_FILE" ]; then
    rm -rf "$wezterm_CFG_FILE"
fi

# install a symlink to `./wezterm.lua`
CFG_FILE="$CONFIG_DIR/wezterm/wezterm.lua"
ln -sf "$CFG_FILE" "$wezterm_CFG_FILE"