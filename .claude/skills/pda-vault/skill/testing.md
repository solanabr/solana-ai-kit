# Vault Testing Guide

## Mollusk (Fast Unit Tests)

```rust
use mollusk_svm::Mollusk;

#[test]
fn test_deposit_and_withdraw() {
    let mollusk = Mollusk::new("target/deploy/vault_program");
    let owner = Keypair::new();
    let mint = Pubkey::new_unique();

    let (vault_pda, bump) = Pubkey::find_program_address(
        &[b"vault", &owner.pubkey().to_bytes(), &mint.to_bytes()],
        &mollusk.program_id,
    );

    // Test deposit
    let deposit_ix = Instruction {
        program_id: mollusk.program_id,
        accounts: vec![...],
        data: vec![1, ...],  // deposit instruction
    };
    let result = mollusk.process_instruction(&deposit_ix, &[&owner]);
    assert!(result.is_ok());

    // Verify vault balance
    let vault_account = mollusk.get_account(&vault_pda);
    // read balance from account data...
}
```

## LiteSVM (Integration Tests)

```rust
use litesvm::LiteSVM;

#[test]
fn test_full_vault_flow() {
    let mut svm = LiteSVM::new();
    let program_id = svm.deploy_program("target/deploy/vault_program");

    // Create mint, ATAs, vault account
    // Test initialize, deposit, withdraw
    // Assert balance changes and events
}
```

## Surfpool (Mainnet Forking)

```bash
surfpool test --fork mainnet --program target/deploy/vault_program
```

Useful for testing against real mainnet token accounts and protocol programs.

## What to Test

| Scenario | Expected |
|----------|----------|
| Deposit tokens | Balance increases by amount |
| Withdraw tokens | Balance decreases by amount |
| Withdraw more than balance | Error: InsufficientBalance |
| Close with balance > 0 | Error: VaultNotEmpty |
| Close with balance == 0 | Success, rent returned |
| Wrong signer withdraws | Error: MissingRequiredSignature |
| Double initialization | Error: AccountAlreadyInUse |
| Wrong token mint | Error: ConstraintTokenMint |
