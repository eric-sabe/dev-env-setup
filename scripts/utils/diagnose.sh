#!/usr/bin/env bash
# diagnose.sh - Aggregated environment diagnostic wrapper.
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cross-platform.sh"

OUTPUT_DIR=${1:-diagnostics-$(date +%Y%m%d-%H%M%S)}
mkdir -p "$OUTPUT_DIR"

log_info "Collecting diagnostics into $OUTPUT_DIR"

section() { echo -e "\n==== $1 ===="; }

{
  section "System"; uname -a; date
  section "Platform"; echo "Detected: $PLATFORM"
  section "Disk"; df -h
  section "Memory"; free -h 2>/dev/null || vm_stat 2>/dev/null
  section "Top Processes"; ps axo pid,%cpu,%mem,command | head -n 15
  section "Git Versions"; command_exists git && git --version || echo 'git missing'
  section "Languages"; for c in python3 node java gcc; do echo -n "$c: "; command -v $c >/dev/null && $c --version 2>&1 | head -n1 || echo 'missing'; done
  section "Containers"; command_exists docker && docker --version || echo 'docker missing'
  section "Package Managers"; for c in brew apt yum pacman snap; do command -v $c >/dev/null && echo "$c present"; done
} > "$OUTPUT_DIR/summary.txt" 2>&1 || true

log_success "Diagnostics written to $OUTPUT_DIR/summary.txt"
