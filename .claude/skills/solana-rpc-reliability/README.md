# Solana RPC Reliability Skill

This is a production-oriented Solana AI Kit skill for diagnosing and fixing RPC,
transaction send, confirmation, priority fee, blockhash expiry, and provider failover
issues.

## Problem

Many Solana apps work locally but fail in production because transaction reliability is
treated as an SDK detail. Builders often conflate "sent" with "landed", reuse expired
blockhashes, wait forever on confirmation, swallow simulation logs, or run all traffic
through one RPC endpoint.

This skill gives agents a focused workflow for finding and fixing those failures.

## Included

- `SKILL.md`: concise entry point and routing guide.
- `references/diagnostic-workflow.md`: incident triage and endpoint health workflow.
- `references/transaction-send-patterns.md`: robust send/confirm patterns.
- `references/provider-abstraction.md`: provider failover and observability patterns.
- `scripts/rpc-health-check.mjs`: dependency-free RPC health diagnostic.
- `commands/debug-solana-rpc.md`: command workflow for incidents.
- `rules/typescript.md`: reliability-oriented TypeScript rules.

## Install

Copy the `solana-rpc-reliability` directory into a Solana AI Kit skills directory, or
submodule this repository and point the kit at:

```text
open-bounties/solana-ai-kit-skills/solana-rpc-reliability
```

## Run Diagnostic

```bash
node scripts/rpc-health-check.mjs --rpc https://api.mainnet-beta.solana.com --json
```

Compare providers:

```bash
node scripts/rpc-health-check.mjs \
  --rpc https://api.mainnet-beta.solana.com \
  --rpc https://api.devnet.solana.com \
  --json
```

## Questionnaire

**Did you contribute towards existing repos or is it a new idea?**

New skill idea, packaged to slot into the Solana AI Kit skill structure. It can be
submitted as a standalone skill repo/subdirectory or converted into a PR.

**What is your closest competing skill?**

The closest existing coverage is the Helius skill for provider-specific RPC products and
the core Solana dev skill for general transaction concepts. This skill focuses
specifically on cross-provider reliability diagnostics, send/confirm loops, blockhash
expiry, and production incident workflows.

**Founder-market fit / proof**

The repo includes a working diagnostic script, progressive references, and concrete
review rules. The creator agent also built and tested a Solana narrative detector and
Memo-program provenance tool in the same bounty workstream, demonstrating practical
Solana RPC usage.

