---
name: bounty-intelligence
description: Bounty discovery and triage across Superteam Earn, Sherlock, GitHub, and Immunefi with scoring, cost estimation, and automated submission tracking.
---

# Bounty Intelligence & Competitive Analysis

Discover, triage, and win smart-contract and development bounties. Covers Superteam Earn, Sherlock, GitHub label:bounty, and Immunefi with a repeatable evaluation workflow.

## Platform Overview

### Superteam Earn
- Agent-accessible API at `https://superteam.fun/api/agents/listings/live`
- Authentication via `sk_...` API key from `/earn/agents/` registration
- Filterable by type: `bounty`, `project`, `hackathon`
- Client-side deadline filtering required (API returns all listings, filter by `deadline` and `isWinnersAnnounced`)

### Sherlock
- Official contest API: `https://audits.sherlock.xyz/api/contests`
- Statuses: `ACTIVE` (submissions open), `JUDGING` (submissions closed), `SHERLOCK_JUDGING`, `FINISHED`
- Prize pools range from $10K-$500K+

### GitHub
- Query pattern: `gh search issues "label:bounty" --state open --sort created --order desc`
- Target specific repos: `repo:owner/name label:bounty`
- Frantic Board bounties are "massively parallel" — multiple submissions accepted per issue

### Immunefi
- 202+ active bug bounty programs
- Requires finding and proving security vulnerabilities in deployed protocols
- Max bounties: $3M (Ethena), $500K (DeXe), $250K (SSV, ENS)
- Verify program details at `https://immunefi.com/bug-bounty/`

## Triage Scoring

Evaluate opportunities on a 100-point scale:

| Factor | Points | Rationale |
|--------|--------|-----------|
| Prize $10K+ | +25 | High-value targets |
| Prize $1K-$10K | +15 | Mid-value |
| Prize $100-$1K | +5 | Low-value |
| Sherlock contest | +10 | Fixed prize, clear scope |
| Superteam agent-allowed | +5 | No human OAuth needed |
| Deadline >14 days | +10 | Ample time for quality work |
| Deadline 3-14 days | +5 | Moderate pressure |
| Deadline <3 days | -10 | Probably too late |

Score ≥60: strong candidate. Score ≥75: immediate action.

## Cost Estimation

| Bounty Type | Estimated Hours | Effective Rate |
|------------|----------------|----------------|
| GitHub runx skill ($10) | 1-2h | $5-10/hr |
| Superteam content ($500-3K) | 4-8h | $125-375/hr |
| Sherlock audit ($10-100K) | 40-80h | Variable |
| Immunefi vulnerability ($10K-3M) | 20-200h | Variable |

## Submission Pipeline

1. **Scout** — Fetch all sources, filter by deadline/status, normalize to common format
2. **Triage** — Score each entry, estimate effort, rank by expected value per hour
3. **Assign** — Select target, estimate completion time, set deadline
4. **Execute** — Complete work per bounty specifications
5. **Submit** — Push PR for GitHub, upload to Superteam/Immunefi platform
6. **Track** — Monitor status, respond to reviewer feedback
