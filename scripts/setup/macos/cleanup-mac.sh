#!/usr/bin/env bash
# cleanup-mac.sh - macOS focused cleanup wrapper (delegates heavy logic to cleanup-dev.sh)
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR%/scripts/*}"
UTIL_DIR="$ROOT_DIR/scripts/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"

log_info "macOS cleanup wrapper starting"

# Example: purge Homebrew cache safely
if command -v brew &>/dev/null; then
  brew cleanup -s || true
  rm -rf "$(brew --cache)"/* || true
  log_success "Brew caches cleaned"
fi

log_info "Invoking generic cleanup script (interactive)"
"$ROOT_DIR/scripts/cleanup-dev.sh" || true

log_success "macOS cleanup completed"
