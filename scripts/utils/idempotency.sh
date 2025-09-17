#!/usr/bin/env bash
# idempotency.sh - Shared utilities for idempotent installations
# Usage: source this file, then call check_and_install_*, ensure_*, etc.

# Only set strict mode when executed directly under Bash (not when sourced).
if [[ -n "${BASH_VERSION:-}" ]]; then
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ ${STRICT_MODE:-0} == 1 || -n ${CI:-} ]]; then
      set -Eeuo pipefail
    else
      set -o pipefail
    fi
  fi
fi

# Source existing utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_DIR="${SCRIPT_DIR%/utils*/}/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"
[[ -f "$UTIL_DIR/verify.sh" ]] && source "$UTIL_DIR/verify.sh"

# Colors for output (reuse from cross-platform.sh if available)
if [[ -z "${BLUE:-}" ]]; then
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'
fi

# Logging functions (reuse from cross-platform.sh if available)
if ! command -v log_info &>/dev/null; then
    log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    log_success() { echo -e "${GREEN}✅ $1${NC}"; }
    log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
    log_error() { echo -e "${RED}❌ $1${NC}"; }
fi

# Check if a command is available
is_command_available() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# Check if a package is installed (apt/dpkg)
is_apt_package_installed() {
    local package="$1"
    dpkg -l "$package" 2>/dev/null | grep -q "^ii"
}

# Check if a package is installed (yum/dnf)
is_yum_package_installed() {
    local package="$1"
    rpm -q "$package" &>/dev/null
}

# Check if a package is installed (pacman)
is_pacman_package_installed() {
    local package="$1"
    pacman -Q "$package" &>/dev/null
}

# Check if a Homebrew package is installed
is_brew_package_installed() {
    local package="$1"
    brew list "$package" &>/dev/null 2>&1
}

# Check if a Python package is installed
is_python_package_installed() {
    local package="$1"
    python3 -c "import $package" &>/dev/null
}

# Check if a Node.js package is installed globally
is_npm_package_installed() {
    local package="$1"
    npm list -g "$package" &>/dev/null 2>&1
}

# Check if a service is running
is_service_running() {
    local service="$1"
    if command -v systemctl &>/dev/null; then
        systemctl is-active --quiet "$service"
    elif command -v brew &>/dev/null && brew services list 2>/dev/null | grep -q "^$service"; then
        # macOS brew services
        return 0
    else
        return 1
    fi
}

# Check if a port is in use
is_port_in_use() {
    local port="$1"
    lsof -i :"$port" &>/dev/null || (command -v ss &>/dev/null && ss -ltn 2>/dev/null | grep -q ":$port ")
}

# Check if a file/directory exists
is_path_exists() {
    local path="$1"
    [[ -e "$path" ]]
}

# Check if a directory exists and is not empty
is_directory_populated() {
    local dir="$1"
    [[ -d "$dir" ]] && [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]
}

# Generic package installer with idempotency
check_and_install_package() {
    local package="$1"
    local description="${2:-$package}"
    local installer="$3"
    local checker="$4"

    log_info "Checking for $description..."

    if $checker "$package"; then
        log_success "$description already installed"
        return 0
    fi

    log_info "Installing $description..."
    if $installer "$package"; then
        log_success "$description installed successfully"
        return 0
    else
        log_error "Failed to install $description"
        return 1
    fi
}

# Ensure a command is available (install if missing)
ensure_command() {
    local cmd="$1"
    local description="${2:-$cmd}"
    local install_func="$3"

    if is_command_available "$cmd"; then
        log_success "$description already available"
        return 0
    fi

    log_info "Installing $description..."
    if $install_func; then
        if is_command_available "$cmd"; then
            log_success "$description installed successfully"
            return 0
        else
            log_error "$description installation failed - command still not found"
            return 1
        fi
    else
        log_error "Failed to install $description"
        return 1
    fi
}

# Ensure a service is running
ensure_service_running() {
    local service="$1"
    local description="${2:-$service}"

    if is_service_running "$service"; then
        log_success "$description service already running"
        return 0
    fi

    log_info "Starting $description service..."
    if [[ -n "${PLATFORM:-}" ]]; then
        case $PLATFORM in
            macos)
                if command -v brew &>/dev/null; then
                    brew services start "$service" || true
                fi
                ;;
            ubuntu|redhat|arch)
                sudo systemctl enable "$service" || true
                sudo systemctl start "$service" || true
                ;;
        esac
    fi

    if is_service_running "$service"; then
        log_success "$description service started"
        return 0
    else
        log_warning "$description service may not be running"
        return 1
    fi
}

# Ensure a directory exists
ensure_directory() {
    local dir="$1"
    local description="${2:-directory $dir}"

    if [[ -d "$dir" ]]; then
        log_success "$description already exists"
        return 0
    fi

    log_info "Creating $description..."
    if mkdir -p "$dir"; then
        log_success "$description created"
        return 0
    else
        log_error "Failed to create $description"
        return 1
    fi
}

# Ensure a file exists with specific content
ensure_file_content() {
    local file="$1"
    local content="$2"
    local description="${3:-file $file}"

    if [[ -f "$file" ]] && [[ "$(cat "$file")" == "$content" ]]; then
        log_success "$description already has correct content"
        return 0
    fi

    log_info "Creating/updating $description..."
    if echo "$content" > "$file"; then
        log_success "$description updated"
        return 0
    else
        log_error "Failed to update $description"
        return 1
    fi
}

# Platform-specific package installers
install_apt_package() {
    local package="$1"
    sudo apt update && sudo apt install -y "$package"
}

install_yum_package() {
    local package="$1"
    if command -v dnf &>/dev/null; then
        sudo dnf install -y "$package"
    else
        sudo yum install -y "$package"
    fi
}

install_pacman_package() {
    local package="$1"
    sudo pacman -S --noconfirm "$package"
}

install_brew_package() {
    local package="$1"
    brew install "$package"
}

install_pip_package() {
    local package="$1"
    pip3 install "$package"
}

install_npm_package() {
    local package="$1"
    npm install -g "$package"
}

# High-level idempotent installers
ensure_apt_package() {
    check_and_install_package "$1" "$2" install_apt_package is_apt_package_installed
}

ensure_yum_package() {
    check_and_install_package "$1" "$2" install_yum_package is_yum_package_installed
}

ensure_pacman_package() {
    check_and_install_package "$1" "$2" install_pacman_package is_pacman_package_installed
}

ensure_brew_package() {
    check_and_install_package "$1" "$2" install_brew_package is_brew_package_installed
}

ensure_pip_package() {
    check_and_install_package "$1" "$2" install_pip_package is_python_package_installed
}

ensure_npm_package() {
    check_and_install_package "$1" "$2" install_npm_package is_npm_package_installed
}

# Cross-platform package installer
ensure_package() {
    local package="$1"
    local description="${2:-$package}"

    case ${PLATFORM:-unknown} in
        ubuntu)
            ensure_apt_package "$package" "$description"
            ;;
        redhat)
            ensure_yum_package "$package" "$description"
            ;;
        arch)
            ensure_pacman_package "$package" "$description"
            ;;
        macos)
            ensure_brew_package "$package" "$description"
            ;;
        *)
            log_warning "Unsupported platform for package installation: ${PLATFORM:-unknown}"
            return 1
            ;;
    esac
}

# Summary tracking
IDEMPOTENCY_INSTALLED=0
IDEMPOTENCY_SKIPPED=0
IDEMPOTENCY_FAILED=0

track_installation() {
    local status="$1"
    case $status in
        installed) ((IDEMPOTENCY_INSTALLED++)) ;;
        skipped) ((IDEMPOTENCY_SKIPPED++)) ;;
        failed) ((IDEMPOTENCY_FAILED++)) ;;
    esac
}

print_idempotency_summary() {
    local total=$((IDEMPOTENCY_INSTALLED + IDEMPOTENCY_SKIPPED + IDEMPOTENCY_FAILED))
    echo
    log_info "Installation Summary:"
    echo "  ✅ Installed: $IDEMPOTENCY_INSTALLED"
    echo "  ⏭️  Skipped: $IDEMPOTENCY_SKIPPED"
    echo "  ❌ Failed: $IDEMPOTENCY_FAILED"
    echo "  📊 Total: $total"

    if [[ $IDEMPOTENCY_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}