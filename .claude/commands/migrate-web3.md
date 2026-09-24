---
description: "Migrate from @solana/web3.js to @solana/kit"
---

You are migrating a codebase from `@solana/web3.js` to `@solana/kit` (the modern Solana TypeScript SDK). This is a file-by-file migration with verification.

## Related Skills

- [ext/solana-dev/skills/solana-dev/references/kit-web3-interop.md](../skills/ext/solana-dev/skills/solana-dev/references/kit-web3-interop.md) - Kit/web3.js interop patterns and boundary handling
- [ext/solana-dev/skills/solana-dev/references/frontend.md](../skills/ext/solana-dev/skills/solana-dev/references/frontend.md) - Kit-first frontend patterns

## Step 1: Detect web3.js Usage

```bash
echo "Scanning for @solana/web3.js usage..."
echo ""

# Find all files importing web3.js
echo "Files importing @solana/web3.js:"
grep -rn "from.*@solana/web3\.js" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" . | grep -v node_modules | grep -v ".next"

echo ""
echo "Total files:"
grep -rl "from.*@solana/web3\.js" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" . | grep -v node_modules | grep -v ".next" | wc -l

echo ""
echo "Import breakdown:"
grep -roh "import.*from.*@solana/web3\.js" --include="*.ts" --include="*.tsx" . | grep -v node_modules | sort | uniq -c | sort -rn
```

## Step 2: Detect Specific APIs in Use

```bash
echo "Detecting specific web3.js APIs in use..."
echo ""

# Connection usage
echo "Connection instances:"
grep -rn "new Connection\|Connection(" --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l

# PublicKey usage
echo "PublicKey usage:"
grep -rn "new PublicKey\|PublicKey\." --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l

# Transaction usage
echo "Transaction/VersionedTransaction:"
grep -rn "new Transaction\|VersionedTransaction\|TransactionInstruction" --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l

# Keypair usage
echo "Keypair usage:"
grep -rn "Keypair\." --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l

# sendTransaction
echo "sendTransaction calls:"
grep -rn "sendTransaction\|sendAndConfirmTransaction" --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l

# Token program
echo "SPL Token usage:"
grep -rn "@solana/spl-token" --include="*.ts" --include="*.tsx" . | grep -v node_modules | wc -l
```

## Step 3: Key Migration Mappings

Reference these when transforming each file:

### Core Type Mappings

| web3.js | @solana/kit | Notes |
|---------|-------------|-------|
| `Connection` | `createSolanaRpc()` | Functional, not class-based |
| `PublicKey` | `Address` (string type) | Use `address()` to validate |
| `Keypair` | `await generateKeyPair()` | Returns `CryptoKeyPair` |
| `Transaction` | `pipe(createTransactionMessage(...), ...)` | Functional pipeline |
| `VersionedTransaction` | `compileTransaction(msg)` | Compiled from message |
| `TransactionInstruction` | `IInstruction` | Interface, not class |
| `SystemProgram.transfer()` | `getTransferSolInstruction()` | From `@solana/system` |
| `sendAndConfirmTransaction` | `sendAndConfirmTransactionFactory()` | Factory pattern |
| `LAMPORTS_PER_SOL` | `lamports(1_000_000_000n)` | Branded `bigint` type |

### Package Mapping

| Old Package | New Package(s) |
|-------------|----------------|
| `@solana/web3.js` | `@solana/kit` (umbrella) |
| `@solana/spl-token` | `@solana/spl-token` (updated) or Codama-generated |
| `@solana/wallet-adapter-*` | `@solana/wallet-standard` + `@wallet-standard/react` |
| `@coral-xyz/anchor` (legacy pre-1.0 name) | `@anchor-lang/core` (Anchor 1.0 rename; compatible with both web3.js versions) |

### Common Patterns

```typescript
// OLD: Connection
const connection = new Connection("https://api.mainnet-beta.solana.com");
const balance = await connection.getBalance(publicKey);

// NEW: RPC
import { createSolanaRpc } from "@solana/kit";
const rpc = createSolanaRpc("https://api.mainnet-beta.solana.com");
const balance = await rpc.getBalance(address).send();

// OLD: Transaction
const tx = new Transaction().add(instruction);
const sig = await sendAndConfirmTransaction(connection, tx, [payer]);

// NEW: Transaction message pipeline
import { pipe, createTransactionMessage, setTransactionMessageFeePayer,
    appendTransactionMessageInstruction, signAndSendTransactionMessageWithSigners } from "@solana/kit";
const msg = pipe(
    createTransactionMessage({ version: 0 }),
    m => setTransactionMessageFeePayer(payerAddress, m),
    m => setTransactionMessageLifetimeUsingBlockhash(blockhash, m),
    m => appendTransactionMessageInstruction(instruction, m),
);

// OLD: PublicKey
const pubkey = new PublicKey("So11111111111111111111111111111111111111112");

// NEW: Address
import { address } from "@solana/kit";
const addr = address("So11111111111111111111111111111111111111112");
```

## Step 4: Install New Dependencies

```bash
echo "Installing @solana/kit..."
npm install @solana/kit

# If using specific sub-packages
# npm install @solana/rpc @solana/signers @solana/transactions @solana/addresses

echo ""
echo "Current @solana packages:"
grep "@solana" package.json | grep -v "//"
```

## Step 5: Generate Migration Plan

For each file found in Step 1, create a migration plan:

1. **Read the file** - Identify all web3.js imports and usage
2. **Map imports** - Replace `@solana/web3.js` imports with `@solana/kit` equivalents
3. **Transform types** - `PublicKey` to `Address`, `Keypair` to `CryptoKeyPair`, etc.
4. **Transform patterns** - Class instantiation to functional calls
5. **Update tests** - Ensure test files use new APIs
6. **Verify compilation** - `npx tsc --noEmit` after each file

## Step 6: Migrate File by File

For each file:

```bash
# After migrating a file, verify it compiles
npx tsc --noEmit

if [ $? -ne 0 ]; then
    echo "TypeScript errors after migration. Review and fix before continuing."
fi
```

## Step 7: Verify Migration

```bash
echo "Verifying migration..."
echo ""

# Check for remaining web3.js imports
REMAINING=$(grep -rl "from.*@solana/web3\.js" --include="*.ts" --include="*.tsx" . | grep -v node_modules | grep -v ".next")

if [ -z "$REMAINING" ]; then
    echo "No remaining @solana/web3.js imports."
else
    echo "Files still using @solana/web3.js:"
    echo "$REMAINING"
fi

# Type check
echo ""
echo "Running type check..."
npx tsc --noEmit

# Run tests
echo ""
echo "Running tests..."
npm test
```

## Migration Strategy

- **Incremental**: Migrate one file at a time, verify after each
- **Boundary pattern**: If some code must stay on web3.js temporarily, use the interop boundary from kit-web3-interop.md
- **Tests first**: Migrate test utilities first, then shared code, then page-level code
- **Anchor compatibility**: `@anchor-lang/core` (renamed from `@coral-xyz/anchor` in Anchor 1.0) works with both; migrate around it

## After Migration

- [ ] No `@solana/web3.js` imports remain (or documented exceptions)
- [ ] All TypeScript compiles cleanly
- [ ] All tests pass
- [ ] Remove `@solana/web3.js` from package.json if fully migrated
- [ ] Update any documentation referencing web3.js patterns
