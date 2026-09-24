#!/bin/bash
# Install solana-token-intel skill for Claude Code / Codex
set -e

SKILL_DIR=".claude/skills/ext/solana-token-intel"

echo "Installing solana-token-intel skill..."

# Copy skill files
mkdir -p "$SKILL_DIR"
cp -r skill/* "$SKILL_DIR/"

# Register in skill registry if exists
REGISTRY=".claude/skills/skill-registry.json"
if [ -f "$REGISTRY" ]; then
  echo "Registering in skill-registry.json..."
  # Add entry if not already present
  if ! grep -q "solana-token-intel" "$REGISTRY"; then
    python3 -c "
import json
with open('$REGISTRY') as f:
    reg = json.load(f)
reg['skills'] = reg.get('skills', [])
reg['skills'].append({
    'name': 'solana-token-intel',
    'path': 'ext/solana-token-intel',
    'description': 'Token due diligence scanner — risk score for any SPL token'
})
with open('$REGISTRY', 'w') as f:
    json.dump(reg, f, indent=2)
"
  fi
fi

echo "✅ solana-token-intel installed at $SKILL_DIR"
echo "Usage: paste a Solana token address and ask 'is this safe?'"
