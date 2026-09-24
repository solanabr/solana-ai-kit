---
description: "Run TypeScript tests for Solana frontends and Anchor programs"
---

You are running TypeScript tests. This command covers Anchor program tests, frontend component tests, and integration tests.

## Related Skills

- [testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Testing strategy details
- [frontend.md](../skills/ext/solana-dev/skills/solana-dev/references/frontend.md) - React/Next.js patterns
- [programs/anchor.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/anchor.md) - Anchor test patterns

## Step 1: Identify Test Type

```bash
echo "🔍 Detecting TypeScript test configuration..."

# Check for Anchor tests
if [ -f "Anchor.toml" ] && [ -d "tests" ]; then
    echo "⚓ Anchor TypeScript tests detected"
fi

# Check for Vitest
if grep -q "vitest" package.json 2>/dev/null; then
    echo "⚡ Vitest configured"
fi

# Check for Jest
if grep -q "jest" package.json 2>/dev/null; then
    echo "🃏 Jest configured"
fi

# Check for Playwright
if grep -q "playwright" package.json 2>/dev/null; then
    echo "🎭 Playwright E2E tests configured"
fi
```

---

## Anchor Program Tests

### Run Anchor Tests

```bash
echo "⚓ Running Anchor TypeScript tests..."

# Build first
anchor build

# Run all tests
anchor test

# Skip rebuild (faster iteration)
anchor test --skip-build

# Run specific test file
anchor test tests/vault.ts

# Run with logs
RUST_LOG=debug anchor test
```

### Anchor Test Pattern

```typescript
import * as anchor from "@anchor-lang/core";
import { Program } from "@anchor-lang/core";
import { MyProgram } from "../target/types/my_program";
import { expect } from "chai";

describe("my_program", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.MyProgram as Program<MyProgram>;

  it("initializes vault", async () => {
    const [vaultPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), provider.wallet.publicKey.toBuffer()],
      program.programId
    );

    await program.methods
      .initialize()
      .accounts({
        vault: vaultPda,
        authority: provider.wallet.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    const vault = await program.account.vault.fetch(vaultPda);
    expect(vault.authority.toString()).to.equal(
      provider.wallet.publicKey.toString()
    );
  });

  it("deposits funds", async () => {
    const [vaultPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), provider.wallet.publicKey.toBuffer()],
      program.programId
    );

    const depositAmount = new anchor.BN(1_000_000_000); // 1 SOL

    await program.methods
      .deposit(depositAmount)
      .accounts({
        vault: vaultPda,
        authority: provider.wallet.publicKey,
      })
      .rpc();

    const vault = await program.account.vault.fetch(vaultPda);
    expect(vault.balance.toNumber()).to.equal(depositAmount.toNumber());
  });

  it("fails with insufficient funds", async () => {
    const [vaultPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), provider.wallet.publicKey.toBuffer()],
      program.programId
    );

    try {
      await program.methods
        .withdraw(new anchor.BN(999_000_000_000)) // More than balance
        .accounts({
          vault: vaultPda,
          authority: provider.wallet.publicKey,
        })
        .rpc();
      expect.fail("Should have thrown");
    } catch (err) {
      expect(err.message).to.include("InsufficientFunds");
    }
  });
});
```

### LiteSVM TypeScript Tests

For faster tests without validator:

```bash
npm install --save-dev litesvm
```

```typescript
import { LiteSVM } from 'litesvm';
import { PublicKey, Transaction, Keypair } from '@solana/web3.js';

describe("litesvm tests", () => {
  let svm: LiteSVM;
  const programId = new PublicKey("YourProgramId...");

  beforeAll(() => {
    svm = new LiteSVM();
    svm.addProgramFromFile(programId, "target/deploy/program.so");
  });

  it("processes instruction", () => {
    const payer = Keypair.generate();
    svm.airdrop(payer.publicKey, 1_000_000_000);

    const tx = new Transaction();
    tx.recentBlockhash = svm.latestBlockhash();
    tx.add(/* your instruction */);
    tx.sign(payer);

    const result = svm.sendTransaction(tx);
    expect(result.err).toBeNull();
  });
});
```

---

## Frontend Component Tests

### Vitest Setup

```bash
echo "⚡ Running Vitest tests..."
npm run test
# or
npx vitest run
```

### React Component Test

```typescript
// components/__tests__/WalletButton.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { WalletButton } from '../WalletButton';

// Mock wallet hooks
vi.mock('@solana/wallet-adapter-react', () => ({
  useWallet: () => ({
    connected: false,
    connect: vi.fn(),
    disconnect: vi.fn(),
    publicKey: null,
  }),
}));

describe('WalletButton', () => {
  it('renders connect button when not connected', () => {
    render(<WalletButton />);
    expect(screen.getByText('Connect Wallet')).toBeInTheDocument();
  });

  it('calls connect on click', async () => {
    const { useWallet } = await import('@solana/wallet-adapter-react');
    const mockConnect = vi.fn();
    vi.mocked(useWallet).mockReturnValue({
      connected: false,
      connect: mockConnect,
      disconnect: vi.fn(),
      publicKey: null,
    });

    render(<WalletButton />);
    fireEvent.click(screen.getByText('Connect Wallet'));
    expect(mockConnect).toHaveBeenCalled();
  });
});
```

### Hook Testing

```typescript
// hooks/__tests__/useBalance.test.tsx
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useBalance } from '../useBalance';

describe('useBalance', () => {
  it('fetches balance for address', async () => {
    const mockAddress = 'So11111111111111111111111111111111111111112';

    const { result } = renderHook(() => useBalance(mockAddress));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.balance).toBeDefined();
  });

  it('returns null for invalid address', async () => {
    const { result } = renderHook(() => useBalance('invalid'));

    await waitFor(() => {
      expect(result.current.error).toBeDefined();
    });
  });
});
```

---

## E2E Tests with Playwright

### Setup

```bash
echo "🎭 Running Playwright E2E tests..."
npx playwright test
```

### E2E Test Pattern

```typescript
// e2e/wallet-flow.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Wallet Connection Flow', () => {
  test('connects wallet and shows balance', async ({ page }) => {
    await page.goto('/');

    // Click connect button
    await page.click('[data-testid="connect-wallet"]');

    // Wait for wallet modal
    await expect(page.locator('.wallet-modal')).toBeVisible();

    // Select wallet (mocked in test environment)
    await page.click('[data-testid="phantom-wallet"]');

    // Verify connected state
    await expect(page.locator('[data-testid="wallet-address"]')).toBeVisible();
    await expect(page.locator('[data-testid="balance"]')).toContainText('SOL');
  });

  test('sends transaction', async ({ page }) => {
    // Assume wallet is connected
    await page.goto('/transfer');

    await page.fill('[data-testid="recipient"]', 'So11111111111111111111111111111111111111112');
    await page.fill('[data-testid="amount"]', '0.01');
    await page.click('[data-testid="send-button"]');

    // Wait for confirmation
    await expect(page.locator('[data-testid="tx-signature"]')).toBeVisible({
      timeout: 30000,
    });
  });
});
```

---

## Test Commands Summary

```bash
# Anchor tests
anchor test                    # Full test run
anchor test --skip-build       # Skip rebuild
anchor test tests/vault.ts     # Specific file

# Vitest
npm run test                   # Run all
npx vitest run                 # Run once
npx vitest                     # Watch mode
npx vitest run --coverage      # With coverage

# Jest
npm test                       # Run all
npm test -- --watch            # Watch mode
npm test -- --coverage         # With coverage

# Playwright
npx playwright test            # Run all
npx playwright test --ui       # Interactive UI
npx playwright test --debug    # Debug mode
```

## Debugging Failed Tests

```bash
# Anchor with logs
RUST_LOG=debug anchor test

# Vitest with verbose output
npx vitest run --reporter=verbose

# Jest with debug
node --inspect-brk node_modules/.bin/jest --runInBand

# Playwright debug
npx playwright test --debug
```

## Mocking Patterns

### Mock Wallet Provider

```typescript
// test-utils/mocks.ts
export const mockWallet = {
  connected: true,
  publicKey: new PublicKey('So11111111111111111111111111111111111111112'),
  signTransaction: vi.fn(),
  signAllTransactions: vi.fn(),
  sendTransaction: vi.fn().mockResolvedValue('mock-signature'),
};

export const MockWalletProvider = ({ children }) => (
  <WalletContext.Provider value={mockWallet}>
    {children}
  </WalletContext.Provider>
);
```

### Mock RPC Responses

```typescript
// Mock getBalance
vi.mock('@solana/kit', () => ({
  createSolanaRpc: () => ({
    getBalance: vi.fn().mockResolvedValue({ value: 1_000_000_000n }),
    getAccountInfo: vi.fn().mockResolvedValue({ value: null }),
  }),
}));
```

## Test Checklist

Before deployment:

- [ ] All Anchor program tests pass
- [ ] Component tests pass
- [ ] Hook tests pass
- [ ] E2E critical paths pass
- [ ] Error states tested
- [ ] Loading states tested
- [ ] Edge cases covered
- [ ] Wallet connection/disconnection tested

---

**Remember**: Test user flows, not implementation details. Mock external dependencies, not your own code.
