---
description: "Health check for the dev environment and solana-ai-kit config — read-only, with one exact fix-it command per failure"
---

You are running a health check on this project's toolchain and solana-ai-kit configuration. **Read-only contract: this command never writes, edits, or deletes files.** It only inspects and reports.

## Related Commands

- [setup-mcp.md](setup-mcp.md) — fix missing MCP API keys
- [update.md](update.md) — update config to latest upstream
- [resync.md](resync.md) — resync external skill submodules

## Check 1: Core Toolchain

```bash
node --version 2>/dev/null || echo "MISSING node"
npm --version 2>/dev/null || echo "MISSING npm"
claude --version 2>/dev/null || echo "MISSING claude CLI"
```

- ✓ `node` ≥ 18, `npm`, `claude` all present
- ✗ Missing → fix-it: `brew install node` / `npm install -g @anthropic-ai/claude-code`

## Check 2: Solana CLI + Cluster

```bash
solana --version 2>/dev/null || echo "MISSING solana CLI"
solana config get 2>/dev/null | grep "RPC URL"        # active cluster
solana balance --url devnet 2>/dev/null || echo "NO devnet balance / no keypair"
```

- ✓ CLI installed, cluster configured, devnet balance > 0
- ! Devnet balance 0 → fix-it: `solana airdrop 2 --url devnet`
- ! Cluster is mainnet during development → fix-it: `solana config set --url devnet`
- ✗ No CLI → fix-it: `sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"`

## Check 3: Rust / Anchor Toolchain

Only flag as ✗ if the project contains Rust programs (`Anchor.toml` or `programs/` present); otherwise report `-` (n/a).

```bash
rustc --version 2>/dev/null || echo "MISSING rustc"
cargo --version 2>/dev/null || echo "MISSING cargo"
anchor --version 2>/dev/null || echo "MISSING anchor"
avm --version 2>/dev/null || echo "MISSING avm"
```

- ✗ No rustc/cargo → fix-it: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- ✗ No anchor → fix-it: `cargo install --git https://github.com/coral-xyz/anchor avm --force && avm install latest && avm use latest`
- ! `anchor --version` ≠ `Anchor.toml` `anchor_version` → fix-it: `avm use <version>`

## Check 4: Git Submodules

```bash
git submodule status
```

- ✓ Every line starts with a SHA (space or `+` prefix)
- ✗ Any line with a `-` prefix = uninitialized submodule → fix-it: `git submodule update --init --recursive`
- ! `+` prefix = checked-out commit differs from recorded SHA → fix-it: `git submodule update --recursive` (or `/resync` if intentional)

## Check 5: Environment Keys

Compare key **names** between `.env.example` and `.env`. **NEVER print, echo, or display values — names only.**

```bash
# Key names present in example but absent in .env (presence check only)
comm -23 \
  <(grep -oE '^[A-Z_]+=' .env.example 2>/dev/null | sort -u) \
  <(grep -oE '^[A-Z_]+=' .env 2>/dev/null | sort -u)
# Keys present but left empty in .env
grep -E '^[A-Z_]+=$' .env 2>/dev/null | cut -d= -f1
```

- ✓ All `.env.example` keys exist in `.env` with non-empty values
- ! Key missing or empty → fix-it: `/setup-mcp` (for MCP keys) or edit `.env` manually
- ✗ No `.env` at all → fix-it: `cp .env.example .env` then `/setup-mcp`

## Check 6: Config Version vs Upstream

```bash
cat .claude/VERSION
git ls-remote --tags --sort=-v:refname https://github.com/solanabr/solana-ai-kit | head -3
```

- ✓ Local version matches latest upstream tag
- ! Behind upstream → fix-it: `bash .claude/bin/update.sh` (preview first: `bash .claude/bin/update.sh --dry-run`)
- ✗ No `.claude/VERSION` → config is corrupted or pre-1.0 → fix-it: `bash .claude/bin/update.sh`

## Check 7: MCP Configuration

```bash
python3 -c "import json; d=json.load(open('.mcp.json')); print('\n'.join(d.get('mcpServers', {}).keys()))" \
  2>/dev/null || echo "INVALID or missing .mcp.json"
# surfpool MCP requires the surfpool CLI binary on PATH (keyless, user-installed)
if grep -q '"surfpool"' .mcp.json 2>/dev/null; then
  surfpool --version 2>/dev/null || echo "MISSING surfpool CLI"
fi
```

- ✓ `.mcp.json` parses; expected servers listed (helius, solana-dev, context7, playwright, surfpool, ...)
- ✗ Parse failure → fix-it: `bash .claude/bin/update.sh` (restores stock `.mcp.json`)
- ! Server listed but its API key failed Check 5 → fix-it: `/setup-mcp`
- ! `.mcp.json` lists `surfpool` but the `surfpool` CLI is missing → fix-it: `curl -L https://surfpool.run/install | sh` (or `brew install txtx/taps/surfpool`)

## Check 8: Dual-Install Guard (plugin + full install)

solana-ai-kit ships two ways: the **plugin** (`/plugin install solana-ai-kit@solana-ai-kit`) and the **full install** (`install.sh` → project `.claude/`). Running both in one project double-loads commands, hooks, and MCP servers (e.g. `/deploy` and `/solana-ai-kit:deploy`, banner prints twice). Detect (names only, read-only):

```bash
# Plugin enabled at project scope? (user-scope lives in ~/.claude/settings.json)
PLUGIN_ON=$(grep -lE '"solana-ai-kit@[^"]*"[[:space:]]*:[[:space:]]*true' \
  .claude/settings.json "$HOME/.claude/settings.json" 2>/dev/null | head -1)
# Full install present?
[ -f .claude/VERSION ] && echo "FULL_INSTALL present"
[ -n "$PLUGIN_ON" ] && echo "PLUGIN enabled (in: $PLUGIN_ON)"
```

- ✓ Exactly one install path active (plugin **or** full install) → no conflict
- ✓ Neither detected here → n/a (`-`)
- ! BOTH the plugin (`enabledPlugins` has `solana-ai-kit`) AND a project `.claude/` full install are active → double commands/hooks/MCP → fix-it: pick one — either `/plugin uninstall solana-ai-kit` (keep the full install for rules/permissions/submodules) **or** remove the project `.claude/` and rely on the plugin (note: rules + permissions/sandbox + ext/ submodules then no longer apply)

## Output

Render exactly one summary table, then fix-its for non-✓ rows only:

```
## Doctor Report — <date>

| # | Check              | Status | Detail                          |
|---|--------------------|--------|---------------------------------|
| 1 | Core toolchain     | ✓      | node 22.x, npm 10.x, claude 2.x |
| 2 | Solana CLI         | !      | cluster=mainnet, devnet bal 0   |
| 3 | Rust/Anchor        | ✓      | anchor 1.0.2 = Anchor.toml      |
| 4 | Submodules         | ✗      | 2 uninitialized (-)             |
| 5 | .env keys          | !      | HELIUS_API_KEY empty            |
| 6 | Config version     | ✓      | 1.5.0 = upstream                |
| 7 | MCP config         | ✓      | 7 servers parsed                |
| 8 | Dual-install guard | ✓      | full install only (no plugin)   |

### Fix-its (run in order)
1. `git submodule update --init --recursive`
2. `/setup-mcp`
3. `solana airdrop 2 --url devnet`
```

Legend: ✓ healthy · ! degraded (works, but fix soon) · ✗ broken (blocks workflows) · - n/a.

## Guardrails

- Never write files — report only. If a fix-it would modify state, print it for the user to run.
- Never print `.env` values, keypair contents, or anything matching a secret pattern.
- Network access limited to read-only lookups (`git ls-remote`, `solana balance`). Never airdrop, deploy, or send transactions on the user's behalf.
- If a check errors unexpectedly, mark it `!` with the error one-liner — don't abort the remaining checks.
