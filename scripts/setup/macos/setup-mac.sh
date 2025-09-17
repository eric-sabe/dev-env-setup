#!/usr/bin/env bash
# macOS Development Environment Setup Script
# Comprehensive setup for CS students - macOS 12+ (Monterey or later)

set -Eeuo pipefail

# Source shared utilities (logging, platform detection, safety helpers)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
UTILS_DIR="${SCRIPT_DIR%/setup/macos}/utils"
if [[ -f "$UTILS_DIR/cross-platform.sh" ]]; then
    # shellcheck source=../../utils/cross-platform.sh
    source "$UTILS_DIR/cross-platform.sh"
else
    echo "[WARN] cross-platform utilities not found; proceeding with minimal safety" >&2
fi

# Backwards-compatible aliases for prior log_* names used in docs
log_warning() { log_warn "$@"; }

trap 'log_error "macOS setup aborted at line $LINENO"' ERR

# Check if running on macOS
check_macos() {
    if [[ "${PLATFORM:-}" != "macos" ]]; then
        log_error "This script is designed for macOS only (detected: ${PLATFORM:-unknown})."
        exit 1
    fi
    local macos_version
    macos_version=$(sw_vers -productVersion | cut -d. -f1 || echo 0)
    if (( macos_version < 12 )); then
        log_error "macOS 12 (Monterey) or later is required. Current major version: $macos_version"
        exit 1
    fi
    log_success "macOS $macos_version detected"
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    start_timer "Xcode Command Line Tools installation"

    if ! xcode-select -p &>/dev/null; then
        log_timed_info "Installing Xcode Command Line Tools..."
        xcode-select --install

        # Wait for installation to complete
        log_info "Please complete the Xcode Command Line Tools installation, then press Enter to continue..."
        read -r
        stop_timer "Xcode Command Line Tools installation"
    else
        log_timed_success "Xcode Command Line Tools already installed"
        stop_timer "Xcode Command Line Tools installation"
    fi
}

# Install Homebrew
install_homebrew() {
    start_timer "Homebrew installation and setup"

    if ! command -v brew &>/dev/null; then
        log_timed_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_timed_success "Homebrew already installed"
    fi

    # Update Homebrew
    log_timed_info "Updating Homebrew..."
    brew update
    
    stop_timer "Homebrew installation and setup"
}

# Install development tools
install_dev_tools() {
    start_timer "Development tools installation"

    # Core development tools
    brew install git cmake wget curl htop tree jq

    # Build tools
    brew install make automake autoconf libtool

    # Version control and productivity
    brew install gh  # GitHub CLI

    stop_timer "Development tools installation"
}

# Install Python and pyenv
install_python() {
    start_timer "Python environment setup"

    # Install pyenv
    if ! command -v pyenv &>/dev/null; then
        brew install pyenv
        log_success "pyenv installed"
    else
        log_success "pyenv already installed"
    fi

    # Install latest Python versions
    log_info "Installing Python versions..."
    pyenv install 3.11.7 || log_warning "Python 3.11.7 already installed or failed to install"
    pyenv install 3.12.1 || log_warning "Python 3.12.1 already installed or failed to install"
    pyenv global 3.11.7

    # Install pip and virtualenv
    brew install pipx
    pipx install virtualenv
    pipx install pipenv

    stop_timer "Python environment setup"
}

# Install Node.js and nvm
install_nodejs() {
    start_timer
    log_timed_info "Setting up Node.js environment..."

    # Install nvm
    if [[ ! -d "$HOME/.nvm" ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        log_success "nvm installed"
    else
        log_success "nvm already installed"
    fi

    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install Node.js versions
    log_info "Installing Node.js versions..."
    nvm install 18 || log_warning "Node.js 18 already installed or failed to install"
    nvm install 20 || log_warning "Node.js 20 already installed or failed to install"
    nvm alias default 20

    # Install global npm packages
    npm install -g npm@latest
    npm install -g yarn pnpm typescript @types/node

    stop_timer
    log_timed_success "Node.js environment configured"
}

# Install Java and SDKMAN
install_java() {
    start_timer
    log_timed_info "Setting up Java environment..."

    # Install SDKMAN
    if [[ ! -d "$HOME/.sdkman" ]]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        log_success "SDKMAN installed"
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        log_success "SDKMAN already installed"
    fi

    # Install Java versions
    log_info "Installing Java versions..."
    sdk install java 17.0.9-zulu || log_warning "Java 17 already installed or failed to install"
    sdk install java 21.0.1-zulu || log_warning "Java 21 already installed or failed to install"
    sdk default java 17.0.9-zulu

    # Install Maven and Gradle
    sdk install maven || log_warning "Maven already installed or failed to install"
    sdk install gradle || log_warning "Gradle already installed or failed to install"

    stop_timer
    log_timed_success "Java environment configured"
}

# Install C++ tools
install_cpp() {
    start_timer
    log_timed_info "Setting up C++ development environment..."

    # Install LLVM/Clang
    brew install llvm
    brew install gcc

    # Install additional C++ tools
    brew install boost eigen opencv

    stop_timer
    log_timed_success "C++ environment configured"
}

# Install databases
install_databases() {
    start_timer
    log_timed_info "Installing database tools..."

    # Install PostgreSQL
    brew install postgresql
    brew services start postgresql

    # Install MySQL
    brew install mysql
    brew services start mysql

    # Install MongoDB
    brew tap mongodb/brew
    brew install mongodb-community
    brew services start mongodb-community

    # Install Redis
    brew install redis
    brew services start redis

    # Install database clients and tools
    brew install pgcli mycli

    stop_timer
    log_timed_success "Database tools installed"
}

# Install Docker
install_docker() {
    start_timer
    log_timed_info "Installing Docker..."

    if ! command -v docker &>/dev/null; then
        brew install --cask docker
        log_success "Docker installed"
    else
        log_success "Docker already installed"
    fi
    
    stop_timer
    log_timed_success "Docker setup completed"
}

# Install IDEs
install_ides() {
    start_timer
    log_timed_info "Installing IDEs..."

    # Install VS Code
    if ! command -v code &>/dev/null; then
        brew install --cask visual-studio-code
        log_success "VS Code installed"
    else
        log_success "VS Code already installed"
    fi

    # Install Eclipse
    brew install --cask eclipse-java

    stop_timer
    log_timed_success "IDEs installed"
}

# Configure shell environment
configure_shell() {
    start_timer
    log_timed_info "Configuring shell environment..."

    local shell_rc="$HOME/.zshrc"

    # Add pyenv to shell
    if ! grep -q 'pyenv init' "$shell_rc"; then
        echo '' >> "$shell_rc"
        echo '# pyenv configuration' >> "$shell_rc"
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$shell_rc"
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$shell_rc"
        echo 'eval "$(pyenv init -)"' >> "$shell_rc"
    fi

    # Add nvm to shell
    if ! grep -q 'NVM_DIR' "$shell_rc"; then
        echo '' >> "$shell_rc"
        echo '# nvm configuration' >> "$shell_rc"
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$shell_rc"
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$shell_rc"
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$shell_rc"
    fi

    # Add SDKMAN to shell
    if ! grep -q 'SDKMAN' "$shell_rc"; then
        echo '' >> "$shell_rc"
        echo '# SDKMAN configuration' >> "$shell_rc"
        echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> "$shell_rc"
        echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> "$shell_rc"
    fi

    # Add useful aliases and functions
    if ! grep -q 'Development aliases' "$shell_rc"; then
        echo '' >> "$shell_rc"
        echo '# Development aliases' >> "$shell_rc"
        echo 'alias python=python3' >> "$shell_rc"
        echo 'alias pip=pip3' >> "$shell_rc"
        echo 'alias activate="source venv/bin/activate"' >> "$shell_rc"
        echo 'alias mkvenv="python -m venv venv && activate"' >> "$shell_rc"
    fi

    stop_timer
    log_timed_success "Shell environment configured"
}

# Create development directory structure
create_dev_structure() {
    start_timer
    log_timed_info "Creating development directory structure..."

    mkdir -p ~/dev/{current,archive,tools,backups}
    mkdir -p ~/dev/current/{python,nodejs,java,cpp,web,mobile}

    stop_timer
    log_timed_success "Development directories created"
}

# Verify installation
verify_installation() {
    start_timer
    log_timed_info "Verifying installation..."

    local errors=0

    # Check core tools
    for tool in git python3 node java mvn gradle gcc docker code; do
        if command -v $tool &>/dev/null; then
            log_success "$tool: $(which $tool)"
        else
            log_error "$tool: NOT FOUND"
            ((errors++))
        fi
    done

    # Check version managers
    if command -v pyenv &>/dev/null; then
        log_success "pyenv: $(pyenv --version)"
    else
        log_error "pyenv: NOT FOUND"
        ((errors++))
    fi

    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        log_success "nvm: installed"
    else
        log_error "nvm: NOT FOUND"
        ((errors++))
    fi

    if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        log_success "SDKMAN: installed"
    else
        log_error "SDKMAN: NOT FOUND"
        ((errors++))
    fi

    stop_timer
    if [[ $errors -eq 0 ]]; then
        log_timed_success "All tools verified successfully!"
    else
        log_warning "$errors tools failed verification. You may need to restart your terminal or check the installation logs."
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}🚀 Setting up macOS Development Environment${NC}"
    echo -e "${BLUE}===============================================${NC}"

    check_macos
    install_xcode_tools
    install_homebrew
    install_dev_tools
    install_python
    install_nodejs
    install_java
    install_cpp
    install_databases
    install_docker
    install_ides
    configure_shell
    create_dev_structure
    verify_installation

    echo ""
    echo -e "${GREEN}🎉 macOS development environment setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal to load the new shell configuration"
    echo "2. Run 'pyenv versions' to see available Python versions"
    echo "3. Run 'nvm list' to see available Node.js versions"
    echo "4. Run 'sdk list java' to see available Java versions"
    echo "5. Use the quickstart scripts to create new projects"
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Run main function
main "$@"
