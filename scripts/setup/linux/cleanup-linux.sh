#!/usr/bin/env bash
# cleanup-linux.sh - Linux focused cleanup wrapper
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR%/scripts/*}"
UTIL_DIR="$ROOT_DIR/scripts/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"

log_info "Linux cleanup wrapper starting"

# Package manager cache clearing (non-destructive)
if command -v apt &>/dev/null; then sudo apt clean || true; fi
if command -v yum &>/dev/null; then sudo yum clean all || true; fi
if command -v dnf &>/dev/null; then sudo dnf clean all || true; fi
if command -v pacman &>/dev/null; then sudo pacman -Scc --noconfirm || true; fi

log_info "Invoking generic cleanup script (interactive)"
"$ROOT_DIR/scripts/cleanup-dev.sh" || true

log_success "Linux cleanup completed"
