#!/usr/bin/env bash
# verify.sh - Shared lightweight post-install verification helpers
# Usage: source this file, then call verify_command, verify_service, etc.
# Only enable strict mode when executed directly under Bash, not when sourced (e.g., from zsh).
if [[ -n "${BASH_VERSION:-}" ]]; then
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ ${STRICT_MODE:-0} == 1 || -n ${CI:-} ]]; then
      set -Eeuo pipefail
    else
      set -o pipefail
    fi
  fi
fi

PASS_COUNT=0
FAIL_COUNT=0
VERIFY_LOG=${VERIFY_LOG:-}

log_v_info() { echo -e "[VERIFY] $1"; }
log_v_pass() { echo -e "\033[0;32m[PASS]\033[0m $1"; }
log_v_fail() { echo -e "\033[0;31m[FAIL]\033[0m $1"; }

_register_pass() { PASS_COUNT=$((PASS_COUNT+1)); }
_register_fail() { FAIL_COUNT=$((FAIL_COUNT+1)); }

verify_command() {
  local cmd=$1; shift || true
  local desc=${*:-$cmd}
  if command -v "$cmd" >/dev/null 2>&1; then
    log_v_pass "Command '$desc' available ($(command -v "$cmd"))"; _register_pass
  else
    log_v_fail "Command '$desc' missing"; _register_fail
  fi
}

verify_python_import() {
  local module=$1
  if python3 - <<EOF >/dev/null 2>&1
import $module
EOF
  then
    log_v_pass "Python module '$module' import succeeded"
    _register_pass
  else
    log_v_fail "Python module '$module' import failed"
    _register_fail
  fi
}

verify_service_active() {
  local svc=$1
  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$svc"; then
    log_v_pass "Service '$svc' active"
    _register_pass
  else
    # macOS brew services fallback
    if command -v brew >/dev/null 2>&1 && brew services list 2>/dev/null | grep -q "^$svc\s"; then
      log_v_pass "Service '$svc' listed (brew services)"
      _register_pass
    else
      log_v_fail "Service '$svc' not active"
      _register_fail
    fi
  fi
}

verify_port_listening() {
  local port=$1
  if lsof -i :"$port" >/dev/null 2>&1 || (command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":$port "); then
    log_v_pass "Port $port listening"
    _register_pass
  else
    log_v_fail "Port $port not listening"
    _register_fail
  fi
}

verify_node_package() {
  local pkg=$1
  if npm list -g --depth=0 2>/dev/null | grep -q " $pkg@"; then
    log_v_pass "Global npm package '$pkg' present"
    _register_pass
  else
    log_v_fail "Global npm package '$pkg' missing"
    _register_fail
  fi
}

print_verification_summary() {
  local total=$((PASS_COUNT+FAIL_COUNT))
  echo "[VERIFY] Summary: $PASS_COUNT passed / $FAIL_COUNT failed (total $total)"
  if [[ $FAIL_COUNT -gt 0 ]]; then
    return 1
  fi
  return 0
}

# Optional automatic summary on exit if AUTO_VERIFY_SUMMARY=1
if [[ "${AUTO_VERIFY_SUMMARY:-}" == "1" ]]; then
  trap print_verification_summary EXIT
fi
