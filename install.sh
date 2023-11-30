#!/usr/bin/env bash

# make sure nix is installed
if command -v nix >/dev/null 2>&1; then
    echo "Installing dots.."
else
    echo "[ERROR] nix not installed"
    exit 1
fi

nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --add https://github.com/guibou/nixGL/archive/main.tar.gz
nix-channel --update
nix-env -iA nixgl.auto.nixGLDefault
nix-shell '<home-manager>' -A install
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes
