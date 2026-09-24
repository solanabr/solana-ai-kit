#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
PLUGIN_DIR="$REPO_ROOT/plugin"
PLUGIN_MANIFEST="$PLUGIN_DIR/.claude-plugin/plugin.json"
PLUGIN_HUB="$PLUGIN_DIR/skills/SKILL.md"

echo "[test_plugin] Claude Code plugin packaging (marketplace + core plugin)..."

# --- Manifests exist and are valid JSON ---
assert_file_exists "$MARKETPLACE" "marketplace.json exists at .claude-plugin/"
assert_json_valid "$MARKETPLACE" "marketplace.json is valid JSON"
assert_file_exists "$PLUGIN_MANIFEST" "plugin.json exists at plugin/.claude-plugin/"
assert_json_valid "$PLUGIN_MANIFEST" "plugin.json is valid JSON"

# Marketplace points its one plugin at ./plugin (NOT ./ — avoids caching tests/install.sh/ext)
MARKET_CONTENT="$(cat "$MARKETPLACE")"
assert_contains "$MARKET_CONTENT" '"source": "./plugin"' "marketplace plugin source is ./plugin"
# Marketplace renamed to stbr (installs as solana-ai-kit@stbr); plugin entry keeps name solana-ai-kit
MARKET_NAME="$(python3 -c "import json; print(json.load(open('$MARKETPLACE'))['name'])" 2>/dev/null)"
assert_eq "$MARKET_NAME" "stbr" "marketplace name is stbr"
PLUGIN_ENTRY_NAME="$(python3 -c "import json; print(json.load(open('$MARKETPLACE'))['plugins'][0]['name'])" 2>/dev/null)"
assert_eq "$PLUGIN_ENTRY_NAME" "solana-ai-kit" "marketplace plugin entry name is solana-ai-kit"

# --- claude plugin validate (skip-with-note if CLI unavailable in CI) ---
if command -v claude >/dev/null 2>&1; then
  assert_cmd_success "claude plugin validate '$REPO_ROOT'" "claude plugin validate (marketplace) exits 0"
  assert_cmd_success "claude plugin validate '$PLUGIN_DIR'" "claude plugin validate (plugin) exits 0"
else
  echo "  NOTE: 'claude' CLI not on PATH — skipping 'claude plugin validate' checks"
fi

# --- Each plugin symlink target resolves on disk (-e follows symlinks) ---
echo "[plugin symlinks]"
for link in agents commands .mcp.json VERSION \
            skills/idea-sprint skills/pitch-deck skills/hackathon skills/skill-registry.json; do
  target="$PLUGIN_DIR/$link"
  TOTAL=$((TOTAL + 1))
  if [ -L "$target" ] && [ -e "$target" ]; then
    echo "  PASS: plugin symlink resolves: $link -> $(readlink "$target")"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: plugin symlink missing or dangling: $link"
    FAIL=$((FAIL + 1))
  fi
done

# --- Plugin hooks (real file, mirrors .claude/settings.json hooks) ---
echo "[plugin hooks]"
PLUGIN_HOOKS="$PLUGIN_DIR/hooks/hooks.json"
assert_file_exists "$PLUGIN_HOOKS" "plugin hooks.json exists"
assert_json_valid "$PLUGIN_HOOKS" "plugin hooks.json is valid JSON"
assert_file_contains "$PLUGIN_HOOKS" "config/solana/id" "plugin hooks.json has the secrets-gate PreToolUse hook"
assert_file_contains "$PLUGIN_HOOKS" "Blocked: reading private keys" "plugin secrets gate prints the block reason"
assert_file_contains "$PLUGIN_HOOKS" "exit 2" "plugin secrets gate blocks with exit 2"
for legacy in '"when"' command_matches CLAUDE_FILE_PATH CLAUDE_TOOL_EXIT_CODE CLAUDE_SUBAGENT_NAME; do
  assert_file_not_contains "$PLUGIN_HOOKS" "$legacy" "plugin hooks.json has no unsupported '$legacy'"
done

# --- Plugin-variant hub must not link into ext/ (submodules absent in plugin installs) ---
echo "[variant hub]"
assert_file_exists "$PLUGIN_HUB" "plugin-variant skills hub exists"
assert_file_not_contains "$PLUGIN_HUB" "ext/" "plugin-variant hub contains no 'ext/' links"

# --- plugin.json version matches .claude/VERSION semver ---
echo "[version coherence]"
KIT_VERSION="$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$REPO_ROOT/.claude/VERSION" | head -1)"
PLUGIN_VERSION="$(python3 -c "import json; print(json.load(open('$PLUGIN_MANIFEST'))['version'])" 2>/dev/null)"
assert_eq "$KIT_VERSION" "$PLUGIN_VERSION" "plugin.json version ($PLUGIN_VERSION) matches .claude/VERSION ($KIT_VERSION)"
MARKETPLACE_VERSION="$(python3 -c "import json; print(json.load(open('$MARKETPLACE'))['metadata']['version'])" 2>/dev/null)"
assert_eq "$KIT_VERSION" "$MARKETPLACE_VERSION" "marketplace.json metadata.version ($MARKETPLACE_VERSION) matches .claude/VERSION ($KIT_VERSION)"

print_summary
