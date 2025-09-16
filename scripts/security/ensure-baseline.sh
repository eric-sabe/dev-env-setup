#!/usr/bin/env bash
# Ensure baseline/archives.json exists; generate if missing using existing generator.
# Idempotent: does nothing if file present.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINE_DIR="$ROOT_DIR/baseline"
BASELINE_FILE="$BASELINE_DIR/archives.json"
GENERATOR="$ROOT_DIR/scripts/security/generate-archives-baseline.sh"
mkdir -p "$BASELINE_DIR"
if [[ -f $BASELINE_FILE ]]; then
  echo "Baseline exists: $BASELINE_FILE"
  exit 0
fi
if [[ ! -f $GENERATOR ]]; then
  echo "Baseline generator not found: $GENERATOR" >&2
  exit 2
fi
# Always invoke via bash to avoid reliance on executable bits
bash "$GENERATOR"
echo "Baseline generated: $BASELINE_FILE"
