#!/usr/bin/env bash
# compute-fingerprint.sh
# Print the 40-hex GPG fingerprint for one or more remote key URLs.
# Usage: scripts/security/compute-fingerprint.sh <url> [<url> ...]

set -Eeuo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <url> [<url> ...]" >&2
  exit 1
fi

for url in "$@"; do
  tmp_key=$(mktemp)
  if ! curl -fsSL "$url" -o "$tmp_key"; then
    echo "URL:$url FPR:ERROR(download)" >&2
    rm -f "$tmp_key"
    continue
  fi
  export GNUPGHOME="$(mktemp -d)"
  fpr=$(gpg --show-keys --with-colons "$tmp_key" 2>/dev/null | awk -F: '/^fpr/ {print $10; exit}') || fpr=""
  rm -f "$tmp_key"; rm -rf "$GNUPGHOME"
  if [[ -z ${fpr} ]]; then
    echo "URL:$url FPR:ERROR(parse)" >&2
  else
    # normalize to uppercase
    fpr_uc=$(echo "$fpr" | tr '[:lower:]' '[:upper:]')
    echo "URL:$url FPR:$fpr_uc"
  fi
done
