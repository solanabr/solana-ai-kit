use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount};

declare_id!("Escrw111111111111111111111111111111111111111");

#[program]
pub mod escrow_vault {
    use super::*;

    pub fn initialize(
        ctx: Context<Initialize>,
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

    pub fn buyer_deposit(ctx: Context<BuyerDeposit>) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        require!(!vault.deposited, EscrowError::AlreadyDeposited);

        token::transfer(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                token::Transfer {
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

        // Transfer tokens to seller
        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                token::Transfer {
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

        // Refund buyer
        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                token::Transfer {
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
}

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

#[derive(Accounts)]
#[instruction(buyer: Pubkey, seller: Pubkey)]
pub struct Initialize<'info> {
    #[account(
        init,
        seeds = [b"escrow", buyer.as_ref(), seller.as_ref(), escrow_nonce.key().as_ref()],
        bump,
        payer = initializer,
        space = 8 + EscrowVault::INIT_SPACE
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(mut)]
    pub initializer: Signer<'info>,
    pub mint: Account<'info, Mint>,
    /// CHECK: Used as nonce in PDA seeds
    pub escrow_nonce: AccountInfo<'info>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct BuyerDeposit<'info> {
    #[account(
        mut,
        seeds = [b"escrow", vault.buyer.as_ref(), vault.seller.as_ref(), vault.escrow_nonce.as_ref()],
        bump = vault.bump,
        has_one = buyer
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = vault
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = buyer
    )]
    pub buyer_ata: Account<'info, TokenAccount>,
    #[account(mut)]
    pub buyer: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct SellerFulfill<'info> {
    #[account(
        mut,
        seeds = [b"escrow", vault.buyer.as_ref(), vault.seller.as_ref(), vault.escrow_nonce.as_ref()],
        bump = vault.bump,
        has_one = seller
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = vault
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = seller
    )]
    pub seller_ata: Account<'info, TokenAccount>,
    #[account(mut)]
    pub seller: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct BuyerCancel<'info> {
    #[account(
        mut,
        seeds = [b"escrow", vault.buyer.as_ref(), vault.seller.as_ref(), vault.escrow_nonce.as_ref()],
        bump = vault.bump,
        has_one = buyer
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = vault
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        token::mint = vault.mint,
        token::authority = buyer
    )]
    pub buyer_ata: Account<'info, TokenAccount>,
    #[account(mut)]
    pub buyer: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[error_code]
pub enum EscrowError {
    #[msg("Already deposited")]
    AlreadyDeposited,
    #[msg("Not deposited yet")]
    NotDeposited,
    #[msg("Already fulfilled")]
    AlreadyFulfilled,
}
