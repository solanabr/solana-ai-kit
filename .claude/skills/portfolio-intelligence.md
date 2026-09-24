---
name: portfolio-intelligence
description: Comprehensive Solana portfolio analysis — real-time valuation, risk scoring, cross-protocol yield comparison, impermanent loss estimation, and gas optimization. Uses Jupiter, Kamino, Marginfi, Meteora, Drift data.
user-invocable: true
---

# Portfolio Intelligence

Analyze Solana wallets, assess risk, find yield opportunities, and optimize transactions. Use `/portfolio-intelligence <wallet-address>` to trigger a full report, or invoke individual analysis steps below.

## Quick Reference

| Capability | Data Source | When to Use |
|-----------|------------|-------------|
| Portfolio valuation | Jupiter Price API v6 | Wallet review, net worth tracking |
| Risk assessment | On-chain position analysis | Concentration checks, diversification |
| Yield scanning | Kamino, Marginfi, Meteora, Drift | Deploying idle assets |
| Impermanent loss | Price ratio math | LP position review |
| Gas optimization | Priority fee history | Transaction bundling |

## 1. Portfolio Valuation

### Fetch Full Portfolio
To value a wallet, batch-fetch all token accounts and SOL balance, then get prices via Jupiter:

```typescript
// Get all tokens via Helius DAS API or direct RPC
const tokenAccounts = await connection.getParsedTokenAccountsByOwner(wallet, {
  programId: TOKEN_PROGRAM_ID
});

// Collect mints with non-zero balances
const mints = tokenAccounts.value
  .filter(ta => ta.account.data.parsed.info.tokenAmount.uiAmount > 0)
  .map(ta => ta.account.data.parsed.info.mint);

// Batch price fetch from Jupiter (free, no API key)
const prices = await fetch(
  `https://quote-api.jup.ag/v6/price?ids=${mints.join(',')}`
).then(r => r.json());
```

### SOL Price
```typescript
// SOL mint: So11111111111111111111111111111111111111112
const solPrice = prices.data['So11111111111111111111111111111111111111112']?.price || 0;
```

### Output Format
```json
{
  "walletAddress": "...",
  "solBalance": 10.5,
  "solValueUsd": 1575.00,
  "tokens": [
    {"mint": "...", "symbol": "JUP", "amount": 1000, "priceUsd": 0.50, "valueUsd": 500}
  ],
  "totalValueUsd": 2500.00
}
```

## 2. Risk Assessment

Score wallet health on a 0-100 scale. Each factor reduces the score:

| Risk Factor | Threshold | Score Impact |
|------------|-----------|--------------|
| Single asset >50% | High concentration | -30 |
| Single asset >30% | Moderate concentration | -15 |
| Stablecoin ratio <10% | No dry powder | -10 |
| Stablecoin ratio >60% | Overly conservative | -15 |
| Top 3 assets >80% | Poor diversification | -10 |

### Concentration Analysis
```typescript
function assessRisk(portfolio) {
  const { totalValueUsd, solValueUsd, tokens } = portfolio;
  const allAssets = [
    { symbol: 'SOL', valueUsd: solValueUsd },
    ...tokens.map(t => ({ symbol: t.symbol, valueUsd: t.valueUsd }))
  ].sort((a, b) => b.valueUsd - a.valueUsd);

  const singleAssetRisk = (allAssets[0].valueUsd / totalValueUsd) * 100;
  const top3Share = allAssets.slice(0, 3).reduce((s, a) => s + a.valueUsd, 0) / totalValueUsd * 100;

  // Stablecoin detection
  const stablePattern = /USDC|USDT|DAI|USDH|PYUSD/i;
  const stablecoinRatio = allAssets
    .filter(a => stablePattern.test(a.symbol))
    .reduce((s, a) => s + a.valueUsd, 0) / totalValueUsd * 100;

  return { singleAssetRisk, top3Share, stablecoinRatio };
}
```

## 3. Yield Opportunity Scanning

Compare APY across lending protocols. Priority order: highest APY with acceptable risk.

### Protocol Reference Data (Q4 2026 estimates)

| Protocol | Asset | Typical APY | Risk | Integration |
|----------|-------|-------------|------|-------------|
| Kamino | SOL | 6-10% | Low | kamino.finance API |
| Kamino | USDC | 10-15% | Low | kamino.finance API |
| Marginfi | SOL | 0.3-0.8% | Low | marginfi.com |
| Marginfi | USDC | 6-10% | Low | marginfi.com |
| Meteora DLMM | SOL/USDC | 15-40% | Medium | app.meteora.ag |
| Drift | USDC | 8-12% | Low | app.drift.trade |
| Solayer | SOL | 8-12% | Medium | app.solayer.org |
| JitoSOL | SOL | 7-9% | Low | jito.network |

### Yield Scanner Pattern
```typescript
async function scanYields(portfolio) {
  const assets = portfolio.tokens
    .filter(t => t.valueUsd > 10) // Skip dust
    .map(t => ({ mint: t.mint, symbol: t.symbol }));

  const opportunities = [];

  // Kamino strategies
  try {
    const kamino = await fetch(
      'https://api.kamino.finance/strategies/metrics?env=mainnet-beta'
    ).then(r => r.json());
    // Filter strategies matching portfolio assets, sort by APY
    opportunities.push(...kamino.filter(s => 
      assets.some(a => s.tokenA === a.symbol || s.tokenB === a.symbol)
    ).map(s => ({
      protocol: 'Kamino',
      asset: `${s.tokenA}/${s.tokenB}`,
      apy: s.apy?.total || 0,
      risk: s.apy?.total > 30 ? 'high' : s.apy?.total > 10 ? 'medium' : 'low'

    })));
  } catch { /* Use reference rates from table above */ }

  return opportunities.sort((a, b) => b.apy - a.apy);
}
```

## 4. Impermanent Loss Calculator

For LP positions: `IL = 2 * sqrt(priceRatio) / (1 + priceRatio) - 1`

| Price Change | IL % |
|-------------|------|
| 1.25x | 0.6% |
| 1.50x | 2.0% |
| 2x | 5.7% |
| 3x | 13.4% |
| 5x | 25.5% |
| 10x | 42.5% |

```typescript
function calcIL(entryPriceRatio: number, currentPriceRatio: number): number {
  const ratio = currentPriceRatio / entryPriceRatio;
  return Math.abs(2 * Math.sqrt(ratio) / (1 + ratio) - 1) * 100;
}
```

**Rule of thumb**: LP is profitable only when fees earned > IL. For volatile pairs, expect 15-40% IL. For stable pairs (USDC/USDT), IL is negligible.

## 5. Gas Optimization

### Priority Fee Estimation
```typescript
async function optimizeGas(connection: Connection) {
  const fees = await connection.getRecentPrioritizationFees();
  const sorted = fees
    .map(f => f.prioritizationFee)
    .filter((f): f is number => f > 0)
    .sort((a, b) => a - b);
  
  const median = sorted[Math.floor(sorted.length / 2)] || 5000;
  const recommended = Math.max(median, 10000);

  return {
    currentMedian: median,
    recommended,
    bundleSize: 4 // Jito bundle optimal
  };
}
```

### CU Optimization Rules
- Anchor programs: default 200k CU, optimize with Pinocchio for 80-95% savings
- Token transfers: 50k CU
- Jupiter swaps: 300k-600k CU depending on route complexity
- Always add 20% buffer to CU estimates
- Use `computeUnits` + `prioritizationFee` in transaction config

## Integration Pattern

When building agent skills that need portfolio data:

```typescript
import { Connection, PublicKey } from '@solana/web3.js';

class PortfolioAnalyzer {
  private connection: Connection;

  constructor(rpcUrl: string) {
    this.connection = new Connection(rpcUrl, 'confirmed');
  }

  async analyze(walletAddress: string): Promise<PortfolioReport> {
    // 1. Fetch balances and prices
    // 2. Calculate risk scores
    // 3. Find yield opportunities
    // 4. Estimate gas for rebalancing
    // 5. Generate actionable suggestions
  }
}
```

## Common Patterns

### Rebalance to Target Allocation
When a portfolio is over-concentrated:
1. Identify overweight assets (>target %)
2. Find best exit route (Jupiter swap with lowest slippage)
3. Identify underweight targets
4. Execute in order: sell overweight → buy underweight
5. Use Jito bundles for multi-swap atomic execution

### Deploy Idle Stablecoins
When stablecoin ratio > recommended:
1. Compare lending APY across Kamino, Marginfi, Drift
2. Check utilization rates (high utilization = sustainable APY)
3. Split deposit across 2 protocols for risk management
4. Monitor rates weekly, rotate if spread >3%

## Security Notes

- Never expose private keys in portfolio analysis outputs
- Mask wallet addresses in public reports (show first 4 + last 4 chars)
- Jupiter API is read-only and does not require authentication
- Kamino API has rate limits — cache results for 5 minutes
- All on-chain data is public — no privacy risk in analysis
- For compliance: tag addresses known to be associated with sanctioned entities
