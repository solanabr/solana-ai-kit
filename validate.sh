#!/usr/bin/env bash
set -euo pipefail

# Solana AI Kit Validator
# Run from repo root to check config integrity.

PASS=0
FAIL=0
SKIP=0

# A path lives under an ext/ submodule; if that submodule dir is empty it isn't
# initialized (fresh clone without --recurse-submodules, or before install.sh) —
# a setup state, NOT broken config. Return 0 when the path is inside an
# uninitialized submodule so callers can SKIP instead of FAIL.
in_uninitialized_submodule() {
  local path="$1"
  case "$path" in
    .claude/skills/ext/*)
      local sub
      sub="$(printf '%s' "$path" | sed -E 's#(\.claude/skills/ext/[^/]+).*#\1#')"
      [ -d "$sub" ] && [ -z "$(ls -A "$sub" 2>/dev/null)" ]
      ;;
    *) return 1 ;;
  esac
}

check() {
  local description="$1"
  local result="$2"
  if [ "$result" -eq 0 ]; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    FAIL=$((FAIL + 1))
  fi
}

echo "Validating Solana AI Kit..."
echo ""

# --- Agent frontmatter ---
echo "[Agents]"
for f in .claude/agents/*.md; do
  name="$(basename "$f")"
  has_name=1; has_desc=1; has_model=1

  # Check for frontmatter block
  if head -1 "$f" | grep -q "^---"; then
    frontmatter="$(awk '/^---$/{c++;next} c==1{print; if(NR>22)exit}' "$f")"
    echo "$frontmatter" | grep -q "^name:" && has_name=0
    echo "$frontmatter" | grep -q "^description:" && has_desc=0
    echo "$frontmatter" | grep -q "^model:" && has_model=0
  fi

  check "$name has name:" $has_name
  check "$name has description:" $has_desc
  check "$name has model:" $has_model
done
echo ""

# --- Command frontmatter ---
echo "[Commands]"
for f in .claude/commands/*.md; do
  name="$(basename "$f")"
  has_desc=1

  if head -1 "$f" | grep -q "^---"; then
    frontmatter="$(awk '/^---$/{c++;next} c==1{print; if(NR>22)exit}' "$f")"
    echo "$frontmatter" | grep -q "^description:" && has_desc=0
  fi

  check "$name has description:" $has_desc
done
echo ""

# --- Skill references ---
echo "[Skills]"
if [ -f .claude/skills/SKILL.md ]; then
  check "SKILL.md exists" 0

  # Extract markdown links and check targets
  broken=0
  while IFS= read -r link; do
    # Remove leading/trailing whitespace
    link="$(echo "$link" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
    [ -z "$link" ] && continue

    target=".claude/skills/$link"
    if [ ! -e "$target" ] && [ ! -d "$target" ]; then
      if in_uninitialized_submodule "$target"; then
        SKIP=$((SKIP + 1))
      else
        echo "  FAIL: Broken link -> $link"
        FAIL=$((FAIL + 1))
        broken=$((broken + 1))
      fi
    fi
  done < <(grep -oE '\]\([^)]+\)' .claude/skills/SKILL.md | sed 's/\](//' | sed 's/)//' | grep -v '^http')

  if [ "$broken" -eq 0 ]; then
    check "All SKILL.md links resolve" 0
  fi
else
  check "SKILL.md exists" 1
fi
echo ""

# --- Submodules ---
echo "[Submodules]"
for dir in .claude/skills/ext/*/; do
  name="$(basename "$dir")"
  if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    echo "  SKIP: ext/$name not initialized (run: git submodule update --init)"
    SKIP=$((SKIP + 1))
  else
    check "ext/$name is initialized (non-empty)" 0
  fi
done
echo ""

# --- Versioning ---
echo "[Versioning]"
if [ -f .claude/VERSION ]; then
  if grep -qE '(^|[[:space:]])[0-9]+\.[0-9]+\.[0-9]+$' .claude/VERSION; then
    check ".claude/VERSION follows semver" 0
  else
    check ".claude/VERSION follows semver" 1
  fi
else
  check ".claude/VERSION file exists" 1
fi

if [ -f .claude/bin/update.sh ] && [ -x .claude/bin/update.sh ]; then
  check "update.sh exists and is executable" 0
else
  check "update.sh exists and is executable" 1
fi

if [ -f .claude/bin/resync.sh ] && [ -x .claude/bin/resync.sh ]; then
  check "resync.sh exists and is executable" 0
else
  check "resync.sh exists and is executable" 1
fi
echo ""

# --- .env.example ---
echo "[Environment]"
if [ -f .env.example ]; then
  check ".env.example exists" 0
else
  check ".env.example exists" 1
fi
echo ""

# --- JSON files ---
echo "[JSON]"
if [ -f .claude/settings.json ]; then
  if python3 -c "import json; json.load(open('.claude/settings.json'))" 2>/dev/null; then
    check "settings.json is valid JSON" 0
  else
    check "settings.json is valid JSON" 1
  fi
else
  check "settings.json exists" 1
fi

if [ -f .mcp.json ]; then
  if python3 -c "import json; json.load(open('.mcp.json'))" 2>/dev/null; then
    check ".mcp.json is valid JSON" 0
  else
    check ".mcp.json is valid JSON" 1
  fi
fi
echo ""

# --- Rules frontmatter ---
echo "[Rules]"
for f in .claude/rules/*.md; do
  name="$(basename "$f")"
  has_globs=1

  if head -1 "$f" | grep -q "^---"; then
    frontmatter="$(awk '/^---$/{c++;next} c==1{print; if(NR>22)exit}' "$f")"
    # Accept either globs: or paths:
    (echo "$frontmatter" | grep -qE "^(globs|paths):") && has_globs=0
  fi

  check "$name has globs/paths in frontmatter" $has_globs
done
echo ""

# --- Summary ---
TOTAL=$((PASS + FAIL))
echo "========================================="
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped (of $((TOTAL + SKIP)) checks)"
if [ "$SKIP" -gt 0 ]; then
  echo "Note: $SKIP checks skipped because submodules aren't initialized."
  echo "      Run 'git submodule update --init --recursive' (or ./install.sh) to check them."
fi
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
