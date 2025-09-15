#!/usr/bin/env bash
# emergency-recovery.sh - Last resort environment recovery guidance & minimal automated steps.
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cross-platform.sh"

log_info "Starting emergency recovery procedure"
log_warn "This script performs minimal automated actions. Review before continuing."

if ! confirm "Proceed with emergency recovery"; then
  log_info "Cancelled by user."; exit 0
fi

# 1. Capture diagnostic snapshot
SNAPSHOT_DIR=${HOME}/dev-emergency-$(date +%Y%m%d-%H%M%S)
mkdir -p "$SNAPSHOT_DIR"
log_info "Collecting diagnostics into $SNAPSHOT_DIR"
{
  echo "# System Info"; uname -a
  echo; echo "# Disk Usage"; df -h
  echo; echo "# Memory"; free -h 2>/dev/null || vm_stat 2>/dev/null
  echo; echo "# Top Processes"; ps axo pid,ppid,%cpu,%mem,command | head -n 25
} > "$SNAPSHOT_DIR/system.txt" 2>&1 || true

# 2. Optional package manager database repairs (interactive)
case $PLATFORM in
  ubuntu)
    log_info "Running apt repair (non-destructive)"
    sudo apt update || true
    sudo apt -f install || true
    sudo dpkg --configure -a || true
    ;;
  redhat)
    sudo yum check || true
    ;;
  arch)
    sudo pacman -Syy || true
    ;;
  macos)
    brew doctor || true
    ;;
esac

log_success "Recovery baseline actions completed"
log_info "Review diagnostics: $SNAPSHOT_DIR"
log_info "Next manual steps: restore from latest backup or rerun setup scripts."
