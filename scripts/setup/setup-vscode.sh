#!/usr/bin/env bash
# VS Code Setup Script (refactored)
# Installs and configures VS Code with development extensions using shared utils.

set -Eeuo pipefail
trap 'echo "[ERROR] vscode setup failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_DIR="${SCRIPT_DIR%/scripts/setup*}/scripts/utils"
ROOT_DIR="${SCRIPT_DIR%/scripts/setup*}"
if [[ -f "$UTIL_DIR/cross-platform.sh" ]]; then
    # shellcheck source=../utils/cross-platform.sh
    source "$UTIL_DIR/cross-platform.sh"
fi
if [[ -f "$UTIL_DIR/version-resolver.sh" ]]; then
    # shellcheck source=../utils/version-resolver.sh
    source "$UTIL_DIR/version-resolver.sh"
fi

VSCODE_CHANNEL="stable" # placeholder; future manifest integration

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

# Check if VS Code is installed
check_vscode() {
    if command -v code &>/dev/null; then
        log_success "VS Code is already installed"
        return 0
    else
        return 1
    fi
}

# Install VS Code
install_vscode() {
    log_info "Installing VS Code (channel: $VSCODE_CHANNEL)..."

    case $PLATFORM in
        macos)
            if ! command -v brew &>/dev/null; then
                log_error "Homebrew is required for macOS installation"
                exit 1
            fi
            brew install --cask visual-studio-code
            ;;
        ubuntu)
            # Verify Microsoft VS Code repo key fingerprint before trusting repository
            if ! "$ROOT_DIR/scripts/security/verify-gpg-key.sh" --name microsoft-vscode; then
                log_error "GPG key verification failed for microsoft-vscode"
                exit 1
            fi
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
            sudo apt update
            sudo apt install -y code
            ;;
        redhat)
            if ! "$ROOT_DIR/scripts/security/verify-gpg-key.sh" --name microsoft-vscode; then
                log_error "GPG key verification failed for microsoft-vscode"
                exit 1
            fi
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
            sudo yum install -y code
            ;;
        arch)
            sudo pacman -S --noconfirm code
            ;;
        windows)
            log_info "Please download and install VS Code manually from https://code.visualstudio.com/"
            log_info "After installation, re-run this script to configure extensions"
            exit 0
            ;;
        *)
            log_error "Unsupported platform for VS Code installation"
            exit 1
            ;;
    esac

    # Verify installation
    if command -v code &>/dev/null; then
        log_success "VS Code installed successfully"
    else
        log_error "VS Code installation failed"
        exit 1
    fi
}

# Install VS Code extensions
install_extensions() {
    log_info "Installing VS Code extensions (idempotent)..."

    # Core extensions
    local extensions=(
        # Version control
        "ms-vscode.vscode-json"
        "ms-vscode.vscode-typescript-next"
        "redhat.vscode-yaml"
        "ms-vscode.powershell"

        # Themes
        "ms-vscode.vscode-theme-seti"
        "ms-vscode.vscode-icons"

        # Productivity
        "ms-vscode.vscode-eslint"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-git-graph"
        "gruntfuggly.todo-tree"
        "ms-vscode.vscode-live-server"

        # Python
        "ms-python.python"
        "ms-python.pylint"
        "ms-python.black-formatter"
        "ms-python.isort"

        # JavaScript/Node.js
        "ms-vscode.vscode-typescript"
        "bradlc.vscode-tailwindcss"
        "formulahendry.auto-rename-tag"
        "christian-kohler.path-intellisense"

        # Java
        "redhat.java"
        "vscjava.vscode-java-debug"
        "vscjava.vscode-java-test"
        "vscjava.vscode-maven"
        "vscjava.vscode-gradle"

        # C++
        "ms-vscode.cpptools"
        "ms-vscode.cmake-tools"
        "twxs.cmake"
        "ms-vscode.vscode-clangd"

        # Database
        "ms-mssql.mssql"
        "mongodb.mongodb-vscode"

        # Docker
        "ms-azuretools.vscode-docker"

        # Git
        "donjayamanne.githistory"
        "mhutchie.git-graph"

        # Remote development
        "ms-vscode-remote.remote-wsl"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.remote-containers"
    )

    local failed_extensions=()

    for extension in "${extensions[@]}"; do
        if code --list-extensions | grep -iq "^${extension}$"; then
            log_info "Already present: $extension"
            continue
        fi
        log_info "Installing extension: $extension"
        if code --install-extension "$extension" --force >/dev/null 2>&1; then
            log_success "Installed: $extension"
        else
            log_warning "Failed to install: $extension"
            failed_extensions+=("$extension")
        fi
    done

    if [[ ${#failed_extensions[@]} -gt 0 ]]; then
        log_warning "Some extensions failed to install: ${failed_extensions[*]}"
        log_info "You can try installing them manually from the VS Code marketplace"
    else
        log_success "All extensions installed successfully"
    fi
}

# Configure VS Code settings
configure_settings() {
    log_info "Configuring VS Code settings..."

    # Determine settings location
    local settings_dir
    case $PLATFORM in
        macos)
            settings_dir="$HOME/Library/Application Support/Code/User"
            ;;
        linux|ubuntu|redhat|arch)
            settings_dir="$HOME/.config/Code/User"
            ;;
        windows)
            settings_dir="$APPDATA/Code/User"
            ;;
        *)
            log_warning "Unknown settings location for platform: $PLATFORM"
            return
            ;;
    esac

    # Create settings directory if it doesn't exist
    mkdir -p "$settings_dir"

    # Create settings.json
    cat << EOF > "$settings_dir/settings.json"
{
    // Editor settings
    "editor.fontSize": 14,
    "editor.fontFamily": "Fira Code, Consolas, 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": false,
    "editor.renderWhitespace": "boundary",
    "editor.wordWrap": "on",
    "editor.minimap.enabled": true,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": "explicit",
        "source.organizeImports": "explicit"
    },

    // File associations
    "files.associations": {
        "*.json": "jsonc",
        "Dockerfile*": "dockerfile"
    },

    // Exclude files from search
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/CVS": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/venv": true,
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/target": true,
        "**/build": true,
        "**/.gradle": true,
        "**/.vscode": false
    },

    // Search settings
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/__pycache__": true,
        "**/target": true,
        "**/build": true,
        "**/.gradle": true
    },

    // Python settings
    "python.defaultInterpreterPath": "python3",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "python.sortImports.args": ["--profile", "black"],

    // JavaScript/TypeScript settings
    "typescript.preferences.preferTypeOnlyAutoImports": true,
    "javascript.preferences.preferTypeOnlyAutoImports": true,
    "emmet.includeLanguages": {
        "javascript": "javascriptreact",
        "typescript": "typescriptreact"
    },

    // Java settings
    "java.configuration.checkProjectSettingsExclusions": false,
    "java.server.launchMode": "Standard",

    // C++ settings
    "C_Cpp.default.cppStandard": "c++17",
    "C_Cpp.default.cStandard": "c11",
    "C_Cpp.clang_format_fallbackStyle": "Google",

    // Terminal settings
    "terminal.integrated.shell.linux": "/bin/bash",
    "terminal.integrated.shell.osx": "/bin/zsh",
    "terminal.integrated.shell.windows": "C:\\\\Windows\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe",

    // Git settings
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,

    // Extensions settings
    "extensions.ignoreRecommendations": false,

    // Workbench settings
    "workbench.iconTheme": "vscode-icons",
    "workbench.colorTheme": "Seti",
    "workbench.editor.enablePreview": false,
    "workbench.editor.showTabs": "multiple",

    // Window settings
    "window.zoomLevel": 0,

    // Telemetry (opt-out)
    "telemetry.telemetryLevel": "off",

    // Security
    "security.workspace.trust.enabled": true
}
EOF

    log_success "VS Code settings configured"
}

# Configure keybindings
configure_keybindings() {
    log_info "Configuring VS Code keybindings..."

    local keybindings_dir
    case $PLATFORM in
        macos)
            keybindings_dir="$HOME/Library/Application Support/Code/User"
            ;;
        linux|ubuntu|redhat|arch)
            keybindings_dir="$HOME/.config/Code/User"
            ;;
        windows)
            keybindings_dir="$APPDATA/Code/User"
            ;;
        *)
            log_warning "Unknown keybindings location for platform: $PLATFORM"
            return
            ;;
    esac

    # Create keybindings.json
    cat << EOF > "$keybindings_dir/keybindings.json"
[
    // Custom keybindings for development
    {
        "key": "ctrl+shift+t",
        "command": "workbench.action.terminal.toggleTerminal",
        "when": "terminal.active"
    },
    {
        "key": "ctrl+shift+g",
        "command": "workbench.view.scm"
    },
    {
        "key": "ctrl+shift+d",
        "command": "workbench.view.debug"
    },
    {
        "key": "ctrl+shift+x",
        "command": "workbench.view.extensions"
    },
    {
        "key": "alt+shift+f",
        "command": "editor.action.formatDocument",
        "when": "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly"
    }
]
EOF

    log_success "VS Code keybindings configured"
}

# Create workspace settings template
create_workspace_template() {
    log_info "Creating workspace settings template..."

    local template_dir="$HOME/dev/tools/vscode-templates"
    mkdir -p "$template_dir"

    # Create workspace settings template
    cat << EOF > "$template_dir/workspace-settings-template.json"
{
    // Workspace-specific settings
    "python.pythonPath": "./venv/bin/python",
    "python.linting.pylintArgs": ["--rcfile=.pylintrc"],
    "java.project.sourcePaths": ["src/main/java"],
    "java.project.outputPath": "bin",
    "cmake.buildDirectory": "\${workspaceFolder}/build",
    "C_Cpp.default.includePath": [
        "\${workspaceFolder}/include",
        "\${workspaceFolder}/src"
    ]
}
EOF

    # Create launch.json template for debugging
    cat << EOF > "$template_dir/launch-template.json"
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "\${file}",
            "console": "integratedTerminal",
            "justMyCode": true
        },
        {
            "name": "Java: Launch",
            "type": "java",
            "request": "launch",
            "mainClass": "\${workspaceFolder}/src/main/java/App.java",
            "projectName": "\${workspaceFolderBasename}"
        },
        {
            "name": "C++: Launch",
            "type": "cppdbg",
            "request": "launch",
            "program": "\${workspaceFolder}/build/\${workspaceFolderBasename}",
            "args": [],
            "stopAtEntry": false,
            "cwd": "\${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
EOF

    log_success "VS Code templates created in $template_dir"
}

# Main function
main() {
    log_info "🚀 Setting up VS Code"

    detect_platform

    if ! check_vscode; then
        install_vscode
    fi

    install_extensions
    configure_settings
    configure_keybindings
    create_workspace_template

    echo ""
    log_success "VS Code setup complete!"
    echo ""
    log_info "Next steps:"
    echo "1. Restart VS Code to apply all settings"
    echo "2. Check that all extensions are installed and working"
    echo "3. For new projects, copy settings from ~/dev/tools/vscode-templates/"
    echo "4. Configure your preferred theme and additional extensions"
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Run main function
main "$@"
