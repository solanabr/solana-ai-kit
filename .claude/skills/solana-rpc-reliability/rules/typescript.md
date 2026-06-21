# TypeScript Rules

- Keep RPC provider boundaries explicit; do not hide endpoint choice in global state.
- Represent transaction status as a discriminated union, not booleans.
- Preserve simulation logs in thrown errors.
- Add timeout or block-height expiry to every confirmation path.
- Do not label a transaction successful before confirmation.

