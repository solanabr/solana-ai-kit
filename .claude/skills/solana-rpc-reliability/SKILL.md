---
name: solana-rpc-reliability
description: Diagnose and improve Solana RPC, transaction send, confirmation, priority fee, blockhash expiry, endpoint failover, and production transaction reliability. Use when Codex is debugging flaky Solana dapps, wallets, bots, indexers, or backend send flows; designing reliable broadcast/confirm logic; comparing RPC providers; or adding monitoring for slot lag, health, latency, and transaction landing failures.
---

# Solana RPC Reliability

## Core Workflow

1. Classify the failure.
   - RPC read failure: timeouts, rate limits, inconsistent account data, slot lag.
   - Send failure: preflight error, blockhash expiry, dropped transaction, duplicate signature.
   - Landing failure: transaction sent but not confirmed, priority fee too low, compute budget too low.
   - UX failure: wallet signs but app gives no actionable status or retry path.

2. Collect minimal evidence.
   - Endpoint URL, cluster, commitment, slot, latest blockhash, last valid block height.
   - Transaction signature, recent blockhash used, compute budget, priority fee, simulation logs.
   - Error text from `sendTransaction`, `simulateTransaction`, and confirmation polling.

3. Load the relevant reference.
   - Read [references/diagnostic-workflow.md](references/diagnostic-workflow.md) for incident triage and endpoint checks.
   - Read [references/transaction-send-patterns.md](references/transaction-send-patterns.md) for robust send/confirm loops.
   - Read [references/provider-abstraction.md](references/provider-abstraction.md) when designing failover across RPC providers.

4. Run the bundled diagnostic when an RPC URL is available.

```bash
node scripts/rpc-health-check.mjs --rpc https://api.mainnet-beta.solana.com --json
```

5. Fix the smallest reliability boundary first.
   - Reads: timeout, retry with jitter, quorum/fallback for critical reads, slot-lag alerts.
   - Sends: fresh blockhash, explicit last valid block height, simulation, priority fee, rebroadcast.
   - Confirms: poll signature status until landed, expired, or failed; never wait indefinitely.

## Default Recommendations

- Use separate read and send paths. A cheap public RPC is acceptable for non-critical reads, but production sends need a reliable provider path.
- Treat `sendTransaction` as "accepted for forwarding", not "landed".
- Track `lastValidBlockHeight`; retrying after expiry without resigning is incorrect.
- Make priority fee and compute budget explicit for user-facing swaps, mints, claims, liquidations, and bots.
- Prefer bounded retries with jitter over unbounded loops.
- Surface transaction state to users: simulated, signed, sent, rebroadcasting, confirmed, expired, failed.
- Log endpoint latency, slot lag, status-code class, simulation logs, and signature status.

## Code Review Checklist

- No hardcoded single RPC endpoint in production paths.
- No confirmation loop without timeout or block-height expiry check.
- No reuse of expired blockhashes.
- No blind `skipPreflight: true` unless simulation happens elsewhere and is documented.
- No swallowed simulation logs.
- No wallet UX that says "success" before confirmation.
- Retry logic distinguishes retryable transport errors from deterministic instruction errors.

## Commands

- `/debug-solana-rpc`: Use [commands/debug-solana-rpc.md](commands/debug-solana-rpc.md) to run a structured RPC/transaction incident review.

