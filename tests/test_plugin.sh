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
assert_contains "$MARKET_CONTENT" '"name": "solana-ai-kit"' "marketplace name is solana-ai-kit"

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
            skills/idea-sprint skills/pitch-deck skills/hackathon skills/registry; do
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

# --- Plugin-variant hub must not link into ext/ (submodules absent in plugin installs) ---
echo "[variant hub]"
assert_file_exists "$PLUGIN_HUB" "plugin-variant skills hub exists"
assert_file_not_contains "$PLUGIN_HUB" "ext/" "plugin-variant hub contains no 'ext/' links"

# --- plugin.json version matches .claude/VERSION semver ---
echo "[version coherence]"
KIT_VERSION="$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$REPO_ROOT/.claude/VERSION" | head -1)"
PLUGIN_VERSION="$(python3 -c "import json; print(json.load(open('$PLUGIN_MANIFEST'))['version'])" 2>/dev/null)"
assert_eq "$KIT_VERSION" "$PLUGIN_VERSION" "plugin.json version ($PLUGIN_VERSION) matches .claude/VERSION ($KIT_VERSION)"

print_summary
