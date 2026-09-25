#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "[test_install_agents_only] Installing --agents to temp directory: $TEMP_DIR"

# Initialize a git repo so submodule commands work
(cd "$TEMP_DIR" && git init -q)

# Run install.sh in agents-only mode
SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" bash "$REPO_ROOT/install.sh" --agents "$TEMP_DIR"

echo ""
echo "[test_install_agents_only] Verifying --agents installation..."

# .agents/ directory should exist (NOT .claude/)
assert_dir_exists "$TEMP_DIR/.agents" ".agents/ directory exists"

# .claude/ should NOT exist
TOTAL=$((TOTAL + 1))
if [ ! -d "$TEMP_DIR/.claude" ]; then
  echo "  PASS: .claude/ does NOT exist (--agents mode installs to .agents/)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: .claude/ should NOT exist in --agents mode"
  FAIL=$((FAIL + 1))
fi

# All subdirectories should exist in .agents/
assert_dir_exists "$TEMP_DIR/.agents/agents" ".agents/agents/ directory exists"
assert_dir_exists "$TEMP_DIR/.agents/commands" ".agents/commands/ directory exists"
assert_dir_exists "$TEMP_DIR/.agents/skills" ".agents/skills/ directory exists"
assert_dir_not_exists "$TEMP_DIR/.agents/rules" ".agents/rules/ not installed (kit ships none)"
assert_dir_exists "$TEMP_DIR/.agents/bin" ".agents/bin/ directory exists"
assert_file_exists "$TEMP_DIR/.agents/skills/SKILL.md" "SKILL.md exists in .agents/"

# settings.json should exist in .agents/
assert_json_valid "$TEMP_DIR/.agents/settings.json" ".agents/settings.json is valid JSON"

# Count agents (should match full install)
AGENT_COUNT=$(find "$TEMP_DIR/.agents/agents" -name "*.md" | wc -l | tr -d ' ')
assert_eq "15" "$AGENT_COUNT" "Agent count is 15"

# Count commands (should match full install)
CMD_COUNT=$(find "$TEMP_DIR/.agents/commands" -name "*.md" | wc -l | tr -d ' ')
assert_eq "30" "$CMD_COUNT" "Command count is 30"

# AGENTS.md (read by Codex and opencode) should exist at project root; CLAUDE.md stays Claude Code's
assert_file_exists "$TEMP_DIR/AGENTS.md" "AGENTS.md exists at project root"
assert_file_not_exists "$TEMP_DIR/CLAUDE.md" "CLAUDE.md is not written in --agents mode"

# .gitignore should have .agents/skills/ext/ entry
assert_file_exists "$TEMP_DIR/.gitignore" ".gitignore exists"
GITIGNORE_CONTENT="$(cat "$TEMP_DIR/.gitignore")"
assert_contains "$GITIGNORE_CONTENT" ".agents/skills/ext/" ".gitignore contains .agents/skills/ext/ entry"
assert_contains "$GITIGNORE_CONTENT" ".gitmodules" ".gitignore contains .gitmodules (config gitignored by default)"
assert_contains "$GITIGNORE_CONTENT" "solana-ai-kit config" ".gitignore has config markers for /commit-claude-config"

# ── Agents-mode layout checks (mirrors the agents-mode job in .github/workflows/ci.yml) ──
WORK="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR" "$WORK"' EXIT
export SOLANA_AI_KIT_LOCAL_SRC="$REPO_ROOT" NO_COLOR=1

# install_agents <dir> — returns install.sh's exit code; output goes to $WORK/last.log
install_agents() { bash "$REPO_ROOT/install.sh" --agents "$1" >"$WORK/last.log" 2>&1; }

# Project-relative .claude/ paths would dangle in an agents-mode install (this mode
# never creates .claude/). Intentional ones are skipped: ~/.claude/ and $HOME/.claude/
# (user-global), paths inside the vendored ext/ repos, bin/ (scripts resolve their own
# dir and read the kit repo's .claude/ layout), and lines that also name .agents/.
CLAUDE_REF='(^|[^[:alnum:]_./~-])\.claude/|CLAUDE_PROJECT_DIR:-[.][}]/\.claude/'
dangling_claude_refs() {
  local d="$1"
  {
    grep -rnE --exclude-dir=ext --exclude-dir=bin "$CLAUDE_REF" \
      "$d/.agents" "$d/AGENTS.md" "$d/.gitmodules" 2>/dev/null || true
    sed -n '/>>> solana-ai-kit config/,/<<< solana-ai-kit config/p' "$d/.gitignore" 2>/dev/null \
      | grep '\.claude' || true
  } | grep -v '\.agents/' || true
}

# snapshot <dir> [paths...] — checksums of every file (default: whole tree minus .git/)
snapshot() {
  local d="$1"; shift
  if [ "$#" -eq 0 ]; then set -- .; fi
  (cd "$d" && find "$@" -path ./.git -prune -o -type f -exec cksum {} + | LC_ALL=C sort -k3)
}

assert_no_dangling_refs() {
  local refs; refs="$(dangling_claude_refs "$1")"
  TOTAL=$((TOTAL + 1))
  if [ -z "$refs" ]; then
    echo "  PASS: $2"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $2"
    printf '%s\n' "$refs" | head -10 | sed 's/^/    /'
    FAIL=$((FAIL + 1))
  fi
}

assert_submodules_under_agents() {
  local d="$1" paths bad="" p
  paths="$(git config -f "$d/.gitmodules" --get-regexp '\.path$' 2>/dev/null | awk '{print $2}')"
  for p in $paths; do
    case "$p" in
      .agents/skills/ext/*) [ -n "$(ls -A "$d/$p" 2>/dev/null)" ] || bad="$bad $p(empty)" ;;
      *) bad="$bad $p" ;;
    esac
  done
  assert_eq "$(git config -f "$REPO_ROOT/.gitmodules" --get-regexp '\.path$' | wc -l | tr -d ' ')" \
    "$(printf '%s\n' "$paths" | grep -c .)" "$2: every kit submodule is registered"
  assert_eq "" "$bad" "$2: .gitmodules paths are populated dirs under .agents/skills/ext/"
  assert_eq "0" "$(find "$d/.agents/skills/ext" -name .git -type f | wc -l | tr -d ' ')" \
    "$2: no dangling submodule gitfiles in .agents/skills/ext/"
}

echo "[instruction file + paths]"
# Generic, not tied to CLAUDE-solana.md's wording: only .claude/ -> .agents/ path rewrites
sed 's#\.agents/#.claude/#g' "$TEMP_DIR/AGENTS.md" > "$WORK/agents-md.norm" 2>/dev/null || true
sed 's#\.agents/#.claude/#g' "$REPO_ROOT/CLAUDE-solana.md" > "$WORK/claude-solana-md.norm"
assert_cmd_success "cmp -s '$WORK/agents-md.norm' '$WORK/claude-solana-md.norm'" \
  "AGENTS.md is CLAUDE-solana.md with only .claude/ -> .agents/ path changes"
assert_eq "" "$(grep -nE "$CLAUDE_REF" "$TEMP_DIR/AGENTS.md" | grep -v '\.agents/' || true)" \
  "AGENTS.md has no dangling .claude/ path"
assert_eq "AGENTS.md" "$(sed -n '/>>> solana-ai-kit config/,/<<< solana-ai-kit config/p' "$TEMP_DIR/.gitignore" | grep -x 'AGENTS.md' || true)" \
  ".gitignore config block lists AGENTS.md"
assert_no_dangling_refs "$TEMP_DIR" "no dangling .claude/ references in the installed tree"
assert_submodules_under_agents "$TEMP_DIR" "fresh install"

# ── Idempotent re-install ───────────────────────────────────────────────────
echo "[idempotent re-install]"
snapshot "$TEMP_DIR" > "$WORK/before.txt"
assert_cmd_success "install_agents '$TEMP_DIR'" "second install.sh --agents exits 0"
snapshot "$TEMP_DIR" > "$WORK/after.txt"
assert_cmd_success "diff '$WORK/before.txt' '$WORK/after.txt'" "second install changes no file"
assert_file_not_exists "$TEMP_DIR/AGENTS.md.bak" "no AGENTS.md.bak when AGENTS.md is unchanged"

# ── Next to an existing Claude Code setup ───────────────────────────────────
echo "[existing .claude/]"
WITH_CLAUDE="$WORK/with-claude"; mkdir -p "$WITH_CLAUDE/.claude/agents"; git -C "$WITH_CLAUDE" init -q
echo '{"user_custom": true}' > "$WITH_CLAUDE/.claude/settings.json"
echo "# my agent" > "$WITH_CLAUDE/.claude/agents/mine.md"
echo "# my Claude Code instructions" > "$WITH_CLAUDE/CLAUDE.md"
BEFORE="$(snapshot "$WITH_CLAUDE" .claude CLAUDE.md)"
assert_cmd_success "install_agents '$WITH_CLAUDE'" "install.sh --agents next to .claude/ exits 0"
assert_eq "$BEFORE" "$(snapshot "$WITH_CLAUDE" .claude CLAUDE.md)" ".claude/ and CLAUDE.md are left untouched"
assert_file_not_exists "$WITH_CLAUDE/CLAUDE.md.bak" "no CLAUDE.md.bak (CLAUDE.md is not replaced)"
assert_file_exists "$WITH_CLAUDE/AGENTS.md" "AGENTS.md installed next to .claude/"
assert_no_dangling_refs "$WITH_CLAUDE" "no dangling .claude/ references next to .claude/"

# ── Existing .agents/ (e.g. the user's own Codex skills), AGENTS.md, .gitmodules ──
echo "[existing .agents/]"
WITH_AGENTS="$WORK/with-agents"; mkdir -p "$WITH_AGENTS/.agents/skills/my-skill"; git -C "$WITH_AGENTS" init -q
printf -- '---\nname: my-skill\ndescription: mine\n---\n' > "$WITH_AGENTS/.agents/skills/my-skill/SKILL.md"
echo "# my AGENTS.md" > "$WITH_AGENTS/AGENTS.md"
printf '[submodule "vendor/lib"]\n\tpath = vendor/lib\n\turl = https://example.com/lib.git\n' > "$WITH_AGENTS/.gitmodules"
assert_cmd_success "install_agents '$WITH_AGENTS'" "install.sh --agents over an existing .agents/ exits 0"
assert_file_contains "$WITH_AGENTS/.agents/skills/my-skill/SKILL.md" "name: my-skill" "user's own skill preserved"
assert_file_contains "$WITH_AGENTS/AGENTS.md.bak" "my AGENTS.md" "user's AGENTS.md backed up to AGENTS.md.bak"
assert_cmd_success "cmp -s '$TEMP_DIR/AGENTS.md' '$WITH_AGENTS/AGENTS.md'" "AGENTS.md replaced with the kit's"
assert_file_contains "$WITH_AGENTS/.gitmodules" 'path = vendor/lib' "user's own .gitmodules entry preserved"
assert_eq "$(git config -f "$REPO_ROOT/.gitmodules" --get-regexp '\.path$' | wc -l | tr -d ' ')" \
  "$(git config -f "$WITH_AGENTS/.gitmodules" --get-regexp '\.path$' | grep -c ' \.agents/skills/ext/')" \
  "every kit submodule merged into an existing .gitmodules"

# ── update.sh and resync.sh from .agents/bin ────────────────────────────────
echo "[update.sh + resync.sh]"
if DRY_OUT="$(cd "$TEMP_DIR" && bash .agents/bin/update.sh --dry-run 2>&1)"; then RC=0; else RC=$?; fi
assert_eq "0" "$RC" "update.sh --dry-run exits 0"
assert_contains "$DRY_OUT" "DRY RUN" "update.sh --dry-run reports a dry run"
assert_cmd_success "cd '$TEMP_DIR' && bash .agents/bin/update.sh" "update.sh exits 0"
assert_dir_not_exists "$TEMP_DIR/.claude" "update.sh does not create .claude/"
assert_file_not_exists "$TEMP_DIR/CLAUDE.md" "update.sh does not create CLAUDE.md"
assert_file_not_exists "$TEMP_DIR/AGENTS.md.upstream" "no AGENTS.md.upstream when AGENTS.md matches upstream"
assert_no_dangling_refs "$TEMP_DIR" "no dangling .claude/ references after update.sh"
assert_submodules_under_agents "$TEMP_DIR" "after update.sh"

if RESYNC_OUT="$(cd "$WORK" && bash "$TEMP_DIR/.agents/bin/resync.sh" 2>&1)"; then RC=0; else RC=$?; fi
assert_eq "0" "$RC" "resync.sh exits 0 (run from another cwd)"
assert_contains "$RESYNC_OUT" "All skill paths resolve correctly." "resync.sh resolves every SKILL.md path"
assert_dir_not_exists "$TEMP_DIR/.claude" "resync.sh does not create .claude/"

# ── Not a git repository ────────────────────────────────────────────────────
echo "[non-git directory]"
NOGIT="$WORK/nogit"; mkdir -p "$NOGIT"
assert_cmd_success "install_agents '$NOGIT'" "install.sh --agents exits 0 outside git"
assert_no_dangling_refs "$NOGIT" "no dangling .claude/ references outside git"
assert_cmd_success "cd '$NOGIT' && bash .agents/bin/update.sh" "update.sh exits 0 outside git"
if RESYNC_OUT="$(cd "$NOGIT" && bash .agents/bin/resync.sh 2>&1)"; then RC=0; else RC=$?; fi
assert_eq "0" "$RC" "resync.sh exits 0 outside git"
assert_contains "$RESYNC_OUT" "Not a git repository" "resync.sh explains it skipped the submodule update"
assert_dir_not_exists "$NOGIT/.claude" "nothing written under .claude/ outside git"

# ── Upgrade an install made by an older --agents installer ──────────────────
# Older installers wrote CLAUDE.md, kept .claude/skills/ext/ paths in .gitmodules
# and copied dangling submodule gitfiles.
echo "[upgrade from an older --agents install]"
for OLD in "$WORK/old-update" "$WORK/old-reinstall"; do
  mkdir -p "$OLD"; git -C "$OLD" init -q
  install_agents "$OLD" || true
  mv "$OLD/AGENTS.md" "$OLD/CLAUDE.md" 2>/dev/null || true
  sed 's#\.agents/skills/ext/#.claude/skills/ext/#g' "$OLD/.gitmodules" > "$WORK/gm" && cat "$WORK/gm" > "$OLD/.gitmodules"
  sed 's#^AGENTS\.md$#CLAUDE.md#' "$OLD/.gitignore" > "$WORK/gi" && cat "$WORK/gi" > "$OLD/.gitignore"
  echo "gitdir: ../../../../.git/modules/.claude/skills/ext/solana-dev" > "$OLD/.agents/skills/ext/solana-dev/.git" 2>/dev/null || true
done
assert_cmd_success "cd '$WORK/old-update' && bash .agents/bin/update.sh" "update.sh upgrades an older --agents install"
assert_cmd_success "install_agents '$WORK/old-reinstall'" "install.sh --agents re-install upgrades an older --agents install"
for OLD in "$WORK/old-update" "$WORK/old-reinstall"; do
  NAME="$(basename "$OLD")"
  assert_file_exists "$OLD/AGENTS.md" "$NAME: AGENTS.md created"
  assert_eq "AGENTS.md" "$(sed -n '/>>> solana-ai-kit config/,/<<< solana-ai-kit config/p' "$OLD/.gitignore" | grep -x 'AGENTS.md' || true)" \
    "$NAME: AGENTS.md added to the .gitignore config block"
  assert_submodules_under_agents "$OLD" "$NAME"
done

print_summary
