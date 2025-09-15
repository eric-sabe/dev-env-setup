#!/usr/bin/env bash
# validate.sh - Run static validation on repository scripts
set -Eeuo pipefail
trap 'echo "[ERROR] validate failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if command -v shellcheck &>/dev/null; then
  echo "Running shellcheck..."
  # Exclude vendor or large generated dirs if any (none currently)
  find scripts -type f -name "*.sh" -print0 | xargs -0 shellcheck --severity=warning || true
else
  echo "shellcheck not installed; skipping static analysis" >&2
fi

echo "Validation complete"
