#!/usr/bin/env bash
# Automate bumping Eclipse release in manifest and resetting hashes for re-lock.
# It updates all eclipse-* archive entries matching old release with a new release (e.g. 2025-09 -> 2025-12)
# Steps:
#   1. Find eclipse-* entries with version: <old>
#   2. Replace version field and embedded URL segment /<old>/ with /<new>/
#   3. Set sha256: TBD (so lock process can recalc) and remove content_length lines.
#   4. Update meta entry eclipse-release-<old> -> eclipse-release-<new>
# Dry-run by default; use --write to modify file.
# Usage:
#   scripts/tools/update-eclipse-release.sh 2025-09 2025-12 --write

set -euo pipefail
[[ $# -ge 2 ]] || { echo "Usage: $0 <old-release> <new-release> [--write]" >&2; exit 2; }
OLD="$1"; shift
NEW="$1"; shift
WRITE=0
if [[ ${1:-} == --write ]]; then WRITE=1; fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"
[[ -f $MANIFEST ]] || { echo "Missing manifest: $MANIFEST" >&2; exit 3; }

tmp="${TMPDIR:-/tmp}/eclipse-bump-$$.yaml"

awk -v OLD="$OLD" -v NEW="$NEW" '
  function is_eclipse_name(line){ return line ~ /- name: eclipse-/ }
  function reset_hash_line(line){ sub(/sha256:.*/, "sha256: TBD"); return line }
  {
    if ($0 ~ /- name: eclipse-release-/ && $0 ~ OLD) {
      sub("eclipse-release-"OLD, "eclipse-release-"NEW)
    }
    if (is_eclipse_name($0)) {
      in_eclipse=1
    }
    if (in_eclipse && $0 ~ /version: \""OLD"\"/) {
      sub(/version: \""OLD"\"/, "version: \""NEW"\"")
    }
    if (in_eclipse && $0 ~ /url:/ && $0 ~ OLD) {
      gsub("/"OLD"/", "/"NEW"/")
    }
    if (in_eclipse && $0 ~ /sha256:/) {
      $0 = reset_hash_line($0)
    }
    if (in_eclipse && $0 ~ /content_length:/) {
      next
    }
    if ($0 ~ /^\s*sha256:/) {
      in_eclipse=0
    }
    print
  }
' "$MANIFEST" > "$tmp"

if (( WRITE )); then
  mv "$tmp" "$MANIFEST"
  echo "Updated eclipse release $OLD -> $NEW in $MANIFEST (hashes reset, sizes removed)." >&2
else
  cat "$tmp"
fi
