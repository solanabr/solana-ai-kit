# Payouts & Payroll

## Bulk Disbursement Batch Design

Bulk disbursement on Solana is not "send N transactions at once." The UX, cost, and reliability constraints are different from Web2 payroll.

### Batch Construction

```
Payout request: N recipients, total X USDC
          │
          ▼
1. Validate balance (ledger, not on-chain)
   └─ Insufficient? → pause batch, alert ops
          │
          ▼
2. Group recipients by:
   - ATA exists vs needs creation
   - Known wallet vs first payout
          │
          ▼
3. For each group:
   Build instructions:
   - createATA (if needed)
   - transfer (USDC)
          │
          ▼
4. Split into sub-batches of ~20 instructions:
   - Solana TX size limit (~1232 bytes)
   - Keep each sub-batch under limit
          │
          ▼
5. For each sub-batch:
   - Fetch fresh blockhash
   - Set priority fee (see fee estimation below)
   - Sign with treasury wallet
   - Send
          │
          ▼
6. Track per-recipient result:
   ┌─ confirmed → ledger: debit USDC, status: completed
   └─ failed → queue for retry
```

### Fee Estimation Strategy

| Traffic Condition | Priority Fee Strategy |
|------------------|---------------------|
| Low congestion | Use `getRecentPrioritizationFees` median |
| Normal | Median + 50% headroom |
| High (launch, airdrop) | Pause batch, alert ops |
| Unknown (no fee data) | Use Jupiter fee API or fixed 0.00001 SOL/instruction |

**Never** hardcode a fixed priority fee. During mempool congestion, fixed fees cause batch-wide failure.

### ATA Pre-Creation

Before sending any USDC to a new Solana address, ensure the associated token account (ATA) exists. If you skip this, the transfer fails.

```typescript
// Pseudocode — check/create ATA before payout
import { getAssociatedTokenAddressSync, createAssociatedTokenAccountInstruction } from '@solana/spl-token'

const ata = getAssociatedTokenAddressSync(USDC_MINT, recipientAddress)
const ataAccountInfo = await connection.getAccountInfo(ata)

if (!ataAccountInfo) {
  instructions.push(
    createAssociatedTokenAccountInstruction(
      treasuryWallet.publicKey,  // fee payer
      ata,
      recipientAddress,
      USDC_MINT
    )
  )
}
instructions.push(createTransferInstruction(...))
```

## Invoice Payment Routing

### Payment Link Generation

```
Invoice created (inv_42, workspace ABC, 500 USDC due)
          │
          ▼
Generate payment link:
  - Unique URL: https://pay.app/inv_42
  - Linked to workspace ABC's treasury wallet
  - Amount: 500 USDC (or fiat equivalent + FX rate lock)
  - Metadata: { invoice_id: "inv_42", workspace_id: "abc" }
          │
          ▼
Send to customer via email/SMS/WhatsApp
```

### FX Rate Lock Timing

Critical decision with operational consequences:

| Strategy | How It Works | Risk |
|----------|-------------|------|
| **Lock at link generation** | Rate is set when payment link is created. Customer pays in fiat; you guarantee USDC amount. | If fiat depreciates between link creation and settlement, you receive less USDC than promised. |
| **Lock at payment initiation** | Rate is set when customer clicks the link / starts the payment. | If the customer starts but doesn't complete, the rate expires. |
| **Lock at settlement** | Rate is set when fiat arrives at provider. | Customer sees a floating amount — poor UX. |

**Recommendation:** Lock at payment initiation, with a 15-minute expiry. This gives the customer time to complete the bank transfer (if instant) or card payment, while limiting your FX exposure window.

### Underpayment / Overpayment

Fiat payments rarely match the invoice amount exactly. Bank fees, FX rounding, and partial payments create discrepancies.

**Approach:**
- Define a tolerance threshold (e.g., ±2% of invoice total)
- Within tolerance: accept the payment, log the difference as "FX variance" (tracked for reconciliation)
- Outside tolerance: flag for manual review, notify both parties
- Record the actual vs expected delta in the ledger entry

## Payroll-Specific Reconciliation

### The Ledger vs. On-Chain Gap

Payroll cycles create a divergence between the internal ledger and on-chain wallet balance:

1. **Pre-funding**: Company deposits bulk USDC into treasury wallet → on-chain balance is N, ledger balance is N (match)
2. **Instruction generation**: Payroll instructions are composed (may take minutes for N>100)
3. **Submission**: Batches are submitted; some confirm, some fail, some are pending
4. **Settlement window**: During submission, on-chain balance is partially debited, ledger is partially credited

The ledger must track individual instruction states:

```
recipient_a: { status: "pending_submission" }
recipient_b: { status: "pending_submission" }
...
          │
          ▼
TX1 (recipients a-j): sent, confirmed
  recipient_a: { status: "completed", tx: "sig1" }
  recipient_b: { status: "completed", tx: "sig1" }
...
TX2 (recipients k-t): sent, failed (blockhash expired)
  recipient_k: { status: "retry_1", scheduled: +30s }
```

### Finality Reconciliation

After the payroll cycle completes:
1. Sum all `completed` debit entries = total USDC deducted from treasury
2. Query on-chain USDC balance of treasury wallet
3. If (pre_balance - ledger_debits) ≈ onchain_balance → settled
4. If discrepancy > threshold → alert, investigate

Common payroll-specific discrepancies:
- **Gas fees**: treasury wallet paid SOL for TX fees, reducing USDC-available SOL. Track separately.
- **Failed retries**: three retries exhausted, recipient not paid. Needs manual intervention.
- **ATA creation cost**: creating a new ATA costs 0.002039 SOL. If SOL was purchased from treasury USDC, this reduces the visible USDC balance.

### Idempotency in Payroll

Each payroll run must be idempotent. The worst outcome is paying a recipient twice:

```typescript
// Payroll run request includes idempotency key
POST /api/payroll/run
Body: {
  payroll_id: "pr_2026_06_20",
  workspace_id: "abc",
  idempotency_key: "pr_2026_06_20_abc_v1"
}

// Backend checks:
const existing = db.query("SELECT status FROM payroll_runs WHERE idempotency_key = $1")
if (existing && existing.status === 'completed') {
  return { status: 'already_processed' }
}
if (existing && existing.status === 'in_progress') {
  return { status: 'in_progress', retry_after: 30 }
}
```

### Payout Notification

After payout confirmation:

```
Per successful recipient:
  - Update ledger: status → completed, add tx_signature
  - Emit: "payout sent" event (webhook to customer app, push notification, email)
  - If ATA was created: log for gas cost tracking

Per failed recipient (after retries exhausted):
  - Update ledger: status → failed
  - Emit: "payout failed" event
  - Queue for manual review
  - Do NOT auto-retry (avoid double-pay risk on recovery)
```
