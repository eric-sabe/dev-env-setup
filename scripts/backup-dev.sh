#!/bin/bash
# Development Environment Backup Script
# Backs up development environments and projects

set -Eeuo pipefail  # Stricter error handling
trap 'echo "[ERROR] Backup failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_DIR="${SCRIPT_DIR}/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"

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

# Default backup directory
BACKUP_DIR="${BACKUP_DIR:-$HOME/dev-backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="dev_backup_$TIMESTAMP"

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

# Create backup directory
create_backup_dir() {
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"

    # Create subdirectories
    mkdir -p "$backup_path"/{projects,configs,databases,packages}

    log_success "Backup directory created: $backup_path"
    echo "$backup_path"
}

# Backup development projects
backup_projects() {
    local backup_path="$1"
    local projects_dir="$backup_path/projects"

    log_info "Backing up development projects..."

    # Backup main dev directory
    if [[ -d "$HOME/dev" ]]; then
        log_info "Backing up $HOME/dev directory..."
        tar -czf "$projects_dir/dev_projects.tar.gz" -C "$HOME" dev 2>/dev/null || true
        log_success "Dev projects backed up"
    fi

    # Backup individual project directories
    local project_dirs=("$HOME/Projects" "$HOME/workspace" "$HOME/code" "$HOME/src")
    for dir in "${project_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local dirname=$(basename "$dir")
            log_info "Backing up $dir..."
            tar -czf "$projects_dir/${dirname}.tar.gz" -C "$HOME" "$dirname" 2>/dev/null || true
            log_success "$dirname backed up"
        fi
    done
}

# Backup configuration files
backup_configs() {
    local backup_path="$1"
    local configs_dir="$backup_path/configs"

    log_info "Backing up configuration files..."

    # Shell configurations
    local shell_files=(".bashrc" ".zshrc" ".bash_profile" ".zsh_profile")
    for file in "${shell_files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            cp "$HOME/$file" "$configs_dir/"
            log_success "$file backed up"
        fi
    done

    # Git configuration
    if [[ -f "$HOME/.gitconfig" ]]; then
        cp "$HOME/.gitconfig" "$configs_dir/"
        log_success ".gitconfig backed up"
    fi

    # SSH keys (public keys only for security)
    if [[ -d "$HOME/.ssh" ]]; then
        mkdir -p "$configs_dir/ssh"
        cp "$HOME/.ssh"/*.pub "$configs_dir/ssh/" 2>/dev/null || true
        cp "$HOME/.ssh"/config "$configs_dir/ssh/" 2>/dev/null || true
        log_success "SSH public keys backed up"
    fi

    # VS Code settings
    if [[ -d "$HOME/.vscode" ]]; then
        cp -r "$HOME/.vscode" "$configs_dir/"
        log_success "VS Code settings backed up"
    fi

    # IntelliJ IDEA settings
    if [[ -d "$HOME/.IntelliJIdea"* ]]; then
        cp -r "$HOME/.IntelliJIdea"* "$configs_dir/" 2>/dev/null || true
        log_success "IntelliJ IDEA settings backed up"
    fi

    # Development tool configurations
    local config_files=(
        ".npmrc"
        ".yarnrc"
        ".pip/pip.conf"
        ".m2/settings.xml"
        ".gradle/gradle.properties"
        ".rustup/settings.toml"
        ".flutter_settings"
    )

    for file in "${config_files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            local dirname=$(dirname "$file")
            mkdir -p "$configs_dir/$dirname"
            cp "$HOME/$file" "$configs_dir/$file"
            log_success "$file backed up"
        fi
    done
}

# Backup package lists
backup_packages() {
    local backup_path="$1"
    local packages_dir="$backup_path/packages"

    log_info "Backing up package lists..."

    case $PLATFORM in
        macos)
            # Homebrew packages
            if command -v brew &>/dev/null; then
                brew list --formula > "$packages_dir/brew_packages.txt"
                brew list --cask > "$packages_dir/brew_casks.txt"
                log_success "Homebrew packages backed up"
            fi
            ;;
        ubuntu)
            # apt packages
            if command -v dpkg &>/dev/null; then
                dpkg --get-selections > "$packages_dir/apt_packages.txt"
                log_success "apt packages backed up"
            fi

            # snap packages
            if command -v snap &>/dev/null; then
                snap list > "$packages_dir/snap_packages.txt"
                log_success "snap packages backed up"
            fi
            ;;
        redhat)
            # yum/dnf packages
            if command -v npm &>/dev/null; then
                npm list -g --depth=0 > "$packages_dir/npm_packages.txt" 2>/dev/null || true
                # Also export JSON for robust parsing during restore
                npm ls -g --depth=0 --json > "$packages_dir/npm_packages.json" 2>/dev/null || true
            fi
            fi
            ;;
        arch)
            # pacman packages
            if command -v pacman &>/dev/null; then
                pacman -Q > "$packages_dir/pacman_packages.txt"
                log_success "pacman packages backed up"
            fi
            ;;
    esac

    # Python packages
    if command -v pip &>/dev/null; then
        pip list --format=freeze > "$packages_dir/pip_packages.txt"
        log_success "Python packages backed up"
    fi

    # Node.js packages
    if command -v npm &>/dev/null; then
        npm list -g --depth=0 > "$packages_dir/npm_packages.txt" 2>/dev/null || true
        log_success "npm packages backed up"
    fi

    # Ruby gems
    if command -v gem &>/dev/null; then
        gem list > "$packages_dir/gem_packages.txt"
        log_success "Ruby gems backed up"
    fi
}

# Backup databases
backup_databases() {
    local backup_path="$1"
    local databases_dir="$backup_path/databases"

    log_info "Backing up databases..."

    # PostgreSQL
    if command -v pg_dump &>/dev/null; then
        mkdir -p "$databases_dir/postgresql"
        # Get list of databases and dump each one
        psql -l -t | cut -d'|' -f1 | sed -e 's/ //g' | grep -v -E '^(template[01]|postgres)$' | while read db; do
            if [[ -n "$db" ]]; then
                pg_dump "$db" > "$databases_dir/postgresql/${db}.sql" 2>/dev/null || true
                log_success "PostgreSQL database '$db' backed up"
            fi
        done
    fi

    # MySQL/MariaDB
    if command -v mysqldump &>/dev/null; then
        mkdir -p "$databases_dir/mysql"
        mysql -e "SHOW DATABASES;" | grep -v -E '^(Database|information_schema|performance_schema|mysql|sys)$' | while read db; do
            if [[ -n "$db" ]]; then
                mysqldump "$db" > "$databases_dir/mysql/${db}.sql" 2>/dev/null || true
                log_success "MySQL database '$db' backed up"
            fi
        done
    fi

    # MongoDB
    if command -v mongodump &>/dev/null; then
        mkdir -p "$databases_dir/mongodb"
        mongodump --out "$databases_dir/mongodb/" 2>/dev/null || true
        log_success "MongoDB databases backed up"
    fi

    # Redis
    if command -v redis-cli &>/dev/null; then
        mkdir -p "$databases_dir/redis"
        redis-cli save 2>/dev/null || true
        cp /var/lib/redis/dump.rdb "$databases_dir/redis/" 2>/dev/null || true
        log_success "Redis database backed up"
    fi
}

# Create backup manifest
create_manifest() {
    local backup_path="$1"
    local manifest_file="$backup_path/backup_manifest.txt"

    log_info "Creating backup manifest..."

    cat << EOF > "$manifest_file"
Development Environment Backup Manifest
======================================

Backup Date: $(date)
Platform: $PLATFORM
Backup Name: $BACKUP_NAME
Backup Location: $backup_path

Contents:
---------

Projects:
$(ls -la "$backup_path/projects/" 2>/dev/null || echo "No projects backed up")

Configurations:
$(ls -la "$backup_path/configs/" 2>/dev/null || echo "No configurations backed up")

Packages:
$(ls -la "$backup_path/packages/" 2>/dev/null || echo "No package lists backed up")

Databases:
$(ls -la "$backup_path/databases/" 2>/dev/null || echo "No databases backed up")

System Information:
------------------
OS: $(uname -s)
Kernel: $(uname -r)
Architecture: $(uname -m)
User: $(whoami)
Home Directory: $HOME

Backup Size: $(du -sh "$backup_path" 2>/dev/null | cut -f1)

To restore this backup, run:
./restore-dev.sh --backup="$backup_path"
EOF

    log_success "Backup manifest created"
}

# Compress backup
compress_backup() {
    local backup_path="$1"
    local archive_name="${BACKUP_NAME}.tar.gz"
    local archive_path="$BACKUP_DIR/$archive_name"

    log_info "Compressing backup..."

    cd "$BACKUP_DIR"
    tar -czf "$archive_name" "$BACKUP_NAME"

    # Calculate sizes
    local original_size=$(du -sh "$backup_path" | cut -f1)
    local compressed_size=$(du -sh "$archive_path" | cut -f1)

    log_success "Backup compressed: $original_size → $compressed_size"
    log_success "Archive created: $archive_path"

    # Optionally remove uncompressed backup
    if [[ "$KEEP_UNCOMPRESSED" != "true" ]]; then
        rm -rf "$backup_path"
        log_info "Uncompressed backup removed"
    fi
}

# Show backup summary
show_summary() {
    local backup_path="$1"

    echo ""
    echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Backup Summary:${NC}"
    echo "Location: $backup_path"
    echo "Size: $(du -sh "$backup_path" 2>/dev/null | cut -f1)"
    echo "Contents:"
    echo "  Projects: $(ls "$backup_path/projects/" 2>/dev/null | wc -l) items"
    echo "  Configs: $(ls "$backup_path/configs/" 2>/dev/null | wc -l) items"
    echo "  Packages: $(ls "$backup_path/packages/" 2>/dev/null | wc -l) items"
    echo "  Databases: $(find "$backup_path/databases/" -type f 2>/dev/null | wc -l) items"
    echo ""
    echo -e "${BLUE}To restore this backup:${NC}"
    echo "./restore-dev.sh --backup=\"$backup_path\""
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name=*)
                BACKUP_NAME="${1#*=}"
                shift
                ;;
            --dir=*)
                BACKUP_DIR="${1#*=}"
                shift
                ;;
            --keep-uncompressed)
                KEEP_UNCOMPRESSED=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --name=NAME          Set backup name (default: dev_backup_TIMESTAMP)"
                echo "  --dir=DIR            Set backup directory (default: $HOME/dev-backups)"
                echo "  --keep-uncompressed  Keep uncompressed backup after compression"
                echo "  --help               Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    detect_platform

    echo -e "${BLUE}💾 Creating Development Environment Backup${NC}"
    echo -e "${BLUE}=========================================${NC}"

    local backup_path=$(create_backup_dir)

    backup_projects "$backup_path"
    backup_configs "$backup_path"
    backup_packages "$backup_path"
    backup_databases "$backup_path"
    create_manifest "$backup_path"
    compress_backup "$backup_path"

    show_summary "$backup_path"
}

# Run main function
main "$@"
