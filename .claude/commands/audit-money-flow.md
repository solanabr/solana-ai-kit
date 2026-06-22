---
name: audit-money-flow
description: Trace the full fiat → USDC → payout path for a workspace and identify reconciliation gaps, double-credit risks, and failure handling gaps.
---

# Audit Money Flow

Trace the full fiat → USDC → payout path for a workspace and identify reconciliation gaps, double-credit risks, and failure handling gaps.

## Usage

```
/audit-money-flow [workspace-id] [options]
```

### Options
- `--days N` - Audit last N days (default: 30)
- `--providers provider,...` - Restrict to specific providers
- `--verbose` - Show individual ledger entries and on-chain TX signatures
- `--fix` - Generate remediation instructions (dry-run only)

## Audit Checklist

### 1. Webhook Integrity

- [ ] event_dedupe table has no duplicate entries for the same provider event_id
- [ ] No ledger entries missing event_id
- [ ] Ratio of webhook arrivals to ledger credits ≈ 1:1

### 2. Ledger vs. On-Chain

- [ ] Query workspace treasury wallet USDC balance via RPC
- [ ] Compute ledger balance from completed entries
- [ ] Difference < threshold (1% of volume or $50, whichever is larger)
- [ ] If difference exists: categorize as gas fees, pending swaps, or unknown

### 3. Auto-Convert Pipeline

- [ ] Every completed fiat_in entry has a corresponding usdc_credit entry
- [ ] No fiat_in entry stuck in "pending" for > 2 hours
- [ ] Failed swaps have manual review queue entries
- [ ] Slippage on completed swaps within configured tolerance

### 4. Payout Integrity

- [ ] Every payout batch has a matching ledger debit entry
- [ ] Per-recipient tracking: no "completed" without TX signature
- [ ] Failed payouts (retries exhausted) have review queue entries
- [ ] No payout batch processed twice (idempotency keys)

### 5. Virtual Account Health

- [ ] Every provisioned virtual account has a workspace mapping
- [ ] No active VA with inactive workspace (zombie VA)
- [ ] Deposits to archived/closed VAs have exception handling

### 6. Compliance Hooks

- [ ] Sanctions screening runs before every credit
- [ ] Travel rule check on transfers above threshold
- [ ] KYC tier verified before VA provisioning and payouts

## Report Format

```
Audit Report: workspace_abc (2026-06-01 → 2026-06-20)
═══════════════════════════════════════════════════════════
Webhook Integrity:  ✓  (142 events, 142 credits)
Ledger vs On-Chain: ✓  (diff: 2.34 USDC — gas fees)
Auto-Convert:       ⚠  (1 stuck pending: inv_42)
Payout Integrity:   ✓  (12 batches, 0 double-sends)
VA Health:          ✓  (23 active, 2 to archive)
Compliance Hooks:   ✓

Action Items:
  [1] Review inv_42 — swap stalled; manual reconciliation needed
```

For full detail, see [architecture-patterns.md](../skills/solana-fiat-rails/architecture-patterns.md).
