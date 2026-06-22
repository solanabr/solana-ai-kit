#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

AGENTS_DIR="$REPO_ROOT/.claude/agents"

echo "[test_agents] Checking agent frontmatter..."

COUNT=0
for f in "$AGENTS_DIR"/*.md; do
  name="$(basename "$f")"
  COUNT=$((COUNT + 1))

  # Extract frontmatter
  if head -1 "$f" | grep -q "^---"; then
    frontmatter="$(sed -n '/^---$/,/^---$/p' "$f" | head -20 || true)"

    TOTAL=$((TOTAL + 1))
    if echo "$frontmatter" | grep -q "^name:"; then
      echo "  PASS: $name has name:"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: $name missing name:"
      FAIL=$((FAIL + 1))
    fi

    TOTAL=$((TOTAL + 1))
    if echo "$frontmatter" | grep -q "^description:"; then
      echo "  PASS: $name has description:"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: $name missing description:"
      FAIL=$((FAIL + 1))
    fi

    TOTAL=$((TOTAL + 1))
    if echo "$frontmatter" | grep -q "^model:"; then
      echo "  PASS: $name has model:"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: $name missing model:"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "  FAIL: $name has no frontmatter"
    TOTAL=$((TOTAL + 3))
    FAIL=$((FAIL + 3))
  fi
done

echo ""
assert_eq "16" "$COUNT" "Total agent count is 16"

print_summary
