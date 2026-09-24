---
description: "Scaffold a new Solana project with programs, frontend, tests, and CI"
---

You are scaffolding a new Solana project. Detect the project type and generate appropriate structure with this config pre-installed.

## Related Skills

- [ext/solana-dev/skills/solana-dev/references/programs/anchor.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/anchor.md) - Anchor program patterns
- [ext/solana-dev/skills/solana-dev/references/frontend.md](../skills/ext/solana-dev/skills/solana-dev/references/frontend.md) - Frontend scaffolding
- [ext/solana-dev/skills/solana-dev/references/testing.md](../skills/ext/solana-dev/skills/solana-dev/references/testing.md) - Test setup

## Step 1: Determine Project Type

Ask the user or detect from context. Options:

1. **Anchor program only** - On-chain program with tests
2. **Fullstack** - Anchor program + Next.js frontend + tests
3. **Frontend only** - Next.js/React app connecting to existing programs
4. **Native program** - Pinocchio/solana-program with tests

```bash
echo "Checking existing project indicators..."

[ -f "Anchor.toml" ] && echo "Anchor project detected"
[ -f "Cargo.toml" ] && echo "Rust project detected"
[ -f "package.json" ] && echo "Node project detected"
[ -f "next.config.js" ] || [ -f "next.config.mjs" ] && echo "Next.js detected"

# Check for Solana CLI
solana --version 2>/dev/null || echo "WARNING: Solana CLI not installed"
anchor --version 2>/dev/null || echo "WARNING: Anchor CLI not installed"
```

## Step 2: Scaffold - Anchor Program

```bash
PROJECT_NAME="${1:-my-solana-program}"

echo "Scaffolding Anchor program: $PROJECT_NAME"

# Initialize Anchor project
anchor init "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Verify structure
echo ""
echo "Project structure:"
ls -la
ls -la programs/*/src/
```

## Step 3: Scaffold - Fullstack (Anchor + Frontend)

```bash
PROJECT_NAME="${1:-my-solana-dapp}"

echo "Scaffolding fullstack project: $PROJECT_NAME"

# Option A: Use create-solana-dapp (recommended)
if command -v npx >/dev/null 2>&1; then
    npx create-solana-dapp@latest "$PROJECT_NAME"
    cd "$PROJECT_NAME"
else
    echo "npx not available. Manual scaffold..."
    anchor init "$PROJECT_NAME"
    cd "$PROJECT_NAME"

    # Add frontend manually
    mkdir -p app
    cd app
    npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
    npm install @solana/kit @solana/wallet-standard @wallet-standard/react
    cd ..
fi

echo "Fullstack project created."
```

## Step 4: Scaffold - Frontend Only

```bash
PROJECT_NAME="${1:-my-solana-frontend}"

echo "Scaffolding frontend: $PROJECT_NAME"

npx create-next-app@latest "$PROJECT_NAME" --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
cd "$PROJECT_NAME"

# Install Solana dependencies (Kit-first)
npm install @solana/kit @solana/wallet-standard @wallet-standard/react

echo "Frontend project created with @solana/kit."
```

## Step 5: Copy Claude Config

```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SOURCE="${SCRIPT_DIR}/../../.."  # Adjust path to solana-ai-kit root

echo "Installing Claude Code configuration..."

# Copy .claude directory
if [ -d "$CONFIG_SOURCE/.claude" ]; then
    cp -r "$CONFIG_SOURCE/.claude" .
    echo "Copied .claude/ config"
else
    echo "WARNING: Could not find .claude config source at $CONFIG_SOURCE"
    echo "Manually copy from solana-ai-kit:"
    echo "  cp -r /path/to/solana-ai-kit/.claude ."
    echo "  cp /path/to/solana-ai-kit/CLAUDE-solana.md ./CLAUDE.md"
fi

# Copy CLAUDE.md
if [ -f "$CONFIG_SOURCE/CLAUDE-solana.md" ]; then
    cp "$CONFIG_SOURCE/CLAUDE-solana.md" ./CLAUDE.md
    echo "Copied CLAUDE.md"
fi

# Initialize submodules for skills
if [ -f ".gitmodules" ]; then
    git submodule update --init --recursive
    echo "Initialized skill submodules"
fi
```

## Step 6: Setup Git and Branch Workflow

```bash
echo "Setting up git..."

# Initialize git if not already
if [ ! -d ".git" ]; then
    git init
fi

# Create .gitignore if missing
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'GITIGNORE'
# Dependencies
node_modules/
.yarn/

# Build
target/
.next/
out/
dist/

# Environment
.env
.env.local
.env*.local

# IDE
.idea/
.vscode/
*.swp

# Solana
test-ledger/
.anchor/

# OS
.DS_Store
Thumbs.db
GITIGNORE
    echo "Created .gitignore"
fi

# Initial commit
git add -A
git commit -m "feat: scaffold $PROJECT_NAME with solana-ai-kit"

echo ""
echo "Git initialized with initial commit."
echo "Branch workflow: git checkout -b <type>/<scope>-<description>-<DD-MM-YYYY>"
```

## Step 7: Add Test Infrastructure

```bash
echo "Setting up test infrastructure..."

# For Anchor projects
if [ -f "Anchor.toml" ]; then
    # Ensure test dependencies
    if [ -f "package.json" ]; then
        npm install --save-dev @anchor-lang/core mocha chai @types/mocha @types/chai ts-mocha
    fi

    # Create test template if tests dir is empty
    if [ ! "$(ls -A tests/ 2>/dev/null)" ]; then
        mkdir -p tests
        echo "// Test file will be generated after first anchor build"
        echo "// Run: anchor test"
    fi
fi

# For frontend projects
if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
    npm install --save-dev vitest @testing-library/react @testing-library/jest-dom
fi

echo "Test infrastructure ready."
```

## Step 8: Verify Scaffold

```bash
echo ""
echo "=== Scaffold Complete ==="
echo ""
echo "Project: $PROJECT_NAME"
echo "Structure:"
find . -maxdepth 3 -not -path './node_modules/*' -not -path './.git/*' -not -path './target/*' -not -path './.next/*' | head -40

echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. Review CLAUDE.md for development guidelines"
echo "  3. Run: anchor build (if Anchor project)"
echo "  4. Run: anchor test (to verify setup)"
echo "  5. Start building with Claude Code"
```

## Project Type Reference

| Type | Command | Includes |
|------|---------|----------|
| Anchor only | `anchor init` | Program, tests, Anchor.toml |
| Fullstack | `create-solana-dapp` | Program, Next.js app, tests, wallet UI |
| Frontend only | `create-next-app` + Kit | Next.js, @solana/kit, wallet-standard |
| Native | `cargo init --lib` | Cargo project, manual BPF setup |

## After Scaffolding

- [ ] Project compiles/builds cleanly
- [ ] `.claude/` config installed
- [ ] `CLAUDE.md` present at project root
- [ ] Git initialized with initial commit
- [ ] Test infrastructure in place
- [ ] Ready for development
