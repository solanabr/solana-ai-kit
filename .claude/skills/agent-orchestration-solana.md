---
name: agent-orchestration-solana
description: Multi-agent orchestration patterns for Solana development — chain specialized agents together for architect→implement→test→audit→deploy workflows with decision traces, uncertainty quantification, and automated handoffs.
---

# Agent Orchestration for Solana Development

Chain multiple specialized AI agents together for production Solana workflows. Each agent handles one phase and passes context to the next, with decision traces, uncertainty quantification, and automated quality gates.

## Why Orchestrate?

Solana programs have a high failure surface: account validation, CPI safety, pda derivation, arithmetic correctness, and upgrade authority management. A single pass misses too much. Orchestration applies **multiple specialized perspectives** in sequence, each catching what the previous missed.

The Kit ships 15 specialized agents. Orchestration is the pattern that combines them into a pipeline.

## Pipeline: Architect → Implement → Test → Audit → Deploy

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│Architect │───▶│Implement │───▶│   Test   │───▶│  Audit   │───▶│  Deploy  │
│(design)  │    │(code)    │    │(verify)  │    │(security)│    │(release) │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │               │               │               │               │
     ▼               ▼               ▼               ▼               ▼
 Decision       Code +         Test          Audit          Deployment
  Trace        Tests         Report         Report          Manifest
```

### Phase 1: Architect (`solana-architect`)

Generate a structured design document before any code. The architect agent explores the design space and outputs a scored decision trace.

```markdown
## Decision Trace: Token Vesting Program

| Decision | Option A | Option B | Winner | Confidence |
|----------|----------|----------|--------|------------|
| Account model | Single PDA per vesting | User-owned + escrow PDA | Option A | 0.85 |
| Cliff mechanism | Timestamp check | Slot number check | Option A | 0.72 |
| Revocation | Freeze authority | Timelock DAO | Option B | 0.91 |
```

**Uncertainty rule**: If any decision has confidence < 0.7, flag for human review before proceeding.

**Output artifacts**: `docs/decisions/{program-name}-architecture.md`

### Phase 2: Implement (`anchor-engineer`)

The implementer agent reads the architecture doc and produces code. Each module gets a self-contained Anchor program.

```bash
# Scaffold from architecture
solana-ai-kit:scaffold --from docs/decisions/token-vesting-architecture.md
```

**Implementation checklist:**
- [ ] All accounts validated in every instruction
- [ ] CPI targets hardcoded (never dynamic)
- [ ] PDA bumps stored, not recalculated
- [ ] Arithmetic uses `checked_*` or safe math
- [ ] No `unwrap()` in program code
- [ ] Error codes cover all failure paths
- [ ] Events emitted on all state changes

**Output artifacts**: `programs/{name}/`, `tests/{name}.ts`

### Phase 3: Test (`solana-qa-engineer`)

The QA agent generates test cases from the architecture and implementation, targeting edge cases the implementer missed.

```typescript
// Generated test template from decision trace
describe("TokenVesting", () => {
  // From uncertainty trace — edge cases the architect flagged
  describe("Cliff mechanism", () => {
    it("releases at exact cliff timestamp", async () => { /* ... */ });
    it("reverts 1 second before cliff", async () => { /* ... */ });
    it("handles overflow when cliff > i64::MAX", async () => { /* ... */ });
  });

  // Fuzz harness
  it.fuzz("handles any valid schedule", async (fuzz) => {
    const schedule = {
      cliff: fuzz.u64(),
      duration: fuzz.u64().filter(n => n > 0),
      amount: fuzz.u64(),
    };
    // invariant: total released never exceeds total allocated
  });
});
```

**Quality gates:**
- Unit tests: ≥ 10 per instruction
- Fuzz tests: ≥ 1 per state-modifying instruction
- Invariant tests: ≥ 1 covering all state transitions
- Test coverage: ≥ 90% of instruction handlers

**Output artifacts**: `tests/{name}.ts`, `tests/fuzz/{name}.ts`

### Phase 4: Audit (`solana-researcher` + `devops-engineer`)

Run the audit agent against the code and tests. It applies multiple heuristics:

```yaml
audit_report:
  program: token-vesting
  findings:
    - severity: high
      category: account-validation
      description: "Missing owner check on vesting_account"
      file: programs/token-vesting/src/instructions/release.rs
      line: 42
      remediation: "Add `has_one = authority` constraint"
    - severity: medium
      category: arithmetic
      description: "Potential precision loss in percentage calculation"
      file: programs/token-vesting/src/math.rs
      line: 15
      remediation: "Use checked_mul before division"
  passing: 12
  failing: 2
  score: 0.86
```

### Phase 5: Deploy (`devops-engineer` + deploy command)

```bash
# Staged rollout
solana-ai-kit:deploy --env devnet --verify
solana-ai-kit:deploy --env testnet --verify
# After 24h monitoring:
solana-ai-kit:deploy --env mainnet --multisig ./upgrade-authority-keypair.json
```

## Orchestration Handoff Protocol

When one agent finishes, it writes a structured handoff file for the next:

```yaml
# .handoffs/architect-to-implementer.yaml
phase: architect → implementer
trace_id: "0x7a3f...b91c"
decisions:
  - id: "account-model"
    confidence: 0.85
    rationale: "Single PDA reduces CPI surface"
    flagged: false
  - id: "cliff-mechanism"
    confidence: 0.72
    rationale: "Timestamp aligns with real-world schedules"
    flagged: true  # needs human review
pending_review:
  - "cliff-mechanism — confidence below threshold"
artifacts:
  - "docs/decisions/token-vesting-architecture.md"
```

## Running the Pipeline

```bash
# Full pipeline (auto)
./orchestrate.sh --program token-vesting --pipeline full

# Individual phases
./orchestrate.sh --program token-vesting --phase architect
./orchestrate.sh --program token-vesting --phase implement
./orchestrate.sh --program token-vesting --phase test
./orchestrate.sh --program token-vesting --phase audit
./orchestrate.sh --program token-vesting --phase deploy

# Resume from last completed phase
./orchestrate.sh --program token-vesting --pipeline resume
```

## Understanding Decision Traces

A Decision Trace records **what was decided, what was rejected, and why**. A trace has four dimensions:

| Dimension | What It Captures | Solana Example |
|-----------|-----------------|----------------|
| **Uncertainty (P)** | Confidence score per decision | "account model confidence: 0.85" |
| **Search (C)** | Alternatives explored | "considered 3 PDA derivation strategies" |
| **Temporal (T)** | When decisions were made, decay | "design finalized 2026-06-20, still valid" |
| **Equilibrium (B)** | Tradeoff resolution | "chose security over gas efficiency (λ=0.7)" |

This framework is based on the 4D Decision-Trace system used by the Antigravity Empire's Mastra orchestration layer.

## Integration with CI/CD

```yaml
# .github/workflows/solana-orchestrate.yml
name: Solana Agent Pipeline
on: [push, pull_request]
jobs:
  orchestrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: solanabr/solana-ai-kit@v2
      - name: Run audit pipeline
        run: |
          solana-ai-kit:audit-solana --program programs/my-program
          solana-ai-kit:diff-review --base origin/main
```

## References

- Solana AI Kit agents: `.claude/agents/` (15 specialized agents)
- Decision Trace framework: originated from Mastra 4D orchestration (P/C/T/B dimensions)
- Solana security checklist: adapted from `.claude/rules/` in the kit
