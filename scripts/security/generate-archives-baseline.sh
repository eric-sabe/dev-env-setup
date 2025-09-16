#!/usr/bin/env bash
# Generate baseline JSON snapshot of archives (name, sha256, content_length) from manifest.
# Output: baseline/archives.json
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"
OUT_DIR="$ROOT_DIR/baseline"
OUT_FILE="$OUT_DIR/archives.json"
mkdir -p "$OUT_DIR"
[[ -f $MANIFEST ]] || { echo "Missing manifest" >&2; exit 2; }

current_name=""; current_sha=""; current_len=""; in_archives=0
entries=()
while IFS= read -r line; do
  if [[ $line =~ ^[[:space:]]*archives: ]]; then in_archives=1; continue; fi
  if (( in_archives )) && [[ $line =~ ^[^[:space:]-] ]]; then in_archives=0; fi
  (( in_archives )) || continue
  if [[ $line =~ ^[[:space:]]*-[[:space:]]name: ]]; then
    current_name=$(echo "$line" | sed -E 's/.*name: *([^ #]+)/\1/')
    current_sha=""; current_len=""
  elif [[ -n $current_name && $line =~ sha256: ]]; then
    current_sha=$(echo "$line" | awk '{print $2}')
  elif [[ -n $current_name && $line =~ content_length: ]]; then
    current_len=$(echo "$line" | awk '{print $2}')
  fi
  if [[ -n $current_name && -n $current_sha && -n $current_len ]]; then
    if [[ $current_sha =~ ^0{64}$ || $current_sha == TBD ]]; then continue; fi
    entries+=("{\"name\":\"$current_name\",\"sha256\":\"$current_sha\",\"content_length\":$current_len}")
    # reset to avoid duplicate capture if more fields encountered
    current_name=""; current_sha=""; current_len=""
  fi
done < "$MANIFEST"

{ printf '['; printf '%s' "${entries[0]:-}"; for ((i=1;i<${#entries[@]};i++)); do printf ',%s' "${entries[$i]}"; done; printf ']'; } > "$OUT_FILE"
echo "Wrote $OUT_FILE" >&2
