#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
YAML="$ROOT_DIR/manifests/versions.yaml"
TMP_DIR="${TMPDIR:-/tmp}/lock-src-$$"
DRY=1
FILTER=""

usage(){ cat <<EOF
Usage: $0 [--write] [--filter <name-substring>]
Resolves TBD sha256 entries in sources: by downloading artifact and computing hash.

Outputs updated manifest to stdout (dry-run) unless --write is given (in-place edit).
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --write) DRY=0; shift;;
    --filter) FILTER="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f $YAML ]] || { echo "missing manifest: $YAML" >&2; exit 3; }
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

# Extract sources block lines (portable, no bash 4 mapfile)
lines=()
while IFS= read -r __l; do
  lines+=("$__l")
done < "$YAML"

# We'll rebuild file; when encountering a source entry with sha256: TBD compute replacement
out=()
current_name=""
current_url=""
current_type=""
for i in "${!lines[@]}"; do
  line="${lines[$i]}"
  if [[ $line =~ ^[[:space:]]*-\ name: ]]; then
    current_name=$(echo "$line" | sed -E 's/.*name: *([^ #]+)/\1/')
    current_url="" # reset
    current_type=""
  elif [[ $line =~ url: ]]; then
    current_url=$(echo "$line" | sed -E 's/.*url: *([^ #]+)/\1/')
  elif [[ $line =~ type: ]]; then
    current_type=$(echo "$line" | sed -E 's/.*type: *([^ #]+)/\1/')
  elif [[ $line =~ sha256:\ TBD ]]; then
    if [[ -n $current_name && -n $current_url ]]; then
      if [[ -n $FILTER && $current_name != *"$FILTER"* ]]; then
        out+=("$line")
        continue
      fi
      case $current_type in
        pypi|npm)
          out+=("$line")
          continue
          ;;
      esac
      echo "Locking $current_name from $current_url" >&2
      file="$TMP_DIR/$current_name.bin"
      if curl -L --fail --silent --show-error "$current_url" -o "$file"; then
        if command -v shasum >/dev/null 2>&1; then
          hash=$(shasum -a 256 "$file" | awk '{print $1}')
        else
          hash=$(sha256sum "$file" | awk '{print $1}')
        fi
        out+=("${line/TBD/$hash}")
      else
        echo "WARN: download failed for $current_name" >&2
        out+=("$line")
      fi
    else
      out+=("$line")
    fi
    continue
  fi
  out+=("$line")
 done

if [[ $DRY -eq 1 ]]; then
  printf '%s\n' "${out[@]}"
else
  printf '%s\n' "${out[@]}" > "$YAML"
  echo "Updated $YAML" >&2
fi
