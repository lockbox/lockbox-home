#!/usr/bin/env bash
# IMPORTS:
# - CONFIG_DIR
# - addRuntimeEnv
#
# install script for starship, adds an env var
# that points to `./config.toml`
#
# This script:
# - appends an env var to point to our `./config.toml`
addRuntimeEnv "STARSHIP_CONFIG" "$CONFIG_DIR/starship/config.toml"
