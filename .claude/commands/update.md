---
description: "Update solana-ai-kit to latest version from upstream"
model: sonnet
disable-model-invocation: true
---

Pull the latest agents, commands, skills and `bin/` tooling from upstream with the bundled update script.

1. Resolve the config dir and run: `BIN=$( [ -d .claude/bin ] && echo .claude/bin || echo .agents/bin ); bash "$BIN/update.sh"` (append `--dry-run` to preview without writing).
2. Review the script's change list.
3. If `CLAUDE.md.upstream` was created, diff it against `CLAUDE.md` and merge the relevant changes.
4. If the kit config is versioned (`/commit-claude-config`), review `git diff` before committing.
