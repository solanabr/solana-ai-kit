---
name: pda-vault
description: Build production-grade PDA vaults on Solana. Single-signer, time-lock, multi-sig, and escrow vault patterns with Anchor 1.0+ and Pinocchio. Covers PDA derivation, CPI signing, seed strategies, and security.
user-invocable: true
---

# PDA Vault Development Skill

Build secure, production-grade PDA vaults for Solana. A PDA vault is a program-owned account used to hold and manage assets on behalf of users -- the foundational pattern behind every lending pool, escrow, staking vault, and AMM.

## What This Skill Is For

Use this skill when the user asks about:

### Basic Vault Operations
- Single-signer vault with deposit/withdraw
- Token vaults with PDA authority
- Balance tracking and account management

### Time-Lock Vaults
- Token vesting with cliff unlocks
- Salary streams and payment schedules
- Clock-based release conditions

### Escrow Vaults
- Two-party settlement (P2P trading, OTC deals)
- Buyer deposit, seller fulfill, buyer cancel
- Atomic swap patterns

### Multi-Sig Vaults
- M-of-N approval for withdrawals
- Proposal-based execution
- DAO treasury management

### High-Performance Vaults
- Pinocchio implementation for 88-95% CU reduction
- Zero-copy account access with bytemuck
- High-throughput vaults for DEXs and orderbooks

### Security
- PDA seed verification and bump management
- Reinitialization attack prevention
- Balance tracking with checked math
- CPI reentrancy protection

### Testing
- Mollusk unit tests
- LiteSVM integration tests
- Surfpool mainnet forking

## Default Stack Decisions

1. Programs: Anchor 1.0+ or Pinocchio 0.10+
2. Testing: Mollusk or LiteSVM
3. Client: @solana/kit (web3.js v2)
4. IDL: Codama from Anchor

## Operating Procedure

### 1. Classify the Task

| Layer | Examples | Skill File |
|-------|----------|------------|
| Single-signer vault | Deposit, withdraw, balance | [single-signer.md](single-signer.md) |
| Time-lock vault | Vesting, cliff, streaming | [time-lock.md](time-lock.md) |
| Escrow vault | P2P settlement, cancel | [escrow.md](escrow.md) |
| Multi-sig vault | Approvals, threshold | [multi-sig.md](multi-sig.md) |
| High-performance | Pinocchio vault | [pinocchio.md](pinocchio.md) |
| Security review | Audits, checklists | [security.md](security.md) |
| Testing | Unit, integration, fork | [testing.md](testing.md) |
| Reference | Seeds, addresses, cheats | [resources.md](resources.md) |

### 2. Common Patterns

- PDA seeds must be deterministic for client-side derivation
- Always verify bump matches canonical bump from find_program_address
- Use checked_add/checked_sub for all balance operations
- Release immutable borrows before taking mutable borrows
- Close vaults with the close constraint to reclaim rent

### 3. Deliverables

When implementing a vault, provide:
- Exact files changed with clear diffs
- Program ID and PDA derivation
- Deposit/withdraw instruction signatures
- Testing instructions
- Mainnet vs devnet considerations

## Progressive Disclosure

Read only what you need:

- [single-signer.md](single-signer.md) -- Deposit, withdraw, balance tracking with Anchor
- [time-lock.md](time-lock.md) -- Clock-gated unlock, vesting schedules
- [escrow.md](escrow.md) -- Buyer/seller settlement, cancel flows
- [multi-sig.md](multi-sig.md) -- M-of-N approvals, proposal execution
- [pinocchio.md](pinocchio.md) -- Zero-copy vault implementation
- [security.md](security.md) -- Vulnerability checklist and prevention
- [testing.md](testing.md) -- Mollusk, LiteSVM, Surfpool testing
- [resources.md](resources.md) -- PDA cheatsheet, program addresses

## Task Routing Guide

| User asks about... | Primary skill file |
|--------------------|--------------------|
| Create a vault | single-signer.md |
| Deposit tokens | single-signer.md |
| Withdraw tokens | single-signer.md |
| Time-lock or vesting | time-lock.md |
| Escrow between two parties | escrow.md |
| Multi-sig approval | multi-sig.md |
| High-performance vault | pinocchio.md |
| Audit vault security | security.md |
| Write vault tests | testing.md |
| PDA derivation | resources.md |
| Vault program addresses | resources.md |

## Commands

| Command | Description |
|---------|-------------|
| /scaffold-vault | Generate an Anchor vault project |
| /test-vault | Run vault tests with Mollusk |

## Agents

| Agent | Purpose |
|-------|---------|
| **vault-architect** | Vault design, seed strategy, security review |
| **vault-engineer** | Implement vault instructions in Anchor or Pinocchio |
