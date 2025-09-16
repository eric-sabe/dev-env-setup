#!/usr/bin/env bash
# SBOM generator stub (Phase 3 scaffold)
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"
OUT_DIR="sbom"
mkdir -p "$OUT_DIR"
FILE="$OUT_DIR/sbom.json"

# Collect components
components=()

if [[ -f "$MANIFEST" ]]; then
  # python packages
  while IFS= read -r line; do
    # match lines inside python: packages groups of form 'name: "version"'
    if [[ $line =~ ^[[:space:]]+[a-zA-Z0-9_.-]+: ]]; then
      pkg=$(echo "$line" | sed -E 's/^[[:space:]]*([A-Za-z0-9_.-]+):.*/\1/')
      ver=$(echo "$line" | sed -nE 's/.*"([0-9][^"]*)".*/\1/p')
      if [[ -n $ver ]]; then
        purl="pkg:pypi/${pkg}@${ver}"
        components+=("{\"type\": \"library\", \"name\": \"$pkg\", \"version\": \"$ver\", \"purl\": \"$purl\"}")
      fi
    fi
  done < <(awk '/^python:/,/^node:/' "$MANIFEST")
  # node globals
  while IFS= read -r line; do
    if [[ $line =~ :[[:space:]]*"[0-9] ]]; then
      pkg=$(echo "$line" | sed -E 's/^[[:space:]]*([@A-Za-z0-9_\/-]+):.*/\1/')
      ver=$(echo "$line" | sed -nE 's/.*"([0-9][^"]*)".*/\1/p')
      if [[ -n $ver ]]; then
        escaped_pkg=${pkg//@/%40}
        purl="pkg:npm/${escaped_pkg}@${ver}"
        components+=("{\"type\": \"library\", \"name\": \"$pkg\", \"version\": \"$ver\", \"purl\": \"$purl\"}")
      fi
    fi
  done < <(awk '/^node:/,/^linux:/' "$MANIFEST")
fi

{
  echo '{'
  echo '  "bomFormat": "CycloneDX",'
  echo '  "specVersion": "1.5",'
  echo '  "version": 1,'
  echo '  "metadata": {'
  echo '    "timestamp": '"\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""','
  echo '    "tools": [{"vendor": "dev-env-setup", "name": "sbom-generator", "version": "0.2"}]'
  echo '  },'
  echo '  "components": ['
  for i in "${!components[@]}"; do
    printf '    %s%s\n' "${components[$i]}" $([[ $i -lt $((${#components[@]}-1)) ]] && echo ',')
  done
  echo '  ]'
  echo '}'
} > "$FILE"

echo "SBOM written to $FILE (components: ${#components[@]})" >&2
