# Multi-Sig Vault

M-of-N approval for withdrawals. Each proposal requires a threshold of signers to execute.

## Vault Account

```rust
#[account]
#[derive(InitSpace)]
pub struct MultiSigVault {
    pub signers: Vec<Pubkey>,
    pub threshold: u8,
    pub owner: Pubkey,
}
```

## Proposal Account

```rust
#[account]
#[derive(InitSpace)]
pub struct Proposal {
    pub vault: Pubkey,
    pub destination: Pubkey,
    pub amount: u64,
    pub approved_count: u8,
    pub executed: bool,
    pub approvals: [Pubkey; 10],  // max 10 signers
}
```

## Approve Proposal

Each signer approves. When threshold is met, the transfer executes.

```rust
pub fn approve_proposal(ctx: Context<ApproveProposal>) -> Result<()> {
    let proposal = &mut ctx.accounts.proposal;
    let signer = ctx.accounts.signer.key();

    require!(
        ctx.accounts.vault.signers.contains(&signer),
        MultiSigError::NotAuthorized
    );
    require!(!proposal.approvals.contains(&signer), MultiSigError::AlreadyApproved);
    require!(!proposal.executed, MultiSigError::AlreadyExecuted);

    let idx = proposal.approvals.iter()
        .position(|a| *a == Pubkey::default())
        .unwrap();
    proposal.approvals[idx] = signer;
    proposal.approved_count += 1;

    if proposal.approved_count >= ctx.accounts.vault.threshold {
        proposal.executed = true;
        // execute transfer via PDA sign
    }
    Ok(())
}
```

## Execution

When threshold is reached, the vault PDA signs the transfer.

```rust
pub fn execute_proposal(ctx: Context<ExecuteProposal>) -> Result<()> {
    let proposal = &ctx.accounts.proposal;
    require!(proposal.executed, MultiSigError::NotApproved);

    // PDA seeds include all signer pubkeys for determinism
    let seeds = &[b"multisig", &proposal.vault.to_bytes()];
    // ... invoke_signed transfer
    Ok(())
}
```

## Guidelines

- Use a dedicated proposal account to track approvals per transaction
- Max signers should be bounded (10) to cap account size
- Emit events when each signer approves and when proposal executes
- Consider adding a time-to-live on proposals so stale ones expire
- The vault PDA authority should be derived from all signer pubkeys
