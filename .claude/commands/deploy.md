---
description: "Deploy Solana program (devnet first, then mainnet)"
---

You are deploying a Solana program. **ALWAYS test on devnet before mainnet.**

## Related Skills

- [deployment.md](../skills/deployment.md) - Full deployment workflow details
- [security.md](../skills/ext/solana-dev/skills/solana-dev/references/security.md) - Pre-deployment security checklist

## Step 1: Identify Target Network

```bash
echo "🎯 Deployment Target Selection"
echo ""
echo "Choose deployment target:"
echo "  1. devnet (testing - safe, free SOL)"
echo "  2. mainnet (production - REAL SOL, IRREVERSIBLE)"
echo ""

# Check current config
CURRENT_NETWORK=$(solana config get | grep "RPC URL" | awk '{print $3}')
echo "Current network: $CURRENT_NETWORK"
```

**IMPORTANT**: If this is a new program, **ALWAYS deploy to devnet first**.

---

## DEVNET DEPLOYMENT

### Step D1: Configure Devnet

```bash
echo "🌐 Configuring for devnet..."

solana config set --url devnet

# Verify
solana config get
# Should show: RPC URL: https://api.devnet.solana.com
```

### Step D2: Verify Build

```bash
echo "🔨 Building program..."

# Build
if [ -f "Anchor.toml" ]; then
    anchor build
else
    cargo build-sbf
fi

# Check program exists
ls -lh target/deploy/*.so
```

### Step D3: Fund Wallet

```bash
echo "💰 Checking wallet balance..."

solana address
solana balance

# If balance is low, airdrop (devnet only!)
solana airdrop 2

solana balance
```

### Step D4: Deploy to Devnet

```bash
echo "🚀 Deploying to devnet..."

if [ -f "Anchor.toml" ]; then
    anchor deploy --provider.cluster devnet
else
    solana program deploy target/deploy/program.so
fi

# Get program ID
PROGRAM_ID=$(solana address -k target/deploy/program-keypair.json)
echo "✅ Program deployed: $PROGRAM_ID"

# Save program ID
echo $PROGRAM_ID > .program-id-devnet
```

### Step D5: Verify Devnet Deployment

```bash
echo "🔍 Verifying deployment..."

solana program show $PROGRAM_ID

# Explorer link
echo ""
echo "📡 Explorer: https://explorer.solana.com/address/$PROGRAM_ID?cluster=devnet"
```

### Step D6: Test on Devnet

```bash
echo "🧪 Running devnet tests..."

if [ -f "Anchor.toml" ]; then
    anchor test --skip-build --skip-deploy
fi

# Or run custom integration tests
```

### Devnet Checklist

- [ ] Program deployed to devnet
- [ ] Program ID saved
- [ ] Upgrade authority verified
- [ ] Program visible on explorer
- [ ] Basic functionality tested
- [ ] Integration with frontend tested

**Next step**: Test thoroughly on devnet for multiple days before mainnet.

---

## MAINNET DEPLOYMENT

### ⚠️ CRITICAL PRE-DEPLOYMENT CHECKLIST

**STOP: Do NOT proceed to mainnet without ALL items checked:**

- [ ] All tests passing (unit + integration + fuzz)
- [ ] Security audit completed (use /audit-solana)
- [ ] CU usage optimized and verified
- [ ] **Devnet testing successful (multiple days)**
- [ ] Program audited by professional firm (for financial programs)
- [ ] Emergency procedures documented
- [ ] Upgrade authority strategy decided
- [ ] Monitoring/alerts configured

### Step M1: CONFIRMATION REQUIRED

```
🚨 MAINNET DEPLOYMENT CONFIRMATION REQUIRED 🚨

Network: Solana Mainnet-Beta
Program: [program name]
Estimated Cost: [X SOL for deployment + buffer]

This action will:
- Deploy program to MAINNET (IRREVERSIBLE)
- Spend REAL SOL
- Make program publicly accessible
- Potentially handle user funds

⚠️  HAVE YOU COMPLETED:
- [ ] Security audit
- [ ] Professional code review
- [ ] Extensive devnet testing (multiple days)
- [ ] Emergency procedures

Type 'DEPLOY TO MAINNET' to confirm:
```

**DO NOT PROCEED WITHOUT USER CONFIRMATION**

### Step M2: Configure Mainnet

```bash
echo "🌐 Configuring for mainnet..."

solana config set --url mainnet-beta

# VERIFY
solana config get
# Must show: RPC URL: https://api.mainnet-beta.solana.com

# Check wallet and balance
solana address
solana balance
# Need ~3-5 SOL for deployment
```

### Step M3: Final Build Verification

```bash
echo "🔨 Final build verification..."

# Clean build
anchor clean
anchor build --verifiable

# Verify program size
ls -lh target/deploy/*.so

# Run all tests one more time
anchor test

# Security checks
cargo clippy -- -W clippy::all
cargo audit
```

### Step M4: Calculate Deployment Cost

```bash
# Estimate deployment cost
solana program deploy target/deploy/program.so --dry-run

# Ensure you have 2x this amount for safety
```

### Step M5: Deploy to Mainnet

```bash
echo "⚠️  FINAL CONFIRMATION"
echo "Network: $(solana config get | grep 'RPC URL')"
echo "Deployer: $(solana address)"
echo "Balance: $(solana balance)"

# Deploy
anchor deploy --provider.cluster mainnet-beta

# SAVE PROGRAM ID IMMEDIATELY
PROGRAM_ID=$(solana address -k target/deploy/program-keypair.json)
echo "🎯 DEPLOYED PROGRAM ID: $PROGRAM_ID"

# Save to file
echo $PROGRAM_ID > .program-id-mainnet
```

### Step M6: Verify Mainnet Deployment

```bash
# Verify program is on mainnet
solana program show $PROGRAM_ID

# Check upgrade authority
UPGRADE_AUTH=$(solana program show $PROGRAM_ID | grep "Upgrade Authority" | awk '{print $3}')
echo "Upgrade Authority: $UPGRADE_AUTH"

# Explorer
echo "Explorer: https://explorer.solana.com/address/$PROGRAM_ID"

# Verify program binary
solana program dump $PROGRAM_ID program-dump.so
diff target/deploy/program.so program-dump.so
```

### Step M7: Initial Mainnet Testing

**Test with SMALL amounts first!**

```bash
# Test read-only operations first
# Test write operations with MINIMAL amounts (0.01 SOL)
# Monitor for any issues
```

### Step M8: Post-Deployment

```bash
# Save deployment info
cat > deployment-mainnet.json <<EOF
{
  "programId": "$PROGRAM_ID",
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployer": "$(solana address)",
  "network": "mainnet-beta",
  "upgradeAuthority": "$UPGRADE_AUTH"
}
EOF

# Update frontend
echo "NEXT_PUBLIC_PROGRAM_ID=$PROGRAM_ID" >> .env.production
```

### Step M9: Upgrade Authority Staging

<!-- Adapted from sendaifun/solana-new (deploy-to-mainnet), MIT -->
Don't freeze on day one — stage the path to immutability:

| Phase | Upgrade authority | Command |
|-------|-------------------|---------|
| Launch → ~3 months | Deployer key (hardware wallet) — bugs surface early, keep the ability to ship fixes fast | — |
| ~3 months post-launch | Squads multisig — removes single-key risk once stable | `solana program set-upgrade-authority $PROGRAM_ID --new-upgrade-authority <SQUADS_PDA>` |
| Post-audit, battle-tested | None / frozen — maximum trustlessness, IRREVERSIBLE | `solana program set-upgrade-authority $PROGRAM_ID --final` |

### Mainnet Checklist

- [ ] Program deployed successfully
- [ ] Visible on Solana explorer
- [ ] Program ID documented
- [ ] Initial tests passed
- [ ] Monitoring active
- [ ] Emergency procedures ready
- [ ] Team notified

---

## Emergency Procedures

### If Issues Detected on Mainnet

1. **Pause if possible** (if program has pause function)
2. **Document the issue** immediately
3. **Assess severity**
4. **Prepare upgrade** if needed
5. **Communicate** to users

### Program Upgrade

```bash
# Prepare upgrade
anchor build --verifiable

# Deploy upgrade
anchor upgrade target/deploy/program.so \
    --program-id $PROGRAM_ID \
    --upgrade-authority <path-to-keypair>

# Verify
solana program show $PROGRAM_ID
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Insufficient balance | Airdrop on devnet, fund wallet on mainnet |
| Program too large | Optimize code, use zero-copy |
| Wrong network | Verify with `solana config get` |
| Deployment timeout | Retry, network congestion |

## Critical Reminders

- ⚡ **Devnet first, always**
- 💰 Mainnet uses REAL SOL
- 🔒 Mainnet is IRREVERSIBLE
- 📊 Monitor after mainnet deployment
- 🚨 Have emergency procedures ready
- 🧪 Test with minimal amounts first

---

**Remember**: The extra time spent testing on devnet prevents costly mistakes on mainnet.
