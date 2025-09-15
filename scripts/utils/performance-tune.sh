#!/usr/bin/env bash
# performance-tune.sh - Lightweight performance tuning suggestions.
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cross-platform.sh"

log_info "Performance tune advisory starting (no destructive changes)."

# CPU governor (Linux)
if [[ $PLATFORM == ubuntu || $PLATFORM == redhat || $PLATFORM == arch ]]; then
  if command_exists cpupower; then
    log_info "Current CPU frequency governor:"; cpupower frequency-info | grep 'governor' || true
  fi
fi

# List top memory consumers
log_info "Top memory consumers:"; ps axo pid,%mem,%cpu,command | sort -k2 -r | head -n 10

# I/O stats if available
if command_exists iostat; then
  log_info "iostat snapshot:"; iostat -xz 1 1 || true
fi

log_success "Performance snapshot complete. No system changes made."
