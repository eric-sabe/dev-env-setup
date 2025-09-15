#!/bin/bash
# System Health Check Script
# Comprehensive development environment diagnostic tool

set -Eeuo pipefail  # Stricter error handling (will relax inside sections)
trap 'echo "[ERROR] Health check aborted at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

FAIL_COUNT=0
SECTION_ERRORS=()

run_section() {
    local name="$1"; shift
    # Run a section capturing errors but not aborting full script
    set +e
    ( set -e; "$@" )
    local rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
        FAIL_COUNT=$((FAIL_COUNT+1))
        SECTION_ERRORS+=("$name (exit $rc)")
        log_warning "Section '$name' reported errors (continuing)."
    fi
}

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
    echo -e "${PURPLE}🔍 $1${NC}"
    echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"
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
        PLATFORM="unknown"
    fi
}

# Check system resources
check_system_resources() {
    log_header "System Resources"

    echo "💻 System Information:"
    echo "   OS: $(uname -s) $(uname -r)"
    echo "   Architecture: $(uname -m)"
    echo "   Hostname: $(hostname)"
    echo "   User: $(whoami)"
    echo "   Uptime: $(uptime | sed 's/.*up //' | sed 's/,.*//')"
    echo ""

    echo "💾 Disk Usage:"
    df -h | head -1
    df -h / | tail -1

    # Check if disk usage is high
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        log_error "Disk usage is very high: ${disk_usage}%"
    elif [[ $disk_usage -gt 80 ]]; then
        log_warning "Disk usage is high: ${disk_usage}%"
    else
        log_success "Disk usage is normal: ${disk_usage}%"
    fi
    echo ""

    echo "🧠 Memory Usage:"
    if command -v free &>/dev/null; then
        free -h | grep -E "^(Mem|Swap)"
        echo ""
        # Memory usage percentage
        mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
        if [[ $mem_usage -gt 90 ]]; then
            log_error "Memory usage is very high: ${mem_usage}%"
        elif [[ $mem_usage -gt 80 ]]; then
            log_warning "Memory usage is high: ${mem_usage}%"
        else
            log_success "Memory usage is normal: ${mem_usage}%"
        fi
    elif [[ "$PLATFORM" == "macos" ]]; then
        vm_stat | head -10
    fi
    echo ""

    echo "🔥 CPU Load:"
    uptime
    echo ""
}

# Check development tools
check_development_tools() {
    log_header "Development Tools"

    local tools_found=0
    local tools_total=0

    # Python
    ((tools_total++))
    if command -v python3 &>/dev/null; then
        echo -e "${GREEN}✅ Python 3:$(python3 --version 2>&1 | cut -d' ' -f2)${NC}"
        ((tools_found++))
    else
        echo -e "${RED}❌ Python 3: Not found${NC}"
    fi

    # Python version managers
    if command -v pyenv &>/dev/null; then
        echo -e "${GREEN}   └─ pyenv:$(pyenv --version | cut -d' ' -f2)${NC}"
        echo -e "${BLUE}     └─ Global:$(pyenv global)${NC}"
    fi

    # Node.js
    ((tools_total++))
    if command -v node &>/dev/null; then
        echo -e "${GREEN}✅ Node.js:$(node --version)${NC}"
        ((tools_found++))
    else
        echo -e "${RED}❌ Node.js: Not found${NC}"
    fi

    # npm
    if command -v npm &>/dev/null; then
        echo -e "${GREEN}   └─ npm:$(npm --version)${NC}"
    fi

    # yarn
    if command -v yarn &>/dev/null; then
        echo -e "${GREEN}   └─ yarn:$(yarn --version)${NC}"
    fi

    # nvm
    if command -v nvm &>/dev/null; then
        echo -e "${GREEN}   └─ nvm:$(nvm --version)${NC}"
    fi

    # Java
    ((tools_total++))
    if command -v java &>/dev/null; then
        java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        echo -e "${GREEN}✅ Java:$java_version${NC}"
        ((tools_found++))
    else
        echo -e "${RED}❌ Java: Not found${NC}"
    fi

    # SDKMAN
    if command -v sdk &>/dev/null; then
        echo -e "${GREEN}   └─ SDKMAN:$(sdk version)${NC}"
    fi

    # Maven
    if command -v mvn &>/dev/null; then
        mvn_version=$(mvn -version 2>&1 | head -n1 | cut -d' ' -f3)
        echo -e "${GREEN}   └─ Maven:$mvn_version${NC}"
    fi

    # Gradle
    if command -v gradle &>/dev/null; then
        gradle_version=$(gradle -version 2>&1 | grep "Gradle" | cut -d' ' -f2)
        echo -e "${GREEN}   └─ Gradle:$gradle_version${NC}"
    fi

    # C/C++
    ((tools_total++))
    if command -v gcc &>/dev/null; then
        gcc_version=$(gcc --version | head -n1 | cut -d' ' -f4)
        echo -e "${GREEN}✅ GCC:$gcc_version${NC}"
        ((tools_found++))
    else
        echo -e "${RED}❌ GCC: Not found${NC}"
    fi

    if command -v g++ &>/dev/null; then
        echo -e "${GREEN}   └─ G++: Available${NC}"
    fi

    if command -v clang &>/dev/null; then
        clang_version=$(clang --version | head -n1 | cut -d' ' -f4)
        echo -e "${GREEN}   └─ Clang:$clang_version${NC}"
    fi

    # Git
    ((tools_total++))
    if command -v git &>/dev/null; then
        git_version=$(git --version | cut -d' ' -f3)
        echo -e "${GREEN}✅ Git:$git_version${NC}"
        ((tools_found++))
    else
        echo -e "${RED}❌ Git: Not found${NC}"
    fi

    # Docker
    if command -v docker &>/dev/null; then
        docker_version=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        echo -e "${GREEN}✅ Docker:$docker_version${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker: Not found${NC}"
    fi

    # VS Code
    if command -v code &>/dev/null; then
        echo -e "${GREEN}✅ VS Code: Installed${NC}"
    else
        echo -e "${YELLOW}⚠️  VS Code: Not found${NC}"
    fi

    echo ""
    echo "📊 Tool Summary: $tools_found/$tools_total core tools found"
    if [[ $tools_found -lt $tools_total ]]; then
        log_warning "Some core development tools are missing"
    else
        log_success "All core development tools are available"
    fi
    echo ""
}

# Check environment configurations
check_environment_config() {
    log_header "Environment Configuration"

    # Check PATH
    echo "🔗 PATH Configuration:"
    echo "$PATH" | tr ':' '\n' | head -10
    if [[ $(echo "$PATH" | tr ':' '\n' | wc -l) -gt 10 ]]; then
        echo "... and $(($(echo "$PATH" | tr ':' '\n' | wc -l) - 10)) more paths"
    fi
    echo ""

    # Check shell configuration
    echo "🐚 Shell Configuration:"
    echo "   Shell: $SHELL"
    echo "   Home: $HOME"

    if [[ -f ~/.bashrc ]]; then
        echo -e "${GREEN}   └─ .bashrc: Found${NC}"
    else
        echo -e "${YELLOW}   └─ .bashrc: Not found${NC}"
    fi

    if [[ -f ~/.zshrc ]]; then
        echo -e "${GREEN}   └─ .zshrc: Found${NC}"
    else
        echo -e "${YELLOW}   └─ .zshrc: Not found${NC}"
    fi

    if [[ -f ~/.profile ]]; then
        echo -e "${GREEN}   └─ .profile: Found${NC}"
    else
        echo -e "${YELLOW}   └─ .profile: Not found${NC}"
    fi
    echo ""

    # Check Python virtual environments
    echo "🐍 Python Environments:"
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo -e "${GREEN}   └─ Active venv: $(basename "$VIRTUAL_ENV")${NC}"
    else
        echo -e "${YELLOW}   └─ No active virtual environment${NC}"
    fi

    # Check for common venv directories
    venv_count=$(find . -maxdepth 2 -type d -name "venv" -o -name "env" -o -name ".venv" 2>/dev/null | wc -l)
    if [[ $venv_count -gt 0 ]]; then
        echo -e "${GREEN}   └─ Found $venv_count virtual environment(s) in current directory tree${NC}"
    fi
    echo ""

    # Check Node.js project
    echo "📦 Node.js Project:"
    if [[ -f package.json ]]; then
        echo -e "${GREEN}   └─ package.json: Found${NC}"
        if [[ -d node_modules ]]; then
            node_modules_count=$(find node_modules -maxdepth 1 -type d | wc -l)
            echo -e "${GREEN}   └─ node_modules: $((node_modules_count - 1)) packages${NC}"
        else
            echo -e "${YELLOW}   └─ node_modules: Not installed (run 'npm install')${NC}"
        fi
    else
        echo -e "${BLUE}   └─ Not a Node.js project${NC}"
    fi
    echo ""
}

# Check network connectivity
check_network() {
    log_header "Network Connectivity"

    echo "🌐 Network Status:"

    # Check internet connectivity
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo -e "${GREEN}✅ Internet: Connected${NC}"
    else
        echo -e "${RED}❌ Internet: Not connected${NC}"
    fi

    # Check DNS resolution
    if nslookup github.com &>/dev/null; then
        echo -e "${GREEN}✅ DNS: Working${NC}"
    else
        echo -e "${RED}❌ DNS: Not working${NC}"
    fi

    # Check common development sites
    sites=("github.com" "npmjs.com" "pypi.org" "gradle.org")
    for site in "${sites[@]}"; do
        if curl -s --max-time 5 --head "$site" &>/dev/null; then
            echo -e "${GREEN}✅ $site: Accessible${NC}"
        else
            echo -e "${RED}❌ $site: Not accessible${NC}"
        fi
    done
    echo ""
}

# Check security
check_security() {
    log_header "Security Check"

    echo "🔒 Security Status:"

    # Check SSH keys
    if [[ -d ~/.ssh ]]; then
        ssh_keys=$(find ~/.ssh -name "*.pub" 2>/dev/null | wc -l)
        echo -e "${GREEN}✅ SSH keys: $ssh_keys public key(s) found${NC}"

        # Check key permissions
        insecure_keys=$(find ~/.ssh -name "id_*" -not -name "*.pub" -perm /o+r 2>/dev/null | wc -l)
        if [[ $insecure_keys -gt 0 ]]; then
            echo -e "${RED}❌ SSH keys: $insecure_keys private key(s) have insecure permissions${NC}"
        else
            echo -e "${GREEN}✅ SSH keys: All private keys have secure permissions${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  SSH keys: No .ssh directory found${NC}"
    fi

    # Check sudo access
    if sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Sudo: Passwordless sudo is configured${NC}"
    else
        echo -e "${GREEN}✅ Sudo: Requires password${NC}"
    fi

    # Check firewall (basic check)
    if [[ "$PLATFORM" == "macos" ]]; then
        if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
            echo -e "${GREEN}✅ Firewall: Enabled${NC}"
        else
            echo -e "${YELLOW}⚠️  Firewall: Disabled${NC}"
        fi
    elif [[ "$PLATFORM" == "ubuntu" ]]; then
        if ufw status | grep -q "active"; then
            echo -e "${GREEN}✅ Firewall: Enabled${NC}"
        else
            echo -e "${YELLOW}⚠️  Firewall: Disabled${NC}"
        fi
    fi

    echo ""
}

# Generate health report
generate_report() {
    log_header "Health Report Summary"

    local report_file="$HOME/dev-health-report-$(date +%Y%m%d-%H%M%S).txt"

    echo "📋 Generating comprehensive health report..."
    echo "Report saved to: $report_file"
    echo ""

    {
        echo "Development Environment Health Report"
        echo "====================================="
        echo "Generated: $(date)"
        echo "Platform: $PLATFORM"
        echo "User: $(whoami)"
        echo ""

        echo "SYSTEM RESOURCES"
        echo "----------------"
        echo "OS: $(uname -s) $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Uptime: $(uptime | sed 's/.*up //' | sed 's/,.*//')"
        echo "Disk Usage: $(df -h / | tail -1)"
        if command -v free &>/dev/null; then
            echo "Memory Usage: $(free -h | grep Mem)"
        fi
        echo ""

        echo "DEVELOPMENT TOOLS"
        echo "-----------------"
        tools=("python3" "node" "java" "gcc" "git" "docker")
        for tool in "${tools[@]}"; do
            if command -v "$tool" &>/dev/null; then
                version=$("$tool" --version 2>&1 | head -n1)
                echo "✅ $tool: $version"
            else
                echo "❌ $tool: Not found"
            fi
        done
        echo ""

        echo "RECOMMENDATIONS"
        echo "---------------"
        echo "1. Ensure all core development tools are installed"
        echo "2. Keep disk usage below 80%"
        echo "3. Regularly update development tools"
        echo "4. Use virtual environments for Python projects"
        echo "5. Keep SSH keys secure"
        echo ""

    } > "$report_file"

    log_success "Health report generated: $report_file"
}

# Interactive mode menu
show_menu() {
    clear
    echo -e "${CYAN}🔍 Development Environment Health Check${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    echo "1. System Resources"
    echo "2. Development Tools"
    echo "3. Environment Configuration"
    echo "4. Network Connectivity"
    echo "5. Security Check"
    echo "6. Generate Full Report"
    echo "7. Quick Check (All)"
    echo "0. Exit"
    echo ""
}

# Quick check - run all checks
quick_check() {
    run_section "system_resources" check_system_resources
    run_section "development_tools" check_development_tools
    run_section "environment_config" check_environment_config
    run_section "network" check_network
    run_section "security" check_security

    echo ""
    if [[ $FAIL_COUNT -gt 0 ]]; then
        log_warning "Quick health check completed with $FAIL_COUNT section error(s)."
    else
        log_success "Health check completed!"
    fi
    echo ""
    read -p "Generate detailed report? (y/N): " generate
    if [[ $generate =~ ^[Yy]$ ]]; then
        generate_report
    fi
}

# Main function
main() {
    detect_platform

    # Check if running in interactive mode or with arguments
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Choose an option: " choice

            case $choice in
                1)
                    run_section "system_resources" check_system_resources
                    ;;
                2)
                    run_section "development_tools" check_development_tools
                    ;;
                3)
                    run_section "environment_config" check_environment_config
                    ;;
                4)
                    run_section "network" check_network
                    ;;
                5)
                    run_section "security" check_security
                    ;;
                6)
                    run_section "generate_report" generate_report
                    ;;
                7)
                    quick_check
                    ;;
                0)
                    log_success "Goodbye! 👋"
                    exit 0
                    ;;
                *)
                    log_error "Invalid option. Please choose 0-7."
                    sleep 2
                    ;;
            esac

            if [[ $choice != "7" && $choice != "0" ]]; then
                echo ""
                if [[ $FAIL_COUNT -gt 0 ]]; then
                    log_warning "Current session accumulated $FAIL_COUNT error section(s): ${SECTION_ERRORS[*]}"
                fi
                read -p "Press Enter to continue..."
            fi
        done
    else
        # Command line mode
        case $1 in
            --quick)
                quick_check
                ;;
            --resources)
                run_section "system_resources" check_system_resources
                ;;
            --tools)
                run_section "development_tools" check_development_tools
                ;;
            --config)
                run_section "environment_config" check_environment_config
                ;;
            --network)
                run_section "network" check_network
                ;;
            --security)
                run_section "security" check_security
                ;;
            --report)
                run_section "generate_report" generate_report
                ;;
            --help)
                echo "Usage: $0 [OPTION]"
                echo ""
                echo "Options:"
                echo "  --quick     Run all checks"
                echo "  --resources Check system resources"
                echo "  --tools     Check development tools"
                echo "  --config    Check environment configuration"
                echo "  --network   Check network connectivity"
                echo "  --security  Check security settings"
                echo "  --report    Generate detailed report"
                echo "  --help      Show this help"
                echo ""
                echo "Run without arguments for interactive mode."
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
        if [[ $FAIL_COUNT -gt 0 ]]; then
            log_warning "Completed with $FAIL_COUNT section error(s): ${SECTION_ERRORS[*]}"
            exit 1
        fi
    fi
}

# Run main function
main "$@"
