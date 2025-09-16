#!/usr/bin/env bash
# EXPERIMENTAL: Rollback stub (Phase 4) - interface & behavior subject to change.
# Minimal uninstall support for select components.
# Current scope: global npm packages (manifest node.globals), user-site pip packages (from manifest groups).
# Future: apt/brew removal with safety prompts, service disablement.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/versions.yaml"

usage(){ cat <<EOF
Usage: $0 [--no-dry-run] [--npm-globals] [--pip-group <group>]... [--list-brew] [--list-apt]
Default is dry-run (prints actions). Use --no-dry-run to actually uninstall.
Examples:
  $0 --npm-globals --pip-group core --pip-group ml
  $0 --list-brew --list-apt
EOF
}

DRY=1; REMOVE_NPM=0; PIP_GROUPS=(); LIST_BREW=0; LIST_APT=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY=1; shift;; # backward compatibility
    --no-dry-run) DRY=0; shift;;
    --npm-globals) REMOVE_NPM=1; shift;;
    --pip-group) PIP_GROUPS+=("$2"); shift 2;;
    --list-brew) LIST_BREW=1; shift;;
    --list-apt) LIST_APT=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -f $MANIFEST ]] || { echo "Missing manifest $MANIFEST" >&2; exit 3; }

remove_npm(){
  echo "[rollback] npm globals" >&2
  pkgs=$(awk '/^node:/{f=1} f && /globals:/ {g=1;next} g && /^[[:space:]]+[A-Za-z0-9@_-]+:/ {sub(":.*","",$1); print $1} g && /^[^[:space:]]/ {exit}' "$MANIFEST")
  for p in $pkgs; do
    echo "  npm -g rm $p" >&2
    (( DRY )) || npm -g rm "$p" || true
  done
}

remove_pip_group(){
  group="$1"
  echo "[rollback] pip group $group" >&2
  # naive extraction: find group header then collect key: version lines until blank or dedent
  collecting=0
  while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*$group: ]]; then collecting=1; continue; fi
    if (( collecting )); then
      if [[ $line =~ ^[[:space:]]*[A-Za-z0-9._-]+: ]]; then
        pkg=$(echo "$line" | sed -E 's/^[[:space:]]*([A-Za-z0-9._-]+):.*/\1/')
        echo "  pip uninstall -y $pkg" >&2
        (( DRY )) || pip uninstall -y "$pkg" || true
      elif [[ $line =~ ^[[:space:]]*$ || $line =~ ^[^[:space:]] ]]; then
        break
      fi
    fi
  done < "$MANIFEST"
}

(( REMOVE_NPM )) && remove_npm
for g in "${PIP_GROUPS[@]:-}"; do
  remove_pip_group "$g"
done

if (( LIST_BREW )); then
  if command -v brew >/dev/null 2>&1; then
    echo "[rollback] brew leaves (candidates)" >&2
    brew leaves 2>/dev/null | sed 's/^/  brew uninstall /' >&2 || true
  else
    echo "[rollback] brew not found" >&2
  fi
fi

if (( LIST_APT )); then
  if command -v apt >/dev/null 2>&1; then
    echo "[rollback] apt installed (filtered common dev pkgs)" >&2
    apt list --installed 2>/dev/null | grep -E 'build-essential|cmake|git|python3|nodejs' | cut -d/ -f1 | sed 's/^/  sudo apt remove /' >&2 || true
  else
    echo "[rollback] apt not found" >&2
  fi
fi

echo "Rollback stub complete (dry-run=$DRY)." >&2
