---
name: security-posture-guardian
description: Solana program security analysis methodology — static analysis, fuzzing, manual review, and proof-of-concept workflow covering Anchor, native Rust, and Pinocchio programs.
---

# Security Posture Guardian

Enterprise-grade security analysis workflow for Solana programs. Combines static analysis, fuzzing, manual review, and PoC development to identify and validate vulnerabilities. Applies to Anchor, native Rust, and Pinocchio programs.

## Prerequisites

- Anchor framework (v0.30+): CLI tools for Anchor programs
- Solana CLI + SDK: Local test validator
- Cargo: For native program builds
- Forge (Foundry): Solidity fuzzing — adaptable to Solana via program-derived test patterns

## Methodology

### Phase 1: Static Analysis

Run automated analysis tools and manual code review:

```
# Analyze dependency tree for known-vulnerable versions
cargo audit

# Check for common Rust security anti-patterns
cargo clippy -- -W clippy::pedantic -W clippy::cargo

# Anchor-specific — verify constraint correctness, signer checks
# Manual: check every #[account(...)] constraint and signer seed derivation
```

**Checklist (50+ items across 6 categories):**

1. **Access Control** — missing signer checks, incorrect `has_one`, `seeds` with attacker-controlled prefixes, PDA signing without proper authorization
2. **Arithmetic** — unchecked overflow (pre-v0.30), rounding direction in financial math, decimal scaling errors
3. **CPI Safety** — arbitrary CPI targets, unvalidated return data, reentrancy via CPI to untrusted programs
4. **Account Validation** — type confusion, missing `close` constraints, rent-exemption assumptions, account discriminator forgery
5. **PDA Derivation** — seed malleability, missing bump canonicalization (`findProgramAddress` vs `createProgramAddress`), collision attacks
6. **Oracle/External Data** — unvalidated price feeds, stale timestamps, manipulation via sandwich attacks

### Phase 2: Fuzzing & Property Testing

Use program-derived test harnesses to verify invariants under random conditions:

```
# Anchor test with fuzz-aware patterns — use mollusk or litesvm for faster cycles
anchor test --skip-deploy

# For native programs — use custom fuzz harness with arbitrary inputs
cargo fuzz run target -- -runs=100000
```

**Key properties to fuzz:**
- State transitions from all valid and edge-case account states
- Arithmetic: balance conservation, invariant preservation
- Access control: all signer permutations including unexpected signers
- Reentrancy: recursive CPI call chains
- Rounding: deposit/withdraw round-trip consistency

### Phase 3: Manual Review

Follow the architecture-first approach:

1. **Understand the program model** — read IDL, account structs, instruction enum → map state machine
2. **Trace critical paths** — identify high-value instructions (withdrawals, admin controls, oracle feeds)
3. **Verify invariants** — for each state transition, confirm all guards are enforced
4. **Look for composability issues** — interactions between instructions within the same program and across programs

**Pattern Library — Common Solana Vulnerabilities:**

| Pattern | Severity | Detection |
|---------|----------|-----------|
| Missing signer check on admin instruction | Critical | `solana-verify` / manual review of `ctx.accounts` |
| Unchecked account type (no discriminator) | High | Look for `Account` without `has_one` or seed constraint |
| CPI to user-supplied program | Critical | Any `invoke` with program_id from accounts |
| Reinitialization via missing discriminator | High | Anchor v0.30+ uses `init_if_needed` — verify guard |
| Seed derivation with user input | High | Trace PDA seeds to ensure attacker can't collide |
| Rounding always in caller's favor | Medium | Financial math: verify rounding direction benefits protocol, not user |
| Oracle price manipulation | High | Check TWAP, min/max bounds, freshness requirements |

### Phase 4: Proof of Concept

For each confirmed vulnerability, produce a minimal reproduction:

```
// Anchor test PoC template — run with anchor test
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { TargetProgram } from "../target/types/target_program";

describe("vulnerability-poc", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const program = anchor.workspace.TargetProgram as Program<TargetProgram>;

  it("demonstrates the vulnerability", async () => {
    // Build attacker accounts
    // Construct exploit instruction
    // Assert the undesired outcome
  });
});
```

## Risk Scoring

Use CVSS 3.1 adapted for Solana:

| Score | Severity | Example | Action |
|-------|----------|---------|--------|
| 9.0-10.0 | Critical | Missing signer on drain | Immediate disclosure |
| 7.0-8.9 | High | Oracle manipulation | Expedite fix |
| 4.0-6.9 | Medium | Locked accounts on error | Fix next release |
| 0.1-3.9 | Low | Event log missing | Acceptable risk |

## Reference Tools

- **Slither** (experimental Solana support): Static analysis for Solidity → adaptable patterns
- **Aderyn**: Solidity AST analysis → Solana equivalent patterns via manual translation
- **Foundry**: Fuzzing engine — write invariant tests adapted for program account models
- **Anchor CLI**: Built-in verification, account constraint checks
- **Cargo Audit**: Dependency vulnerability scanning
- **Trident**: Fuzzing framework for Solana programs (use for Phase 2)

## Reporting

Generate a security posture report containing:
1. **Summary**: Attack surface overview, total findings by severity
2. **Methodology**: Tools, approaches, coverage areas
3. **Detailed Findings**: For each — description, impact, reproduction steps, PoC, fix recommendation
4. **Appendices**: Full analysis logs, fuzz run results, dependency audit
