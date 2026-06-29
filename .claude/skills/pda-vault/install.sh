#!/usr/bin/env bash
set -euo pipefail

echo "Installing PDA Vault Skill..."

INSTALL_DIR="${1:-$HOME/.claude/skills/pda-vault}"
mkdir -p "$INSTALL_DIR"

cp -r skill/ "$INSTALL_DIR/skill/"
cp -r agents/ "$INSTALL_DIR/agents/" 2>/dev/null || true
cp -r commands/ "$INSTALL_DIR/commands/" 2>/dev/null || true
cp -r rules/ "$INSTALL_DIR/rules/" 2>/dev/null || true

echo "Installed to $INSTALL_DIR"
echo "Add to your CLAUDE.md or skills hub to enable."
