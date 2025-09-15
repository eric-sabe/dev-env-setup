#!/usr/bin/env bash
# diagnose.sh - Aggregated environment diagnostic wrapper.
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cross-platform.sh"

JSON_MODE="false"
OUTPUT_DIR=""

print_usage() {
  echo "Usage: diagnose.sh [--json] [output-directory]" >&2
}

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE="true"; shift ;;
    -h|--help)
      print_usage; exit 0 ;;
    *)
      ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]}"

OUTPUT_DIR=${1:-diagnostics-$(date +%Y%m%d-%H%M%S)}
mkdir -p "$OUTPUT_DIR"
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
JSON_FILE="$OUTPUT_DIR/summary.json"

log_info "Collecting diagnostics into $OUTPUT_DIR (json=$JSON_MODE)"

section() { echo -e "\n==== $1 ====\n"; }

# Gather raw data into variables for potential JSON emission
SYS_UNAME="$(uname -a 2>/dev/null || echo unknown)"
SYS_DATE="$(date 2>/dev/null || echo unknown)"
DISK_INFO="$(df -h 2>/dev/null | sed 's/"/'"'"/g')"
MEM_INFO="$( (free -h 2>/dev/null || vm_stat 2>/dev/null) | sed 's/"/'"'"/g')"
TOP_PROC="$(ps axo pid,%cpu,%mem,command | head -n 15 | sed 's/"/'"'"/g')"
GIT_VER="$( (command_exists git && git --version) 2>/dev/null || echo 'git missing')"
LANG_VERSIONS=()
for c in python3 node java gcc; do
  if command -v "$c" >/dev/null 2>&1; then
    LANG_VERSIONS+=("$c: $( $c --version 2>&1 | head -n1 | sed 's/"/'"'"/g')")
  else
    LANG_VERSIONS+=("$c: missing")
  fi
done
DOCKER_VER="$( (command_exists docker && docker --version) 2>/dev/null || echo 'docker missing')"
PKG_MANAGERS=()
for c in brew apt yum dnf pacman snap; do
  command -v "$c" >/dev/null 2>&1 && PKG_MANAGERS+=("$c")
done

{
  section "System"; echo "$SYS_UNAME"; echo "$SYS_DATE"
  section "Platform"; echo "Detected: $PLATFORM"
  section "Disk"; echo "$DISK_INFO"
  section "Memory"; echo "$MEM_INFO"
  section "Top Processes"; echo "$TOP_PROC"
  section "Git Version"; echo "$GIT_VER"
  section "Languages"; printf '%s\n' "${LANG_VERSIONS[@]}"
  section "Containers"; echo "$DOCKER_VER"
  section "Package Managers"; printf '%s present\n' "${PKG_MANAGERS[@]}"
} > "$SUMMARY_FILE" 2>&1 || true

if [[ "$JSON_MODE" == "true" ]]; then
  # Emit simple JSON (avoid requiring jq). Use \n replacement for multiline values.
  to_json_string() { echo -n "$1" | sed ':a;N;$!ba;s/\n/\\n/g'; }
  {
    echo '{'
    echo '  "system": {'
    echo '    "uname": "'"$(to_json_string "$SYS_UNAME")"'",'
    echo '    "date": "'"$(to_json_string "$SYS_DATE")"'"'
    echo '  },'
    echo '  "platform": "'"$PLATFORM"'",'
    echo '  "disk": "'"$(to_json_string "$DISK_INFO")"'",'
    echo '  "memory": "'"$(to_json_string "$MEM_INFO")"'",'
    echo '  "top_processes": "'"$(to_json_string "$TOP_PROC")"'",'
    echo '  "git": "'"$(to_json_string "$GIT_VER")"'",'
    echo '  "languages": ['
    for i in "${!LANG_VERSIONS[@]}"; do
      SEP=','; [[ $i -eq $((${#LANG_VERSIONS[@]}-1)) ]] && SEP=''
      echo '    "'"$(to_json_string "${LANG_VERSIONS[$i]}")"'"'$SEP
    done
    echo '  ],'
    echo '  "docker": "'"$(to_json_string "$DOCKER_VER")"'",'
    echo '  "package_managers": ['
    for i in "${!PKG_MANAGERS[@]}"; do
      SEP=','; [[ $i -eq $((${#PKG_MANAGERS[@]}-1)) ]] && SEP=''
      echo '    "'"${PKG_MANAGERS[$i]}"'"'$SEP
    done
    echo '  ]'
    echo '}'
  } > "$JSON_FILE" 2>/dev/null || true
  log_success "Diagnostics written to $SUMMARY_FILE and $JSON_FILE"
else
  log_success "Diagnostics written to $SUMMARY_FILE"
fi
