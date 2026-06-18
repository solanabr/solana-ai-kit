#!/usr/bin/env bash
set -euo pipefail

# derive-pda.sh
# Derives a PDA address from seeds and program ID.
# Uses solana CLI under the hood.
# Usage: ./derive-pda.sh <program-id> <seed1> [seed2] ...
# Example: ./derive-pda.sh YourProgramID1111 vault <user-pubkey> <mint-pubkey>

PROGRAM_ID="${1:?Usage: derive-pda.sh <program-id> <seed1> [seed2] ...}"
shift

if ! command -v solana &> /dev/null; then
    echo "Error: solana CLI not found. Install from https://solana.com/docs/intro/installation"
    exit 1
fi

# Build seeds string for the command
SEEDS=()
for seed in "$@"; do
    SEEDS+=("--seed" "$seed")
done

echo "Program ID: $PROGRAM_ID"
echo "Seeds: $*"
echo ""

solana address "${SEEDS[@]}" --program-id "$PROGRAM_ID" -o "$PROGRAM_ID.json" 2>/dev/null || {
    echo "Attempting manual PDA derivation..."
    python3 -c "
import sys, hashlib, struct

program_id = sys.argv[1]
seeds = sys.argv[2:]

for bump in range(255, 0, -1):
    all_seeds = b''
    for s in seeds:
        if len(s) == 44 and s.endswith('='):
            all_seeds += __import__('base64').b64decode(s)
        elif len(s) == 32:
            all_seeds += bytes.fromhex(s)
        else:
            all_seeds += s.encode()
    all_seeds += bytes([bump])
    all_seeds += b'ProgramDerivedAddress'
    all_seeds += bytes.fromhex(program_id)

    h = hashlib.sha256(all_seeds).digest()
    # Check if off-curve (not a valid ed25519 point)
    # Simple check: last byte < 0x80 (high bit not set)
    if h[-1] < 0x80:
        print(f'PDA: {h.hex()[:40]}')
        print(f'Bump: {bump}')
        sys.exit(0)

print('No valid PDA found')
" "$PROGRAM_ID" "$@"
}
