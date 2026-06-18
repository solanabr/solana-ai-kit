# solana-token-intel

Token due diligence scanner for the [Solana AI Kit](https://github.com/solanabr/solana-ai-kit).

Give it any SPL token mint address → get a structured risk assessment with a 1-10 score and stop/go recommendation.

## What It Does

| Check | Weight | What It Analyzes |
|-------|--------|-----------------|
| Liquidity Analysis | 25% | LP depth, lock status, pool health |
| Holder Intelligence | 20% | Top holders, concentration, distribution |
| Contract Safety | 25% | Mint/freeze/upgrade authority, Token-2022 extensions |
| Market Metrics | 15% | Volume, wash trading, price impact |
| Honeypot Detection | 10% | Sell restrictions, blacklist, transfer hooks |
| Integration Readiness | 5% | DEX listing, metadata, standard compliance |

## Usage

```
# Full scan
"Scan token DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"

# Quick check
"Is this safe? DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"

# Integration check
"Should I integrate this token? DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"
```

## Output

```
🔍 TOKEN INTEL REPORT
━━━━━━━━━━━━━━━━━━━━

Token: Bonk (BONK)
Mint: DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263

RISK SCORE: 7/10 ⚠️ CAUTION

✅ Liquidity: 8/10 — Deep pools, LP partially locked
✅ Holders: 7/10 — 700K+ holders, moderate whale concentration
✅ Contract: 9/10 — Mint + freeze authority revoked
⚠️ Market: 6/10 — High volume but some wash trading signals
✅ Honeypot: 10/10 — Fully tradeable, no restrictions
✅ Integration: 10/10 — Listed everywhere, full metadata

VERDICT: GO
REASON: Legitimate meme token with renounced authorities and deep liquidity.
```

## Installation

```bash
chmod +x install.sh && ./install.sh
```

## Data Sources

- **Solana RPC** — Contract state (mint/freeze authority)
- **Birdeye** — Market data (liquidity, volume, holders)
- **Jupiter** — Tradeability (quote tests, token list)
- **Helius** — Enhanced metadata (DAS API)
- **Solscan** — Fallback data source

## Files

```
skill/
  SKILL.md                              ← Main skill definition
  references/
    domains/
      honeypot-patterns.md              ← Known honeypot patterns
      data-sources.md                   ← API reference
    workflows/
      scan-workflow.md                  ← Step-by-step scan process
```

## Contributing

PRs welcome. Focus on:
- New honeypot patterns as they emerge
- Additional data sources
- Better scoring algorithms
- More jurisdictions for compliance checks

## License

MIT
