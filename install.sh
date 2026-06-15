#!/usr/bin/env bash
set -euo pipefail

# Solana AI Kit Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/solanabr/solana-ai-kit/main/install.sh | bash
#   bash install.sh /path/to/project
#   bash install.sh --agents /path/to/project   # installs into .agents/ instead of .claude/

REPO_URL="https://github.com/solanabr/solana-ai-kit.git"
SCRIPT_VERSION="dev"

# Resolve latest tagged release; fall back to main
LATEST_TAG=$(git ls-remote --tags --sort=-v:refname "$REPO_URL" 'refs/tags/v*' 2>/dev/null \
  | head -1 | sed 's|.*refs/tags/||; s|\^{}||')
BRANCH="${LATEST_TAG:-main}"

# Parse flags
AGENTS_ONLY=false
TARGET_ARG=""
for arg in "$@"; do
  case "$arg" in
    --agents) AGENTS_ONLY=true ;;
    *) TARGET_ARG="$arg" ;;
  esac
done

TARGET_DIR="${TARGET_ARG:-.}"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Set config directory name based on flag
if [ "$AGENTS_ONLY" = true ]; then
  CONFIG_DIR=".agents"
else
  CONFIG_DIR=".claude"
fi

# ── Branding ──────────────────────────────────────────────────────────────
# Solana gradient (purple → green), only on interactive truecolor terminals.
# NO_COLOR (https://no-color.org) and non-TTY output stay plain.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && printf %s "${COLORTERM:-}" | grep -qiE 'truecolor|24bit'; then
  C1=$'\033[38;2;153;69;255m'; C2=$'\033[38;2;131;98;237m'
  C3=$'\033[38;2;109;126;220m'; C4=$'\033[38;2;86;155;202m'
  C5=$'\033[38;2;64;184;184m'; C6=$'\033[38;2;42;212;167m'
  C7=$'\033[38;2;20;241;149m'
  CDIM=$'\033[2m'; CRST=$'\033[0m'
else
  C1=""; C2=""; C3=""; C4=""; C5=""; C6=""; C7=""; CDIM=""; CRST=""
fi

print_banner() {
  printf '%s%s%s\n' "$C1" '   _____ ____  __    ___    _   _____' "$CRST"
  printf '%s%s%s\n' "$C2" '  / ___// __ \/ /   /   |  / | / /   |' "$CRST"
  printf '%s%s%s\n' "$C3" '  \__ \/ / / / /   / /| | /  |/ / /| |' "$CRST"
  printf '%s%s%s\n' "$C4" ' ___/ / /_/ / /___/ ___ |/ /|  / ___ |' "$CRST"
  printf '%s%s%s\n' "$C5" '/____/\____/_____/_/  |_/_/ |_/_/  |_|' "$CRST"
  printf '%s%s%s\n' "$C6" '           ▄▀█ █   █▄▀ █ ▀█▀' "$CRST"
  printf '%s%s%s\n' "$C7" '           █▀█ █   █ █ █  █' "$CRST"
  printf '%s\n\n' "${CDIM}by @SuperteamBR 🇧🇷${CRST}"
}

# Log helpers — glyph prefixes only; message text stays grep-stable.
step() { printf '▸ %s\n' "$*"; }
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*"; }
fail() { printf '✗ %s\n' "$*"; }

print_banner

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Support local source for testing: SOLANA_AI_KIT_LOCAL_SRC=/path/to/repo
# (SOLANA_CLAUDE_LOCAL_SRC honored as legacy fallback)
LOCAL_SRC="${SOLANA_AI_KIT_LOCAL_SRC:-${SOLANA_CLAUDE_LOCAL_SRC:-}}"
if [ -n "$LOCAL_SRC" ] && [ -d "$LOCAL_SRC/.claude" ]; then
  step "Using local source: $LOCAL_SRC"
  mkdir -p "$TEMP_DIR/repo"
  cp -r "$LOCAL_SRC/.claude" "$TEMP_DIR/repo/.claude"
  cp "$LOCAL_SRC/CLAUDE-solana.md" "$TEMP_DIR/repo/CLAUDE-solana.md"
  [ -f "$LOCAL_SRC/.mcp.json" ] && cp "$LOCAL_SRC/.mcp.json" "$TEMP_DIR/repo/.mcp.json"
  [ -f "$LOCAL_SRC/.env.example" ] && cp "$LOCAL_SRC/.env.example" "$TEMP_DIR/repo/.env.example"
  [ -f "$LOCAL_SRC/.gitmodules" ] && cp "$LOCAL_SRC/.gitmodules" "$TEMP_DIR/repo/.gitmodules"
  [ -f "$LOCAL_SRC/.claude/VERSION" ] && cp "$LOCAL_SRC/.claude/VERSION" "$TEMP_DIR/repo/.claude/VERSION"
  # CHANGELOG.md stays in the repo — not shipped to user projects
else
  # Clone repo with submodules
  step "Cloning repository..."
  git clone --recurse-submodules --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/repo" 2>&1 | tail -1 || true
fi

# Read version from source
[ -f "$TEMP_DIR/repo/.claude/VERSION" ] && SCRIPT_VERSION="$(awk '{print $NF}' "$TEMP_DIR/repo/.claude/VERSION")"

step "Installing Solana AI Kit v$SCRIPT_VERSION to: $TARGET_DIR ($CONFIG_DIR/)"

# Copy .claude/ as $CONFIG_DIR (selective — protects user files)
step "Copying $CONFIG_DIR/ configuration..."
mkdir -p "$TARGET_DIR/$CONFIG_DIR"

if [ -d "$TARGET_DIR/$CONFIG_DIR/agents" ]; then
  warn "Warning: $CONFIG_DIR/ already exists, merging..."
fi

# Directories: always overwrite with upstream (same as update.sh)
for dir in agents skills rules commands bin; do
  if [ -d "$TEMP_DIR/repo/.claude/$dir" ]; then
    cp -r "$TEMP_DIR/repo/.claude/$dir" "$TARGET_DIR/$CONFIG_DIR/"
  fi
done

# VERSION: always overwrite (CHANGELOG stays in source repo only)
[ -f "$TEMP_DIR/repo/.claude/VERSION" ] && cp "$TEMP_DIR/repo/.claude/VERSION" "$TARGET_DIR/$CONFIG_DIR/VERSION"

# Protected files: only copy if target doesn't exist yet
if [ -f "$TEMP_DIR/repo/.claude/settings.json" ] && [ ! -f "$TARGET_DIR/$CONFIG_DIR/settings.json" ]; then
  cp "$TEMP_DIR/repo/.claude/settings.json" "$TARGET_DIR/$CONFIG_DIR/settings.json"
fi

# MCP config: lives at project root as .mcp.json (Claude Code only reads this path)
if [ -f "$TEMP_DIR/repo/.mcp.json" ] && [ ! -f "$TARGET_DIR/.mcp.json" ]; then
  cp "$TEMP_DIR/repo/.mcp.json" "$TARGET_DIR/.mcp.json"
fi

# Copy CLAUDE-solana.md as CLAUDE.md
step "Copying CLAUDE.md..."
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  warn "Warning: CLAUDE.md already exists, backing up to CLAUDE.md.bak"
  cp "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md.bak"
fi
cp "$TEMP_DIR/repo/CLAUDE-solana.md" "$TARGET_DIR/CLAUDE.md"

# Merge .gitmodules (don't overwrite — user may have their own submodules)
if [ -f "$TEMP_DIR/repo/.gitmodules" ]; then
  if [ ! -f "$TARGET_DIR/.gitmodules" ]; then
    cp "$TEMP_DIR/repo/.gitmodules" "$TARGET_DIR/.gitmodules"
  else
    # Append submodule entries that don't already exist in target
    while IFS= read -r line; do
      if [[ "$line" =~ ^\[submodule\ \"(.+)\"\] ]]; then
        submod="${BASH_REMATCH[1]}"
        if ! grep -qF "[submodule \"$submod\"]" "$TARGET_DIR/.gitmodules"; then
          echo "" >> "$TARGET_DIR/.gitmodules"
          echo "$line" >> "$TARGET_DIR/.gitmodules"
          # Read and append path + url lines
          while IFS= read -r detail; do
            [[ "$detail" =~ ^\[submodule ]] && break
            [ -n "$detail" ] && echo "$detail" >> "$TARGET_DIR/.gitmodules"
          done
        fi
      fi
    done < "$TEMP_DIR/repo/.gitmodules"
  fi
fi

# Initialize submodules in target
step "Initializing submodules..."
(cd "$TARGET_DIR" && git submodule update --init --recursive 2>/dev/null) || warn "Note: Submodule init skipped (not a git repo or submodules already set up)"

# Add $CONFIG_DIR/skills/ext/ to .gitignore if not present
GITIGNORE="$TARGET_DIR/.gitignore"
EXT_PATTERN="$CONFIG_DIR/skills/ext/"
if [ -f "$GITIGNORE" ]; then
  if ! grep -qF "$EXT_PATTERN" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo "# External Claude skill submodules" >> "$GITIGNORE"
    echo "$EXT_PATTERN" >> "$GITIGNORE"
    ok "Added $EXT_PATTERN to .gitignore"
  fi
else
  echo "# External Claude skill submodules" > "$GITIGNORE"
  echo "$EXT_PATTERN" >> "$GITIGNORE"
  ok "Created .gitignore with $EXT_PATTERN"
fi

# Add CLAUDE.local.md to .gitignore (Claude creates it organically when needed)
if ! grep -qF "CLAUDE.local.md" "$GITIGNORE"; then
  echo "CLAUDE.local.md" >> "$GITIGNORE"
fi

# Add $CONFIG_DIR/context/ to .gitignore (phase-handoff files: idea.md, build.md)
CONTEXT_PATTERN="$CONFIG_DIR/context/"
if ! grep -qF "$CONTEXT_PATTERN" "$GITIGNORE"; then
  echo "$CONTEXT_PATTERN" >> "$GITIGNORE"
fi

# Merge .env.example (append-only — preserves user edits on reinstall)
# shellcheck source=.claude/bin/_env_merge.sh
source "$TEMP_DIR/repo/.claude/bin/_env_merge.sh"
if [ -f "$TEMP_DIR/repo/.env.example" ]; then
  merge_env_file "$TEMP_DIR/repo/.env.example" "$TARGET_DIR/.env.example"
  if [ ! -f "$TARGET_DIR/.env" ]; then
    cp "$TARGET_DIR/.env.example" "$TARGET_DIR/.env"
    ok "Created .env from .env.example"
  else
    # Append new keys (with empty values) to existing .env
    merge_env_file "$TEMP_DIR/repo/.env.example" "$TARGET_DIR/.env"
  fi
fi

echo ""
BOX_LINES=(
  "Installation complete!"
  ""
  "Next steps:"
  "  1. cd $TARGET_DIR"
  "  2. Edit .env to add your API keys (Helius, RPC, etc.)"
  "  3. Run 'claude' to start Claude Code with Solana config"
  "  4. Try /build-program or /audit-solana commands"
  ""
  "This is the full install. If you also enable the solana-ai-kit"
  "plugin, prefer one path — both double-load commands/hooks/MCP"
  "(run /doctor to check)."
)
if [ "$AGENTS_ONLY" = true ]; then
  BOX_LINES+=("")
  BOX_LINES+=("Note: Installed into $CONFIG_DIR/ (--agents mode).")
  BOX_LINES+=("The .md files also work as system prompts or context for any AI tool")
  BOX_LINES+=("(Cursor, Windsurf, Copilot, etc.).")
fi
BOX_W=0
for line in "${BOX_LINES[@]}"; do
  if [ "${#line}" -gt "$BOX_W" ]; then BOX_W="${#line}"; fi
done
BOX_BORDER=""
i=0
while [ "$i" -lt $((BOX_W + 2)) ]; do BOX_BORDER="${BOX_BORDER}─"; i=$((i + 1)); done
printf '%s╭%s╮%s\n' "$C1" "$BOX_BORDER" "$CRST"
for line in "${BOX_LINES[@]}"; do
  printf '%s│%s %-*s %s│%s\n' "$CDIM" "$CRST" "$BOX_W" "$line" "$CDIM" "$CRST"
done
printf '%s╰%s╯%s\n' "$C7" "$BOX_BORDER" "$CRST"
