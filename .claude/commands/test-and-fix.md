---
description: "Run tests and automatically fix common issues"
---

You are running tests and fixing any issues found. This command iteratively tests, diagnoses problems, fixes them, and retests.

## Related Skills

- [testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Testing strategy details
- [security.md](../skills/ext/solana-dev/skills/solana-dev/references/security.md) - Security fix patterns

## Overview

This command follows a **test → diagnose → fix → retest** loop until all tests pass or manual intervention is needed.

## Step 1: Initial Test Run

```bash
echo "🧪 Running initial tests..."

# Determine project type and run appropriate tests
if [ -f "Anchor.toml" ]; then
    # Anchor project
    anchor build && anchor test --skip-deploy
    TEST_STATUS=$?
elif grep -q "solana-program" Cargo.toml 2>/dev/null; then
    # Native Solana program
    cargo build-sbf && cargo test
    TEST_STATUS=$?
else
    # Standard Rust or backend
    cargo test
    TEST_STATUS=$?
fi

if [ $TEST_STATUS -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
fi

echo "❌ Tests failed. Starting diagnosis..."
```

## Step 2: Diagnose Issues

Analyze the test output to categorize failures:

### Common Issue Categories

1. **Format Issues**
   - Code not formatted
   - Inconsistent style

2. **Clippy Warnings**
   - Lints not satisfied
   - Potential bugs

3. **Compilation Errors**
   - Syntax errors
   - Type mismatches
   - Missing imports

4. **Test Failures**
   - Failed assertions
   - Logic errors
   - Account validation failures (Solana)

5. **Runtime Errors**
   - Panics
   - Arithmetic overflow
   - Account errors (Solana)

## Step 3: Automatic Fixes

### Fix Format Issues

```bash
# Always start with formatting
echo "📝 Fixing format issues..."
cargo fmt

# For TypeScript tests
if [ -d "tests" ] && ls tests/*.ts >/dev/null 2>&1; then
    npx prettier --write "tests/**/*.ts"
fi

echo "✅ Format fixed"
```

### Fix Clippy Warnings (Auto-fixable)

```bash
echo "🔧 Fixing clippy warnings..."

# Apply automatic clippy fixes
cargo clippy --fix --allow-dirty --allow-staged

# Note: Not all clippy warnings are auto-fixable
# Manual fixes may be needed for:
# - Logic issues
# - Unsafe code
# - Complex refactorings

echo "✅ Clippy auto-fixes applied"
```

### Fix Common Solana Issues

#### Missing Account in Anchor Test
```bash
# If test fails with "Missing account: system_program"
# Add to test accounts:
# systemProgram: anchor.web3.SystemProgram.programId,
```

#### Account Not Mutable
```bash
# If error: "Account not mutable"
# Update account definition to include 'mut':
# #[account(mut)]
```

#### Insufficient Compute Units
```bash
# If error: "Exceeded CU limit"
# Add compute budget instruction in test:
# .preInstructions([
#   ComputeBudgetProgram.setComputeUnitLimit({ units: 400000 })
# ])
```

## Step 4: Rerun Tests

```bash
echo "🔄 Retesting after fixes..."

# Run tests again
if [ -f "Anchor.toml" ]; then
    anchor test --skip-deploy
    TEST_STATUS=$?
elif grep -q "solana-program" Cargo.toml 2>/dev/null; then
    cargo test
    TEST_STATUS=$?
else
    cargo test
    TEST_STATUS=$?
fi

if [ $TEST_STATUS -eq 0 ]; then
    echo "✅ All tests now pass!"
    exit 0
fi
```

## Step 5: Manual Fix Guidance

If automatic fixes didn't resolve all issues, provide guidance:

```bash
echo "⚠️  Manual fixes needed. Analyzing failures..."

# Parse test output for specific errors
# This is where AI assistance helps diagnose complex issues
```

### Solana-Specific Manual Fixes

#### Account Validation Failures
```rust
// Error: "A has_one constraint was violated"
// Fix: Ensure account relationships match constraints

#[account(
    mut,
    has_one = authority @ ErrorCode::Unauthorized,  // authority must match
)]
pub vault: Account<'info, Vault>,
```

#### PDA Derivation Mismatch
```rust
// Error: "Invalid PDA seed"
// Fix: Verify seeds match between program and test

// Program:
seeds = [b"vault", authority.key().as_ref()]

// Test:
const [vaultPda] = PublicKey.findProgramAddressSync(
  [Buffer.from("vault"), authority.publicKey.toBuffer()],
  programId
);
```

#### Arithmetic Overflow
```rust
// Error: "Arithmetic overflow"
// Fix: Use checked arithmetic

// Bad:
vault.balance = vault.balance + amount;

// Good:
vault.balance = vault
    .balance
    .checked_add(amount)
    .ok_or(ErrorCode::Overflow)?;
```

#### Missing Signer
```rust
// Error: "Missing required signature"
// Fix: Ensure account is marked as Signer

#[account(mut)]
pub authority: Signer<'info>,  // Must be Signer, not SystemAccount
```

### Backend Service Manual Fixes

#### Async/Await Issues
```rust
// Error: "Cannot call blocking function in async context"
// Fix: Use async version or spawn_blocking

// Bad:
async fn handler() -> Result<String> {
    std::fs::read_to_string("file.txt")?  // Blocking!
}

// Good:
async fn handler() -> Result<String> {
    tokio::fs::read_to_string("file.txt").await?
}
```

#### Database Connection Issues
```rust
// Error: "Connection pool exhausted"
// Fix: Increase pool size or close connections properly

let pool = PgPoolOptions::new()
    .max_connections(50)  // Increase if needed
    .connect(&database_url)
    .await?;
```

## Step 6: Iterative Fixing

```bash
# Maximum fix iterations
MAX_ITERATIONS=5
ITERATION=1

while [ $ITERATION -le $MAX_ITERATIONS ]; do
    echo "🔄 Fix iteration $ITERATION/$MAX_ITERATIONS"

    # Apply automatic fixes
    cargo fmt
    cargo clippy --fix --allow-dirty --allow-staged

    # Run tests
    if [ -f "Anchor.toml" ]; then
        anchor test --skip-deploy
    else
        cargo test
    fi

    if [ $? -eq 0 ]; then
        echo "✅ All tests pass after $ITERATION iteration(s)!"
        exit 0
    fi

    ITERATION=$((ITERATION + 1))

    # If still failing after max iterations, need manual intervention
    if [ $ITERATION -gt $MAX_ITERATIONS ]; then
        echo "⚠️  Maximum iterations reached. Manual fixes required."
        echo "Please review the test output above and fix remaining issues."
        exit 1
    fi
done
```

## Common Fix Patterns

### Pattern 1: Update Test Data
```typescript
// Test failing because program changed
// Update test to match new program logic

it("deposits funds", async () => {
  // OLD: amount was u64
  await program.methods
    .deposit(new BN(1000))  // UPDATED: now using BN for u64
    .accounts({ vault: vaultPda })
    .rpc();
});
```

### Pattern 2: Add Missing Accounts
```typescript
// Error: "NotEnoughAccountKeys"
// Add missing accounts to instruction

.accounts({
  vault: vaultPda,
  authority: wallet.publicKey,
  systemProgram: SystemProgram.programId,  // ADDED
})
```

### Pattern 3: Fix Account Constraints
```rust
// Error: Constraint violation
// Update account definition

#[account(
    mut,
    constraint = vault.balance >= amount @ ErrorCode::InsufficientFunds,  // ADDED
)]
pub vault: Account<'info, Vault>,
```

### Pattern 4: Handle Async Properly
```rust
// Error: Cannot spawn a future
// Ensure async context

// Bad:
let result = async_function();  // Not awaited!

// Good:
let result = async_function().await?;
```

## Test Fix Checklist

When tests fail, check in order:
1. [ ] Code is formatted (`cargo fmt`)
2. [ ] Clippy is satisfied (`cargo clippy`)
3. [ ] All imports present
4. [ ] Types match between program and tests
5. [ ] Account relationships correct (Solana)
6. [ ] PDAs derived correctly (Solana)
7. [ ] Signers marked properly (Solana)
8. [ ] Arithmetic uses checked operations (Solana)
9. [ ] Async/await used correctly (Backend)
10. [ ] Test data matches program expectations

## Success Criteria

Tests are fixed when:
- ✅ `cargo fmt` passes (no changes)
- ✅ `cargo clippy` passes (no warnings)
- ✅ All unit tests pass
- ✅ All integration tests pass
- ✅ No panics or unexpected errors

## When to Ask for Help

Request manual review if:
- Tests fail after 5 fix iterations
- Error messages are unclear
- Multiple unrelated failures
- Suspected program logic bug (not test bug)
- Breaking changes to program interface

---

**Remember**: Most test failures have simple fixes. Format first, then clippy, then logic.
