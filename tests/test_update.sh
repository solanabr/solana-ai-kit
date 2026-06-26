#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "[test_update] Comprehensive update.sh validation"
echo ""

# --- Setup: initial install ---
(cd "$TEMP_DIR" && git init -q)
SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" "$TEMP_DIR" >/dev/null 2>&1

# --- Run update ---
echo "[basic update]"
(cd "$TEMP_DIR" && SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash .claude/bin/update.sh) >/dev/null 2>&1

assert_dir_exists "$TEMP_DIR/.claude" ".claude/ still exists after update"
assert_file_exists "$TEMP_DIR/CLAUDE.md" "CLAUDE.md still exists after update"
assert_dir_exists "$TEMP_DIR/.claude/agents" "agents/ preserved"
assert_dir_exists "$TEMP_DIR/.claude/commands" "commands/ preserved"
assert_file_exists "$TEMP_DIR/.claude/skills/SKILL.md" "SKILL.md preserved"
assert_json_valid "$TEMP_DIR/.claude/settings.json" "settings.json still valid"
assert_file_exists "$TEMP_DIR/.claude/VERSION" ".claude/VERSION exists after update"

# --- VERSION is valid semver ---
VERSION_CONTENT="$(cat "$TEMP_DIR/.claude/VERSION")"
TOTAL=$((TOTAL + 1))
if echo "$VERSION_CONTENT" | grep -qE '(^|[[:space:]])[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "  PASS: VERSION content is valid semver ($VERSION_CONTENT)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: VERSION content is not valid semver ($VERSION_CONTENT)"
  FAIL=$((FAIL + 1))
fi

# --- Counts after update ---
assert_count "$TEMP_DIR/.claude/agents" "*.md" "15" "Agent count == 15 after update"
assert_count "$TEMP_DIR/.claude/commands" "*.md" "30" "Command count == 30 after update"

# --- Dry-run mode ---
echo "[dry-run]"
DRY_OUTPUT="$(cd "$TEMP_DIR" && SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash .claude/bin/update.sh --dry-run 2>&1)"
assert_contains "$DRY_OUTPUT" "DRY RUN" "--dry-run output contains DRY RUN"

# VERSION should still be valid after dry-run (not corrupted)
VERSION_AFTER="$(cat "$TEMP_DIR/.claude/VERSION")"
assert_eq "$VERSION_CONTENT" "$VERSION_AFTER" "VERSION unchanged after dry-run"

# --- CLAUDE.md.upstream: modify CLAUDE.md, then update ---
echo "[upstream detection]"
echo "# My customized CLAUDE.md" > "$TEMP_DIR/CLAUDE.md"
(cd "$TEMP_DIR" && SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash .claude/bin/update.sh) >/dev/null 2>&1

assert_file_exists "$TEMP_DIR/CLAUDE.md.upstream" "CLAUDE.md.upstream created when CLAUDE.md differs"
assert_file_contains "$TEMP_DIR/CLAUDE.md" "My customized" "Original CLAUDE.md not overwritten"

# --- Protected files: .env not overwritten ---
echo "[protected files]"
echo "MY_SECRET=preserved" > "$TEMP_DIR/.env"
(cd "$TEMP_DIR" && SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash .claude/bin/update.sh) >/dev/null 2>&1
assert_file_contains "$TEMP_DIR/.env" "MY_SECRET=preserved" ".env not overwritten by update"

# --- Agents mode ---
echo "[agents mode]"
AGENTS_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR" "$AGENTS_DIR"' EXIT
(cd "$AGENTS_DIR" && git init -q)
SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" --agents "$AGENTS_DIR" >/dev/null 2>&1

assert_dir_exists "$AGENTS_DIR/.agents" ".agents/ exists after --agents install"
assert_file_exists "$AGENTS_DIR/.agents/bin/update.sh" ".agents/bin/update.sh exists"

(cd "$AGENTS_DIR" && SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash .agents/bin/update.sh) >/dev/null 2>&1
assert_dir_exists "$AGENTS_DIR/.agents/agents" ".agents/agents/ valid after agents-mode update"
assert_dir_exists "$AGENTS_DIR/.agents/commands" ".agents/commands/ valid after agents-mode update"

print_summary
