#!/usr/bin/env bash
# migrate-secrets-add-host-suffix.sh
#
# One-shot migration: rename the legacy single-host entries inside
# secrets.yaml to a per-host suffixed form, so multiple darwin hosts can
# share the same encrypted secrets file without key collisions.
#
# Renames:
#   nix-serve-priv-key        -> nix-serve-priv-key-<suffix>
#   tailscale-authkey         -> tailscale-authkey-<suffix>
#   it-admin-password-hash    -> it-admin-password-hash-<suffix>
#
# Idempotent: re-running after migration is a no-op because the legacy
# names are already gone. Safe to abort mid-run; the only mutation is
# `sops --set` followed by `sops unset` per key.
#
# Usage:
#   scripts/migrate-secrets-add-host-suffix.sh <suffix>
#
# Example (on pane):
#   scripts/migrate-secrets-add-host-suffix.sh pane

set -euo pipefail

REPO="${HOME}/.config/lockbox-home"
LOCAL_NIX="${REPO}/darwin/local.nix"
[[ -f "$LOCAL_NIX" ]] || { echo "[error] ${LOCAL_NIX} not found" >&2; exit 1; }

if [[ $# -ne 1 ]]; then
  echo "usage: $(basename "$0") <suffix>" >&2
  echo "  example: $(basename "$0") pane" >&2
  exit 2
fi
SUFFIX="$1"
[[ "$SUFFIX" =~ ^[a-zA-Z0-9_-]+$ ]] \
  || { echo "[error] suffix '${SUFFIX}' contains invalid characters" >&2; exit 1; }

read_local_path() {
  nix eval --impure --raw --expr "toString (import ${LOCAL_NIX}).$1" 2>/dev/null
}

SECRETS_DIR="$(read_local_path secretsDir)"
[[ -n "$SECRETS_DIR" && -d "$SECRETS_DIR" ]] \
  || { echo "[error] secretsDir from ${LOCAL_NIX} not a directory" >&2; exit 1; }

SOPS_POLICY="${SECRETS_DIR}/.sops.yaml"
SECRETS_FILE="${SECRETS_DIR}/secrets.yaml"
[[ -f "$SOPS_POLICY"  ]] || { echo "[error] $SOPS_POLICY not found" >&2; exit 1; }
[[ -f "$SECRETS_FILE" ]] || { echo "[error] $SECRETS_FILE not found" >&2; exit 1; }

log() { printf '\033[1;34m[migrate]\033[0m %s\n' "$*"; }

NIX_RUN=(nix shell --quiet nixpkgs#sops --command)

LEGACY_KEYS=(nix-serve-priv-key tailscale-authkey it-admin-password-hash)

# python3 is available on macOS by default; used to JSON-encode arbitrary
# decrypted values for `sops --set`. Avoids YAML/shell quoting pitfalls.
json_encode() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

decrypt_field() {
  "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --decrypt \
      --extract "[\"${1}\"]" "$SECRETS_FILE" 2>/dev/null
}

has_field() {
  decrypt_field "$1" >/dev/null 2>&1
}

set_field() {
  local key="$1" val="$2"
  local jval
  jval="$(printf '%s' "$val" | json_encode)"
  "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --set \
      "[\"${key}\"] ${jval}" "$SECRETS_FILE"
}

unset_field() {
  "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" unset \
      "$SECRETS_FILE" "[\"${1}\"]"
}

for LEGACY in "${LEGACY_KEYS[@]}"; do
  NEW="${LEGACY}-${SUFFIX}"

  if has_field "$NEW"; then
    log "${NEW} already present"
    if has_field "$LEGACY"; then
      log "  legacy ${LEGACY} also present; removing"
      unset_field "$LEGACY"
    fi
    continue
  fi

  if ! has_field "$LEGACY"; then
    log "${LEGACY} not present; nothing to migrate"
    continue
  fi

  log "${LEGACY} -> ${NEW}"
  val="$(decrypt_field "$LEGACY")"
  set_field "$NEW" "$val"
  unset val
  unset_field "$LEGACY"
done

log "done. Inspect with:"
log "  sops --config ${SOPS_POLICY} --decrypt ${SECRETS_FILE} | head"
