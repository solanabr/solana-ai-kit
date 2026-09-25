---
description: "First-time-user product review: scorecard and fix roadmap; --harsh for a roast"
---

<!-- Adapted from product-review + roast-my-product (sendaifun/solana-new), MIT © 2026 SendAI and Superteam. Telemetry removed. -->

Review the product the way its next user will meet it, not the way its builder hopes it works. `$ARGUMENTS` may hold the URL, repo path or build, and `--harsh` for the stress-test mode.

| Invocation | Tone | Output |
|---|---|---|
| `/product-review` | Balanced, constructive | 8-dimension scorecard + bucketed roadmap |
| `/product-review --harsh` | Brutal but constructive | 10 weighted dimensions + verdict + exactly 3 fixes |

This is not a code review: send code quality to `/diff-review` and security to `/audit-solana` or `/audit-infra`.

## Steps

1. Ask before reviewing: the product (URL, repo, or running build), the specific target user, the one core action a user must complete, and the stage (prototype, MVP, beta, launched). With no product yet, suggest `/plan-feature` or `/scaffold` instead.
2. Walk through it as that user. With a URL or local build, offer to drive it live through the Playwright MCP (`browser_navigate`, `browser_snapshot`, then click through the core flow); otherwise walk the screens and code. Record each friction point with where it happens and what the user sees. Checkpoints:
   - The landing page says what this is within 5 seconds, without crypto jargon.
   - Value is visible before wallet connect; no wallet gate with nothing behind it.
   - The first meaningful action is reachable within 60 seconds by an obvious path.
   - The transaction preview shows what will happen and what it costs before the wallet popup.
   - Pending and confirmed states are visible, with an explorer link.
   - A failed transaction says why and what to try next.
   - After the first action, the next step and a reason to return are clear.

## Default mode

Score each dimension 1-10 with evidence from the walkthrough ("onboarding 6/10: step 3 demands a wallet without saying why"), never a bare number. Overall is the mean, one decimal. Per dimension, note what works, what needs improvement, and one concrete fix for its biggest issue.

| # | Dimension | What you judge |
|---|---|---|
| 1 | Onboarding | Landing to first meaningful action: steps, friction, wallet deferral |
| 2 | Core-loop clarity | Is the repeated action obvious; is there a reason to come back |
| 3 | Empty states | Zero-balance, no-history and no-results screens guide rather than confuse |
| 4 | Error states | Human-readable transaction failures, recovery guidance, no silent failures |
| 5 | Performance | Load time, transaction feedback latency, loading states, data freshness |
| 6 | Trust signals | Audits, team, volume, social proof, understandable approval dialogs |
| 7 | Mobile | Responsive layout, touch targets, wallet deep links |
| 8 | Docs | Users can self-serve; README, help and FAQ are accurate |

Roadmap: bucket every fix and order by impact within each bucket: quick wins (under 1 day: copy, error messages, missing links), medium (1-3 days: flow restructuring, state handling, mobile), major (1 week+: onboarding redesign, retention mechanics, new surfaces). Lead with where users are leaving, not nice-to-haves.

```
## Executive Summary
[2-3 sentences: overall quality, biggest strength, biggest risk]

## Scorecard
| Dimension | Score | Evidence |
(all 8 rows, then **Overall**)

## Top 3 Strengths
1. [Strength] - [specific evidence]

## Top 3 Improvements
1. [Change] - [expected impact]

## Roadmap
### Quick wins (< 1 day)
- [ ] [Fix] - [impact]
### Medium (1-3 days)
### Major (1 week+)
```

## --harsh mode

A stress test, not a review: find every weakness before users and investors do.

- Lead with the worst. No compliment sandwich, no "overall it's pretty good".
- Every criticism states what is wrong, why it matters, and what good looks like. Harshness without a fix is noise.
- A score above 7 needs a justification.
- Name crypto-for-crypto's-sake plainly: if a database could replace the chain and nothing breaks, say so.
- Be a YC partner with no patience for hand-waving, not a heckler.

| # | Dimension | Weight | Kill question |
|---|---|---|---|
| 1 | Value proposition | 2x | Can you explain it in one sentence without "decentralized", "protocol" or "ecosystem"? |
| 2 | Crypto necessity | 1x | What breaks if the chain becomes a database? Nothing: score 1-3 |
| 3 | Target user clarity | 1x | Could you DM 10 real target users today? |
| 4 | First-time UX | 1x | Wallet gate before any value? Jargon wall? |
| 5 | Core loop | 1x | What brings a user back on day 7? No answer, no loop |
| 6 | Moat | 1x | A funded competitor clones it in a weekend: what saves you? |
| 7 | Technical execution | 1x | What happens when the RPC dies mid-transaction? |
| 8 | Naming and messaging | 1x | Heard once, can you spell it and repeat the pitch? |
| 9 | Monetization | 1x | If the token goes to zero, does the business survive? |
| 10 | Market timing | 1x | Why now; what changed in the last 6 months? |

Weighted total out of 110: 90+ exceptional, 70-89 strong, 50-69 needs work, 30-49 rethink, under 30 start over.

Harsh output uses exactly this structure:

```
## Verdict
[One sentence: the single most damning truth]

## Scorecard
| Dimension | Score | Justification |
(all 10 rows + weighted total /110)

## The Worst Issues (top 3-5)
### 1. [Issue]
**What's wrong**: ... **Why it matters**: ... **What good looks like**: ...

## Fix These Now (exactly 3)
1. **Highest impact**: [the fix that reaches the most users]
2. **Easiest win**: [lowest effort, meaningful improvement]
3. **Existential**: [if this is not fixed, the product dies]
```

In both modes, judge usability over taste: "I dislike the design" is not "users cannot complete the task".
