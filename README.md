# Solana Claude Configuration

[![CI](https://github.com/solanabr/solana-claude-config/actions/workflows/ci.yml/badge.svg)](https://github.com/solanabr/solana-claude-config/actions/workflows/ci.yml)

Production-ready Claude Code configuration for full-stack Solana development. Combines best practices from multiple sources into an agent-optimized, token-efficient config you can install and adapt to your specific project.

The idea here is to provide a generic CLAUDE.md that relies on subagents to plan and execute actions, dynamically loading markdown files, saving tokens and context in the end of the day. This config fully leverages the official Claude Code config recommendations:
- Rules are only loaded whenever specific file types are involved;
- SKILL.md is a mega hub to dynamically-disclosed skill files that are directly fetched from the best skill repos distributed across the ecosystem (Solana Foundation, Colosseum, Solana Mobile, SendAI, etc);
- Plus, its CLAUDE-solana.md is less than half the size of the usual CLAUDE.md, leaving space for its self improvements programmed into the agents, noting and learning from anti-patterns, errors, recurrency and more.

Current multi-agent workflow favors monorepos, so we use a single CLAUDE.md/config for the whole project while leveraging agents and context-specific skills to solve each step of builder flow.

If you installed manually, remember to rename ./CLAUDE-solana.md back to ./CLAUDE.md, as the current top-level CLAUDE.md file is focused on maintaining the repo itself.

## What This Is

A complete `.claude/` configuration that turns Claude into a Solana development expert with:

- **15 specialized agents** for different tasks (architecture, Anchor, Pinocchio, DeFi, tokens, frontend, mobile, backend, DevOps, QA, docs, games, Unity, learning, research)
- **24 workflow commands** for building, testing, deploying, profiling, migrating, and committing
- **6 MCP server integrations** for on-chain data (Helius), Solana docs (solana-dev), library docs (Context7), browser automation (Puppeteer), context optimization (context-mode), and persistent memory (memsearch)
- **Agent teams** for multi-step workflows (architect → engineer → QA)
- **Progressive skill loading** that only loads context when needed (saves tokens)
- **Auto-loading rules** that enforce best practices based on file patterns

## Quick Start

```bash
# Option 1: One-liner installer (Claude Code)
curl -fsSL https://raw.githubusercontent.com/solanabr/solana-claude-config/main/install.sh | bash

# Option 2: Agents + skills only (Cursor, Windsurf, Copilot, etc.)
curl -fsSL https://raw.githubusercontent.com/solanabr/solana-claude-config/main/install.sh | bash -s -- --agents

# Option 3: Manual setup
git clone --recurse-submodules https://github.com/solanabr/solana-claude-config.git
cp -r solana-claude-config/.claude /path/to/your-project/
cp solana-claude-config/CLAUDE-solana.md /path/to/your-project/CLAUDE.md
cd /path/to/your-project && git submodule update --init --recursive

# Start Claude Code
claude
```

### `--agents` Flag

Pass `--agents` to install everything into `.agents/` instead of `.claude/`. Same content, different directory name. Useful when `.claude/` is already taken or for non-Claude AI tools (Cursor, Windsurf, Copilot, etc.).

```bash
bash install.sh --agents /path/to/your-project
```

To update an `--agents` install:

```bash
# Run from your project root:
bash .agents/bin/update.sh
```

### MCP Setup (Optional)

After installation, configure MCP servers for enhanced capabilities:

```bash
# In your project with Claude Code running:
/setup-mcp
```

This guides you through API key configuration for Helius, Context7, and other MCP servers.

## Key Features

### Agent-Ready Architecture

Each agent loads its own specialized context on invocation:

```
"Use solana-architect to design the vault program"
"Use anchor-engineer to implement the deposit instruction"
"Use defi-engineer to integrate Jupiter swaps"
"Use solana-qa-engineer to write comprehensive tests"
```

Claude will spawn each specialized agent by itself based on context.

### Agent Teams

With `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` enabled, orchestrate multi-agent workflows:

```
"Create an agent team: solana-architect for design, anchor-engineer for implementation, solana-qa-engineer for testing"
```

Recommended team patterns:

| Pattern | Flow | Use Case |
|---------|------|----------|
| **program-ship** | architect → anchor/pinocchio → qa | Build program from spec to tested |
| **full-stack** | architect → anchor → frontend → qa | End-to-end feature |
| **audit-and-fix** | qa → trailofbits context → anchor | Audit and remediate |
| **game-ship** | game-architect → unity → qa | Game feature |
| **defi-compose** | researcher → defi-engineer → qa | DeFi integration |
| **token-launch** | token-engineer → frontend → qa | Token creation + launch UI |

### MCP Server Integrations

Pre-configured MCP servers in `.claude/mcp.json` (API keys go in `.env`):

| Server | Capabilities |
|--------|-------------|
| **Helius** | 60+ tools: RPC, DAS API, webhooks, priority fees, token metadata, NFT data |
| **solana-dev** | Solana Foundation official MCP — Solana docs, guides, and API references |
| **Context7** | Up-to-date library documentation lookup |
| **Puppeteer** | Browser automation for dApp testing and visual verification |
| **context-mode** | Context window optimization — compresses large RPC responses, build logs, and code analysis |
| **memsearch** | Persistent AI memory across sessions — auto-captures summaries, semantic search, git-friendly storage |

### Token-Efficient Design

- CLAUDE.md is delivered as a user message (not system prompt) — shorter = better adherence
- Skills load progressively (not all at once)
- Agents reference skills instead of duplicating content
- Path-scoped rules lazy-load on file read (zero startup cost)
- `CLAUDE.local.md` for private scratch notes (gitignored, never shared)
- Subdirectory CLAUDE.md files lazy-load in monorepos
- Decision frameworks live in agents, not global context

### Modern Stack (2026)

| Layer | Stack |
|-------|-------|
| Programs | Anchor 0.31+, Pinocchio, Rust 1.82+ |
| Token Extensions | Token-2022 (transfer hooks, confidential transfers, metadata) |
| Testing | Mollusk, LiteSVM, Surfpool, Trident |
| Frontend | @solana/kit, Next.js 15, React 19 |
| Mobile | React Native, Expo, Mobile Wallet Adapter |
| Backend | Axum 0.8+, Tokio 1.40+, sqlx |
| Unity Games | Solana.Unity-SDK, .NET 9, C# 13 |
| PlaySolana | PSG1 console, PlayDex, SvalGuard |
| DeFi | Jupiter, Drift, Kamino, Raydium, Orca, Meteora |
| Infrastructure | Cloudflare Workers, GitHub Actions, Docker |

## Repository Structure

```
.
├── CLAUDE.md                    # Main hub - Claude reads this first
├── CLAUDE.local.md              # Private notes (gitignored)
├── README.md                    # This file
├── install.sh                   # One-liner installer
├── update.sh                    # Deprecation wrapper → .claude/bin/update.sh
├── validate.sh                  # Config integrity checker
├── LICENSE                      # MIT
├── tests/                       # Config integrity test suite
├── .github/workflows/
│   ├── ci.yml                       # PR validation
│   └── claude-code.yml              # Claude Code action template
└── .claude/
    ├── VERSION                  # Semver version (e.g. 1.1.0)
    ├── CHANGELOG.md             # Release notes
    ├── agents/                  # 15 specialized agents
    ├── bin/
    │   ├── update.sh                # In-place update from upstream
    │   └── resync.sh                # Submodule resync script
    ├── commands/                # 24 workflow commands
    ├── skills/                  # Progressive-loading knowledge
    │   ├── SKILL.md                 # Unified hub routing to all skills
    │   ├── ext/                     # External skill submodules
    │   │   ├── solana-dev/              # Solana Foundation dev skill (core)
    │   │   ├── sendai/                  # SendAI protocol skills (DeFi)
    │   │   ├── solana-game/             # Solana game skill (Unity, PSG1)
    │   │   ├── cloudflare/              # Cloudflare Workers, Agents SDK
    │   │   ├── trailofbits/             # Trail of Bits security skills
    │   │   ├── qedgen/                # QEDGen formal verification (Lean 4)
    │   │   ├── solana-mobile/           # Mobile Wallet Adapter, Genesis Token
    │   │   ├── colosseum/              # Colosseum Copilot (startup research)
    │   │   └── safe-solana-builder/   # Security-first code generation
    │   ├── token-2022.md            # Token Extensions guide (local)
    │   ├── backend-async.md         # Axum/Tokio patterns (local)
    │   └── deployment.md            # Deployment workflows (local)
    ├── mcp.json                 # MCP server configurations
    ├── rules/                   # Auto-loading constraints
    └── settings.json            # Permissions, hooks, agent teams
```

## Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| **solana-architect** | System design, PDA schemes, token economics, multi-program architecture | Opus |
| **anchor-engineer** | Anchor development, IDL generation, account constraints | Opus |
| **pinocchio-engineer** | CU optimization (80-95% savings), zero-copy, minimal binary | Opus |
| **defi-engineer** | DeFi integrations: Jupiter, Drift, Kamino, Raydium, Orca, Meteora | Opus |
| **token-engineer** | Token-2022 extensions, token economics, launch mechanics | Opus |
| **solana-frontend-engineer** | React/Next.js, wallet UX, transaction flows, accessibility | Opus |
| **mobile-engineer** | React Native/Expo, mobile wallet adapter, deep linking | Sonnet |
| **rust-backend-engineer** | Axum APIs, indexers, WebSocket services | Opus |
| **devops-engineer** | CI/CD, monitoring, RPC infrastructure, Cloudflare Workers | Sonnet |
| **solana-qa-engineer** | Testing (Mollusk/LiteSVM/Trident), CU profiling, code quality | Opus |
| **tech-docs-writer** | READMEs, API docs, integration guides | Sonnet |
| **game-architect** | Solana game design, Unity architecture, on-chain game state, PlaySolana | Opus |
| **unity-engineer** | Unity/C# implementation, Solana.Unity-SDK, wallet integration, NFT display | Sonnet |
| **solana-guide** | Learning, tutorials, concept explanations, progressive learning paths | Sonnet |
| **solana-researcher** | Ecosystem research, protocol investigation, SDK analysis | Sonnet |

## Commands

### Building
| Command | Purpose |
|---------|---------|
| `/build-program` | Build Anchor or native Solana program |
| `/build-app` | Build Next.js/Vite web client |
| `/build-unity` | Build Unity project (WebGL, Desktop, PSG1) |
| `/scaffold` | Generate project scaffolding (program + frontend + tests + CI) |

### Testing & Quality
| Command | Purpose |
|---------|---------|
| `/test-rust` | Run Mollusk, LiteSVM, Surfpool, Trident tests |
| `/test-ts` | Run TypeScript tests (Anchor, Vitest, Playwright) |
| `/test-dotnet` | Run .NET/C# tests (Unity Test Framework, NUnit) |
| `/test-and-fix` | Run tests and auto-fix common issues |
| `/audit-solana` | Comprehensive security audit |
| `/diff-review` | AI-powered diff review for Solana-specific issues |
| `/profile-cu` | CU profiling per instruction with optimization suggestions |
| `/benchmark` | CU benchmarks with before/after comparison |

### Deployment & Migration
| Command | Purpose |
|---------|---------|
| `/deploy` | Deploy to devnet (always first) or mainnet |
| `/migrate-web3` | Migrate from @solana/web3.js to @solana/kit |
| `/generate-idl-client` | Generate typed clients from IDL (Codama/Shank) |

### Workflow & Setup
| Command | Purpose |
|---------|---------|
| `/quick-commit` | Create branch, format, lint, conventional commit |
| `/setup-ci-cd` | Configure GitHub Actions pipeline |
| `/setup-mcp` | Configure MCP server API keys and connections |
| `/resync` | Resync external skill submodules to latest |
| `/write-docs` | Generate documentation for programs, APIs, components |
| `/explain-code` | Explain complex code with visual diagrams |
| `/plan-feature` | Plan feature implementation with specifications |
| `/update` | Update config to latest version from upstream |
| `/cleanup` | Initialize forked template — setup CLAUDE.md, remove scaffolding |

## DX Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | One-liner installer: copies config to your project (`--agents` for non-Claude tools) |
| `update.sh` | Deprecation wrapper → `.claude/bin/update.sh` |
| `validate.sh` | Validates all config integrity (agents, commands, skills, settings, versioning) |
| `tests/run_all.sh` | Runs full test suite for config validation |

## GitHub Action for Team Collaboration

This config includes a pre-built GitHub Action (`.github/workflows/claude-code.yml`) for PR-based iteration:

1. Add `ANTHROPIC_API_KEY` to your repository secrets
2. Copy `.github/workflows/claude-code.yml` to your project
3. Team members can `@claude` in PR comments
4. Claude responds with code suggestions using this configuration

## External Skill Submodules

| Submodule | Source | Purpose |
|-----------|--------|---------|
| `ext/solana-dev` | [solana-foundation/solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill) | Core Solana development (programs, frontend, testing, security) |
| `ext/sendai` | [sendaifun/skills](https://github.com/sendaifun/skills) | DeFi protocol integrations (Jupiter, Drift, Raydium, etc.) |
| `ext/solana-game` | [solanabr/solana-game-skill](https://github.com/solanabr/solana-game-skill) | Game development (Unity, PlaySolana, PSG1) |
| `ext/cloudflare` | [cloudflare/skills](https://github.com/cloudflare/skills) | Infrastructure (Workers, Agents SDK, MCP servers) |
| `ext/trailofbits` | [trailofbits/skills](https://github.com/trailofbits/skills) | Security auditing and vulnerability scanning |
| `ext/qedgen` | [QEDGen/solana-skills](https://github.com/QEDGen/solana-skills) | Formal verification with Lean 4 theorem proving |
| `ext/solana-mobile` | [nicoorfi/solana-mobile](https://github.com/nicoorfi/solana-mobile) | Mobile Wallet Adapter, Genesis Token, SKR address resolution |
| `ext/colosseum` | [ColosseumOrg/colosseum-copilot](https://github.com/ColosseumOrg/colosseum-copilot) | Startup research, idea validation, hackathon projects (proprietary license) |
| `ext/safe-solana-builder` | [frankcastleauditor/safe-solana-builder](https://github.com/frankcastleauditor/safe-solana-builder) | Security-first code generation (70+ audit-derived rules) |

## Branch Workflow

All new work starts on a feature branch:

```bash
# Format: <type>/<scope>-<description>-<DD-MM-YYYY>
git checkout -b feat/program-vault-15-01-2026
git checkout -b fix/frontend-auth-15-01-2026
```

Use `/quick-commit` to automate branch creation and commits.

## Code Quality

Before merging, run `/diff-review` or check diff against main:

```bash
git diff main...HEAD
```

Remove: excessive comments, abnormal try/catch blocks, verbose errors, redundant validation.

Keep: legitimate security checks, non-obvious explanations, matching error patterns.

## Using as a GitHub Template

1. Click "Use this template" on GitHub (or fork the repo)
2. Clone your new repo
3. Run Claude Code and use `/cleanup` — this copies `CLAUDE-solana.md` → `CLAUDE.md` and removes config repo scaffolding (tests, install scripts, docs)
4. Start building!

For monorepos, add a `CLAUDE.md` to each package/module with architecture decisions scoped to that directory. Claude Code automatically loads these when working in that subdirectory.

## Updating

```bash
# Preferred: use /update in Claude Code, or run directly:
bash .claude/bin/update.sh

# Preview changes without applying:
bash .claude/bin/update.sh --dry-run

# Resync skill submodules only:
bash .claude/bin/resync.sh

# Or manually update submodules
git submodule update --remote --merge
```

## Credits

This project builds on excellent work from the community:

- **[solana-foundation/solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill)** - The Solana Foundation's comprehensive skill set for Solana development, included as the primary submodule.

- **[sendaifun/skills](https://github.com/sendaifun/skills)** - SendAI's protocol-specific skills for DeFi integrations.

- **[solanabr/solana-game-skill](https://github.com/solanabr/solana-game-skill)** - Game development skills for Unity and PlaySolana.

- **[trailofbits/skills](https://github.com/trailofbits/skills)** - Trail of Bits security auditing skills.

- **[cloudflare/skills](https://github.com/cloudflare/skills)** - Cloudflare infrastructure skills.

- **[QEDGen/solana-skills](https://github.com/QEDGen/solana-skills)** - Formal verification for Solana programs using Lean 4 theorem proving.

- **[ColosseumOrg/colosseum-copilot](https://github.com/ColosseumOrg/colosseum-copilot)** - Solana startup research, idea validation, and hackathon project discovery from Colosseum. Proprietary license (Copyright Colosseum).

- **[0xquinto/bcherny-claude](https://github.com/0xquinto/bcherny-claude)** - Compiled Boris Cherny's (creator of Claude Code at Anthropic) best practices including verification loops, parallel Claude sessions, and CLAUDE.md patterns.

- **[builderz-labs/solana-claude-md](https://github.com/builderz-labs/solana-claude-md)** - Provided starter inspiration for Solana-specific Claude configuration.

## License

MIT - See [LICENSE](LICENSE)
