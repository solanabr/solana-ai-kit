# Time-Lock Vault

Tokens are locked until a specific timestamp. Withdraw is only allowed after unlock_time passes.

## Vault Account

```rust
#[account]
#[derive(InitSpace)]
pub struct TimelockVault {
    pub owner: Pubkey,
    pub mint: Pubkey,
    pub balance: u64,
    pub bump: u8,
    pub unlock_time: i64,
}
```

## Initialize

Seeds: `[b"timelock", owner, &unlock_time.to_le_bytes()]`

Validate unlock_time is in the future.

```rust
pub fn initialize_timelock(ctx: Context<InitializeTimelock>, unlock_time: i64) -> Result<()> {
    let clock = Clock::get()?;
    require!(unlock_time > clock.unix_timestamp, VaultError::InvalidUnlockTime);

    let vault = &mut ctx.accounts.vault;
    vault.owner = ctx.accounts.owner.key();
    vault.mint = ctx.accounts.mint.key();
    vault.balance = 0;
    vault.bump = ctx.bumps.vault;
    vault.unlock_time = unlock_time;
    Ok(())
}
```

## Withdraw (Time-Gated)

Check Clock before allowing withdraw.

```rust
pub fn withdraw_timelock(ctx: Context<WithdrawTimelock>, amount: u64) -> Result<()> {
    let clock = Clock::get()?;
    let vault = &ctx.accounts.vault;

    require!(
        clock.unix_timestamp >= vault.unlock_time,
        VaultError::TokensLocked
    );

    let seeds = &[
        b"timelock",
        vault.owner.as_ref(),
        &vault.unlock_time.to_le_bytes(),
        &[vault.bump],
    ];

    anchor_spl::token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            anchor_spl::token::Transfer {
                from: ctx.accounts.vault_ata.to_account_info(),
                to: ctx.accounts.user_ata.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &[&seeds[..]],
        ),
        amount,
    )?;

    ctx.accounts.vault.balance = vault.balance.checked_sub(amount)
        .ok_or(ProgramError::Custom(3))?;
    Ok(())
}
```

## Key Differences from Basic Vault

- Seeds include unlock_time, not just owner+mint
- Every user can create multiple time-locks with different unlock times
- Use Clock::get() for time checks -- never trust a user-provided timestamp
- Socket-based timing is faster than timestamp-based, use slots for shorter locks

## Common Use Cases

- Token vesting with cliff (team tokens, investor tokens)
- Salary streaming (pay once per month)
- Locked liquidity (LP tokens)
- Locked airdrop claims

## Guidelines

- Validate unlock_time > Clock::get().unix_timestamp at init
- Use i64 for timestamps (Unix epoch seconds)
- For sub-day precision, use Clock::get().slot instead
- Consider allowing early cancellation with a penalty
