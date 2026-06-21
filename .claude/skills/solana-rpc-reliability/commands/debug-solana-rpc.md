# /debug-solana-rpc

Use this command when a user reports flaky Solana RPC, slow confirmations, dropped
transactions, or transaction status ambiguity.

## Steps

1. Ask for the RPC URL, cluster, signature if available, and the failing code path.
2. Run `node scripts/rpc-health-check.mjs --rpc <RPC_URL> --json` if a URL is provided.
3. Classify the issue as read, send, landing, or UX failure.
4. Inspect transaction send code for:
   - stale blockhash reuse
   - missing last valid block height checks
   - unbounded confirmation loops
   - swallowed simulation logs
   - absent priority fee / compute budget where needed
5. Return:
   - likely root cause
   - evidence
   - minimal fix
   - test or monitor to prevent recurrence

