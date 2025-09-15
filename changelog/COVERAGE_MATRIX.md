# Coverage Matrix

This document maps claims in README and guide to actual scripts present in the repository and identifies gaps.

Legend: Present ✅  Missing ❌  Partial (exists but incomplete) ⚠️

## Core Environment & Maintenance
| Claim (README / Guide) | Script Path | Status | Notes |
|------------------------|-------------|--------|-------|
| Backup development environment | scripts/backup-dev.sh | ✅ | Covers projects, configs, packages, DBs; extensible. |
| Restore development environment | scripts/restore-dev.sh | ✅ | Recreates from backup directory or archive. |
| Cleanup (generic) | scripts/cleanup-dev.sh | ✅ | Multi‑option interactive cleanup. |
| Platform-specific cleanup: macOS | scripts/setup/macos/cleanup-mac.sh | ✅ | Wrapper around generic cleanup + brew cache purge. |
| Platform-specific cleanup: Linux | scripts/setup/linux/cleanup-linux.sh | ✅ | Wrapper: pm cache clean + generic cleanup. |
| Platform-specific cleanup: WSL | scripts/setup/windows/cleanup-wsl.sh | ✅ | Wrapper: log trimming + generic cleanup. |
| Emergency recovery script | scripts/utils/emergency-recovery.sh | ✅ | Minimal guided recovery + diagnostics. |
| Performance tuning script | scripts/utils/performance-tune.sh | ✅ | Non-destructive performance snapshot. |
| Cross-platform shared utilities | scripts/utils/cross-platform.sh | ✅ | Central logging, platform detect, safety helpers. |
| Diagnose / troubleshooting script | scripts/utils/diagnose.sh | ✅ | Aggregated environment snapshot. |
| Semester/archive automation | scripts/utils/semester-archive.sh | ✅ | Archives dev/project dirs to timestamped tarballs. |
| Health check / environment diagnostics | scripts/management/health-check.sh | ✅ | Provides extensive system & tool checks. |
| Environment manager (interactive) | scripts/management/env-manager.sh | ✅ | Menus for Python/Node/Java + maintenance. |
| Semester/archive automation (duplicate legacy reference) | — | ✅ | Consolidated; single implementation present. |

## Platform Setup
| Claim | Script | Status | Notes |
|-------|--------|--------|-------|
| macOS setup | scripts/setup/macos/setup-mac.sh | ✅ | Performs macOS bootstrap. |
| Linux setup | scripts/setup/linux/setup-linux.sh | ✅ | Performs Linux bootstrap. |
| Windows setup (PowerShell) | scripts/setup/windows/setup-windows.ps1 | ✅ | PowerShell script present. |
| WSL setup | scripts/setup/windows/setup-wsl.sh | ✅ | WSL bootstrap present. |
| VS Code setup | scripts/setup/setup-vscode.sh | ✅ | IDE setup. |
| Eclipse setup | scripts/setup/setup-eclipse.sh | ✅ | IDE setup. |
| Common setup utilities directory (legacy guide ref) | (setup/common/*) | ⚠️ | Superseded by `scripts/utils/cross-platform.sh`; guide updated. |

## Course / Domain Setup
| Domain | Script | Status | Notes |
|--------|--------|--------|-------|
| Databases | scripts/courses/setup-database.sh | ✅ | Installs PostgreSQL, MySQL/MariaDB, MongoDB, Redis + sample. |
| Machine Learning / Data Science | scripts/courses/setup-ml.sh | ✅ | Extensive ML/NLP/CV/GPU stack. |
| Mobile Development | scripts/courses/setup-mobile.sh | ✅ | Android, iOS (advisory), React Native, Flutter. |
| Systems Programming | scripts/courses/setup-systems.sh | ✅ | Compilers, debuggers, profilers, QEMU, sample C/CMake project. |
| Web Development | scripts/courses/setup-webdev.sh | ✅ | Full web stack; minor defect (pip install sqlite3). |
| Web Development | scripts/courses/setup-webdev.sh | ✅ | Full web stack; sqlite3 PyPI issue removed. |

## Quickstart Generators
| Language / Stack | Script | Status | Notes |
|------------------|--------|--------|-------|
| Python multi-archetype | scripts/quickstart/quickstart-python.sh | ✅ | API (FastAPI/Flask), CLI, ML, library, desktop, minimal. |
| Node.js multi-archetype (legacy fragile JSON note) | scripts/quickstart/quickstart-node.sh | ✅ | Refactored JSON creation (heredoc + optional jq). |
| Python pyproject-only option | scripts/quickstart/quickstart-python.sh | ✅ | User can skip legacy setup.py now. |
| Node.js multi-archetype | scripts/quickstart/quickstart-node.sh | ✅ | API, CLI, library, full-stack, minimal; JSON creation refactored. |
| Java (Maven/Gradle) | scripts/quickstart/quickstart-java.sh | ✅ | Basic scaffolds. |
| C++ (CMake + GTest) | scripts/quickstart/quickstart-cpp.sh | ✅ | Optional tests via FetchContent. |

## Tooling & Package Management
| Claim | Implementation | Status | Notes |
|-------|---------------|--------|-------|
| Python version management (pyenv) | Several scripts (env-manager, course setups) | ✅ | Used where relevant. |
| Node version management (nvm) | env-manager, webdev, node quickstart | ✅ | Present; detection fallback could be improved. |
| Java version management (SDKMAN) | env-manager, java quickstart | ✅ | Assumes sdk command exists. |
| Docker support | Mentioned in guide (various) | ✅ | Installed/checked in multiple scripts (needs centralization). |
| Database clients & GUIs | database setup script | ✅ | TablePlus/pgAdmin references; OS coverage varies. |

## Documentation Accuracy Summary (Updated)
- All previously missing utility and wrapper scripts now implemented.
- Shared helpers centralized in `scripts/utils/cross-platform.sh` instead of `setup/common` (guide references should be adjusted if still mentioning `setup/common`).
- Course and quickstart scripts aligned with README claims; earlier fragile Node JSON logic fixed.
- Web dev sqlite3 pip defect resolved; ML GPU detection enhanced; MySQL hardening added.

## Recommendations (Remaining)
1. Adjust any lingering guide references from hypothetical `setup/common` to `scripts/utils`.
2. Consider further distro mappings for MongoDB beyond implemented focal/jammy/noble & Mint mapping.
3. Diagnose JSON output implemented (`--json`); possible future: structured per-section files.
4. Added basic idempotency (MongoDB repo skip, archive tarball skip); extend to large language/framework installs.
5. Potential creation of a lightweight plugin system for course add-ons.

---
Generated automatically for current repository state.
