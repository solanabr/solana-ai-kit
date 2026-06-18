use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount};

declare_id!("TLock11111111111111111111111111111111111111");

#[program]
pub mod time_lock_vault {
    use super::*;

    pub fn initialize(
        ctx: Context<Initialize>,
        unlock_time: i64,
    ) -> Result<()> {
        let clock = Clock::get()?;
        require!(
            unlock_time > clock.unix_timestamp,
            VaultError::InvalidUnlockTime
        );

        let vault = &mut ctx.accounts.vault;
        vault.owner = ctx.accounts.owner.key();
        vault.mint = ctx.accounts.mint.key();
        vault.balance = 0;
        vault.bump = ctx.bumps.vault;
        vault.unlock_time = unlock_time;
        Ok(())
    }

    pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
        let vault = &mut ctx.accounts.vault;

        token::transfer(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                token::Transfer {
                    from: ctx.accounts.user_ata.to_account_info(),
                    to: ctx.accounts.vault_ata.to_account_info(),
                    authority: ctx.accounts.owner.to_account_info(),
                },
            ),
            amount,
        )?;

        vault.balance = vault.balance.checked_add(amount).unwrap();
        Ok(())
    }

    pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
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

        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                token::Transfer {
                    from: ctx.accounts.vault_ata.to_account_info(),
                    to: ctx.accounts.user_ata.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                },
                &[&seeds[..]],
            ),
            amount,
        )?;

        ctx.accounts.vault.balance = vault
            .balance
            .checked_sub(amount)
            .unwrap();
        Ok(())
    }
}

#[account]
#[derive(InitSpace)]
pub struct Vault {
    pub owner: Pubkey,
    pub mint: Pubkey,
    pub balance: u64,
    pub bump: u8,
    pub unlock_time: i64,
}

#[derive(Accounts)]
#[instruction(unlock_time: i64)]
pub struct Initialize<'info> {
    #[account(
        init,
        seeds = [b"timelock", owner.key().as_ref(), &unlock_time.to_le_bytes()],
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

#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(
        mut,
        seeds = [b"timelock", vault.owner.as_ref(), &vault.unlock_time.to_le_bytes()],
        bump = vault.bump
    )]
    pub vault: Account<'info, Vault>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = vault
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = owner
    )]
    pub user_ata: Account<'info, TokenAccount>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(
        mut,
        seeds = [b"timelock", vault.owner.as_ref(), &vault.unlock_time.to_le_bytes()],
        bump = vault.bump,
        has_one = owner
    )]
    pub vault: Account<'info, Vault>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = vault
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = owner
    )]
    pub user_ata: Account<'info, TokenAccount>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[error_code]
pub enum VaultError {
    #[msg("Tokens are still locked")]
    TokensLocked,
    #[msg("Invalid unlock time")]
    InvalidUnlockTime,
}
