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
SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" "$TEMP_DIR" >/dev/null 2>&1

assert_file_exists "$TEMP_DIR/.claude/bin/resync.sh" "resync.sh exists after install"

# --- Runs correctly regardless of the caller's cwd ---
# resync.sh must resolve TARGET_DIR from its own location and cd there before
# doing anything relative-path-based (SKILL.md verification) or running git
# submodule commands, so it behaves the same whether invoked from the project
# root or from anywhere else. Build a throwaway repo with zero real
# submodules so `git submodule update --remote --merge` is a network-free
# no-op, then invoke resync.sh from an unrelated, non-git cwd.
echo "[cwd-independence]"
FAKE_ROOT="$(mktemp -d)"
OTHER_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR" "$FAKE_ROOT" "$OTHER_DIR"' EXIT

(cd "$FAKE_ROOT" && git init -q)
mkdir -p "$FAKE_ROOT/.claude/bin" "$FAKE_ROOT/.claude/skills/ext/dummy"
touch "$FAKE_ROOT/.claude/skills/ext/dummy/.gitkeep"
cp "$RESYNC" "$FAKE_ROOT/.claude/bin/resync.sh"
chmod +x "$FAKE_ROOT/.claude/bin/resync.sh"
# One file link and one directory link (directory links used to be misparsed as "(bar/")
printf '# Skills\n- [Foo](foo.md)\n- [Bar](bar/)\n' > "$FAKE_ROOT/.claude/skills/SKILL.md"
echo "# Foo" > "$FAKE_ROOT/.claude/skills/foo.md"
mkdir -p "$FAKE_ROOT/.claude/skills/bar"

if OUTPUT="$(cd "$OTHER_DIR" && bash "$FAKE_ROOT/.claude/bin/resync.sh" 2>&1)"; then
  RC=0
else
  RC=$?
fi

TOTAL=$((TOTAL + 1))
if [ "$RC" -eq 0 ] && echo "$OUTPUT" | grep -q "All skill paths resolve correctly."; then
  echo "  PASS: resync.sh resolves paths against its target dir, not the caller's cwd"
  PASS=$((PASS + 1))
else
  echo "  FAIL: resync.sh did not resolve correctly when run from a different cwd (exit $RC)"
  echo "$OUTPUT" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
fi

# Static defense-in-depth: the fix must stay in place even if the dynamic
# check above is ever skipped (e.g. no network / no git in CI).
assert_contains "$RESYNC_CONTENT" 'cd "$TARGET_DIR"' "resync.sh cds into TARGET_DIR before using relative paths"

print_summary
