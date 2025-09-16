#!/usr/bin/env bash
# License aggregator stub
set -Eeuo pipefail
OUT="THIRD_PARTY_LICENSES.md"
cat > "$OUT" <<EOF
# Third-Party Licenses (Stub)

This file will enumerate third-party component licenses in a future phase.
EOF
echo "License stub written to $OUT" >&2
