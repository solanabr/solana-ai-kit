---
description: "Generate TypeScript client from Solana program IDL using Codama or Anchor"
---

You are generating a TypeScript client from a Solana program's IDL. Detect the IDL source and generator, run the appropriate pipeline, and verify the output compiles.

## Related Skills

- [ext/solana-dev/skills/solana-dev/references/idl-codegen.md](../skills/ext/solana-dev/skills/solana-dev/references/idl-codegen.md) - Codama/Shank client generation patterns
- [ext/solana-dev/skills/solana-dev/references/programs/anchor.md](../skills/ext/solana-dev/skills/solana-dev/references/programs/anchor.md) - Anchor IDL format

## Step 1: Detect IDL Source

```bash
echo "Detecting IDL source..."
echo ""

# Check for Anchor IDL
if ls target/idl/*.json 2>/dev/null; then
    echo "Found Anchor IDL(s) in target/idl/"
    IDL_SOURCE="anchor"
    ls -la target/idl/*.json
fi

# Check Anchor.toml for program names
if [ -f "Anchor.toml" ]; then
    echo ""
    echo "Anchor.toml programs:"
    grep -A 10 '\[programs' Anchor.toml
fi

# Check for Shank-annotated programs
if grep -r "ShankInstruction\|ShankAccount\|shank" --include="*.rs" programs/ src/ 2>/dev/null | head -5; then
    echo ""
    echo "Shank annotations detected"
    IDL_SOURCE="${IDL_SOURCE:-shank}"
fi

# Check for Codama config
if [ -f "codama.json" ] || [ -f "codama.config.ts" ] || [ -f "codama.config.js" ]; then
    echo ""
    echo "Codama config found"
    IDL_SOURCE="${IDL_SOURCE:-codama}"
fi

# Check for existing IDL files in other locations
if ls idl/*.json 2>/dev/null || ls *.idl.json 2>/dev/null; then
    echo ""
    echo "Found IDL files in project root or idl/ directory"
fi

echo ""
echo "IDL source: ${IDL_SOURCE:-unknown}"
```

## Step 2: Generate IDL (if needed)

### Anchor IDL Generation

```bash
if [ "$IDL_SOURCE" = "anchor" ] || [ -f "Anchor.toml" ]; then
    echo "Generating Anchor IDL..."

    # Build IDL
    anchor build

    if [ $? -ne 0 ]; then
        echo "Anchor build failed. Fix errors before generating client."
        exit 1
    fi

    echo ""
    echo "Generated IDL files:"
    ls -la target/idl/*.json

    # Show IDL summary
    for idl in target/idl/*.json; do
        PROGRAM=$(basename "$idl" .json)
        INSTRUCTIONS=$(grep -c '"name"' "$idl" | head -1)
        echo "  $PROGRAM: $(cat "$idl" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{len(d.get(\"instructions\",[]))} instructions, {len(d.get(\"accounts\",[]))} accounts')" 2>/dev/null || echo "parsed")"
    done
fi
```

### Shank IDL Generation

```bash
if [ "$IDL_SOURCE" = "shank" ]; then
    echo "Generating IDL with Shank..."

    # Install shank-cli if needed
    if ! command -v shank >/dev/null 2>&1; then
        echo "Installing shank-cli..."
        cargo install shank-cli
    fi

    # Find program crate
    PROGRAM_DIR=$(find programs/ src/ -name "Cargo.toml" -maxdepth 2 | head -1 | xargs dirname)

    if [ -n "$PROGRAM_DIR" ]; then
        shank idl -r "$PROGRAM_DIR" -o target/idl/
        echo "Shank IDL generated in target/idl/"
    else
        echo "Could not find program crate for Shank"
    fi
fi
```

## Step 3: Determine Client Generator

```bash
echo ""
echo "Detecting client generator..."

# Check for Codama pipeline
if [ -f "codama.json" ] || [ -f "codama.config.ts" ]; then
    GENERATOR="codama"
    echo "Using Codama pipeline"
elif [ -f "Anchor.toml" ]; then
    GENERATOR="anchor"
    echo "Using Anchor client generation"
else
    GENERATOR="codama"
    echo "Defaulting to Codama (recommended)"
fi

echo "Generator: $GENERATOR"
```

## Step 4: Generate Client - Codama

```bash
if [ "$GENERATOR" = "codama" ]; then
    echo "Generating client with Codama..."

    # Install Codama if needed
    if ! npm ls @codama/renderers-js 2>/dev/null | grep -q "@codama"; then
        echo "Installing Codama dependencies..."
        npm install --save-dev @codama/renderers-js @codama/nodes-from-anchor
    fi

    # Determine output directory
    CLIENT_DIR="src/generated"
    if [ -d "app" ]; then
        CLIENT_DIR="app/src/generated"
    elif [ -d "web" ]; then
        CLIENT_DIR="web/src/generated"
    fi

    mkdir -p "$CLIENT_DIR"

    # If codama config exists, use it
    if [ -f "codama.config.ts" ]; then
        npx tsx codama.config.ts
    elif [ -f "codama.config.js" ]; then
        node codama.config.js
    else
        # Generate using Codama API directly
        # The agent should create a codama generation script based on the IDL
        echo "No codama config found. Create codama.config.ts or use Anchor generation."
        echo ""
        echo "Example codama.config.ts:"
        echo '
import { createFromRoot } from "@codama/nodes";
import { rootNodeFromAnchor } from "@codama/nodes-from-anchor";
import { renderJavaScriptVisitor } from "@codama/renderers-js";
import anchorIdl from "./target/idl/program_name.json";

const node = rootNodeFromAnchor(anchorIdl);
const codama = createFromRoot(node);
codama.accept(renderJavaScriptVisitor("./src/generated"));
'
    fi

    echo "Client generated in $CLIENT_DIR"
fi
```

## Step 5: Generate Client - Anchor

```bash
if [ "$GENERATOR" = "anchor" ]; then
    echo "Generating Anchor TypeScript client..."

    # Anchor generates types automatically during build
    # Check for generated types
    if [ -d "target/types" ]; then
        echo "Anchor types found in target/types/"
        ls target/types/
    fi

    # For standalone client generation from IDL
    CLIENT_DIR="src/generated"
    if [ -d "app" ]; then
        CLIENT_DIR="app/src/generated"
    fi
    mkdir -p "$CLIENT_DIR"

    # Copy IDL for frontend consumption
    for idl in target/idl/*.json; do
        PROGRAM=$(basename "$idl" .json)
        cp "$idl" "$CLIENT_DIR/${PROGRAM}_idl.json"
        echo "Copied IDL: $CLIENT_DIR/${PROGRAM}_idl.json"
    done

    echo ""
    echo "For Anchor projects, import the IDL and use Program class:"
    echo '  import idl from "./generated/program_name_idl.json";'
    echo '  const program = new Program(idl, provider);'
fi
```

## Step 6: Verify Generated Types Compile

```bash
echo ""
echo "Verifying generated client compiles..."

# TypeScript compilation check
if [ -f "tsconfig.json" ]; then
    npx tsc --noEmit
    if [ $? -eq 0 ]; then
        echo "TypeScript compilation successful."
    else
        echo "TypeScript errors detected. Review generated types."
        echo "Common fixes:"
        echo "  - Add generated dir to tsconfig include"
        echo "  - Install missing type dependencies"
        echo "  - Check resolveJsonModule is enabled for IDL imports"
    fi
else
    echo "No tsconfig.json found. Skipping type check."
fi

# List generated files
echo ""
echo "Generated files:"
find "${CLIENT_DIR:-.}" -name "*.ts" -o -name "*.js" -o -name "*_idl.json" 2>/dev/null | head -20
```

## Step 7: Summary

```bash
echo ""
echo "=== Client Generation Summary ==="
echo ""
echo "IDL Source:    $IDL_SOURCE"
echo "Generator:     $GENERATOR"
echo "Output Dir:    ${CLIENT_DIR:-target/types}"
echo ""
echo "Generated artifacts:"
ls -la "${CLIENT_DIR:-target/types}/" 2>/dev/null | head -15
echo ""
echo "Next steps:"
echo "  1. Import generated types in your application code"
echo "  2. Re-run this command after any program changes"
echo "  3. Commit generated files or add generation to build pipeline"
```

## Troubleshooting

### IDL Not Found
```bash
# Rebuild the program
anchor build
# Or for Shank: shank idl -r programs/your-program -o target/idl/
```

### Codama Version Mismatch
```bash
# Update Codama packages
npm update @codama/renderers-js @codama/nodes-from-anchor
```

### Missing Anchor Types
```bash
# Ensure @anchor-lang/core is installed
npm install @anchor-lang/core
# Rebuild to regenerate types
anchor build
```

## After Generation

- [ ] IDL generated from latest program code
- [ ] Client types generated successfully
- [ ] TypeScript compiles without errors
- [ ] Generated types match program interface
- [ ] Output directory configured correctly
- [ ] Generation integrated into build pipeline (optional)
