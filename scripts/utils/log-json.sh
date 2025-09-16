#!/usr/bin/env bash
# Structured JSON logging helper.
# Usage: log-json.sh event <key=value> ...
# Fields automatically added: ts (UTC ISO8601), pid.
# Destination: stdout and, if LOG_JSONL set, appended to that file.

set -euo pipefail

now_iso(){ date -u +"%Y-%m-%dT%H:%M:%SZ"; }
escape_json(){
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//"/\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

if [[ ${1:-} == "event" ]]; then
  shift || true
  if ! declare -A __test 2>/dev/null; then
    ts=$(now_iso); pid=$$
    out="{\"ts\":\"$ts\",\"pid\":$pid"
    for pair in "$@"; do k=${pair%%=*}; v=${pair#*=}; v=$(printf '%s' "$v" | sed 's/\\/\\\\/g; s/"/\\"/g'); out+=" ,\"$k\":\"$v\""; done
    out+="}"
    echo "$out"
    if [[ -n ${LOG_JSONL:-} ]]; then mkdir -p "$(dirname "$LOG_JSONL")"; echo "$out" >> "$LOG_JSONL"; fi
    exit 0
  fi
  declare -A kv
  for pair in "$@"; do
    k=${pair%%=*}
    v=${pair#*=}
    v=$(escape_json "$v")
    kv[$k]="$v"
  done
  ts=$(now_iso)
  pid=$$
  json="{\"ts\":\"$ts\",\"pid\":$pid"
  for k in "${!kv[@]}"; do
    json+=" ,\"$k\":\"${kv[$k]}\""
  done
  json+="}"
  echo "$json"
  if [[ -n ${LOG_JSONL:-} ]]; then
    mkdir -p "$(dirname "$LOG_JSONL")"
    echo "$json" >> "$LOG_JSONL"
  fi
else
  echo "Usage: $0 event key=value ..." >&2
  exit 2
fi
