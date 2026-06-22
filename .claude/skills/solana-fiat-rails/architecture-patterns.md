# Architecture Patterns — Fiat Rails on Solana

## Core Principle: The Internal Ledger Is the Source of Truth

Treat every external data source (provider webhook, on-chain balance, block explorer) as an *input* to reconciliation, not as ground truth. The ledger is authoritative. The patterns below exist because shipping production fiat rails means internalizing the following reality:

- Provider webhooks fire more than once, out of order, or not at all
- On-chain balances reflect final settlement but don't capture the business event (what was this payment for? which invoice?)
- Both can race each other — a webhook arrives before the transaction is confirmed, or the transaction confirms and the webhook never arrives

The ledger sits between both and resolves conflicts.

---

## Pattern 1: Auto-Convert-on-Receipt

### The Flow

```
Provider webhook: "100 BRL received for account X"
          │
          ▼
Dedupe check (event ID) ──► duplicate? ──► ack 200, no-op
          │
          ▼
  Internal ledger: credit "pending fiat receivable (100 BRL)"
          │
          ▼
  Initiate swap via Jupiter / aggregator: 100 BRL → USDC
          │
          ▼
  On swap confirmation:
    Ledger: debit "pending fiat receivable", credit "USDC balance (internal)"
    Emit: "user USDC available" event
```

### Why Not Credit Wallet Balance Directly

If you credit the user's embedded wallet balance on webhook receipt (before the swap executes), you expose yourself to:

- **Swap failure**: webhook arrives, you credit, then the DEX/slippage/insolvency fails the swap. Now you owe USDC you can't deliver.
- **Timing gap**: the webhook and the swap settlement are separate concerns. The user should only see spendable USDC after the swap finalizes.
- **Slippage exposure**: if you guarantee a fixed USDC amount on receipt but the swap delivers less, you eat the loss.

### Solana-Specific Notes

- Use `@crossmint/client-sdk` or similar embedded wallet APIs to provision the recipient wallet. The wallet should be a **workspace treasury wallet**, not the user's personal wallet (see Pattern 2).
- The swap step uses Jupiter Ultra API (`POST /swap/v1/build`) with a fixed-output quote so the user gets exactly N USDC regardless of inbound variance.
- For jurisdictions where stablecoin conversion is required before any credit (e.g., regulatory stablecoin-only mandates), the swap is mandatory. For USDC-native corridors, the swap reduces to a no-op — credit USDC directly from the inbound payment.

---

## Pattern 2: Treasury Wallet vs. Personal Wallet

### The Problem

Without workspace-level treasury wallets, every invoice payment, payment-link click, and client deposit lands in the founder's personal embedded wallet. This creates:

- **Co-mingling**: business revenue and personal funds share the same Solana address
- **Audit nightmare**: tracing which deposits were "business" vs "personal" requires side-channel labeling
- **Regulatory risk**: in many jurisdictions, mixing business and personal funds violates money-transmitter licensing terms
- **Operational fragility**: if the founder's wallet key material changes (lost device, revoked access), the entire payment flow breaks

### The Solution

Provision a **workspace-level treasury wallet** per customer/workspace using the embedded wallet API. This is a deterministic key derived from the workspace ID, not a hot wallet with a mnemonic.

```
Workspace created (KYC completed)
          │
          ▼
Embedded wallet API: create_treasury_wallet(workspace_id)
          │
          ▼
Returns: Solana address (e.g., 6F8...AbC)
Stored in your DB: workspace_id → treasury_address
          │
          ▼
All invoice payment links / virtual account numbers
route fiat to this address' associated provider account
```

### Routing Invoices to Treasury Wallets

When generating a payment link or invoice:

```
Invoice created for workspace ABC
  ├── Payment link generated
  ├── Metadata includes: { workspace_id: "abc", invoice_id: "inv_42" }
  └── Underlying fiat deposit goes to the virtual account
      mapped to workspace ABC's treasury wallet
```

On the receiving side, the auto-convert-on-receipt pipeline checks `workspace_id` from the webhook metadata to decide which ledger to credit.

### Crossmint / Privy Example (Solana)

```typescript
// Pseudocode — provision a workspace treasury wallet
import { CrossmintWalletService } from '@crossmint/client-sdk'

const wallet = await CrossmintWalletService.createWallet({
  chain: 'solana',
  walletType: 'treasury',        // isolated treasury wallet
  ownerId: workspace.id,          // scoped to workspace, not user
  features: {
    autoSweep: true,              // auto-convert to USDC
    sweepDestination: treasuryPoolAddress,
  },
})
```

### Solana Account Model Note

Embedded wallets on Solana (Crossmint, Privy, Turnkey) use a delegated program PDA or key-stored-on-server pattern. The treasury wallet's Solana address is a first-class address on-chain — anyone can send USDC to it. The embedded wallet provider holds the signing key. Your application holds a permission layer on top (who can initiate transfers out of the treasury wallet).

---

## Pattern 3: Idempotent Webhook Handling

### The Architecture

```
Provider webhook arrives at /webhooks/:provider
          │
          ▼
  1. Extract provider event ID (idempotency key)
          │
          ▼
  2. Check event_dedupe table:
       ┌─ EXISTS? ──► return 200 OK (already processed)
       └─ NOT EXISTS? ──► proceed
          │
          ▼
  3. BEGIN transaction (DB)
     - Insert event_dedupe row (event_id, status='processing')
     - Create ledger entry (status='pending')
     - COMMIT
          │
          ▼
  4. Process (swap, credit, notify...)
          │
          ▼
  5. On success: update ledger entry status, mark dedupe row as 'completed'
     On failure: mark dedupe row as 'failed', trigger retry queue
```

### Handling Out-of-Order Delivery

Provider webhooks for the same deposit may arrive in any order:

- `payment.intent.succeeded` arrives before `payment.intent.processing`
- `transfer.completed` arrives the next day, hours after the user already saw the credit

**Rule:** process each webhook independently, keyed by its event ID (which encodes the canonical sequence). If a "completed" event arrives without a corresponding "processing" event, process it anyway and backfill the missing ledger state. The `updated_at` on the ledger row resolves the eventual consistency.

### Handling Non-Delivery (Reconciliation Backstop)

Webhooks drop. The provider does not guarantee delivery.

**Reconciliation job** (runs every N hours per provider):

```
1. Fetch all "pending" ledger entries older than TTL
2. Call provider reconciliation API:
     POST /api/v1/reconciliation
     Body: { batch_id, date_range, status_filter }
3. For each provider-side confirmed event not in event_dedupe:
     - Process as if the webhook had arrived
     - Credit user, update dedupe table
4. For each provider-side refunded/cancelled event:
     - If user was credited, reverse the entry
     - Notify user
```

### Storage Schema (PostgreSQL Example)

```sql
CREATE TABLE event_dedupe (
    provider TEXT NOT NULL,
    event_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    PRIMARY KEY (provider, event_id)
);

CREATE TABLE ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id TEXT NOT NULL,
    provider TEXT NOT NULL,
    event_id TEXT NOT NULL UNIQUE,
    entry_type TEXT NOT NULL,       -- 'fiat_in', 'usdc_credit', 'fiat_out'
    fiat_amount NUMERIC NOT NULL,
    fiat_currency TEXT NOT NULL,
    usdc_amount NUMERIC,
    status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'completed', 'failed', 'reversed'
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    settled_at TIMESTAMPTZ
);
```

---

## Pattern 4: Reconciliation Ledger Design

### Why On-Chain Balance Is Not the Truth

The wallet's on-chain USDC balance tells you: "How much USDC does this address hold right now?" It does not tell you:

- Which invoices were paid to generate this balance
- Which payouts are pending against this balance
- Which webhooks have been processed (and which haven't)
- Whether a given deposit was already credited to the user once, twice, or not at all

The internal ledger records the *business event*, not just the *balance change*.

### Why Webhook Delivery Is Not the Truth

Provider webhooks are at-least-once delivery:

- Same event may arrive 2×, 3×, or 5×
- Events may arrive out of order
- Events may arrive hours or days late
- Events may never arrive (reconciliation backstop required)

Internal state transitions are the only way to deduplicate and sequence.

### Ledger-As-Truth Decision Flow

```
User asks: "What is my available balance?"
          │
          ▼
  SELECT SUM(
    CASE WHEN entry_type = 'usdc_credit' THEN usdc_amount
         WHEN entry_type = 'fiat_out' THEN -usdc_amount
         ELSE 0
    END
  )
  FROM ledger_entries
  WHERE workspace_id = 'abc'
    AND status = 'completed'
          │
          ▼
  This is the user's spendable balance.
          │
          ▼
  Cross-check against on-chain wallet balance
  (alert if discrepancy > threshold)
```

### Discrepancy Detection

Schedule a daily/weekly reconciliation job:

```
For each workspace treasury wallet:
  1. Query on-chain USDC balance (via Solana RPC)
  2. Compute ledger balance from completed entries
  3. If |onchain - ledger| > configurable_threshold:
       - Alert operations team
       - Pause automated payouts
       - Flag for manual review
```

Common causes of manageable discrepancies:
- A provider deposit credited on-ledger but USDC not yet received (reconciliation job will pick up the pending entry)
- A user-initiated transfer out of the wallet that bypassed the system (alert, investigate, reverse)
- Gas fees consumed from the treasury wallet (track via a separate `gas_fee` entry type)

---

## Pattern 5: Payout Failure / Retry

### The Problem

Batch payouts fail partially. Some recipients receive USDC; others don't. The naive approach — retry the entire batch — double-pays those who already received.

### Solana-Specific Challenges

- **Blockhash expiry**: a transaction composed 30 seconds ago may be invalid by the time it lands
- **Priority fee spikes**: during congestion, a batch TX may fail because fees were too low
- **Account closure**: if a recipient's associated token account (ATA) doesn't exist, the transfer fails

### Batched Payout Design

```
  Payout batch created (N recipients)
          │
          ▼
  For each recipient:
    1. Validate ATA exists (create if not)
    2. Build instruction
          │
          ▼
  Split into sub-batches of ~20 instructions (TX size limit)
          │
          ▼
  For each sub-batch:
    1. Compose TX with current blockhash
    2. Sign
    3. Send with priority fee estimate
          │
          ▼
  Per-recipient tracking: { address, status: pending/sent/confirmed/failed }
          │
          ▼
  After all sub-batches:
    - Mark confirmed entries as 'completed' in ledger
    - Queue failed entries for retry (exponential backoff, max 3)
    - If retries exhausted: flag for manual review
```

### Retry Strategy

| Attempt | Delay | Action |
|---------|-------|--------|
| 1 | 30s | Re-compose with fresh blockhash, re-send |
| 2 | 5min | Re-compose with higher priority fee |
| 3 | 30min | Re-compose, alert ops if still failing |
| Final | — | Flag for manual review, pause batch |

---

## Solana-Specific Integration Points

| Concern | Solana Mechanism |
|---------|-----------------|
| Embedded wallet provision | Crossmint / Privy / Turnkey — delegated key custody |
| USDC token | SPL-token USDC (EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v) |
| Swap engine | Jupiter Ultra API |
| ATA management | `getAssociatedTokenAddress()` — create if not existing before payout |
| Priority fee | `getRecentPrioritizationFees` or Jupiter fee API |
| Blockhash | `getLatestBlockhash` — must be fresh per TX batch |
| Treasury address derivation | Deterministic PDA or embedded wallet API per workspace ID |
