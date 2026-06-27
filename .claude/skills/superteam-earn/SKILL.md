---
name: superteam-earn
description: Discover, build, and submit Superteam Earn bounties and GitHub /bounty issues autonomously. Use when the user says "earn on Superteam", "submit bounty", "find Solana bounties", "agent earn loop", or wants USDC from Superteam/GitHub bounties.
user-invocable: true
---

# Superteam Earn & GitHub Bounty Agent

End-to-end workflow for autonomous agents earning USDC/SOL via Superteam Earn and GitHub bounties.

## When to use

- User wants to earn from Superteam listings or GitHub `/bounty` issues
- Agent needs to register on Superteam agent API or scan human listings
- After winning: human claim handoff for KYC/payout

## Two Superteam channels

| Channel | API | Who submits | Payout |
|---------|-----|-------------|--------|
| Agent listings | `POST /api/agents` → Bearer token | Agent via `/api/agents/submissions/create` | Human claims at `/earn/claim/{code}` |
| Human listings | `GET /api/listings?isActive=true` | Human on superteam.fun (HUMAN_ONLY) | User wallet after KYC |

**Check before submitting:** `isWinnersAnnounced` must be `false`. Agent feed (`/api/agents/listings/live`) may list closed bounties — use human listings API for open work.

## Agent registration

```bash
curl -s -X POST "https://superteam.fun/api/agents" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-agent"}'
```

Store `apiKey` and `claimCode`. Human completes claim before payout.

## Discover open human bounties

```bash
curl -s "https://superteam.fun/api/listings?take=50&isActive=true" | jq '[.[] | select(.isWinnersAnnounced==false and .status=="OPEN")]'
```

Filter by skill: Backend, Blockchain, Content. Dev bounties often $800–$5000.

## Listing details

```bash
curl -s "https://superteam.fun/api/agents/listings/details/{slug}" \
  -H "Authorization: Bearer sk_..."
```

## Submit (agent-eligible only)

```bash
curl -s -X POST "https://superteam.fun/api/agents/submissions/create" \
  -H "Authorization: Bearer sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "listingId": "<uuid>",
    "link": "https://github.com/...",
    "otherInfo": "What you built",
    "eligibilityAnswers": [],
    "ask": null
  }'
```

## GitHub bounty pipeline

1. Search: `"/bounty $" in:body is:issue is:open`
2. Rank by reward / open PR competition
3. Fork → implement → `create_pr_api.py` or Git Data API push
4. Nudge maintainers on open PRs weekly

## Solana payment verification

Poll wallet via JSON-RPC:

- `getSignaturesForAddress(wallet, {limit: 20})`
- `getTransaction(sig)` → compare `postBalances - preBalances`

Confirm bounty payouts landed before marking earned.

## Other agent marketplaces

| Platform | Register | Payout |
|----------|----------|--------|
| Clustly | `POST https://clustly.ai/api/v1/agent/register` | USDC escrow, 4% fee |
| AgentBazaar | `https://agentbazaar.dev` | x402 USDC per request |
| x402 Bazaar | Wrap API with `@x402/express` | Passive micropayments |

## Pitfalls

- Do not submit after `isWinnersAnnounced: true`
- Human listings require human Superteam login — agent API returns 403
- Plagiarism on Superteam disqualifies — original work only
- Rate limit: 60 submissions/hour/agent

## References

- Official spec: https://superteam.fun/skill.md
- Agent landing: https://superteam.fun/earn/agents
- Solana x402: https://solana.com/x402/what-is-x402
