---
name: solana-ai-kit
description: Skill hub for the solana-ai-kit Claude Code plugin. Routes the bundled go-to-market and registry skills, and points to upstream marketplaces (and the install.sh full install) for protocol, security, and ecosystem depth. Progressive disclosure — read only what you need.
user-invocable: true
---

# Solana AI Kit — Plugin Skill Hub

This is the **plugin variant** of the kit's skill hub. It ships only the skills that travel cleanly in a plugin (go-to-market wrappers + the registry). For the full depth — protocol/security/ecosystem skills, `.claude/rules/*`, and the curated permissions/sandbox policy — use the **full install** (see "Getting more depth" below).

**Source precedence (when multiple skills cover one topic):**
1. `.claude/rules/*` are law for code style — but rules ship **only** with the full install (`install.sh`), not this plugin. If you installed via the plugin, the house code-style rules are not loaded; prefer them when present.
2. Protocol-OFFICIAL skill is primary for that protocol's API/SDK usage (jup-ag→Jupiter, metaplex-foundation→Metaplex, helius-labs→Helius). In plugin form, add the relevant upstream marketplace (below).
3. Foundation/platform skills (Solana Foundation `solana-dev`) are primary for general concepts (Anchor, Pinocchio, testing, clients) — add its marketplace.
4. Community versions (sendai et al.) are secondary references.

## Bundled skills (shipped with this plugin)

These load automatically when the plugin is enabled. Commands and skills are namespaced under `solana-ai-kit:` (e.g. `/solana-ai-kit:deploy`).

### Idea, Pitch & Go-To-Market

Local wrappers, adapted from sendaifun/solana-new (MIT, telemetry removed):

- [idea-sprint/SKILL.md](idea-sprint/SKILL.md) — What to build: blunt interview, crypto-necessity gate, 3 scored candidates (/15), go/no-go with pivot suggestions
- [pitch-deck/SKILL.md](pitch-deck/SKILL.md) — Audience-aware decks (hackathon/VC/grant/accelerator): narrative frameworks, slides + speaking notes, objection prep
- [hackathon/SKILL.md](hackathon/SKILL.md) — Scannable submissions, <3-min demo scripts, least-crowded-track selection, Superteam Earn grants

### Registry & Monitoring

- [registry/SKILL.md](registry/SKILL.md) — scouting methodology to research/vet new repos, skills, and MCPs + curated, link-rich watchlists ([trusted repos](registry/references/trusted-repos.md), [extended skills](registry/references/extended-skills.md), [optional MCPs](registry/references/optional-mcps.md), [young/unverified watchlist](registry/references/watchlist.md)). The home for opt-in skills and MCPs NOT installed by default.

## Getting more depth (protocol / security / ecosystem skills)

Plugins cannot carry git submodules, so the 18 external skill packs (the `ext` submodules) are **not** bundled here. Two ways to get them:

### Option A — Add the upstream marketplaces (routing, not copying)

Several of the upstream skill packs publish their own Claude Code marketplaces. Add the ones you need, then `/plugin install` the specific skill plugins:

| Domain | Add the marketplace | Then install |
|--------|---------------------|--------------|
| DeFi protocols, infra, data (Jupiter, Raydium, Kamino, perps, oracles, cross-chain…) | `/plugin marketplace add sendaifun/skills` | the protocol plugins you need (one per skill) |
| AppSec scanning (SAST, SCA, secrets) | `/plugin marketplace add ghostsecurity/skills` | `ghost` |
| Security auditing, vulnerability scanning | `/plugin marketplace add trailofbits/skills` | the audit plugins you need |
| Infrastructure (Workers, Agents SDK, MCP servers) | `/plugin marketplace add cloudflare/skills` | `cloudflare` |

For Jupiter, Metaplex, and Helius the official skill repos are the primary sources — check the registry skill (`registry/SKILL.md`) for their current upstream locations and `/plugin marketplace add` targets. Route to a **marketplace** and install the plugin; do not point at an upstream repo's `SKILL.md` directly.

### Option B — Full install (recommended for project teams)

Run the installer in your project to get everything the plugin can't carry — the 18 external skill submodules, the lazy-loaded `.claude/rules` files (Rust, Anchor, Pinocchio, TypeScript, .NET code-style law), and the curated permissions + sandbox policy:

```bash
curl -fsSL https://raw.githubusercontent.com/solanabr/solana-ai-kit/main/install.sh | bash
```

See the project README ("External Skill Submodules" and "Install as a Claude Code plugin") for when to pick the plugin vs. the full install — they are complementary, not competing. If you run **both** in the same project, `/solana-ai-kit:doctor` warns about duplicate commands/hooks/MCP and advises picking one.

## Task Routing (bundled skills)

| User asks about... | Skill |
|--------------------|-------|
| Idea validation, "what should I build" | idea-sprint/SKILL.md |
| Pitch deck, demo day, investor or grant slides | pitch-deck/SKILL.md |
| Hackathon submission, demo script, track choice | hackathon/SKILL.md |
| Scout new repos/skills/MCPs, registry, what to monitor, "should I add X" | registry/SKILL.md |
| Protocol SDK depth (Jupiter, Metaplex, Helius, Raydium…), security audits, infra | add the upstream marketplace (Option A) or do the full install (Option B) |
