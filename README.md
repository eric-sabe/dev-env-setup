# Development Environment Setup Scripts

[![CI](https://github.com/eric-sabe/dev-env-setup/actions/workflows/ci.yml/badge.svg)](https://github.com/eric-sabe/dev-env-setup/actions/workflows/ci.yml) [![Markdown Lint](https://img.shields.io/badge/markdownlint-config-blue)](#)

A comprehensive collection of scripts to set up and manage development environments for college computer science students across macOS, Linux, and Windows platforms.

## 🚀 Quick Start

**First, ensure Git is installed:**

- macOS: `xcode-select --install` (then `git --version`)
- Ubuntu/Debian: `sudo apt update && sudo apt install -y git`
- Fedora: `sudo dnf install -y git`
- Windows: Install "Git for Windows" from https://git-scm.com/download/win, then restart PowerShell/Terminal.

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
   - **macOS**: `./scripts/setup/macos/setup-mac.sh`
   - **Linux**: `./scripts/setup/linux/setup-linux.sh`
   - **Windows**: `./scripts/setup/windows/setup-windows.ps1` then `./scripts/setup/windows/setup-wsl.sh`

4. **Create your first project**:
   - **Python**: `./scripts/quickstart/quickstart-python.sh`
   - **Node.js**: `./scripts/quickstart/quickstart-node.sh`

5. **Start coding!**

## ✅ What You Get

### Complete Development Environment

### Course-Specific Setups

### Management Tools

## 🛠️ Key Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup/macos/setup-mac.sh` | Complete macOS development setup |
| `scripts/setup/linux/setup-linux.sh` | Complete Linux development setup |
| `scripts/quickstart/quickstart-python.sh` | Interactive Python project generator |
| `scripts/quickstart/quickstart-node.sh` | Interactive Node.js project generator |
| `scripts/management/env-manager.sh` | Environment management tool |
| `scripts/management/health-check.sh` | System health diagnostics |
| `scripts/courses/setup-database.sh` | Database course setup |
| `scripts/utils/diagnose.sh` | Aggregate diagnostics snapshot (add `--json` for machine-readable) |
| `scripts/utils/emergency-recovery.sh` | Last-resort recovery helpers |
| `scripts/utils/performance-tune.sh` | Performance snapshot suggestions |
| `scripts/utils/semester-archive.sh` | Archive semester projects |
| `scripts/setup/macos/cleanup-mac.sh` | macOS targeted cleanup wrapper |
| `scripts/setup/linux/cleanup-linux.sh` | Linux targeted cleanup wrapper |
| `scripts/setup/windows/cleanup-wsl.sh` | WSL targeted cleanup wrapper |
| `scripts/validate.sh` | Static analysis runner (shellcheck) |

## 📖 Documentation

## 🧪 Platform Features (Experimental)
The following components are early-stage and may change or be removed while we refocus on core student setup workflows:

- Archive integrity verification (`scripts/security/verify-archives.sh`) – now outputs JSON (`--output-json`) for CI; schema may evolve.
- Prefetch/offline cache (`scripts/cache/prefetch.sh`, `scripts/utils/offline.sh`) – experimental; not yet wired into course scripts broadly.
- Operation ledger (`scripts/state/ledger.sh`) – append-only audit chain; format may change.
- Rollback stub (`scripts/state/rollback.sh`) – limited uninstall support (npm globals, pip groups) – interface unstable.
- Structured logging (`scripts/utils/log-json.sh`) – initial schema for future metrics.

See `changelog/nextlevel.md` “Scope Stabilization” section for the short list of wrap‑up tasks before advanced phases resume. Treat these as optional; they are not required for normal student usage.


## 🧰 Utilities Overview

Located in `scripts/utils` unless noted:


See `COVERAGE_MATRIX.md` for feature mapping and `DEFECTS.md` for improvement history. Recent additions: JSON diagnostics output, pyproject-only Python project option, dynamic MongoDB repo detection, idempotent semester archiving, resilient health check aggregation.

## 📦 Tools & Versions Matrix (Auto-Generated)

<!-- AUTOGEN:TOOLS_MATRIX:BEGIN -->

# Tools & Versions Matrix

### Python Package Groups

| Group | Package | Pin |
|-------|---------|-----|

### Node Global Packages

| Package | Pin |
|---------|-----|

### Profiles

| Profile | Python Groups | Node Globals |
|---------|---------------|--------------|
| minimal | core | typescript |
| full | core,ml,viz | typescript,yarn,pnpm,create-react-app,'@vue/cli','@angular/cli',nodemon,concurrently,http-server,live-server,jest,cypress,playwright,webpack,webpack-cli,parcel,vite,eslint,prettier,stylelint |

<!-- AUTOGEN:TOOLS_MATRIX:END -->

## ✅ Post-Install Verification

Each major course setup script (`setup-database.sh`, `setup-ml.sh`, `setup-webdev.sh`, `setup-systems.sh`, `setup-mobile.sh`) now performs a standardized verification pass at the end using `scripts/utils/verify.sh`.

What it checks (context-aware, non-fatal where appropriate):

Summary output reports PASS / FAIL counts at the end of each script. Failures do not always abort; they highlight gaps students can fix immediately.

Run a script again after manual fixes—idempotent guards skip already-installed components while re-verifying.

## 🔐 Security & Hardening

Recent hardening & quality improvements:

> Strict Mode Policy (v1.0):
> - Archives (manifests.archives) must have concrete `sha256` and `content_length`. CI fails if any are missing.
> - Sources that refer to package managers (type: pypi, npm) are informational and excluded from strict checksum enforcement.
> - For non package-manager sources that point to concrete artifacts, a `sha256` is required.
> - GPG key fingerprints are matched before repository addition (fail-fast on mismatch).

### Checksum Locking Workflow
1. Add new entry in `manifests/versions.yaml` with `sha256: TBD`.
2. Run `scripts/security/lock-sources.sh` (dry-run prints updated manifest). For archives, this will compute and fill hashes; package-manager entries are skipped.
3. Commit updated manifest or use `--write` to apply in place.
4. CI `security-baseline` job enforces strict mode for archives and non package-manager sources.
5. Keep hashes current when bumping versions; use archive verify workflows to catch upstream drift.

`generate-sbom.sh` now emits CycloneDX style component list derived from the manifest (Python + Node globals).

Recommended manual follow-ups (not automated):

## 🖥️ GPU / ML Setup

`setup-ml.sh` auto-detects NVIDIA GPUs (`nvidia-smi`) and installs GPU variants of TensorFlow / PyTorch when present. Use `--no-gpu` to force CPU-only installs:
```
./scripts/courses/setup-ml.sh --no-gpu
```
CUDA / cuDNN installation steps remain partially manual on some distros (RHEL/CentOS, macOS). The script logs guidance without failing if unsupported.

## 🎓 For Students

This toolkit is designed specifically for computer science students to:

## 🤝 Contributing

We welcome contributions! See our [contributing guidelines](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.


**Happy coding! 🎉**

*Review scripts before running with administrative privileges. These tools are provided for educational purposes.*

### Archive Integrity Verification

We track external Eclipse distributions (multi-OS / arch, Java & JEE flavors) inside `manifests/versions.yaml` with both `sha256` and `content_length`.

Scripts:
* `scripts/security/collect-content-lengths.sh` – probe and list current Content-Length values.
* `scripts/security/verify-archives.sh` – quick (HEAD only) or full (download + hash) verification.
* `scripts/tools/update-eclipse-release.sh` – bump Eclipse release, reset hashes/sizes for re-lock.

Usage examples:
```
# Quick (size/header) verify all eclipse entries
bash scripts/security/verify-archives.sh --quick --filter eclipse

# Full verify (downloads + hash) – use sparingly / CI manual dispatch
bash scripts/security/verify-archives.sh --filter eclipse

# Bump release (dry-run) from 2025-09 to 2025-12
bash scripts/tools/update-eclipse-release.sh 2025-09 2025-12

# Write changes in-place
bash scripts/tools/update-eclipse-release.sh 2025-09 2025-12 --write
```

### CI

GitHub Actions workflow: `.github/workflows/verify-archives.yml`
* On push / PR: runs quick verification (no full downloads) for `eclipse-*` archives.
* Manual dispatch (`workflow_dispatch` with `full=true`): performs full download + hash verification.

Exit codes: build fails on mismatched size or hash, guarding against silent upstream changes or HTML error pages.

### Phase 4: State & Offline (Early)

State tracking, rollback prototypes, and offline reproducibility layer are being introduced:

Components:
* `scripts/state/ledger.sh` – append-only JSONL ledger with hash-chained integrity (`record` / `verify`).
* `scripts/state/rollback.sh` – preliminary uninstall (npm globals, pip user packages) with safe dry-run design planned.
* `scripts/utils/offline.sh` – `fetch_with_cache` + `OFFLINE_MODE=1` gating for networkless replays.
* `scripts/cache/prefetch.sh` – pre-download (currently Eclipse archives) into `cache/` by hash.

Ledger usage:
```
# Record an action
bash scripts/state/ledger.sh record --action install_python --component numpy --status ok --duration-ms 3120

# Verify chain integrity
bash scripts/state/ledger.sh verify
```

Prefetch + offline verify:
```
# Populate cache (downloads if missing)
bash scripts/cache/prefetch.sh --filter eclipse

# Run quick verification without network
OFFLINE_MODE=1 bash scripts/security/verify-archives.sh --quick --filter eclipse
```

Conventions:
* Ledger file: `state/ledger.jsonl` (ignored by git).
* Head hash: `state/ledger.head` (verifies tamper-free chain).
* Cache dir: `cache/` (ignored). Future: embed manifest fingerprint to detect stale artifacts.

Planned next (short-term): extend rollback targets (brew leaves, apt groups), generic prefetch manifest walker, parallel size probe in verification, and manifest hash embedding for cache coherency.
