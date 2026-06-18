# PDA Derivation Cheatsheet

## Common Seed Patterns

```rust
// Per-user per-mint vault
let (pda, bump) = Pubkey::find_program_address(
    &[b"vault", user.as_ref(), mint.as_ref()],
    &program_id,
);

// Time-lock vault
let (pda, bump) = Pubkey::find_program_address(
    &[b"timelock", user.as_ref(), &unlock_time.to_le_bytes()],
    &program_id,
);

// Escrow between two parties
let (pda, bump) = Pubkey::find_program_address(
    &[b"escrow", buyer.as_ref(), seller.as_ref(), &nonce.to_le_bytes()],
    &program_id,
);

// Global vault counter
let (pda, bump) = Pubkey::find_program_address(
    &[b"vault", &next_id.to_le_bytes()],
    &program_id,
);

// Multi-sig proposal
let (pda, bump) = Pubkey::find_program_address(
    &[b"proposal", vault.as_ref(), &slot.to_le_bytes()],
    &program_id,
);
```

## create_program_address vs find_program_address

| Method | Purpose | Can fail? |
|--------|---------|-----------|
| `find_program_address` | Finds the first valid PDA + bump | Never |
| `create_program_address` | Derives PDA with known bump | Yes (wrong bump) |

Always use `find_program_address` for on-chain derivation. Use `create_program_address` only when you already have a verified bump.

## Seed Rules

- Max 16 seed items per PDA
- Each seed item max 32 bytes
- Seeds are case-sensitive byte arrays
- A PDA seed set must produce a point **off** the ed25519 curve
- Bump seed (last seed) iterates from 255 downward until valid

## PDA Signing for CPI

```rust
// Single PDA signer
let seeds = &[b"vault", owner.as_ref(), &[bump]];
invoke_signed(&ix, &accounts, &[&seeds[..]])?;

// Multiple PDA signers
let seeds1 = &[b"vault", owner.as_ref(), &[bump1]];
let seeds2 = &[b"authority", &[bump2]];
invoke_signed(&ix, &accounts, &[&seeds1[..], &seeds2[..]])?;
```

## Anchor Constraint Quick Reference

```rust
#[account(
    init,                                    // Create + zero-initialize
    seeds = [b"vault", owner.key().as_ref()], // PDA seeds
    bump,                                    // Use canonical bump
    payer = owner,                           // Who pays rent
    space = 8 + Vault::INIT_SPACE,           // Account size
    has_one = owner,                         // Check field == account key
    mut,                                     // Writable
    close = owner,                           // Refund rent to owner
    token::mint = vault.mint,                // Token account mint check
    token::authority = vault,                // Token account authority
)]
pub vault: Account<'info, Vault>;
```

## Program IDs

| Program | Address |
|---------|---------|
| Token | `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA` |
| Token-2022 | `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` |
| Associated Token | `ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL` |
| System | `11111111111111111111111111111111` |
