#!/bin/sh
#
# speckit-ext-deck-render — installer
# Layers the optional council-defense-deck-to-pptx renderer onto a repo already
# initialized with GitHub spec-kit (`specify init`). Installs the extension
# payload and the /speckit-deck-render skill; registers `deck-render` in
# .specify/extensions.yml's `installed:` list. Never invokes a model, never
# requires `python-pptx` (FR-015 — the toolchain is imported lazily, inside
# render.py, at render time; install/uninstall never touch it).
#
# POSIX `sh` throughout (plan.md Technical Context: "POSIX sh for
# install/uninstall/test" — this feature's own choice, distinct from the
# `#!/usr/bin/env bash` every sibling extension's installer uses). No
# bash-isms: no BASH_SOURCE (uses `$0` instead), no `local`, no `[[ ]]`, no
# `pipefail` (not POSIX — nothing here pipes a command whose mid-pipe exit
# status matters, so plain `set -eu` is sufficient).
#
# Skills live at the TOP level (extensions/deck-render/skills/) — the
# graphify/council/git/workforce convention — NOT nested under
# extension/skills/ the way extensions/testing/ ships them.
#
# Registry merge: this extension declares ZERO hooks (FR-008/FR-012 — there
# is no seam inside the council or graphify trees this extension may attach
# to; see README "The zero-hook seam"). The `installed:` list is still a
# shared-mutation point every extension's installer merges into concurrently,
# so this step copies extensions/testing/install.sh's locked, atomic merge —
# `fcntl.flock` around the whole read-modify-write, plus a tempfile +
# `os.replace()` write — verbatim in shape, NOT extensions/git/install.sh's
# earlier unlocked `>` write. The merge stays driven off the INSTALLED
# extension.yml's `hooks:` key (never hardcoded here) purely so the shape
# matches every sibling exactly; today that key is empty by design and stays
# that way permanently for this extension.
#
# Idempotent / reinstall-safe: payload and skill are `rm -rf` + `cp -R`
# (replace, not append); the registry merge only appends `deck-render` to
# `installed:` if it is not already present. Running this script twice in a
# row converges to the same state as running it once.
#
# Usage:  ./install.sh [TARGET_REPO]      (default: current directory)
#
set -eu

# --- locate ourselves & the target -----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m*\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '\033[31mx %s\033[0m\n' "$1" >&2; exit 1; }

[ -n "$TARGET" ] && [ -d "$TARGET" ] || die "Target repo not found: ${1:-$(pwd)}"

bold "speckit-ext-deck-render -> $TARGET"

# --- preconditions ------------------------------------------------------------
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target. Initialize spec-kit first:
    https://github.com/github/spec-kit  (run: specify init)"

# No install-order dependency on council, graphify, git, workforce, or any
# other extension (README "Install"): deck-render reads council's markdown
# output at RENDER time, never at install time, and its own installer writes
# nothing any other extension's installer touches. No presentation toolchain
# (python-pptx) is required or checked here either (FR-015) — a host with it
# and a host without it install identically.

# --- 1. install the extension payload ----------------------------------------
EXT_DEST="$SPECIFY_DIR/extensions/deck-render"
mkdir -p "$SPECIFY_DIR/extensions"
rm -rf "$EXT_DEST"
cp -R "$SCRIPT_DIR/extension" "$EXT_DEST"
ok "extension -> .specify/extensions/deck-render/"

# --- 2. install the speckit-deck-render skill --------------------------------
# Source is the top-level skills/ dir (see header note), not a nested
# extension/skills/. Same rm -rf + cp -R replace idiom every sibling uses.
SKILLS_DEST="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DEST"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -R "$skill_dir" "$SKILLS_DEST/$name"
  ok "skill -> .claude/skills/$name/"
done

# --- 3. register deck-render in .specify/extensions.yml -----------------------
# See header note: manifest-driven, append-only, idempotent; a no-op on hook
# ROWS (deck-render's own extension.yml declares none, permanently, by
# design — FR-008/FR-012) but still registers `deck-render` into `installed:`
# and runs the identical locked, atomic merge every sibling runs.
EXT_YML="$SPECIFY_DIR/extensions.yml"
MANIFEST="$EXT_DEST/extension.yml"

PY_MERGE="$(mktemp)"
trap 'rm -f "$PY_MERGE"' EXIT
cat > "$PY_MERGE" <<'PYEOF'
import sys, os, fcntl, tempfile, yaml

registry_path, manifest_path = sys.argv[1], sys.argv[2]

with open(manifest_path) as fh:
    manifest = yaml.safe_load(fh) or {}
ext_id = manifest.get("extension", {}).get("id", "deck-render")
manifest_hooks = manifest.get("hooks", {}) or {}
# Whatever extension.yml declares under `hooks:` is read fresh on every run —
# never assumed. deck-render's own extension.yml declares none, by design,
# permanently (FR-008/FR-012: there is no seam inside the council or
# graphify trees this extension may attach to). This loop only knows how to
# register whatever IS declared; it never hardcodes one, purely to keep this
# merge's shape identical to every sibling's.

def to_registry_row(hook_name, decl):
    # Same row shape every sibling's merge writes: before_* hooks get
    # priority 1 (sort ahead), after_* get priority 5.
    priority = 1 if hook_name.startswith("before_") else 5
    row = {
        "extension": ext_id,
        "command": decl["command"],
        "enabled": True,
        "optional": decl.get("optional", False),
        "priority": priority,
        "prompt": None,   # optional:false hooks are auto-invoked, not prompted
        "description": decl.get("description", ""),
        "condition": None,
    }
    if "phase" in decl:
        row["phase"] = decl["phase"]
    if "gate" in decl:
        row["gate"] = decl["gate"]
    return row

# Lock the whole read-modify-write, and land the write via a tempfile +
# os.replace() so a crash mid-write or a second concurrent installer never
# produces a torn or clobbered registry (extensions/testing/install.sh's
# model — not extensions/git/install.sh's earlier unlocked `>` write).
lock_path = registry_path + ".lock"
lockfh = open(lock_path, "a+")
fcntl.flock(lockfh, fcntl.LOCK_EX)
try:
    data = {}
    if os.path.exists(registry_path):
        with open(registry_path) as fh:
            data = yaml.safe_load(fh) or {}

    data.setdefault("installed", [])
    if ext_id not in data["installed"]:
        data["installed"].append(ext_id)
    data.setdefault("settings", {}).setdefault("auto_execute_hooks", True)
    hooks = data.setdefault("hooks", {})

    for hook_name, decl in manifest_hooks.items():
        entries = hooks.get(hook_name) or []
        if not isinstance(entries, list):
            entries = []
        row = to_registry_row(hook_name, decl)
        already = any(
            isinstance(e, dict)
            and e.get("extension") == ext_id
            and e.get("command") == row["command"]
            for e in entries
        )
        if not already:
            entries.append(row)          # append-only: every other extension's rows untouched
        entries.sort(key=lambda e: e.get("priority", 5) if isinstance(e, dict) else 5)
        hooks[hook_name] = entries

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

if manifest_hooks:
    print("registered hooks: " + ", ".join(sorted(manifest_hooks.keys())))
else:
    print("registered — extension.yml declares no hooks of its own (deck-render is a zero-hook, on-demand command extension by design, FR-008/FR-012)")
PYEOF

shebang_python() {  # resolve the #! interpreter of a CLI on PATH (e.g. graphify, specify)
  command -v "$1" >/dev/null 2>&1 || return 1
  head -n1 "$(command -v "$1")" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}'
}

run_yaml_merge() {  # $1 = registry path, $2 = manifest path
  for py in "$(shebang_python graphify)" "$(shebang_python specify)" python3 python; do
    [ -n "$py" ] || continue
    if command -v "$py" >/dev/null 2>&1 && "$py" -c 'import yaml, fcntl' >/dev/null 2>&1; then
      "$py" "$PY_MERGE" "$1" "$2" && return 0
    fi
  done
  if command -v uv >/dev/null 2>&1; then
    uv run --quiet --with pyyaml python "$PY_MERGE" "$1" "$2" && return 0
  fi
  return 70
}

print_manual_block() {
  cat <<'MANUAL'

  Could not find a Python with PyYAML (and no `uv` to borrow one).
  Register deck-render by hand — add `deck-render` to `installed:` in
  .specify/extensions.yml:

    installed:
      - deck-render

  No hooks: entry is needed. deck-render's extension.yml declares no hooks
  by design (FR-008/FR-012) — the render command is triggered on demand,
  never from a pipeline seam. If a later extension.yml ever adds a hooks:
  entry (it should not — see README), mirror it here using the same row
  shape as any existing entry in this file
  (extension/command/enabled/optional/priority/prompt/description/condition,
  plus phase: or gate: if the hook declares one) — append to any existing
  list for that key, never remove or reorder another extension's rows.
MANUAL
}

set +e
out="$(run_yaml_merge "$EXT_YML" "$MANIFEST" 2>/dev/null)"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  ok "$out"
else
  warn "automatic registration skipped"
  print_manual_block
fi

# --- done ----------------------------------------------------------------------
echo
bold "Done. The deck-render extension now provides:"
echo "  /speckit-deck-render [technical|overview|both] [--feature <dir>] [--validate-profile]"
echo "    Renders the selected defense deck(s) to specs/NNN-feature/renders/*.pptx (gitignored)."
echo "    Zero hooks, zero model calls, zero trace records (FR-008/FR-011/FR-012)."
echo "    python-pptx is optional and lazily imported at render time (FR-015) — this installer"
echo "    never checked for it and never required it."
