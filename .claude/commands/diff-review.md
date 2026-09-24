---
description: "AI-powered diff review for Solana-specific issues and code quality"
---

You are reviewing the current branch diff for Solana-specific security issues, code quality problems, and anti-patterns. Output categorized findings with line references and fix suggestions.

## Related Skills

- [ext/solana-dev/skills/solana-dev/references/security.md](../skills/ext/solana-dev/skills/solana-dev/references/security.md) - Vulnerability categories
- [ext/trailofbits/plugins/building-secure-contracts/skills/solana-vulnerability-scanner/](../skills/ext/trailofbits/plugins/building-secure-contracts/skills/solana-vulnerability-scanner/) - Automated scanning

## Step 1: Get the Diff

```bash
# Determine base branch
BASE_BRANCH="main"
if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    BASE_BRANCH="master"
fi

echo "Reviewing diff: $BASE_BRANCH...HEAD"
echo "Branch: $(git branch --show-current)"
echo ""

# Get the full diff
git diff "$BASE_BRANCH"...HEAD

echo ""
echo "Changed files:"
git diff --name-only "$BASE_BRANCH"...HEAD

echo ""
echo "Diff stats:"
git diff --stat "$BASE_BRANCH"...HEAD
```

## Step 2: Check for Critical Issues

Scan the diff for each category. Report with file path, line number, and severity.

### Account Validation

```bash
echo "=== Account Validation Check ==="

# Find Anchor account structs in changed files
CHANGED_RS=$(git diff --name-only "$BASE_BRANCH"...HEAD | grep '\.rs$')

if [ -n "$CHANGED_RS" ]; then
    echo "Checking Rust files for account validation..."

    # Missing owner checks in native programs
    for f in $CHANGED_RS; do
        [ -f "$f" ] || continue
        grep -n "AccountInfo" "$f" | head -20
    done

    # Check for accounts missing constraints in Anchor
    for f in $CHANGED_RS; do
        [ -f "$f" ] || continue
        # Accounts without any constraint attribute
        grep -n "pub.*Account<" "$f" | grep -v "#\[account" | head -20
    done
fi
```

### Arithmetic Safety

```bash
echo ""
echo "=== Arithmetic Safety Check ==="

if [ -n "$CHANGED_RS" ]; then
    for f in $CHANGED_RS; do
        [ -f "$f" ] || continue
        # Unchecked arithmetic operators on likely numeric operations
        grep -n -E '\b\w+\s*[+\-\*]\s*\w+' "$f" | grep -v "checked_" | grep -v "//" | grep -v "test" | head -20
    done
fi
```

### Hardcoded Addresses

```bash
echo ""
echo "=== Hardcoded Address Check ==="

# Look for base58 strings that look like Solana addresses (32-44 chars)
git diff "$BASE_BRANCH"...HEAD | grep -n "^+" | grep -oP '[1-9A-HJ-NP-Za-km-z]{32,44}' | head -20
```

### PDA Bump Storage

```bash
echo ""
echo "=== PDA Bump Check ==="

if [ -n "$CHANGED_RS" ]; then
    for f in $CHANGED_RS; do
        [ -f "$f" ] || continue
        # find_program_address without storing bump
        grep -n "find_program_address" "$f" | head -10

        # Check if bumps are stored in account structs
        grep -n "bump" "$f" | head -10
    done
fi
```

### Token-2022 Awareness

```bash
echo ""
echo "=== Token-2022 Check ==="

if [ -n "$CHANGED_RS" ]; then
    for f in $CHANGED_RS; do
        [ -f "$f" ] || continue
        # Token transfers without transfer hook handling
        grep -n "token::transfer\|transfer_checked" "$f" | head -10
        # Check for Token-2022 program ID awareness
        grep -n "spl_token_2022\|token_2022\|Token2022" "$f" | head -10
    done
fi
```

## Step 3: Check for AI Slop

Detect common AI-generated anti-patterns in the diff.

```bash
echo ""
echo "=== AI Slop Detection ==="

CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD)

for f in $CHANGED_FILES; do
    [ -f "$f" ] || continue

    # Excessive comments (comment-to-code ratio)
    COMMENTS=$(grep -c "^\s*//" "$f" 2>/dev/null || echo 0)
    CODE=$(grep -c "^\s*[^/]" "$f" 2>/dev/null || echo 1)
    if [ "$CODE" -gt 0 ] && [ "$COMMENTS" -gt 0 ]; then
        RATIO=$((COMMENTS * 100 / CODE))
        if [ "$RATIO" -gt 40 ]; then
            echo "WARNING: $f has ${RATIO}% comment ratio (likely over-commented)"
        fi
    fi

    # Redundant try/catch wrapping in TypeScript
    if echo "$f" | grep -qE '\.(ts|tsx)$'; then
        grep -n "try {" "$f" 2>/dev/null | head -5
    fi

    # Verbose error messages that leak implementation details
    grep -n 'console\.error\|println!\|eprintln!\|msg!' "$f" 2>/dev/null | head -5
done
```

## Step 4: Check CU Waste Patterns

```bash
echo ""
echo "=== CU Waste Patterns ==="

if [ -n "$CHANGED_RS" ]; then
    for f in $CHANGED_RS; do
        [ -f "$f" ] || continue

        # Unnecessary msg! calls (CU cost)
        MSG_COUNT=$(grep -c "msg!" "$f" 2>/dev/null || echo 0)
        if [ "$MSG_COUNT" -gt 5 ]; then
            echo "WARNING: $f has $MSG_COUNT msg! calls (each costs ~100 CU)"
        fi

        # find_program_address in instruction handlers (should use stored bumps)
        grep -n "find_program_address" "$f" | grep -v "test\|#\[cfg(test" | head -5

        # Unnecessary clones
        grep -n "\.clone()" "$f" | head -5
    done
fi
```

## Step 5: Generate Report

Compile all findings into a categorized report:

```
=== DIFF REVIEW REPORT ===
Branch: <branch> vs <base>
Files changed: <count>
Lines added/removed: +<added> -<removed>

--- CRITICAL ---
Issues that must be fixed before merge:
- Missing account validations
- Unchecked arithmetic in financial operations
- Missing signer checks

--- WARNING ---
Issues that should be addressed:
- Hardcoded addresses (use constants or config)
- Missing PDA bump storage (CU waste)
- Token-2022 transfer hooks not handled
- High comment-to-code ratio (AI slop)

--- INFO ---
Suggestions for improvement:
- CU optimization opportunities
- Code style improvements
- Test coverage gaps

--- FIX SUGGESTIONS ---
For each finding, provide:
1. File and line number
2. Current code
3. Suggested fix
4. Rationale
```

## Review Checklist

The review should systematically check:

- [ ] **Account validation** - All accounts have owner/signer/constraint checks
- [ ] **Arithmetic safety** - All math uses checked operations
- [ ] **PDA handling** - Bumps stored, canonical bumps used
- [ ] **CPI security** - Program IDs validated, accounts reloaded after CPI
- [ ] **Token-2022** - Transfer hooks handled if interacting with tokens
- [ ] **Hardcoded values** - No magic addresses or numbers without constants
- [ ] **Error handling** - Specific error codes, no unwrap/expect in program code
- [ ] **CU efficiency** - No unnecessary logging, cloning, or PDA recalculation
- [ ] **AI slop** - No excessive comments, verbose errors, or redundant patterns
- [ ] **Test coverage** - New code has corresponding tests

## Step 6: Capture Learnings

If any CRITICAL or WARNING finding represents a recurring pattern or project-specific antipattern not already in the "Project Learnings" section of `CLAUDE.md`, append a 1-2 line entry to the appropriate subsection (Recurring Issues, Fix Patterns, or Project Conventions).

## After Review

- [ ] All Critical issues resolved
- [ ] Warning issues addressed or documented as accepted risk
- [ ] Info suggestions considered
- [ ] Learnings captured in CLAUDE.md if applicable
- [ ] Branch ready for merge
