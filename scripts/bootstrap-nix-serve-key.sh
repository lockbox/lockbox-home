#!/usr/bin/env bash
# bootstrap-nix-serve-key.sh
#
# Generates an ed25519 nix binary-cache keypair, encrypts the private key
# into ~/.config/lockbox-home/secrets.yaml under the field
# `nix-serve-priv-key`, and prints the public key string for the operator
# to paste into darwin/default.nix.
#
# Idempotent: refuses to overwrite an existing `nix-serve-priv-key` entry
# unless --force is passed. Re-running after rotation requires --force.
#
# Requires: nix, sops (will be fetched via nix shell).

set -euo pipefail

REPO="${HOME}/.config/lockbox-home"
SECRETS_FILE="${REPO}/secrets.yaml"
SOPS_POLICY="${REPO}/.sops.yaml"
KEY_NAME="this-host-nix-serve-1"
FIELD="nix-serve-priv-key"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

log() { printf '\033[1;34m[nix-serve-key]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$SECRETS_FILE" ]] || die "$SECRETS_FILE not found (run bootstrap-sops-builder.sh first)"
[[ -f "$SOPS_POLICY"  ]] || die "$SOPS_POLICY not found"

NIX_RUN=(nix shell --quiet nixpkgs#nix nixpkgs#sops --command)

# Check whether the field already exists in the encrypted document.
if "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --decrypt \
     --extract "[\"${FIELD}\"]" "$SECRETS_FILE" >/dev/null 2>&1; then
  if [[ $FORCE -eq 0 ]]; then
    log "$FIELD already present in $SECRETS_FILE; pass --force to rotate"
    log "deriving public key from existing private key for convenience..."
    TMPDIR_KEY="$(mktemp -d "${TMPDIR:-/tmp}/nix-serve-key.XXXXXX")"
    chmod 700 "$TMPDIR_KEY"
    trap 'rm -rf "$TMPDIR_KEY"' EXIT
    "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --decrypt \
        --extract "[\"${FIELD}\"]" "$SECRETS_FILE" > "$TMPDIR_KEY/priv"
    PUB="$(cat "$TMPDIR_KEY/priv" | "${NIX_RUN[@]}" nix key convert-secret-to-public)"
    log "public key: $PUB"
    exit 0
  fi
  log "--force: rotating $FIELD"
fi

TMPDIR_KEY="$(mktemp -d "${TMPDIR:-/tmp}/nix-serve-key.XXXXXX")"
chmod 700 "$TMPDIR_KEY"
trap 'rm -rf "$TMPDIR_KEY"' EXIT

log "generating keypair ($KEY_NAME)"
"${NIX_RUN[@]}" nix-store --generate-binary-cache-key \
    "$KEY_NAME" "$TMPDIR_KEY/priv" "$TMPDIR_KEY/pub"

PRIV_CONTENT="$(cat "$TMPDIR_KEY/priv")"
PUB_CONTENT="$(cat "$TMPDIR_KEY/pub")"

log "encrypting private key into $SECRETS_FILE under $FIELD"
PRIV_JSON="$(printf '%s' "$PRIV_CONTENT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
"${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --set \
    "[\"${FIELD}\"] ${PRIV_JSON}" "$SECRETS_FILE"

# Stage so Nix can see the change in the in-memory git snapshot.
( cd "$REPO" && git add secrets.yaml )

log "public key (paste into darwin/default.nix):"
echo
echo "  $PUB_CONTENT"
echo
log "done. Next: update VM trusted-public-keys list, then darwin-rebuild switch --impure."
