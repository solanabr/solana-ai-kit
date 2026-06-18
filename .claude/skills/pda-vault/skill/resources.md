# Vault Resources

## Seed Patterns Quick Reference

| Strategy | Seeds | Use Case |
|----------|-------|----------|
| User + Mint | `[b"vault", user, mint]` | Per-user per-token vault |
| User + Index | `[b"vault", user, &index.to_le_bytes()]` | Multiple vaults per user |
| Timestamp | `[b"timelock", user, &unlock_time.to_le_bytes()]` | Time-lock positions |
| Counter | `[b"vault", &next_id.to_le_bytes()]` | Global vault counter |
| Escrow | `[b"escrow", buyer, seller, nonce]` | Escrow between two parties |

## PDA Derivation

```rust
// Client side
let (pda, bump) = Pubkey::find_program_address(
    &[b"vault", user_pubkey.as_ref(), mint_pubkey.as_ref()],
    &program_id,
);
```

## Program Addresses

| Program | Address |
|---------|---------|
| System Program | 11111111111111111111111111111111 |
| SPL Token | TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA |
| Token-2022 | TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb |
| Associated Token | ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL |

## Console Derivation (for testing)

```bash
solana address --seed "vault" --seed <USER_PUBKEY> --seed <MINT_PUBKEY> --program-id <PROGRAM_ID>
```
