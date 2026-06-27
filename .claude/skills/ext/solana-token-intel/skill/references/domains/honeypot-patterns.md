# Honeypot Patterns — Solana

Known patterns that indicate a token is a honeypot (can buy, cannot sell).

## Definite Honeypots

### 1. Non-Transferable Token (Token-2022)
- Extension: `nonTransferable`
- Effect: Token can NEVER be transferred after initial distribution
- Detection: Check token extensions in account data
- Risk: 10/10 — confirmed scam

### 2. Permanent Delegate (Token-2022)
- Extension: `permanentDelegate`
- Effect: Delegate can burn or transfer ANY holder's tokens at any time
- Detection: Check if `delegate` field is set to an EOA
- Risk: 9/10 — dev can drain everyone

### 3. Transfer Hook with Blacklist (Token-2022)
- Extension: `transferHook`
- Effect: Custom program runs on every transfer — can blacklist sellers
- Detection: Check hook program code for blacklist logic
- Risk: 8/10 — selective scamming

### 4. Transfer Fee = 100% (Token-2022)
- Extension: `transferFee` with `maximumFee` = supply
- Effect: Selling burns 100% of tokens as fee
- Detection: Check transferFee config
- Risk: 9/10 — can never recover value

## Likely Honeypots

### 5. Freeze Authority Active + Used
- Mint has freeze authority set to EOA
- Dev has frozen seller accounts before
- Detection: Check freeze authority + recent freeze transactions
- Risk: 8/10

### 6. Mint Authority Active
- More tokens can be minted at any time
- Dev can dump infinite supply
- Detection: `mintAuthority` is not null
- Risk: 7/10 (not honeypot per se, but inflation rug)

### 7. Hidden Supply Manipulation
- Large hidden wallets that dump on buyers
- Pre-minted supply distributed to insider wallets
- Detection: Top holder analysis, check creation transactions
- Risk: 6/10

## False Positives (NOT honeypots)

### Legitimate Transfer Fees
- Token-2022 transfer fees <5% are often legitimate (protocol revenue)
- Check if fee recipient is a known treasury/multisig

### Legitimate Freeze Authority
- Stablecoins (USDC, USDT) have freeze authority for compliance
- Check if issuer is a known regulated entity

### Low Liquidity Sell Failures
- Sell transaction fails due to slippage, not honeypot
- Try smaller amounts or higher slippage tolerance
