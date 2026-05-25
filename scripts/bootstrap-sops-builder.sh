#!/usr/bin/env bash
# bootstrap-sops-builder.sh
#
# Bootstraps sops-nix + Tailscale auth for the Determinate linux-builder VM:
#   1. Provisions an age key at ~/.config/sops/age/keys.txt (standard sops
#      CLI lookup path, outside the dotfiles repo).
#   2. Writes ~/.config/lockbox-home/.sops.yaml with that recipient.
#   3. Prompts for a Tailscale pre-auth key and an it-admin password,
#      hashes the password with mkpasswd, and encrypts both into
#      ~/.config/lockbox-home/secrets.yaml via sops.
#   4. Updates the flake lock for sops-nix.
#   5. darwin-rebuild switch --impure (the VM config references the age
#      key by absolute path outside the flake, requiring impure eval).
#   6. Restarts the linux-builder VM and verifies cache reachability.
#
# Idempotent: existing age key / .sops.yaml / secrets.yaml are reused unless
# --force is passed. Re-running after a key rotation requires --force.
# Empty / non-sops-formatted secrets.yaml files are regenerated automatically.
#
# Requires: nix (Determinate), darwin-rebuild, sudo.

set -euo pipefail

REPO="${HOME}/.config/lockbox-home"
LOCAL_NIX="${REPO}/darwin/local.nix"
[[ -f "$LOCAL_NIX" ]] || { echo "[error] ${LOCAL_NIX} not found; copy darwin/local.nix.example and fill it in before running this script" >&2; exit 1; }

read_local() {
  nix eval --impure --raw --expr "(import ${LOCAL_NIX}).$1" 2>/dev/null
}

# secretsDir is a Nix path literal; toString returns its original filesystem
# path without triggering the path-to-store-copy coercion that --raw applies
# to bare path values.
read_local_path() {
  nix eval --impure --raw --expr "toString (import ${LOCAL_NIX}).$1" 2>/dev/null
}

SECRETS_DIR="$(read_local_path secretsDir)"
[[ -n "$SECRETS_DIR" && -d "$SECRETS_DIR" ]] \
  || { echo "[error] secretsDir from ${LOCAL_NIX} not a directory: ${SECRETS_DIR:-<empty>}" >&2; exit 1; }
[[ -d "${SECRETS_DIR}/.git" ]] \
  || { echo "[error] ${SECRETS_DIR} is not a git repository; clone ssh://git@git.struct.foo:2222/lockbox/secrets.git there first" >&2; exit 1; }

CACHE_HOST="$(read_local cacheHost)"
[[ -n "$CACHE_HOST" ]] || { echo "[error] cacheHost in ${LOCAL_NIX} is empty" >&2; exit 1; }

# Per-host secret field names live in local.nix so the same script works
# on every host: foo-mac-mini's local.nix encrypts under
# `tailscale-authkey-foo-mac-mini` while pane uses `-pane`. The shared
# secrets.yaml ends up with one entry per host per secret type.
TS_FIELD="$(read_local tailscaleAuthkeySecret)"
IT_FIELD="$(read_local itAdminPasswordHashSecret)"
[[ -n "$TS_FIELD" ]] || { echo "[error] tailscaleAuthkeySecret in ${LOCAL_NIX} is empty" >&2; exit 1; }
[[ -n "$IT_FIELD" ]] || { echo "[error] itAdminPasswordHashSecret in ${LOCAL_NIX} is empty" >&2; exit 1; }

AGE_DIR="${HOME}/.config/sops/age"
AGE_KEY="${AGE_DIR}/keys.txt"
SOPS_POLICY="${SECRETS_DIR}/.sops.yaml"
SECRETS_FILE="${SECRETS_DIR}/secrets.yaml"
# Used as a per-block marker in keys.txt (`# host: <HOST_TAG>`) so multiple
# darwin hosts can share one keys.txt file. Independent of the darwin
# flake target name; just needs to be unique per machine.
HOST_TAG="$(hostname -s)"
# Flake target name for the final darwin-rebuild step. Defaults to the
# short hostname (which matches `pane`), can be overridden with --target
# (mac mini's short hostname is `foo-mini` but the flake target is
# `foo-mac-mini`).
DARWIN_TARGET="$HOST_TAG"
VM_SERVICE="system/org.nixos.nixos-vm-based-linux-builder"
CACHE_PROBE_PATH="/nix-cache/nix-cache-info"

FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --target) DARWIN_TARGET="$2"; shift ;;
    --target=*) DARWIN_TARGET="${1#--target=}" ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
  shift
done

log() { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[[ -d "$REPO" ]] || die "repo not found at $REPO"
command -v nix >/dev/null || die "nix not on PATH"
command -v darwin-rebuild >/dev/null || die "darwin-rebuild not on PATH"

# Run age/sops/ssh-to-age out of an ephemeral nix shell so this script
# works even before they land in the home-manager profile.
NIX_RUN=(nix shell --quiet nixpkgs#age nixpkgs#sops nixpkgs#mkpasswd --command)

log "step 1/6: ensure this host has an age key block in $AGE_KEY (tag: $HOST_TAG)"
mkdir -p "$AGE_DIR"
chmod 700 "$AGE_DIR"

# Migration: an earlier version of this script staged the key inside the
# flake at .secrets/age.key (with the CLI path as a symlink). Revert to a
# real file at the standard sops location so nothing secret-adjacent lives
# in the repo.
LEGACY_KEY="${REPO}/.secrets/age.key"
if [[ -L "$AGE_KEY" ]]; then
  target="$(readlink "$AGE_KEY")"
  if [[ "$target" == "$LEGACY_KEY" && -f "$LEGACY_KEY" ]]; then
    log "  migrating key from $LEGACY_KEY back to $AGE_KEY"
    rm "$AGE_KEY"
    mv "$LEGACY_KEY" "$AGE_KEY"
    rmdir "${REPO}/.secrets" 2>/dev/null || true
  fi
fi

# keys.txt may contain multiple host blocks. Each block we control is
# preceded by `# host: <tag>`. Extract this host's recipient by walking
# the file and capturing the `# public key:` that follows our tag.
extract_recipient_for_host() {
  awk -v h="$HOST_TAG" '
    /^# host: / { current = $3; next }
    /^# public key: / && current == h { print $4; exit }
  ' "$AGE_KEY" 2>/dev/null
}

RECIPIENT=""
if [[ -f "$AGE_KEY" ]]; then
  RECIPIENT="$(extract_recipient_for_host)"
fi

if [[ -n "$RECIPIENT" && $FORCE -eq 0 ]]; then
  log "  existing key block for ${HOST_TAG}; recipient: $RECIPIENT"
elif [[ $FORCE -eq 1 && -n "$RECIPIENT" ]]; then
  die "  --force key rotation not implemented for multi-host keys.txt; rotate manually"
else
  # No block for this host yet. Generate a new keypair into a temp file
  # and append (with our host marker) to keys.txt. Preserves any existing
  # blocks that belong to other hosts (e.g. pane's key copied here during
  # mac-mini onboarding).
  TMP_KEY="$(mktemp "${TMPDIR:-/tmp}/age-keygen.XXXXXX")"
  trap 'rm -f "$TMP_KEY"' EXIT
  "${NIX_RUN[@]}" age-keygen -o "$TMP_KEY"
  {
    printf '# host: %s\n' "$HOST_TAG"
    cat "$TMP_KEY"
    printf '\n'
  } >> "$AGE_KEY"
  chmod 600 "$AGE_KEY"
  RECIPIENT="$("${NIX_RUN[@]}" age-keygen -y "$TMP_KEY")"
  rm -f "$TMP_KEY"
  trap - EXIT
  log "  appended new key block for ${HOST_TAG}; recipient: $RECIPIENT"
fi
[[ -n "$RECIPIENT" ]] || die "could not determine recipient for ${HOST_TAG}"

log "step 2/6: ensure $SOPS_POLICY lists $RECIPIENT"
NEEDS_REKEY=0
if [[ ! -f "$SOPS_POLICY" ]]; then
  cat > "$SOPS_POLICY" <<EOF
# Generated by scripts/bootstrap-sops-builder.sh
creation_rules:
  - path_regex: secrets\.yaml$
    age: ${RECIPIENT}
EOF
  log "  wrote new policy"
elif grep -Fq "$RECIPIENT" "$SOPS_POLICY"; then
  log "  recipient already listed; no policy change"
else
  # sops accepts comma-separated recipients on a single `age:` line.
  # Append ours to the existing list. The sed pattern matches the first
  # `age:` field under any creation_rule. Backup file gets removed.
  sed -i.bak -E "s|^([[:space:]]*age:[[:space:]]*[^[:space:]]+.*)$|\1,${RECIPIENT}|" "$SOPS_POLICY"
  rm -f "${SOPS_POLICY}.bak"
  log "  appended recipient to policy; secrets.yaml will be re-keyed"
  NEEDS_REKEY=1
fi

log "step 3/6: ensure this host's entries are encrypted into $SECRETS_FILE"
# Helpers: check / set a single key inside the sops document. `sops --set`
# adds or overwrites the field in place and re-encrypts only that value.
# Avoids the old code path that overwrote the whole file (which would
# clobber other hosts' entries in a shared secrets.yaml).
has_secret() {
  "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --decrypt \
      --extract "[\"${1}\"]" "$SECRETS_FILE" >/dev/null 2>&1
}
set_secret() {
  local key="$1" val="$2"
  local jval
  jval="$(printf '%s' "$val" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
  "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --set \
      "[\"${key}\"] ${jval}" "$SECRETS_FILE"
}

# Initialise secrets.yaml if missing / not a sops document. A placeholder
# key gets encrypted first so subsequent `sops --set` calls have an
# existing document to edit.
if [[ ! -s "$SECRETS_FILE" ]] || ! grep -q '^sops:' "$SECRETS_FILE"; then
  log "  initialising new $SECRETS_FILE"
  TMPDIR_SECRET="$(mktemp -d "${TMPDIR:-/tmp}/sops-bootstrap.XXXXXX")"
  chmod 700 "$TMPDIR_SECRET"
  trap 'rm -rf "$TMPDIR_SECRET"' EXIT
  TMP="$TMPDIR_SECRET/secrets.yaml"
  printf '_init: placeholder\n' > "$TMP"
  "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" --encrypt \
      --input-type yaml --output-type yaml "$TMP" > "$SECRETS_FILE"
  rm -rf "$TMPDIR_SECRET"
  trap - EXIT
fi

needs_ts=1
needs_it=1
if has_secret "$TS_FIELD" && [[ $FORCE -eq 0 ]]; then
  log "  $TS_FIELD already present; skipping (use --force to rotate)"
  needs_ts=0
fi
if has_secret "$IT_FIELD" && [[ $FORCE -eq 0 ]]; then
  log "  $IT_FIELD already present; skipping (use --force to rotate)"
  needs_it=0
fi

if [[ $needs_ts -eq 1 ]]; then
  echo
  echo "Generate a reusable + ephemeral Tailscale pre-auth key (tag:builder"
  echo "or whatever ACL grants tailnet access) at:"
  echo "  https://login.tailscale.com/admin/settings/keys"
  echo
  printf 'Paste Tailscale auth key for %s (tskey-auth-...): ' "$TS_FIELD"
  IFS= read -rs TS_AUTHKEY
  echo
  [[ "$TS_AUTHKEY" == tskey-auth-* ]] \
    || die "key did not start with tskey-auth-, aborting"
  set_secret "$TS_FIELD" "$TS_AUTHKEY"
  unset TS_AUTHKEY
fi

if [[ $needs_it -eq 1 ]]; then
  echo
  echo "Set a password for the 'it-admin' user in this host's linux-builder VM."
  echo "Used for console / recovery; routine SSH access uses the host key."
  while :; do
    printf 'it-admin password: '
    IFS= read -rs IT_ADMIN_PW
    echo
    printf 'it-admin password (confirm): '
    IFS= read -rs IT_ADMIN_PW2
    echo
    [[ -n "$IT_ADMIN_PW" ]] || { echo "  empty password not allowed"; continue; }
    [[ "$IT_ADMIN_PW" == "$IT_ADMIN_PW2" ]] && break
    echo "  passwords do not match, try again"
  done
  unset IT_ADMIN_PW2
  IT_ADMIN_HASH="$(printf '%s' "$IT_ADMIN_PW" | "${NIX_RUN[@]}" mkpasswd -m sha-512 -s)"
  unset IT_ADMIN_PW
  [[ "$IT_ADMIN_HASH" == \$6\$* ]] \
    || die "mkpasswd did not produce a sha-512 hash"
  set_secret "$IT_FIELD" "$IT_ADMIN_HASH"
  unset IT_ADMIN_HASH
fi

# After step 2 added a new recipient to the policy, re-encrypt all
# existing entries so the new recipient can decrypt them. Requires at
# least one current recipient's age private key present in $AGE_KEY.
if [[ $NEEDS_REKEY -eq 1 ]]; then
  log "  re-keying $SECRETS_FILE for updated recipient list"
  "${NIX_RUN[@]}" sops --config "$SOPS_POLICY" updatekeys -y "$SECRETS_FILE"
fi

# Determinate's flake evaluation only sees files that git knows about
# (tracked or staged). Untracked files in the working tree are filtered
# out even though the tree is "dirty". Stage the encrypted secret and
# policy so they're visible in the in-memory git snapshot Nix builds.
# Both files are safe to commit: secrets.yaml is age-encrypted, .sops.yaml
# only contains the public recipient.
log "  committing ${SOPS_POLICY} and ${SECRETS_FILE} inside the secrets repo"
(
  cd "$SECRETS_DIR"
  git add .sops.yaml secrets.yaml
  if ! git diff --cached --quiet; then
    git commit -m "secrets: bootstrap update from $(hostname -s)"
    log "  changes committed; run 'git -C ${SECRETS_DIR} push' when ready to share"
  else
    log "  no changes to commit in secrets repo"
  fi
)

log "step 4/6: update flake lock for sops-nix"
# `nix flake update <input>` is the non-deprecated form for refreshing a
# single input on modern Nix; fall back to full update on older Nix.
( cd "$REPO" && nix flake update sops-nix 2>/dev/null ) \
  || ( cd "$REPO" && nix flake update )

log "step 5/6: darwin-rebuild switch --impure --flake .#${DARWIN_TARGET}"
# --impure is required because environment.etc.<name>.source references
# an absolute path outside the flake (/Users/.../sops/age/keys.txt).
# All other inputs are pinned; the impurity is limited to that one file.
( cd "$REPO" && sudo darwin-rebuild switch --impure \
    --flake ".#${DARWIN_TARGET}" )

log "step 6/6: restart linux-builder VM and verify"
sudo launchctl kickstart -k "$VM_SERVICE"

# Give the VM time to boot, tailscaled to auth, MagicDNS to settle.
log "  waiting up to 60s for tailscaled inside VM..."
for i in $(seq 1 12); do
  if sudo ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
       -i /etc/nix/builder_ed25519 builder@nixos-vm-based-linux-builder \
       'tailscale status >/dev/null 2>&1 && \
        curl -fsSI -o /dev/null --max-time 5 https://'"${CACHE_HOST}${CACHE_PROBE_PATH}"'' \
       2>/dev/null; then
    log "  cache reachable from VM"
    log "done."
    exit 0
  fi
  sleep 5
done

cat >&2 <<EOF
[warn] could not reach https://${CACHE_HOST}${CACHE_PROBE_PATH} from the VM
       within 60s. Inspect with:

  sudo ssh -i /etc/nix/builder_ed25519 it-admin@nixos-vm-based-linux-builder \\
    'sudo journalctl -u tailscaled -u tailscaled-autoconnect -n 80 --no-pager; \\
     sudo ls -la /run/secrets /run/secrets-for-users; \\
     tailscale status; getent hosts ${CACHE_HOST}'

Possible causes:
  - Tailscale pre-auth key expired or wrong tag/ACL
  - VM has no outbound to login.tailscale.com via host NAT
  - ACL on tailnet does not permit tag:builder -> cache host
EOF
exit 1
