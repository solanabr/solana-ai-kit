---
description: "Compare per-instruction CU with the stored baseline to catch regressions"
---

Measure CU per instruction and compare it with the baseline in `.claude/benchmarks/cu-baseline.json`. $ARGUMENTS: optional program or instruction filter. For one-off profiling and optimization advice, use `/profile-cu`.

## Steps

1. Build (`anchor build` / `cargo build-sbf`) and run the tests. Stop if any fail, since CU from failing paths is meaningless.
2. Measure with the same harness, inputs and toolchain as the baseline, because platform-tools and Agave upgrades shift CU on their own. Repeatable sources: `MolluskComputeUnitBencher`, LiteSVM `compute_units_consumed`, or Surfpool `surfnet_profileTransaction` with a tag plus `surfnet_getProfileResultsByTag`.
3. Write `.claude/benchmarks/cu-current.json`:
   ```json
   {"timestamp": "<ISO 8601>", "commit": "<short sha>",
    "instructions": {"deposit": {"cu": 45000, "limit": 200000}}}
   ```
4. With no baseline yet, copy the current file to `cu-baseline.json` and say so. Otherwise compare per instruction: a delta above +5% of the baseline is a REGRESSION, below -5% is IMPROVED, anything else is STABLE. List new and removed instructions separately, and flag any instruction above 100k CU (warning) or 200k CU (critical: over the default per-instruction budget).
5. Replace the baseline only after the user confirms the changes are intended.

## Output

Table: instruction | baseline | current | delta % | status. For each regression, give the commit range and the likely cause from the diff of that instruction's code since the baseline commit.

`.claude/` is gitignored by default in kit installs; run `/commit-claude-config` if CI or teammates should share the baseline.
