---
description: "Version the Solana AI Kit config in git (un-ignores .claude/, CLAUDE.md, .mcp.json, .gitmodules and commits them)"
---

You are opting this project **into** version-controlling its Solana AI Kit config. By default `install.sh` gitignores the kit (`.claude/`, `CLAUDE.md`, `.mcp.json`, `.gitmodules`) so it stays out of the user's repo. This command reverses that: it removes the config block from `.gitignore`, stages those files, and commits them — so the config travels with the repo (team setup, reproducible config).

The `ext/` skill submodules stay gitignored (they're upstream content, re-fetched via `git submodule update`, not vendored). Only `.gitmodules` is tracked, so the submodule list ships and a `--recurse-submodules` clone can repopulate them.

## Step 0: Preflight

```bash
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "✗ Not a git repository. Run 'git init' first, then re-run /commit-claude-config."
  exit 1
fi

# Which config dir is installed?
if [ -d .claude ]; then CONFIG_DIR=.claude
elif [ -d .agents ]; then CONFIG_DIR=.agents
else echo "✗ No .claude/ or .agents/ found — nothing to commit."; exit 1
fi
echo "▸ Config dir: $CONFIG_DIR/"
```

## Step 1: Un-ignore the kit config

Remove the `# >>> solana-ai-kit config … <<<` block from `.gitignore` (leaves the `ext/` and local-only sections untouched). Portable across GNU/BSD sed via a temp file.

```bash
if [ -f .gitignore ] && grep -qF ">>> solana-ai-kit config" .gitignore; then
  sed '/# >>> solana-ai-kit config/,/# <<< solana-ai-kit config <<</d' .gitignore > .gitignore.tmp \
    && mv .gitignore.tmp .gitignore
  echo "✓ Removed the config block from .gitignore (ext/ + local-only stay ignored)"
else
  echo "ℹ config block already absent from .gitignore — continuing"
fi
```

## Step 2: Stage the config

`ext/` is still gitignored, so `git add "$CONFIG_DIR"` records your agents/commands/rules/skills/settings but NOT the 18 upstream submodule trees.

```bash
git add .gitignore 2>/dev/null || true
for p in .gitmodules CLAUDE.md .mcp.json "$CONFIG_DIR"; do
  [ -e "$p" ] && git add "$p"
done

echo ""
echo "Staged:"
git diff --cached --name-status
```

## Step 3: Commit

```bash
if git diff --cached --quiet; then
  echo "ℹ Nothing to commit — kit config is already tracked and up to date."
  exit 0
fi

git commit -m "chore: track Solana AI Kit config"
echo ""
echo "✓ Committed. The kit config now travels with this repo."
```

## Notes

- **Respects your pre-commit hook.** If the project has the kit's `git commit` PreToolUse gate (or a `.git/hooks/pre-commit`), it runs as usual.
- **Reversing this:** to go back to ignoring the config, re-run `install.sh` (it re-adds the block only if absent) or `git rm --cached -r .claude CLAUDE.md .mcp.json .gitmodules` and restore the `.gitignore` lines.
- **To also version the `ext/` submodules** (rarely needed — they're large and upstream), remove the `$CONFIG_DIR/skills/ext/` line from `.gitignore` first, then `git submodule update --init` so real gitlinks exist before `git add`.
- **`--agents` installs** are handled — the command detects `.agents/` and stages it instead of `.claude/`.
