# Compliance Flags — Engineering Guidance Only

> **⚠️ This is not legal advice. No licensing determinations are made here.**
>
> This document describes engineering-level compliance *flagging* — places where your code
> intersects with regulatory obligations. Whether those obligations apply to you depends on
> the jurisdictions you operate in, the volume you process, the custody model you use, and
> the findings of a qualified legal review.
>
> Defer jurisdiction-specific licensing questions to a crypto-legal-skill or real counsel.

## Travel Rule (FATF Recommendation 16)

### What It Is

The Travel Rule requires originator and beneficiary information to be transmitted with
virtual asset transfers above a threshold (typically ~$1,000 USD or equivalent, varies by
jurisdiction). This applies to fiat-to-stablecoin ramps and stablecoin-to-stablecoin
transfers between VASPs (Virtual Asset Service Providers).

### Engineering Hook Points

| Flow | Travel Rule Trigger | What to Capture |
|------|-------------------|-----------------|
| Onramp (fiat → USDC) | Value > local threshold | Sender name, address, DOB, purpose of payment |
| Offramp (USDC → fiat) | Value > local threshold | Beneficiary name, receiving institution |
| Wallet-to-wallet (within your system) | Value > threshold | Both sender and receiver details |
| Wallet-to-external (to another VASP) | Value > threshold (varies by destination jurisdiction) | Sender details transmitted via provider's travel-rule API |

### Integration Pattern

```typescript
// Hook point: before executing any transfer above threshold
function checkTravelRule(transfer: Transfer): TravelRuleResult {
  if (transfer.amount > TRAVEL_RULE_THRESHOLD_USD) {
    const senderInfo = await getVerifiedSenderInfo(transfer.senderWorkspaceId)
    const beneficiaryInfo = await getBeneficiaryInfo(transfer)
    // Transmit via provider's travel rule API (or refuse if provider doesn't support)
    return await provider.transmitTravelRuleInfo({
      sender: senderInfo,
      beneficiary: beneficiaryInfo,
      amount: transfer.amount,
      currency: 'USDC',
      chain: 'solana',
    })
  }
  return { required: false }
}
```

**Provider Support:** Yellow Card, Crossmint, and Bridge.xyz provide travel-rule data
transmission. Verify with your provider that their API handles transmission to the
beneficiary VASP before building custom infrastructure.

## Sanctions Screening

### When to Screen

- **Before credit**: screen the sender when a fiat deposit webhook arrives. If the sender
  is on a sanctions list, do not credit. Place funds in a suspense ledger.
- **Before payout**: screen the recipient before initiating a USDC transfer or fiat
  payout. If the recipient is sanctioned, block the transfer.
- **Not after**: crediting first and screening later means you've already facilitated a
  sanctioned transaction. The penalty for sanctions violations is strict-liability in
  most regimes — intent is irrelevant.

### Integration Points

```
Webhook: fiat deposit received from sender S
          │
          ▼
Screen S against OFAC SDN, EU consolidated, UN sanctions lists
  ┌─ MATCH (or fuzzy match > threshold) → freeze in suspense ledger, alert compliance
  └─ CLEAR → proceed with auto-convert
```

### Fuzzy Matching

Sanctions screening is not exact string matching. The sender name "Jonh Doe" might be
"John Doe" on the sanctions list. Use a fuzzy matching library or provider screening API
that handles:

- Spelling variations (Mohammad / Mohammed / Muhammad)
- Name reversal (Doe, John / John Doe)
- Partial matches (John / Johnathan Doe)
- Date-of-birth cross-validation

## KYC-Tier Gating

### Tier Model (Common Pattern)

| Tier | Requirements | Permitted Actions |
|------|-------------|-------------------|
| 0 | Email + phone | Deposit up to daily limit (~$100) |
| 1 | Government ID + selfie | Deposit up to monthly limit (~$1,000) |
| 2 | ID + proof of address + liveness check | Unlimited deposits, virtual account provisioning |
| 3 | Business verification (director ID, proof of registration) | Payout initiation, treasury wallet management |

### Gating Logic

```typescript
function canProvisionVirtualAccount(workspaceId: string): boolean {
  const kycTier = await getWorkspaceKYCTier(workspaceId)
  return kycTier >= KYC_TIER.TIER_2  // VA provisioning requires tier 2+
}

function canInitiatePayout(workspaceId: string, amount: number): boolean {
  const kycTier = await getWorkspaceKYCTier(workspaceId)
  if (kycTier < KYC_TIER.TIER_3) return false  // payouts require business tier
  if (amount > DAILY_PAYOUT_LIMIT && kycTier < KYC_TIER.TIER_3) return false  // or per-tier limits
  return true
}
```

## Record Retention

Most regulations require retaining transaction records for 5 years (FATF recommendation)
or longer in some jurisdictions.

### Minimum Data to Retain

| Field | Source | Retention |
|-------|--------|-----------|
| Provider event ID | Provider webhook | 5+ years |
| Full webhook payload | Provider webhook | 5+ years |
| Sender identity (name, address, ID) | KYC provider | 5+ years post-account closure |
| Beneficiary details (payouts) | Application | 5+ years |
| IP addresses (web sessions) | Application logs | 2+ years |
| KYC verification result + timestamps | KYC provider | 5+ years post-account closure |

### Implementation

```sql
-- Never delete, only soft-delete or archive
UPDATE ledger_entries SET archived_at = NOW() WHERE created_at < NOW() - INTERVAL '5 years';
-- Data is preserved but not in hot tables
```

## Jurisdiction-Specific Flags

| Concern | Flag This | Don't Resolve |
|---------|-----------|---------------|
| Is onramping fiat → USDC a money transmission? | If any corridor requires a license | Determine which license; ask counsel |
| Is holding customer USDC a custodial service? | If embedded wallet provider returns signing keys to you vs the user | Classify custody model; ask counsel |
| What tax event is the USDC conversion? | If fiat → USDC is a disposal for capital gains purposes | Determine tax treatment; ask tax advisor |
| Are payouts to non-crypto-native users regulated? | If sending USDC from treasury to users who then offramp | Determine regulatory scope; ask counsel |

## Trust but Verify

Flag everything here for review by a qualified compliance professional or legal team
before shipping to production. This document identifies *where* to look, not *what* to do.
