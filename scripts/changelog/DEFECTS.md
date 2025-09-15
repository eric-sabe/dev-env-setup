# Script Defects & Improvement Opportunities

Severity: High (H), Medium (M), Low (L)

## Global / Cross-Cutting
| Issue | Affected Files | Severity | Notes / Recommendation |
|-------|----------------|----------|------------------------|
| Only `set -e` used (missing `-u -o pipefail -E`) | All bash scripts | H | Add `set -Eeuo pipefail` for robustness; ensure functions handle unset vars. |
| Duplicated platform detection & logging logic | Nearly all large scripts | M | Create `scripts/lib/common.sh` for detect_platform, color logging, require_root, command_exists. |
| Inconsistent quoting of variables in paths and globs | cleanup-dev.sh, restore-dev.sh, backup-dev.sh, course scripts | M | Quote variable expansions ("$VAR") to avoid word-splitting. |
| Potential unsafe `rm -rf` with broad globs | cleanup-dev.sh | H | Add safety: explicit path prefixes, optional `--dry-run`, confirmation, prune symlinks. |
| Missing stubs for referenced scripts (documentation drift) | Multiple (see COVERAGE_MATRIX) | H | Either implement minimal stubs or update docs. |
| Lack of `command -v` checks before using tools (pg_dump, mysql, mongodump, jq) | backup-dev.sh, restore-dev.sh, database/webdev setup | M | Guard operations; skip gracefully if absent. |
| Hard-coded linux distro cases not normalized (ubuntu/redhat/arch) repeated | Many installers | L | Centralize mapping. |
| Minimal error context (no trap with diagnostic) | All | M | Add `trap 'log_error "Failed at ${BASH_SOURCE[0]}:${LINENO}"' ERR`. |

## Specific Scripts
| Script | Issue | Severity | Recommendation |
|--------|-------|----------|----------------|
| backup-dev.sh | No check existence of backup directory tools, potential failure in db listing loops | M | Verify commands with `command -v`; skip and log warn. |
| backup-dev.sh | NPM global list used plain text tree; restore expects manual parsing | M | Also store JSON: `npm ls -g --depth=0 --json > npm_packages.json`. |
| cleanup-dev.sh | Aggressive `find` deletions could match unintended paths (e.g., `-name node_modules`) | H | Replace with `find "$HOME/dev" -type d -name node_modules -prune -exec rm -rf {} +`; add confirmation & dry run. |
| cleanup-dev.sh | No dry-run mode | M | Add `--dry-run` flag. |
| restore-dev.sh | Reinstallation of NPM packages not implemented robustly, parsing issues | M | Read from JSON file; use `jq -r '.dependencies | keys[]'` fallback. |
| restore-dev.sh | Database restore assumes service running & tools present | M | Add presence checks; conditional restore. |
| setup-webdev.sh | `pip install --user psycopg2-binary sqlite3` (sqlite3 not a PyPI package) | H | Remove `sqlite3`; optionally add `aiosqlite` for async usage. |
| setup-webdev.sh | Many global npm packages increases maintenance | L | Consider limiting or gating behind prompt/flag. |
| setup-ml.sh | CUDA/GPU install heuristics simplistic & potentially stale | M | Add detection + prompt; allow opt-in flag. |
| setup-mobile.sh | Flutter install path detection may duplicate installs | L | Check if `flutter` already in PATH. |
| setup-mobile.sh | iOS tooling placeholders (can't automate) not clearly separated | L | Add explicit notice section. |
| setup-database.sh | MySQL root operations not secured (no `mysql_secure_installation`) | M | Prompt user to run secure script or implement basic hardening. |
| setup-database.sh | MongoDB repo pinned single release (jammy) | M | Resolved: dynamic codename w/ fallback + idempotent repo add. |
| setup-systems.sh | Duplicate `set -e` mid-file (line ~489) | L | Remove duplicate. |
| env-manager.sh | Uses `jq` without ensuring installed | M | Add check & helpful message. |
| env-manager.sh | Some functions rely on external managers without guard (pyenv, nvm, sdk) | M | Add fallback messages. |
| health-check.sh | `set -e` may abort on first failing check reducing report completeness | M | Resolved: section wrapper aggregates failures without early exit. |
| quickstart-node.sh | Manual JSON manipulation fragile and sed -i differences macOS vs GNU | M | Use `jq` to modify package.json or build JSON into temp file then move. |
| quickstart-node.sh | No check for required tools (git, npm) early | L | Add preflight. |
| quickstart-python.sh | Uses legacy `setup.py` only (no pyproject.toml) | L | Resolved: pyproject.toml always generated; optional skip of legacy setup.py. |
| quickstart-python.sh | Potential multiple writes of large here-doc sections (performance minor) | L | Acceptable; no action. |
| quickstart-cpp.sh | Duplicate `set -e` appears (line ~414) | L | Remove. |
| All setup scripts | Mixed use of `pip` vs `pip3` | M | Standardize to `python3 -m pip`. |
| All setup scripts | Lack of idempotency checks (reinstalling packages each run) | L | Partially improved: MongoDB repo skip + archive tarball skip; broader package skip future. |

## Prioritized Fix List (Phase 1)
1. Safety & Correctness: strict mode, trap, sqlite3 removal, safer cleanup deletions, add command existence checks.
2. Data Integrity: add JSON export for npm packages; adjust restore logic accordingly.
3. Documentation Drift: add stub scripts or update docs (decision needed).
4. Portability: unify `pip` invocations; plan for `jq` optional.
5. Maintainability: create shared `common.sh` (phase 2 if time permits) and refactor duplicated platform logic incrementally.

## Notes
- Some improvements (creating many new stub scripts) may expand repo size; can alternatively update documentation quickly then implement stubs later.
- Phase 1 patches should avoid major structural refactors to reduce risk.

## Resolved Items (Current Status)
- Added `set -Eeuo pipefail` and traps to major scripts (macOS/Linux/WSL setup, course setups, quickstarts, management scripts).
- Introduced shared utilities `cross-platform.sh` eliminating duplicated color/log/platform logic in macOS, Linux, WSL, mobile, ML scripts.
- Implemented safer cleanup with dry-run & confirmations (`cleanup-dev.sh`).
- Added npm global package JSON export plus improved restore logic.
- Removed invalid `sqlite3` PyPI install from web dev setup.
- Standardized pip usage via `pip_install` helper where appropriate.
- Added stubs & utility scripts: diagnose, emergency recovery, performance tune, semester archive, platform cleanup wrappers.
- Refactored fragile manual JSON assembly in `quickstart-node.sh` to a single heredoc + optional jq normalization.
- Added MySQL hardening (interactive + automated) function invoked after installation in database setup.
- Added GPU detection and `--no-gpu` flag plus conditional TensorFlow/PyTorch installs in ML setup.
- Updated README with Security & GPU sections reflecting new capabilities.
- Coverage matrix updated to reflect new utility scripts and corrected prior missing entries.

## Pending / Future Opportunities (Updated)
- Extend idempotency: skip large framework installs (e.g., re-run detection for ML stacks, Flutter).
- Additional shellcheck-driven quote tightening in any newly added scripts.
- Per-section JSON output in `diagnose.sh` and richer structured health report export.
- Plugin-style architecture for course add-ons (reduce monolithic scripts).
- Automatic detection of Apple Silicon vs Intel for future ML optimizations.
