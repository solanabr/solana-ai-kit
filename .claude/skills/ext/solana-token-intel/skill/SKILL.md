---
name: solana-token-intel
description: |
  Token due diligence scanner for Solana. Give it any SPL token mint address and get a
  structured risk assessment: liquidity health, holder distribution, contract authorities,
  market behavior, honeypot detection, and integration readiness. Outputs a risk score
  (1-10) with a stop/go recommendation. Use when a user says "check this token",
  "is this safe", "scan this", "rug check", "should I integrate this token", or pastes
  a Solana address and asks about it.
user-invocable: true
license: MIT
compatibility:
  - claude-code
  - codex
  - hermes-agent
metadata:
  version: "1.0.0"
  chain: solana
  data-sources: [helius, birdeye, jupiter, solana-rpc]
---

# solana-token-intel — Token Due Diligence Scanner

One address in, risk score out. No fluff.

## When To Use

- User pastes a Solana token mint address and asks "is this safe?"
- User wants to know if a token is worth integrating into their protocol
- User asks "check this token", "rug check", "scan this"
- User is considering adding liquidity and wants a safety check

## What This Skill Does NOT Do

- Not a trading bot — no buy/sell signals
- Not a price predictor — no TA or forecasts
- Not an auditor — no smart contract code review
- Not financial advice — user makes their own decision

## Input

Any of these:
- SPL Token mint address (e.g., `DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263`)
- Token symbol (resolve via Jupiter/Birdeye first)
- URL with token address (extract address from URL)

## Output Format

```
🔍 TOKEN INTEL REPORT
━━━━━━━━━━━━━━━━━━━━

Token: [Name] ([Symbol])
Mint: [address]
Chain: Solana

RISK SCORE: [X]/10 [STATUS]

✅ Liquidity: [score]/10 — [one-line]
✅ Holders: [score]/10 — [one-line]
⚠️ Contract: [score]/10 — [one-line]
✅ Market: [score]/10 — [one-line]
❌ Honeypot: [score]/10 — [one-line]

VERDICT: [STOP / CAUTION / GO]
REASON: [one sentence]

━━━━━━━━━━━━━━━━━━━━
```

## Analysis Framework

Run ALL 6 checks. Each produces a sub-score (1-10). Final score = weighted average.

### 1. Liquidity Analysis (weight: 25%)

**Check:**
- Total liquidity in USD (via Birdeye/Jupiter)
- LP token status — burned? locked? unlocked?
- Number of liquidity pools
- Pool age (how long has LP existed?)

**Score:**
| Score | Criteria |
|-------|----------|
| 9-10 | LP burned or locked >1 year, >$500K liquidity, multiple pools |
| 7-8 | LP locked 30-365 days, >$100K liquidity |
| 5-6 | LP unlocked but present, >$50K liquidity |
| 3-4 | Low liquidity (<$50K), LP unlocked |
| 1-2 | Almost no liquidity, or LP removed |

**Data sources:**
```
# Birdeye token overview
GET https://public-api.birdeye.so/defi/token_overview?address={mint}

# Jupiter token list
GET https://tokens.jup.ag/token/{mint}

# Helius DAS API for token metadata
POST https://mainnet.helius-rpc.com/?api-key={KEY}
{"jsonrpc":"2.0","id":1,"method":"getAsset","params":{"id":"{mint}"}}
```

### 2. Holder Intelligence (weight: 20%)

**Check:**
- Top 10 holder concentration (% supply held)
- Number of unique holders
- Distribution pattern (whale-dominated or spread?)
- Known insider/dev wallets

**Score:**
| Score | Criteria |
|-------|----------|
| 9-10 | >10K holders, top 10 hold <20%, healthy distribution |
| 7-8 | >1K holders, top 10 hold <40% |
| 5-6 | >500 holders, top 10 hold <60% |
| 3-4 | <500 holders, top 10 hold >60% |
| 1-2 | <100 holders, top 10 hold >80% (whale-dominated) |

**Data sources:**
```
# Helius getTokenLargestHolders
POST https://mainnet.helius-rpc.com/?api-key={KEY}
{"jsonrpc":"2.0","id":1,"method":"getTokenLargestAccounts","params":["{mint}"]}

# Birdeye holder data
GET https://public-api.birdeye.so/defi/token_holder?address={mint}
```

### 3. Contract Safety (weight: 25%)

**Check:**
- Mint authority — can more tokens be created?
- Freeze authority — can accounts be frozen?
- Upgrade authority — can the program be changed?
- Token extensions (Token-2022 specific risks)

**Score:**
| Score | Criteria |
|-------|----------|
| 9-10 | Mint authority revoked, freeze authority revoked, no upgrade authority |
| 7-8 | Mint authority revoked, freeze authority exists but known multisig |
| 5-6 | Mint authority revoked, freeze authority is EOA |
| 3-4 | Mint authority exists (can inflate supply) |
| 1-2 | Mint + freeze both active EOAs (full control by dev) |

**Data sources:**
```
# Solana RPC — getTokenAccountInfo
POST https://api.mainnet-beta.solana.com
{"jsonrpc":"2.0","id":1,"method":"getAccountInfo","params":["{mint}",{"encoding":"jsonParsed"}]}

# Response fields to check:
# result.value.data.parsed.info.mintAuthority
# result.value.data.parsed.info.freezeAuthority
```

### 4. Market Metrics (weight: 15%)

**Check:**
- 24h volume vs market cap ratio
- Volume consistency (spike = suspicious)
- Number of unique traders
- Price impact on $1K/$10K swap

**Score:**
| Score | Criteria |
|-------|----------|
| 9-10 | Healthy vol/mcap ratio (5-20%), consistent volume, many traders |
| 7-8 | Vol/mcap 20-50%, reasonable consistency |
| 5-6 | Vol/mcap >50% or <1%, some inconsistency |
| 3-4 | Vol/mcap >100% (wash trade suspected), few traders |
| 1-2 | No real volume, or 100%+ daily swings |

**Data sources:**
```
# Birdeye price/volume
GET https://public-api.birdeye.so/defi/price_volume?address={mint}&type=24h

# Jupiter quote for price impact test
GET https://quote-api.jup.ag/v6/quote?inputMint=So11111111111111111111111111111111&outputMint={mint}&amount=1000000000
```

### 5. Honeypot Detection (weight: 10%)

**Check:**
- Can you actually sell? (simulate sell transaction)
- Are there transfer restrictions?
- Is there a blacklist mechanism?
- Does the token have suspicious extensions?

**Score:**
| Score | Criteria |
|-------|----------|
| 9-10 | Sell works normally, no restrictions, no blacklist |
| 7-8 | Sell works but high slippage needed |
| 5-6 | Some transfer restrictions exist |
| 3-4 | Sell fails or requires special conditions |
| 1-2 | Cannot sell — confirmed honeypot |

**Data sources:**
```
# Simulate sell via Jupiter
GET https://quote-api.jup.ag/v6/quote?inputMint={mint}&outputMint=So11111111111111111111111111111111&amount=1000000

# Check token extensions (Token-2022)
POST https://api.mainnet-beta.solana.com
{"jsonrpc":"2.0","id":1,"method":"getAccountInfo","params":["{mint}",{"encoding":"jsonParsed"}]}
# Look for: transferFee, transferHook, permanentDelegate, nonTransferable
```

### 6. Integration Checklist (weight: 5%)

**Check:**
- Token listed on Jupiter? (liquidity routing)
- Token listed on Birdeye? (price feed)
- Token has metadata? (name, symbol, logo)
- Token standard? (SPL vs Token-2022)

**Score:**
| Score | Criteria |
|-------|----------|
| 9-10 | Listed on Jupiter + Birdeye, full metadata, SPL standard |
| 7-8 | Listed on one major DEX, metadata present |
| 5-6 | Tradeable but not listed on aggregators |
| 3-4 | Missing metadata, hard to integrate |
| 1-2 | Non-standard token, no metadata, no DEX listing |

## Risk Score Calculation

```
final_score = (
  liquidity_score * 0.25 +
  holder_score * 0.20 +
  contract_score * 0.25 +
  market_score * 0.15 +
  honeypot_score * 0.10 +
  integration_score * 0.05
)
```

## Verdict Logic

| Score | Verdict | Action |
|-------|---------|--------|
| 8-10 | ✅ GO | Safe to integrate. Low risk. |
| 5-7 | ⚠️ CAUTION | Proceed with care. Monitor closely. |
| 1-4 | 🛑 STOP | High risk. Do not integrate. |

## Quick Commands

**Full scan:**
> "Scan token DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"

**Quick check:**
> "Is this token safe? DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"

**Integration check:**
> "Should I integrate this token into my DeFi protocol? [address]"

## Pitfalls

1. **New tokens lack data.** If token is <24h old, holder and market data may be incomplete. Say so — don't fake a score.
2. **LP burned ≠ safe.** Token can still be a scam even with burned LP (rug via sell tax, blacklist, etc.)
3. **High holders ≠ bad.** Some legitimate tokens have high team allocation (locked vesting). Check lock schedules.
4. **Token-2022 has extra risks.** Transfer hooks, transfer fees, permanent delegate — these are real features but can be abused.
5. **Wash trading is common.** Volume alone doesn't mean real activity. Cross-check with unique trader count.
6. **Jupiter quote failure ≠ honeypot.** Could be low liquidity. Try smaller amounts before concluding.
