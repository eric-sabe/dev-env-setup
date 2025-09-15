# Contributing to Development Environment Setup Scripts

Thank you for your interest in contributing to the Development Environment Setup Scripts! This project aims to help computer science students get started with development environments quickly and efficiently.

## 🚀 Ways to Contribute

### Report Issues
- **Bug Reports**: Found a bug? [Create an issue](https://github.com/eric-sabe/dev-env-setup/issues/new) with:
  - Clear title and description
  - Steps to reproduce
  - Expected vs actual behavior
  - Your platform (macOS/Linux/Windows) and versions

- **Feature Requests**: Have an idea? [Create an issue](https://github.com/eric-sabe/dev-env-setup/issues/new) with:
  - Clear description of the feature
  - Why it would be useful
  - Any implementation suggestions

### Code Contributions
- **Fixes**: Small bug fixes are always welcome
- **Enhancements**: New features or improvements to existing scripts
- **Documentation**: Improvements to guides, README, or inline documentation
- **Testing**: Additional test coverage or test improvements

## 🛠️ Development Setup

### Prerequisites
- Bash-compatible shell (zsh/bash)
- Git
- Basic understanding of shell scripting

### Local Development
1. **Fork and Clone**:
   ```bash
   git clone https://github.com/your-username/dev-env-setup.git
   cd dev-env-setup
   ```

2. **Create a branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-number
   ```

3. **Make your changes** and test them locally

4. **Test your changes**:
   - Run scripts in a safe environment first
   - Test on your platform
   - Check for syntax errors: `bash -n script.sh`

## 📝 Coding Standards

### Shell Scripts
- Use `#!/bin/bash` shebang
- Include comprehensive error handling with `set -e`
- Add clear comments explaining complex logic
- Use meaningful variable names
- Follow consistent indentation (2 or 4 spaces)
- Include usage examples in comments

### Example Script Structure
```bash
#!/bin/bash
# Description: Brief description of what the script does
# Usage: ./script.sh [options]
# Author: Your Name
# Date: YYYY-MM-DD

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Functions first
log_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Main logic
main() {
    log_info "Starting script..."
    # Your code here
}

# Run main function
main "$@"
```

### Documentation
- Update README.md for new features
- Update guide.md for detailed changes
- Add inline comments for complex logic
- Include usage examples

## 🧪 Testing Guidelines

### Manual Testing
- Test scripts on your platform before submitting
- Verify error handling works correctly
- Check that scripts are idempotent (can be run multiple times safely)
- Test with different user permissions

### Platform Testing
- macOS: Test on latest macOS version
- Linux: Test on Ubuntu and at least one other distribution
- Windows: Test WSL2 setup

### Checklist Before Submitting
- [ ] Scripts run without syntax errors (`bash -n`)
- [ ] Scripts include proper error handling
- [ ] Documentation is updated
- [ ] Changes tested on target platforms
- [ ] No sensitive information committed
- [ ] Follows coding standards

## 📋 Pull Request Process

1. **Create a Pull Request**:
   - Use a clear, descriptive title
   - Reference any related issues
   - Provide a summary of changes

2. **PR Description**:
   ```markdown
   ## Description
   Brief description of what this PR does

   ## Changes Made
   - Change 1
   - Change 2
   - Change 3

   ## Testing
   - How you tested the changes
   - Platforms tested on

   ## Screenshots (if applicable)
   Any relevant screenshots or output
   ```

3. **Review Process**:
   - Maintainers will review your PR
   - Address any feedback or requested changes
   - Once approved, your PR will be merged

## 🎯 Types of Contributions

### Script Improvements
- Better error handling
- Performance optimizations
- Cross-platform compatibility
- Security improvements

### New Features
- Additional language support
- New course setups
- Enhanced management tools
- Integration with new tools

### Documentation
- Improved setup guides
- Better troubleshooting sections
- Video tutorials or screencasts
- Translation to other languages

### Testing
- Automated test scripts
- CI/CD pipeline improvements
- Test coverage expansion

## 🚫 What Not to Contribute

- Scripts that require paid software/licenses
- Changes that break existing functionality
- Code with security vulnerabilities
- Unnecessary complexity
- Platform-specific code that could be cross-platform

## 📞 Getting Help

- **Questions**: Create a discussion or issue
- **Stuck**: Ask for help in your PR comments
- **Ideas**: Start a discussion to gather feedback

## 📜 Code of Conduct

### Be Respectful
- Treat all contributors with respect
- Use inclusive language
- Focus on constructive feedback
- Help newcomers learn

### Be Collaborative
- Work together to solve problems
- Share knowledge and best practices
- Give credit where due
- Celebrate successes

### Be Responsible
- Test your changes thoroughly
- Follow security best practices
- Respect user privacy
- Consider the impact on students

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md (if we create one)
- Mentioned in release notes
- Credited in documentation updates
- Recognized for their impact on student success

## 📋 License

By contributing to this project, you agree that your contributions will be licensed under the same MIT License that covers the project.

---

**Thank you for contributing to make development environments easier for CS students! 🎓🚀**
