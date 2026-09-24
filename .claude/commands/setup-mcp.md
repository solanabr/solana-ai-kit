---
description: "Configure MCP server API keys in .env"
model: sonnet
---

Walk the user through filling in `.env`. Secrets go in `.env`, never in `.mcp.json`.

## Steps

1. If `.env` is missing, copy `.env.example` to `.env` (or create an empty one).
2. For each key below, in order, ask the user to paste a value or say "skip". Write or update that line in `.env` and leave skipped keys empty. Don't echo values back.

   MCP server key (the only one `.mcp.json` reads):
   - `HELIUS_API_KEY`: Helius RPC and DAS API for the `helius` MCP server (https://dev.helius.xyz)

   Optional skill/CLI keys, read at runtime by skill CLIs in `.claude/skills/ext/`, not by any MCP server:
   - `COLOSSEUM_COPILOT_PAT`: Colosseum Copilot startup-research skill (PAT at https://arena.colosseum.org/copilot)
   - `COLOSSEUM_COPILOT_API_BASE`: the default `https://copilot.colosseum.com/api/v1` works for most
   - `MISTRAL_API_KEY`: QEDGen formal-verification CLI (https://console.mistral.ai)
   - `THEGRID_API_KEY`: TheGrid Colosseum project-graph queries (https://thegrid.id)
   - `THEGRID_GRAPHQL_ENDPOINT`: the default `https://beta.node.thegrid.id/graphql` works for most
   - `QUICKNODE_RPC_URL`, `QUICKNODE_WSS_URL`, `QUICKNODE_API_KEY`: QuickNode RPC, WebSocket/Streams and DAS for the `quicknode` skill (https://www.quicknode.com)
   - `X_BEARER_TOKEN`: X API bearer token for the `ct-alpha` CT research skill (https://developer.x.com)
   - `DFLOW_API_KEY`: DFlow order-flow integration skill (credentials from hello@dflow.net)
3. The Surfpool MCP server needs no key, but it runs `surfpool mcp`, so the `surfpool` CLI must be on PATH. Check with `command -v surfpool`; if it is missing, give the user the install command (`curl -L https://surfpool.run/install | sh` or `brew install txtx/taps/surfpool`) rather than running it.

## Output

Configured or skipped for each key (names only), grouped as MCP and skill/CLI, then remind the user to restart Claude Code so the changes are picked up.
