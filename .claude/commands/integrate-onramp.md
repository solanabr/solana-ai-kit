---
name: integrate-onramp
description: Walk through integrating a fiat onramp/offramp provider (Yellow Card, Crossmint, Bridge, Onramper, Transak, MoonPay, Ramp) with a Solana wallet flow. Covers provider selection, webhook wiring, auto-convert pipeline, and treasury wallet provisioning.
---

# Integrate Onramp

Walk through the full integration of a fiat onramp/offramp provider with a Solana application.

## Usage

```
/integrate-onramp [provider] [region] [options]
```

### Providers
- `yellow-card` - Yellow Card (Africa, 50+ currencies)
- `crossmint` - Crossmint (global, full stack)
- `bridge` - Bridge.xyz (LatAm, B2B treasury)
- `onramper` - Onramper (aggregator, 30+ ramps)
- `transak` | `moonpay` | `ramp` - Global single-ramp providers

### Regions
- `africa` - African corridors (NGN, KES, GHS, ZAR, XAF/XOF)
- `latam` - Latin America (BRL, MXN, COP, ARS)
- `sea` - Southeast Asia (PHP, IDR, THB, VND)
- `global` - No regional preference

### Options
- `--usdc-only` - Only handle USDC (no swap step needed)
- `--virtual-accounts` - Provision virtual bank accounts
- `--no-treasury` - Skip treasury wallet isolation
- `--sandbox` - Use provider sandbox/test environment

## Workflow

### 1. Provider Selection

Identify the best provider for the target corridor using [solana-fiat-rails/provider-matrix.md](../skills/solana-fiat-rails/provider-matrix.md):
- Confirm Solana support in current docs
- Verify target currency and settlement speed support
- Validate KYC requirements match your user base

### 2. Sandbox Setup

- Register for provider sandbox/developer account
- Obtain API keys (scoped to minimal permissions)
- Configure webhook target URL
- Whitelist IPs if required

### 3. Webhook Endpoint

Create a webhook handler:

```
POST /webhooks/{provider}
  ├── Extract provider event ID
  ├── Dedupe check (event_dedupe table)
  ├── Parse payload (amount, currency, sender, metadata)
  ├── Screen sender against sanctions list
  ├── Create ledger entry (fiat receivable, pending)
  └── Respond 200 OK quickly (do not block on swap)
```

### 4. Auto-Convert Pipeline

Wire up the swap step in a background worker:

```
Ledger entry created (status: pending, type: fiat_in)
  ├── Initiate Jupiter swap: fiat-equivalent → USDC
  ├── On swap confirmation:
  │   ├── Update ledger: status → completed
  │   └── Credit workspace internal balance
  └── On swap failure:
      ├── Update ledger: status → failed
      └── Alert ops (manual reconciliation needed)
```

### 5. Treasury Wallet

Provision workspace-level treasury wallets:

```
POST /api/wallets/create
Body: { workspace_id, chain: "solana" }
  → Returns: Solana treasury address
  → Store: workspace_id ↔ treasury_address mapping
```

### 6. Reconciliation Backstop

```
Cron: every 4 hours per provider
  ├── Fetch pending ledger entries > 30 minutes old
  ├── Call provider reconciliation endpoint
  ├── For confirmed events not in dedupe table: process and credit
  └── For cancelled events: reverse ledger entry if credited
```

### 7. Verify End-to-End

- Deposit test funds in sandbox
- Confirm webhook arrives and dedupe prevents double-processing
- Confirm USDC appears in treasury wallet
- Confirm ledger balance matches expected amount

For full detail, see [architecture-patterns.md](../skills/solana-fiat-rails/architecture-patterns.md).
