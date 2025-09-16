#!/usr/bin/env bash
# Checksum utilities (Phase 3 scaffold)
set -Eeuo pipefail

usage() { cat <<EOF
Usage: $0 <command> [args]
Commands:
  verify <file> <sha256>    Verify file matches expected sha256
  fetch-verify <url> <sha256> <output>  Download URL to output then verify
  compute <file>            Print sha256 of file
  verify-or-record <name> <url> <expected|TBD> <output>  If expected is TBD, download + compute and print record line; else enforce match.
EOF
}

sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}';
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
  else echo "no sha256 tool found" >&2; return 1; fi
}

verify_file() {
  local file="$1" expected="$2"
  [[ -f $file ]] || { echo "missing file: $file" >&2; return 2; }
  local actual
  actual=$(sha256 "$file")
  if [[ "$actual" != "$expected" ]]; then
    echo "SHA256 mismatch for $file" >&2
    echo "expected: $expected" >&2
    echo "actual:   $actual" >&2
    return 3
  fi
  echo "OK $file" >&2
}

fetch_and_verify() {
  local url="$1" expected="$2" out="$3"
  curl -L --fail --silent --show-error "$url" -o "$out"
  verify_file "$out" "$expected"
}

verify_or_record() {
  local name="$1" url="$2" expected="$3" out="$4"
  curl -L --fail --silent --show-error "$url" -o "$out"
  if [[ "$expected" == "TBD" ]]; then
    local actual
    actual=$(sha256 "$out")
    echo "RECORD $name $actual $url" >&2
  else
    verify_file "$out" "$expected"
  fi
}

cmd=${1:-}
case "$cmd" in
  verify) shift; verify_file "$@" ;;
  fetch-verify) shift; fetch_and_verify "$@" ;;
  compute) shift; sha256 "$@" ;;
  verify-or-record) shift; verify_or_record "$@" ;;
  *) usage; exit 1;;
 esac
