#!/usr/bin/env bash
set -euo pipefail

# Solana AI Kit — In-Place Update
# Fetches latest from upstream and applies updates.
# Safe: backs up CLAUDE.md, preserves .env, shows diff.
#
# Usage:
#   bash .claude/bin/update.sh              # from project root
#   bash .agents/bin/update.sh              # from project root (agents mode)
#   bash .claude/bin/update.sh --dry-run    # preview changes only
#
# Env: SOLANA_AI_KIT_UPSTREAM / SOLANA_AI_KIT_BRANCH override the source
# (legacy SOLANA_CLAUDE_UPSTREAM / SOLANA_CLAUDE_BRANCH still honored)

REPO_URL="${SOLANA_AI_KIT_UPSTREAM:-${SOLANA_CLAUDE_UPSTREAM:-https://github.com/solanabr/solana-ai-kit.git}}"
BRANCH="${SOLANA_AI_KIT_BRANCH:-${SOLANA_CLAUDE_BRANCH:-main}}"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Auto-detect config dir from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_NAME="$(basename "$CONFIG_DIR")"
TARGET_DIR="$(cd "$CONFIG_DIR/.." && pwd)"

# Verify we're in a project with the config dir
if [ ! -d "$TARGET_DIR/$CONFIG_NAME" ]; then
  echo "Error: $CONFIG_NAME/ not found in $TARGET_DIR. Run from your project root."
  exit 1
fi

# Read current version
CURRENT_VERSION="unknown"
[ -f "$TARGET_DIR/$CONFIG_NAME/VERSION" ] && CURRENT_VERSION="$(awk '{print $NF}' "$TARGET_DIR/$CONFIG_NAME/VERSION")"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Fetch upstream (SOLANA_AI_KIT_LOCAL_SRC for local testing; legacy SOLANA_CLAUDE_LOCAL_SRC honored)
LOCAL_SRC="${SOLANA_AI_KIT_LOCAL_SRC:-${SOLANA_CLAUDE_LOCAL_SRC:-}}"
if [ -n "$LOCAL_SRC" ] && [ -d "$LOCAL_SRC/.claude" ]; then
  echo "Using local source: $LOCAL_SRC"
  mkdir -p "$TEMP_DIR/repo"
  cp -r "$LOCAL_SRC/.claude" "$TEMP_DIR/repo/.claude"
  [ -f "$LOCAL_SRC/CLAUDE-solana.md" ] && cp "$LOCAL_SRC/CLAUDE-solana.md" "$TEMP_DIR/repo/CLAUDE-solana.md"
  [ -f "$LOCAL_SRC/.mcp.json" ] && cp "$LOCAL_SRC/.mcp.json" "$TEMP_DIR/repo/.mcp.json"
  [ -f "$LOCAL_SRC/.env.example" ] && cp "$LOCAL_SRC/.env.example" "$TEMP_DIR/repo/.env.example"
  [ -f "$LOCAL_SRC/.gitmodules" ] && cp "$LOCAL_SRC/.gitmodules" "$TEMP_DIR/repo/.gitmodules"
else
  echo "Fetching latest from upstream..."
  git clone --recurse-submodules --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/repo" 2>&1 | tail -1 || true
fi

# Read new version
NEW_VERSION="unknown"
[ -f "$TEMP_DIR/repo/.claude/VERSION" ] && NEW_VERSION="$(awk '{print $NF}' "$TEMP_DIR/repo/.claude/VERSION")"

if [ "$CURRENT_VERSION" = "unknown" ]; then
  echo "Installing version tracking (first update)"
else
  echo "Updating v$CURRENT_VERSION → v$NEW_VERSION"
fi
echo ""
echo "Config directory: $CONFIG_NAME/"

# Track changes
CHANGES=""

# Preserved files — never overwrite these
# .env, settings.json, settings.local.json, .mcp.json, MEMORY.md, memory/, CLAUDE.local.md

# Directories to update (full update for both modes)
UPDATE_DIRS="agents skills rules commands bin"
echo "Updating: $UPDATE_DIRS"

for dir in $UPDATE_DIRS; do
  SRC="$TEMP_DIR/repo/.claude/$dir"
  DST="$TARGET_DIR/$CONFIG_NAME/$dir"
  if [ -d "$SRC" ]; then
    if [ "$DRY_RUN" = true ]; then
      if ! diff -rq "$SRC" "$DST" >/dev/null 2>&1; then
        CHANGES="$CHANGES  [would update] $CONFIG_NAME/$dir/\n"
      fi
    else
      if ! diff -rq "$SRC" "$DST" >/dev/null 2>&1; then
        CHANGES="$CHANGES  [updated] $CONFIG_NAME/$dir/\n"
      fi
      cp -r "$SRC" "$TARGET_DIR/$CONFIG_NAME/"
    fi
  fi
done

# NOTE: the loop above just overwrote bin/, i.e. this file. Bash reads a running
# script by byte offset, so an older update.sh carries on with the new code from
# here. Keep every byte above this comment unchanged; add new logic below it.

# The kit no longer ships rules/. Its old rule files used `globs:`, which Claude Code
# ignores, so they loaded into every session. Remove those copies; rules the user
# wrote are left alone.
for f in anchor.md dotnet.md pinocchio.md rust.md typescript.md; do
  OLD="$TARGET_DIR/$CONFIG_NAME/rules/$f"
  if [ -f "$OLD" ] && grep -q '^globs:' "$OLD"; then
    if [ "$DRY_RUN" = true ]; then
      CHANGES="$CHANGES  [would remove] $CONFIG_NAME/rules/$f (retired kit rule)\n"
    else
      rm "$OLD"
      CHANGES="$CHANGES  [removed] $CONFIG_NAME/rules/$f (retired kit rule)\n"
    fi
  fi
done
[ "$DRY_RUN" = true ] || rmdir "$TARGET_DIR/$CONFIG_NAME/rules" 2>/dev/null || true

# --agents installs: the kit ships .claude/ paths. Point what was just copied at
# .agents/ (same rewrite as install.sh). Left alone: ~/.claude/, the vendored
# ext/ repos, bin/, and lines that already name .agents/ (they handle both modes).
agents_paths() {
  local f
  for f in "$@"; do
    [ -f "$f" ] && grep -q '\.claude/' "$f" || continue
    sed -E '/\.agents\//!{s#(^|[^[:alnum:]_./~-])\.claude/#\1.agents/#g;s#([$][{]CLAUDE_PROJECT_DIR:-[.][}])/\.claude/#\1/.agents/#g;}' \
      "$f" > "$f.tmp" && cat "$f.tmp" > "$f" && rm -f "$f.tmp"
  done
}
INSTR_FILE="CLAUDE.md"
if [ "$CONFIG_NAME" = ".agents" ]; then
  INSTR_FILE="AGENTS.md"
  agents_paths "$TEMP_DIR/repo/CLAUDE-solana.md" "$TEMP_DIR/repo/.gitmodules"
  if [ "$DRY_RUN" = false ]; then
    while IFS= read -r rel; do agents_paths "$TARGET_DIR/$CONFIG_NAME/$rel"; done < <(
      cd "$TEMP_DIR/repo/.claude" && find agents commands rules skills -path skills/ext -prune -o -type f -print 2>/dev/null
    )
    # Older --agents installs registered ext/ under .claude/ paths; drop those
    # stale entries unless a regular .claude/ install still uses them.
    if [ -f "$TARGET_DIR/.gitmodules" ] && [ ! -d "$TARGET_DIR/.claude/skills/ext" ]; then
      STALE="$(git config -f "$TARGET_DIR/.gitmodules" --get-regexp '^submodule\..*\.path$' 2>/dev/null \
        | awk '$2 ~ /^\.claude\/skills\/ext\// { sub(/\.path$/, "", $1); print $1 }' || true)"
      for section in $STALE; do git config -f "$TARGET_DIR/.gitmodules" --remove-section "$section"; done
      if [ -n "$STALE" ]; then
        CHANGES="$CHANGES  [migrated] .gitmodules ext/ entries now point at .agents/skills/ext/\n"
      fi
    fi
  fi
fi

# ext/ skills are vendored copies: drop submodule gitfiles copied from the
# fetched clone whose gitdir doesn't exist here.
if [ "$DRY_RUN" = false ] && [ -d "$TARGET_DIR/$CONFIG_NAME/skills/ext" ]; then
  while IFS= read -r gitfile; do
    gitdir="$(sed -n 's/^gitdir: //p' "$gitfile")"
    (cd "$(dirname "$gitfile")" && [ -n "$gitdir" ] && [ -d "$gitdir" ]) || rm -f "$gitfile"
  done < <(find "$TARGET_DIR/$CONFIG_NAME/skills/ext" -name .git -type f)
fi

# Merge .gitmodules (don't overwrite — user may have their own submodules)
if [ -f "$TEMP_DIR/repo/.gitmodules" ]; then
  if [ ! -f "$TARGET_DIR/.gitmodules" ]; then
    if ! diff -q "$TEMP_DIR/repo/.gitmodules" "$TARGET_DIR/.gitmodules" >/dev/null 2>&1; then
      CHANGES="$CHANGES  [updated] .gitmodules\n"
    fi
    if [ "$DRY_RUN" = false ]; then
      cp "$TEMP_DIR/repo/.gitmodules" "$TARGET_DIR/.gitmodules"
    fi
  else
    # Append submodule entries that don't already exist in target. One pass with a
    # flag: a nested read loop would swallow the next [submodule] header.
    ADDED_SUBMODS=""
    COPYING=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^\[submodule\ \"(.+)\"\] ]]; then
        COPYING=false
        submod="${BASH_REMATCH[1]}"
        if ! grep -qF "[submodule \"$submod\"]" "$TARGET_DIR/.gitmodules"; then
          ADDED_SUBMODS="$ADDED_SUBMODS $submod"
          COPYING=true
          if [ "$DRY_RUN" = false ]; then
            printf '\n%s\n' "$line" >> "$TARGET_DIR/.gitmodules"
          fi
        fi
      elif [ "$COPYING" = true ] && [ -n "$line" ] && [ "$DRY_RUN" = false ]; then
        printf '%s\n' "$line" >> "$TARGET_DIR/.gitmodules"
      fi
    done < "$TEMP_DIR/repo/.gitmodules"
    if [ -n "$ADDED_SUBMODS" ]; then
      CHANGES="$CHANGES  [merged] .gitmodules (added:$ADDED_SUBMODS)\n"
    fi
  fi
fi

# Update VERSION
if [ -f "$TEMP_DIR/repo/.claude/VERSION" ]; then
  if [ "$DRY_RUN" = false ]; then
    cp "$TEMP_DIR/repo/.claude/VERSION" "$TARGET_DIR/$CONFIG_NAME/VERSION"
  fi
  CHANGES="$CHANGES  [updated] $CONFIG_NAME/VERSION → $NEW_VERSION\n"
fi

# CHANGELOG.md stays in source repo — not shipped to user projects

# Merge .env.example — append new vars without overwriting user edits
# shellcheck source=_env_merge.sh
source "$SCRIPT_DIR/_env_merge.sh"
if [ -f "$TEMP_DIR/repo/.env.example" ]; then
  if [ "$DRY_RUN" = true ]; then
    # Check if there would be new vars
    if [ -f "$TARGET_DIR/.env.example" ]; then
      local_keys=$(grep -oE '^[A-Z_][A-Z0-9_]*=' "$TARGET_DIR/.env.example" 2>/dev/null || true)
      new_keys=""
      while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)= ]]; then
          key="${BASH_REMATCH[1]}"
          if ! echo "$local_keys" | grep -q "^${key}=$"; then
            new_keys="$new_keys $key"
          fi
        fi
      done < "$TEMP_DIR/repo/.env.example"
      if [ -n "$new_keys" ]; then
        CHANGES="$CHANGES  [would add] New env vars in .env.example:$new_keys\n"
      fi
    else
      CHANGES="$CHANGES  [would create] .env.example\n"
    fi
  else
    merge_env_file "$TEMP_DIR/repo/.env.example" "$TARGET_DIR/.env.example"
    if [ -f "$TARGET_DIR/.env" ]; then
      merge_env_file "$TEMP_DIR/repo/.env.example" "$TARGET_DIR/.env"
    fi
    CHANGES="$CHANGES  [merged] .env.example (new vars appended)\n"
  fi
fi

# Instruction file (CLAUDE.md, or AGENTS.md for --agents) — don't overwrite,
# offer the upstream version for manual merge
if [ -f "$TEMP_DIR/repo/CLAUDE-solana.md" ]; then
  if [ -f "$TARGET_DIR/$INSTR_FILE" ]; then
    if ! diff -q "$TEMP_DIR/repo/CLAUDE-solana.md" "$TARGET_DIR/$INSTR_FILE" >/dev/null 2>&1; then
      if [ "$DRY_RUN" = false ]; then
        cp "$TEMP_DIR/repo/CLAUDE-solana.md" "$TARGET_DIR/$INSTR_FILE.upstream"
      fi
      CHANGES="$CHANGES  [notice] New upstream $INSTR_FILE available at $INSTR_FILE.upstream — review and merge manually\n"
    fi
  else
    if [ "$DRY_RUN" = false ]; then
      cp "$TEMP_DIR/repo/CLAUDE-solana.md" "$TARGET_DIR/$INSTR_FILE"
    fi
    CHANGES="$CHANGES  [created] $INSTR_FILE\n"
    if [ "$INSTR_FILE" = "AGENTS.md" ] && [ -f "$TARGET_DIR/CLAUDE.md" ]; then
      CHANGES="$CHANGES  [notice] --agents installs now use AGENTS.md; CLAUDE.md is no longer updated\n"
    fi
  fi
fi

# Older --agents installs listed CLAUDE.md in the .gitignore config block; add AGENTS.md
GITIGNORE="$TARGET_DIR/.gitignore"
if [ "$INSTR_FILE" = "AGENTS.md" ] && [ "$DRY_RUN" = false ] && [ -f "$GITIGNORE" ] \
  && grep -qF ">>> solana-ai-kit config" "$GITIGNORE" \
  && ! sed -n '/>>> solana-ai-kit config/,/<<< solana-ai-kit config/p' "$GITIGNORE" | grep -qxF "$INSTR_FILE"; then
  awk -v f="$INSTR_FILE" '/^# <<< solana-ai-kit config <<</ { print f } { print }' "$GITIGNORE" > "$GITIGNORE.tmp" \
    && cat "$GITIGNORE.tmp" > "$GITIGNORE" && rm -f "$GITIGNORE.tmp"
  CHANGES="$CHANGES  [updated] .gitignore — $INSTR_FILE added to the kit config block\n"
fi

# CLAUDE.local.md is created organically by Claude when needed (gitignored)

# Update submodules
if [ "$DRY_RUN" = false ]; then
  echo "Updating submodules..."
  (cd "$TARGET_DIR" && git submodule update --init --recursive 2>/dev/null) || echo "Note: Submodule update skipped"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
  echo "=== DRY RUN — no changes written ==="
  echo ""
fi

if [ -n "$CHANGES" ]; then
  echo "Changes:"
  printf "$CHANGES"
else
  echo "Already up to date."
fi

echo ""
echo "Update complete!"
