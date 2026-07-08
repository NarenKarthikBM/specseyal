#!/usr/bin/env bash
#
# speckit-ext-council — installer
# Layers the plan-defense council extension + 3 companion Claude skills onto a
# repo that has already been initialized with GitHub spec-kit (`specify init`).
#
# Usage:  ./install.sh [TARGET_REPO]      (default: current directory)
#
set -euo pipefail

# --- locate ourselves & the target -----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

[ -n "$TARGET" ] && [ -d "$TARGET" ] || die "Target repo not found: ${1:-$(pwd)}"

bold "speckit-ext-council → $TARGET"

# --- preconditions ----------------------------------------------------------
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target. Initialize spec-kit first:
    https://github.com/github/spec-kit  (run: specify init)"

# --- 1. install the extension ----------------------------------------------
EXT_DEST="$SPECIFY_DIR/extensions/council"
mkdir -p "$SPECIFY_DIR/extensions"
rm -rf "$EXT_DEST"
cp -R "$SCRIPT_DIR/extension" "$EXT_DEST"
ok "extension → .specify/extensions/council/"

# --- 2. install the companion skills ---------------------------------------
SKILLS_DEST="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DEST"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -R "$skill_dir" "$SKILLS_DEST/$name"
  ok "skill → .claude/skills/$name/"
done

# --- done -------------------------------------------------------------------
# No before_* hooks to register: the council is command-invoked, not a
# pipeline hook, so there is nothing to merge into .specify/extensions.yml.
echo
bold "Done. Next:"
echo "  1. Spec it → plan it:       /speckit-specify  →  /speckit-plan"
echo "  2. Convene the council:     /speckit-council"
echo "  3. Triage the suggestions:  /speckit-council-triage"
echo "  4. Gate it (human):         /speckit-council-approve"
