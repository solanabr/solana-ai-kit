# PDA Vault Skill

Build production-grade PDA vaults on Solana. Single-signer, time-lock, multi-sig, and escrow vault patterns with Anchor 1.0+ and Pinocchio.

## What's Included

### Skills

| File | Covers |
|------|--------|
| skill/SKILL.md | Entry point, routing, stack decisions |
| skill/single-signer.md | Basic vault with deposit, withdraw, close |
| skill/time-lock.md | Clock-gated unlock, vesting schedules |
| skill/escrow.md | Two-party settlement, buyer cancel |
| skill/multi-sig.md | M-of-N approvals, proposal execution |
| skill/pinocchio.md | Zero-copy vault for 88-95% CU reduction |
| skill/security.md | Vulnerability checklist and prevention |
| skill/testing.md | Mollusk, LiteSVM, Surfpool testing |
| skill/resources.md | Seed cheatsheet, program addresses |

### Agents

| Agent | Purpose |
|-------|---------|
| vault-architect | Design seed strategy, authority model, security |
| vault-engineer | Implement instructions in Anchor or Pinocchio |

### Commands

| Command | Description |
|---------|-------------|
| /scaffold-vault | Generate an Anchor vault project |
| /test-vault | Run vault tests |

### Rules

- Vault coding standards enforced via .claude/rules/vault.md

## Installation

```bash
git clone https://github.com/worztm/pda-vault-skill
cd pda-vault-skill
./install.sh
```

Or add as a submodule to your Solana AI Kit:

```bash
git submodule add https://github.com/worztm/pda-vault-skill .claude/skills/pda-vault
```

## License

MIT
