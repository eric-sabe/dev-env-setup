# Development Environment Setup Scripts

A comprehensive collection of scripts to set up and manage development environments for college computer science students across macOS, Linux, and Windows platforms.

## 🚀 Quick Start

**Get coding in 5 minutes:**

1. **Clone this repository**:
   ```bash
   git clone https://github.com/eric-sabe/dev-env-setup.git
   cd dev-env-setup
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x *.sh scripts/**/*.sh
   ```

3. **Run platform setup**:
   - **macOS**: `./setup/macos/setup-mac.sh`
   - **Linux**: `./setup/linux/setup-linux.sh`
   - **Windows**: `./setup/windows/setup-windows.ps1` then `./setup/windows/setup-wsl.sh`

4. **Create your first project**:
   - **Python**: `./quickstart/quickstart-python.sh`
   - **Node.js**: `./quickstart/quickstart-node.sh`

5. **Start coding!**

## ✅ What You Get

### Complete Development Environment
- **Languages**: Python, Node.js, Java, C++
- **Tools**: Git, Docker, databases, testing frameworks
- **IDEs**: VS Code, JetBrains IDEs (free student licenses)
- **Platforms**: macOS, Linux, Windows (WSL2)

### Course-Specific Setups
- **Database Systems**: PostgreSQL, MySQL, MongoDB, Redis
- **Web Development**: React, Vue, Angular, Express, Django
- **Machine Learning**: TensorFlow, PyTorch, scikit-learn, Jupyter
- **Systems Programming**: GCC, GDB, Valgrind, QEMU
- **Mobile Development**: React Native, Flutter

### Management Tools
- **Environment Manager**: Interactive tool management
- **Health Checks**: System diagnostics and monitoring
- **Backup/Restore**: Complete environment preservation
- **Cleanup**: Cache and junk file removal
- **Post-Install Verification**: Every course setup now self-validates installed tools (see Verification section)

## 🛠️ Key Scripts

| Script | Purpose |
|--------|---------|
| `setup/macos/setup-mac.sh` | Complete macOS development setup |
| `setup/linux/setup-linux.sh` | Complete Linux development setup |
| `quickstart/quickstart-python.sh` | Interactive Python project generator |
| `quickstart/quickstart-node.sh` | Interactive Node.js project generator |
| `management/env-manager.sh` | Environment management tool |
| `management/health-check.sh` | System health diagnostics |
| `courses/setup-database.sh` | Database course setup |
| `utils/diagnose.sh` | Aggregate diagnostics snapshot (add `--json` for machine-readable) |
| `utils/emergency-recovery.sh` | Last-resort recovery helpers |
| `utils/performance-tune.sh` | Performance snapshot suggestions |
| `utils/semester-archive.sh` | Archive semester projects |
| `setup/macos/cleanup-mac.sh` | macOS targeted cleanup wrapper |
| `setup/linux/cleanup-linux.sh` | Linux targeted cleanup wrapper |
| `setup/windows/cleanup-wsl.sh` | WSL targeted cleanup wrapper |
| `scripts/validate.sh` | Static analysis runner (shellcheck) |

## 📖 Documentation

- **[Complete Guide](GUIDE.md)**: Detailed setup instructions, troubleshooting, and advanced usage (renamed from guide.md)
- Platform-specific guidance consolidated in the Guide
- Script-level inline documentation within each script

## 🧰 Utilities Overview

Located in `scripts/utils` unless noted:

- `cross-platform.sh`: Shared logging, platform detection, safety helpers.
- `diagnose.sh`: Collects environment summary (system, tools, versions).
- `emergency-recovery.sh`: Minimal automated recovery + diagnostics snapshot.
- `performance-tune.sh`: Performance metrics snapshot (non-destructive).
- `semester-archive.sh`: Compresses project directories for archival.
- Cleanup wrappers: `setup/macos/cleanup-mac.sh`, `setup/linux/cleanup-linux.sh`, `setup/windows/cleanup-wsl.sh`.
- Validation: `scripts/validate.sh` runs shellcheck when available.

See `COVERAGE_MATRIX.md` for feature mapping and `DEFECTS.md` for improvement history. Recent additions: JSON diagnostics output, pyproject-only Python project option, dynamic MongoDB repo detection, idempotent semester archiving, resilient health check aggregation.

## ✅ Post-Install Verification

Each major course setup script (`setup-database.sh`, `setup-ml.sh`, `setup-webdev.sh`, `setup-systems.sh`, `setup-mobile.sh`) now performs a standardized verification pass at the end using `scripts/utils/verify.sh`.

What it checks (context-aware, non-fatal where appropriate):
- Presence of core commands (compilers, runtimes, CLIs)
- Python imports for key ML / data / web libraries
- Node global packages / CLIs for web & mobile frameworks
- Active services & listening ports for databases (PostgreSQL, MySQL/MariaDB, MongoDB, Redis)
- Lightweight smoke tests (Node execution, tiny C compile, PyTorch / TensorFlow GPU availability, Flutter doctor)

Summary output reports PASS / FAIL counts at the end of each script. Failures do not always abort; they highlight gaps students can fix immediately.

Run a script again after manual fixes—idempotent guards skip already-installed components while re-verifying.

## 🔐 Security & Hardening

Recent hardening & quality improvements:
- Unified strict Bash safety (`set -Eeuo pipefail`) and error traps across scripts.
- Added optional MySQL secure configuration (interactive or automated) during database course setup.
- Dynamic MongoDB repository codename detection for Ubuntu & derivatives (fallback safety if unknown).
- Safer cleanup operations with dry-run and confirmation prompts (`cleanup-dev.sh`).
- Centralized logging and platform detection via `cross-platform.sh` to reduce divergence.

Recommended manual follow-ups (not automated):
- Run `mysql_secure_installation` again if you need custom auth plugins or remote access changes.
- Review database service bind addresses before exposing outside localhost.
- Keep Docker Desktop / engine updated for CVE patches.

## 🖥️ GPU / ML Setup

`setup-ml.sh` auto-detects NVIDIA GPUs (`nvidia-smi`) and installs GPU variants of TensorFlow / PyTorch when present. Use `--no-gpu` to force CPU-only installs:
```
./scripts/courses/setup-ml.sh --no-gpu
```
CUDA / cuDNN installation steps remain partially manual on some distros (RHEL/CentOS, macOS). The script logs guidance without failing if unsupported.

## 🎓 For Students

This toolkit is designed specifically for computer science students to:
- **Save time** on environment setup
- **Learn best practices** through automated configurations
- **Focus on coding** instead of configuration
- **Maintain consistency** across different courses and projects

## 🤝 Contributing

We welcome contributions! See our [contributing guidelines](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Happy coding! 🎉**

*Review scripts before running with administrative privileges. These tools are provided for educational purposes.*
