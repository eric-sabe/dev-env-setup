#!/bin/bash
# Environment Manager Script
# Comprehensive development environment management tool

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_header() {
    echo -e "${PURPLE}🔧 $1${NC}"
    echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"
}

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        PLATFORM="windows"
    else
        PLATFORM="unknown"
    fi
}

# Python environment management
manage_python() {
    log_header "Python Environment Management"

    echo "1. List Python versions (pyenv)"
    echo "2. Install Python version"
    echo "3. Set global Python version"
    echo "4. Create virtual environment"
    echo "5. List virtual environments"
    echo "6. Activate virtual environment"
    echo "7. Update pip packages"
    echo "8. Show Python environment info"
    echo "0. Back to main menu"
    echo ""

    read -p "Choose Python option: " choice

    case $choice in
        1)
            if command -v pyenv &>/dev/null; then
                log_info "Available Python versions:"
                pyenv versions
            else
                log_error "pyenv not found. Install it first."
            fi
            ;;
        2)
            if command -v pyenv &>/dev/null; then
                read -p "Enter Python version to install (e.g., 3.11.0): " version
                log_info "Installing Python $version..."
                pyenv install "$version"
                log_success "Python $version installed"
            else
                log_error "pyenv not found. Install it first."
            fi
            ;;
        3)
            if command -v pyenv &>/dev/null; then
                read -p "Enter Python version to set globally: " version
                pyenv global "$version"
                log_success "Global Python version set to $version"
            else
                log_error "pyenv not found. Install it first."
            fi
            ;;
        4)
            read -p "Enter virtual environment name: " venv_name
            read -p "Enter Python version (leave empty for system default): " py_version

            if [[ -n "$py_version" ]]; then
                python"$py_version" -m venv "$venv_name"
            else
                python3 -m venv "$venv_name"
            fi

            log_success "Virtual environment '$venv_name' created"
            log_info "Activate with: source $venv_name/bin/activate"
            ;;
        5)
            log_info "Virtual environments in current directory:"
            ls -la | grep -E "^d.*venv|env" || echo "No virtual environments found"
            ;;
        6)
            read -p "Enter virtual environment path/name: " venv_path
            if [[ -f "$venv_path/bin/activate" ]]; then
                source "$venv_path/bin/activate"
                log_success "Activated virtual environment: $venv_path"
                log_info "Current Python: $(which python)"
                log_info "Current pip: $(which pip)"
            else
                log_error "Virtual environment not found: $venv_path"
            fi
            ;;
        7)
            if [[ -n "$VIRTUAL_ENV" ]]; then
                log_info "Updating pip packages in current virtual environment..."
                pip install --upgrade pip
                pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U
                log_success "Packages updated"
            else
                log_warning "No active virtual environment. Activate one first."
            fi
            ;;
        8)
            echo ""
            log_info "Python Environment Information:"
            echo "Python executable: $(which python3 2>/dev/null || which python)"
            echo "Python version: $(python3 --version 2>/dev/null || python --version)"
            echo "Pip version: $(pip3 --version 2>/dev/null || pip --version 2>/dev/null || echo 'pip not found')"
            echo "Virtual environment: ${VIRTUAL_ENV:-None active}"
            if command -v pyenv &>/dev/null; then
                echo "Pyenv versions: $(pyenv versions --bare | tr '\n' ' ')"
                echo "Pyenv global: $(pyenv global)"
            fi
            ;;
        0)
            return
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
}

# Node.js environment management
manage_nodejs() {
    log_header "Node.js Environment Management"

    echo "1. List Node.js versions (nvm)"
    echo "2. Install Node.js version"
    echo "3. Set default Node.js version"
    echo "4. Create new project"
    echo "5. Install global packages"
    echo "6. Update npm packages"
    echo "7. Clear npm cache"
    echo "8. Show Node.js environment info"
    echo "0. Back to main menu"
    echo ""

    read -p "Choose Node.js option: " choice

    case $choice in
        1)
            if command -v nvm &>/dev/null; then
                log_info "Available Node.js versions:"
                nvm list
            else
                log_error "nvm not found. Install it first."
            fi
            ;;
        2)
            if command -v nvm &>/dev/null; then
                read -p "Enter Node.js version to install (e.g., 18.17.0, lts): " version
                log_info "Installing Node.js $version..."
                nvm install "$version"
                log_success "Node.js $version installed"
            else
                log_error "nvm not found. Install it first."
            fi
            ;;
        3)
            if command -v nvm &>/dev/null; then
                read -p "Enter Node.js version to set as default: " version
                nvm alias default "$version"
                nvm use default
                log_success "Default Node.js version set to $version"
            else
                log_error "nvm not found. Install it first."
            fi
            ;;
        4)
            read -p "Enter project name: " project_name
            read -p "Choose template (express, react, vue, vanilla) [vanilla]: " template
            template=${template:-vanilla}

            case $template in
                express)
                    npx express-generator "$project_name" --view=pug
                    cd "$project_name"
                    npm install
                    ;;
                react)
                    npx create-react-app "$project_name"
                    ;;
                vue)
                    npx @vue/cli create "$project_name" --default
                    ;;
                vanilla)
                    mkdir "$project_name"
                    cd "$project_name"
                    npm init -y
                    ;;
                *)
                    log_error "Unknown template: $template"
                    return
                    ;;
            esac

            log_success "Project '$project_name' created with $template template"
            ;;
        5)
            read -p "Enter global packages to install (space-separated): " packages
            if [[ -n "$packages" ]]; then
                npm install -g $packages
                log_success "Global packages installed: $packages"
            fi
            ;;
        6)
            read -p "Update packages in current project? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                if [[ -f "package.json" ]]; then
                    npm update
                    log_success "Packages updated"
                else
                    log_error "No package.json found in current directory"
                fi
            fi
            ;;
        7)
            npm cache clean --force
            log_success "npm cache cleared"
            ;;
        8)
            echo ""
            log_info "Node.js Environment Information:"
            echo "Node.js executable: $(which node 2>/dev/null || echo 'not found')"
            echo "Node.js version: $(node --version 2>/dev/null || echo 'not found')"
            echo "npm version: $(npm --version 2>/dev/null || echo 'not found')"
            echo "yarn version: $(yarn --version 2>/dev/null || echo 'not found')"
            if command -v nvm &>/dev/null; then
                echo "nvm version: $(nvm --version)"
                echo "Current nvm version: $(nvm current)"
            fi
            if [[ -f "package.json" ]]; then
                echo "Current project: $(pwd)"
                echo "Project dependencies: $(jq -r '.dependencies | keys | length' package.json 2>/dev/null || echo 'unable to parse')"
            fi
            ;;
        0)
            return
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
}

# Java environment management
manage_java() {
    log_header "Java Environment Management"

    echo "1. List Java versions (SDKMAN)"
    echo "2. Install Java version"
    echo "3. Set default Java version"
    echo "4. Install Maven"
    echo "5. Install Gradle"
    echo "6. Create Java project"
    echo "7. Show Java environment info"
    echo "0. Back to main menu"
    echo ""

    read -p "Choose Java option: " choice

    case $choice in
        1)
            if command -v sdk &>/dev/null; then
                log_info "Available Java versions:"
                sdk list java
            else
                log_error "SDKMAN not found. Install it first."
            fi
            ;;
        2)
            if command -v sdk &>/dev/null; then
                read -p "Enter Java version to install (e.g., 11.0.19-tem, 17.0.7-tem): " version
                log_info "Installing Java $version..."
                sdk install java "$version"
                log_success "Java $version installed"
            else
                log_error "SDKMAN not found. Install it first."
            fi
            ;;
        3)
            if command -v sdk &>/dev/null; then
                read -p "Enter Java version to set as default: " version
                sdk default java "$version"
                log_success "Default Java version set to $version"
            else
                log_error "SDKMAN not found. Install it first."
            fi
            ;;
        4)
            if command -v sdk &>/dev/null; then
                log_info "Installing Maven..."
                sdk install maven
                log_success "Maven installed"
            else
                log_error "SDKMAN not found. Install it first."
            fi
            ;;
        5)
            if command -v sdk &>/dev/null; then
                log_info "Installing Gradle..."
                sdk install gradle
                log_success "Gradle installed"
            else
                log_error "SDKMAN not found. Install it first."
            fi
            ;;
        6)
            read -p "Enter project name: " project_name
            read -p "Choose build tool (maven, gradle) [maven]: " build_tool
            build_tool=${build_tool:-maven}

            case $build_tool in
                maven)
                    mvn archetype:generate -DgroupId=com.example -DartifactId="$project_name" -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
                    ;;
                gradle)
                    mkdir "$project_name"
                    cd "$project_name"
                    gradle init --type java-application
                    ;;
                *)
                    log_error "Unknown build tool: $build_tool"
                    return
                    ;;
            esac

            log_success "Java project '$project_name' created with $build_tool"
            ;;
        7)
            echo ""
            log_info "Java Environment Information:"
            echo "Java executable: $(which java 2>/dev/null || echo 'not found')"
            echo "Java version: $(java -version 2>&1 | head -n1 || echo 'not found')"
            echo "Javac version: $(javac -version 2>&1 || echo 'not found')"
            echo "Maven version: $(mvn -version 2>&1 | head -n1 || echo 'not found')"
            echo "Gradle version: $(gradle -version 2>&1 | head -n1 || echo 'not found')"
            if command -v sdk &>/dev/null; then
                echo "SDKMAN version: $(sdk version)"
                echo "Current Java: $(sdk current java 2>/dev/null || echo 'none')"
            fi
            ;;
        0)
            return
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
}

# System maintenance
system_maintenance() {
    log_header "System Maintenance"

    echo "1. Clean package manager caches"
    echo "2. Clean development tool caches"
    echo "3. Clean system temporary files"
    echo "4. Update all development tools"
    echo "5. Check disk usage"
    echo "6. Show system information"
    echo "0. Back to main menu"
    echo ""

    read -p "Choose maintenance option: " choice

    case $choice in
        1)
            log_info "Cleaning package manager caches..."
            case $PLATFORM in
                macos)
                    brew cleanup -s
                    brew autoremove
                    ;;
                linux)
                    sudo apt autoremove -y 2>/dev/null || true
                    sudo apt autoclean 2>/dev/null || true
                    ;;
            esac
            log_success "Package manager caches cleaned"
            ;;
        2)
            log_info "Cleaning development tool caches..."
            # npm/yarn
            npm cache clean --force 2>/dev/null || true
            yarn cache clean 2>/dev/null || true

            # pip
            pip cache purge 2>/dev/null || true

            # Maven
            rm -rf ~/.m2/repository/* 2>/dev/null || true

            # Gradle
            rm -rf ~/.gradle/caches/* 2>/dev/null || true

            log_success "Development tool caches cleaned"
            ;;
        3)
            log_info "Cleaning system temporary files..."
            # Clean old temp files
            find /tmp -type f -atime +7 -delete 2>/dev/null || true
            find ~/tmp -type f -atime +7 -delete 2>/dev/null || true

            # Clean bash history (optional)
            read -p "Clear bash history? (y/N): " clear_history
            if [[ $clear_history =~ ^[Yy]$ ]]; then
                cat /dev/null > ~/.bash_history
                log_success "Bash history cleared"
            fi

            log_success "System temporary files cleaned"
            ;;
        4)
            log_info "Updating development tools..."

            # Update pip
            pip install --upgrade pip 2>/dev/null || true

            # Update npm global packages
            npm update -g 2>/dev/null || true

            # Update SDKMAN
            if command -v sdk &>/dev/null; then
                sdk selfupdate
                sdk update
            fi

            log_success "Development tools updated"
            ;;
        5)
            log_info "Disk Usage Information:"
            echo ""
            df -h
            echo ""
            echo "Top 10 largest directories in home:"
            du -sh ~/* 2>/dev/null | sort -hr | head -10
            ;;
        6)
            echo ""
            log_info "System Information:"
            echo "OS: $(uname -s)"
            echo "Kernel: $(uname -r)"
            echo "Architecture: $(uname -m)"
            echo "User: $(whoami)"
            echo "Home Directory: $HOME"
            echo "Shell: $SHELL"
            echo "Uptime: $(uptime)"
            echo ""
            echo "Memory Usage:"
            free -h 2>/dev/null || vm_stat
            ;;
        0)
            return
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
}

# Main menu
show_main_menu() {
    clear
    echo -e "${CYAN}🔧 Development Environment Manager${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo ""
    echo "1. Python Environment Management"
    echo "2. Node.js Environment Management"
    echo "3. Java Environment Management"
    echo "4. System Maintenance"
    echo "5. Quick Health Check"
    echo "0. Exit"
    echo ""
}

# Quick health check
quick_health_check() {
    log_header "Quick Health Check"

    echo "🔍 Checking development environment..."
    echo ""

    # Check Python
    if command -v python3 &>/dev/null; then
        echo -e "${GREEN}✅ Python:$(python3 --version)${NC}"
    else
        echo -e "${RED}❌ Python: Not found${NC}"
    fi

    # Check Node.js
    if command -v node &>/dev/null; then
        echo -e "${GREEN}✅ Node.js:$(node --version)${NC}"
    else
        echo -e "${RED}❌ Node.js: Not found${NC}"
    fi

    # Check Java
    if command -v java &>/dev/null; then
        echo -e "${GREEN}✅ Java:$(java -version 2>&1 | head -n1)${NC}"
    else
        echo -e "${RED}❌ Java: Not found${NC}"
    fi

    # Check Git
    if command -v git &>/dev/null; then
        echo -e "${GREEN}✅ Git:$(git --version)${NC}"
    else
        echo -e "${RED}❌ Git: Not found${NC}"
    fi

    # Check Docker
    if command -v docker &>/dev/null; then
        echo -e "${GREEN}✅ Docker: Available${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker: Not found${NC}"
    fi

    echo ""
    echo "💾 Disk Usage:"
    df -h / | tail -1

    echo ""
    echo "🧠 Memory Usage:"
    free -h 2>/dev/null | grep "^Mem:" || echo "Memory info not available"

    echo ""
    read -p "Press Enter to continue..."
}

# Main function
main() {
    detect_platform

    while true; do
        show_main_menu
        read -p "Choose an option: " choice

        case $choice in
            1)
                manage_python
                ;;
            2)
                manage_nodejs
                ;;
            3)
                manage_java
                ;;
            4)
                system_maintenance
                ;;
            5)
                quick_health_check
                ;;
            0)
                log_success "Goodbye! 👋"
                exit 0
                ;;
            *)
                log_error "Invalid option. Please choose 0-5."
                sleep 2
                ;;
        esac
    done
}

# Run main function
main "$@"
