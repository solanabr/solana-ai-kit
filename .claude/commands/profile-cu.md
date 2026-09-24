---
description: "Profile compute unit usage per instruction in a Solana program"
---

You are profiling CU (compute unit) consumption for a Solana program. This identifies expensive instructions and optimization opportunities.

## Related Skills

- [ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md) - CU optimization patterns
- [ext/solana-dev/skills/solana-dev/references/testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Test framework CU measurement

## Step 1: Verify Program

```bash
echo "Detecting program..."

if [ ! -f "Anchor.toml" ]; then
    echo "No Anchor.toml found. This command requires an Anchor project."
    echo "For native programs, use 'solana program show <PROGRAM_ID>' and manual CU logging."
    exit 1
fi

# Extract program IDs from Anchor.toml
echo "Programs in Anchor.toml:"
grep -A 5 '\[programs' Anchor.toml

# Check if deployed (optional)
CLUSTER=$(grep -m1 'cluster' Anchor.toml | sed 's/.*= *//' | tr -d '"')
echo "Cluster: ${CLUSTER:-localnet}"
```

## Step 2: Build Program

```bash
echo "Building program..."
anchor build

if [ $? -ne 0 ]; then
    echo "Build failed. Fix compilation errors before profiling."
    exit 1
fi

# Report binary size
echo ""
echo "Program binary sizes:"
ls -lh target/deploy/*.so | awk '{print $5, $9}'
```

## Step 3: Run Tests with CU Logging

```bash
echo "Running tests with CU profiling enabled..."

# Set environment for verbose CU logging
export SBF_OUT_DIR=target/deploy
export RUST_LOG=solana_runtime::message_processor=trace

# Run Anchor tests and capture output
anchor test --skip-deploy 2>&1 | tee /tmp/cu-profile-output.txt

TEST_STATUS=$?
if [ $TEST_STATUS -ne 0 ]; then
    echo "Tests failed. Fix test failures before profiling CU."
    exit 1
fi
```

## Step 4: Parse CU Usage

Extract CU consumption from test output. Look for patterns like:
- `consumed X of Y compute units`
- `Program <ID> consumed <N> of <M> compute units`

```bash
echo ""
echo "=== CU Profile Results ==="
echo ""

# Extract CU lines from test output
grep -i "consumed.*compute units" /tmp/cu-profile-output.txt | \
    sed 's/.*Program //' | \
    sort -t' ' -k3 -n -r | \
    head -50

echo ""
echo "--- Per-Instruction Breakdown ---"
echo ""

# Parse into table format
grep -i "consumed.*compute units" /tmp/cu-profile-output.txt | \
    awk '{
        for(i=1;i<=NF;i++) {
            if($i=="consumed") { cu=$(i+1) }
            if($i=="of") { limit=$(i+1) }
        }
        if(cu && limit) {
            pct = (cu/limit)*100
            printf "%-60s %8s / %-8s (%5.1f%%)\n", $0, cu, limit, pct
        }
    }'
```

## Step 5: Compare with Baseline

```bash
BASELINE=".claude/benchmarks/cu-baseline.json"

if [ -f "$BASELINE" ]; then
    echo ""
    echo "=== Baseline Comparison ==="
    echo ""
    echo "Baseline file: $BASELINE"
    echo ""

    # Read baseline and compare
    # Format expected: {"instruction_name": cu_value, ...}
    echo "Instruction             | Baseline | Current  | Delta    | Status"
    echo "------------------------|----------|----------|----------|--------"

    # Parse current results into comparable format
    # The agent should read the baseline JSON and compare instruction-by-instruction
    cat "$BASELINE"
else
    echo ""
    echo "No baseline found at $BASELINE"
    echo "To create a baseline, save current results:"
    echo "  mkdir -p .claude/benchmarks"
    echo "  echo '{\"instruction_name\": cu_value}' > $BASELINE"
fi
```

## Step 6: Optimization Analysis

Analyze the CU profile and flag optimization opportunities:

### CU Thresholds

| Range | Status | Action |
|-------|--------|--------|
| < 50,000 CU | Efficient | No action needed |
| 50,000 - 150,000 CU | Normal | Review if hot path |
| 150,000 - 300,000 CU | Heavy | Optimize data access, reduce allocations |
| > 300,000 CU | Critical | Refactor: split instruction, use zero-copy, cache PDAs |

### Common CU Optimizations

1. **Store PDA bumps** - `find_program_address` costs ~1,500 CU per call; `create_program_address` with stored bump costs ~200 CU
2. **Zero-copy deserialization** - Use `AccountLoader` instead of `Account` for large structs
3. **Reduce logging** - `msg!()` costs ~100 CU per call; use `#[cfg(feature = "debug")]` guards
4. **Minimize account loads** - Each account deserialization has a CU cost proportional to data size
5. **Use Pinocchio** - For CU-critical paths, consider Pinocchio over Anchor (~50-70% CU reduction)

## After Profiling

- [ ] CU usage per instruction documented
- [ ] High-CU instructions identified
- [ ] Baseline saved to `.claude/benchmarks/cu-baseline.json`
- [ ] Optimization plan created for instructions > 150,000 CU
- [ ] Re-profile after optimizations to verify improvement
