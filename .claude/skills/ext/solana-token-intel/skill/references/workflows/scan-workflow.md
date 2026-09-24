# Token Scan Workflow

Step-by-step process when user provides a token address.

## Step 1: Validate Input

```
User provides: [address or symbol]

IF symbol → resolve to mint address via Jupiter token list
IF URL → extract address from URL
IF invalid address → ask for valid Solana address

Confirm: "Scanning [token name] ([mint])..."
```

## Step 2: Contract Safety Check (Fastest — do first)

```
1. Call getAccountInfo on mint address
2. Extract: mintAuthority, freezeAuthority, supply, decimals
3. Check Token-2022 extensions if applicable
4. Score contract safety

IF mintAuthority is null AND freezeAuthority is null:
   → Contract is renounced (good sign)
IF mintAuthority is set:
   → Flag: "Dev can mint more tokens"
IF freezeAuthority is set:
   → Flag: "Dev can freeze accounts"
```

## Step 3: Liquidity Check

```
1. Call Birdeye token_overview
2. Extract: liquidity_usd, number of pools
3. Check LP status via pool account data
4. Score liquidity

Key question: "Is there enough liquidity to exit?"
```

## Step 4: Holder Analysis

```
1. Call getTokenLargestAccounts
2. Calculate top 10 concentration
3. Count total holders
4. Score holder distribution

Key question: "Can one wallet dump everything?"
```

## Step 5: Market Check

```
1. Call Birdeye price_volume
2. Calculate vol/mcap ratio
3. Check unique traders
4. Score market health

Key question: "Is this real trading or wash trading?"
```

## Step 6: Honeypot Check

```
1. Get Jupiter quote (sell small amount)
2. If quote succeeds → likely not honeypot
3. If quote fails → try smaller amount
4. If all amounts fail → flag as potential honeypot
5. Check Token-2022 extensions for dangerous patterns
6. Score honeypot risk

Key question: "Can you actually sell?"
```

## Step 7: Integration Readiness

```
1. Check Jupiter listing
2. Check Birdeye listing
3. Check metadata completeness
4. Score integration readiness

Key question: "Can you easily integrate this into your app?"
```

## Step 8: Generate Report

```
Calculate final score:
final = (liquidity * 0.25) + (holders * 0.20) + (contract * 0.25) + 
        (market * 0.15) + (honeypot * 0.10) + (integration * 0.05)

Determine verdict:
8-10 → ✅ GO
5-7 → ⚠️ CAUTION
1-4 → 🛑 STOP

Output formatted report
```

## Error Handling

| Error | Action |
|-------|--------|
| Token not found | "This address is not a valid SPL token mint." |
| No liquidity data | "Cannot determine liquidity — token may be too new." |
| RPC timeout | Retry once, then use cached/fallback data |
| All quotes fail | "Unable to get sell quote — proceed with extreme caution." |
| Token-2022 with hooks | "Token has transfer hooks — manual review recommended." |
