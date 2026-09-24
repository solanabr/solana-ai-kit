---
description: "Benchmark CU usage and compare against baseline for regression detection"
---

You are running CU benchmarks for a Solana program and comparing results against a stored baseline. This detects performance regressions and tracks optimization progress.

## Related Skills

- [ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md) - CU optimization techniques
- [ext/solana-dev/skills/solana-dev/references/testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Test framework CU measurement

## Step 1: Setup

```bash
BENCHMARK_DIR=".claude/benchmarks"
BASELINE_FILE="$BENCHMARK_DIR/cu-baseline.json"
CURRENT_FILE="$BENCHMARK_DIR/cu-current.json"

mkdir -p "$BENCHMARK_DIR"

echo "Benchmark configuration:"
echo "  Baseline: $BASELINE_FILE"
echo "  Output:   $CURRENT_FILE"
echo ""

# Verify project
if [ ! -f "Anchor.toml" ] && [ ! -f "Cargo.toml" ]; then
    echo "No Anchor.toml or Cargo.toml found. Cannot benchmark."
    exit 1
fi
```

## Step 2: Build Program

```bash
echo "Building program..."

if [ -f "Anchor.toml" ]; then
    anchor build
else
    cargo build-sbf
fi

if [ $? -ne 0 ]; then
    echo "Build failed. Fix compilation errors before benchmarking."
    exit 1
fi

echo "Build successful."
echo ""
```

## Step 3: Run Tests with CU Measurement

```bash
echo "Running test suite with CU measurement..."
echo ""

export SBF_OUT_DIR=target/deploy

if [ -f "Anchor.toml" ]; then
    # Run Anchor tests, capture CU output
    anchor test --skip-deploy 2>&1 | tee /tmp/benchmark-output.txt
else
    cargo test 2>&1 | tee /tmp/benchmark-output.txt
fi

TEST_STATUS=$?
if [ $TEST_STATUS -ne 0 ]; then
    echo ""
    echo "Tests failed. Fix failures before benchmarking."
    exit 1
fi

echo ""
echo "Tests passed. Parsing CU data..."
```

## Step 4: Parse CU Results

Extract CU consumption per instruction from test output.

```bash
echo "Parsing CU usage from test output..."

# Extract lines with CU data
# Pattern: "Program <ID> consumed <N> of <M> compute units"
grep -i "consumed.*compute units" /tmp/benchmark-output.txt > /tmp/cu-lines.txt

TOTAL_INSTRUCTIONS=$(wc -l < /tmp/cu-lines.txt)
echo "Found $TOTAL_INSTRUCTIONS instruction CU measurements."
echo ""

# Display raw CU data
echo "Raw CU measurements:"
cat /tmp/cu-lines.txt
```

## Step 5: Generate Current Benchmark JSON

Build a JSON file with instruction-level CU data. The agent should parse the test output and create a structured JSON:

```json
{
  "timestamp": "2026-03-24T00:00:00Z",
  "commit": "<git-sha>",
  "instructions": {
    "initialize": { "cu": 25000, "limit": 200000 },
    "deposit": { "cu": 45000, "limit": 200000 },
    "withdraw": { "cu": 52000, "limit": 200000 },
    "transfer": { "cu": 38000, "limit": 200000 }
  }
}
```

```bash
# Get current commit for tagging
COMMIT=$(git rev-parse --short HEAD)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Generating benchmark data..."
echo "  Commit: $COMMIT"
echo "  Time:   $TIMESTAMP"
```

The agent should parse `/tmp/cu-lines.txt` and write the structured JSON to `$CURRENT_FILE`.

## Step 6: Compare with Baseline

```bash
if [ -f "$BASELINE_FILE" ]; then
    echo ""
    echo "=== Baseline Comparison ==="
    echo ""
    echo "Baseline: $BASELINE_FILE"
    echo "Current:  $CURRENT_FILE"
    echo ""

    # The agent should read both JSON files and produce a comparison table:
    echo "Instruction             | Baseline CU | Current CU | Delta      | Status"
    echo "------------------------|-------------|------------|------------|--------"

    # For each instruction, compute:
    # - Delta = current - baseline
    # - Status:
    #   - IMPROVED if delta < -5% of baseline
    #   - REGRESSION if delta > +5% of baseline
    #   - STABLE if within +/- 5%

    cat "$BASELINE_FILE"
    echo ""
    cat "$CURRENT_FILE"

    echo ""
    echo "Threshold: +/- 5% = stable, >5% increase = REGRESSION, >5% decrease = IMPROVED"
else
    echo ""
    echo "No baseline found at $BASELINE_FILE"
    echo "Current results will become the new baseline."
fi
```

## Step 7: Save or Update Baseline

```bash
if [ ! -f "$BASELINE_FILE" ]; then
    echo "Saving current results as baseline..."
    cp "$CURRENT_FILE" "$BASELINE_FILE"
    echo "Baseline saved to $BASELINE_FILE"
else
    echo ""
    echo "To update baseline with current results:"
    echo "  cp $CURRENT_FILE $BASELINE_FILE"
    echo ""
    echo "Only update baseline after intentional changes are verified."
fi
```

## Step 8: Summary Report

```bash
echo ""
echo "=== Benchmark Summary ==="
echo ""
echo "Commit:     $COMMIT"
echo "Timestamp:  $TIMESTAMP"
echo "Tests:      PASSED"
echo ""

# Per-instruction summary
echo "Instruction CU Usage:"
# The agent should output a clean summary table

echo ""
echo "Recommendations:"
# Flag any instructions over thresholds:
# > 200,000 CU: CRITICAL - must optimize
# > 100,000 CU: WARNING - review for optimization
# < 50,000 CU: GOOD

echo ""
echo "Files:"
echo "  Current benchmark: $CURRENT_FILE"
echo "  Baseline:          $BASELINE_FILE"
```

## CU Budget Reference

| Operation | Typical CU Cost |
|-----------|----------------|
| Account deserialization (Anchor) | 3,000 - 8,000 |
| Account deserialization (Pinocchio) | 200 - 500 |
| PDA find_program_address | ~1,500 |
| PDA create_program_address | ~200 |
| SPL Token transfer | ~4,500 |
| System transfer | ~2,100 |
| msg! macro | ~100 per call |
| SHA256 hash | ~100 per 32 bytes |
| Ed25519 verify | ~25,000 |

## After Benchmarking

- [ ] All instructions measured
- [ ] No regressions detected (or documented/justified)
- [ ] Baseline updated if intentional changes made
- [ ] Optimization plan for high-CU instructions
- [ ] Results committed to `.claude/benchmarks/`
