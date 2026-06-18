## What This Adds

A token safety scanner skill for the Solana AI Kit that analyzes any SPL token across 6 dimensions:

1. **Liquidity Analysis** (25%) — LP depth, lock status, pool health
2. **Holder Intelligence** (20%) — Top holders, concentration, distribution
3. **Contract Safety** (25%) — Mint/freeze authority, Token-2022 extensions
4. **Market Metrics** (15%) — Volume patterns, wash trading detection
5. **Honeypot Detection** (10%) — Sell restrictions, blacklist, transfer hooks
6. **Integration Readiness** (5%) — DEX listing, metadata completeness

Outputs a **risk score (1-10)** with a stop/go recommendation.

## Why This Matters

Builders evaluate tokens daily before integrating them into protocols or adding liquidity. No existing skill in the kit provides this analysis. This fills a real gap between "build" and "ship" — knowing which tokens are safe to work with.

## Files

- `skill/SKILL.md` — Main skill definition with scoring framework
- `skill/references/domains/honeypot-patterns.md` — Known honeypot patterns
- `skill/references/domains/data-sources.md` — API reference (Solana RPC, Birdeye, Jupiter, Helius)
- `skill/references/workflows/scan-workflow.md` — Step-by-step scan process
- `README.md` — Documentation
- `install.sh` — Easy install script

## Data Sources

- Solana RPC (contract state)
- Birdeye (market data)
- Jupiter (tradeability)
- Helius (enhanced metadata)
- DexScreener (fallback)

## Compatible With

- Claude Code
- Codex
- Hermes Agent
