---
description: "Build Solana program (Anchor or native)"
---

You are building a Solana program. Follow these steps:

## Related Skills

- [programs/anchor.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/anchor.md) - Anchor build patterns
- [programs/pinocchio.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md) - Pinocchio build optimization

## Step 1: Identify Program Type

Check which framework is being used:

```bash
# Check for Anchor
if [ -f "Anchor.toml" ]; then
    echo "Anchor program detected"
fi

# Check for Cargo
if [ -f "Cargo.toml" ]; then
    echo "Native Rust program detected"
fi
```

## Step 2: Build Program

### For Anchor Programs

```bash
# Clean build
anchor clean
anchor build

# Build specific program
anchor build -p program-name

# Build with verifiable build
anchor build --verifiable

# Check build output
ls -lh target/deploy/*.so
```

### For Native Rust Programs

```bash
# Build BPF program
cargo build-sbf

# Build with specific BPF SDK
cargo build-sbf --bpf-sdk /path/to/bpf-sdk

# Check output
ls -lh target/deploy/*.so
```

## Step 3: Verify Build

```bash
# Check program size (should be < 400KB ideally)
ls -lh target/deploy/*.so | awk '{print $5, $9}'

# Verify program ID
solana address -k target/deploy/program-keypair.json

# If Anchor, verify IDL generated
ls -lh target/idl/*.json
```

## Step 4: Run Format and Lint

After successful build:

```bash
# Format code
cargo fmt

# Run clippy
cargo clippy -- -W clippy::all

# Check for warnings
cargo clippy --all-targets --all-features -- -D warnings
```

## Common Build Issues

### Compilation Errors
- Check Rust version: `rustc --version` (need 1.79+)
- Update dependencies: `cargo update`
- Clean and rebuild: `anchor clean && anchor build`

### Binary Size Too Large
```bash
# Check current size
ls -lh target/deploy/*.so

# Optimize in Cargo.toml:
# [profile.release]
# opt-level = "z"
# lto = "fat"
# codegen-units = 1
```

### Missing Dependencies
```bash
# For Anchor
npm install

# For Rust
cargo fetch
```

### BPF SDK Issues
```bash
# Update Solana CLI
agave-install update

# Reinstall BPF SDK
cargo build-sbf --force-tools-install
```

## Build Optimization

### For Production

```toml
# Add to Cargo.toml
[profile.release]
overflow-checks = true
lto = "fat"
codegen-units = 1
opt-level = 3

[profile.release.build-override]
opt-level = 3
```

### Measure Build Time

```bash
# Time the build
time anchor build

# Or with cargo
time cargo build-sbf
```

## Verifiable Build (Anchor)

**CRITICAL for production and security audits:**

Verifiable builds ensure your program binary can be reproduced identically by anyone, proving no hidden code was injected during compilation. This is essential for:
- Security audits (auditors can verify deployed bytecode matches source)
- User trust (anyone can verify what's deployed)
- Mainnet deployments (industry best practice)

```bash
# Create verifiable build (ALWAYS use for mainnet!)
anchor build --verifiable

# This produces identical builds across machines
# Uses Docker to ensure reproducible compilation environment

# Verify a deployed program matches source
anchor verify <program-id> --provider.cluster mainnet
```

**When to use verifiable builds:**
- ✅ Always for mainnet deployments
- ✅ For security audits
- ✅ Before professional code reviews
- ⚠️ Optional for devnet testing (but good practice)
- ❌ Not needed for local development iteration

**Note:** First verifiable build may take longer as it downloads Docker image, but subsequent builds are faster.

## After Successful Build

- [ ] Program compiled without errors
- [ ] Binary size acceptable (< 400KB preferred)
- [ ] Clippy shows no warnings
- [ ] Code is formatted
- [ ] IDL generated (if Anchor)
- [ ] Verifiable build successful (for mainnet)
- [ ] Ready for testing
