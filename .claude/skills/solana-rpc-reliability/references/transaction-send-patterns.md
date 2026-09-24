# Transaction Send Patterns

Use this when implementing or reviewing production transaction flows.

## Robust Send And Confirm Loop

Pseudocode:

```ts
const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash("confirmed");
const tx = buildTransaction({ blockhash, feePayer });
addComputeBudgetIfNeeded(tx);
const simulation = await connection.simulateTransaction(tx);
if (simulation.value.err) throw new SimulationError(simulation.value.logs);

const signed = await wallet.signTransaction(tx);
const raw = signed.serialize();
const signature = getSignature(signed);

while (true) {
  await connection.sendRawTransaction(raw, {
    skipPreflight: true,
    maxRetries: 0,
  }).catch(ignoreRetryableTransportError);

  const status = await connection.getSignatureStatuses([signature], {
    searchTransactionHistory: false,
  });

  if (status.value[0]?.err) throw new TransactionFailed(status.value[0].err);
  if (status.value[0]?.confirmationStatus === "confirmed" || status.value[0]?.confirmationStatus === "finalized") {
    return signature;
  }

  const blockHeight = await connection.getBlockHeight("confirmed");
  if (blockHeight > lastValidBlockHeight) throw new BlockhashExpired(signature);
  await sleepWithJitter(400, 900);
}
```

## Priority Fees

Use explicit priority fees for:

- Swaps and perps.
- Liquidations and keepers.
- Claims during high-traffic launches.
- NFT mints.
- User actions where "landed soon" matters more than minimum cost.

Pattern:

```ts
import { ComputeBudgetProgram } from "@solana/web3.js";

tx.add(
  ComputeBudgetProgram.setComputeUnitLimit({ units: 300_000 }),
  ComputeBudgetProgram.setComputeUnitPrice({ microLamports: 5_000 })
);
```

Tune from provider fee APIs or recent prioritization fee samples, not hardcoded forever.

## Preflight

Use preflight by default for user-facing flows while developing. For production high-speed
senders, it is acceptable to set `skipPreflight: true` only when:

- The exact transaction was already simulated.
- Simulation logs are recorded.
- The flow has deterministic error reporting.
- Confirmation still checks on-chain status.

## Blockhash Expiry

Never retry an expired transaction by sending the same bytes. Once the last valid block
height passes, rebuild with a fresh blockhash and request a new signature.

