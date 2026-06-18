---
name: pda-vault
description: Build production-grade PDA vaults on Solana. Covers Anchor 1.0+ and Pinocchio implementations with single-signer, multi-sig, time-lock, and escrow vault patterns. Use when implementing token vaults, escrows, leverage vaults, or any program-owned account pattern.
license: MIT
metadata:
  author: Superteam Brazil
  stack: anchor-1.0, pinocchio, solana-kit
  updated: 2026-06
---

# PDA Vault Development Guide

Build secure, production-grade PDA vaults for Solana. A PDA vault is a program-owned account used to hold and manage assets on behalf of users — the foundational pattern behind every lending pool, escrow, staking vault, and AMM on Solana.

## Overview

A PDA vault uses a Program Derived Address (PDA) as the owner of a token account or SOL account. Because only the program can sign for its PDAs, assets in the vault are trustlessly controlled by program logic.

### When to Use Each Vault Type

| Vault Type | Use Case | Auth Pattern |
|------------|----------|-------------|
| **Single-Signer** | Per-user deposit boxes, staking positions | One PDA per user |
| **Multi-Sig** | DAO treasuries, team vesting | Multiple signers required |
| **Time-Lock** | Token vesting, cliff unlocks, salary streams | Clock-based release |
| **Escrow** | P2P trading, OTC deals | Two-party settlement |

### 2026 Stack

| Layer | Recommended |
|-------|------------|
| Programs | Anchor 1.0+ or Pinocchio 0.10+ |
| Testing | Mollusk or LiteSVM |
| Client | @solana/kit (web3.js v2) |
| IDL | Codama from Anchor |

## Quick Start

### Anchor 1.0 Scaffold

```bash
anchor init my-vault
cd my-vault
anchor add token-2022  # if using Token Extensions
```

### Core Vault Account (Anchor)

```rust
use anchor_lang::prelude::*;

#[account]
#[derive(InitSpace)]
pub struct Vault {
    pub owner: Pubkey,
    pub mint: Pubkey,
    pub balance: u64,
    pub bump: u8,
    pub vault_type: VaultType,
    // Time-lock fields (optional)
    pub unlock_time: i64,
    // Multi-sig fields (optional)
    pub signers: Vec<Pubkey>,
    pub threshold: u8,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, InitSpace)]
pub enum VaultType {
    Single,
    TimeLock { unlock_time: i64 },
    MultiSig { threshold: u8 },
    Escrow { seller: Pubkey, buyer: Pubkey },
}
```

### Initialize Vault Instruction

```rust
#[derive(Accounts)]
#[instruction(vault_type: VaultType)]
pub struct InitializeVault<'info> {
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

pub fn initialize_vault(ctx: Context<InitializeVault>, vault_type: VaultType) -> Result<()> {
    let vault = &mut ctx.accounts.vault;
    vault.owner = ctx.accounts.owner.key();
    vault.mint = ctx.accounts.mint.key();
    vault.balance = 0;
    vault.bump = ctx.bumps.vault;
    vault.vault_type = vault_type;
    Ok(())
}
```

## Core Vault Patterns

### Pattern 1: Single-Signer Vault

The simplest vault — one PDA per (user, mint) pair. Each user gets their own vault account.

```rust
#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(
        mut,
        seeds = [b"vault", owner.key().as_ref(), vault.mint.key().as_ref()],
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

pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    let vault = &mut ctx.accounts.vault;

    // Transfer tokens from user to vault
    transfer_tokens(
        ctx.accounts.user_ata.to_account_info(),
        ctx.accounts.vault_ata.to_account_info(),
        amount,
        ctx.accounts.owner.to_account_info(),
        ctx.accounts.token_program.to_account_info(),
    )?;

    vault.balance = vault.balance.checked_add(amount)
        .ok_or(ErrorCode::Overflow)?;

    Ok(())
}

#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(
        mut,
        seeds = [b"vault", owner.key().as_ref(), vault.mint.key().as_ref()],
        bump = vault.bump,
        has_one = owner @ ErrorCode::Unauthorized
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

pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let vault = &ctx.accounts.vault;

    vault.balance.checked_sub(amount)
        .ok_or(ErrorCode::InsufficientBalance)?;

    // PDA signs the CPI — the program controls these tokens
    let seeds = &[
        b"vault",
        vault.owner.as_ref(),
        vault.mint.as_ref(),
        &[vault.bump],
    ];
    let signer_seeds = &[&seeds[..]];

    transfer_tokens_from_pda(
        ctx.accounts.vault_ata.to_account_info(),
        ctx.accounts.user_ata.to_account_info(),
        amount,
        ctx.accounts.vault.to_account_info(),
        ctx.accounts.token_program.to_account_info(),
        signer_seeds,
    )?;

    ctx.accounts.vault.balance = vault.balance.checked_sub(amount)
        .ok_or(ErrorCode::InsufficientBalance)?;

    Ok(())
}
```

### Pattern 2: Time-Lock Vault

Tokens are locked until a specific timestamp. The agent must verify `Clock::get()?.unix_timestamp >= vault.unlock_time`.

```rust
#[derive(Accounts)]
pub struct TimeLockDeposit<'info> {
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

pub fn initialize_timelock(
    ctx: Context<TimeLockDeposit>,
    unlock_time: i64,
) -> Result<()> {
    let clock = Clock::get()?;
    require!(
        unlock_time > clock.unix_timestamp,
        ErrorCode::InvalidUnlockTime
    );

    let vault = &mut ctx.accounts.vault;
    vault.owner = ctx.accounts.owner.key();
    vault.unlock_time = unlock_time;
    vault.vault_type = VaultType::TimeLock { unlock_time };
    vault.bump = ctx.bumps.vault;
    Ok(())
}

#[derive(Accounts)]
pub struct TimeLockWithdraw<'info> {
    #[account(
        mut,
        seeds = [b"timelock", vault.owner.key().as_ref(), &vault.unlock_time.to_le_bytes()],
        bump = vault.bump,
        has_one = owner
    )]
    pub vault: Account<'info, Vault>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

pub fn withdraw_timelock(ctx: Context<TimeLockWithdraw>, amount: u64) -> Result<()> {
    let clock = Clock::get()?;
    require!(
        clock.unix_timestamp >= ctx.accounts.vault.unlock_time,
        ErrorCode::TokensLocked
    );
    // ... proceed with PDA-signed transfer
    Ok(())
}
```

### Pattern 3: Multi-Sig Vault

Requires M-of-N signers to approve withdrawals. Each approval is recorded on-chain.

```rust
#[account]
#[derive(InitSpace)]
pub struct MultiSigProposal {
    pub vault: Pubkey,
    pub destination: Pubkey,
    pub amount: u64,
    pub approved_count: u8,
    pub executed: bool,
    pub approvals: [Pubkey; 10],  // max 10 signers
}

pub fn approve_proposal(ctx: Context<ApproveProposal>) -> Result<()> {
    let proposal = &mut ctx.accounts.proposal;
    let signer = ctx.accounts.signer.key();

    require!(
        ctx.accounts.vault.signers.contains(&signer),
        ErrorCode::NotAuthorized
    );
    require!(!proposal.approvals.contains(&signer), ErrorCode::AlreadyApproved);
    require!(!proposal.executed, ErrorCode::AlreadyExecuted);

    let idx = proposal.approvals.iter().position(|a| *a == Pubkey::default()).unwrap();
    proposal.approvals[idx] = signer;
    proposal.approved_count += 1;

    if proposal.approved_count >= ctx.accounts.vault.threshold {
        proposal.executed = true;
        // Execute the transfer
    }
    Ok(())
}
```

### Pattern 4: Escrow Vault

Two-party settlement — buyer deposits, seller fulfills, or either party can cancel.

```rust
#[derive(Accounts)]
#[instruction(buyer: Pubkey, seller: Pubkey)]
pub struct InitializeEscrow<'info> {
    #[account(
        init,
        seeds = [b"escrow", buyer.as_ref(), seller.as_ref(), &Clock::get()?.slot.to_le_bytes()],
        bump,
        payer = buyer,
        space = 8 + Vault::INIT_SPACE
    )]
    pub vault: Account<'info, Vault>,
    #[account(mut)]
    pub buyer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

pub fn initialize_escrow(
    ctx: Context<InitializeEscrow>,
    buyer: Pubkey,
    seller: Pubkey,
    expected_amount: u64,
) -> Result<()> {
    let vault = &mut ctx.accounts.vault;
    vault.vault_type = VaultType::Escrow {
        buyer,
        seller,
    };
    vault.owner = ctx.accounts.buyer.key();
    vault.balance = expected_amount;
    vault.bump = ctx.bumps.vault;
    Ok(())
}
```

## Pinocchio Implementation

For high-throughput vaults (DEXs, orderbooks), use Pinocchio for 88-95% CU reduction.

```rust
use pinocchio::{
    account_info::AccountInfo,
    entrypoint,
    program_error::ProgramError,
    pubkey::Pubkey,
    ProgramResult,
    sysvar::clock::Clock,
};
use pinocchio_token::instructions::Transfer;
use bytemuck::{Pod, Zeroable};

entrypoint!(process_instruction);

#[repr(C)]
#[derive(Clone, Copy, Pod, Zeroable)]
pub struct Vault {
    pub discriminator: u8,     // 0x01 for vault
    pub owner: [u8; 32],
    pub mint: [u8; 32],
    pub balance: u64,
    pub bump: u8,
    pub _padding: [u8; 7],     // align to 8 bytes
}

pub fn process_instruction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    data: &[u8],
) -> ProgramResult {
    match data.first() {
        Some(0) => initialize_vault(program_id, accounts, &data[1..]),
        Some(1) => deposit(program_id, accounts, &data[1..]),
        Some(2) => withdraw(program_id, accounts, &data[1..]),
        _ => Err(ProgramError::InvalidInstructionData),
    }
}

fn withdraw(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    data: &[u8],
) -> ProgramResult {
    let [vault_info, vault_ata, user_ata, owner, token_prog, ..] = accounts
    else { return Err(ProgramError::NotEnoughAccountKeys) };

    // Parse vault data zero-copy
    let vault_data = vault_info.try_borrow_data()?;
    let vault: &Vault = bytemuck::from_bytes(&vault_data[..core::mem::size_of::<Vault>()]);

    // Verify owner
    require(owner.is_signer(), ProgramError::MissingRequiredSignature);
    require(vault.owner == *owner.key(), ProgramError::InvalidAccountData);

    // Parse amount
    let amount = u64::from_le_bytes(data[..8].try_into().unwrap());

    // PDA signs
    let seeds = &[b"vault", vault.owner.as_ref(), vault.mint.as_ref(), &[vault.bump]];
    let signer_seeds = &[&seeds[..]];

    Transfer {
        source: vault_ata,
        destination: user_ata,
        authority: vault_info,
        amount,
    }.invoke_signed(signer_seeds)?;

    drop(vault_data);  // release borrow before mutable access

    // Update balance
    let mut vault_data = vault_info.try_borrow_mut_data()?;
    let vault_mut: &mut Vault = bytemuck::from_bytes_mut(&mut vault_data[..core::mem::size_of::<Vault>()]);
    vault_mut.balance = vault_mut.balance.checked_sub(amount).ok_or(ProgramError::InsufficientFunds)?;

    Ok(())
}

fn require(cond: bool, err: ProgramError) -> ProgramResult {
    if !cond { return Err(err) }
    Ok(())
}
```

## Seed Derivation Strategies

Choose seeds based on your vault type:

| Strategy | Seeds | Use Case |
|----------|-------|----------|
| User + Mint | `[b"vault", user, mint]` | Per-user per-token vault |
| User + Index | `[b"vault", user, &index.to_le_bytes()]` | Multiple vaults per user |
| Timestamp | `[b"timelock", user, &unlock_time.to_le_bytes()]` | Time-lock positions |
| Counter | `[b"vault", &next_id.to_le_bytes()]` | Global vault counter |
| Deterministic | `[b"escrow", buyer, seller, nonce]` | Escrow between two parties |

**Key rule**: Your seeds must be deterministic enough to derive on the client side. Never use random values unless you store them in a lookup account.

## Testing with Mollusk (Anchor)

```rust
#[cfg(test)]
mod tests {
    use mollusk_svm::Mollusk;
    use solana_sdk::{
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
        signature::Keypair,
        signer::Signer,
    };

    #[test]
    fn test_vault_deposit_and_withdraw() {
        let mollusk = Mollusk::new(&"target/deploy/my_vault_program");
        let owner = Keypair::new();
        let mint = Pubkey::new_unique();

        // Derive vault PDA
        let (vault_pda, bump) = Pubkey::find_program_address(
            &[b"vault", &owner.pubkey().to_bytes(), &mint.to_bytes()],
            &mollusk.program_id,
        );

        // ... test deposit, verify balance, test withdraw
    }
}
```

## Security Checklist

- **Reinitialization guard**: Always check discriminator — use `init` constraint in Anchor or check `discriminator != 0` in Pinocchio
- **PDA seed verification**: Verify every seed component — don't trust the caller's PDA
- **Signer verification**: User must sign for their own vault operations
- **Balance tracking**: Use `checked_add`/`checked_sub` — never allow balance underflow
- **Account closure**: Zero out lamports or use `close` constraint to reclaim rent
- **CPI reentrancy**: Use `require_keys_eq!` on program IDs in CPI calls
- **Token account ownership**: Verify `vault_ata.owner == vault.key()` — tokens must be owned by the PDA

## Common Errors

### Error: AccountNotInitialized
**Cause**: Vault account not yet created. **Solution**: Call `initialize_vault` first.

### Error: InsufficientBalance
**Cause**: `balance - amount < 0`. **Solution**: Check `vault.balance >= amount` before withdraw.

### Error: ConstraintSeeds
**Cause**: PDA seeds mismatch. **Solution**: Verify the seeds match `find_program_address` output.

### Error: TokensLocked
**Cause**: Withdraw before `unlock_time`. **Solution**: Wait until clock passes the unlock timestamp.

### Error: MissingRequiredSignature
**Cause**: Owner not a signer. **Solution**: Pass `owner` as a signer.

## Guidelines

1. **Always use checked math** — overflow/underflow is the #1 vault exploit
2. **One PDA per logical vault** — don't reuse PDAs across users
3. **Track balance in the vault account** — don't rely on token account balance alone
4. **Use `close` constraint** for vault closure to reclaim rent
5. **Verify mint matches** — prevent cross-mint attacks
6. **Test with Mollusk or LiteSVM** — fork mainnet state for realistic tests
7. **Never trust `account.data`** — always validate discriminator and owner

## References

- [Anchor Docs](https://www.anchor-lang.com/)
- [Solana PDA Documentation](https://solana.com/docs/core/programs#program-derived-addresses)
- [Pinocchio Framework](https://github.com/anza-xyz/pinocchio)
- [Token-2022 Extension Guide](https://spl.solana.com/token-2022)
- [Mollusk Testing](https://github.com/buffalojoec/mollusk)

## Scripts

### scaffold-vault.sh
Generates a complete Anchor vault project with deposit/withdraw pattern.
```bash
./scripts/scaffold-vault.sh my-vault-project
```

### derive-pda.sh
Derives a PDA address from seeds and program ID for testing.
```bash
./scripts/derive-pda.sh YourProgramID1111 vault <user-pubkey> <mint-pubkey>
```

## Skill Structure

```
pda-vault/
├── SKILL.md
├── scripts/
│   ├── scaffold-vault.sh
│   └── derive-pda.sh
├── resources/
│   ├── pda-cheatsheet.md
│   └── program-addresses.md
├── examples/
│   ├── basic-vault/lib.rs
│   ├── time-lock-vault/lib.rs
│   └── escrow-vault/lib.rs
├── templates/
│   └── vault-template.rs
└── docs/
    └── troubleshooting.md
```
