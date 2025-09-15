#!/usr/bin/env bash
# cleanup-wsl.sh - WSL focused cleanup wrapper
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR%/scripts/*}"
UTIL_DIR="$ROOT_DIR/scripts/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"

log_info "WSL cleanup wrapper starting"

# WSL specific suggestions
log_info "Trimming /var/log size (safe rotate)"
sudo find /var/log -type f -name '*.log' -size +20M -exec truncate -s 0 {} + || true

log_info "Invoking generic cleanup script (interactive)"
"$ROOT_DIR/scripts/cleanup-dev.sh" || true

log_success "WSL cleanup completed"
