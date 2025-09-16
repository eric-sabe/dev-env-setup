# Development Environment Setup Guide

## Detailed Platform Setup

### macOS Setup

**Requirements**: macOS 12+ (Monterey or later), Admin access

**Initial Setup**:
```bash
cd ~/dev-scripts
./setup/macos/setup-mac.sh
```

This script will:
- Install Homebrew package manager
- Set up Xcode Command Line Tools
- Install and configure pyenv (Python), nvm (Node.js), SDKMAN (Java)
- Install development tools (Git, CMake, compilers)
- Configure shell environment (.zshrc)

**Maintenance**:
- Update tools: `./setup/macos/update-mac.sh`
- Clean environment: `./setup/macos/cleanup-mac.sh`

### Linux Setup

**Requirements**: Ubuntu 20.04+ or Debian 11+, sudo access

**Initial Setup**:
```bash
cd ~/dev-scripts
./setup/linux/setup-linux.sh
```

This script will:
- Update system packages
- Install build essentials and compilers
- Set up version managers for Python, Node.js, and Java
- Install Docker and database clients
- Configure shell environment (.bashrc)

### Windows 11 with WSL2

**Requirements**: Windows 10/11 with WSL2 capability

**Step 1 - Windows Setup** (Run PowerShell as Administrator):
```powershell
cd C:\path\to\dev-scripts
.\setup\windows\setup-windows.ps1
```

**Step 2 - WSL Setup** (Inside WSL Ubuntu):
```bash
cd ~/dev-scripts
./setup/windows/setup-wsl.sh
```
cd ~/dev-scripts
./setup/windows/setup-wsl.sh
```

## Environment Management

### Environment Manager
Interactive tool for managing development environments:

```bash
~/dev-scripts/management/env-manager.sh
```

**Use for**:
- Installing Python/Node.js/Java versions
- Creating and managing virtual environments
- Package management and updates
- System cleanup and optimization

### Health Checks
Monitor your development environment:

```bash
# Quick check
~/dev-scripts/management/health-check.sh --quick

# Detailed diagnostics
~/dev-scripts/management/health-check.sh --detailed

# Generate report
~/dev-scripts/management/health-check.sh --report
```

### Backup & Restore
```bash
# Backup your work
~/dev-scripts/management/backup-dev.sh

# Backups stored in ~/backups/dev/
```

**Common Tasks**:
```bash
# Create Python virtual environment
# Select option 1 → Python Tools → Create Virtual Environment

# Install Node.js version
# Select option 2 → Node.js Tools → Install Version

# Update all packages
# Select option 4 → System Maintenance → Update Packages
```

## Creating Projects

### Python Projects
```bash
~/dev-scripts/quickstart/quickstart-python.sh
```

**Choose from**:
1. **Web API** - REST APIs (FastAPI/Flask)
2. **CLI Tool** - Command-line applications
3. **Data Science/ML** - Notebooks, scikit-learn, data processing
4. **Library/Package** - Reusable Python packages
5. **Desktop App** - GUI applications (Tkinter/PyQt6)
6. **Minimal** - Basic Python setup

### Node.js Projects
```bash
~/dev-scripts/quickstart/quickstart-node.sh
```

**Choose from**:
1. **Web API** - Express.js REST API
2. **CLI Tool** - Command-line applications
3. **Library** - NPM packages
4. **Full-stack** - Complete web applications

### Other Languages
```bash
# Java projects
~/dev-scripts/quickstart/quickstart-java.sh my-project

# C++ projects
~/dev-scripts/quickstart/quickstart-cpp.sh my-project
```

## Language Management

### Python
```bash
# Install version
pyenv install 3.11.7

# Set project version
cd my-project
pyenv local 3.11.7

# Create virtual environment
python -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate   # Windows
```

### Node.js
```bash
# Install version
nvm install 20

# Use version
nvm use 20

# Set project version
echo "20" > .nvmrc
```

### Java
```bash
# Install version
sdk install java 17.0.9-zulu

# Use version
sdk use java 17.0.9-zulu

# Set project version
echo "java=17.0.9-zulu" > .sdkmanrc
```

## Course Setups

### Database Course
```bash
~/dev-scripts/courses/setup-database.sh
```
Installs PostgreSQL, MySQL, MongoDB, Redis, database tools

### Web Development Course
```bash
~/dev-scripts/courses/setup-webdev.sh
```
Installs React, Vue, Angular, Express, Django, testing tools

### Machine Learning Course
```bash
~/dev-scripts/courses/setup-ml.sh
```
Installs TensorFlow, PyTorch, scikit-learn, Jupyter, visualization

### Systems Programming Course
```bash
~/dev-scripts/courses/setup-systems.sh
```
Installs GDB, Valgrind, QEMU, cross-compilers

### Mobile Development Course
```bash
~/dev-scripts/courses/setup-mobile.sh
```
Installs React Native, Flutter, mobile SDKs

### Post-Install Verification (All Course Scripts)

All course setup scripts now conclude with a standardized verification summary powered by `scripts/utils/verify.sh`.

What gets validated:
- Databases: services running + ports open (5432, 3306, 27017, 6379) and client commands present
- ML: Python runtime, pip, core scientific libs, TensorFlow / PyTorch (with GPU capability notes)
- Web: Node.js toolchain, package managers, framework CLIs (React, Vue, Angular), Django import
- Systems: Compilers (gcc/clang), build tools (make, cmake, ninja), debuggers (gdb/lldb), valgrind, perf, QEMU, minimal compile smoke test
- Mobile: Node, React Native CLI, Expo, Flutter, adb, CocoaPods/Xcode (macOS), Appium / Detox

How to interpret results:
- PASS: Tool or library detected / basic usage succeeded
- FAIL: Missing critical component—re-run platform setup or install manually
- WARN: Optional or platform-specific tool unavailable (e.g., Valgrind on macOS)

Rerunning scripts: Safe & idempotent—skips existing installs but re-runs verification so students can confirm fixes.

## Troubleshooting

### Common Issues

**Command not found**:
```bash
# Check if tool is in PATH
which python
which node

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"
```

**Permission issues**:
```bash
# Fix npm permissions
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH

# Fix Python permissions
sudo chown -R $(whoami) ~/.cache/pip
```

**Port conflicts**:
```bash
# Find process using port
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill process
kill -9 $(lsof -t -i:3000)
```

**Version conflicts**:
```bash
# Python
pyenv versions
pyenv global 3.11.7

# Node.js
nvm list
nvm use 20

# Java
sdk list java
sdk use java 17.0.9-zulu
```

### Emergency Recovery
If everything breaks:
```bash
~/dev-scripts/utils/emergency-recovery.sh
```
**Warning**: This resets your entire development environment!

## Best Practices

### Project Organization
```
~/dev/
├── Spring2025/
│   ├── CS101-Intro/
│   │   ├── lab1/
│   │   ├── lab2/
│   │   └── project/
│   └── CS201-DataStructures/
│       ├── assignments/
│       └── project/
```

### Version Control
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <repository-url>
git push -u origin main
```

### Dependencies

**Python**:
```bash
python -m venv venv
source venv/bin/activate  # macOS/Linux
pip freeze > requirements.txt
```

**Node.js**:
```bash
npm ci  # Install from lock file
npm audit fix  # Fix vulnerabilities
```

### Environment Isolation
- Python: Virtual environments (use project generators)
- Node.js: `.nvmrc` files (auto-generated)
- Java: `.sdkmanrc` files (auto-generated)

### Regular Maintenance
- Weekly: Run `~/dev-scripts/management/health-check.sh --quick`
- Clean caches: `npm cache clean --force`, `pip cache purge`
- Update tools: `brew upgrade` (macOS), `apt update && apt upgrade` (Linux)
- Backup: `~/dev-scripts/management/backup-dev.sh`

### Security
Use provided `.gitignore`:
```bash
cp ~/dev-scripts/config/.gitignore-template .gitignore
```

Never commit: passwords, API keys, `.env` files, private keys, database dumps

## Quick Reference

### Python
```bash
pyenv versions                  # List versions
python -m venv venv            # Create virtual env
source venv/bin/activate       # Activate (macOS/Linux)
pip install -r requirements.txt # Install deps
```

### Node.js
```bash
nvm list                       # List versions
nvm use 20                     # Use version
npm ci                         # Clean install
npm run dev                    # Run dev server
```

### Java
```bash
sdk list java                  # List versions
sdk use java 17.0.9-zulu       # Use version
mvn clean install             # Build Maven
gradle build                  # Build Gradle
```

### Git
```bash
git status                    # Check status
git add .                     # Stage all
git commit -m "message"       # Commit
git push                      # Push to remote
```

### Docker
```bash
docker ps                     # List containers
docker images                 # List images
docker-compose up             # Start services
docker system prune           # Clean up
```

## Quick Starts
```bash
quickstart-python.sh          # Interactive Python project
quickstart-node.sh            # Interactive Node.js project
quickstart-java.sh project    # Java project
quickstart-cpp.sh project     # C++ project

# Environment Management
env-manager.sh               # Manage environments
health-check.sh --quick      # Quick health check
backup-dev.sh                # Backup work

# Cleanup
cleanup-mac.sh               # macOS cleanup
cleanup-linux.sh             # Linux cleanup
cleanup-wsl.sh              # WSL cleanup
```
~/dev-scripts/management/health-check.sh --permissions
```

## IDE Setup

### Visual Studio Code
```bash
~/dev-scripts/scripts/setup/setup-vscode.sh
cp ~/dev-scripts/config/vscode-settings.json ~/.config/Code/User/settings.json
```

### JetBrains IDEs
Free for students: https://www.jetbrains.com/student/
```bash
# Use JetBrains Toolbox (manual install) or install via your platform package manager.
# This repo currently focuses on VS Code automation.
```

## Resources

### Documentation
- **Python**: https://docs.python.org
- **Node.js**: https://nodejs.org/docs
- **Java**: https://docs.oracle.com/javase
- **Git**: https://git-scm.com/doc

### Package Managers
- **Homebrew** (macOS): https://brew.sh
- **npm** (Node.js): https://docs.npmjs.com
- **pip** (Python): https://pip.pypa.io
- **Maven** (Java): https://maven.apache.org

### Version Managers
- **pyenv**: https://github.com/pyenv/pyenv
- **nvm**: https://github.com/nvm-sh/nvm
- **SDKMAN**: https://sdkman.io

## Conclusion

Focus on coding, not setup. Use these scripts to get started quickly and maintain your environment efficiently.

**Key habits**:
- Use project generators for new projects
- Run health checks weekly
- Keep environments updated
- Backup regularly
- Follow best practices

Happy coding! 🚀

## Performance Optimization

Run performance tuning:
```bash
~/dev-scripts/utils/performance-tune.sh
```

This optimizes:
- File watchers (Linux/WSL2)
- Git performance
- Package manager caches
- Platform-specific settings

## Cross-Platform Development

Use the cross-platform utilities:
```bash
source ~/dev-scripts/utils/cross-platform.sh

# Now use functions like:
detect_os        # Returns: macos, linux, or windows
install_package  # Installs across platforms
```

## Resources and Support

### Documentation
- **Python**: https://docs.python.org
- **Node.js**: https://nodejs.org/docs
- **Java**: https://docs.oracle.com/javase
- **Git**: https://git-scm.com/doc

### Package Managers
- **Homebrew** (macOS): https://brew.sh
- **npm** (Node.js): https://docs.npmjs.com
- **pip** (Python): https://pip.pypa.io
- **Maven** (Java): https://maven.apache.org

### Version Managers
- **pyenv**: https://github.com/pyenv/pyenv
- **nvm**: https://github.com/nvm-sh/nvm
- **SDKMAN**: https://sdkman.io

### Communities
- Stack Overflow: https://stackoverflow.com
- Reddit: r/learnprogramming, r/csmajors
- Discord: Various programming servers
- Campus resources: TA office hours, computer labs

## Quick Reference Card

```bash
# Python
pyenv versions                  # List Python versions
python -m venv venv            # Create virtual environment
source venv/bin/activate       # Activate environment
pip install -r requirements.txt # Install dependencies

# Node.js
nvm list                       # List Node versions
nvm use                        # Use .nvmrc version
npm ci                         # Clean install
npm run dev                    # Run dev server

# Java
sdk list java                  # List Java versions
sdk env                        # Load .sdkmanrc
mvn clean install             # Build Maven project
gradle build                  # Build Gradle project

# Git
git status                    # Check status
git add .                     # Stage all changes
git commit -m "message"       # Commit changes
git push                      # Push to remote

# Docker
docker ps                     # List running containers
docker images                 # List images
docker-compose up            # Start services
docker system prune          # Clean up

# Quick Starts (Enhanced 2025)
quickstart-python.sh          # Interactive Python project generator (6 project types)
quickstart-node.sh            # Interactive Node.js project generator (4 project types)

# Environment Management (Enhanced)
env-manager.sh               # Comprehensive environment management with interactive menus
health-check.sh              # Advanced health monitoring with detailed diagnostics
backup-dev.sh                # Automated backup system with restore capabilities

# Legacy Quick Starts (Still Available)
quickstart-java.sh project   # Java project template
quickstart-cpp.sh project    # C++ project template

# Cleanup Scripts
cleanup-mac.sh               # macOS environment cleanup
cleanup-linux.sh             # Linux environment cleanup
cleanup-wsl.sh              # WSL environment cleanup
```

## Appendix A: File Structure Templates

### Python Project Structure
```
my-python-project/
├── .python-version          # pyenv version
├── .gitignore              # Git ignore rules
├── requirements.txt        # Production dependencies
├── requirements-dev.txt    # Development dependencies
├── README.md              # Project documentation
├── setup.py               # Package configuration
├── venv/                  # Virtual environment
├── src/                   # Source code
│   ├── __init__.py
│   └── main.py
├── tests/                 # Test files
│   ├── __init__.py
│   └── test_main.py
└── docs/                  # Documentation
```

### Node.js Project Structure
```
my-node-project/
├── .nvmrc                 # Node version
├── .gitignore            # Git ignore rules
├── package.json          # Dependencies and scripts
├── package-lock.json     # Locked dependencies
├── README.md            # Project documentation
├── .env.example         # Environment variables template
├── src/                 # Source code
│   ├── index.js
│   ├── routes/
│   ├── models/
│   └── utils/
├── tests/               # Test files
│   └── app.test.js
├── public/              # Static files
└── node_modules/        # Dependencies (not committed)
```

### Java Project Structure (Maven)
```
my-java-project/
├── .sdkmanrc            # Java version
├── .gitignore          # Git ignore rules
├── pom.xml             # Maven configuration
├── README.md           # Project documentation
├── src/
│   ├── main/
│   │   ├── java/      # Source code
│   │   └── resources/ # Resources
│   └── test/
│       ├── java/      # Test code
│       └── resources/ # Test resources
└── target/             # Build output (not committed)
```

### C++ Project Structure
```
my-cpp-project/
├── .gitignore          # Git ignore rules
├── CMakeLists.txt      # CMake configuration
├── README.md           # Project documentation
├── build.sh            # Build script
├── include/            # Header files
│   └── utils.h
├── src/                # Source files
│   └── main.cpp
├── tests/              # Test files
│   └── test_main.cpp
├── build/              # Build artifacts (not committed)
└── docs/               # Documentation
```

## Appendix B: Configuration Files

### .gitignore Template
```gitignore
# Use the provided template:
cp ~/dev-scripts/config/.gitignore-template .gitignore
```

### EditorConfig (.editorconfig)
```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{py,js,java,cpp,h}]
indent_style = space
indent_size = 4

[*.{json,yml,yaml}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

### Prettier Config (.prettierrc)
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
```

### ESLint Config (.eslintrc.json)
```json
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": 12,
    "sourceType": "module"
  },
  "rules": {
    "indent": ["error", 2],
    "quotes": ["error", "single"],
    "semi": ["error", "always"]
  }
}
```

## Appendix C: Common Commands Reference

### Package Installation

**Python**:
```bash
pip install package-name              # Install package
pip install -r requirements.txt       # Install from file
pip install --upgrade package-name    # Upgrade package
pip uninstall package-name            # Remove package
pip list                              # List installed packages
pip freeze > requirements.txt         # Save dependencies
```

**Node.js**:
```bash
npm install package-name              # Install package
npm install --save-dev package-name   # Install dev dependency
npm install                           # Install from package.json
npm ci                                # Clean install from lock
npm update                            # Update packages
npm uninstall package-name            # Remove package
npm list                              # List installed packages
```

**Java (Maven)**:
```bash
mvn install                           # Install dependencies
mvn clean install                     # Clean and install
mvn dependency:tree                   # View dependency tree
mvn dependency:analyze                # Analyze dependencies
mvn versions:display-dependency-updates # Check for updates
```

### Version Control

```bash
# Setup
git init                              # Initialize repository
git clone <url>                       # Clone repository

# Basic workflow
git status                            # Check status
git add <file>                        # Stage file
git add .                             # Stage all files
git commit -m "message"               # Commit changes
git push                              # Push to remote
git pull                              # Pull from remote

# Branches
git branch                            # List branches
git branch <name>                     # Create branch
git checkout <branch>                 # Switch branch
git checkout -b <branch>              # Create and switch
git merge <branch>                    # Merge branch

# Undo
git reset HEAD <file>                 # Unstage file
git reset --hard HEAD                 # Reset to last commit
git revert <commit>                   # Revert commit
```

### Docker Commands

```bash
# Images
docker images                         # List images
docker pull <image>                   # Download image
docker build -t <name> .              # Build image
docker rmi <image>                    # Remove image

# Containers
docker ps                             # List running containers
docker ps -a                          # List all containers
docker run <image>                    # Run container
docker stop <container>               # Stop container
docker rm <container>                 # Remove container

# Compose
docker-compose up                     # Start services
docker-compose down                   # Stop services
docker-compose logs                   # View logs
docker-compose ps                     # List services

# Cleanup
docker system prune                   # Remove unused data
docker system prune -a                # Remove all unused data
```

## Appendix D: Troubleshooting Flowchart

```
Problem Occurs
    ↓
Run diagnose.sh
    ↓
Check error type:
    ├─ Command not found → Check PATH, reinstall tool
    ├─ Permission denied → Check file permissions, use sudo if appropriate
    ├─ Port in use → Find process using port, kill or change port
    ├─ Module not found → Check virtual environment, reinstall dependencies
    ├─ Version conflict → Check version managers, set correct version
    └─ Network error → Check internet, proxy settings, DNS

If not resolved:
    ↓
Run health-check.sh
    ↓
Check specific area:
    ├─ Disk full → Clean caches, remove old projects
    ├─ Memory issues → Close applications, increase swap
    ├─ Corrupt environment → Reset with cleanup scripts
    └─ Unknown → Use emergency-recovery.sh (last resort)
```

## Appendix E: Semester Timeline

### Week 1-2: Environment Setup
- Run platform setup script
- Install IDEs and extensions
- Set up version control
- Create semester directory structure

### Week 3-4: Course-Specific Setup
- Run course setup scripts as needed
- Create project templates
- Test all tools and environments

### Mid-Semester: Maintenance
- Run health checks weekly
- Clean up unused dependencies
- Backup important work
- Update tools if needed

### Week Before Finals: Preparation
- Full backup of all work
- Clean and optimize environments
- Ensure all projects build correctly
- Document any special setup needs

### After Finals: Archive
- Run semester archive script
- Create summary documentation
- Clean up disk space
- Prepare for next semester

## Tips for Success

### 1. Start Clean
Begin each semester with a fresh environment setup. This prevents accumulated cruft from previous courses interfering with new work.

### 2. Document Everything
Keep a `SETUP.md` in each project documenting:
- Required versions (Python, Node, Java)
- Installation steps
- How to run the project
- Known issues and solutions

### 3. Use Version Control Properly
- Commit early and often
- Write meaningful commit messages
- Never commit sensitive data
- Use branches for experiments

### 4. Automate Repetitive Tasks
If you do something more than twice, write a script for it. The time invested in automation pays off quickly.

### 5. Learn from Errors
When you encounter and solve a problem:
- Document the solution
- Add it to your personal troubleshooting guide
- Share with classmates

### 6. Stay Organized
- One project per directory
- Consistent naming conventions
- Regular cleanup of old files
- Maintain a project index/README

### 7. Backup Strategies
- Use Git for code (GitHub, GitLab, Bitbucket)
- Cloud storage for large files (Google Drive, Dropbox)
- Local backups for quick recovery
- Test restore procedures periodically

### 8. Performance Monitoring
- Check disk usage weekly
- Monitor memory usage during heavy work
- Clean caches regularly
- Restart your machine weekly

### 9. Security Awareness
- Use strong, unique passwords
- Enable 2FA where possible
- Keep sensitive data encrypted
- Review permissions regularly

### 10. Continuous Learning
- Read documentation
- Follow best practices
- Learn from others' setups
- Contribute improvements back

## Conclusion

Managing development environments across multiple courses doesn't have to be overwhelming. With the enhanced 2025 tools, you can maintain clean, efficient, and reliable environments throughout your academic career.

**Key 2025 Improvements**:
- **Interactive Tools**: User-friendly menus guide you through complex tasks
- **Professional Generators**: Create production-ready projects with industry best practices
- **Comprehensive Monitoring**: Advanced health checks with automated fixes and detailed reporting
- **Complete Automation**: From project creation to environment maintenance, everything is automated

**Remember**:
- **Automate** with the enhanced interactive tools
- **Monitor** your environment health regularly
- **Generate** professional projects with the quickstart tools
- **Document** your setup and solutions
- **Backup** your work regularly
- **Clean** environments periodically
- **Learn** from each experience

The scripts provided in this guide are comprehensive tools designed for modern development workflows. The enhanced 2025 edition provides enterprise-grade capabilities that will serve you well in both academic and professional environments.

Good luck with your studies, and happy coding! 🚀

---

*Version: 2.0 (2025 Edition)*  
*Last Updated: September 2025*  
*Major Updates: Enhanced interactive tools, professional project generators, comprehensive health monitoring*  
*Feedback: Improve this guide by submitting suggestions to your TA or professor*