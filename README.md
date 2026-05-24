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

## Bootstrap on a fresh clone

This repo intentionally does not commit `darwin/local.nix`, nor any
encrypted secret material. Set up per host:

1. **Clone the sibling secrets repo alongside this one:**
   ```bash
   git clone ssh://git@git.struct.foo:2222/lockbox/secrets.git ~/.config/lockbox-secrets
   ```

2. **Configure host-specific values.** Copy the example overlay and fill it in:
   ```bash
   cp darwin/local.nix.example darwin/local.nix
   $EDITOR darwin/local.nix
   ```
   Set `cacheHost`, `cacheIP`, `cacheURL`, `cachePubKey` for your remote
   binary cache (reached over Tailscale, MagicDNS resolved). Set
   `localKeyName` to a unique identifier for this host's nix-serve key
   (e.g. `${hostname}-nix-serve-1`). Set `secretsDir` to the absolute
   path of the secrets clone (Nix path literal — no quotes). Leave
   `localPubKey` at its placeholder for now; it gets filled in after step 4.

3. **Bootstrap sops + first rebuild:**
   ```bash
   scripts/bootstrap-sops-builder.sh
   ```
   This generates an age key at `~/.config/sops/age/keys.txt`, adds this
   host's recipient to `${secretsDir}/.sops.yaml`, encrypts (or
   re-encrypts) tailscale + it-admin material into
   `${secretsDir}/secrets.yaml`, commits inside the secrets repo, then
   runs `darwin-rebuild switch --impure` and restarts the linux-builder VM.

4. **Generate this host's nix-serve signing key:**
   ```bash
   scripts/bootstrap-nix-serve-key.sh
   ```
   Generates an ed25519 keypair, encrypts the private key into
   `${secretsDir}/secrets.yaml` under `nix-serve-priv-key`, commits
   inside the secrets repo, and prints the public key.

5. **Paste the printed pubkey** into `darwin/local.nix` as `localPubKey`,
   then rebuild so the new trusted-public-keys entry takes effect:
   ```bash
   darwin-rebuild switch --impure --flake .
   ```

6. **Push the secrets repo** when ready to share with other hosts:
   ```bash
   git -C ~/.config/lockbox-secrets push
   ```
