# Escrow Vault

Two-party settlement: buyer deposits tokens, seller fulfills to receive them, or buyer cancels to get a refund.

## Vault Account

```rust
#[account]
#[derive(InitSpace)]
pub struct EscrowVault {
    pub buyer: Pubkey,
    pub seller: Pubkey,
    pub mint: Pubkey,
    pub escrow_nonce: Pubkey,
    pub expected_amount: u64,
    pub bump: u8,
    pub deposited: bool,
    pub fulfilled: bool,
}
```

## Initialize

Seeds: `[b"escrow", buyer, seller, nonce]`

The nonce allows multiple escrows between the same buyer and seller.

```rust
pub fn initialize_escrow(
    ctx: Context<InitializeEscrow>,
    buyer: Pubkey,
    seller: Pubkey,
    expected_amount: u64,
) -> Result<()> {
    let vault = &mut ctx.accounts.vault;
    vault.buyer = buyer;
    vault.seller = seller;
    vault.mint = ctx.accounts.mint.key();
    vault.expected_amount = expected_amount;
    vault.deposited = false;
    vault.fulfilled = false;
    vault.bump = ctx.bumps.vault;
    vault.escrow_nonce = ctx.accounts.escrow_nonce.key();
    Ok(())
}
```

## Buyer Deposit

Only the buyer can deposit. Allows exactly expected_amount.

```rust
pub fn buyer_deposit(ctx: Context<BuyerDeposit>) -> Result<()> {
    let vault = &mut ctx.accounts.vault;
    require!(!vault.deposited, EscrowError::AlreadyDeposited);

    anchor_spl::token::transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            anchor_spl::token::Transfer {
                from: ctx.accounts.buyer_ata.to_account_info(),
                to: ctx.accounts.vault_ata.to_account_info(),
                authority: ctx.accounts.buyer.to_account_info(),
            },
        ),
        vault.expected_amount,
    )?;

    vault.deposited = true;
    Ok(())
}
```

## Seller Fulfill

Seller claims the tokens. PDA signs the transfer.

```rust
pub fn seller_fulfill(ctx: Context<SellerFulfill>) -> Result<()> {
    let vault = &ctx.accounts.vault;
    require!(vault.deposited, EscrowError::NotDeposited);
    require!(!vault.fulfilled, EscrowError::AlreadyFulfilled);

    let seeds = &[
        b"escrow",
        vault.buyer.as_ref(),
        vault.seller.as_ref(),
        vault.escrow_nonce.as_ref(),
        &[vault.bump],
    ];

    anchor_spl::token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            anchor_spl::token::Transfer {
                from: ctx.accounts.vault_ata.to_account_info(),
                to: ctx.accounts.seller_ata.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &[&seeds[..]],
        ),
        vault.expected_amount,
    )?;

    ctx.accounts.vault.fulfilled = true;
    Ok(())
}
```

## Buyer Cancel

If seller does not fulfill, buyer can refund.

```rust
pub fn buyer_cancel(ctx: Context<BuyerCancel>) -> Result<()> {
    let vault = &ctx.accounts.vault;
    require!(vault.deposited, EscrowError::NotDeposited);
    require!(!vault.fulfilled, EscrowError::AlreadyFulfilled);

    let seeds = &[
        b"escrow",
        vault.buyer.as_ref(),
        vault.seller.as_ref(),
        vault.escrow_nonce.as_ref(),
        &[vault.bump],
    ];

    anchor_spl::token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            anchor_spl::token::Transfer {
                from: ctx.accounts.vault_ata.to_account_info(),
                to: ctx.accounts.buyer_ata.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &[&seeds[..]],
        ),
        vault.expected_amount,
    )?;

    ctx.accounts.vault.fulfilled = true;
    Ok(())
}
```

## Flow States

| State | deposited | fulfilled | Allowed Actions |
|-------|-----------|-----------|-----------------|
| Created | false | false | Buyer deposit |
| Funded | true | false | Seller fulfill, buyer cancel |
| Complete | true | true | None |
| Cancelled | false | true | None |

## Guidelines

- Add a timeout clause so buyer can cancel after N days even without seller action
- Store the expected_amount at init to prevent partial fulfillment
- Use a nonce account in seeds to enable multiple escrows between same parties
- Emit events for each state transition
