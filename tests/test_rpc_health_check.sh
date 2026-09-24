#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

echo "[test_rpc_health_check] Running RPC health-check unit tests..."

assert_file_exists "$REPO_ROOT/tests/rpc-health-check.test.mjs" "RPC health-check unit test exists"
assert_cmd_success "node --test '$REPO_ROOT/tests/rpc-health-check.test.mjs'" "RPC health-check unit tests pass"

print_summary
