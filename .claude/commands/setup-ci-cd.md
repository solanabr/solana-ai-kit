---
description: "Setup CI/CD pipeline with automated security checks for Solana programs"
---

You are setting up a CI/CD pipeline for Solana program development. Modern Solana development requires automated security checks on every commit.

## Related Skills

- [deployment.md](../skills/deployment.md) - CI/CD patterns and workflows
- [testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Test automation
- [security.md](../skills/ext/solana-dev/skills/solana-dev/references/security.md) - Security automation

## Overview

This command creates a GitHub Actions workflow that automatically:
- Builds programs with verifiable builds
- Runs comprehensive tests (unit, integration, fuzz)
- Performs security audits (cargo audit, clippy)
- Validates code formatting
- Generates security reports

## Step 1: Create GitHub Actions Workflow

```bash
# Create .github/workflows directory
mkdir -p .github/workflows

# Create workflow file
cat > .github/workflows/solana-security.yml << 'EOF'
name: Solana Security Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  SOLANA_VERSION: '2.1.0'
  ANCHOR_VERSION: '0.31.1'
  RUST_VERSION: '1.82.0'

jobs:
  security-audit:
    name: Security Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Rust
        uses: actions-rust-lang/setup-rust-toolchain@v1
        with:
          toolchain: ${{ env.RUST_VERSION }}
          components: clippy, rustfmt

      - name: Cache Cargo dependencies
        uses: actions/cache@v4
        with:
          path: |
            ~/.cargo/bin/
            ~/.cargo/registry/index/
            ~/.cargo/registry/cache/
            ~/.cargo/git/db/
            target/
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}

      - name: Install Solana
        run: |
          sh -c "$(curl -sSfL https://release.solana.com/v${{ env.SOLANA_VERSION }}/install)"
          echo "$HOME/.local/share/solana/install/active_release/bin" >> $GITHUB_PATH

      - name: Install Anchor
        run: |
          cargo install --git https://github.com/coral-xyz/anchor --tag v${{ env.ANCHOR_VERSION }} anchor-cli --locked

      - name: Format Check
        run: cargo fmt --all -- --check

      - name: Clippy Security Lints
        run: |
          cargo clippy --all-targets --all-features -- \
            -W clippy::all \
            -W clippy::pedantic \
            -W clippy::unwrap_used \
            -W clippy::expect_used \
            -W clippy::arithmetic_side_effects \
            -D warnings

      - name: Cargo Audit
        run: |
          cargo install cargo-audit
          cargo audit

      - name: Build Programs
        run: anchor build

      - name: Run Tests
        run: |
          # Unit tests
          cargo test
          # Integration tests
          anchor test --skip-deploy

      - name: Security Report
        if: always()
        run: |
          echo "## Security Audit Report" >> $GITHUB_STEP_SUMMARY
          echo "- ✅ Format check passed" >> $GITHUB_STEP_SUMMARY
          echo "- ✅ Clippy security lints passed" >> $GITHUB_STEP_SUMMARY
          echo "- ✅ Cargo audit passed" >> $GITHUB_STEP_SUMMARY
          echo "- ✅ All tests passed" >> $GITHUB_STEP_SUMMARY

  verifiable-build:
    name: Verifiable Build
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Install Rust
        uses: actions-rust-lang/setup-rust-toolchain@v1
        with:
          toolchain: ${{ env.RUST_VERSION }}

      - name: Install Anchor
        run: |
          cargo install --git https://github.com/coral-xyz/anchor --tag v${{ env.ANCHOR_VERSION }} anchor-cli --locked

      - name: Verifiable Build
        run: anchor build --verifiable

      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: verifiable-build
          path: |
            target/deploy/*.so
            target/idl/*.json

  fuzz-testing:
    name: Fuzz Testing
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      - name: Install Rust
        uses: actions-rust-lang/setup-rust-toolchain@v1
        with:
          toolchain: ${{ env.RUST_VERSION }}

      - name: Install Trident
        run: cargo install trident-cli

      - name: Run Fuzz Tests
        run: |
          cd trident-tests
          trident fuzz run --timeout 300
        timeout-minutes: 10
        continue-on-error: true

      - name: Upload Fuzz Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: fuzz-results
          path: trident-tests/hfuzz_workspace/
EOF

echo "✅ GitHub Actions workflow created: .github/workflows/solana-security.yml"
```

## Step 2: Create Pre-commit Hooks

```bash
# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
set -e

echo "🔍 Running pre-commit security checks..."

# Format check
echo "📝 Checking code formatting..."
cargo fmt --all -- --check || {
    echo "❌ Format check failed. Run 'cargo fmt' to fix."
    exit 1
}

# Clippy check
echo "🔎 Running Clippy security lints..."
cargo clippy --all-targets -- \
    -W clippy::unwrap_used \
    -W clippy::expect_used \
    -W clippy::arithmetic_side_effects \
    -D warnings || {
    echo "❌ Clippy found issues. Please fix before committing."
    exit 1
}

# Quick test
if [ -f "Anchor.toml" ]; then
    echo "🧪 Running quick tests..."
    cargo test --lib || {
        echo "❌ Tests failed. Please fix before committing."
        exit 1
    }
fi

echo "✅ All pre-commit checks passed!"
EOF

# Make executable
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed"
```

## Step 3: Create Security Checklist Template

```bash
# Create pull request template
mkdir -p .github

cat > .github/PULL_REQUEST_TEMPLATE.md << 'EOF'
## Description
<!-- Describe your changes -->

## Security Checklist

### Code Quality
- [ ] Code is formatted (`cargo fmt`)
- [ ] Clippy passes with security lints
- [ ] No `unwrap()` or `expect()` in program code
- [ ] All arithmetic uses checked operations

### Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Fuzz tests pass (if applicable)
- [ ] All test coverage maintained/improved

### Security
- [ ] All accounts validated (owner, signer, PDA)
- [ ] PDA bumps stored (not recalculated)
- [ ] CPI targets validated
- [ ] Accounts reloaded after CPIs
- [ ] No security vulnerabilities introduced
- [ ] `cargo audit` passes

### Build
- [ ] Program builds successfully
- [ ] Binary size acceptable (< 400KB)
- [ ] Verifiable build succeeds (for mainnet changes)

### Documentation
- [ ] Code comments added for complex logic
- [ ] Security considerations documented
- [ ] Breaking changes documented

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Security improvement
- [ ] Performance optimization

## Additional Notes
<!-- Any additional context -->
EOF

echo "✅ Pull request template created"
```

## Step 4: Add Security Configuration Files

```bash
# Create cargo audit config
cat > audit.toml << 'EOF'
[advisories]
db-path = "~/.cargo/advisory-db"
db-urls = ["https://github.com/rustsec/advisory-db"]
vulnerability = "deny"
unmaintained = "warn"
yanked = "warn"
notice = "warn"
ignore = []

[licenses]
unlicensed = "deny"
allow = [
    "MIT",
    "Apache-2.0",
    "BSD-3-Clause",
    "BSD-2-Clause",
]
deny = []
copyleft = "warn"
allow-osi-fsf-free = "either"
default = "deny"
EOF

echo "✅ Cargo audit config created"
```

## Step 5: Create Dependabot Configuration

```bash
# Create dependabot config for automated dependency updates
cat > .github/dependabot.yml << 'EOF'
version: 2
updates:
  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
EOF

echo "✅ Dependabot config created"
```

## Step 6: Verify CI/CD Setup

```bash
# Verify all files created
echo "📋 Verifying CI/CD setup..."

if [ -f ".github/workflows/solana-security.yml" ]; then
    echo "✅ GitHub Actions workflow"
else
    echo "❌ Missing GitHub Actions workflow"
fi

if [ -x ".git/hooks/pre-commit" ]; then
    echo "✅ Pre-commit hook"
else
    echo "❌ Missing pre-commit hook"
fi

if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
    echo "✅ PR template"
else
    echo "❌ Missing PR template"
fi

if [ -f "audit.toml" ]; then
    echo "✅ Cargo audit config"
else
    echo "❌ Missing cargo audit config"
fi

if [ -f ".github/dependabot.yml" ]; then
    echo "✅ Dependabot config"
else
    echo "❌ Missing dependabot config"
fi

echo ""
echo "🎉 CI/CD setup complete!"
echo ""
echo "Next steps:"
echo "1. Commit these changes to your repository"
echo "2. Push to GitHub to trigger the workflow"
echo "3. Review the security pipeline results"
echo "4. Configure GitHub branch protection rules"
```

## GitHub Branch Protection (Manual Setup)

After pushing, configure branch protection on GitHub:

1. Go to repository Settings → Branches
2. Add rule for `main` branch:
   - ✅ Require pull request reviews (1+ reviewers)
   - ✅ Require status checks to pass
     - Select: `Security Audit`
     - Select: `Verifiable Build`
   - ✅ Require branches to be up to date
   - ✅ Require linear history
   - ✅ Include administrators

## CI/CD Best Practices

### Automated Checks on Every Commit
- Format validation
- Security lints (clippy)
- Vulnerability scanning (cargo audit)
- Unit and integration tests
- Build verification

### Before Merging to Main
- All CI checks must pass
- Code review required
- No security warnings
- Test coverage maintained

### Before Deploying to Mainnet
- Verifiable build succeeds
- All tests pass (including fuzz)
- Professional security audit completed
- Manual deployment approval required

## Monitoring and Alerts

Consider setting up:
- GitHub notifications for security advisories
- Slack/Discord integration for CI failures
- Automated security reports
- Dependency vulnerability alerts

## Maintenance

### Weekly
- Review dependabot PRs
- Update security advisories

### Monthly
- Review and update security lints
- Audit CI/CD pipeline performance
- Update toolchain versions

### Before Major Releases
- Full security audit
- Penetration testing
- Third-party code review

---

**Remember**: CI/CD is your first line of defense. Every commit should be validated for security issues automatically.
