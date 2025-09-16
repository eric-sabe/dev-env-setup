#!/usr/bin/env bash
# Version Resolver (Phase 1 Skeleton)
# Loads manifests/versions.yaml and exposes helper query functions.
# Future phases: checksum mapping, source URLs, profile expansion.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ ${STRICT_MODE:-0} == 1 || -n ${CI:-} ]]; then
    set -Eeuo pipefail
  else
    set -o pipefail
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR%/scripts/utils*}"
VERSIONS_FILE="${REPO_ROOT}/manifests/versions.yaml"

if ! command -v awk >/dev/null || ! command -v grep >/dev/null; then
  echo "[resolver] Missing basic text utilities (awk/grep)." >&2
  exit 1
fi

if [[ ! -f "$VERSIONS_FILE" ]]; then
  echo "[resolver] versions.yaml not found at $VERSIONS_FILE" >&2
  exit 1
fi

# Simple cache
_RESOLVER_CACHE_LOADED=false
_RESOLVER_TMP="${TMPDIR:-/tmp}/versions.$$.$RANDOM"
mkdir -p "$_RESOLVER_TMP"

resolver_load() {
  if $_RESOLVER_CACHE_LOADED; then return 0; fi
  # Minimal parse: key: "value" or key: value (no nested objects besides our known groups processed ad hoc)
  # For portability avoid yq until later phase.
  awk 'NF && $1 !~ /^#/ {print}' "$VERSIONS_FILE" > "$_RESOLVER_TMP/flat.txt"
  _RESOLVER_CACHE_LOADED=true
}

# Get Python runtime preferred version
get_python_runtime() {
  resolver_load
  awk '/python:/, /runtime:/' "$VERSIONS_FILE" >/dev/null 2>&1 # noop for readability
  grep -E '^\s*preferred:' "$VERSIONS_FILE" | head -1 | awk '{print $2}'
}

# List python packages for a category (supports dot notation e.g. extras.nlp)
list_python_category() {
  local category="$1"
  resolver_load
  # Translate dot path to awk range: e.g., extras.nlp -> extras: then nlp:
  if [[ "$category" == *.* ]]; then
    local top="${category%%.*}" rest="${category#*.}"
    # Narrow to top-level block first
    local block
    block=$(awk "/${top}:/,/^[[:space:]]*[a-z]+:/" "$VERSIONS_FILE")
    # Then search inside that block for the rest subcategory
    echo "$block" | awk "/${rest}:/,/^[[:space:]]*[a-z]+:/" | \
      grep -E '^[[:space:]]+[a-zA-Z0-9_.@-]+:' | sed -E 's/["'\'']//g' | awk -F: '{gsub(/ /,"",$2); print $1"="$2}'
  else
    awk "/${category}:/,/^[[:space:]]*[a-z]+:/" "$VERSIONS_FILE" | \
      grep -E '^[[:space:]]+[a-zA-Z0-9_.@-]+:' | sed -E 's/["'\'']//g' | awk -F: '{gsub(/ /,"",$2); print $1"="$2}'
  fi
}

# List node globals for profile (minimal/full)
list_node_globals_profile() {
  local profile="$1"
  resolver_load
  # Extract array entries under node_globals for the profile
  awk "/${profile}:/,/^[[:space:]]*[a-z]+:/" "$VERSIONS_FILE" \
    | grep -E 'node_globals:' -A5 | grep -E "[-']" \
    | sed -E 's/^[[:space:]]*-[[:space:]]*//; s/["\'\']//g'
}

# Get version for a node global tool name (from top-level node.globals mapping) if present
get_node_global_version() {
  local name="$1"
  resolver_load
  # Search under node: then globals:
  awk '/node:/,/profiles:/' "$VERSIONS_FILE" | awk '/globals:/, /profiles:/' | \
    grep -E "^[[:space:]]+[A-Za-z0-9_@\-]+:" | sed -E 's/^[[:space:]]*//; s/["\'\']//g' | \
    awk -F: -v target="$name" '{gsub(/ /,"",$2); if($1==target){print $2}}' | head -1
}

# List linux apt group packages
list_linux_apt_group() {
  local group="$1"
  resolver_load
  awk '/linux:/,/macos:/' "$VERSIONS_FILE" | awk '/apt:/,/macos:/' | \
    awk "/${group}:/,/^[[:space:]]*[^-]/" | grep -E '^[[:space:]]+-' | sed -E 's/^[[:space:]]+-[[:space:]]*//'
}

# List macOS brew group packages
list_macos_brew_group() {
  local group="$1"
  resolver_load
  awk '/macos:/,/profiles:/' "$VERSIONS_FILE" | awk '/brew:/,/profiles:/' | \
    awk "/${group}:/,/^[[:space:]]*[^-]/" | grep -E '^[[:space:]]+-' | sed -E 's/^[[:space:]]+-[[:space:]]*//'
}

# Return python package exact spec (name==version pattern) for category + package name
get_python_package_spec() {
  local category="$1"; shift; local pkg="$1"
  list_python_category "$category" | awk -F= -v p="$pkg" '{if($1==p){print $1"=="$2}}'
}

# Error if missing required key later phases will enforce JSON schema
assert_version_exists() {
  local key="$1"; shift
  if ! grep -q "$key" "$VERSIONS_FILE"; then
    echo "[resolver] Missing key: $key" >&2
    return 1
  fi
}

# Example aggregated pip install arguments for a category
build_pip_install_args() {
  local category="$1"
  list_python_category "$category" | awk -F= '{print $1"=="$2}' | xargs echo
}

# Cleanup trap
cleanup_resolver_tmp() { rm -rf "$_RESOLVER_TMP" || true; }
trap cleanup_resolver_tmp EXIT

# Self-test when executed directly
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  echo "python_runtime=$(get_python_runtime)"
  echo "core_pip=$(build_pip_install_args core)"
fi
