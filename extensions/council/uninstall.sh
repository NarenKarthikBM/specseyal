#!/usr/bin/env bash
#
# speckit-ext-council — uninstaller
# Removes the council extension and its 3 companion skills. Stock spec-kit is
# left untouched.
#
# Usage:  ./uninstall.sh [TARGET_REPO]     (default: current directory)
#
set -euo pipefail

TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

[ -n "$TARGET" ] && [ -d "$TARGET" ] || die "Target repo not found: ${1:-$(pwd)}"

bold "speckit-ext-council uninstall → $TARGET"

# 1. extension
rm -rf "$TARGET/.specify/extensions/council"
ok "removed .specify/extensions/council/"

# 2. skills
for name in speckit-council speckit-council-triage speckit-council-approve; do
  if [ -d "$TARGET/.claude/skills/$name" ]; then
    rm -rf "$TARGET/.claude/skills/$name"
    ok "removed .claude/skills/$name/"
  fi
done

# No hooks were registered at install time (command-invoked extension), so
# there is nothing to de-register from .specify/extensions.yml.
echo
bold "Done."
