#!/usr/bin/env bash
# Eclipse Setup Script (refactored for consistency & safety)
# Installs and configures Eclipse IDE for Java and C++ development using shared utils.

set -Eeuo pipefail
trap 'echo "[ERROR] eclipse setup failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_DIR="${SCRIPT_DIR%/scripts/setup*}/scripts/utils"
if [[ -f "$UTIL_DIR/cross-platform.sh" ]]; then
    # shellcheck source=../utils/cross-platform.sh
    source "$UTIL_DIR/cross-platform.sh"
fi
if [[ -f "$UTIL_DIR/version-resolver.sh" ]]; then
    # shellcheck source=../utils/version-resolver.sh
    source "$UTIL_DIR/version-resolver.sh"
fi
if [[ -f "$UTIL_DIR/idempotency.sh" ]]; then
    # shellcheck source=../utils/idempotency.sh
    source "$UTIL_DIR/idempotency.sh"
fi

ECLIPSE_VERSION_Y="2023-12" # TODO: move to manifest sources block in Phase 3
ECLIPSE_RELEASE="R"         # channel release marker

# Use shared logging if available; otherwise define minimal fallbacks
if ! command -v log_info >/dev/null 2>&1; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
    log_info(){ echo -e "${BLUE}ℹ️  $1${NC}"; }
    log_success(){ echo -e "${GREEN}✅ $1${NC}"; }
    log_warning(){ echo -e "${YELLOW}⚠️  $1${NC}"; }
    log_error(){ echo -e "${RED}❌ $1${NC}"; }
fi

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

# Check prerequisites
check_prerequisites() {
    local eclipse_type=$1

    case $eclipse_type in
        java)
            # Check Java
            if ! command -v java &>/dev/null; then
                log_error "Java is required for Eclipse Java. Please run the platform setup script first."
                exit 1
            fi
            ;;
        cpp)
            # Check C++ compiler
            local compiler_found=false
            for compiler in g++ clang++; do
                if command -v $compiler &>/dev/null; then
                    compiler_found=true
                    break
                fi
            done
            if [[ "$compiler_found" != true ]]; then
                log_error "C++ compiler is required for Eclipse C++. Please run the platform setup script first."
                exit 1
            fi
            ;;
        *)
            log_error "Invalid Eclipse type: $eclipse_type. Use 'java' or 'cpp'"
            exit 1
            ;;
    esac

    log_success "Prerequisites check passed"
}

# Download and install Eclipse
install_eclipse() {
    local eclipse_type=$1
    local install_dir="$HOME/dev/tools/eclipse"

    start_timer
    log_timed_info "Installing Eclipse $eclipse_type (version $ECLIPSE_VERSION_Y) ..."

    # Create installation directory
    mkdir -p "$install_dir"

    # Determine download URL based on type and platform
    local download_url
    case $PLATFORM in
        macos)
            case $eclipse_type in
                java)
                    download_url="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2023-12/R/eclipse-java-2023-12-R-macosx-cocoa-x86_64.dmg&r=1"
                    ;;
                cpp)
                    download_url="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2023-12/R/eclipse-cpp-2023-12-R-macosx-cocoa-x86_64.dmg&r=1"
                    ;;
            esac
            ;;
        linux|ubuntu|redhat|arch)
            case $eclipse_type in
                java)
                    download_url="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2023-12/R/eclipse-java-2023-12-R-linux-gtk-x86_64.tar.gz&r=1"
                    ;;
                cpp)
                    download_url="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2023-12/R/eclipse-cpp-2023-12-R-linux-gtk-x86_64.tar.gz&r=1"
                    ;;
            esac
            ;;
        windows)
            case $eclipse_type in
                java)
                    download_url="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2023-12/R/eclipse-java-2023-12-R-win32-x86_64.zip&r=1"
                    ;;
                cpp)
                    download_url="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2023-12/R/eclipse-cpp-2023-12-R-win32-x86_64.zip&r=1"
                    ;;
            esac
            ;;
    esac

    # Download Eclipse
    local archive_name
    if [[ "$PLATFORM" == "macos" ]]; then
        archive_name="eclipse-${eclipse_type}.dmg"
    elif [[ "$PLATFORM" == "windows" ]]; then
        archive_name="eclipse-${eclipse_type}.zip"
    else
        archive_name="eclipse-${eclipse_type}.tar.gz"
    fi

    if [[ -d "$install_dir/eclipse" ]]; then
        log_warning "Existing eclipse directory found – skipping re-download"
        create_shortcut "$install_dir" "$eclipse_type"
        return 0
    fi

    log_info "Downloading Eclipse from $download_url"
    if ! curl -fsSL -o "$install_dir/$archive_name" "$download_url"; then
        log_error "Failed to download Eclipse"
        exit 1
    fi
    # Phase 3: attempt checksum verification if manifest hash present (placeholder)
    if command -v bash >/dev/null 2>&1 && [[ -f "${SCRIPT_DIR%/scripts/setup*}/scripts/security/checksums.sh" ]]; then
        # shellcheck source=../security/checksums.sh
        source "${SCRIPT_DIR%/scripts/setup*}/scripts/security/checksums.sh" || true
        # Lookup would parse versions.yaml sources (future enhancement)
        EXPECTED_SHA="TBD" # placeholder until populated
        if [[ "$EXPECTED_SHA" != "TBD" ]]; then
            verify_file "$install_dir/$archive_name" "$EXPECTED_SHA" || log_warning "Checksum mismatch (non-fatal yet)"
        else
            log_info "Checksum deferred (TBD entry)"
        fi
    fi

    # Extract/install Eclipse
    cd "$install_dir"
    case $PLATFORM in
        macos)
            # Mount DMG and copy contents
            local mount_point="/Volumes/Eclipse"
            hdiutil attach "$archive_name" -mountpoint "$mount_point" -nobrowse
            cp -R "$mount_point/Eclipse.app" .
            hdiutil detach "$mount_point"
            ;;
        windows)
            # For Windows, we'll extract to a directory
            if command -v unzip &>/dev/null; then
                unzip "$archive_name"
            else
                log_error "unzip command not found. Please extract $archive_name manually"
                exit 1
            fi
            ;;
        *)
            # Linux
            tar -xzf "$archive_name"
            ;;
    esac

    # Clean up archive
    rm -f "$archive_name"

    # Create desktop shortcut/symlink
    create_shortcut "$install_dir" "$eclipse_type"

    stop_timer
    log_timed_success "Eclipse $eclipse_type installed to $install_dir"
}

# Create desktop shortcut or symlink
create_shortcut() {
    local install_dir=$1
    local eclipse_type=$2

    case $PLATFORM in
        macos)
            # macOS applications are already properly installed
            log_info "Eclipse is available in Applications"
            ;;
        linux|ubuntu|redhat|arch)
            # Create desktop entry
            local desktop_file="$HOME/.local/share/applications/eclipse-${eclipse_type}.desktop"
            mkdir -p "$(dirname "$desktop_file")"

            cat << EOF > "$desktop_file"
[Desktop Entry]
Version=1.0
Type=Application
Name=Eclipse ${eclipse_type^^}
Comment=Eclipse IDE for ${eclipse_type^^} Development
Exec=$install_dir/eclipse/eclipse
Icon=$install_dir/eclipse/icon.xpm
Terminal=false
Categories=Development;IDE;
EOF

            chmod +x "$desktop_file"
            log_success "Desktop shortcut created"
            ;;
        windows)
            # Create Windows shortcut (PowerShell)
            local eclipse_exe="$install_dir/eclipse/eclipse.exe"
            if [[ -f "$eclipse_exe" ]]; then
                log_info "Eclipse executable: $eclipse_exe"
                log_info "You can create a desktop shortcut manually or pin to taskbar"
            fi
            ;;
    esac
}

# Configure Eclipse workspace
configure_workspace() {
    local eclipse_type=$1
    local workspace_dir="$HOME/dev/current/${eclipse_type}"

    log_info "Configuring Eclipse workspace..."

    mkdir -p "$workspace_dir"

    # Create workspace configuration files
    case $eclipse_type in
        java)
            # Java-specific configuration will be done when Eclipse first runs
            log_info "Java workspace will be configured when Eclipse starts"
            ;;
        cpp)
            # C++-specific configuration
            log_info "C++ workspace configured at $workspace_dir"
            ;;
    esac

    log_success "Workspace configured at $workspace_dir"
}

# Install Eclipse plugins
install_plugins() {
    local eclipse_type=$1
    local install_dir="$HOME/dev/tools/eclipse"

    start_timer
    log_timed_info "Installing Eclipse plugins..."

    # Create plugin installation script
    local plugin_script="$install_dir/install-plugins.sh"

    cat << 'EOF' > "$plugin_script"
#!/bin/bash
# Eclipse plugin installation script

# Wait for Eclipse to start (if running)
sleep 5

# Install plugins based on type
case "$1" in
    java)
        # Java plugins are usually included in Eclipse Java
        echo "Java plugins should be included in Eclipse Java distribution"
        ;;
    cpp)
        # C++ plugins are usually included in Eclipse C++
        echo "C++ plugins should be included in Eclipse C++ distribution"
        ;;
esac
EOF

    chmod +x "$plugin_script"

    stop_timer
    log_timed_info "Plugin installation script created: $plugin_script"
    log_info "Run this script after starting Eclipse for the first time"
}

# Create run script
create_run_script() {
    local eclipse_type=$1
    local install_dir="$HOME/dev/tools/eclipse"
    local run_script="$HOME/bin/eclipse-${eclipse_type}"

    mkdir -p "$(dirname "$run_script")"

    case $PLATFORM in
        macos)
            cat << EOF > "$run_script"
#!/bin/bash
# Run Eclipse $eclipse_type on macOS
open "$install_dir/Eclipse.app" --args -data "$HOME/dev/current/$eclipse_type"
EOF
            ;;
        windows)
            cat << EOF > "$run_script.bat"
@echo off
REM Run Eclipse $eclipse_type on Windows
"$install_dir\eclipse\eclipse.exe" -data "%USERPROFILE%\dev\current\$eclipse_type"
EOF
            ;;
        *)
            cat << EOF > "$run_script"
#!/bin/bash
# Run Eclipse $eclipse_type on Linux
"$install_dir/eclipse/eclipse" -data "$HOME/dev/current/$eclipse_type"
EOF
            ;;
    esac

    chmod +x "$run_script"

    log_success "Run script created: $run_script"
}

# Create documentation
create_documentation() {
    local eclipse_type=$1
    local docs_dir="$HOME/dev/tools/eclipse"

    log_info "Creating documentation..."

    cat << EOF > "$docs_dir/README-Eclipse-${eclipse_type}.md"
# Eclipse ${eclipse_type^^} Setup

## Installation Location
Eclipse is installed in: $docs_dir

## Workspace Location
Default workspace: ~/dev/current/$eclipse_type

## Running Eclipse
- Use the desktop shortcut (Linux/macOS)
- Run: eclipse-$eclipse_type (from anywhere)
- Or run directly: $docs_dir/eclipse/eclipse

## First Time Setup
1. Start Eclipse
2. Select workspace: ~/dev/current/$eclipse_type
3. Complete the welcome wizard
4. Install any additional plugins as needed

## Recommended Plugins
EOF

    case $eclipse_type in
        java)
            cat << EOF >> "$docs_dir/README-Eclipse-${eclipse_type}.md"
- m2e (Maven integration) - usually included
- Buildship (Gradle integration) - usually included
- Spring Tools Suite (for Spring development)
- TestNG (alternative to JUnit)
EOF
            ;;
        cpp)
            cat << EOF >> "$docs_dir/README-Eclipse-${eclipse_type}.md"
- CDT (C/C++ Development Tools) - usually included
- CMake Support
- Google Test Support
EOF
            ;;
    esac

    cat << EOF >> "$docs_dir/README-Eclipse-${eclipse_type}.md"

## Troubleshooting

### Eclipse won't start
- Check Java version: java -version
- Try running from command line with more memory: eclipse -vmargs -Xmx1g

### Workspace issues
- Delete workspace/.metadata/.plugins/org.eclipse.e4.workbench
- Start Eclipse with -clean option

### Performance issues
- Increase heap size in eclipse.ini
- Disable unused plugins
- Use latest Eclipse version

## Keyboard Shortcuts
- Ctrl+Shift+R: Open Resource
- Ctrl+Shift+T: Open Type
- F11: Debug
- Ctrl+F11: Run
- Ctrl+/: Toggle comment

## Useful Preferences
- General > Editors > Text Editors: Show line numbers
- Java > Code Style > Formatter: Configure code formatting
- C++ > Code Style > Formatter: Configure code formatting
EOF

    log_success "Documentation created: $docs_dir/README-Eclipse-${eclipse_type}.md"
}

# Main function
main() {
    local eclipse_type=${1:-java}

    log_info "🚀 Setting up Eclipse ${eclipse_type^^}"

    detect_platform
    check_prerequisites "$eclipse_type"
    install_eclipse "$eclipse_type"
    configure_workspace "$eclipse_type"
    install_plugins "$eclipse_type"
    create_run_script "$eclipse_type"
    create_documentation "$eclipse_type"

    echo ""
    log_success "Eclipse ${eclipse_type^^} setup complete!"
    echo ""
    log_info "Next steps:"
    echo "1. Start Eclipse using the desktop shortcut or run script"
    echo "2. Select workspace: ~/dev/current/$eclipse_type"
    echo "3. Complete the welcome wizard"
    echo "4. Install additional plugins if needed"
    echo "5. Import or create your first project"
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Show usage if no arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <java|cpp>" >&2
    exit 64
fi

main "$@"
