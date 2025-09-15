#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

log() { printf "[smoke] %s\n" "$*"; }

log "Resolver sample output"
if [[ -x scripts/utils/version-resolver.sh ]]; then
  source scripts/utils/version-resolver.sh
  if declare -f load_versions >/dev/null; then
    load_versions manifests/versions.yaml || true
    declare -f list_python_category >/dev/null && list_python_category core || true
  fi
fi

log "Running pin audit"
bash scripts/validation/verify-pins.sh || { log "Pin audit failed"; exit 1; }

log "Generating docs (dry)"
bash scripts/tools/generate-docs.sh >/dev/null 2>&1 || { log "Doc gen failed"; exit 1; }

log "Basic smoke complete"
