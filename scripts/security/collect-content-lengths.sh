#!/usr/bin/env bash
# Collect Content-Length (byte size) for external archives (currently focused on eclipse-* entries).
# Usage:
#   scripts/security/collect-content-lengths.sh              # prints name size url
#   scripts/security/collect-content-lengths.sh --filter eclipse-linux # filter by substring
# Notes:
# - Uses only POSIX-ish tools (awk, sed, curl) for portability (macOS default Bash 3 compatible).
# - Follows redirects (-L) and picks the final Content-Length header (some mirrors send multiple).
# - If a size can't be determined, prints SIZE=UNKNOWN and exits non‑zero at end (aggregate failure signal).

set -euo pipefail
FILTER=""
YAML_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/manifests"
MANIFEST="$YAML_DIR/versions.yaml"
FAILS=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --filter) FILTER="$2"; shift 2;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //' | sed '1,2d'; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f $MANIFEST ]] || { echo "Missing manifest: $MANIFEST" >&2; exit 3; }

current_name=""; current_url=""; in_archives=0
while IFS= read -r line; do
  # Detect archives section start (indentation level of 'archives:')
  if [[ $line =~ ^[[:space:]]*archives: ]]; then
    in_archives=1; continue
  fi
  # Stop when leaving archives block (next top-level key not starting with spaces or dash under archives)
  if (( in_archives )) && [[ $line =~ ^[^[:space:]-] ]]; then
    # hit a new top-level key
    in_archives=0
  fi
  (( in_archives )) || continue

  if [[ $line =~ ^[[:space:]]*-\ name: ]]; then
    current_name=$(echo "$line" | sed -E 's/.*name: *([^ #]+)/\1/')
    current_url=""
  elif [[ -n $current_name && $line =~ url: ]]; then
    current_url=$(echo "$line" | sed -E 's/.*url: *([^ #]+)/\1/')
    if [[ $current_name == eclipse-* ]]; then
      if [[ -n $FILTER && $current_name != *"$FILTER"* ]]; then
        continue
      fi
      # Fetch final Content-Length
      cl=$(curl -sIL -H 'User-Agent: curl-size-probe/1.0' "$current_url" | awk 'tolower($1)=="content-length:" {print $2}' | tail -n1 | tr -d '\r') || cl=""
      if [[ -z ${cl:-} || ! $cl =~ ^[0-9]+$ ]]; then
        echo "$current_name UNKNOWN $current_url" >&2
        ((FAILS++))
      else
        echo "$current_name $cl $current_url"
      fi
    fi
  fi
done < "$MANIFEST"

exit $FAILS
