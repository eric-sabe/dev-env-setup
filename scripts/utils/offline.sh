#!/usr/bin/env bash
# Offline mode utility.
# Exposes: offline_enabled, offline_require_cache <path>, fetch_with_cache <url> <out>

set -euo pipefail

OFFLINE_FLAG=${OFFLINE_MODE:-0}
CACHE_DIR=${CACHE_DIR:-"${TMPDIR:-/tmp}/dev-env-cache"}
mkdir -p "$CACHE_DIR"

# Manifest fingerprint (sha256 of versions.yaml) to detect stale cache relative to manifest changes.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"
MANIFEST_HASH_FILE="$CACHE_DIR/manifest.hash"

compute_manifest_hash(){
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$MANIFEST" | awk '{print $1}'
  else
    sha256sum "$MANIFEST" | awk '{print $1}'
  fi
}

# Initialize or verify manifest hash when not in pure library context.
if [[ -f $MANIFEST ]]; then
  current_hash=$(compute_manifest_hash)
  if [[ ! -f $MANIFEST_HASH_FILE ]]; then
    printf '%s' "$current_hash" > "$MANIFEST_HASH_FILE"
  else
    cached_hash=$(cat "$MANIFEST_HASH_FILE" || true)
    if [[ $cached_hash != "$current_hash" && $OFFLINE_FLAG == 1 ]]; then
      echo "[offline] WARNING: manifest hash mismatch (cache=$cached_hash current=$current_hash) – cache may be stale" >&2
    fi
  fi
fi

offline_enabled(){ [[ "$OFFLINE_FLAG" == "1" ]]; }

offline_require_cache(){
  local p="$1"; if offline_enabled && [[ ! -f $p ]]; then
    echo "[offline] missing cached artifact: $p" >&2; return 2; fi
  return 0
}

cache_key_from_url(){ echo "$1" | shasum -a 256 | awk '{print $1}'; }

fetch_with_cache(){
  local url="$1" out="$2"; local key=$(cache_key_from_url "$url")
  local cached="$CACHE_DIR/$key.bin"
  if offline_enabled; then
    offline_require_cache "$cached" || return 3
    cp "$cached" "$out"
    return 0
  fi
  if curl -L --fail --silent --show-error "$url" -o "$out"; then
    cp "$out" "$cached" || true
    return 0
  else
    echo "Download failed: $url" >&2; return 4
  fi
}
