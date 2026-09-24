# Provider Abstraction

Use this when a dapp, bot, wallet, or backend needs more than one RPC endpoint.

## Recommended Shape

Create a small provider boundary instead of passing `Connection` everywhere:

```ts
interface SolanaRpcPool {
  read<T>(operation: RpcOperation<T>): Promise<T>;
  send(rawTransaction: Uint8Array, options: SendOptions): Promise<string>;
  confirm(signature: string, context: BlockhashContext): Promise<ConfirmationResult>;
  health(): Promise<RpcEndpointHealth[]>;
}
```

## Endpoint Classes

- `read`: cheap, cached, lower priority.
- `send`: low latency, high reliability, provider key required.
- `confirm`: must be current; can be same provider as send or a quorum across providers.
- `archive`: expensive historical requests, separated from user flows.

## Failover Rules

- Fail over on transport errors, 429s, and provider outages.
- Do not fail over deterministic instruction errors.
- Avoid quorum for every request; use it only for critical state or suspicious stale reads.
- Keep provider-specific telemetry so a broken endpoint is visible.

## Logs To Keep

- endpoint label, cluster, request method
- latency in milliseconds
- status code or RPC error code
- slot returned by contextual methods
- transaction signature
- blockhash and last valid block height
- confirmation status and elapsed time

