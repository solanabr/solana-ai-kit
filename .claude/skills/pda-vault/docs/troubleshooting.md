# PDA Vault Troubleshooting Guide

## Initialization Failures

### "Account already in use"
- The PDA seeds produce an address that already exists
- Solution: Add a nonce or index to the seed set

### "Account address mismatch"
- Client-derived PDA doesn't match on-chain
- Solution: Verify seeds are identical on client and program — most common bug is wrong byte order

### "Invalid seeds"
- The seeds don't correspond to a valid PDA (on the curve)
- Solution: Use `find_program_address` instead of `create_program_address`

## Deposit Failures

### "ConstraintTokenOwner"
- The vault's token account is owned by the wrong program
- Solution: Ensure ATA was created with the vault PDA as authority

### "ConstraintRawAmount"
- Token account doesn't have enough tokens
- Solution: Check user's source token account balance

### "Overflow"
- Balance exceeds u64::MAX
- Solution: Add overflow checks — practically impossible but defensively code it

## Withdraw Failures

### "Missing required signature"
- PDA signing seeds are wrong or missing
- Solution: Verify seeds + bump match `find_program_address` output exactly

### "Account not signed by PDA"
- `invoke_signed` seeds are incorrect
- Solution: The signer seeds must match the exact seeds used in `init`

### "Insufficient funds"
- Vault balance < withdrawal amount
- Solution: Check `vault.balance >= amount` before processing

## Time-Lock Issues

### "TokensLocked"
- Clock time hasn't reached unlock_time
- Solution: Wait or check clock. Slot-based timing is faster than timestamp-based

### "InvalidUnlockTime"
- unlock_time set in the past
- Solution: Validate `unlock_time > Clock::get()?.unix_timestamp` at initialization

## Multi-Sig Issues

### "Not authorized"
- Signer not in the signers list
- Solution: Admin must add signer first

### "Already approved"
- Signer already voted
- Solution: Duplicate votes are rejected

### "Threshold not met"
- Not enough approvals
- Solution: Wait for more signers

## Testing Tips

1. **Use `solana-test-validator` with `--clone`** to fork mainnet state for realistic tests
2. **Log all PDA derivations** — `msg!("PDA: {:?}", pda)` saves hours of debugging
3. **Test with Mollusk** — fastest feedback loop for vault logic
4. **Simulate before sending** — always use `--simulate` flag on mainnet
5. **Watch for rent edge cases** — vaults with zero balance can be closed by anyone if not protected
