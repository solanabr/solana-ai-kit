#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "[test_install_idempotent] Testing double-install safety"
echo ""

# Initialize git repo
(cd "$TEMP_DIR" && git init -q)

# --- First install ---
echo "[first install]"
SOLANA_CLAUDE_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" "$TEMP_DIR" >/dev/null 2>&1

assert_dir_exists "$TEMP_DIR/.claude" ".claude/ exists after 1st install"
assert_file_exists "$TEMP_DIR/CLAUDE.md" "CLAUDE.md exists after 1st install"
assert_file_not_exists "$TEMP_DIR/CLAUDE.md.bak" "No CLAUDE.md.bak after 1st install"
assert_file_exists "$TEMP_DIR/CLAUDE.local.md" "CLAUDE.local.md exists after 1st install"

# Capture CLAUDE.local.md content to verify it's preserved
echo "# My custom local notes" > "$TEMP_DIR/CLAUDE.local.md"

# Add custom content to CLAUDE.md to verify backup
ORIGINAL_CLAUDE_MD="$(cat "$TEMP_DIR/CLAUDE.md")"

# --- Second install ---
echo "[second install]"
SOLANA_CLAUDE_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" "$TEMP_DIR" >/dev/null 2>&1

assert_file_exists "$TEMP_DIR/CLAUDE.md.bak" "CLAUDE.md.bak created on 2nd install"
assert_dir_exists "$TEMP_DIR/.claude" ".claude/ still valid after 2nd install"
assert_dir_exists "$TEMP_DIR/.claude/agents" "agents/ preserved after 2nd install"
assert_dir_exists "$TEMP_DIR/.claude/commands" "commands/ preserved after 2nd install"
assert_json_valid "$TEMP_DIR/.claude/settings.json" "settings.json valid after 2nd install"
assert_count "$TEMP_DIR/.claude/agents" "*.md" "15" "Agent count correct after 2nd install"
assert_count "$TEMP_DIR/.claude/commands" "*.md" "24" "Command count correct after 2nd install"

# CLAUDE.local.md should be preserved (not overwritten)
LOCAL_CONTENT="$(cat "$TEMP_DIR/CLAUDE.local.md")"
assert_contains "$LOCAL_CONTENT" "My custom local notes" "CLAUDE.local.md content preserved"

# .gitignore should not have duplicate entries
EXT_DUPES=$(grep -c "skills/ext/" "$TEMP_DIR/.gitignore" | tr -d ' ')
assert_eq "1" "$EXT_DUPES" "No duplicate ext/ entries in .gitignore"

LOCAL_DUPES=$(grep -c "CLAUDE.local.md" "$TEMP_DIR/.gitignore" | tr -d ' ')
assert_eq "1" "$LOCAL_DUPES" "No duplicate CLAUDE.local.md entries in .gitignore"

print_summary
