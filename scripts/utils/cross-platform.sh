#!/usr/bin/env bash
# cross-platform.sh - Shared utilities (logging, platform detection, safety helpers)
# Sourced by other scripts. Keep POSIX-ish where reasonable.

set -Eeuo pipefail

# Colors (fallback if no tty)
if [[ -t 1 ]]; then
  RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; BOLD="\033[1m"; RESET="\033[0m"
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi

log_info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
log_success() { echo -e "${GREEN}[OK]${RESET} $*"; }

# Trap helper
trap 'log_error "Aborted at ${BASH_SOURCE[0]}:${LINENO}"' ERR

command_exists() { command -v "$1" &>/dev/null; }

# Detect platform: sets PLATFORM (macos|ubuntu|redhat|arch|wsl|windows|unknown)
_detect_platform_internal() {
  local ostype=$(uname -s | tr '[:upper:]' '[:lower:]')
  case $ostype in
    darwin*) PLATFORM="macos" ;;
    linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then PLATFORM="wsl"; else
        if [[ -f /etc/os-release ]]; then
          . /etc/os-release
          case ${ID_LIKE:-$ID} in
            *debian*) PLATFORM="ubuntu" ;;
            *rhel*|*fedora*) PLATFORM="redhat" ;;
            *arch*) PLATFORM="arch" ;;
            *) PLATFORM="linux" ;;
          esac
        else
          PLATFORM="linux"
        fi
      fi ;;
    msys*|cygwin*|mingw*) PLATFORM="windows" ;;
    *) PLATFORM="unknown" ;;
  esac
  export PLATFORM
}

_detect_platform_internal

require_cmd() {
  for c in "$@"; do
    if ! command_exists "$c"; then
      log_error "Required command '$c' not found in PATH"; return 1
    fi
  done
}

confirm() {
  local prompt=${1:-"Continue?"}
  read -r -p "$prompt (y/N): " ans
  [[ $ans =~ ^[Yy]$ ]]
}

# Safe deletion wrapper (prints when DRY_RUN=true)
safe_rm_rf() {
  local target="$1"
  [[ -z ${target} ]] && { log_error "safe_rm_rf: empty target"; return 1; }
  case "$target" in
    /|/*' ..'*|"" ) log_error "Refusing dangerous path: $target"; return 1;;
  esac
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "(dry-run) rm -rf -- "$target""
  else
    rm -rf -- "$target"
  fi
}

# Usage metrics stub (future): collect simple stats
collect_metric() { :; }
