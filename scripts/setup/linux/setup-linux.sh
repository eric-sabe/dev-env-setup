#!/bin/bash
# Linux Development Environment Setup Script
# Comprehensive setup for CS students - Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+

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

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="rhel"
        VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9]\+\).*/\1/')
    else
        log_error "Unsupported Linux distribution"
        exit 1
    fi

    log_success "Detected $DISTRO $VERSION"
}

# Check if running as root (not recommended)
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root is not recommended. Please run as a regular user with sudo access."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Update system packages
update_system() {
    log_info "Updating system packages..."

    case $DISTRO in
        ubuntu|debian|pop|elementary|linuxmint)
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y software-properties-common apt-transport-https ca-certificates curl wget gnupg lsb-release
            ;;
        centos|rhel|fedora)
            if [[ $DISTRO == "fedora" ]]; then
                sudo dnf update -y
                sudo dnf install -y dnf-plugins-core curl wget
            else
                sudo yum update -y
                sudo yum install -y yum-utils curl wget
            fi
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl wget
            ;;
        *)
            log_error "Unsupported distribution for package updates"
            ;;
    esac

    log_success "System updated"
}

# Install development tools
install_dev_tools() {
    log_info "Installing development tools..."

    case $DISTRO in
        ubuntu|debian|pop|elementary|linuxmint)
            sudo apt install -y build-essential git cmake htop tree jq unzip zip
            ;;
        centos|rhel)
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y git cmake htop tree jq unzip zip
            ;;
        fedora)
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y git cmake htop tree jq unzip zip
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm base-devel git cmake htop tree jq unzip zip
            ;;
    esac

    log_success "Development tools installed"
}

# Install Python and pyenv
install_python() {
    log_info "Setting up Python environment..."

    # Install pyenv dependencies
    case $DISTRO in
        ubuntu|debian|pop|elementary|linuxmint)
            sudo apt install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
            ;;
        centos|rhel)
            sudo yum install -y openssl-devel zlib-devel bzip2-devel readline-devel sqlite-devel llvm ncurses-devel xz-devel tk-devel libxml2-devel libxmlsec1-devel libffi-devel lzma-devel
            ;;
        fedora)
            sudo dnf install -y openssl-devel zlib-devel bzip2-devel readline-devel sqlite-devel llvm ncurses-devel xz-devel tk-devel libxml2-devel libxmlsec1-devel libffi-devel lzma-devel
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm openssl zlib bzip2 readline sqlite llvm ncurses xz tk libxml2 libxmlsec libffi xz
            ;;
    esac

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

    case $DISTRO in
        ubuntu|debian|pop|elementary|linuxmint)
            sudo apt install -y clang clang-format clang-tidy gdb valgrind cmake
            sudo apt install -y libboost-all-dev libeigen3-dev
            ;;
        centos|rhel)
            sudo yum install -y clang clang-tools-extra gdb valgrind cmake
            sudo yum install -y boost-devel eigen3-devel
            ;;
        fedora)
            sudo dnf install -y clang clang-tools-extra gdb valgrind cmake
            sudo dnf install -y boost-devel eigen3-devel
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm clang gdb valgrind cmake boost eigen
            ;;
    esac

    log_success "C++ environment configured"
}

# Install databases
install_databases() {
    log_info "Installing database tools..."

    case $DISTRO in
        ubuntu|debian|pop|elementary|linuxmint)
            # PostgreSQL
            sudo apt install -y postgresql postgresql-contrib
            sudo systemctl enable postgresql
            sudo systemctl start postgresql

            # MySQL
            sudo apt install -y mysql-server
            sudo systemctl enable mysql
            sudo systemctl start mysql

            # MongoDB
            curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            sudo apt update
            sudo apt install -y mongodb-org
            sudo systemctl enable mongod
            sudo systemctl start mongod

            # Redis
            sudo apt install -y redis-server
            sudo systemctl enable redis-server
            sudo systemctl start redis-server

            # Database clients
            sudo apt install -y postgresql-client mysql-client
            ;;
        centos|rhel|fedora)
            # PostgreSQL
            if [[ $DISTRO == "fedora" ]]; then
                sudo dnf install -y postgresql-server postgresql-contrib
                sudo postgresql-setup --initdb
                sudo systemctl enable postgresql
                sudo systemctl start postgresql
            else
                sudo yum install -y postgresql-server postgresql-contrib
                sudo postgresql-setup initdb
                sudo systemctl enable postgresql
                sudo systemctl start postgresql
            fi

            # MySQL/MariaDB
            sudo yum install -y mariadb-server
            sudo systemctl enable mariadb
            sudo systemctl start mariadb

            # MongoDB
            # Note: MongoDB installation on RHEL/CentOS is complex, skip for now

            # Redis
            sudo yum install -y redis
            sudo systemctl enable redis
            sudo systemctl start redis
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm postgresql mysql mongodb redis
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            sudo systemctl enable mysqld
            sudo systemctl start mysqld
            sudo systemctl enable mongodb
            sudo systemctl start mongodb
            sudo systemctl enable redis
            sudo systemctl start redis
            ;;
    esac

    # Install database client tools
    pip install --user pgcli mycli

    log_success "Database tools installed"
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."

    case $DISTRO in
        ubuntu|debian|pop|elementary|linuxmint)
            # Remove old versions
            sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

            # Install Docker
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

            # Add user to docker group
            sudo usermod -aG docker $USER
            ;;
        centos|rhel|fedora)
            # Remove old versions
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true

            # Install Docker
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

            # Add user to docker group
            sudo usermod -aG docker $USER
            sudo systemctl enable docker
            sudo systemctl start docker
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm docker docker-compose
            sudo usermod -aG docker $USER
            sudo systemctl enable docker
            sudo systemctl start docker
            ;;
    esac

    log_success "Docker installed"
}

# Install IDEs
install_ides() {
    log_info "Installing IDEs..."

    case $DISTRO in
        ubuntu|debian|pop|elementary|linuxmint)
            # Install VS Code
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
            sudo apt update
            sudo apt install -y code

            # Install Eclipse
            sudo snap install eclipse --classic
            ;;
        centos|rhel|fedora)
            # VS Code
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
            sudo yum install -y code

            # Eclipse - download and install manually
            log_info "Please download Eclipse manually from https://www.eclipse.org/downloads/"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm code eclipse-java
            ;;
    esac

    log_success "IDEs installed"
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

    # Add useful aliases and functions
    if ! grep -q 'Development aliases' "$shell_rc"; then
        echo '' >> "$shell_rc"
        echo '# Development aliases' >> "$shell_rc"
        echo 'alias python=python3' >> "$shell_rc"
        echo 'alias pip=pip3' >> "$shell_rc"
        echo 'alias activate="source venv/bin/activate"' >> "$shell_rc"
        echo 'alias mkvenv="python -m venv venv && activate"' >> "$shell_rc"
    fi

    log_success "Shell environment configured"
}

# Create development directory structure
create_dev_structure() {
    log_info "Creating development directory structure..."

    mkdir -p ~/dev/{current,archive,tools,backups}
    mkdir -p ~/dev/current/{python,nodejs,java,cpp,web,mobile}

    log_success "Development directories created"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."

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

    if [[ $errors -eq 0 ]]; then
        log_success "All tools verified successfully!"
    else
        log_warning "$errors tools failed verification. You may need to restart your terminal or check the installation logs."
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}🚀 Setting up Linux Development Environment${NC}"
    echo -e "${BLUE}===============================================${NC}"

    detect_distro
    check_privileges
    update_system
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
    echo -e "${GREEN}🎉 Linux development environment setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal or run 'source ~/.bashrc' to load the new configuration"
    echo "2. Run 'newgrp docker' or log out/in to use Docker without sudo"
    echo "3. Run 'pyenv versions' to see available Python versions"
    echo "4. Run 'nvm list' to see available Node.js versions"
    echo "5. Run 'sdk list java' to see available Java versions"
    echo "6. Use the quickstart scripts to create new projects"
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Run main function
main "$@"
