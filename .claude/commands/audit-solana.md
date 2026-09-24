---
description: "Security audit for Solana programs (Anchor/native)"
---

You are conducting a security audit for Solana programs. This is CRITICAL - take your time.

## Related Skills

- [security.md](../skills/ext/solana-dev/skills/solana-dev/references/security.md) - Comprehensive security checklist
- [programs/anchor.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/anchor.md) - Anchor security patterns
- [programs/pinocchio.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md) - Pinocchio security patterns
- [testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Fuzz testing with Trident

## Pre-Audit Checklist

- [ ] All tests passing
- [ ] Code compiles without warnings
- [ ] Documentation complete
- [ ] No hardcoded keys or secrets

## Step 1: Automated Analysis

```bash
echo "🔍 Running automated security analysis..."

# Dependency audit (check for known vulnerabilities)
echo "  📦 Checking dependencies..."
cargo audit

# Supply chain security (check for malicious dependencies)
if command -v cargo-geiger >/dev/null 2>&1; then
    echo "  ☢️  Checking unsafe code usage..."
    cargo geiger
fi

# Clippy with strict security lints
echo "  🔎 Running clippy security lints..."
cargo clippy --all-targets -- \
    -W clippy::all \
    -W clippy::pedantic \
    -W clippy::unwrap_used \
    -W clippy::expect_used \
    -W clippy::panic \
    -W clippy::arithmetic_side_effects \
    -D warnings

# Format check
echo "  📝 Checking format..."
cargo fmt --check

# Run full test suite
echo "  🧪 Running tests..."
if [ -f "Anchor.toml" ]; then
    anchor build && anchor test
else
    cargo build-sbf && cargo test
fi

echo "✅ Automated analysis complete"
```

## Step 2: Account Validation Review

**CRITICAL**: Every account MUST be validated. Check each instruction:

### Owner Checks
```rust
// ✓ CORRECT: Validate account owner
if *account.owner != expected_program_id {
    return Err(ProgramError::IncorrectProgramId);
}

// ✗ WRONG: Assuming owner without check
```

### Signer Checks
```rust
// ✓ CORRECT: Verify signer
if !authority.is_signer {
    return Err(ProgramError::MissingRequiredSignature);
}

// ✗ WRONG: Privileged operation without signer check
```

### PDA Validation
```rust
// ✓ CORRECT: Use stored canonical bump
let seeds = &[
    b"vault",
    authority.key.as_ref(),
    &[vault.bump],  // stored bump
];

// ✗ WRONG: Recalculating bump or accepting user-provided bump
let (pda, _) = Pubkey::find_program_address(seeds, program_id);
```

## Step 3: Arithmetic Safety Review

Check ALL arithmetic operations:

```rust
// ✓ CORRECT: Checked arithmetic
let total = amount_a
    .checked_add(amount_b)
    .ok_or(ErrorCode::Overflow)?;

// ✗ WRONG: Unchecked arithmetic (can panic/overflow)
let total = amount_a + amount_b;
```

**Checklist**:
- [ ] All additions use `checked_add`
- [ ] All subtractions use `checked_sub`
- [ ] All multiplications use `checked_mul`
- [ ] All divisions use `checked_div`
- [ ] No unwrap() in arithmetic operations

## Step 4: Common Attack Vectors

### Type Cosplay
```rust
// ✓ CORRECT: Check discriminator
if account.data.borrow()[0..8] != User::DISCRIMINATOR {
    return Err(ProgramError::InvalidAccountData);
}

// In Anchor, Account<'info, T> does this automatically
```

### Account Revival
```rust
// ✓ CORRECT: Zero data AND set closed discriminator
let mut data = account.data.borrow_mut();
data.fill(0);
data[0..8].copy_from_slice(&CLOSED_ACCOUNT_DISCRIMINATOR);

// Anchor's `close` constraint handles this
#[account(mut, close = destination)]
```

### Arbitrary CPI
```rust
// ✓ CORRECT: Validate program ID
if cpi_program.key() != spl_token::ID {
    return Err(ErrorCode::InvalidProgram.into());
}

// ✗ WRONG: Accepting any program from user
invoke(&instruction, accounts)?;
```

### Missing Reload After CPI
```rust
// ✓ CORRECT: Reload account after CPI
transfer_checked(cpi_ctx, amount, mint.decimals)?;
ctx.accounts.token_account.reload()?;

// ✗ WRONG: Using stale data after CPI
transfer_checked(cpi_ctx, amount, mint.decimals)?;
// ... using token_account without reload
```

### PDA Seed Collision
```rust
// ✓ CORRECT: Unique prefixes per account type
let user_seeds = [b"user_vault", user.key().as_ref()];
let admin_seeds = [b"admin_config", admin.key().as_ref()];

// ✗ WRONG: Shared PDA space
let seeds = [b"vault", key.as_ref()];  // collision possible
```

## Step 5: CPI Security

Check all cross-program invocations:

- [ ] Target program ID is validated (hardcoded or checked)
- [ ] Signer privileges not blindly forwarded
- [ ] Accounts reloaded after CPI if modified
- [ ] Return values checked
- [ ] Error handling proper

## Step 6: Economic Security

For financial operations:

- [ ] Slippage protection implemented
- [ ] Oracle data validated (staleness, confidence)
- [ ] No price manipulation vectors
- [ ] Proper fee accounting
- [ ] Inflation attack prevention (for vaults)

## Step 7: Error Handling

- [ ] No `unwrap()` or `expect()` in program code
- [ ] All error codes defined
- [ ] Descriptive error messages
- [ ] All errors propagated correctly

## Step 8: CU (Compute Units) Optimization

Check for CU waste:

- [ ] Minimal logging (use feature flags for debug logs)
- [ ] PDA bumps stored and reused (not recalculated)
- [ ] Efficient data access patterns
- [ ] No unnecessary account loads

## Step 9: Testing Requirements

Verify comprehensive test coverage:

- [ ] All instructions tested (success paths)
- [ ] All error conditions tested
- [ ] Account validation failures tested
- [ ] Arithmetic edge cases tested (max values, overflow)
- [ ] PDA derivation tested
- [ ] CPI success and failure paths tested
- [ ] Fuzz testing with Trident (REQUIRED for mainnet)

### Fuzz Testing with Trident

```bash
# Setup Trident (if not already)
if [ ! -d "trident-tests" ]; then
    echo "Setting up Trident fuzz testing..."
    trident init
fi

# Run fuzz tests for at least 10 minutes (Trident v0.7+)
echo "🔍 Running fuzz tests (10 minutes minimum)..."
cd trident-tests
trident fuzz run --timeout 600

# Review any crashes found
if [ -d "hfuzz_workspace" ]; then
    echo "⚠️  Review crash reports in hfuzz_workspace/"
    ls -la hfuzz_workspace/*/crashes/ 2>/dev/null || echo "No crashes found ✅"
fi

cd ..
```

Fuzz testing discovers:
- Unexpected arithmetic overflows
- Invalid account combinations
- Edge case panics
- Reentrancy vulnerabilities

## Step 10: Static Analysis (Advanced)

### MIRAI Analysis (Future-Ready)

MIRAI is a static analysis tool for Rust. While still emerging for Solana:

```bash
# Install MIRAI (if available)
# cargo install mirai

# Run static analysis
# mirai src/lib.rs
```

### Custom Security Linters

```bash
# Search for common anti-patterns
echo "🔍 Searching for anti-patterns..."

# Determine program source directories
PROGRAM_DIRS=""
if [ -d "programs" ]; then
    PROGRAM_DIRS="programs/"
elif [ -d "src" ]; then
    PROGRAM_DIRS="src/"
fi

if [ -z "$PROGRAM_DIRS" ]; then
    echo "  ⚠️  No program source directory found"
else
    # Check for unwrap() usage (should be none in program code)
    echo "  Checking for unwrap()..."
    grep -rn "unwrap()" $PROGRAM_DIRS --include="*.rs" || echo "  ✅ No unwrap() found"

    # Check for expect() usage
    echo "  Checking for expect()..."
    grep -rn "expect(" $PROGRAM_DIRS --include="*.rs" || echo "  ✅ No expect() found"

    # Check for unchecked arithmetic
    echo "  Checking for unchecked arithmetic..."
    grep -rn -E "\s+\+\s+|\s+-\s+|\s+\*\s+" $PROGRAM_DIRS --include="*.rs" | \
        grep -v "checked_" && echo "  ⚠️  Found potential unchecked arithmetic" || echo "  ✅ Arithmetic appears checked"

    # Check for missing account reloads after CPIs
    echo "  Checking for missing reload() after CPIs..."
    # This is heuristic-based
    grep -rn "invoke\|anchor_lang::solana_program::program::invoke" $PROGRAM_DIRS --include="*.rs" -A 5 | \
        grep -v "reload()" && echo "  ⚠️  Verify account reloading after CPIs" || echo "  ✅ CPI reloading appears correct"
fi

echo "✅ Static analysis complete"
```

## Step 11: CI/CD Security Integration

Verify security automation:

- [ ] GitHub Actions workflow includes security checks
- [ ] Pre-commit hooks configured
- [ ] Dependency updates monitored (Dependabot)
- [ ] Security advisories enabled
- [ ] Automated test runs on every commit

```bash
# Check CI/CD configuration
if [ -f ".github/workflows/solana-security.yml" ]; then
    echo "✅ CI/CD security pipeline configured"
else
    echo "⚠️  No CI/CD security pipeline found"
    echo "   Run: /setup-ci-cd to configure"
fi
```

## Step 12: Verifiable Build Check

For mainnet deployments:

```bash
# Ensure verifiable builds work
echo "🔨 Testing verifiable build..."
anchor build --verifiable

if [ $? -eq 0 ]; then
    echo "✅ Verifiable build succeeds"
else
    echo "❌ Verifiable build failed - fix before mainnet deployment"
    exit 1
fi
```

## Step 13: Documentation Review

- [ ] Security assumptions documented
- [ ] Known limitations documented
- [ ] Upgrade authority documented
- [ ] Admin key management documented
- [ ] Emergency procedures documented
- [ ] Account structures documented
- [ ] PDA schemes documented

## Critical Security Checklist

Go through this systematically:

### Account Security
- [ ] Every account has owner check
- [ ] Signer verification for privileged operations
- [ ] PDA validation with canonical bumps
- [ ] Account discriminators checked
- [ ] No seed collisions possible

### Arithmetic Security
- [ ] All arithmetic uses checked operations
- [ ] Division by zero handled
- [ ] Casting uses try_into() with errors
- [ ] Token amounts use u64 consistently

### CPI Security
- [ ] Program IDs validated before CPI
- [ ] Signer privileges controlled
- [ ] Accounts reloaded after modifying CPIs
- [ ] Reentrancy considered

### Data Security
- [ ] All instruction data validated
- [ ] Account data size verified
- [ ] Strings/vectors have length limits
- [ ] Rent-exempt balance maintained

## Generate Audit Report

Create `docs/security-audit-[date].md`:

```markdown
# Solana Program Security Audit

**Date**: [Current date]
**Program**: [Program name]
**Auditor**: claude-maintainer

## Summary
- Total Issues: X
- Critical: X
- High: X
- Medium: X
- Low: X

## Critical Issues

[List any critical issues with details]

## High Issues

[List high severity issues]

## Recommendations

1. [Recommendation]
2. [Recommendation]

## Testing Results

- [ ] All tests passing
- [ ] Fuzz testing completed
- [ ] CU limits verified

## Sign-off

- [ ] All critical issues resolved
- [ ] All high issues resolved
- [ ] Ready for professional audit / Needs fixes
```

## Before Mainnet Deployment

**NEVER deploy to mainnet without:**

1. ✓ This security audit completed
2. ✓ All critical and high issues fixed
3. ✓ Comprehensive tests passing
4. ✓ Professional audit (for financial programs)
5. ✓ Testnet deployment and testing
6. ✓ User explicit confirmation

## Professional Audit Firms

For mainnet deployment, consider:
- OtterSec
- Neodyme
- Halborn
- Trail of Bits
- Zellic

## Post-Audit Actions

1. Fix all identified issues
2. Re-run tests
3. Document changes
4. Consider bug bounty program
5. Plan emergency procedures
