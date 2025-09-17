#!/usr/bin/env bash
# cross-platform.sh - Shared utilities (logging, platform detection, safety helpers)
# Sourced by other scripts. Keep POSIX-ish where reasonable.

# Only set strict mode when executed directly under Bash (not when sourced, and never from zsh).
if [[ -n "${BASH_VERSION:-}" ]]; then
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ ${STRICT_MODE:-0} == 1 || -n ${CI:-} ]]; then
      set -Eeuo pipefail
    else
      set -o pipefail
    fi
  fi
fi

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

# Timing functions
start_timer() {
    local operation="$1"
    export STEP_START_TIME=$(date +%s)
    log_info "Starting: $operation"
}

stop_timer() {
    local operation="$1"
    if [[ -n "${STEP_START_TIME:-}" ]]; then
        local end_time=$(date +%s)
        local elapsed=$((end_time - STEP_START_TIME))
        log_success "Completed: $operation (${elapsed}s)"
        unset STEP_START_TIME
    else
        log_success "Completed: $operation"
    fi
}

log_timed_info() {
    local timestamp=$(date +"%H:%M:%S")
    echo -e "[$timestamp] ${BLUE}[INFO]${RESET} $*"
}

log_timed_success() {
    local timestamp=$(date +"%H:%M:%S")
    echo -e "[$timestamp] ${GREEN}[OK]${RESET} $*"
}

# Trap helper (portable across bash/zsh). Avoid BASH_SOURCE when not in bash.
__cp_script_name() {
  if [[ -n "${BASH_VERSION:-}" ]]; then
    echo "${BASH_SOURCE[0]}"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    # zsh-specific parameter expansion for current file
    echo "${(%):-%N}"
  else
    echo "$0"
  fi
}
trap 'log_error "Aborted at $(__cp_script_name):${LINENO}"' ERR

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
