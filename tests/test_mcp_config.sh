#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

MCP_FILE="$REPO_ROOT/.claude/mcp.json"

echo "[test_mcp_config] Checking MCP configuration..."

assert_file_exists "$MCP_FILE" "mcp.json exists"
assert_json_valid "$MCP_FILE" "mcp.json is valid JSON"

# Check for mcpServers key
MCP_CONTENT="$(cat "$MCP_FILE")"
assert_contains "$MCP_CONTENT" '"mcpServers"' "mcp.json has mcpServers key"

# Check expected server names
assert_contains "$MCP_CONTENT" '"helius"' "mcp.json has helius server"
assert_contains "$MCP_CONTENT" '"context7"' "mcp.json has context7 server"
assert_contains "$MCP_CONTENT" '"playwright"' "mcp.json has playwright server"
assert_contains "$MCP_CONTENT" '"solana-dev"' "mcp.json has solana-dev server"
assert_contains "$MCP_CONTENT" '"context-mode"' "mcp.json has context-mode server"
assert_contains "$MCP_CONTENT" '"memsearch"' "mcp.json has memsearch server"

# Check .env.example exists
ENV_EXAMPLE="$REPO_ROOT/.env.example"
assert_file_exists "$ENV_EXAMPLE" ".env.example exists"

print_summary
