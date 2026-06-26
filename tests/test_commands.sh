#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

CMDS_DIR="$REPO_ROOT/.claude/commands"

echo "[test_commands] Checking command frontmatter..."

COUNT=0
for f in "$CMDS_DIR"/*.md; do
  name="$(basename "$f")"
  COUNT=$((COUNT + 1))

  if head -1 "$f" | grep -q "^---"; then
    frontmatter="$(sed -n '/^---$/,/^---$/p' "$f" | head -20 || true)"

    TOTAL=$((TOTAL + 1))
    if echo "$frontmatter" | grep -q "^description:"; then
      echo "  PASS: $name has description:"
      PASS=$((PASS + 1))
    else
      echo "  FAIL: $name missing description:"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "  FAIL: $name has no frontmatter"
    TOTAL=$((TOTAL + 1))
    FAIL=$((FAIL + 1))
  fi
done

echo ""
assert_eq "30" "$COUNT" "Total command count is 30"

print_summary
