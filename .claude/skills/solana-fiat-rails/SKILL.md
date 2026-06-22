---
name: solana-fiat-rails
description: Fiat-in/fiat-out layer for stablecoin products on Solana — onramp/offramp integration, virtual accounts, treasury wallet architecture, payroll/payout bulk disbursements, idempotent webhook handling, and compliance flagging for emerging markets (Africa, LatAm, SEA). Extends solana-dev-skill. For on-chain program logic, swap routing, or NFTs, delegate to the respective skills.
user-invocable: true
---

# Solana Fiat Rails Skill

> **Extends**: [solana-dev-skill](../solana-dev/SKILL.md) — Core Solana development

## What This Skill Is For

The fiat-in/fiat-out layer for stablecoin products targeting emerging markets. Getting USDC moving on Solana is the easy 20%. The hard 80% is: local-currency payment in → stablecoin credited; stablecoin → local payout; a treasury wallet that isn't the founder's personal wallet with auto-conversion on every inflow; invoice/payment-link routing to a workspace treasury wallet instead of a personal wallet; payroll/invoice payouts that batch reliably and reconcile against a ledger, not just "the on-chain balance changed"; webhooks that fire more than once, out of order, or not at all.

**Core principle:** the internal ledger is the source of truth — never the provider's webhook, never the raw on-chain balance. Every architecture pattern in this skill exists because treating either as ground truth eventually double-credits a user or loses a reconciliation argument with a regulator.

### Capabilities

| Layer | Description |
|-------|-------------|
| **Onramp/Offramp** | Integrate fiat-to-crypto and crypto-to-fiat providers across Africa, LatAm, SEA |
| **Virtual Accounts** | Provision real bank/mobile-money account numbers mapped 1:1 to wallets |
| **Treasury Wallet Architecture** | Auto-convert-all-inflows-to-USDC, workspace-level treasury routing |
| **Payouts & Payroll** | Bulk disbursements, invoice routing, FX timing, ledger reconciliation |
| **Webhook Idempotency** | Dedupe, out-of-order handling, reconciliation backstop |
| **Compliance Flagging** | Travel-rule thresholds, sanctions screening hook points, KYC-tier gating |

### Don't Use For

- On-chain program logic (solana-dev-skill)
- Swap routing (jupiter/sendai)
- NFTs (metaplex)
- Licensing/legal determinations (defer to crypto-legal-skill or counsel)

## Quick Decision Tree by Region

| Region | Recommended Providers |
|--------|---------------------|
| **Africa** | Yellow Card (full custody, 50+ currencies), Paychant (multi-rail aggregation), Fonbnk (airtime/bank onramp, 19 markets) |
| **LatAm** | Bridge.xyz (B2B treasury-grade, BRL/MXN/COP), Crossmint (full stack, 160+ countries) |
| **SEA / Global** | Crossmint, Onramper (ramp aggregator, 30+ ramps), Transak, MoonPay |
| **Enterprise** | Solana Developer Platform (pre-integrated node/wallet/compliance partners) |

## Operating Procedure

### 1. Classify the Task Layer

| Layer | Skill File(s) |
|-------|---------------|
| Provider selection & comparison | [provider-matrix.md](provider-matrix.md) |
| Fiat flow architecture | [architecture-patterns.md](architecture-patterns.md) |
| Virtual account provisioning | [virtual-accounts.md](virtual-accounts.md) |
| Payouts, payroll, disbursements | [payouts-payroll.md](payouts-payroll.md) |
| Compliance flagging | [compliance-flags.md](compliance-flags.md) |
| Provider docs & references | [resources.md](resources.md) |

### 2. Pick the Right Agent

| Task Type | Agent | Model |
|-----------|-------|-------|
| Onramp/offramp integration, treasury architecture | fiat-rails-engineer | sonnet |

### 3. Apply Core Patterns

- **Internal ledger is source of truth** — credit/debit against the ledger, reconcile on-chain balances as a cross-check
- **Auto-convert on receipt** — detect fiat inflow → swap to USDC → credit ledger, not wallet balance
- **Webhook idempotency** — dedupe on provider event ID before any credit; poll-based reconciliation as backstop
- **Treasury wallet isolation** — workspace-level wallet via embedded wallet APIs, not the founder's personal wallet

### 4. Flag Compliance, Don't Resolve It

Every integration touches compliance boundaries. Flag travel-rule thresholds, sanctions exposure, and KYC-tier gating. Refer licensing questions to a crypto-legal-skill or counsel. This skill flags; it does not determine.

---

## Progressive Disclosure (Read When Needed)

- [provider-matrix.md](provider-matrix.md) — Comparison table of providers with confirmed Solana support
- [architecture-patterns.md](architecture-patterns.md) — Auto-convert, treasury wallet, webhook idempotency, reconciliation
- [virtual-accounts.md](virtual-accounts.md) — Bank/mobile-money account numbers mapped to Solana wallets
- [payouts-payroll.md](payouts-payroll.md) — Bulk disbursements, invoice routing, FX timing
- [compliance-flags.md](compliance-flags.md) — Travel rule, sanctions, KYC gating (engineering guidance only)
- [resources.md](resources.md) — Provider docs, FATF reference

## Commands

| Command | Description |
|---------|-------------|
| /integrate-onramp | Integrate a fiat onramp/offramp provider with Solana wallet flow |
| /audit-money-flow | Trace fiat → USDC → payout path for reconciliation gaps |

## Agents

| Agent | Purpose |
|-------|---------|
| **fiat-rails-engineer** | Onramp/offramp integration, treasury architecture, payout plumbing |

---

**Engineering guidance only. Not legal advice. No licensing determinations made here.**
