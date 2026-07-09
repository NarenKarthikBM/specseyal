#!/usr/bin/env bash
#
# speckit-ext-git — uninstaller
# Removes exactly what install.sh added: git's hook entries in .specify/extensions.yml, the
# payload under .specify/extensions/git/, and the /speckit-git-cleanup skill. Nothing else —
# no specs/ artifact, no other extension's hooks, no branch or tag (FR-014).
#
# ORDER IS LOAD-BEARING (R1-S26a / Risk R4): hooks are DEREGISTERED FIRST. If deregistration
# fails, we FAIL HARD and leave the payload in place — removing the scripts while a dangling
# `optional: false` git hook still points at them would hard-block every /speckit-* phase.
#
# Usage:  ./uninstall.sh [TARGET_REPO]      (default: current directory)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

[ -n "$TARGET" ] && [ -d "$TARGET" ] || die "Target repo not found: ${1:-$(pwd)}"
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target."

bold "speckit-ext-git ✗ $TARGET"

EXT_YML="$SPECIFY_DIR/extensions.yml"
EXT_DEST="$SPECIFY_DIR/extensions/git"
SKILL_DEST="$TARGET/.claude/skills/speckit-git-cleanup"

# --- 1. DEREGISTER HOOKS FIRST (R1-S26a) ------------------------------------
# Remove `git` from installed and every entry with extension==git from each hook list; drop a
# hook key only if it becomes empty (before_tasks/before_implement keep graphify's row). This
# MUST succeed before any payload is removed.
if [ -f "$EXT_YML" ]; then
  PY_DEREG="$(mktemp)"
  trap 'rm -f "$PY_DEREG"' EXIT
  cat > "$PY_DEREG" <<'PYEOF'
import sys, os, yaml
path = sys.argv[1]
EXT = "git"
if not os.path.exists(path):
    sys.exit(0)
with open(path) as fh:
    data = yaml.safe_load(fh) or {}
if isinstance(data.get("installed"), list) and EXT in data["installed"]:
    data["installed"].remove(EXT)
hooks = data.get("hooks", {}) or {}
for name in list(hooks.keys()):
    entries = hooks.get(name) or []
    if isinstance(entries, list):
        kept = [e for e in entries if not (isinstance(e, dict) and e.get("extension") == EXT)]
        if kept:
            hooks[name] = kept          # graphify (or others) survive
        else:
            del hooks[name]             # git-only key disappears cleanly
with open(path, "w") as fh:
    yaml.safe_dump(data, fh, default_flow_style=False, sort_keys=False)
print("deregistered")
PYEOF

  shebang_python() { command -v "$1" >/dev/null 2>&1 || return 1; head -n1 "$(command -v "$1")" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}'; }
  run_dereg() {
    local py
    for py in "$(shebang_python graphify)" "$(shebang_python specify)" python3 python; do
      [ -n "$py" ] || continue
      if command -v "$py" >/dev/null 2>&1 && "$py" -c 'import yaml' >/dev/null 2>&1; then
        "$py" "$PY_DEREG" "$1" && return 0
      fi
    done
    command -v uv >/dev/null 2>&1 && uv run --quiet --with pyyaml python "$PY_DEREG" "$1" && return 0
    return 70
  }

  set +e; run_dereg "$EXT_YML" >/dev/null 2>&1; rc=$?; set -e
  if [ "$rc" -eq 0 ]; then
    ok "deregistered git hooks from .specify/extensions.yml"
  else
    # FAIL HARD — do NOT proceed to payload removal (R1-S26a). A dangling optional:false hook
    # pointing at deleted scripts would hard-block every phase.
    die "Could not deregister git hooks (no Python with PyYAML, no uv). Payload left INTACT to
    avoid a dangling optional:false hook. Remove git's entries from .specify/extensions.yml by
    hand (drop 'git' from installed:, and every {extension: git, …} hook row), then re-run."
  fi
else
  warn "no .specify/extensions.yml — nothing to deregister"
fi

# --- 2. only now remove the payload + skill ---------------------------------
if [ -d "$EXT_DEST" ]; then rm -rf "$EXT_DEST"; ok "removed .specify/extensions/git/"; else warn "payload already absent"; fi
if [ -d "$SKILL_DEST" ]; then rm -rf "$SKILL_DEST"; ok "removed .claude/skills/speckit-git-cleanup/"; else warn "skill already absent"; fi

echo
bold "Uninstalled. Only git's hooks, payload, and skill were removed — nothing else touched."
