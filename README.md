# Development Environment Setup Scripts

[![CI](https://github.com/eric-sabe/dev-env-setup/actions/workflows/ci.yml/badge.svg)](https://github.com/eric-sabe/dev-env-setup/actions/workflows/ci.yml) [![Markdown Lint](https://img.shields.io/badge/markdownlint-config-blue)](#)

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

### Course-Specific Setups

### Management Tools

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


## 🧰 Utilities Overview

Located in `scripts/utils` unless noted:


See `COVERAGE_MATRIX.md` for feature mapping and `DEFECTS.md` for improvement history. Recent additions: JSON diagnostics output, pyproject-only Python project option, dynamic MongoDB repo detection, idempotent semester archiving, resilient health check aggregation.

## 📦 Tools & Versions Matrix (Auto-Generated)

<!-- AUTOGEN:TOOLS_MATRIX:BEGIN -->

# Tools & Versions Matrix

### Python Package Groups

| Group | Package | Pin |
|-------|---------|-----|
| core | numpy | 1.26.* |
| core | pandas | 2.2.* |
| core | matplotlib | 3.8.* |
| core | seaborn | 0.13.* |
| core | scipy | 1.11.* |
| ml | torch | 2.2.* |
| ml | torchvision | 0.17.* |
| ml | torchaudio | 2.2.* |
| ml | scikit-learn | 1.4.* |
| ml | jupyter | 1.0.* |
| ml | jupyterlab | 4.1.* |
| ml | xgboost | 2.1.* |
| ml | lightgbm | 4.3.* |
| ml | catboost | 1.2.* |
| ml | imbalanced-learn | 0.12.* |
| ml | yellowbrick | 1.5.* |
| ml | optuna | 3.6.* |
| ml | hyperopt | 0.2.* |
| web | django | 5.0.* |
| web | djangorestframework | 3.15.* |
| web | flask | 3.0.* |
| web | fastapi | 0.112.* |
| web | uvicorn | 0.30.* |
| web | requests | 2.32.* |
| web | beautifulsoup4 | 4.12.* |
| web | selenium | 4.23.* |
| web | pytest | 8.3.* |
| db | psycopg2-binary | 2.9.* |
| db | aiosqlite | 0.20.* |
| db | pymysql | 1.1.* |
| db | pymongo | 4.8.* |
| db | redis | 5.0.* |
| viz | plotly | 5.22.* |
| viz | bokeh | 3.4.* |
| viz | altair | 5.2.* |
| viz | dash | 2.17.* |
| viz | panel | 1.4.* |
| viz | streamlit | 1.36.* |
| nlp | nltk | 3.9.* |
| nlp | spacy | 3.7.* |
| nlp | transformers | 4.43.* |
| nlp | datasets | 2.20.* |
| cv | opencv-python | 4.10.* |
| cv | Pillow | 10.3.* |
| cv | scikit-image | 0.23.* |

### Node Global Packages

| Package | Pin |
|---------|-----|
| typescript | 5.4.* |
| yarn | 1.22.* |
| pnpm | 8.15.* |
| create-react-app | 5.0.* |
| nodemon | 3.1.* |
| concurrently | 8.2.* |
| http-server | 14.1.* |
| live-server | 1.2.* |
| jest | 29.7.* |
| cypress | 13.13.* |
| playwright | 1.47.* |
| webpack | 5.92.* |
| webpack-cli | 5.1.* |
| parcel | 2.12.* |
| vite | 5.3.* |
| eslint | 8.57.* |
| prettier | 3.3.* |
| stylelint | 16.6.* |
| appium | 2.11.* |
| appium-doctor | 1.19.* |
| detox-cli | 0.0.* # update when stable pin decided |
| react-devtools | 5.0.* |

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

> Strict Mode: All source entries must now have a concrete SHA256; CI fails if any `sha256: TBD` remains. Use `lock-sources.sh --write` to populate hashes before pushing.
> Strict Mode: All source entries must have a concrete SHA256; CI fails if any `sha256: TBD` remains. Use `lock-sources.sh --write` to populate hashes. GPG key fingerprints are matched before repository addition (fail-fast if mismatch).

### Checksum Locking Workflow
1. Add new source entry in `manifests/versions.yaml` with `sha256: TBD`.
2. Run `scripts/security/lock-sources.sh` (dry-run prints updated manifest).
3. Commit updated manifest or use `--write` to apply in place.
4. CI `security-baseline` job reports missing hashes and shows strict preview.
5. After all hashes locked, enable strict gate by switching CI to `--strict` (future step).

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
