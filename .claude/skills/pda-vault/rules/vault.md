When writing vault code:

1. Always use checked_add/checked_sub for balance math
2. Never skip PDA seed verification in accounts struct
3. Always verify the token account owner matches the vault PDA
4. Use close constraint or manual close to reclaim rent
5. Emit events for deposit and withdraw
6. Always verify the caller is a signer
7. Never use unwrap() in production vault code
8. Test with both valid and invalid signers
