#!/bin/bash
# WSL2 Ubuntu Development Environment Setup Script
# Comprehensive setup for CS students - WSL2 Ubuntu 20.04+

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

# Check if running in WSL
check_wsl() {
    if [[ ! -f /proc/version ]] || ! grep -q "Microsoft" /proc/version && ! grep -q "microsoft" /proc/version; then
        log_error "This script is designed for WSL2 Ubuntu. Please run it inside WSL2."
        exit 1
    fi

    log_success "WSL2 environment detected"
}

# Update WSL Ubuntu system
update_system() {
    log_info "Updating WSL Ubuntu system..."

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y software-properties-common apt-transport-https ca-certificates curl wget gnupg lsb-release

    log_success "System updated"
}

# Install development tools
install_dev_tools() {
    log_info "Installing development tools..."

    sudo apt install -y build-essential git cmake htop tree jq unzip zip
    sudo apt install -y linux-tools-generic  # For perf, etc.

    # Install Windows integration tools
    sudo apt install -y wslu  # Windows System for Linux Utilities

    log_success "Development tools installed"
}

# Install Python and pyenv
install_python() {
    log_info "Setting up Python environment..."

    # Install pyenv dependencies
    sudo apt install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    # Install pyenv
    if [[ ! -d "$HOME/.pyenv" ]]; then
        curl https://pyenv.run | bash
        log_success "pyenv installed"
    else
        log_success "pyenv already installed"
    fi

    # Add pyenv to PATH for this session
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"

    # Install Python versions
    log_info "Installing Python versions..."
    pyenv install 3.11.7 || log_warning "Python 3.11.7 already installed or failed to install"
    pyenv install 3.12.1 || log_warning "Python 3.12.1 already installed or failed to install"
    pyenv global 3.11.7

    # Install pip tools
    pip install --user pipx
    pipx install virtualenv
    pipx install pipenv

    log_success "Python environment configured"
}

# Install Node.js and nvm
install_nodejs() {
    log_info "Setting up Node.js environment..."

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

    log_success "Node.js environment configured"
}

# Install Java and SDKMAN
install_java() {
    log_info "Setting up Java environment..."

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

    log_success "Java environment configured"
}

# Install C++ tools
install_cpp() {
    log_info "Setting up C++ development environment..."

    sudo apt install -y clang clang-format clang-tidy gdb valgrind cmake
    sudo apt install -y libboost-all-dev libeigen3-dev

    # Install additional tools for WSL
    sudo apt install -y cppcheck  # Static analysis
    sudo apt install -y doxygen   # Documentation generator

    log_success "C++ environment configured"
}

# Install databases (lightweight versions for WSL)
install_databases() {
    log_info "Installing database tools..."

    # PostgreSQL
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl enable postgresql 2>/dev/null || log_warning "Systemctl not available in WSL, PostgreSQL may need manual start"
    sudo systemctl start postgresql 2>/dev/null || log_warning "PostgreSQL start failed (normal in WSL)"

    # MySQL/MariaDB
    sudo apt install -y mariadb-server
    sudo systemctl enable mariadb 2>/dev/null || log_warning "Systemctl not available in WSL, MariaDB may need manual start"
    sudo systemctl start mariadb 2>/dev/null || log_warning "MariaDB start failed (normal in WSL)"

    # Redis
    sudo apt install -y redis-server
    sudo systemctl enable redis-server 2>/dev/null || log_warning "Systemctl not available in WSL, Redis may need manual start"
    sudo systemctl start redis-server 2>/dev/null || log_warning "Redis start failed (normal in WSL)"

    # Database clients
    sudo apt install -y postgresql-client mysql-client redis-tools

    # Install database client tools
    pip install --user pgcli mycli

    log_success "Database tools installed"
}

# Install Docker (Docker Desktop should be installed on Windows host)
setup_docker() {
    log_info "Setting up Docker integration..."

    # Check if Docker Desktop is running on Windows
    if docker version &>/dev/null; then
        log_success "Docker available (Docker Desktop detected)"
    else
        log_warning "Docker not detected. Install Docker Desktop on Windows host and enable WSL integration"
        log_info "To enable Docker in WSL: Open Docker Desktop > Settings > Resources > WSL Integration"
    fi
}

# Configure shell environment
configure_shell() {
    log_info "Configuring shell environment..."

    local shell_rc="$HOME/.bashrc"

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

    # Add WSL-specific configurations
    if ! grep -q 'WSL configuration' "$shell_rc"; then
        echo '' >> "$shell_rc"
        echo '# WSL configuration' >> "$shell_rc"
        echo 'export WSL=true' >> "$shell_rc"
        echo 'export BROWSER=wslview' >> "$shell_rc"
        echo 'export DISPLAY=:0' >> "$shell_rc"
        echo '' >> "$shell_rc"
        echo '# WSL file permissions fix' >> "$shell_rc"
        echo 'if [[ -f /proc/version ]] && grep -q "microsoft" /proc/version; then' >> "$shell_rc"
        echo '    umask 0022' >> "$shell_rc"
        echo 'fi' >> "$shell_rc"
    fi

    # Add useful aliases and functions
    if ! grep -q 'Development aliases' "$shell_rc"; then
        echo '' >> "$shell_rc"
        echo '# Development aliases' >> "$shell_rc"
        echo 'alias python=python3' >> "$shell_rc"
        echo 'alias pip=pip3' >> "$shell_rc"
        echo 'alias activate="source venv/bin/activate"' >> "$shell_rc"
        echo 'alias mkvenv="python -m venv venv && activate"' >> "$shell_rc"
        echo 'alias open="wslview"' >> "$shell_rc"
        echo 'alias explorer="wslview"' >> "$shell_rc"
    fi

    log_success "Shell environment configured"
}

# Create development directory structure
create_dev_structure() {
    log_info "Creating development directory structure..."

    mkdir -p ~/dev/{current,archive,tools,backups}
    mkdir -p ~/dev/current/{python,nodejs,java,cpp,web,mobile}

    # Create symlink to Windows dev directory if it exists
    if [[ -d /mnt/c/Users/$USER/dev ]]; then
        ln -sf /mnt/c/Users/$USER/dev ~/win-dev
        log_info "Created symlink to Windows dev directory: ~/win-dev"
    fi

    log_success "Development directories created"
}

# Install additional WSL-specific tools
install_wsl_tools() {
    log_info "Installing WSL-specific tools..."

    # Install Windows interoperability tools
    sudo apt install -y wslu

    # Install X11 forwarding tools (for GUI applications)
    sudo apt install -y x11-apps

    # Install file system tools
    sudo apt install -y dos2unix  # Convert Windows line endings

    log_success "WSL-specific tools installed"
}

# Configure Git for WSL
configure_git() {
    log_info "Configuring Git for WSL..."

    # Set Git to handle Windows line endings
    git config --global core.autocrlf input

    # Configure Git credential manager
    git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager-core.exe"

    log_success "Git configured for WSL"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."

    local errors=0

    # Check core tools
    for tool in git python3 node java mvn gradle gcc; do
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

    # Check WSL-specific tools
    if command -v wslview &>/dev/null; then
        log_success "wslu: installed"
    else
        log_warning "wslu: NOT FOUND (optional)"
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All tools verified successfully!"
    else
        log_warning "$errors tools failed verification. You may need to restart your WSL terminal or check the installation logs."
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}🚀 Setting up WSL2 Ubuntu Development Environment${NC}"
    echo -e "${BLUE}====================================================${NC}"

    check_wsl
    update_system
    install_dev_tools
    install_wsl_tools
    install_python
    install_nodejs
    install_java
    install_cpp
    install_databases
    setup_docker
    configure_shell
    configure_git
    create_dev_structure
    verify_installation

    echo ""
    echo -e "${GREEN}🎉 WSL2 Ubuntu development environment setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your WSL terminal or run 'source ~/.bashrc' to load the new configuration"
    echo "2. Run 'pyenv versions' to see available Python versions"
    echo "3. Run 'nvm list' to see available Node.js versions"
    echo "4. Run 'sdk list java' to see available Java versions"
    echo "5. Use the quickstart scripts to create new projects"
    echo "6. For GUI applications, install an X server on Windows (VcXsrv, X410, etc.)"
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Run main function
main "$@"
