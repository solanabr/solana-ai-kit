---
description: Initialize forked template — setup CLAUDE.md and remove config repo scaffolding
model: sonnet
---

Initialize a forked solana-ai-kit template for use as a project. Sets up CLAUDE.md and removes config repo scaffolding files.

## Step 1: Setup CLAUDE.md

If `CLAUDE.md` doesn't exist (or contains "Meta Configuration" indicating it's the repo maintainer version):
1. Copy `CLAUDE-solana.md` → `CLAUDE.md`
2. Create starter `CLAUDE.local.md` (gitignored, private notes) if it doesn't exist
3. Add `CLAUDE.local.md` to `.gitignore` if not present

If `CLAUDE.md` already exists and looks like a project config (not meta), skip this step.

## Step 2: Create .env if missing

If `.env` doesn't exist but `.env.example` does, copy `.env.example` → `.env` before removing .env.example.

## Step 3: Remove scaffolding

Files/dirs that exist only for maintaining or distributing the config repo itself. These ship in a full clone/fork of solana-ai-kit but have no purpose in a downstream project. Remove each **only if present** — never error on a missing path.

**Remove (if they exist):**

Maintenance scaffolding:
- `install.sh` — installer (not needed after fork)
- `update.sh` — deprecation wrapper
- `validate.sh` — config repo validation
- `tests/` — config repo test suite
- `CLAUDE-solana.md` — source template (now copied as CLAUDE.md)
- `QUICK-START.md` — config repo docs
- `README.md` — config repo readme (user should write their own)
- `.claude/CHANGELOG.md` — the kit's changelog (not the user's project changelog)
- `.github/workflows/ci.yml` — config repo CI (keep `.github/templates/claude-code.yml` if present)
- `.env.example` — should already be copied to .env

Distribution infra (Claude Code plugin marketplace + Vercel install endpoint — only relevant when *publishing* the kit):
- `.claude-plugin/` — in-repo plugin marketplace manifest
- `plugin/` — symlinked core-plugin subtree
- `vercel.json` — install-endpoint redirect config

**Preserve (never touch):**
- `.claude/` — entire directory (agents, commands, skills, rules, settings, mcp, `bin/` self-update tooling) — except `.claude/CHANGELOG.md` noted above
- `CLAUDE.md` — just created/preserved above
- `CLAUDE.local.md` — private notes
- `.mcp.json` — MCP server config (user wants this)
- `.env`, `.env.example` (after .env exists) — config
- `.gitmodules` — submodule definitions
- `.gitignore` — ignore rules
- `LICENSE` — keep unless user wants to change
- Any user-created files

If you encounter a file that looks repo-specific but isn't listed above, flag it to the user rather than removing it.

## Step 4: Confirm and execute

1. Show the user exactly what will happen (CLAUDE.md setup + files to remove)
2. Wait for user confirmation before proceeding
3. Execute the removals
4. Print summary of what was done
5. Suggest: `git add -A && git commit -m "chore: initialize project from solana-ai-kit template"`
