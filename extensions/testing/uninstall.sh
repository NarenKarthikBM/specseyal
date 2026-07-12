#!/usr/bin/env bash
#
# speckit-ext-testing — uninstaller
# Removes exactly what install.sh added: testing's entry in
# .specify/extensions.yml (`installed:` — plus any hook rows with
# extension: testing, of which there are none as of this writing), the
# payload under .specify/extensions/testing/, and the 2 command skills under
# .claude/skills/ (speckit-complete, speckit-testing). Nothing else — no
# specs/ artifact, no other extension's hooks or payload, and none of
# git-ext's OWN after_complete/after_testing hooks (owned-source there, D57
# §9 — this uninstaller never touches them).
#
# ORDER IS LOAD-BEARING (mirrors git-ext/workforce R1-S26a): hooks are
# DEREGISTERED FIRST. If deregistration fails, this FAILS HARD and leaves the
# payload in place — removing scripts a dangling `optional: false` hook still
# points at would hard-block whatever phase fires it. (No such hook exists
# for testing today, but the code stays generic, so it is still correct the
# day one does.)
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

bold "speckit-ext-testing ✗ $TARGET"

EXT_YML="$SPECIFY_DIR/extensions.yml"
EXT_DEST="$SPECIFY_DIR/extensions/testing"

# --- 1. DEREGISTER FIRST (mirrors git-ext/workforce R1-S26a) ----------------
# Remove `testing` from installed: and every entry with extension==testing
# from each hook list; drop a hook key only if it becomes empty. This MUST
# succeed before any payload is removed.
if [ -f "$EXT_YML" ]; then
  PY_DEREG="$(mktemp)"
  trap 'rm -f "$PY_DEREG"' EXIT
  cat > "$PY_DEREG" <<'PYEOF'
import sys, os, yaml
path = sys.argv[1]
EXT = "testing"
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
            hooks[name] = kept          # every other extension's entries survive
        else:
            del hooks[name]             # a testing-only key disappears cleanly
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
    ok "deregistered testing from .specify/extensions.yml"
  else
    # FAIL HARD — do NOT proceed to payload removal (mirrors R1-S26a). A
    # dangling optional:false hook pointing at deleted scripts would
    # hard-block whatever phase fires it.
    die "Could not deregister testing (no Python with PyYAML, no uv). Payload left INTACT
    to avoid a dangling optional:false hook. Remove testing's entry from .specify/extensions.yml
    by hand (drop 'testing' from installed:, and every {extension: testing, …} hook row, if any),
    then re-run."
  fi
else
  warn "no .specify/extensions.yml — nothing to deregister"
fi

# --- 2. only now remove the payload + the 2 command skills -------------------
if [ -d "$EXT_DEST" ]; then rm -rf "$EXT_DEST"; ok "removed .specify/extensions/testing/"; else warn "payload already absent"; fi

for name in speckit-complete speckit-testing; do
  dest="$TARGET/.claude/skills/$name"
  if [ -d "$dest" ]; then
    rm -rf "$dest"
    ok "removed .claude/skills/$name/"
  else
    warn ".claude/skills/$name/ already absent"
  fi
done

# --- 3. what this uninstaller never touches ----------------------------------
# git-ext's OWN after_complete/after_testing hooks (owned-source in
# extensions/git/, D57 §9) are not this extension's to remove — they stay
# registered (and keep firing on whatever git-ext-owned phases remain) until
# git-ext itself is uninstalled. No specs/ artifact, no other extension's
# hooks or payload, is ever touched here.

echo
bold "Uninstalled. Only testing's registry entry, payload, and 2 command skills were removed — nothing else touched."
