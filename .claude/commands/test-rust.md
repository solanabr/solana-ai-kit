---
description: "Run Rust tests for Solana programs and backend services"
---

You are running Rust tests. This command covers Solana program testing (Mollusk, LiteSVM, Surfpool, Trident) and backend service testing.

## Related Skills

- [testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Testing strategy details
- [security.md](../skills/ext/solana-dev/skills/solana-dev/references/security.md) - Security testing checklist
- [programs/anchor.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/anchor.md) - Anchor test patterns
- [programs/pinocchio.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md) - Pinocchio test patterns

## Step 1: Identify Project Type

```bash
echo "🔍 Detecting project type..."

if [ -f "Anchor.toml" ]; then
    echo "📦 Anchor project detected"
    PROJECT_TYPE="anchor"
elif grep -q "pinocchio" Cargo.toml 2>/dev/null; then
    echo "🎯 Pinocchio program detected"
    PROJECT_TYPE="pinocchio"
elif grep -q "solana-program" Cargo.toml 2>/dev/null; then
    echo "⚙️  Solana native program detected"
    PROJECT_TYPE="solana"
elif grep -q "axum\|tokio" Cargo.toml 2>/dev/null; then
    echo "🌐 Rust backend service detected"
    PROJECT_TYPE="backend"
else
    echo "🦀 Standard Rust project detected"
    PROJECT_TYPE="standard"
fi
```

---

## Solana Program Testing

### Testing Pyramid

1. **Unit tests (fastest)**: Mollusk - individual instruction tests
2. **Integration tests (fast)**: LiteSVM - multi-instruction flows
3. **Realistic state tests**: Surfpool - mainnet/devnet state locally
4. **Fuzz tests**: Trident - edge case discovery

### Mollusk Unit Tests

Fast, isolated tests for individual instructions:

```bash
echo "🐚 Running Mollusk unit tests..."
cargo test --lib -- --nocapture
```

```rust
#[cfg(test)]
mod tests {
    use mollusk_svm::Mollusk;
    use solana_sdk::{account::Account, pubkey::Pubkey, instruction::Instruction};

    #[test]
    fn test_initialize() {
        let program_id = Pubkey::new_unique();
        let mollusk = Mollusk::new(&program_id, "target/deploy/my_program.so");

        // Setup accounts
        let user = Pubkey::new_unique();
        let accounts = vec![
            (user, Account::new(1_000_000_000, 0, &program_id)),
        ];

        // Create instruction
        let instruction = Instruction {
            program_id,
            accounts: vec![],
            data: vec![0], // Initialize discriminator
        };

        // Process and verify
        let result = mollusk.process_instruction(&instruction, &accounts);
        assert!(result.program_result.is_ok());

        // Check CU usage
        println!("CU consumed: {}", result.compute_units_consumed);
        assert!(result.compute_units_consumed < 50_000);
    }
}
```

### LiteSVM Integration Tests

Multi-instruction flow testing:

```bash
echo "⚡ Running LiteSVM integration tests..."
cargo test --test '*'
```

```rust
#[cfg(test)]
mod tests {
    use litesvm::LiteSVM;
    use solana_sdk::{signature::Keypair, signer::Signer, transaction::Transaction};

    #[test]
    fn test_full_deposit_withdraw_flow() {
        let mut svm = LiteSVM::new();

        // Add program
        let program_id = Pubkey::new_unique();
        svm.add_program(program_id, include_bytes!("../target/deploy/my_program.so"));

        // Create and fund user
        let user = Keypair::new();
        svm.airdrop(&user.pubkey(), 10_000_000_000).unwrap();

        // Build transaction
        let tx = Transaction::new_signed_with_payer(
            &[/* deposit instruction */],
            Some(&user.pubkey()),
            &[&user],
            svm.latest_blockhash(),
        );

        // Execute and verify
        let result = svm.send_transaction(tx);
        assert!(result.is_ok());
    }
}
```

### Surfpool Integration Tests

Test against realistic mainnet/devnet state locally:

```bash
echo "🏄 Running Surfpool integration tests..."

# Start local Surfnet (drop-in replacement for test-validator)
surfpool start --background

# Run tests against realistic state
cargo test --test integration

# Stop Surfnet
surfpool stop
```

```typescript
// Surfpool enables:
// - Complex CPIs with mainnet programs (Jupiter 40+ accounts)
// - Time travel and block manipulation
// - Account cloning between environments

// Time travel to specific slot
await connection._rpcRequest('surfnet_timeTravel', [{
    absoluteSlot: 250000000
}]);

// Clone account from mainnet
await connection._rpcRequest('surfnet_cloneProgramAccount', [{
    source: mainnetProgramId.toString(),
    destination: localProgramId.toString(),
    account: accountPubkey.toString(),
}]);
```

### Trident Fuzz Tests

Property-based fuzzing for edge cases:

```bash
echo "🔱 Running Trident fuzz tests..."

# Initialize (first time only)
if [ ! -d "trident-tests" ]; then
    trident init
fi

cd trident-tests

# Run fuzz tests (modern syntax)
trident fuzz run --timeout 300

# Check for crashes
if [ -d "hfuzz_workspace" ]; then
    echo "📋 Checking for crash reports..."
    find hfuzz_workspace -name "crashes" -type d -exec ls -la {} \; 2>/dev/null
fi

cd ..
```

### Complete Solana Test Suite

```bash
echo "🧪 Running complete Solana test suite..."

# 1. Build program
if [ -f "Anchor.toml" ]; then
    anchor build
else
    cargo build-sbf
fi

# 2. Unit tests (Mollusk)
echo "📍 Unit tests..."
cargo test --lib

# 3. Integration tests (LiteSVM)
echo "📍 Integration tests..."
cargo test --test '*'

# 4. Fuzz tests (Trident) - quick run
if [ -d "trident-tests" ]; then
    echo "📍 Fuzz tests..."
    cd trident-tests && trident fuzz run --timeout 60 && cd ..
fi

echo "✅ All Solana tests complete!"
```

---

## Backend Service Testing

### Axum/Tokio Service Tests

```bash
echo "🌐 Running backend service tests..."

# Run all tests
cargo test

# Run with test database
if [ -f ".env.test" ]; then
    export $(cat .env.test | xargs)
fi

# Integration tests (serial to avoid DB conflicts)
cargo test --test '*' -- --test-threads=1
```

### Database Testing Pattern

```rust
#[cfg(test)]
mod tests {
    use sqlx::PgPool;

    #[sqlx::test]
    async fn test_user_creation(pool: PgPool) {
        let user = sqlx::query_as!(
            User,
            "INSERT INTO users (name) VALUES ($1) RETURNING *",
            "test_user"
        )
        .fetch_one(&pool)
        .await
        .unwrap();

        assert_eq!(user.name, "test_user");
    }
}
```

### Async Handler Tests

```rust
#[cfg(test)]
mod tests {
    use axum::{body::Body, http::{Request, StatusCode}};
    use tower::ServiceExt;

    #[tokio::test]
    async fn test_get_account() {
        let app = create_test_app().await;

        let response = app
            .oneshot(
                Request::builder()
                    .uri("/api/accounts/11111111111111111111111111111111")
                    .method("GET")
                    .body(Body::empty())
                    .unwrap()
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);
    }
}
```

---

## Common Test Commands

```bash
# Show println! output
cargo test -- --nocapture

# Run specific test
cargo test test_name -- --exact

# Run tests serially (shared state)
cargo test -- --test-threads=1

# Run with logging
RUST_LOG=debug cargo test

# Run with backtrace
RUST_BACKTRACE=1 cargo test

# Run ignored tests
cargo test -- --ignored

# Run benchmarks
cargo bench
```

## Test Coverage

```bash
# Install tarpaulin
cargo install cargo-tarpaulin

# Generate coverage report
cargo tarpaulin --out Html --output-dir coverage

echo "📊 Coverage report: coverage/index.html"
```

## Debugging Failed Tests

```bash
# Full debug output
RUST_LOG=trace RUST_BACKTRACE=full cargo test failing_test -- --nocapture --exact

# For Solana programs, check:
# - Program logs in test output
# - Account validation logic
# - PDA derivations
# - Arithmetic errors

# For backend services, check:
# - Database state
# - Mock expectations
# - Async/await usage
# - Environment variables
```

## Test Framework Comparison

| Framework | Speed | Use Case | Scope |
|-----------|-------|----------|-------|
| **Mollusk** | ⚡ Fastest | Single instruction | Unit |
| **LiteSVM** | ⚡ Fast | Multi-instruction flows | Integration |
| **Surfpool** | 🚀 Fast | Realistic cluster state | Integration |
| **Trident** | 🐢 Slower | Edge case discovery | Fuzz |
| **test-validator** | 🐢 Slowest | Full network simulation | E2E |

## CI Test Pattern

```bash
set -e  # Exit on first failure

echo "📝 Format check..."
cargo fmt -- --check

echo "🔎 Clippy..."
cargo clippy --all-targets -- -D warnings

echo "🧪 Unit tests..."
cargo test --lib

echo "🔗 Integration tests..."
cargo test --test '*'

echo "📚 Doc tests..."
cargo test --doc

echo "✅ All tests passed!"
```

## Test Checklist

Before deployment:

- [ ] All Mollusk unit tests pass
- [ ] All LiteSVM integration tests pass
- [ ] Surfpool tests pass (if using mainnet state)
- [ ] Fuzz testing run 10+ minutes with no crashes
- [ ] Error conditions tested
- [ ] Edge cases covered (max values, zero values)
- [ ] CU consumption within limits
- [ ] Backend integration tests pass

---

**Remember**: Test at all levels. Mollusk for speed, LiteSVM for integration, Surfpool for realistic state, Trident for edge cases.
