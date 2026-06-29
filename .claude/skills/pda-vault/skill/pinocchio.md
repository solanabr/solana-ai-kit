# Pinocchio Vault Implementation

Zero-dependency, zero-copy vault implementation for 88-95% CU reduction.

## Setup

```toml
[dependencies]
pinocchio = "0.10"
pinocchio-token = "0.4"
bytemuck = { version = "1.14", features = ["derive"] }
```

## Vault Account

Fixed-size struct with explicit padding.

```rust
use bytemuck::{Pod, Zeroable};

#[repr(C)]
#[derive(Clone, Copy, Pod, Zeroable)]
pub struct Vault {
    pub discriminator: u8,
    pub owner: [u8; 32],
    pub mint: [u8; 32],
    pub balance: u64,
    pub bump: u8,
    pub _padding: [u8; 7],
}
```

## Read/Write Patterns

Zero-copy via bytemuck. Never clone, always borrow in-place.

```rust
pub fn withdraw(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    data: &[u8],
) -> ProgramResult {
    let [vault_info, vault_ata, user_ata, owner, token_prog] = accounts
    else { return Err(ProgramError::NotEnoughAccountKeys) };

    let vault_data = vault_info.try_borrow_data()?;
    let vault: &Vault = bytemuck::from_bytes(
        &vault_data[..core::mem::size_of::<Vault>()]
    );

    let amount = u64::from_le_bytes(data[..8].try_into().unwrap());
    let seeds = &[b"vault", vault.owner.as_ref(), vault.mint.as_ref(), &[vault.bump]];
    let signer_seeds = &[&seeds[..]];

    pinocchio_token::instructions::Transfer {
        source: vault_ata,
        destination: user_ata,
        authority: vault_info,
        amount,
    }.invoke_signed(signer_seeds)?;

    drop(vault_data);

    let mut vault_data = vault_info.try_borrow_mut_data()?;
    let vault_mut: &mut Vault = bytemuck::from_bytes_mut(
        &mut vault_data[..core::mem::size_of::<Vault>()]
    );
    vault_mut.balance = vault_mut.balance
        .checked_sub(amount)
        .ok_or(ProgramError::InsufficientFunds)?;

    Ok(())
}
```

## Key Differences from Anchor

- No macros -- manual instruction routing via discriminator byte
- Manual account parsing via slice patterns
- Zero-copy data access with bytemuck
- No automatic rent collection -- handle manually
- Always release borrow before taking mutable borrow
