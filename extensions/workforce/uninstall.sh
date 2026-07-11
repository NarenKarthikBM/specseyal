#!/usr/bin/env bash
#
# speckit-ext-workforce — uninstaller
# Removes exactly what install.sh added: workforce's hook entries in
# .specify/extensions.yml (after_categorize, after_agent-assign), the payload
# under .specify/extensions/workforce/, and the 3 command skills under
# .claude/skills/ (speckit-categorize, speckit-agent-assign,
# speckit-workforce-approve). Nothing else.
#
# ORDER IS LOAD-BEARING (mirrors git-ext R1-S26a / Risk R4): hooks are
# DEREGISTERED FIRST. If deregistration fails, we FAIL HARD and leave the
# payload in place — removing the scripts while a dangling `optional: false`
# after_categorize/after_agent-assign hook still points at them would
# hard-block the categorize/agent-assign phases' commit step (R7/D57 S1).
#
# CRITICAL — the seed library survives uninstall (S07 / D17 / D24). install.sh
# seeds .claude/agents/ (7 base specialists) and .claude/skills/ (5 seed
# skills, incl. refactor-discipline) ADDITIVELY, and any skill-builder run
# persists generated SKILL.md files into that same .claude/skills/ tree. That
# whole tree is user/flywheel data, living OUTSIDE this extension's rm -rf
# payload — not extension payload we own. So this script NEVER rm -rf's
# .claude/agents/ or .claude/skills/ as a whole; it removes only the 3 named
# command-skill directories below, by exact name, leaving every seed and
# generated skill (and all of .claude/agents/) untouched. See "step 3" below.
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

bold "speckit-ext-workforce ✗ $TARGET"

EXT_YML="$SPECIFY_DIR/extensions.yml"
EXT_DEST="$SPECIFY_DIR/extensions/workforce"

# --- 1. DEREGISTER HOOKS FIRST (mirrors git-ext R1-S26a) --------------------
# Remove `workforce` from installed: and every entry with extension==workforce
# from each hook list (after_categorize, after_agent-assign — R7/D57 S1);
# drop a hook key only if it becomes empty. NOTE: after_workforce_approve is
# deliberately NOT touched by this — it is registered under git-ext's OWN
# extension.yml (extension: git, via on-gate-approve.sh, D57 S2/R8), not
# workforce's, so the extension==workforce filter naturally leaves it (and
# every other extension's entries, e.g. graphify's) alone. This step MUST
# succeed before any payload is removed.
if [ -f "$EXT_YML" ]; then
  PY_DEREG="$(mktemp)"
  trap 'rm -f "$PY_DEREG"' EXIT
  cat > "$PY_DEREG" <<'PYEOF'
import sys, os, yaml
path = sys.argv[1]
EXT = "workforce"
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
            hooks[name] = kept          # other extensions' entries survive
        else:
            del hooks[name]             # workforce-only key disappears cleanly
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
    ok "deregistered workforce hooks (after_categorize, after_agent-assign) from .specify/extensions.yml"
  else
    # FAIL HARD — do NOT proceed to payload removal (mirrors R1-S26a). A
    # dangling optional:false hook pointing at deleted scripts would
    # hard-block the categorize/agent-assign phases.
    die "Could not deregister workforce hooks (no Python with PyYAML, no uv). Payload left INTACT
    to avoid a dangling optional:false hook. Remove workforce's entries from .specify/extensions.yml
    by hand (drop 'workforce' from installed:, and every {extension: workforce, …} hook row), then
    re-run."
  fi
else
  warn "no .specify/extensions.yml — nothing to deregister"
fi

# --- 2. only now remove the payload + the 3 command skills ------------------
if [ -d "$EXT_DEST" ]; then rm -rf "$EXT_DEST"; ok "removed .specify/extensions/workforce/"; else warn "payload already absent"; fi

for name in speckit-categorize speckit-agent-assign speckit-workforce-approve; do
  dest="$TARGET/.claude/skills/$name"
  if [ -d "$dest" ]; then
    rm -rf "$dest"
    ok "removed .claude/skills/$name/"
  else
    warn ".claude/skills/$name/ already absent"
  fi
done

# --- 3. the seed library + any generated skills are NEVER touched (S07) -----
# .claude/agents/ (7 base specialists) and the rest of .claude/skills/ (5 seed
# skills incl. refactor-discipline, plus any skill-builder-generated
# `origin: generated` SKILL.md) are user/flywheel data (D17/D24) that
# install.sh seeded ADDITIVELY, outside this extension's rm -rf payload. No
# step above removes those directories or their contents — only the 3 named
# command-skill dirs above are ever unlinked, by exact name.
ok "left .claude/agents/ and the seed/generated skills in .claude/skills/ untouched (S07)"

echo
bold "Uninstalled. Only workforce's hooks, payload, and 3 command skills were removed — the seed library survives (S07)."
