# home config

Cross-platform home environment configuration supporting both Linux (GNU Guix Home)
and macOS (nix-darwin + home-manager). Shared dotfiles in `configs/` and `profiles/`
serve as the single source of truth across platforms.

## Linux (Guix Home)

This repo is a Guix home configuration that is starting to get less sprawled out
and slowly transitioning over to use more of the modern [Guix Home Services](https://guix.gnu.org/manual/devel/en/html_node/Home-Services.html).

This has only been tested on foreign distros (namely Gentoo and Fedora) as I only
run Guix the distribution on remote hosts.

### Rebuilding

```
scripts/reconfigure
```

## macOS (nix-darwin + home-manager)

### Prerequisites

- [Determinate Nix Installer](https://zero-to-nix.com/start/install)

### First-time setup

```bash
# Clone this repo
git clone https://github.com/lockbox/lockbox-home.git ~/.config/lockbox-home

# Build and activate
darwin-rebuild switch --flake ~/.config/lockbox-home

# Optional: install Doom Emacs
scripts/install-doom-emacs
~/.config/emacs/bin/doom install
```

### Rebuilding after changes

```
scripts/darwin-switch
```

### What's managed

- **System** (nix-darwin): hostname, fonts, nix settings, TouchID sudo
- **User** (home-manager): packages, bash, git, GPG/YubiKey, starship, zellij,
  direnv, zoxide, Emacs (bleeding-edge with native comp), Doom Emacs config
