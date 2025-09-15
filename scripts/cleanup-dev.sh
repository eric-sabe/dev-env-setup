#!/bin/bash
# Development Environment Cleanup Script
# Cleans up and refreshes development environments

set -Eeuo pipefail  # Stricter error handling
trap 'echo "[ERROR] Cleanup failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

# Attempt to source shared utilities if present
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/utils"
if [[ -f "$UTILS_DIR/cross-platform.sh" ]]; then
    # shellcheck disable=SC1091
    source "$UTILS_DIR/cross-platform.sh"
fi

# Flags & Args
DRY_RUN=false
ASSUME_YES=false
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        -y|--yes) ASSUME_YES=true ;;
    esac
done

confirm_action() {
    local msg=${1:-"Proceed?"}
    if [[ $ASSUME_YES == true ]]; then return 0; fi
    read -r -p "$msg (y/N): " ans
    [[ $ans =~ ^[Yy]$ ]]
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]] || [[ "$ID" == "pop" ]] || [[ "$ID" == "elementary" ]] || [[ "$ID" == "linuxmint" ]]; then
                PLATFORM="ubuntu"
            elif [[ "$ID" == "centos" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "fedora" ]]; then
                PLATFORM="redhat"
            elif [[ "$ID" == "arch" ]] || [[ "$ID" == "manjaro" ]]; then
                PLATFORM="arch"
            else
                PLATFORM="linux"
            fi
        else
            PLATFORM="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        PLATFORM="windows"
    else
        log_error "Unsupported platform: $OSTYPE"
        exit 1
    fi

    log_success "Detected platform: $PLATFORM"
}

# Clean package manager caches
clean_package_caches() {
    log_info "Cleaning package manager caches..."

    case $PLATFORM in
        macos)
            # Clean Homebrew cache
            brew cleanup -s
            brew autoremove
            ;;
        ubuntu)
            # Clean apt cache
            sudo apt autoremove -y
            sudo apt autoclean
            sudo apt clean
            ;;
        redhat)
            # Clean yum/dnf cache
            sudo yum clean all
            sudo yum autoremove -y
            ;;
        arch)
            # Clean pacman cache
            sudo pacman -Scc --noconfirm
            ;;
        windows)
            log_info "Clean Windows package caches manually"
            ;;
    esac

    log_success "Package manager caches cleaned"
}

# Clean development tool caches
clean_dev_caches() {
    log_info "Cleaning development tool caches..."

    # Clean npm cache
    if command -v npm &>/dev/null; then
        if confirm_action "Purge npm cache?"; then
            npm cache clean --force || true
            log_success "npm cache cleaned"
        else
            log_info "Skipped npm cache"
        fi
    fi

    # Clean yarn cache
    if command -v yarn &>/dev/null; then
        yarn cache clean
        log_success "yarn cache cleaned"
    fi

    # Clean pip cache
    if command -v pip &>/dev/null; then
        pip cache purge
        log_success "pip cache cleaned"
    fi

    # Clean Maven cache
    if [[ -d "$HOME/.m2/repository" ]]; then
        if confirm_action "Delete Maven local repository cache?"; then
            safe_rm_rf "$HOME/.m2/repository"/*
            log_success "Maven cache cleaned"
        fi
    fi

    # Clean Gradle cache
    if [[ -d "$HOME/.gradle/caches" ]]; then
        if confirm_action "Delete Gradle caches?"; then
            safe_rm_rf "$HOME/.gradle/caches"/*
            log_success "Gradle cache cleaned"
        fi
    fi

    # Clean Rust cache
    if command -v cargo &>/dev/null; then
        cargo cache --autoclean
        log_success "Cargo cache cleaned"
    fi

    # Clean Go cache
    if command -v go &>/dev/null; then
        go clean -cache
        go clean -modcache
        log_success "Go cache cleaned"
    fi

    # Clean Docker
    if command -v docker &>/dev/null; then
        docker system prune -f
        docker volume prune -f
        log_success "Docker cleaned"
    fi
}

# Clean IDE caches
clean_ide_caches() {
    log_info "Cleaning IDE caches (interactive)..."
    if confirm_action "Purge VS Code cache?" && [[ -d "$HOME/.vscode" ]]; then
        safe_rm_rf "$HOME/.vscode/Cache"/* || true
        safe_rm_rf "$HOME/.vscode/CachedData"/* || true
        log_success "VS Code cache cleaned"
    fi
    if confirm_action "Purge IntelliJ IDEA caches?" && compgen -G "$HOME/.IntelliJIdea*" > /dev/null; then
        for d in $HOME/.IntelliJIdea*/system/caches; do [[ -d $d ]] && safe_rm_rf "$d"/*; done
        log_success "IntelliJ IDEA cache cleaned"
    fi
    if confirm_action "Purge Android Studio caches?" && compgen -G "$HOME/.AndroidStudio*" > /dev/null; then
        for d in $HOME/.AndroidStudio*/system/caches; do [[ -d $d ]] && safe_rm_rf "$d"/*; done
        log_success "Android Studio cache cleaned"
    fi
    if [[ "$PLATFORM" == "macos" ]] && confirm_action "Purge Xcode DerivedData?" && [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
        safe_rm_rf "$HOME/Library/Developer/Xcode/DerivedData"/*
        log_success "Xcode DerivedData cleaned"
    fi
}

# Clean temporary files
clean_temp_files() {
    log_info "Cleaning temporary files..."

    # Clean system temp directories
    if [[ -d "/tmp" ]]; then
        sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
        log_success "System temp files cleaned"
    fi

    # Clean user temp directories
    if [[ -d "$HOME/tmp" ]]; then
        find "$HOME/tmp" -type f -atime +7 -delete 2>/dev/null || true
        log_success "User temp files cleaned"
    fi

    # Clean bash history (optional)
    if [[ "$CLEAN_BASH_HISTORY" == "true" ]]; then
        cat /dev/null > "$HOME/.bash_history"
        log_success "Bash history cleaned"
    fi
}

# Clean development project caches
clean_project_caches() {
    log_info "Cleaning development project caches..."

    # Find and clean common project directories
    if confirm_action "Delete project build caches (build,target,dist,node_modules, etc.)?"; then
        for pattern in node_modules .gradle build target .next .nuxt dist .cache; do
            find "$HOME/dev" -type d -name "$pattern" -prune -print 2>/dev/null | while read -r d; do
                safe_rm_rf "$d"
            done
        done
        log_success "Project caches cleaned"
    else
        log_info "Skipped project caches"
    fi
}

# Clean logs
clean_logs() {
    log_info "Cleaning log files..."

    # Clean system logs (be careful!)
    case $PLATFORM in
        ubuntu)
            sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
            ;;
        redhat)
            sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
            ;;
    esac

    # Clean user logs
    find "$HOME" -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true

    log_success "Log files cleaned"
}

# Refresh development environment
refresh_environment() {
    log_info "Refreshing development environment..."

    # Refresh package managers
    case $PLATFORM in
        macos)
            brew update
            brew upgrade
            ;;
        ubuntu)
            sudo apt update
            sudo apt upgrade -y
            ;;
        redhat)
            sudo yum update -y
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
    esac

    # Refresh development tools
    if command -v npm &>/dev/null; then
        npm update -g
    fi

    if command -v yarn &>/dev/null; then
        yarn global upgrade
    fi

    if command -v pip &>/dev/null; then
        pip install --upgrade pip
    fi

    if command -v flutter &>/dev/null; then
        flutter upgrade
    fi

    if command -v rustup &>/dev/null; then
        rustup update
    fi

    log_success "Development environment refreshed"
}

# Deep clean option
deep_clean() {
    log_warning "Performing deep clean - this may take a while..."

    # Clean all caches aggressively
    clean_package_caches
    clean_dev_caches
    clean_ide_caches
    clean_temp_files
    clean_project_caches
    clean_logs

    # Additional deep cleaning
    # Remove old kernels (Linux)
    case $PLATFORM in
        ubuntu)
            sudo apt autoremove --purge -y
            ;;
        redhat)
            sudo package-cleanup --oldkernels --count=2 -y
            ;;
    esac

    # Clean journald logs
    if command -v journalctl &>/dev/null; then
        sudo journalctl --vacuum-time=7d
    fi

    log_success "Deep clean completed"
}

# Show disk usage
show_disk_usage() {
    log_info "Current disk usage:"

    if command -v df &>/dev/null; then
        df -h
    fi

    if command -v du &>/dev/null; then
        echo "Top 10 largest directories in $HOME:"
        du -sh "$HOME"/* 2>/dev/null | sort -hr | head -10
    fi
}

# Interactive menu
show_menu() {
    echo -e "${BLUE}🧹 Development Environment Cleanup Menu${NC}"
    echo "========================================"
    echo "1. Clean package manager caches"
    echo "2. Clean development tool caches"
    echo "3. Clean IDE caches"
    echo "4. Clean temporary files"
    echo "5. Clean project caches"
    echo "6. Clean log files"
    echo "7. Refresh environment"
    echo "8. Deep clean (all of the above)"
    echo "9. Show disk usage"
    echo "0. Exit"
    echo ""
}

# Main function
main() {
    # Parse command line arguments
    DEEP_CLEAN=false
    REFRESH=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --deep)
                DEEP_CLEAN=true
                shift
                ;;
            --refresh)
                REFRESH=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --deep     Perform deep clean"
                echo "  --refresh  Refresh environment after cleaning"
                echo "  --help     Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    detect_platform

    if [[ "$DEEP_CLEAN" == "true" ]]; then
        deep_clean
        if [[ "$REFRESH" == "true" ]]; then
            refresh_environment
        fi
        exit 0
    fi

    if [[ "$REFRESH" == "true" ]]; then
        refresh_environment
        exit 0
    fi

    # Interactive mode
    while true; do
        show_menu
        read -p "Choose an option (0-9): " choice

        case $choice in
            1)
                clean_package_caches
                ;;
            2)
                clean_dev_caches
                ;;
            3)
                clean_ide_caches
                ;;
            4)
                clean_temp_files
                ;;
            5)
                clean_project_caches
                ;;
            6)
                clean_logs
                ;;
            7)
                refresh_environment
                ;;
            8)
                deep_clean
                ;;
            9)
                show_disk_usage
                ;;
            0)
                log_success "Cleanup complete!"
                exit 0
                ;;
            *)
                log_error "Invalid option. Please choose 0-9."
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Run main function
main "$@"
