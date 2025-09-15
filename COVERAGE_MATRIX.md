# Coverage Matrix

This document maps claims in README and guide to actual scripts present in the repository and identifies gaps.

Legend: Present ✅  Missing ❌  Partial (exists but incomplete) ⚠️

## Core Environment & Maintenance
| Claim (README / Guide) | Script Path | Status | Notes |
|------------------------|-------------|--------|-------|
| Backup development environment | scripts/backup-dev.sh | ✅ | Covers projects, configs, packages, DBs; extensible. |
| Restore development environment | scripts/restore-dev.sh | ✅ | Recreates from backup directory or archive. |
| Cleanup (generic) | scripts/cleanup-dev.sh | ✅ | Multi‑option interactive cleanup. |
| Platform-specific cleanup: macOS | (referenced: setup/macos/cleanup-mac.sh) | ❌ | Not present. |
| Platform-specific cleanup: Linux | (referenced: cleanup-linux.sh) | ❌ | Not present. |
| Platform-specific cleanup: WSL | (referenced: cleanup-wsl.sh) | ❌ | Not present. |
| Emergency recovery script | (referenced: utils/emergency-recovery.sh) | ❌ | Not present. |
| Performance tuning script | (referenced: utils/performance-tune.sh) | ❌ | Not present. |
| Cross-platform shared utilities | (referenced: utils/cross-platform.sh) | ❌ | Not present (logic duplicated inside scripts). |
| Diagnose / troubleshooting script | (referenced: diagnose.sh) | ❌ | Not present; health-check partially overlaps. |
| Health check / environment diagnostics | scripts/management/health-check.sh | ✅ | Provides extensive system & tool checks. |
| Environment manager (interactive) | scripts/management/env-manager.sh | ✅ | Menus for Python/Node/Java + maintenance. |
| Semester/archive automation | (referenced) | ❌ | Not present. |

## Platform Setup
| Claim | Script | Status | Notes |
|-------|--------|--------|-------|
| macOS setup | scripts/setup/macos/setup-mac.sh | ✅ | Performs macOS bootstrap. |
| Linux setup | scripts/setup/linux/setup-linux.sh | ✅ | Performs Linux bootstrap. |
| Windows setup (PowerShell) | scripts/setup/windows/setup-windows.ps1 | ✅ | PowerShell script present. |
| WSL setup | scripts/setup/windows/setup-wsl.sh | ✅ | WSL bootstrap present. |
| VS Code setup | scripts/setup/setup-vscode.sh | ✅ | IDE setup. |
| Eclipse setup | scripts/setup/setup-eclipse.sh | ✅ | IDE setup. |
| Common setup utilities directory (guide references setup/common) | (setup/common/*) | ❌ | Directory not present; logic inline per OS. |

## Course / Domain Setup
| Domain | Script | Status | Notes |
|--------|--------|--------|-------|
| Databases | scripts/courses/setup-database.sh | ✅ | Installs PostgreSQL, MySQL/MariaDB, MongoDB, Redis + sample. |
| Machine Learning / Data Science | scripts/courses/setup-ml.sh | ✅ | Extensive ML/NLP/CV/GPU stack. |
| Mobile Development | scripts/courses/setup-mobile.sh | ✅ | Android, iOS (advisory), React Native, Flutter. |
| Systems Programming | scripts/courses/setup-systems.sh | ✅ | Compilers, debuggers, profilers, QEMU, sample C/CMake project. |
| Web Development | scripts/courses/setup-webdev.sh | ✅ | Full web stack; minor defect (pip install sqlite3). |

## Quickstart Generators
| Language / Stack | Script | Status | Notes |
|------------------|--------|--------|-------|
| Python multi-archetype | scripts/quickstart/quickstart-python.sh | ✅ | API (FastAPI/Flask), CLI, ML, library, desktop, minimal. |
| Node.js multi-archetype | scripts/quickstart/quickstart-node.sh | ✅ | API, CLI, library, full-stack, minimal; JSON building fragile. |
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

## Documentation Accuracy Summary
- Primary functional scripts for backup/restore, management, course setups, and quickstarts all exist (core coverage strong).
- Missing all utility and platform-specific cleanup scripts referenced multiple times in guide.md.
- Missing setup/common directory referenced conceptually for shared helpers.
- Missing diagnose/emergency/performance/semeseter-archive scripts.

## Recommendations
1. Either create stub implementations for missing referenced scripts (preferred for forward compatibility) or revise guide.md and README to remove/adjust references.
2. Introduce a shared `scripts/lib/common.sh` (or utils/) to consolidate logging, platform detection, safety flags.
3. Add explicit coverage note in README linking to this matrix file.

---
Generated automatically for current repository state.
