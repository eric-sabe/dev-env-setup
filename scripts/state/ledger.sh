#!/usr/bin/env bash
# EXPERIMENTAL: Append-only operation ledger with integrity chaining.
# Each entry: JSON line containing: ts, action, component, status, duration_ms, extra (optional), prev_sha256.
# A chain file (ledger.jsonl) plus a sidecar latest hash (ledger.head) are maintained.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$ROOT_DIR/state"
LEDGER_FILE="$STATE_DIR/ledger.jsonl"
HEAD_FILE="$STATE_DIR/ledger.head"
mkdir -p "$STATE_DIR"
LOG_JSON="$ROOT_DIR/scripts/utils/log-json.sh"
log_event(){
  if [[ -f $LOG_JSON ]]; then
    bash "$LOG_JSON" event source=ledger "$@" >/dev/null || true
  fi
}

now_iso(){ date -u +"%Y-%m-%dT%H:%M:%SZ"; }

hash_line(){
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    sha256sum | awk '{print $1}'
  fi
}

usage(){ cat <<EOF
Usage: $0 record --action <action> [--component <name>] [--status <ok|fail>] [--duration-ms <n>] [--extra <json-fragment>]
       $0 verify  # verify hash chain
EOF
}

cmd=${1:-}; [[ -n "$cmd" ]] || { usage >&2; exit 2; }; shift || true

ACTION=""; COMPONENT=""; STATUS="ok"; DURATION=""; EXTRA=""
case "$cmd" in
  record)
    while [[ $# -gt 0 ]]; do
      case $1 in
        --action) ACTION="$2"; shift 2;;
        --component) COMPONENT="$2"; shift 2;;
        --status) STATUS="$2"; shift 2;;
        --duration-ms) DURATION="$2"; shift 2;;
        --extra) EXTRA="$2"; shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "Unknown arg: $1" >&2; exit 2;;
      esac
    done
    [[ -n $ACTION ]] || { echo "--action required" >&2; exit 3; }
    prev=""
    if [[ -f $HEAD_FILE ]]; then prev=$(cat "$HEAD_FILE"); fi
    ts=$(now_iso)
    # Build JSON line (minimal escaping; assume inputs sanitized)
    line=$(printf '{"ts":"%s","action":"%s"' "$ts" "$ACTION")
    [[ -n $COMPONENT ]] && line+=$(printf ',"component":"%s"' "$COMPONENT")
    line+=$(printf ',"status":"%s"' "$STATUS")
    [[ -n $DURATION ]] && line+=$(printf ',"duration_ms":%s' "$DURATION")
    [[ -n $EXTRA ]] && line+=$(printf ',"extra":%s' "$EXTRA")
    [[ -n $prev ]] && line+=$(printf ',"prev_sha256":"%s"' "$prev")
    line+='}'
    # Compute new head hash (hash of previous head + newline + line) or just line if first
    if [[ -n $prev ]]; then
      new_head=$( { printf '%s\n' "$prev"; printf '%s' "$line"; } | hash_line )
    else
      new_head=$(printf '%s' "$line" | hash_line)
    fi
    # Append line atomically
    { printf '%s\n' "$line" >> "$LEDGER_FILE"; printf '%s' "$new_head" > "$HEAD_FILE"; } || { echo "Failed to append" >&2; exit 4; }
  log_event action=record ledger_head="$new_head" component="$COMPONENT" status="$STATUS" op="$ACTION"
  echo "$new_head"
    ;;
  verify)
    [[ -f $LEDGER_FILE ]] || { echo "No ledger" >&2; exit 0; }
    calc=""
    while IFS= read -r line; do
      if [[ -z $calc ]]; then
        calc=$(printf '%s' "$line" | hash_line)
      else
        calc=$( { printf '%s\n' "$calc"; printf '%s' "$line"; } | hash_line )
      fi
    done < "$LEDGER_FILE"
    stored=""; [[ -f $HEAD_FILE ]] && stored=$(cat "$HEAD_FILE")
    if [[ $calc == "$stored" ]]; then
      echo "OK chain intact ($calc)"
      exit 0
    else
      echo "FAIL chain mismatch calc=$calc stored=$stored" >&2
      exit 5
    fi
    ;;
  *) usage >&2; exit 2;;
esac
