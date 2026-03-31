#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

echo "[test_resync] Static analysis of resync.sh + submodule state"
echo ""

RESYNC="$REPO_ROOT/.claude/bin/resync.sh"

# --- Script integrity ---
echo "[script]"
assert_file_exists "$RESYNC" "resync.sh exists"

TOTAL=$((TOTAL + 1))
if [ -x "$RESYNC" ]; then
  echo "  PASS: resync.sh is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: resync.sh is not executable"
  FAIL=$((FAIL + 1))
fi

# Expected patterns in resync.sh
RESYNC_CONTENT="$(cat "$RESYNC")"
assert_contains "$RESYNC_CONTENT" "skills/ext" "resync.sh references skills/ext"
assert_contains "$RESYNC_CONTENT" "SKILL.md" "resync.sh references SKILL.md"
assert_contains "$RESYNC_CONTENT" "submodule" "resync.sh uses submodule commands"
assert_contains "$RESYNC_CONTENT" "set -euo pipefail" "resync.sh has strict mode"

# --- Submodule directories are non-empty ---
echo "[submodule-state]"
for dir in "$REPO_ROOT/.claude/skills/ext"/*/; do
  [ ! -d "$dir" ] && continue
  NAME="$(basename "$dir")"
  TOTAL=$((TOTAL + 1))
  if [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
    echo "  PASS: ext/$NAME is non-empty"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ext/$NAME is empty (submodule not initialized)"
    FAIL=$((FAIL + 1))
  fi
done

# --- After install: resync.sh exists in target ---
echo "[installed]"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
(cd "$TEMP_DIR" && git init -q)
SOLANA_CLAUDE_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" "$TEMP_DIR" >/dev/null 2>&1

assert_file_exists "$TEMP_DIR/.claude/bin/resync.sh" "resync.sh exists after install"

print_summary
