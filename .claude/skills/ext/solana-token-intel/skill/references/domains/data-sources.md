# Data Source Quick Reference

All endpoints used by solana-token-intel.

## 1. Solana RPC (Free, public)

```
Endpoint: https://api.mainnet-beta.solana.com

# Get token mint info
Method: getAccountInfo
Params: ["<mint_address>", {"encoding": "jsonParsed"}]
→ Returns: mintAuthority, freezeAuthority, supply, decimals

# Get largest holders
Method: getTokenLargestAccounts
Params: ["<mint_address>"]
→ Returns: Top holders by balance

# Simulate transaction (for honeypot check)
Method: simulateTransaction
Params: ["<serialized_tx>", {"encoding": "base64"}]
→ Returns: success/failure + logs
```

## 2. Helius (API key required)

```
Endpoint: https://mainnet.helius-rpc.com/?api-key=<KEY>

# Enhanced token metadata
Method: getAsset (DAS API)
Params: {"id": "<mint_address>"}
→ Returns: Full metadata, creators, authorities

# Token holders with metadata
Method: getTokenLargestAccounts
Same as Solana RPC but with enhanced data
```

## 3. Birdeye (API key required)

```
Endpoint: https://public-api.birdeye.so

# Token overview (liquidity, volume, price)
GET /defi/token_overview?address=<mint>

# Price + volume history
GET /defi/price_volume?address=<mint>&type=24h

# Token holders
GET /defi/token_holder?address=<mint>

# Token security info
GET /defi/token_security?address=<mint>
```

## 4. Jupiter (Free, no key)

```
Endpoint: https://quote-api.jup.ag/v6

# Get quote (price impact test)
GET /quote?inputMint=<input>&outputMint=<output>&amount=<lamports>
→ Returns: price, priceImpact, slippage

# Token list (metadata)
GET https://tokens.jup.ag/token/<mint>

# Check if token is tradeable
If quote returns error → token may not be tradeable
```

## 5. Solscan (Free, optional)

```
Endpoint: https://public-api.solscan.io

# Token holders
GET /token/holders?tokenAddress=<mint>

# Token meta
GET /token/meta?tokenAddress=<mint>
```

## Rate Limits

| Source | Free Tier | Notes |
|--------|-----------|-------|
| Solana RPC | 40 req/sec | Public endpoint, may be slow |
| Helius | 10 req/sec | Free tier available |
| Birdeye | 30 req/sec | Free tier available |
| Jupiter | Unlimited | No auth needed |
| Solscan | 5 req/sec | Very limited |

## Recommended Flow

1. **First**: Solana RPC for contract data (mint/freeze authority)
2. **Second**: Birdeye for market data (liquidity, volume)
3. **Third**: Jupiter for tradeability check (quote test)
4. **Fourth**: Helius for enhanced metadata (if available)
5. **Fallback**: Solscan if other sources fail
