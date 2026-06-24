# solana-fundraise-skill

Every Solana AI skill out there teaches you how to build. None of them teach you how to get funded.

This skill fixes that. Add it to Claude Code and your agent becomes an expert Solana fundraising advisor — covering the full journey from "what should I build to get funded" all the way to "I got funded, now how do I deliver."

Covers Solana Foundation, Superteam Earn, and Colosseum.

---

## What's inside

```
solana-fundraise-skill/
├── CLAUDE.md                          ← Claude Code configuration
├── SKILL.md                           ← main router (20+ routes)
├── TESTING.md                         ← 8 test cases, issues found, fixes applied
├── install.sh                         ← standard installer
├── install-custom.sh                  ← custom installer (location, options)
│
├── rules/                             ← 3 rules files (always loaded)
│   ├── grant-rules.md                 ← core behavior rules
│   ├── program-rules.md               ← program-specific dos and don'ts
│   └── writing-rules.md               ← language, tone, structure rules
│
├── skill/                             ← 15 knowledge files
│   ├── grants-overview.md             ← which program is right for you + decision tree
│   ├── what-gets-funded.md            ← patterns from funded projects across all 3 programs
│   ├── solana-foundation.md           ← Foundation grant deep dive
│   ├── superteam-grants.md            ← Superteam Earn + regional grants
│   ├── colosseum.md                   ← hackathon strategy + accelerator path
│   ├── application-writing.md         ← proposal templates, milestone format, checklist
│   ├── positioning.md                 ← how to frame your project for reviewers
│   ├── examples.md                    ← real examples of strong vs weak applications
│   ├── sample-application.md          ← complete grant applications for Superteam + Foundation
│   ├── social-proof.md                ← building GitHub, X, and Superteam presence
│   ├── cold-outreach.md               ← reaching grant reviewers and ecosystem leads
│   ├── cofounder-matching.md          ← finding a team for Colosseum and hackathons
│   ├── rejection-handling.md          ← what to do after a rejection
│   ├── post-funding.md                ← milestone delivery, payments, stacking the next grant
│   └── resources.md                   ← curated links, portals, community channels
│
├── commands/                          ← 3 slash commands
│   ├── grant-check.md                 ← /grant-check: readiness assessment
│   ├── milestone-builder.md           ← /milestone-builder: reviewer-approved milestone plan
│   └── position-project.md            ← /position-project: strongest angle per program
│
└── agents/                            ← 2 specialized agents
    ├── grant-reviewer.md              ← reviews draft applications section by section
    └── grant-stacking.md              ← builds a multi-program funding strategy
```

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/aruck-commits/solana-fundraise-skill/main/install.sh | bash
```

Custom install (choose location, options):

```bash
git clone https://github.com/aruck-commits/solana-fundraise-skill.git
cd solana-fundraise-skill
bash install-custom.sh
```

---

## Try it

Once installed, ask Claude Code things like:

- "Which grant should I apply to first?"
- "Show me a complete sample grant application"
- "Run a grant readiness check on my project"
- "Build my milestone plan for a Foundation grant"
- "Review my draft application before I submit"
- "I got rejected — what do I do now?"
- "Build me a multi-program funding strategy"
- "How do I reach out to the Superteam India lead?"
- "What kinds of projects actually get funded?"

---

## Why this exists

The Solana AI Kit has deep technical skills — build, deploy, audit, ship. But when a founder asks their coding agent "how do I fund this?" the answer falls apart. No skill in the ecosystem covers grant strategy, application writing, positioning, social proof, rejection handling, or post-funding delivery.

This skill covers the full fundraising layer, end to end.

---

## Testing

See `TESTING.md` for 8 documented test cases, real outputs from early versions, issues found, and specific fixes applied. The skill that shipped is meaningfully different from the first version we built.

---

## License

MIT — [@aruck2006](https://x.com/aruck2006)
