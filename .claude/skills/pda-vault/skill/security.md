# Vault Security Checklist

## Critical

- Reinitialization guard: check discriminator != 0 before init in native, use Anchor init constraint
- PDA seed verification: every seed component must match expected values
- Signer verification: verify the caller is the vault owner or authorized signer
- Balance tracking: use checked_add/checked_sub, never allow underflow
- PDA ownership: verify vault_ata.owner == vault.key() before any token operation
- CPI program ID: verify token_program.key() is the expected Token or Token-2022 address

## Moderate

- Account closure: use close constraint to reclaim rent, verify balance == 0 before close
- Compute budget: set priority fees for vault operations on mainnet
- Rent exemption: vault accounts must be rent-exempt
- Mint validation: verify vault.mint matches the token account mint
- Event emissions: emit events on deposit, withdraw, and state changes for indexing

## Common Vulnerabilities

| Vulnerability | How It Happens | Prevention |
|---------------|---------------|------------|
| Reinitialization | Calling init on an already-initialized account | Check discriminator or use Anchor init constraint |
| PDA theft | Wrong seeds allow anyone to derive the PDA | Verify every seed component |
| Balance underflow | balance - amount when balance < amount | Use checked_sub |
| Token theft | vault_ata owner changed | Verify vault_ata.owner == vault.key() |
| CPI reentrancy | Malicious program called back | verify program_id in CPI |
| Rent griefing | Attacker closes vault with funds | Check balance == 0 before close |

## Secure Seed Patterns

```rust
// Good: all seed components verified on-chain
let (pda, bump) = Pubkey::find_program_address(
    &[b"vault", owner.as_ref(), mint.as_ref()],
    &program_id,
);

// Bad: user controls seeds -- can claim any PDA
let (pda, bump) = Pubkey::find_program_address(
    &[user_provided_seed],
    &program_id,
);
```
