#!/usr/bin/env bash
# semester-archive.sh - Archive current semester projects & notes.
set -Eeuo pipefail
trap 'echo "[ERROR] Aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cross-platform.sh"

SEMESTER_LABEL=${1:-$(date +%Y)-S?}
ARCHIVE_ROOT=${ARCHIVE_ROOT:-$HOME/semester-archives}
SRC_DIRS=${SRC_DIRS:-"$HOME/dev $HOME/projects"}
mkdir -p "$ARCHIVE_ROOT"

ARCHIVE_DIR="$ARCHIVE_ROOT/$SEMESTER_LABEL"
mkdir -p "$ARCHIVE_DIR"

log_info "Archiving semester '$SEMESTER_LABEL' into $ARCHIVE_DIR"

for dir in $SRC_DIRS; do
  if [[ -d $dir ]]; then
    base=$(basename "$dir")
    tarball="$ARCHIVE_DIR/${base}.tar.gz"
    log_info "Compressing $dir -> $tarball"
    tar -czf "$tarball" -C "$(dirname "$dir")" "$base"
  else
    log_warn "Skip missing directory: $dir"
  fi
done

log_success "Semester archive complete."
