#!/usr/bin/env bash
# Pin Audit Script (Phase 1 Stub)
# Ensures critical install commands reference versions manifest instead of raw unpinned installs.
# Future: Parse AST / use heuristics; current: simple grep pattern detection.

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAIL=0

# Patterns considered unsafe (to be refined):
# - pip install <pkg> (no == and not handled by resolver) inside course scripts
# - npm install -g <pkg> (without explicit version & not create-react-app scaffolding)
# Exclusions: comments, lines invoking version-resolver, yarn/pnpm internal caches.

scan_file() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"
  while IFS= read -r line; do
    case "$line" in
      *'#'* ) ;; # skip commented lines
      *version-resolver* ) ;; # skip resolver lines
      *pip_install*'()'* ) continue ;; # helper function definition
      *'pip install -r'* ) continue ;; # requirements file (treated separately later phases)
      *pip*install* )
        # Allow pip install lines that install variable expansions derived from resolver (contain build_pip_install_args or manifest_pip_group usage earlier)
        if echo "$line" | grep -qE 'pip (install|install --user)'; then
          if echo "$line" | grep -q '\$core_pkgs\|\$viz_pkgs\|manifest_pip_group\|build_pip_install_args\|\$web_pkgs\|\$db_pkgs' >/dev/null 2>&1; then :; 
          elif ! echo "$line" | grep -q '=='; then
            echo "[UNPINNED] $rel: $line" >&2; FAIL=1
          fi
        fi
        ;;
      *npm*install*-g* )
        # Allow resolver-driven installs when version is resolved on separate line or variable
        if echo "$line" | grep -qE 'npm install -g'; then
          if echo "$line" | grep -q '\${pkg}@\${pinned}' || echo "$line" | grep -q '\$pkg'; then :;
          elif echo "$line" | grep -q 'typescript yarn pnpm create-react-app @vue/cli @angular/cli'; then :; # legacy fallback block (will be removed)
          elif ! echo "$line" | grep -qE '@[0-9]'; then
            echo "[UNPINNED] $rel: $line" >&2; FAIL=1
          fi
        fi
        ;;
    esac
  done < "$file"
}

# Scan target directories
find "$ROOT_DIR/scripts/courses" -type f -name '*.sh' -print0 | while IFS= read -r -d '' f; do scan_file "$f"; done

if [[ $FAIL -eq 1 ]]; then
  echo "Pin audit failed. Refactor to use manifest-driven installs." >&2
  exit 2
else
  echo "Pin audit passed." >&2
fi
