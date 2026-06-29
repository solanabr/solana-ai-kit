# Single-Signer Vault

The basic pattern: one PDA per (user, mint) pair. Each user controls their own vault.

## Vault Account

```rust
use anchor_lang::prelude::*;

#[account]
#[derive(InitSpace)]
pub struct Vault {
    pub owner: Pubkey,
    pub mint: Pubkey,
    pub balance: u64,
    pub bump: u8,
}
```

## Initialize

Seeds: `[b"vault", owner, mint]`

```rust
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        seeds = [b"vault", owner.key().as_ref(), mint.key().as_ref()],
        bump,
        payer = owner,
        space = 8 + Vault::INIT_SPACE
    )]
    pub vault: Account<'info, Vault>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub mint: Account<'info, Mint>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
```

## Deposit

Transfer tokens from user's ATA to vault's ATA. The vault's ATA must have the vault PDA as authority.

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    let vault = &mut ctx.accounts.vault;

    anchor_spl::token::transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            anchor_spl::token::Transfer {
                from: ctx.accounts.user_ata.to_account_info(),
                to: ctx.accounts.vault_ata.to_account_info(),
                authority: ctx.accounts.owner.to_account_info(),
            },
        ),
        amount,
    )?;

    vault.balance = vault.balance.checked_add(amount)
        .ok_or(ProgramError::Custom(1))?;
    Ok(())
}
```

## Withdraw

PDA signs the CPI transfer via invoke_signed.

```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let vault = &ctx.accounts.vault;

    let seeds = &[
        b"vault",
        vault.owner.as_ref(),
        vault.mint.as_ref(),
        &[vault.bump],
    ];
    let signer_seeds = &[&seeds[..]];

    anchor_spl::token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            anchor_spl::token::Transfer {
                from: ctx.accounts.vault_ata.to_account_info(),
                to: ctx.accounts.user_ata.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            signer_seeds,
        ),
        amount,
    )?;

    ctx.accounts.vault.balance = vault.balance.checked_sub(amount)
        .ok_or(ProgramError::Custom(2))?;
    Ok(())
}
```

## Close

Reclaim rent when vault is empty.

```rust
#[derive(Accounts)]
pub struct Close<'info> {
    #[account(
        mut,
        seeds = [b"vault", vault.owner.as_ref(), vault.mint.as_ref()],
        bump = vault.bump,
        has_one = owner,
        close = owner
    )]
    pub vault: Account<'info, Vault>,
    #[account(mut)]
    pub owner: Signer<'info>,
}

pub fn close_vault(ctx: Context<Close>) -> Result<()> {
    let vault = &ctx.accounts.vault;
    require!(vault.balance == 0, VaultError::VaultNotEmpty);
    Ok(())
}
```

## Guidelines

- Always use checked_add/checked_sub on balance
- Verify vault_ata.owner == vault.key() before operations
- Use the close constraint to return rent to owner
- Emit events on deposit and withdraw for indexing
