---
description: "Measure compute units per instruction and flag the expensive ones"
---

Measure CU per instruction for the program(s) in $ARGUMENTS (default: every program in the workspace) and point at the costly code. To compare with the stored baseline (`.claude/benchmarks/cu-baseline.json`) or save a new one, use `/benchmark`. Harness APIs: [testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md); optimization techniques: [programs/pinocchio.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/pinocchio.md).

## Steps

1. Build the way you deploy (`anchor build` / `cargo build-sbf`) with debug-log features off, since `msg!` formatting inflates CU.
2. Collect CU per instruction from whichever harness the project has:
   - Mollusk: `compute_units_consumed` on the instruction result; `MolluskComputeUnitBencher` writes a markdown table with deltas to its `out_dir`.
   - LiteSVM: the metadata returned by `send_transaction` carries `compute_units_consumed`; send one instruction per transaction to isolate it.
   - Surfpool, for real mainnet accounts and CPIs into deployed protocols: `surfnet_profileTransaction` returns `transactionProfile.computeUnitsConsumed` and per-instruction `instructionProfiles`. Starting Surfpool with `--ci` disables instruction profiling, and a v1 transaction budgets 0 CU unless `computeUnitLimit` is set.
   - Logs: `Program <id> consumed N of M compute units` appears once per invocation, and an outer program's figure already includes its CPIs, so don't add nested lines together.

   Measure each instruction's worst path (most accounts, longest vectors, first-time init) as well as the happy path.
3. Inside a costly instruction, bracket sections with `sol_log_compute_units()` to find where the CU goes.
4. Classify:

   | CU per instruction | Verdict |
   |---|---|
   | < 50k | Efficient |
   | 50k-100k | Fine; review if on a hot path |
   | 100k-200k | Warning: little headroom for CPIs or composing with other instructions |
   | > 200k | Critical: above the 200k per-instruction default of legacy/v0 txs, so every client must raise the limit (1.4M max per tx); optimize or split |

5. Suggest fixes for the costly ones: store the canonical bump and verify with it (`bump = acct.bump`), since each derivation attempt costs 1,500 CU and `find_program_address` may need several; remove or feature-gate `msg!`, especially with formatting; zero-copy (`AccountLoader`) for large accounts; fewer and smaller account deserializations. Hand CU-bound hot paths to pinocchio-engineer.

## Output

Table: instruction | CU happy path | CU worst path | % of 200k | verdict | top cost. Then the 1-3 highest-impact optimizations with `file:line`.
