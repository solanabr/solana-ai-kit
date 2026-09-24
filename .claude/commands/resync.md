---
description: Resync external skill submodules to latest upstream versions
---

Run the resync script to update all external skill submodules and verify integrity.

1. Resolve the config dir and run: `BIN=$( [ -d .claude/bin ] && echo .claude/bin || echo .agents/bin ); bash "$BIN/resync.sh"`
2. Review submodule changes and verify all skill paths resolve
3. Run `git add .gitmodules .claude/skills/ext/` and commit to lock updates
