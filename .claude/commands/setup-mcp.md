---
description: "Configure MCP server API keys in .env"
model: sonnet
---

You are guiding the user through MCP API key setup. All secrets go in `.env` (never in `mcp.json`).

## Step 1: Ensure .env exists

Check if `.env` exists in the project root. If not, copy from `.env.example`:

```bash
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
elif [ ! -f ".env" ]; then
  touch .env
  echo "Created empty .env"
else
  echo "Found existing .env"
fi
```

## Step 2: Configure secrets

`.env.example` defines 11 keys. Only `HELIUS_API_KEY` is read by `.mcp.json` (it wires the `helius` MCP server); the other 10 are read at runtime by skill CLIs inside `.claude/skills/ext/` submodules, not by any MCP server. Walk the user through both groups below, in order. For each key, ask the user to paste a value or say "skip". For each value provided, write or update the line in `.env`. Skip means leave it empty.

**MCP-server key:**

1. **HELIUS_API_KEY** — Helius RPC + DAS API, powers the `helius` MCP server (get one at https://dev.helius.xyz)

**Skill/CLI keys (optional — not read by `.mcp.json`):**

2. **COLOSSEUM_COPILOT_PAT** — Colosseum Copilot startup-research skill (get a PAT at https://arena.colosseum.org/copilot)
3. **COLOSSEUM_COPILOT_API_BASE** — Colosseum Copilot API base URL (default works for most: `https://copilot.colosseum.com/api/v1`)
4. **MISTRAL_API_KEY** — QEDGen formal-verification CLI (get a key at https://console.mistral.ai)
5. **THEGRID_API_KEY** — TheGrid Colosseum project-graph queries (get a key at https://thegrid.id)
6. **THEGRID_GRAPHQL_ENDPOINT** — TheGrid GraphQL endpoint (default works for most: `https://beta.node.thegrid.id/graphql`)
7. **QUICKNODE_RPC_URL** — QuickNode RPC endpoint for the `quicknode` skill (get endpoints at https://www.quicknode.com)
8. **QUICKNODE_WSS_URL** — QuickNode WebSocket/Streams endpoint (get endpoints at https://www.quicknode.com)
9. **QUICKNODE_API_KEY** — QuickNode DAS API key (get endpoints at https://www.quicknode.com)
10. **X_BEARER_TOKEN** — X/Twitter API for the `ct-alpha` CT research skill (get a bearer token at https://developer.x.com)
11. **DFLOW_API_KEY** — DFlow order-flow integration skill (contact hello@dflow.net for credentials)

**Note — Surfpool MCP is keyless** (no `.env` entry), but its server (`surfpool mcp`) requires the `surfpool` CLI binary on PATH. Install is the user's responsibility — do not run it for them: `curl -L https://surfpool.run/install | sh` or `brew install txtx/taps/surfpool`. Verify with `command -v surfpool`.

## Step 3: Summary

Print which keys are configured vs skipped:

```
MCP secrets (.env):
  HELIUS_API_KEY             [configured / skipped]

Skill/CLI secrets (.env):
  COLOSSEUM_COPILOT_PAT      [configured / skipped]
  COLOSSEUM_COPILOT_API_BASE [configured / skipped]
  MISTRAL_API_KEY            [configured / skipped]
  THEGRID_API_KEY            [configured / skipped]
  THEGRID_GRAPHQL_ENDPOINT   [configured / skipped]
  QUICKNODE_RPC_URL          [configured / skipped]
  QUICKNODE_WSS_URL          [configured / skipped]
  QUICKNODE_API_KEY          [configured / skipped]
  X_BEARER_TOKEN             [configured / skipped]
  DFLOW_API_KEY              [configured / skipped]
```

Remind the user: restart Claude Code to pick up changes.
