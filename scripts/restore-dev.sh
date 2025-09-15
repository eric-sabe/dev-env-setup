#!/bin/bash
# Development Environment Restore Script
# Restores development environments from backups

set -e  # Exit on any error

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

# Find and validate backup
find_backup() {
    local backup_path="$1"

    # If no backup specified, look for the most recent
    if [[ -z "$backup_path" ]]; then
        local backup_dir="${BACKUP_DIR:-$HOME/dev-backups}"
        if [[ -d "$backup_dir" ]]; then
            backup_path=$(find "$backup_dir" -name "dev_backup_*" -type d | sort | tail -1)
            if [[ -z "$backup_path" ]]; then
                # Look for compressed backups
                backup_path=$(find "$backup_dir" -name "dev_backup_*.tar.gz" | sort | tail -1)
                if [[ -n "$backup_path" ]]; then
                    # Extract compressed backup
                    local extract_dir="$backup_dir/$(basename "$backup_path" .tar.gz)"
                    mkdir -p "$extract_dir"
                    tar -xzf "$backup_path" -C "$backup_dir"
                    backup_path="$extract_dir"
                fi
            fi
        fi
    fi

    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory not found: $backup_path"
        echo "Available backups:"
        find "${BACKUP_DIR:-$HOME/dev-backups}" -name "dev_backup_*" -type d 2>/dev/null | head -10
        exit 1
    fi

    # Validate backup manifest
    if [[ ! -f "$backup_path/backup_manifest.txt" ]]; then
        log_warning "Backup manifest not found. This may not be a valid backup."
    else
        log_info "Backup manifest found. Validating backup..."
        cat "$backup_path/backup_manifest.txt"
    fi

    echo "$backup_path"
}

# Restore projects
restore_projects() {
    local backup_path="$1"
    local projects_dir="$backup_path/projects"

    if [[ ! -d "$projects_dir" ]]; then
        log_warning "No projects to restore"
        return
    fi

    log_info "Restoring development projects..."

    # Restore dev directory
    if [[ -f "$projects_dir/dev_projects.tar.gz" ]]; then
        log_info "Restoring dev directory..."
        mkdir -p "$HOME"
        tar -xzf "$projects_dir/dev_projects.tar.gz" -C "$HOME"
        log_success "Dev directory restored"
    fi

    # Restore other project directories
    for archive in "$projects_dir"/*.tar.gz; do
        if [[ "$archive" != "$projects_dir/dev_projects.tar.gz" ]]; then
            local dirname=$(basename "$archive" .tar.gz)
            log_info "Restoring $dirname directory..."
            mkdir -p "$HOME"
            tar -xzf "$archive" -C "$HOME"
            log_success "$dirname directory restored"
        fi
    done
}

# Restore configurations
restore_configs() {
    local backup_path="$1"
    local configs_dir="$backup_path/configs"

    if [[ ! -d "$configs_dir" ]]; then
        log_warning "No configurations to restore"
        return
    fi

    log_info "Restoring configuration files..."

    # Ask for confirmation before overwriting configs
    if [[ "$FORCE_RESTORE" != "true" ]]; then
        read -p "This will overwrite existing configuration files. Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Configuration restore skipped"
            return
        fi
    fi

    # Restore shell configurations
    local shell_files=(".bashrc" ".zshrc" ".bash_profile" ".zsh_profile")
    for file in "${shell_files[@]}"; do
        if [[ -f "$configs_dir/$file" ]]; then
            cp "$configs_dir/$file" "$HOME/"
            log_success "$file restored"
        fi
    done

    # Restore Git configuration
    if [[ -f "$configs_dir/.gitconfig" ]]; then
        cp "$configs_dir/.gitconfig" "$HOME/"
        log_success ".gitconfig restored"
    fi

    # Restore SSH keys (public keys only)
    if [[ -d "$configs_dir/ssh" ]]; then
        mkdir -p "$HOME/.ssh"
        cp "$configs_dir/ssh"/*.pub "$HOME/.ssh/" 2>/dev/null || true
        cp "$configs_dir/ssh"/config "$HOME/.ssh/" 2>/dev/null || true
        chmod 600 "$HOME/.ssh"/*
        log_success "SSH keys restored"
    fi

    # Restore VS Code settings
    if [[ -d "$configs_dir/.vscode" ]]; then
        cp -r "$configs_dir/.vscode" "$HOME/"
        log_success "VS Code settings restored"
    fi

    # Restore IntelliJ IDEA settings
    if [[ -d "$configs_dir/.IntelliJIdea"* ]]; then
        cp -r "$configs_dir/.IntelliJIdea"* "$HOME/" 2>/dev/null || true
        log_success "IntelliJ IDEA settings restored"
    fi

    # Restore development tool configurations
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
        if [[ -f "$configs_dir/$file" ]]; then
            local dirname=$(dirname "$file")
            mkdir -p "$HOME/$dirname"
            cp "$configs_dir/$file" "$HOME/$file"
            log_success "$file restored"
        fi
    done
}

# Restore packages
restore_packages() {
    local backup_path="$1"
    local packages_dir="$backup_path/packages"

    if [[ ! -d "$packages_dir" ]]; then
        log_warning "No package lists to restore"
        return
    fi

    log_info "Restoring packages..."

    # Ask for confirmation
    if [[ "$FORCE_RESTORE" != "true" ]]; then
        read -p "This will install packages listed in the backup. Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Package restore skipped"
            return
        fi
    fi

    case $PLATFORM in
        macos)
            # Restore Homebrew packages
            if [[ -f "$packages_dir/brew_packages.txt" ]]; then
                log_info "Installing Homebrew packages..."
                xargs brew install < "$packages_dir/brew_packages.txt"
                log_success "Homebrew packages installed"
            fi

            if [[ -f "$packages_dir/brew_casks.txt" ]]; then
                log_info "Installing Homebrew casks..."
                xargs brew install --cask < "$packages_dir/brew_casks.txt"
                log_success "Homebrew casks installed"
            fi
            ;;
        ubuntu)
            # Restore apt packages
            if [[ -f "$packages_dir/apt_packages.txt" ]]; then
                log_info "Installing apt packages..."
                sudo dpkg --set-selections < "$packages_dir/apt_packages.txt"
                sudo apt-get dselect-upgrade -y
                log_success "apt packages installed"
            fi

            # Restore snap packages
            if [[ -f "$packages_dir/snap_packages.txt" ]]; then
                log_info "Installing snap packages..."
                tail -n +2 "$packages_dir/snap_packages.txt" | while read -r line; do
                    package=$(echo "$line" | awk '{print $1}')
                    snap install "$package" 2>/dev/null || true
                done
                log_success "snap packages installed"
            fi
            ;;
        redhat)
            # Restore RPM packages
            if [[ -f "$packages_dir/rpm_packages.txt" ]]; then
                log_info "Installing RPM packages..."
                xargs sudo yum install -y < "$packages_dir/rpm_packages.txt"
                log_success "RPM packages installed"
            fi
            ;;
        arch)
            # Restore pacman packages
            if [[ -f "$packages_dir/pacman_packages.txt" ]]; then
                log_info "Installing pacman packages..."
                awk '{print $1}' "$packages_dir/pacman_packages.txt" | xargs sudo pacman -S --noconfirm
                log_success "pacman packages installed"
            fi
            ;;
    esac

    # Restore Python packages
    if [[ -f "$packages_dir/pip_packages.txt" ]]; then
        log_info "Installing Python packages..."
        pip install -r "$packages_dir/pip_packages.txt"
        log_success "Python packages installed"
    fi

    # Restore Node.js packages
    if [[ -f "$packages_dir/npm_packages.txt" ]] && command -v npm &>/dev/null; then
        log_info "Installing npm packages..."
        # This is tricky as we need to parse the global packages
        grep -E "^├── |└── " "$packages_dir/npm_packages.txt" | sed 's/├── //' | sed 's/└── //' | xargs npm install -g
        log_success "npm packages installed"
    fi

    # Restore Ruby gems
    if [[ -f "$packages_dir/gem_packages.txt" ]] && command -v gem &>/dev/null; then
        log_info "Installing Ruby gems..."
        awk '{print $1}' "$packages_dir/gem_packages.txt" | xargs gem install
        log_success "Ruby gems installed"
    fi
}

# Restore databases
restore_databases() {
    local backup_path="$1"
    local databases_dir="$backup_path/databases"

    if [[ ! -d "$databases_dir" ]]; then
        log_warning "No databases to restore"
        return
    fi

    log_info "Restoring databases..."

    # Ask for confirmation
    if [[ "$FORCE_RESTORE" != "true" ]]; then
        read -p "This will overwrite existing databases. Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Database restore skipped"
            return
        fi
    fi

    # PostgreSQL
    if [[ -d "$databases_dir/postgresql" ]]; then
        log_info "Restoring PostgreSQL databases..."
        for sql_file in "$databases_dir/postgresql"/*.sql; do
            if [[ -f "$sql_file" ]]; then
                db_name=$(basename "$sql_file" .sql)
                # Create database if it doesn't exist
                createdb "$db_name" 2>/dev/null || true
                psql "$db_name" < "$sql_file"
                log_success "PostgreSQL database '$db_name' restored"
            fi
        done
    fi

    # MySQL/MariaDB
    if [[ -d "$databases_dir/mysql" ]]; then
        log_info "Restoring MySQL databases..."
        for sql_file in "$databases_dir/mysql"/*.sql; do
            if [[ -f "$sql_file" ]]; then
                db_name=$(basename "$sql_file" .sql)
                # Create database if it doesn't exist
                mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
                mysql "$db_name" < "$sql_file"
                log_success "MySQL database '$db_name' restored"
            fi
        done
    fi

    # MongoDB
    if [[ -d "$databases_dir/mongodb" ]]; then
        log_info "Restoring MongoDB databases..."
        mongorestore "$databases_dir/mongodb/" 2>/dev/null || true
        log_success "MongoDB databases restored"
    fi

    # Redis
    if [[ -f "$databases_dir/redis/dump.rdb" ]]; then
        log_info "Restoring Redis database..."
        sudo cp "$databases_dir/redis/dump.rdb" /var/lib/redis/dump.rdb
        sudo systemctl restart redis 2>/dev/null || true
        log_success "Redis database restored"
    fi
}

# List available backups
list_backups() {
    local backup_dir="${BACKUP_DIR:-$HOME/dev-backups}"

    echo -e "${BLUE}📋 Available Backups:${NC}"
    echo "==================="

    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory not found: $backup_dir"
        return
    fi

    local count=0
    while IFS= read -r -d '' backup; do
        if [[ -f "$backup/backup_manifest.txt" ]]; then
            echo "$((++count)). $(basename "$backup")"
            echo "   Location: $backup"
            echo "   Created: $(stat -c %y "$backup/backup_manifest.txt" 2>/dev/null | cut -d'.' -f1 || stat -f %Sm -t %Y-%m-%d\ %H:%M:%S "$backup/backup_manifest.txt")"
            echo "   Size: $(du -sh "$backup" 2>/dev/null | cut -f1)"
            echo ""
        fi
    done < <(find "$backup_dir" -name "dev_backup_*" -type d -print0 | sort -rz)

    if [[ $count -eq 0 ]]; then
        log_warning "No valid backups found"
    fi
}

# Main function
main() {
    # Parse command line arguments
    local backup_path=""
    FORCE_RESTORE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --backup=*)
                backup_path="${1#*=}"
                shift
                ;;
            --force)
                FORCE_RESTORE=true
                shift
                ;;
            --list)
                list_backups
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --backup=PATH    Path to backup directory to restore"
                echo "  --force          Force restore without confirmation"
                echo "  --list           List available backups"
                echo "  --help           Show this help"
                echo ""
                echo "If no backup is specified, the most recent backup will be used."
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    detect_platform

    echo -e "${BLUE}🔄 Restoring Development Environment${NC}"
    echo -e "${BLUE}=====================================${NC}"

    backup_path=$(find_backup "$backup_path")
    log_success "Using backup: $backup_path"

    # Show backup contents
    echo ""
    echo -e "${YELLOW}Backup Contents:${NC}"
    echo "Projects: $(ls "$backup_path/projects/" 2>/dev/null | wc -l) items"
    echo "Configs: $(ls "$backup_path/configs/" 2>/dev/null | wc -l) items"
    echo "Packages: $(ls "$backup_path/packages/" 2>/dev/null | wc -l) items"
    echo "Databases: $(find "$backup_path/databases/" -type f 2>/dev/null | wc -l) items"
    echo ""

    # Ask for final confirmation
    if [[ "$FORCE_RESTORE" != "true" ]]; then
        read -p "Start restore process? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Restore cancelled"
            exit 0
        fi
    fi

    # Perform restore
    restore_projects "$backup_path"
    restore_configs "$backup_path"
    restore_packages "$backup_path"
    restore_databases "$backup_path"

    echo ""
    echo -e "${GREEN}🎉 Restore completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your shell to apply configuration changes"
    echo "2. Restart your IDE to apply settings"
    echo "3. Verify that your applications work correctly"
}

# Run main function
main "$@"
