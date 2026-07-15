#!/bin/sh
#
# speckit-ext-deck-render — uninstaller
# Removes exactly what install.sh added: deck-render's entry in
# .specify/extensions.yml (`installed:` — plus any hook rows with
# extension: deck-render, of which there are none by design: extension.yml
# declares ZERO hooks, FR-008/FR-012), the payload under
# .specify/extensions/deck-render/, and the 1 command skill under
# .claude/skills/ (speckit-deck-render). Nothing else — no specs/ artifact,
# no council/ or graphify/ installed tree (FR-012), and no `renders/`
# directory a prior invocation may have left on disk: that is gitignored
# build output, not registry state, and removing the extension does not
# retroactively delete a file a human already generated (FR-014).
#
# ORDER IS LOAD-BEARING (mirrors extensions/testing/uninstall.sh, itself
# following git-ext/workforce R1-S26a): the registry is DEREGISTERED FIRST.
# If deregistration fails, this FAILS HARD and leaves the payload in place —
# removing scripts a dangling `optional: false` hook still points at would
# hard-block whatever phase fires it. (No such hook exists for deck-render —
# its manifest declares zero hooks on purpose — but the code stays generic,
# the same discipline every sibling uninstaller carries, so it is correct
# even if that ever changes.)
#
# The registry edit uses the same flock + tempfile + os.replace atomic
# pattern install.sh's merge uses (never a bare `open(path, "w")`), so an
# install-then-uninstall round-trips .specify/extensions.yml byte-identically
# and a concurrent installer (e.g. 005's own install/uninstall lifecycle)
# never sees a torn or half-written registry file.
#
# Usage:  ./uninstall.sh [TARGET_REPO]      (default: current directory)
#
# POSIX sh — no bash-only constructs (arrays, `local`, [[ ]], BASH_SOURCE).
# This shebang says `/bin/sh` and means it.
#
set -eu

TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

[ -n "$TARGET" ] && [ -d "$TARGET" ] || die "Target repo not found: ${1:-$(pwd)}"
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target."

bold "speckit-ext-deck-render ✗ $TARGET"

EXT_YML="$SPECIFY_DIR/extensions.yml"
EXT_DEST="$SPECIFY_DIR/extensions/deck-render"

# --- 1. DEREGISTER FIRST (mirrors testing/uninstall.sh, git-ext/workforce
# R1-S26a) -------------------------------------------------------------------
# Remove `deck-render` from installed: and every entry with
# extension==deck-render from each hook list; drop a hook key only if it
# becomes empty. This MUST succeed before any payload is removed. The edit
# itself is locked (fcntl.flock) and landed via tempfile + os.replace — the
# same atomic technique install.sh's merge uses — never a direct in-place
# write, so a crash mid-write or a second concurrent (un)installer can never
# produce a torn or clobbered registry, and repeated runs converge to one
# clean, byte-identical state.
if [ -f "$EXT_YML" ]; then
  PY_DEREG="$(mktemp)"
  trap 'rm -f "$PY_DEREG"' EXIT
  cat > "$PY_DEREG" <<'PYEOF'
import sys, os, fcntl, tempfile, yaml

registry_path = sys.argv[1]
EXT = "deck-render"

if not os.path.exists(registry_path):
    sys.exit(0)

lock_path = registry_path + ".lock"
lockfh = open(lock_path, "a+")
fcntl.flock(lockfh, fcntl.LOCK_EX)
try:
    with open(registry_path) as fh:
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
                del hooks[name]             # a deck-render-only key disappears cleanly

    reg_dir = os.path.dirname(os.path.abspath(registry_path)) or "."
    fd, tmp_path = tempfile.mkstemp(prefix=".extensions.yml.", dir=reg_dir)
    try:
        with os.fdopen(fd, "w") as fh:
            yaml.safe_dump(data, fh, default_flow_style=False, sort_keys=False)
        os.replace(tmp_path, registry_path)
    except BaseException:
        os.unlink(tmp_path)
        raise
finally:
    fcntl.flock(lockfh, fcntl.LOCK_UN)
    lockfh.close()

print("deregistered")
PYEOF

  shebang_python() {  # resolve the #! interpreter of a CLI on PATH (e.g. graphify, specify)
    command -v "$1" >/dev/null 2>&1 || return 1
    head -n1 "$(command -v "$1")" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}'
  }

  run_dereg() {  # $1 = registry path
    for candidate in "$(shebang_python graphify)" "$(shebang_python specify)" python3 python; do
      [ -n "$candidate" ] || continue
      if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import yaml, fcntl' >/dev/null 2>&1; then
        "$candidate" "$PY_DEREG" "$1" && return 0
      fi
    done
    command -v uv >/dev/null 2>&1 && uv run --quiet --with pyyaml python "$PY_DEREG" "$1" && return 0
    return 70
  }

  set +e
  run_dereg "$EXT_YML" >/dev/null 2>&1
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    ok "deregistered deck-render from .specify/extensions.yml"
  else
    # FAIL HARD — do NOT proceed to payload removal (mirrors testing/
    # uninstall.sh, R1-S26a). A dangling optional:false hook pointing at
    # deleted scripts would hard-block whatever phase fires it.
    die "Could not deregister deck-render (no Python with PyYAML, no uv). Payload left INTACT
    to avoid a dangling optional:false hook. Remove deck-render's entry from .specify/extensions.yml
    by hand (drop 'deck-render' from installed:, and every {extension: deck-render, …} hook row, if any),
    then re-run."
  fi
else
  warn "no .specify/extensions.yml — nothing to deregister"
fi

# --- 2. only now remove the payload + the 1 command skill --------------------
if [ -d "$EXT_DEST" ]; then rm -rf "$EXT_DEST"; ok "removed .specify/extensions/deck-render/"; else warn "payload already absent"; fi

SKILL_DEST="$TARGET/.claude/skills/speckit-deck-render"
if [ -d "$SKILL_DEST" ]; then
  rm -rf "$SKILL_DEST"
  ok "removed .claude/skills/speckit-deck-render/"
else
  warn ".claude/skills/speckit-deck-render/ already absent"
fi

# --- 3. what this uninstaller never touches ----------------------------------
# council/ and graphify/'s installed trees are never this extension's to
# remove (FR-012) — deck-render never wrote there and never will. Neither is
# any specs/ artifact, any other extension's hooks or payload, nor a
# `renders/*.pptx` a prior run may have left on disk: that path is gitignored
# build output regenerable from the markdown at any time (FR-014), not
# registry state, so uninstalling the command that produces it never deletes
# a file a human already generated.

echo
bold "Uninstalled. Only deck-render's registry entry, payload, and 1 command skill were removed — nothing else touched."
