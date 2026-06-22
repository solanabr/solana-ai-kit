# Virtual Accounts on Solana

## What a Virtual Account Actually Is

A virtual account is a real bank account number or mobile-money wallet ID issued by a licensed payment partner, mapped 1:1 to a Solana wallet or sub-ledger entry. The provider gives you an account number (e.g., `1234567890` for NGN transfers). When a customer sends money to that number, the provider notifies you via webhook and the funds appear as a USDC balance on your Solana treasury address.

**Not a Solana account.** No on-chain entity corresponds to the virtual account number. It is a *mapping in your application database*:

| Provider Account Number | Solana Wallet Address | Owner |
|------------------------|----------------------|-------|
| `1234567890` | `6F8...AbC` (Treasury) | Workspace ABC |
| `1234567891` | `6F8...AbC` (Treasury) | Workspace DEF |

Multiple virtual accounts can map to the same Solana wallet (the provider aggregates inbound deposits before settling). The `webhook.metadata.virtual_account_id` tells you which customer the deposit belongs to.

## Provisioning Flow

```
User completes KYC (tier 2+)
          │
          ▼
Application requests virtual account from provider:
  POST /api/v1/virtual_accounts
  Body: { 
    customer_id, 
    currency: "NGN", 
    bank_code: "058",   // GTBank
    wallet_address: "6F8...AbC"
  }
          │
          ▼
Provider issues account number:
  Response: { 
    account_number: "1234567890", 
    bank_name: "Guaranty Trust Bank",
    provider_reference: "va_abc_123"
  }
          │
          ▼
Store mapping:
  DB: virtual_accounts
  - account_number: "1234567890"
  - workspace_id: "abc"
  - currency: "NGN"
  - provider_reference: "va_abc_123"
  - treasury_wallet: "6F8...AbC"
  - status: "active"
          │
          ▼
Return account details to customer for deposits
```

## Webhook on Deposit

```
Provider callback: DEPOSIT
  { 
    virtual_account_id: "va_abc_123",
    amount: 50000,
    currency: "NGN",
    sender_name: "Chinua Achebe",
    reference: "dep_ref_999"
  }
          │
          ▼
1. Dedupe on reference
2. Look up workspace_id from virtual_account_id
3. Create ledger entry: 50000 NGN fiat receivable
4. Trigger auto-convert: NGN → USDC (via Yellow Card / Crossmint)
5. On USDC receipt: credit workspace internal balance
6. Emit: "payment received" notification
```

## Multi-Currency Considerations

| Model | How It Works | Pros | Cons |
|-------|-------------|------|------|
| **Per-currency VA** | Each currency (NGN, KES, GHS) gets its own virtual account per customer | Clear reconciliation per currency | Customer manages N account numbers |
| **Pooled settlement** | All currencies flow to one fiat pool, converted to USDC at provider level | Single VA per customer | Harder to track FX rates per deposit |
| **Hybrid** | Per-currency VA at the provider; provider aggregates and settles USDC to a single Solana address | Best of both — per-currency traceability, single settlement | More complex provider integration |

## Common Pitfalls

### Account Collisions

**Problem:** Provider re-issues the same account number to two different customers (rare but happens during migration or namespace recycling).

**Mitigation:** Dedupe on `provider_reference` (immutable), not `account_number`. If the same account number appears with a different `provider_reference`, treat as a new VA and deactivate the old one.

### Dormant Account Cleanup

**Problem:** Customers request VAs, never use them, but they count against provider rate limits and licensing fees.

**Mitigation:** Implement a lifecycle:
```
active → inactive (no activity 90d) → archived (no activity 180d) → closed
```
Archiving: remove VA at provider, mark `status: archived` in DB.
If the customer deposits to an archived VA, the provider typically returns the funds. Handle as an exception flow.

### KYC-Tier Gating

**Problem:** You provision a VA before the customer completes KYC, and the first deposit triggers a compliance review that blocks settlement.

**Mitigation:** Only provision VAs after the customer reaches the KYC tier required by your provider. This is usually tier 2 or higher (ID + selfie + proof of address). See [compliance-flags.md](compliance-flags.md) for detail.

### Provider Dependency

**Problem:** The VA provider goes down during a reconciliation run, or changes its VA format mid-cycle.

**Mitigation:**
- Maintain a `provider_status` cache (polled or webhook-driven) showing whether each provider's VA system is operational
- Keep the `account_number` column as `TEXT` (providers sometimes switch from numeric to alphanumeric)
- Log raw provider response for every VA provisioning call
