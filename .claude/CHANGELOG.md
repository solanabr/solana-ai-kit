# Changelog

All notable changes to solana-claude-config.

## [1.2.3] - 2026-03-31

### Changed
- Replaced Puppeteer MCP server with Playwright (`@playwright/mcp`) — actively maintained by Microsoft, Puppeteer MCP is unmaintained

## [1.2.1] - 2026-03-31

### Fixed
- `install.sh` nesting bug: installing into a directory with existing `.claude/` created `.claude/.claude/` instead of merging
- `install.sh` now preserves user files (`settings.json`, `mcp.json`, `MEMORY.md`) on reinstall instead of overwriting

### Added
- `test_install_existing_claude.sh` — verifies install into pre-existing `.claude/` directory (no nesting, user files preserved, upstream content installed)
- Enhanced `test_install_idempotent.sh` with nesting checks and user file preservation assertions

## [1.2.0] - 2026-03-31

### Added
- `test_settings_deep.sh` — deep validation of settings.json structure (env, sandbox, plugins, permissions, hooks, model defaults)
- `test_cross_references.sh` — Ripple Map enforcer: cross-validates agent/command/MCP counts and names across README, QUICK-START, and CLAUDE-solana.md
- `test_install_idempotent.sh` — verifies double-install safety (backups, no duplicates, preserved local files)
- `test_cleanup.sh` — simulates /cleanup command contract (scaffolding removal, config preservation)
- `test_resync.sh` — static analysis of resync.sh integrity and submodule state
- 5 new assertion helpers: `assert_file_not_exists`, `assert_dir_not_exists`, `assert_file_contains`, `assert_file_not_contains`, `assert_count`
- CI OS matrix: ubuntu-latest + macos-latest (fail-fast: false)
- CI smoke-test job: fresh install + agents-mode install validation
- CI badge in README.md

### Changed
- `test_update.sh` rewritten: 8 → 22 assertions (dry-run, upstream detection, protected files, agents mode)
- CI JSON validation switched from `jq` to `python3` for portability
- Total test assertions: ~195 → 340 across 14 suites (was 9)

## [1.1.0] - 2026-03-31

### Added
- `/cleanup` command for forked template users to initialize project and remove scaffolding
- `/resync` command (replaces `/update-skills`) for submodule resync with integrity verification
- `CLAUDE.local.md` — private, gitignored scratchpad for per-machine notes
- Self-learning tiered system: strict (tracked CLAUDE.md) + relaxed (private CLAUDE.local.md)
- Monorepo guidance: subdirectory CLAUDE.md auto lazy-loads
- `.claude/bin/resync.sh` — submodule resync script

### Changed
- `/upgrade` renamed to `/update` (`.claude/bin/upgrade.sh` → `.claude/bin/update.sh`)
- `VERSION` and `CHANGELOG.md` moved inside `.claude/` (no longer pollute project root)
- Root `update.sh` is now a thin deprecation wrapper → `.claude/bin/update.sh`
- Token Loading Model table updated with confirmed loading behaviors
- `install.sh` now creates `CLAUDE.local.md` and adds it to `.gitignore`
- `settings.json` env vars: added `BASH_MAX_OUTPUT_LENGTH`, `MAX_MCP_OUTPUT_TOKENS`

### Removed
- `/upgrade` command (replaced by `/update`)
- `/update-skills` command (replaced by `/resync`)
- `.claude/bin/upgrade.sh` (replaced by `.claude/bin/update.sh`)
- Root `VERSION` and `CHANGELOG.md` (moved to `.claude/`)

## [1.0.0] - 2026-03-31

### Added
- 15 specialized Solana agents (Anchor, Pinocchio, DeFi, Frontend, Mobile, Unity, etc.)
- 23 slash commands for building, testing, deploying, and auditing
- 9 external skill submodules (Solana Foundation, SendAI, Trail of Bits, Cloudflare, QEDGen, Colosseum, solana-mobile, solana-game, safe-solana-builder)
- Progressive-loading skill hub with protocol-specific routing
- 6 MCP server integrations (Helius, solana-dev, Context7, Puppeteer, context-mode, memsearch)
- Agent teams support via CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
- Dual install modes: full Claude Code + agents-only (Cursor/Windsurf/Copilot)
