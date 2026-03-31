#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

SETTINGS="$REPO_ROOT/.claude/settings.json"

echo "[test_settings_deep] Deep validation of settings.json structure"
echo ""

# Helper: query JSON with python3
json_get() {
  python3 -c "
import json, sys
data = json.load(open('$SETTINGS'))
try:
    result = eval('data$1')
    if isinstance(result, bool):
        print(str(result).lower())
    elif isinstance(result, (list, dict)):
        print(json.dumps(result))
    else:
        print(result)
except (KeyError, IndexError, TypeError):
    print('__MISSING__')
" 2>/dev/null
}

json_len() {
  python3 -c "
import json
data = json.load(open('$SETTINGS'))
try:
    result = eval('data$1')
    print(len(result))
except (KeyError, IndexError, TypeError):
    print('0')
" 2>/dev/null
}

json_contains() {
  python3 -c "
import json, sys
data = json.load(open('$SETTINGS'))
try:
    result = eval('data$1')
    if isinstance(result, list):
        sys.exit(0 if '$2' in result else 1)
    elif isinstance(result, dict):
        sys.exit(0 if '$2' in result else 1)
    elif isinstance(result, str):
        sys.exit(0 if '$2' in result else 1)
    else:
        sys.exit(1)
except (KeyError, IndexError, TypeError):
    sys.exit(1)
" 2>/dev/null
}

# --- Environment variables ---
echo "[env]"
assert_eq "1" "$(json_get '["env"]["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"]')" "env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS == 1"
assert_eq "1" "$(json_get '["env"]["CLAUDE_CODE_COORDINATOR_MODE"]')" "env.CLAUDE_CODE_COORDINATOR_MODE == 1"
assert_eq "auto" "$(json_get '["env"]["CLAUDE_CODE_EFFORT_LEVEL"]')" "env.CLAUDE_CODE_EFFORT_LEVEL == auto"

# --- Sandbox ---
echo "[sandbox]"
assert_eq "true" "$(json_get '["sandbox"]["enabled"]')" "sandbox.enabled == true"

# Check denyWrite contains critical paths
DENY_WRITE="$(json_get '["sandbox"]["filesystem"]["denyWrite"]')"
assert_contains "$DENY_WRITE" "~/.ssh" "sandbox.filesystem.denyWrite contains ~/.ssh"
assert_contains "$DENY_WRITE" "~/.gnupg" "sandbox.filesystem.denyWrite contains ~/.gnupg"
assert_contains "$DENY_WRITE" "~/.aws" "sandbox.filesystem.denyWrite contains ~/.aws"
assert_contains "$DENY_WRITE" "~/.config/solana/id.json" "sandbox.filesystem.denyWrite contains solana key"

# --- Plugins ---
echo "[plugins]"
PLUGINS="$(json_get '["enabledPlugins"]')"
assert_contains "$PLUGINS" "rust-analyzer" "enabledPlugins has rust-analyzer"
assert_contains "$PLUGINS" "typescript-lsp" "enabledPlugins has typescript-lsp"
assert_contains "$PLUGINS" "csharp-lsp" "enabledPlugins has csharp-lsp"

# --- Permissions ---
echo "[permissions]"
ALLOW_LEN="$(json_len '["permissions"]["allow"]')"
TOTAL=$((TOTAL + 1))
if [ "$ALLOW_LEN" -gt 20 ]; then
  echo "  PASS: permissions.allow length > 20 (got $ALLOW_LEN)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: permissions.allow length > 20 (got $ALLOW_LEN)"
  FAIL=$((FAIL + 1))
fi

# Deny patterns
DENY="$(json_get '["permissions"]["deny"]')"
assert_contains "$DENY" "sudo" "permissions.deny contains sudo pattern"
assert_contains "$DENY" "rm -rf" "permissions.deny contains rm -rf pattern"
assert_contains "$DENY" "git push --force" "permissions.deny contains git push --force"
assert_contains "$DENY" "git push -f" "permissions.deny contains git push -f"
assert_contains "$DENY" "mainnet" "permissions.deny contains mainnet deploy guard"

# --- Hooks ---
echo "[hooks]"
HOOKS="$(json_get '["hooks"]')"
assert_contains "$HOOKS" "SessionStart" "hooks has SessionStart"
assert_contains "$HOOKS" "Stop" "hooks has Stop"
assert_contains "$HOOKS" "PreToolUse" "hooks has PreToolUse"
assert_contains "$HOOKS" "PostToolUse" "hooks has PostToolUse"
assert_contains "$HOOKS" "SubagentStop" "hooks has SubagentStop"

# --- Model Defaults ---
echo "[modelDefaults]"
assert_eq "opus" "$(json_get '["modelDefaults"]["agent"]')" "modelDefaults.agent == opus"
assert_eq "sonnet" "$(json_get '["modelDefaults"]["command"]')" "modelDefaults.command == sonnet"

print_summary
