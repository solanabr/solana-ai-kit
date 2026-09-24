---
description: "Build web client application (Next.js, React, Vite)"
---

You are building a web client application. Follow these steps:

## Related Skills

- [frontend.md](../skills/ext/solana-dev/skills/solana-dev/references/frontend.md) - React/Next.js patterns

## Step 1: Detect Framework

```bash
echo "🔍 Detecting web framework..."

# Check for Next.js
if grep -q "\"next\"" package.json 2>/dev/null; then
    echo "⚡ Next.js project detected"
    FRAMEWORK="nextjs"
# Check for Vite
elif [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
    echo "⚡ Vite project detected"
    FRAMEWORK="vite"
# Check for Create React App
elif grep -q "react-scripts" package.json 2>/dev/null; then
    echo "⚛️  Create React App detected"
    FRAMEWORK="cra"
# Generic React/Node
elif [ -f "package.json" ]; then
    echo "📦 Node.js project detected"
    FRAMEWORK="node"
else
    echo "❌ No package.json found"
    exit 1
fi
```

## Step 2: Install Dependencies

```bash
echo "📦 Installing dependencies..."

# Check for lock files to determine package manager
if [ -f "pnpm-lock.yaml" ]; then
    PKG_MANAGER="pnpm"
elif [ -f "yarn.lock" ]; then
    PKG_MANAGER="yarn"
elif [ -f "bun.lockb" ]; then
    PKG_MANAGER="bun"
else
    PKG_MANAGER="npm"
fi

echo "Using package manager: $PKG_MANAGER"

# Install
$PKG_MANAGER install
```

## Step 3: Environment Configuration

```bash
echo "🔧 Checking environment configuration..."

# Check for required env files
if [ -f ".env.example" ] && [ ! -f ".env.local" ]; then
    echo "⚠️  Missing .env.local - copying from .env.example"
    cp .env.example .env.local
    echo "📝 Please update .env.local with your values"
fi

# Verify Solana program ID is set
if grep -q "PROGRAM_ID\|NEXT_PUBLIC_PROGRAM_ID" .env.local 2>/dev/null; then
    echo "✅ Program ID configured"
else
    echo "⚠️  Warning: No PROGRAM_ID found in environment"
    echo "   Add: NEXT_PUBLIC_PROGRAM_ID=<your-program-id>"
fi

# Verify RPC endpoint
if grep -q "RPC_URL\|NEXT_PUBLIC_RPC" .env.local 2>/dev/null; then
    echo "✅ RPC endpoint configured"
else
    echo "ℹ️  Using default RPC endpoint"
fi
```

## Step 4: Type Check (TypeScript)

```bash
echo "📝 Running type check..."

if [ -f "tsconfig.json" ]; then
    $PKG_MANAGER run typecheck 2>/dev/null || npx tsc --noEmit
    
    if [ $? -eq 0 ]; then
        echo "✅ Type check passed"
    else
        echo "❌ Type errors found - fix before building"
        exit 1
    fi
else
    echo "ℹ️  No TypeScript config found, skipping type check"
fi
```

## Step 5: Lint Check

```bash
echo "🔍 Running linter..."

if grep -q "eslint" package.json 2>/dev/null; then
    $PKG_MANAGER run lint 2>/dev/null || npx eslint . --ext .ts,.tsx,.js,.jsx
    
    if [ $? -eq 0 ]; then
        echo "✅ Lint check passed"
    else
        echo "⚠️  Lint warnings found (non-blocking)"
    fi
fi
```

## Step 6: Build Application

```bash
echo "🔨 Building application..."

case $FRAMEWORK in
    "nextjs")
        echo "Building Next.js app..."
        $PKG_MANAGER run build
        
        # Check build output
        if [ -d ".next" ]; then
            echo "✅ Next.js build successful"
            echo ""
            echo "📊 Build output:"
            du -sh .next
        fi
        ;;
        
    "vite")
        echo "Building Vite app..."
        $PKG_MANAGER run build
        
        if [ -d "dist" ]; then
            echo "✅ Vite build successful"
            echo ""
            echo "📊 Build output:"
            du -sh dist
            ls -lh dist
        fi
        ;;
        
    "cra")
        echo "Building Create React App..."
        $PKG_MANAGER run build
        
        if [ -d "build" ]; then
            echo "✅ CRA build successful"
            echo ""
            echo "📊 Build output:"
            du -sh build
        fi
        ;;
        
    *)
        echo "Building with default script..."
        $PKG_MANAGER run build
        ;;
esac
```

## Step 7: Verify Build

```bash
echo ""
echo "🔍 Verifying build..."

# Check for common issues
verify_build() {
    local build_dir=$1
    
    # Check for source maps in production (security concern)
    if find "$build_dir" -name "*.map" | head -1 | grep -q .; then
        echo "⚠️  Warning: Source maps found in build"
        echo "   Consider disabling for production"
    fi
    
    # Check bundle sizes
    echo ""
    echo "📦 Bundle analysis:"
    if [ "$FRAMEWORK" = "nextjs" ]; then
        # Next.js has built-in bundle analysis
        cat .next/build-manifest.json 2>/dev/null | head -20 || true
    else
        # Generic bundle size check
        find "$build_dir" -name "*.js" -exec ls -lh {} \; | head -10
    fi
}

case $FRAMEWORK in
    "nextjs") verify_build ".next" ;;
    "vite") verify_build "dist" ;;
    "cra") verify_build "build" ;;
esac
```

## Step 8: Test Build Locally (Optional)

```bash
echo ""
echo "🚀 Testing build locally..."

case $FRAMEWORK in
    "nextjs")
        echo "Starting Next.js production server..."
        echo "Run: $PKG_MANAGER run start"
        echo "Then visit: http://localhost:3000"
        ;;
        
    "vite")
        echo "Previewing Vite build..."
        echo "Run: $PKG_MANAGER run preview"
        echo "Then visit: http://localhost:4173"
        ;;
        
    "cra")
        echo "Serving CRA build..."
        echo "Run: npx serve -s build"
        echo "Then visit: http://localhost:3000"
        ;;
esac
```

## Build Summary

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ BUILD COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Framework: $FRAMEWORK"
echo "Package Manager: $PKG_MANAGER"
echo ""
echo "📁 Output location:"
case $FRAMEWORK in
    "nextjs") echo "   .next/" ;;
    "vite") echo "   dist/" ;;
    "cra") echo "   build/" ;;
esac
echo ""
echo "💡 Next steps:"
echo "   - Test locally: $PKG_MANAGER run start (or preview)"
echo "   - Deploy: Connect to Vercel, Netlify, or your hosting"
echo "   - Verify program ID matches target network"
```

---

## Common Build Issues

### Missing Dependencies

```bash
# Clear cache and reinstall
rm -rf node_modules
rm -f package-lock.json pnpm-lock.yaml yarn.lock
$PKG_MANAGER install
```

### TypeScript Errors

```bash
# Check specific file
npx tsc --noEmit path/to/file.tsx

# Generate types from Anchor IDL
anchor build  # Regenerates types
```

### Environment Variables Not Loading

```bash
# Next.js: Must prefix with NEXT_PUBLIC_ for client-side
# Vite: Must prefix with VITE_ for client-side
# Ensure .env.local exists (not .env for local dev)
```

### Solana Buffer Polyfill (Vite/Webpack 5)

```typescript
// vite.config.ts
import { nodePolyfills } from 'vite-plugin-node-polyfills';

export default defineConfig({
  plugins: [
    nodePolyfills({
      include: ['buffer', 'crypto', 'stream'],
    }),
  ],
});
```

### Bundle Too Large

```bash
# Analyze bundle
$PKG_MANAGER run build -- --analyze

# Common optimizations:
# - Dynamic imports for heavy components
# - Tree-shake unused wallet adapters
# - Use @solana/kit instead of legacy web3.js
```

---

## Build Checklist

- [ ] Dependencies installed
- [ ] Environment variables configured
- [ ] Type check passes
- [ ] Lint check passes
- [ ] Build completes without errors
- [ ] Bundle size acceptable
- [ ] Tested locally
- [ ] Program ID matches target network

---

**Remember**: Always verify the build works with your target Solana network (devnet/mainnet) before deploying.
