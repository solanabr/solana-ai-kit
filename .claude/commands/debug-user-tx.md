---
description: "Reproduce and debug a user-reported failing transaction against forked cluster state, mapping the failure back to source code"
---

You are debugging a transaction that a user reports as failing. You have the project's source code locally; the goal is to reproduce the failure against forked cluster state, then map the on-chain error back to the exact line of Rust / IDL that produced it and suggest a fix.

## Related Skills

- [ext/solana-dev/skill/references/testing.md](../skills/ext/solana-dev/skill/references/testing.md) — Surfpool (mainnet fork), LiteSVM, Mollusk
- [ext/solana-dev/skill/references/programs/anchor.md](../skills/ext/solana-dev/skill/references/programs/anchor.md) — Anchor error codes, constraint failures
- [ext/solana-dev/skill/references/programs/pinocchio.md](../skills/ext/solana-dev/skill/references/programs/pinocchio.md) — Pinocchio error patterns
- [ext/solana-dev/skill/references/security.md](../skills/ext/solana-dev/skill/references/security.md) — Common failure categories

## Inputs

Collect from the user (at least one of `signature` or `instruction` is required):

| Input | Required | Notes |
|-------|----------|-------|
| `signature` | preferred | On-chain tx signature. Fastest path — fetch + replay. |
| `wallet` | optional | User's pubkey. Auto-extracted from tx if signature given. |
| `instruction` | fallback | Raw ix JSON when the tx never landed (serialized tx / accounts + data). |
| `cluster` | optional | `mainnet` / `devnet`. Default: infer from `Anchor.toml` or `.env`. |
| `rpc` | optional | Override RPC endpoint. Default: cluster default or project `.env`. |
| `program` | optional | Program ID. Auto-detected from workspace. |

If the user only pasted an error message, ask for the signature before proceeding — it's the difference between 30 seconds and guessing.

## Step 1: Detect Project Layout

```bash
echo "Detecting project..."

FRAMEWORK="unknown"
if [ -f "Anchor.toml" ]; then
    FRAMEWORK="anchor"
    echo "Anchor project detected"
elif [ -f "Cargo.toml" ] && grep -q "pinocchio" Cargo.toml 2>/dev/null; then
    FRAMEWORK="pinocchio"
    echo "Pinocchio project detected"
elif [ -f "Cargo.toml" ] && grep -q "solana-program" Cargo.toml 2>/dev/null; then
    FRAMEWORK="native"
    echo "Native Solana program detected"
else
    echo "No Solana program workspace detected. Debug will proceed RPC-only (no source mapping)."
fi

# Infer cluster
CLUSTER="${CLUSTER:-mainnet}"
if [ -f "Anchor.toml" ]; then
    DETECTED=$(grep -m1 'cluster' Anchor.toml | sed 's/.*= *//' | tr -d '"')
    [ -n "$DETECTED" ] && CLUSTER="$DETECTED"
fi
echo "Cluster: $CLUSTER"

# Collect program IDs + IDLs
ls target/idl/*.json 2>/dev/null || echo "No IDLs found at target/idl/ — run 'anchor build' for best results"
```

## Step 2: Fetch the Failing Transaction

If a signature was provided, fetch it with full detail. Use the project's RPC if configured; otherwise fall back to the cluster default.

```bash
SIG="<signature>"
RPC="${RPC:-https://api.$CLUSTER.solana.com}"

mkdir -p .claude/debug
OUT=".claude/debug/tx-${SIG:0:8}.json"

curl -s -X POST "$RPC" \
  -H "Content-Type: application/json" \
  -d "$(cat <<EOF
{
  "jsonrpc":"2.0","id":1,"method":"getTransaction",
  "params":["$SIG",{"encoding":"json","maxSupportedTransactionVersion":0,"commitment":"confirmed"}]
}
EOF
)" > "$OUT"

# Sanity check
jq -e '.result != null' "$OUT" >/dev/null || { echo "Tx not found or not yet confirmed"; exit 1; }
```

Extract from the JSON (Claude: read `$OUT` with `jq` or the Read tool):

- `meta.err` — the error object (e.g. `{"InstructionError":[1,{"Custom":6003}]}`)
- `meta.logMessages` — full program log output
- `meta.preBalances` / `meta.postBalances`
- `meta.preTokenBalances` / `meta.postTokenBalances`
- `meta.innerInstructions` — CPI tree
- `slot` — for fork replay
- `transaction.message.accountKeys` — ordered account list
- `transaction.message.instructions` — each with `programIdIndex`, `accounts`, `data`
- `transaction.message.addressTableLookups` — resolve if present

## Step 3: Identify the Failing Instruction

From `meta.err`, extract the instruction index. For `InstructionError: [N, ...]`, instruction `N` failed.

```bash
FAILING_IX=$(jq -r '.result.meta.err.InstructionError[0]' "$OUT")
FAILING_PROGRAM=$(jq -r --argjson i "$FAILING_IX" \
  '.result.transaction.message.accountKeys[.result.transaction.message.instructions[$i].programIdIndex]' \
  "$OUT")
echo "Failing instruction #$FAILING_IX → program $FAILING_PROGRAM"
```

> **Note**: Index 0 is almost always `ComputeBudget` (`setComputeUnitLimit` / `setComputeUnitPrice`). The real failure is usually index ≥ 1. Trust `meta.err.InstructionError[0]`, not position.

> **Address Table Lookups**: If `transaction.message.addressTableLookups` is non-empty, extend the account list before indexing: `accountKeys ++ meta.loadedAddresses.writable ++ meta.loadedAddresses.readonly`. Otherwise you'll resolve the wrong program for CPI-heavy txs.

Compare `$FAILING_PROGRAM` against the project's program IDs (from `declare_id!` or `Anchor.toml`). If it matches, source mapping is possible. If not (e.g. Jupiter, Token Program), the failure is inside a CPI target — note this and proceed with log-based diagnosis.

### Decode the instruction discriminator

`instructions[N].data` is **base58-encoded** when fetched with `encoding: "json"` (what Step 2 uses). Decode before slicing.

For the project's own program:

- **Anchor**: first 8 bytes of decoded data = handler discriminator.
  - Anchor ≥ 0.30: match directly against `target/idl/<program>.json` → `instructions[].discriminator`.
  - Anchor < 0.30: IDL has no `discriminator` field. Compute it: `sha256("global:<handler_name>")[0..8]`, then match.
- **Pinocchio / native**: typically first 1 byte. Match against the `match` arm in `process_instruction` (grep `src/lib.rs` or `src/entrypoint.rs`).

Record the handler name.

## Step 4: Map the Error to Source

**Fast path — scan `meta.logMessages` first.** Anchor emits one of these formats depending on how the error was raised:

```
# From err!() / return Err(ErrorCode::X.into()) — includes source file:line directly
Program log: AnchorError thrown in <path/to/file.rs>:<line>. Error Code: <CodeName>. Error Number: <N>. Error Message: "<msg>".

# From a constraint violation in #[derive(Accounts)]
Program log: AnchorError caused by account: <account_name>. Error Code: <CodeName>. Error Number: <N>.

# Generic form
Program log: AnchorError occurred. Error Code: <CodeName>. Error Number: <N>. Error Message: "<msg>".
```

When any of these are present, this skips discriminator math entirely: you get the error variant name and often the source location in one line. The `thrown in <file>:<line>` form is the gold standard — quote it directly in the report. Always scan for all three before falling back to error-code lookups.

Based on `meta.err`:

### Anchor `Custom(N)` codes

Anchor user errors start at 6000. Match against the project's `#[error_code]` enum:

```bash
# For the matched program's crate
grep -rn "#\[error_code\]" programs/ | head -5

# Then list the enum variants in order; Custom(6000+i) → variant[i]
```

Claude: read the error enum file, count from 0, report `variant name + #[msg(...)] text + file:line`.

### Anchor constraint errors (2000–2999)

Well-known codes — map directly:

| Code | Meaning | Where to look |
|------|---------|---------------|
| 2000 | ConstraintMut | Missing `mut` on an account |
| 2001 | ConstraintHasOne | `has_one` mismatch |
| 2002 | ConstraintSigner | Account not a signer |
| 2003 | ConstraintRaw | Custom `constraint = ...` failed |
| 2006 | ConstraintSeeds | PDA mismatch |
| 2011 | ConstraintOwner | Wrong program owner |
| 2012 | ConstraintRentExempt | Not rent-exempt |
| 2019 | ConstraintTokenMint | Token account mint mismatch |
| 3007 | AccountDiscriminatorMismatch | Wrong account type passed |
| 3012 | AccountNotInitialized | Expected initialized account |

Read the failing instruction's `#[derive(Accounts)]` struct and list the constraints in order; line up with the error.

### Pinocchio / native `ProgramError`

```bash
grep -rn "ProgramError::Custom\|const ERROR_" programs/ src/ 2>/dev/null | head -20
```

Map `Custom(N)` to the const or enum-derived discriminant. For standard `ProgramError` variants (`InvalidAccountData`, `MissingRequiredSignature`, etc.), report the variant name directly.

### Log-based hints

Scan `meta.logMessages` for:

- `Program log: AnchorError caused by account: <name>. Error Code: <Code>. Error Number: <N>.` — direct pointer to the failing account
- `Program log: Left: X` / `Right: Y` — Anchor constraint comparisons
- `Program log: <any msg!()>` — follow breadcrumbs the program author left
- `Program <id> failed: <reason>`

Quote the last 10–15 log lines in the report.

## Step 5: Local Replay (optional but recommended)

Replay against forked state at `slot - 1` to confirm the diagnosis and enable iteration.

### Option A: Surfpool (preferred — real fork)

```bash
SLOT=$(jq -r '.result.slot' "$OUT")
FORK_SLOT=$((SLOT - 1))

# Start surfpool forking from just before the failure
surfpool start --fork-url "$RPC" --fork-slot "$FORK_SLOT" &
SURFPOOL_PID=$!
sleep 3

# Replay the serialized transaction against the local fork
# surfpool exposes an RPC on localhost:8899 that mirrors the forked state
# A helper script can reuse .claude/debug/tx-*.json to rebuild + resend the ix

# Clean up when done
# kill $SURFPOOL_PID
```

### Option B: LiteSVM (fast, minimal — no fork)

Useful when you want to isolate the instruction with synthetic accounts built from the captured pre-state:

```rust
// .claude/debug/replay.rs (scaffold — Claude should generate per-project)
use litesvm::LiteSVM;
use solana_sdk::{pubkey::Pubkey, account::Account, transaction::Transaction};

fn main() {
    let mut svm = LiteSVM::new();
    // Load program bytes from target/deploy/<name>.so
    svm.add_program_from_file(PROGRAM_ID, "target/deploy/program.so").unwrap();

    // Seed each account with pre-state captured from meta.preBalances / account data
    // (Claude: read account data via getAccountInfo at FORK_SLOT and inject here)

    let tx: Transaction = /* reconstruct from captured instruction */;
    let result = svm.send_transaction(tx);
    println!("{:#?}", result);
}
```

Claude: only scaffold Option B if Surfpool is unavailable; otherwise prefer A.

## Step 6: Account State Diff

For each writable account in the failing instruction:

```bash
# Extract writable accounts (those with isWritable=true in the message)
# Compare pre vs expected-post balances and data

jq -r '.result.meta | {
  preBalances: .preBalances,
  postBalances: .postBalances,
  preTokenBalances: .preTokenBalances,
  postTokenBalances: .postTokenBalances
}' "$OUT"
```

Fetch current on-chain state for each writable account via `getAccountInfo`. Flag anomalies:

- Owner != expected program
- Insufficient lamports for rent exemption
- Uninitialized account (all zeros) where handler expects initialized
- Discriminator mismatch
- Stale data (e.g. last_update older than expected)

## Step 7: Build the Report

Output a single structured markdown report to stdout. Do **not** write a file unless the user asks.

```
## Debug report: <short-sig or "reconstructed">

- Cluster: <mainnet|devnet>
- Slot: <N>
- Fee payer: <pubkey>
- Wallet: <user pubkey>

### Failure
Instruction #<i> → program `<id>` (<project-name> / <external>)
Handler: `<handler_name>` — <path/to/file.rs>:<line>
Error: <ErrorName> (code <N>) — "<#[msg] text>"
  defined at <path/to/errors.rs>:<line>

### Root cause (likely)
<one-paragraph explanation tying the error to the handler's logic and the observed account state>

Relevant guard: <path/to/handler.rs>:<line>
```rust
require!(<condition>, ErrorCode::<Variant>);
```

### Account state (writable)
| Account | Role | Pre | Post (expected) | Status |
|---|---|---|---|---|
| <pubkey> | vault PDA | 0 lamports | rent-exempt | ❌ uninitialized |
| ... | ... | ... | ... | ... |

### Program logs (tail)
```
<last 10–15 lines from meta.logMessages>
```

### Reproduction
```
surfpool start --fork-url <rpc> --fork-slot <N-1>
# then replay: <command or steps>
```

### Suggested next steps
1. <actionable fix, with file:line pointer>
2. <client-side mitigation if relevant>
3. <test to add so this fails fast next time>
```

## Modes

### Mode A: signature provided (80% case)
Full flow: Steps 1 → 2 → 3 → 4 → 6 → 7. Step 5 (replay) is optional; skip if the on-chain diagnosis is already conclusive.

### Mode B: no signature (tx never landed)
User provides the raw instruction + wallet. Steps 1 → 3 (skip fetch) → 5 (replay is now mandatory since there's no on-chain record) → 4 (map error from replay logs) → 6 → 7.

### Mode C: unknown program
If the failing program isn't the project's own (e.g. failure inside a Jupiter/Token CPI), skip source mapping but still run Steps 4 (log-based) and 6 (state diff), and flag that the root cause is outside this codebase.

## Guardrails

- **Never** ask the user for a private key. Simulation and replay require no signatures.
- **Never** broadcast a transaction. This command is read + replay only.
- Cache fetched tx JSON under `.claude/debug/` so Claude can re-read without hitting RPC again.
- If RPC rate-limits, suggest setting `RPC=<helius/quicknode>` and retry.
- If the program at `FAILING_PROGRAM` is not in the workspace, say so explicitly — don't invent source mappings.

## Checklist

- [ ] Transaction fetched and `meta.err` extracted
- [ ] Failing instruction index and program identified
- [ ] Handler name resolved via IDL / discriminator match
- [ ] Error code mapped to source (variant name + `#[msg]` text + file:line)
- [ ] Writable account state diff produced
- [ ] Program logs tail captured
- [ ] Root cause hypothesis stated with file:line pointer
- [ ] Reproduction steps included
- [ ] At least one suggested fix with source location

---

**Remember**: The dev's question is "where in *my* code did this fail?" Your job is to answer that with file paths and line numbers, not generic advice.
