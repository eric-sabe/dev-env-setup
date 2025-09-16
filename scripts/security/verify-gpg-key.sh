#!/usr/bin/env bash
# verify-gpg-key.sh
# Fetches a remote GPG key, extracts its fingerprint, and compares against the manifest allowlist.
# Usage:
#   scripts/security/verify-gpg-key.sh --name microsoft-vscode
#   scripts/security/verify-gpg-key.sh --all
# Options:
#   --manifest <path>   Path to versions.yaml (auto-detect if omitted)
#   --name <key-name>   Verify only the specified key by name
#   --all               Verify all keys in gpg_keys section
#   --json              Emit JSON summary
# Exit codes:
#   0 success
#   1 general error
#   2 mismatch / missing key
#   3 parse error (manifest)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR%/scripts/security*}"
MANIFEST="${ROOT_DIR}/manifests/versions.yaml"

want_json=false
mode=""
filter_name=""

die(){ echo "[ERROR] $1" >&2; exit "${2:-1}"; }
log(){ echo "[verify-gpg-key] $1"; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --manifest) MANIFEST=$2; shift 2;;
    --name) filter_name=$2; mode="single"; shift 2;;
    --all) mode="all"; shift;;
    --json) want_json=true; shift;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0;;
    *) die "Unknown arg: $1" 1;;
  esac
done

[[ -f $MANIFEST ]] || die "Manifest not found: $MANIFEST" 1

# Extract gpg_keys block (stop at next top-level key like 'python:' etc.)
keys_block=$(awk 'BEGIN{inblk=0} \
  /^gpg_keys:/ {inblk=1;next} \
  /^[[:alpha:]_]+:/ { if(inblk){inblk=0} } \
  { if(inblk) print }' "$MANIFEST" || true)
[[ -n $keys_block ]] || die "No gpg_keys section present in manifest" 3

names=(); fingerprints=(); sources=(); statuses=()
current_name=""; current_fp=""; current_source=""; current_status=""; collecting=false
while IFS= read -r line; do
  # Start of a new key entry
  if [[ $line =~ ^[[:space:]]*-[[:space:]]+name:[[:space:]]*(.+)$ ]]; then
    if $collecting; then
      names+=("$current_name"); fingerprints+=("$current_fp"); sources+=("$current_source"); statuses+=("$current_status")
    fi
    collecting=true
    current_name="${BASH_REMATCH[1]}"; current_fp=""; current_source=""; current_status=""
    continue
  fi
  $collecting || continue
  # Capture fields
  if [[ $line =~ fingerprint:[[:space:]]*([A-Fa-f0-9]{40}|PLACEHOLDER_[A-Za-z0-9_]+) ]]; then
    current_fp="${BASH_REMATCH[1]}"
    continue
  fi
  if [[ $line =~ source:[[:space:]]*(https?://[^[:space:]]+) ]]; then
    current_source="${BASH_REMATCH[1]}"
    continue
  fi
  if [[ $line =~ status:[[:space:]]*([A-Za-z0-9_-]+) ]]; then
    current_status="${BASH_REMATCH[1]}"
    continue
  fi
done < <(echo "$keys_block")
if $collecting; then
  names+=("$current_name"); fingerprints+=("$current_fp"); sources+=("$current_source"); statuses+=("$current_status")
fi

if [[ ${#names[@]} -eq 0 ]]; then
  die "No key entries found in gpg_keys" 3
fi

selected_indices=()
for i in "${!names[@]}"; do
  [[ -n ${names[$i]} ]] || continue
  if [[ $mode == single && ${names[$i]} != "$filter_name" ]]; then
    continue
  fi
  selected_indices+=("$i")

done

if [[ $mode == single && ${#selected_indices[@]} -eq 0 ]]; then
  die "Requested key name not found: $filter_name" 2
fi

[[ $mode == all || $mode == single ]] || die "Specify --all or --name <key>" 1

results_json="["
first_json=true
status_code=0

for idx in "${selected_indices[@]}"; do
  name=${names[$idx]}
  fp_expected=${fingerprints[$idx]}
  key_url=${sources[$idx]}
  key_status=${statuses[$idx]:-active}

  if [[ $key_status != "active" ]]; then
    log "Skipping inactive key: $name"
    continue
  fi

  if [[ $fp_expected == PLACEHOLDER_* ]]; then
    log "Key $name still has placeholder fingerprint" >&2
    status_code=2
    if $want_json; then
      json_obj="{\"name\":\"$name\",\"status\":\"placeholder\"}"
      if $first_json; then results_json+="$json_obj"; first_json=false; else results_json+=",$json_obj"; fi
    fi
    continue
  fi

  tmp_key=$(mktemp)
  if ! curl -fsSL "$key_url" -o "$tmp_key"; then
    log "Failed to download key for $name"
    status_code=2
    continue
  fi
  # Extract fingerprint
  # Use gpg in a temporary GNUPGHOME to avoid polluting user keyring
  export GNUPGHOME="$(mktemp -d)"
  fp_actual=$(gpg --show-keys --with-colons "$tmp_key" | awk -F: '/^fpr/ {print $10; exit}') || fp_actual=""
  rm -f "$tmp_key"
  rm -rf "$GNUPGHOME"
  if [[ -z $fp_actual ]]; then
    log "Could not extract fingerprint for $name"
    status_code=2
    continue
  fi
  # Normalize case for comparison (portable, avoid Bash 4+ dependency)
  fp_actual_uc=$(echo "$fp_actual" | tr '[:lower:]' '[:upper:]')
  fp_expected_uc=$(echo "$fp_expected" | tr '[:lower:]' '[:upper:]')
  if [[ $fp_actual_uc == $fp_expected_uc ]]; then
    log "Match: $name ($fp_actual)"
    if $want_json; then
      json_obj="{\"name\":\"$name\",\"status\":\"match\",\"fingerprint\":\"$fp_actual\"}"
      if $first_json; then results_json+="$json_obj"; first_json=false; else results_json+=",$json_obj"; fi
    fi
  else
    log "Mismatch: $name expected $fp_expected got $fp_actual" >&2
    status_code=2
    if $want_json; then
      json_obj="{\"name\":\"$name\",\"status\":\"mismatch\",\"expected\":\"$fp_expected\",\"actual\":\"$fp_actual\"}"
      if $first_json; then results_json+="$json_obj"; first_json=false; else results_json+=",$json_obj"; fi
    fi
  fi

done

results_json+="]"
if $want_json; then
  echo "$results_json"
fi
exit $status_code
