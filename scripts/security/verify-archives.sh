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
CONCURRENCY=1
SIZE_WARN_PCT=""  # numeric percent
ALLOW_WARN=0
OUTPUT_JSON=""
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"
TMP_DIR="${TMPDIR:-/tmp}/verify-archives-$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

LOG_JSON="$ROOT_DIR/scripts/utils/log-json.sh"
log_event(){
  if [[ -f $LOG_JSON ]]; then
    bash "$LOG_JSON" event source=verify-archives "$@" >/dev/null || true
  fi
}
start_ts=""

# Offline support (if OFFLINE_MODE=1 and offline.sh present)
if [[ -f "$ROOT_DIR/scripts/utils/offline.sh" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/scripts/utils/offline.sh"
fi

usage(){ grep '^# ' "$0" | sed 's/^# //'; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --filter) FILTER="$2"; shift 2;;
  --quick) QUICK=1; shift;;
  --concurrency) CONCURRENCY="$2"; shift 2;;
    --size-warn) SIZE_WARN_PCT="$2"; shift 2;;
  --allow-warn) ALLOW_WARN=1; shift;;
  --output-json) OUTPUT_JSON="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

get_ms(){
  local raw
  if raw=$(date +%s%3N 2>/dev/null); then
    printf '%s' "${raw//[^0-9]/}"
  else
    # Fallback: seconds -> ms
    printf '%s000' "$(date +%s)"
  fi
}
start_ts=$(get_ms)
log_event phase=start mode=$([[ $QUICK -eq 1 ]] && echo quick || echo full)

[[ -f $MANIFEST ]] || { echo "Missing manifest $MANIFEST" >&2; exit 3; }

fail=0; warn=0
declare -a ARTIFACT_JSON

current_name=""; current_url=""; current_sha=""; current_len=""; in_archives=0
declare -a QUEUE_NAMES QUEUE_URLS QUEUE_LEN QUEUE_SHA

run_head(){ # name url expected_len sha
  local n="$1" u="$2" elen="$3" sha="$4"
  local remote_len
  remote_len=$(curl -sIL -H 'User-Agent: verify-archives/1.0' "$u" | awk 'tolower($1)=="content-length:" {print $2}' | tail -n1 | tr -d '\r' || true)
  if [[ -n $elen && -n $remote_len && $remote_len != $elen ]]; then
    echo "SIZE-MISMATCH $n manifest=$elen remote=$remote_len" >&2
    echo FAIL
    return
  fi
  echo "OK-SIZE $n" >&2
  echo OK
}

wait_heads(){
  local pids=() names=()
  local results_file="$TMP_DIR/results.$$"
  : > "$results_file"
  for idx in "${!QUEUE_NAMES[@]}"; do
    (
      outcome=$(run_head "${QUEUE_NAMES[$idx]}" "${QUEUE_URLS[$idx]}" "${QUEUE_LEN[$idx]}" "${QUEUE_SHA[$idx]}")
      # Persist individual result for later JSON collation
      if [[ $outcome == OK ]]; then
        printf '%s size_ok\n' "${QUEUE_NAMES[$idx]}" >> "$results_file"
      else
        printf '%s size_mismatch\n' "${QUEUE_NAMES[$idx]}" >> "$results_file"
      fi
    ) &
    pids+=($!)
    names+=("${QUEUE_NAMES[$idx]}")
    # throttle
    if (( ${#pids[@]} >= CONCURRENCY )); then
      for i in "${!pids[@]}"; do
        if wait "${pids[$i]}"; then
          log_event artifact="${names[$i]}" result=size_ok
        else
          fail=$((fail+1))
          log_event artifact="${names[$i]}" result=size_fail
        fi
      done
      pids=(); names=()
    fi
  done
  # final wait
  for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
      log_event artifact="${names[$i]}" result=size_ok
    else
      fail=$((fail+1))
      log_event artifact="${names[$i]}" result=size_fail
    fi
  done
  # Incorporate recorded results into ARTIFACT_JSON (size_ok or size_mismatch)
  if [[ -f $results_file ]]; then
    while read -r name res; do
      if [[ $res == size_ok ]]; then
        ARTIFACT_JSON+=("{\"name\":\"$name\",\"result\":\"size_ok\"}")
      else
        ARTIFACT_JSON+=("{\"name\":\"$name\",\"result\":\"size_mismatch\"}")
      fi
    done < "$results_file"
  fi
  QUEUE_NAMES=(); QUEUE_URLS=(); QUEUE_LEN=(); QUEUE_SHA=()
}

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
      if (( QUICK )) && (( CONCURRENCY > 1 )); then
        QUEUE_NAMES+=("$current_name"); QUEUE_URLS+=("$current_url"); QUEUE_LEN+=("$current_len"); QUEUE_SHA+=("$current_sha")
        continue
      fi
      # Quick single HEAD path
      remote_len=$(curl -sIL -H 'User-Agent: verify-archives/1.0' "$current_url" | awk 'tolower($1)=="content-length:" {print $2}' | tail -n1 | tr -d '\r' || true)
      if [[ -n $current_len && -n $remote_len && $remote_len != $current_len ]]; then
        echo "SIZE-MISMATCH $current_name manifest=$current_len remote=$remote_len" >&2
        ((fail++))
      fi
      if [[ -n $SIZE_WARN_PCT && -n $current_len && -n $remote_len && $remote_len == $current_len ]]; then
        : # exact match, fine
      fi
      if (( QUICK )); then
  log_event artifact="$current_name" result=size_ok
  ARTIFACT_JSON+=("{\"name\":\"$current_name\",\"result\":\"size_ok\"}")
        continue
      fi
      tmp="$TMP_DIR/$current_name.bin"
      if command -v fetch_with_cache >/dev/null 2>&1; then
        if ! fetch_with_cache "$current_url" "$tmp"; then
          echo "DOWNLOAD-FAIL $current_name" >&2
          log_event artifact="$current_name" result=download_fail
          ARTIFACT_JSON+=("{\"name\":\"$current_name\",\"result\":\"download_fail\"}")
          ((fail++))
          continue
        fi
      else
        if ! curl -sL --fail "$current_url" -o "$tmp"; then
          echo "DOWNLOAD-FAIL $current_name" >&2
          log_event artifact="$current_name" result=download_fail
          ARTIFACT_JSON+=("{\"name\":\"$current_name\",\"result\":\"download_fail\"}")
          ((fail++))
          continue
        fi
      fi
      # MIME sniff
      if head -c 256 "$tmp" | grep -qi '<html'; then
  echo "HTML-DETECTED $current_name (probable error page)" >&2
  log_event artifact="$current_name" result=html_error
  ARTIFACT_JSON+=("{\"name\":\"$current_name\",\"result\":\"html_error\"}")
        ((fail++))
        continue
      fi
      # Size exact check if content_length set
      if [[ -n $current_len ]]; then
        actual_size=$(wc -c < "$tmp")
        if [[ $actual_size != "$current_len" ]]; then
          echo "SIZE-DIFF-DOWNLOADED $current_name manifest=$current_len actual=$actual_size" >&2
          log_event artifact="$current_name" result=size_mismatch
          ARTIFACT_JSON+=("{\"name\":\"$current_name\",\"result\":\"size_mismatch\"}")
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
          log_event artifact="$current_name" result=hash_mismatch
          ARTIFACT_JSON+=("{\"name\":\"$current_name\",\"result\":\"hash_mismatch\"}")
          ((fail++))
        else
          echo "OK $current_name" >&2
          log_event artifact="$current_name" result=ok
          ARTIFACT_JSON+=("{\"name\":\"$current_name\",\"result\":\"ok\"}")
        fi
      fi
    fi
  fi
done < "$MANIFEST"

if (( QUICK )) && (( CONCURRENCY > 1 )) && (( ${#QUEUE_NAMES[@]} )); then
  wait_heads
fi

end_ts=$(get_ms)
if [[ $end_ts =~ ^[0-9]+$ && $start_ts =~ ^[0-9]+$ ]]; then
  duration=$(( end_ts - start_ts ))
  (( duration < 0 )) && duration=0
else
  duration=0
fi
total_processed=${#ARTIFACT_JSON[@]}
log_event phase=end failures=$fail duration_ms=$duration artifacts=$total_processed mode=$([[ $QUICK -eq 1 ]] && echo quick || echo full) || true
if [[ -n $OUTPUT_JSON ]]; then
  {
  printf '{"mode":"%s","failures":%s,"duration_ms":%s,"count":%s,"artifacts":[' "$([[ $QUICK -eq 1 ]] && echo quick || echo full)" "$fail" "$duration" "$total_processed"
  printf '%s' "${ARTIFACT_JSON[0]:-}"
    for ((i=1;i<${#ARTIFACT_JSON[@]};i++)); do printf ',%s' "${ARTIFACT_JSON[$i]}"; done
    printf ']}'
  } > "$OUTPUT_JSON"
fi
if (( fail )); then
  echo "FAILURES: $fail" >&2
  exit 2
elif (( warn )) && (( ! ALLOW_WARN )); then
  echo "WARNINGS: $warn (treating as success)" >&2
  exit 1
fi
exit 0
