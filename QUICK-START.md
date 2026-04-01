# Quick Start: Use This Config in 2 Minutes

## TL;DR

```bash
# Option 1: One-liner installer (recommended)
curl -fsSL https://raw.githubusercontent.com/solanabr/solana-claude-config/main/install.sh | bash

# Option 2: Manual setup
git clone --recurse-submodules https://github.com/solanabr/solana-claude-config.git
cp -r solana-claude-config/.claude /path/to/your-project/
cp solana-claude-config/CLAUDE-solana.md /path/to/your-project/CLAUDE.md
cd /path/to/your-project && git submodule update --init --recursive

# Start Claude Code
claude
```

That's it. Claude now has Solana superpowers.

---

## Optional: Configure MCP Servers

After setup, run `/setup-mcp` in Claude Code to configure:
- **Helius** — On-chain data, DAS API, webhooks (needs API key from helius.dev)
- **solana-dev** — Solana Foundation official docs and API references (no key needed)
- **Context7** — Library documentation lookup (no key needed)
- **Playwright** — Browser automation for dApp testing (no key needed)
- **context-mode** — Context window optimization for large responses (no key needed)
- **memsearch** — Persistent AI memory across sessions (no key needed)

---

## What You Get

### 15 Specialized Agents

| Agent | Use For |
|-------|---------|
| **solana-architect** | System design, account structures, PDAs |
| **anchor-engineer** | Anchor program development |
| **pinocchio-engineer** | CU-optimized native programs |
| **defi-engineer** | DeFi integrations (Jupiter, Drift, Kamino, etc.) |
| **token-engineer** | Token-2022 extensions, token launches |
| **solana-frontend-engineer** | React/Next.js dApp frontends |
| **mobile-engineer** | React Native/Expo mobile dApps |
| **rust-backend-engineer** | Rust backend services |
| **devops-engineer** | CI/CD, monitoring, infrastructure |
| **solana-qa-engineer** | Testing, fuzzing, security |
| **tech-docs-writer** | Documentation |
| **game-architect** | Solana game design, concept docs |
| **unity-engineer** | Unity/C# with Solana.Unity-SDK |
| **solana-guide** | Learning and tutorials |
| **solana-researcher** | Ecosystem research |

### 24 Slash Commands

**Building:**
- `/build-program` - Build Anchor or native programs
- `/build-app` - Build web client
- `/build-unity` - Build Unity projects (WebGL, PSG1)
- `/scaffold` - Generate project scaffolding

**Testing & Quality:**
- `/test-rust` - Run Rust tests
- `/test-ts` - Run TypeScript tests
- `/test-dotnet` - Run .NET/Unity tests
- `/test-and-fix` - Run tests and auto-fix issues
- `/audit-solana` - Security audit
- `/diff-review` - AI-powered diff review
- `/profile-cu` - CU profiling per instruction
- `/benchmark` - CU benchmarks before/after

**Deployment & Migration:**
- `/deploy` - Deploy to devnet/mainnet
- `/migrate-web3` - Migrate web3.js → @solana/kit
- `/generate-idl-client` - Generate typed clients from IDL

**Workflow & Setup:**
- `/quick-commit` - Format, lint, and commit
- `/setup-ci-cd` - Setup CI/CD pipeline
- `/setup-mcp` - Configure MCP servers
- `/resync` - Resync external skill submodules
- `/write-docs` - Generate documentation
- `/explain-code` - Explain complex code
- `/plan-feature` - Plan feature implementation
- `/update` - Update config to latest upstream
- `/cleanup` - Initialize forked template, remove scaffolding

### Agent Teams

Create multi-agent workflows:
```
"Create an agent team: architect for design, anchor-engineer for code, qa-engineer for tests"
```

### Auto-Loading Rules

Rules automatically activate based on file patterns:
- `.rs` files → Rust rules
- `.cs` files → C#/.NET rules
- `.ts/.tsx` files → TypeScript rules

### Progressive Skills

Knowledge loads on-demand:
- Solana fundamentals
- Anchor patterns
- Token-2022 extensions
- DeFi protocol integrations
- Unity SDK patterns
- PlaySolana/PSG1 integration
- Security auditing

---

## Supported Tech Stack

### Programs
- **Anchor** - Rapid development with macros
- **Pinocchio** - Maximum CU optimization
- **Native Rust** - Full control

### Clients
- **TypeScript** - @solana/kit, Anchor client
- **Rust** - solana-sdk, anchor-client
- **C#/Unity** - Solana.Unity-SDK

### Testing
- **Bankrun** - Fast TypeScript testing
- **LiteSVM** - Lightweight Rust testing
- **Mollusk** - Instruction-level testing
- **Trident** - Fuzz testing

### Platforms
- **Web** - React, Next.js
- **Desktop** - Tauri, Electron
- **Mobile** - React Native, Expo
- **Gaming** - Unity (WebGL, PSG1)

---

## Project Structure After Setup

```
your-project/
├── CLAUDE.md              # ← Main config (copied from CLAUDE-solana.md)
├── .claude/
│   ├── agents/            # 15 specialized AI agents
│   ├── commands/          # 24 slash commands
│   ├── skills/            # Progressive knowledge
│   │   ├── SKILL.md           # Unified hub (start here)
│   │   ├── ext/               # External skill submodules
│   │   │   ├── solana-dev/        # Core Solana (Foundation)
│   │   │   ├── sendai/            # DeFi protocols
│   │   │   ├── solana-game/       # Game dev (Unity, PSG1)
│   │   │   ├── cloudflare/        # Infrastructure
│   │   │   ├── trailofbits/       # Security auditing
│   │   │   ├── qedgen/            # Formal verification (Lean 4)
│   │   │   ├── solana-mobile/     # Mobile Wallet Adapter
│   │   │   ├── colosseum/         # Startup research (Colosseum)
│   │   │   └── safe-solana-builder/ # Security-first code gen
│   │   ├── token-2022.md     # Token Extensions guide
│   │   ├── backend-async.md  # Axum/Tokio patterns
│   │   └── deployment.md     # Deploy workflows
│   ├── mcp.json           # MCP server configs
│   ├── rules/             # Auto-loading rules
│   └── settings.json      # Permissions
├── programs/              # Your Solana programs
├── app/                   # Your frontend
└── ...
```

---

## Usage Examples

### Start a New Program
```
You: Create an escrow program
Claude: [Uses solana-architect to design, anchor-engineer to implement]
```

### DeFi Integration
```
You: Integrate Jupiter swaps into the program
Claude: [Uses defi-engineer with Jupiter protocol skills]
```

### Build and Test
```
You: /build-program
Claude: [Runs anchor build, reports any errors]

You: /test-rust
Claude: [Runs cargo test, shows results]
```

### Profile Performance
```
You: /profile-cu
Claude: [Reports CU usage per instruction, suggests optimizations]
```

### Deploy
```
You: /deploy devnet
Claude: [Deploys to devnet, provides program ID]
```

### Token Launch
```
You: Create a Token-2022 token with transfer fees
Claude: [Uses token-engineer with token-2022.md skill]
```

---

## Customization

### Add Project-Specific Context

Edit your `CLAUDE.md` to add:

```markdown
## Project-Specific

- Program ID: `YourProgram...`
- Main token: `TokenMint...`
- Custom patterns for this project
```

### Adjust Permissions

Edit `.claude/settings.json` to customize allowed commands.

### Configure MCP Servers

Edit `.env` to add API keys for MCP servers (Helius, Solana Agent Kit). Run `/setup-mcp` for guided setup.

---

## Updating

```bash
# Preferred: use /update in Claude Code, or run directly:
bash .claude/bin/update.sh

# Or resync submodules only
/resync
```

---

## Troubleshooting

**Claude doesn't use the config:**
- Ensure `CLAUDE.md` is in your project root
- Ensure `.claude/` folder is in your project root
- Restart Claude Code

**Commands not working:**
- Check `.claude/settings.json` permissions
- Ensure command files are in `.claude/commands/`

**Agent not spawning:**
- Verify agent file exists in `.claude/agents/`
- Check agent description matches your request

**MCP servers not connecting:**
- Run `/setup-mcp` to verify configuration
- Check API keys are set in environment

**Submodules empty:**
- Run `git submodule update --init --recursive`
- Or run `/resync`

---

## Resources

- [CLAUDE-solana.md](./CLAUDE-solana.md) - Full configuration reference
- [.claude/agents/](./.claude/agents/) - All agent definitions
- [.claude/commands/](./.claude/commands/) - All commands
- [.claude/skills/](./.claude/skills/) - Knowledge base
- [.claude/mcp.json](./.claude/mcp.json) - MCP server configs

---

**Ready to build on Solana!**
