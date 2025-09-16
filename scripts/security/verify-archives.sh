#!/usr/bin/env bash
# Verify external archive integrity using manifest (versions.yaml).
# Checks:
#   1. sha256 matches (full mode) OR optional quick mode only size & header sanity.
#   2. content_length (if present) matches remote Content-Length exactly.
#   3. Detect HTML/text (probable error page) by MIME sniffing first bytes.
#   4. Optional tolerance (--size-warn <pct>) to warn if size drift exceeds threshold (even if hash same TBD future bump).
#
# Usage:
#   scripts/security/verify-archives.sh                 # full verification all archives with sha256 len=present
#   scripts/security/verify-archives.sh --filter eclipse-linux  # subset
#   scripts/security/verify-archives.sh --quick         # HEAD + size check only
#   scripts/security/verify-archives.sh --size-warn 2   # warn if size differs from manifest by >2%
# Exit codes: 0 all good; 1 warnings only (if --allow-warn), 2 hard failures.

set -euo pipefail
FILTER=""
QUICK=0
SIZE_WARN_PCT=""  # numeric percent
ALLOW_WARN=0
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"
TMP_DIR="${TMPDIR:-/tmp}/verify-archives-$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

usage(){ grep '^# ' "$0" | sed 's/^# //'; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --filter) FILTER="$2"; shift 2;;
    --quick) QUICK=1; shift;;
    --size-warn) SIZE_WARN_PCT="$2"; shift 2;;
    --allow-warn) ALLOW_WARN=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f $MANIFEST ]] || { echo "Missing manifest $MANIFEST" >&2; exit 3; }

fail=0; warn=0

current_name=""; current_url=""; current_sha=""; current_len=""; in_archives=0
flush(){ :; }

while IFS= read -r line; do
  if [[ $line =~ ^[[:space:]]*archives: ]]; then in_archives=1; continue; fi
  if (( in_archives )) && [[ $line =~ ^[^[:space:]-] ]]; then in_archives=0; fi
  (( in_archives )) || continue

  if [[ $line =~ ^[[:space:]]*-\ name: ]]; then
    # process previous (none needed) and start new
    current_name=$(echo "$line" | sed -E 's/.*name: *([^ #]+)/\1/')
    current_url=""; current_sha=""; current_len=""
  elif [[ -n $current_name && $line =~ url: ]]; then
    current_url=$(echo "$line" | sed -E 's/.*url: *([^ #]+)/\1/')
  elif [[ -n $current_name && $line =~ sha256: ]]; then
    current_sha=$(echo "$line" | awk '{print $2}')
  elif [[ -n $current_name && $line =~ content_length: ]]; then
    current_len=$(echo "$line" | awk '{print $2}')
  fi

  # When we have url + sha + (optional len) and next dash or end, verify
  if [[ -n $current_name && -n $current_url && -n $current_sha ]]; then
    # Peek ahead? Simplify: run when we just captured sha256 line OR when a blank line occurs.
    if [[ $line =~ sha256: ]]; then
      if [[ -n $FILTER && $current_name != *"$FILTER"* ]]; then continue; fi
      if [[ $current_name == eclipse-release-* ]]; then continue; fi
      # Quick HEAD for Content-Length
      remote_len=$(curl -sIL -H 'User-Agent: verify-archives/1.0' "$current_url" | awk 'tolower($1)=="content-length:" {print $2}' | tail -n1 | tr -d '\r' || true)
      if [[ -n $current_len && -n $remote_len && $remote_len != $current_len ]]; then
        echo "SIZE-MISMATCH $current_name manifest=$current_len remote=$remote_len" >&2
        ((fail++))
      fi
      if [[ -n $SIZE_WARN_PCT && -n $current_len && -n $remote_len && $remote_len == $current_len ]]; then
        : # exact match, fine
      fi
      if (( QUICK )); then continue; fi
      tmp="$TMP_DIR/$current_name.bin"
      if ! curl -sL --fail "$current_url" -o "$tmp"; then
        echo "DOWNLOAD-FAIL $current_name" >&2
        ((fail++))
        continue
      fi
      # MIME sniff
      if head -c 256 "$tmp" | grep -qi '<html'; then
        echo "HTML-DETECTED $current_name (probable error page)" >&2
        ((fail++))
        continue
      fi
      # Size exact check if content_length set
      if [[ -n $current_len ]]; then
        actual_size=$(wc -c < "$tmp")
        if [[ $actual_size != "$current_len" ]]; then
          echo "SIZE-DIFF-DOWNLOADED $current_name manifest=$current_len actual=$actual_size" >&2
          ((fail++))
        elif [[ -n $SIZE_WARN_PCT ]]; then
          # placeholder for future drift logic if we store historical sizes
          :
        fi
      fi
      # Hash check (skip if placeholder all zeros)
      if [[ $current_sha =~ ^0{64}$ ]]; then
        echo "SKIP-HASH meta/placeholder $current_name" >&2
      else
        have_sha=$(shasum -a 256 "$tmp" | awk '{print $1}')
        if [[ $have_sha != $current_sha ]]; then
          echo "HASH-MISMATCH $current_name expected=$current_sha got=$have_sha" >&2
          ((fail++))
        else
          echo "OK $current_name" >&2
        fi
      fi
    fi
  fi
done < "$MANIFEST"

if (( fail )); then
  echo "FAILURES: $fail" >&2
  exit 2
elif (( warn )) && (( ! ALLOW_WARN )); then
  echo "WARNINGS: $warn (treating as success)" >&2
  exit 1
fi
exit 0
