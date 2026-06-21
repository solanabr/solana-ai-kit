# Diagnostic Workflow

Use this when a Solana app has intermittent RPC failures, stale reads, slow confirmation,
or unclear transaction status.

## Incident Triage

Record these facts before changing code:

- Cluster: mainnet-beta, devnet, testnet, localnet.
- Endpoint provider and URL shape.
- Commitment used for reads and confirmation.
- Current slot from the endpoint.
- Latest blockhash and last valid block height.
- Error text and HTTP status.
- Whether the failure affects reads, sends, or confirmations.

## Endpoint Health Checks

Run:

```bash
node scripts/rpc-health-check.mjs --rpc <RPC_URL> --json
```

Interpretation:

- `healthOk=false`: endpoint is not healthy enough for production sends.
- `latencyMs > 800`: acceptable for some reads, risky for time-sensitive sends.
- `slotLag` compared to another endpoint: if one endpoint is consistently behind, avoid it for confirmation.
- `tpsSample=0`: performance sample request failed or endpoint is degraded.

## Failure Classes

### Rate Limited

Symptoms:

- HTTP 429.
- Provider-specific quota error.
- Request succeeds after a delay.

Fix:

- Add request budgeting.
- Cache stable reads.
- Separate user traffic from background indexers.
- Use provider keys per environment instead of shared public endpoints.

### Stale Reads

Symptoms:

- Account state differs across endpoints.
- UI shows old balance after confirmed transaction.

Fix:

- Read from the same provider used for confirmation during critical flows.
- Include slot/context in logs.
- Use `minContextSlot` after a transaction lands when reading dependent state.

### Confirmation Hangs

Symptoms:

- Signature exists locally but UI spins forever.
- `confirmTransaction` waits until timeout without explaining expiry.

Fix:

- Confirm with signature, blockhash, and last valid block height.
- Poll `getSignatureStatuses`.
- Stop on `blockHeight > lastValidBlockHeight`.
- Rebuild and resign when expired.

### Dropped Transaction

Symptoms:

- `sendTransaction` returns a signature but explorers never show it.
- Same transaction sometimes lands only after repeated sends.

Fix:

- Rebroadcast the same signed transaction until landed or expired.
- Send to multiple trusted RPC providers when the action is high value.
- Increase priority fee for congested routes.

