# Solana AI Kit

[![CI](https://github.com/solanabr/solana-ai-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/solanabr/solana-ai-kit/actions/workflows/ci.yml)
![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/github/license/solanabr/solana-ai-kit)
![Solana](https://img.shields.io/badge/Solana-black?logo=solana)
![Claude Code](https://img.shields.io/badge/Claude_Code-powered-orange)

Production-ready Claude Code configuration for full-stack Solana development. Combines best practices from multiple sources into an agent-optimized, token-efficient config you can install and adapt to your specific project.

The idea here is to provide a generic CLAUDE.md that relies on subagents to plan and execute actions, dynamically loading markdown files, saving tokens and context in the end of the day. This config fully leverages the official Claude Code config recommendations:
- Rules are only loaded whenever specific file types are involved;
- SKILL.md is a mega hub to dynamically-disclosed skill files that are directly fetched from the best skill repos distributed across the ecosystem (Solana Foundation, Colosseum, Solana Mobile, SendAI, etc);
- Plus, its CLAUDE-solana.md is than half the size of the usual CLAUDE.md, leaving space for its self improvements programmed into the agents, noting and learning from anti-patterns, errors, recurrency and more. For less important notes, CLAUDE.local.md is constantly maintained by agents as well and, on monorepos, per-folder CLAUDE.md is also maintained.

Current multi-agent workflow favors monorepos, so we use a single CLAUDE.md/config for the whole project while leveraging agents and context-specific skills to solve each step of builder flow.

If you installed manually, remember to rename ./CLAUDE-solana.md back to ./CLAUDE.md, as the current top-level CLAUDE.md file is focused on maintaining the repo itself.

## What This Is

A complete `.claude/` configuration that turns Claude into a Solana development expert with:

- **15 specialized agents** for different tasks (architecture, Anchor, Pinocchio, DeFi, tokens, frontend, mobile, backend, DevOps, QA, docs, games, Unity, learning, research)
- **29 workflow commands** for building, testing, deploying, profiling, migrating, and committing
- **7 MCP server integrations** for on-chain data (Helius), Solana docs (solana-dev), library docs (Context7), browser automation (Playwright), context optimization (context-mode), persistent memory (memsearch), and local-validator / mainnet-fork control (Surfpool)
- **Agent teams** for multi-step workflows (architect → engineer → QA)
- **Progressive skill loading** that only loads context when needed (saves tokens)
- **Auto-loading rules** that enforce best practices based on file patterns

## Quick Start

```bash
# Option 0: Fork Template (Github UI)
claude -m "/cleanup"  # then start claude code running /cleanup so top-level directory of your project isn't polluted


# Option 1: One-liner installer (Claude Code)
curl -fsSL https://raw.githubusercontent.com/solanabr/solana-ai-kit/main/install.sh | bash

# Option 2: One-liner installer (Codex, Opencode, everything else)
curl -fsSL https://raw.githubusercontent.com/solanabr/solana-ai-kit/main/install.sh | bash -s -- --agents

# Option 3: Manual setup
git clone --recurse-submodules https://github.com/solanabr/solana-ai-kit.git
cp -r solana-ai-kit/.claude /path/to/your-project/
cp solana-ai-kit/CLAUDE-solana.md /path/to/your-project/CLAUDE.md
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

## Install as a Claude Code plugin

solana-ai-kit is also its own Claude Code marketplace serving one **core plugin**. From inside Claude Code:

```text
/plugin marketplace add solanabr/solana-ai-kit
/plugin install solana-ai-kit@solana-ai-kit
```

The plugin ships the **core kit**: the 15 agents, 29 commands, the local go-to-market + registry skills (idea-sprint, pitch-deck, hackathon, registry), the 7 MCP servers, and the dev hooks (banner, formatter, pre-deploy/commit gates). Commands and skills are namespaced — `/deploy` becomes `/solana-ai-kit:deploy`.

What the plugin **cannot** carry (Claude Code plugins are plain git clones — they can't init submodules or ship a permissions/sandbox policy), so these stay exclusive to the **full install** (`install.sh`):

- the lazy-loaded `.claude/rules/*` code-style law (Rust, Anchor, Pinocchio, TypeScript, .NET)
- the curated permissions allowlist + sandbox policy
- the 18 `ext/` skill submodules (protocol, security, infra, ecosystem depth)

For protocol-skill depth in plugin form, add the upstream marketplaces instead (routing, not copying) — e.g. `/plugin marketplace add sendaifun/skills`, `ghostsecurity/skills`, `trailofbits/skills`, `cloudflare/skills`. The plugin's skill hub and the `registry` skill list the current targets.

The two paths are complementary: individuals wanting Solana agents/commands across **all** their projects → plugin at user scope; project teams working in one repo → `install.sh` (full kit). If you enable both in the same project, `/doctor` warns about duplicate commands/hooks/MCP and advises picking one. Plugin auto-update is off by default for third-party marketplaces — refresh with `/plugin marketplace update` + `claude plugin update`.

## Key Features

## External Skill Submodules

| Submodule | Source | Purpose |
|-----------|--------|---------|
| `ext/solana-dev` | [solana-foundation/solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill) | Core Solana development (programs, frontend, testing, security) |
| `ext/sendai` | [sendaifun/skills](https://github.com/sendaifun/skills) | DeFi protocol integrations (Jupiter, Raydium, Kamino, perps, cross-chain, oracles, etc.) |
| `ext/solana-game` | [solanabr/solana-game-skill](https://github.com/solanabr/solana-game-skill) | Game development (Unity, PlaySolana, PSG1) |
| `ext/cloudflare` | [cloudflare/skills](https://github.com/cloudflare/skills) | Infrastructure (Workers, Agents SDK, MCP servers) |
| `ext/trailofbits` | [trailofbits/skills](https://github.com/trailofbits/skills) | Security auditing and vulnerability scanning |
| `ext/qedgen` | [QEDGen/solana-skills](https://github.com/QEDGen/solana-skills) | Formal verification with Lean 4 theorem proving |
| `ext/solana-mobile` | [solana-mobile/solana-mobile-dev-skill](https://github.com/solana-mobile/solana-mobile-dev-skill) | Mobile Wallet Adapter, Genesis Token, SKR address resolution |
| `ext/colosseum` | [ColosseumOrg/colosseum-copilot](https://github.com/ColosseumOrg/colosseum-copilot) | Startup research, idea validation, hackathon projects |
| `ext/safe-solana-builder` | [frankcastleauditor/safe-solana-builder](https://github.com/frankcastleauditor/safe-solana-builder) | Security-first code generation (70+ audit-derived rules) |
| `ext/vercel` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Vercel deployment, Next.js, AI SDK, v0, edge functions |
| `ext/solana-new` | [sendaifun/solana-new](https://github.com/sendaifun/solana-new) | 32 idea→launch journey skills + idea datasets/knowledge base; routed via local wrappers |
| `ext/ghostsecurity` | [ghostsecurity/skills](https://github.com/ghostsecurity/skills) | 7 AppSec skills: SAST criteria, SCA, secrets, validation |
| `ext/defending-code` | [anthropics/defending-code-reference-harness](https://github.com/anthropics/defending-code-reference-harness) | Anthropic vuln-discovery reference harness + 6 skills |
| `ext/jupiter` | [jup-ag/agent-skills](https://github.com/jup-ag/agent-skills) | Official Jupiter skills: Ultra swap, Lend, swap migration, VRFD |
| `ext/metaplex` | [metaplex-foundation/skill](https://github.com/metaplex-foundation/skill) | Official Metaplex: Core, Token Metadata, Bubblegum, Candy Machine, Genesis |
| `ext/helius` | [helius-labs/core-ai](https://github.com/helius-labs/core-ai) | Official Helius infra skill + unique SVM internals skill |
| `ext/quicknode-anchor` | [quiknode-labs/solana-anchor-claude-skill](https://github.com/quiknode-labs/solana-anchor-claude-skill) | Anchor/financial-math/Quasar reference files (quarantined — refs only) |
| `ext/eth-to-sol` | [solana-foundation/eth-to-sol-skill](https://github.com/solana-foundation/eth-to-sol-skill) | EVM/Solidity → Anchor two-pass porting |

### Agent Teams

Each agent loads its own specialized context on invocation:

```
"Use solana-architect to design the vault program"
"Use anchor-engineer to implement the deposit instruction"
"Use defi-engineer to integrate Jupiter swaps"
"Use solana-qa-engineer to write comprehensive tests"
```

Claude will spawn each specialized agent by itself based on context and, with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` enabled, orchestrate multi-agent workflows:

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

Pre-configured MCP servers in `.mcp.json` (API keys go in `.env`):

| Server | Capabilities |
|--------|-------------|
| **Helius** | 60+ tools: RPC, DAS API, webhooks, priority fees, token metadata, NFT data |
| **solana-dev** | Solana Foundation official MCP — Solana docs, guides, and API references |
| **Context7** | Up-to-date library documentation lookup |
| **Playwright** | Browser automation for dApp testing and visual verification |
| **context-mode** | Context window optimization — compresses large RPC responses, build logs, and code analysis |
| **memsearch** | Persistent AI memory across sessions — auto-captures summaries, semantic search, git-friendly storage |
| **Surfpool** | Agent-driven local validator / mainnet-fork control via the Surfpool CLI — `surfpool mcp` (requires the surfpool CLI) |

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
├── README.md                    # This file
├── .mcp.json                    # MCP server configurations (project root)
├── install.sh                   # One-liner installer
├── update.sh                    # Deprecation wrapper → .claude/bin/update.sh
├── validate.sh                  # Config integrity checker
├── LICENSE                      # MIT
├── tests/                       # Config integrity test suite
├── .github/workflows/
│   ├── ci.yml                       # PR validation
│   ├── claude-code.yml              # Claude Code action template
│   └── claude.yml                   # @claude mention responder (issues/PRs)
└── .claude/
    ├── VERSION                  # Semver version (e.g. 1.4.0)
    ├── agents/                  # 15 specialized agents
    ├── bin/
    │   ├── update.sh                # In-place update from upstream
    │   └── resync.sh                # Submodule resync script
    ├── commands/                # 29 workflow commands
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
    │   │   ├── safe-solana-builder/   # Security-first code generation
    │   │   ├── vercel/                # Vercel deployment, Next.js, AI SDK
    │   │   ├── solana-new/            # SendAI idea→launch journey skills + datasets
    │   │   ├── ghostsecurity/         # Ghost Security AppSec skills
    │   │   ├── defending-code/        # Anthropic vuln-discovery reference harness
    │   │   ├── jupiter/               # Official Jupiter skills (swap, lend, VRFD)
    │   │   ├── metaplex/              # Official Metaplex (NFT, candy machine)
    │   │   ├── helius/                # Official Helius infra + SVM internals
    │   │   ├── quicknode-anchor/      # Anchor/Quasar reference files (quarantined)
    │   │   └── eth-to-sol/            # EVM/Solidity → Anchor porting
    │   ├── registry/                # Scout new repos/skills/MCPs + watchlists
    │   ├── idea-sprint/             # Wrapper: find + validate crypto ideas (GTM)
    │   ├── pitch-deck/              # Wrapper: pitch decks for crypto projects (GTM)
    │   ├── hackathon/               # Wrapper: hackathon submissions + grants (GTM)
    │   ├── token-2022.md            # Token Extensions guide (local)
    │   ├── backend-async.md         # Axum/Tokio patterns (local)
    │   └── deployment.md            # Deployment workflows (local)
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
| `/audit-infra` | Infra-first security audit: secrets, supply chain, CI/CD, LLM/skill security, OWASP, STRIDE |
| `/product-review` | Product quality review — UX walkthrough, 8-dimension scorecard (`--harsh` for the roast variant) |
| `/diff-review` | AI-powered diff review for Solana-specific issues |
| `/profile-cu` | CU profiling per instruction with optimization suggestions |
| `/benchmark` | CU benchmarks with before/after comparison |
| `/debug-user-tx` | Replay a user's failing tx against forked state, map error to source |

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
| `/doctor` | Health check for dev environment + config — read-only, one fix-it command per failure |
| `/dream` | Memory consolidation — dedupe, prune, re-rank MEMORY.md and Project Learnings |

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

- **[sendaifun/solana-new](https://github.com/sendaifun/solana-new)** - SendAI + Superteam's idea→launch journey skills, idea datasets, and ecosystem catalogs (basis of the `idea-sprint`, `pitch-deck`, and `hackathon` wrapper skills). The bundled idea datasets draw on primary sources from Superteam, Y Combinator, a16z crypto, and Alliance. MIT licensed:

  > MIT License
  >
  > Copyright (c) 2026 SendAI and Superteam
  >
  > Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  >
  > The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  >
  > THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

- **cso** by **gstack** - The infrastructure-first security audit methodology shipped in sendaifun/solana-new, the basis of our `/audit-infra` command (adapted telemetry-free).

- **[ghostsecurity/skills](https://github.com/ghostsecurity/skills)** and **[anthropics/defending-code-reference-harness](https://github.com/anthropics/defending-code-reference-harness)** - AppSec scanning skills and Anthropic's vulnerability-discovery reference harness, both included as submodules under their Apache-2.0 licenses.

- **[jup-ag/agent-skills](https://github.com/jup-ag/agent-skills)** - Jupiter's official agent skills (Ultra swap, Lend, swap migration, VRFD), included as a submodule under the MIT license.

- **[metaplex-foundation/skill](https://github.com/metaplex-foundation/skill)** - Metaplex's official NFT-standards skill (Core, Token Metadata, Bubblegum, Candy Machine, Genesis), included as a submodule under the Apache-2.0 license.

- **[helius-labs/core-ai](https://github.com/helius-labs/core-ai)** - Helius's official infrastructure skill plus its SVM-internals skill, included as a submodule under the MIT license. Home repo of the Helius MCP server shipped in this kit.

- **[quiknode-labs/solana-anchor-claude-skill](https://github.com/quiknode-labs/solana-anchor-claude-skill)** - QuickNode's Anchor / financial-math / Quasar reference material, included as a submodule under the MIT license (quarantined — reference files only; `.claude/rules/anchor.md` governs code style).

- **[solana-foundation/eth-to-sol-skill](https://github.com/solana-foundation/eth-to-sol-skill)** - The Solana Foundation's EVM/Solidity → Anchor two-pass porting skill, included as a submodule.

## License

MIT - See [LICENSE](LICENSE)
