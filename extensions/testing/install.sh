#!/usr/bin/env bash
#
# speckit-ext-testing — installer
# Layers the testing extension onto a repo already initialized with GitHub
# spec-kit (`specify init`): the `complete` phase (/speckit-complete — main
# thread, no new model role) and the doc-only `testing` phase
# (/speckit-testing — a dispatched Sonnet `tester`, separate session). The
# 4th pipeline extension, joining graphify/council/git/workforce (spec
# 004-testing-completion).
#
# Packaging = graphify/council/workforce's own-payload idiom (rm -rf + cp -R
# under .specify/extensions/testing/) + the git-ext/workforce hook-merge
# ladder (PyYAML found directly → `uv run --with pyyaml` → a manual paste
# block), reused verbatim in STRUCTURE even though this extension's OWN
# extension.yml declares zero hooks as of this writing: the complete/testing
# phase-tagged commits are git-ext's OWN after_complete / after_testing
# hooks — owned-source in extensions/git/, never this extension's to declare
# (D57 §9, artifact-layout.md §9). The merge is driven entirely off the
# INSTALLED extension.yml's `hooks:` key (never hardcoded here), so a future
# testing-ext hook registers itself with zero changes to this script. The
# merge body itself carries forward workforce's improved S06 technique (an
# `fcntl.flock` around the whole read-modify-write, plus a tempfile +
# `os.replace` atomic write) rather than git-ext's earlier direct `>` write —
# the more recent, more correct sibling precedent.
#
# Skills live NESTED under extension/skills/ (this feature's own
# council-approved plan.md §1.1 Project Structure — not the top-level
# extensions/<name>/skills/ convention graphify/council/git/workforce use);
# copied to .claude/skills/<name>/ exactly like every sibling.
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

bold "speckit-ext-testing → $TARGET"

# --- preconditions ----------------------------------------------------------
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target. Initialize spec-kit first:
    https://github.com/github/spec-kit  (run: specify init)"
command -v git >/dev/null 2>&1 || die "git not found on PATH (git >= 2.20 required)."
ok "git found ($(git --version 2>/dev/null))"

# Advisory only (never a hard block): the complete/testing phase-tagged
# commits fire from git-ext's OWN after_complete/after_testing hooks, not
# from anything this installer registers — so this extension installs
# cleanly either way, but those commits won't happen until git-ext is also
# installed.
if [ -d "$SPECIFY_DIR/extensions/git" ]; then
  ok "git-ext detected under .specify/extensions/git (complete(<id>)/testing(<id>) commits are wired)"
else
  warn "git-ext not detected under .specify/extensions/git"
  warn "  complete(<id>) / testing(<id>) phase-tagged commits are git-ext's OWN after_complete /"
  warn "  after_testing hooks (owned-source, D57 §9) — install extensions/git first, or continue"
  warn "  now and install it after; this extension works either way."
fi

# --- 1. install the extension payload ---------------------------------------
EXT_DEST="$SPECIFY_DIR/extensions/testing"
mkdir -p "$SPECIFY_DIR/extensions"
rm -rf "$EXT_DEST"
cp -R "$SCRIPT_DIR/extension" "$EXT_DEST"
ok "extension → .specify/extensions/testing/"

# --- 2. install the 2 command skills -----------------------------------------
# Source is extension/skills/ (nested — see header note), NOT a top-level
# extensions/testing/skills/ like graphify/council/git/workforce ship. Same
# rm -rf + cp -R idiom as every sibling's own command-skill install.
SKILLS_DEST="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DEST"
for skill_dir in "$SCRIPT_DIR"/extension/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -R "$skill_dir" "$SKILLS_DEST/$name"
  ok "skill → .claude/skills/$name/"
done

# --- 3. register hooks in .specify/extensions.yml ----------------------------
# See header note: manifest-driven, append-only, idempotent; a no-op on hook
# ROWS today (testing's own extension.yml declares none) but still registers
# `testing` into `installed:` and runs the identical merge every sibling
# runs, so nothing here needs to change the day a testing-ext hook exists.
EXT_YML="$SPECIFY_DIR/extensions.yml"
MANIFEST="$EXT_DEST/extension.yml"

PY_MERGE="$(mktemp)"
trap 'rm -f "$PY_MERGE"' EXIT
cat > "$PY_MERGE" <<'PYEOF'
import sys, os, fcntl, tempfile, yaml

registry_path, manifest_path = sys.argv[1], sys.argv[2]

with open(manifest_path) as fh:
    manifest = yaml.safe_load(fh) or {}
ext_id = manifest.get("extension", {}).get("id", "testing")
manifest_hooks = manifest.get("hooks", {}) or {}
# Whatever extension.yml declares under `hooks:` today, read fresh on every
# run — never assumed. As of this writing that key is empty or absent: the
# complete/testing phase-boundary commits are git-ext's OWN after_complete /
# after_testing hooks (owned-source in extensions/git/, D57 §9). This loop
# only knows how to register whatever IS declared; it never hardcodes one.

def to_registry_row(hook_name, decl):
    # Same row shape every sibling's merge writes (R1-S07 idiom, mirrored):
    # before_* hooks get priority 1 (sort ahead), after_* get priority 5.
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

# S06 (carried from workforce, the more recent/correct sibling precedent):
# lock the whole read-modify-write, and land the write via a tempfile +
# os.replace() so a crash mid-write or a second concurrent installer never
# produces a torn or clobbered registry.
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
    print("registered — extension.yml declares no hooks of its own (complete/testing commits are git-ext's after_complete/after_testing, owned-source)")
PYEOF

shebang_python() {  # resolve the #! interpreter of a CLI on PATH (e.g. graphify, specify)
  command -v "$1" >/dev/null 2>&1 || return 1
  head -n1 "$(command -v "$1")" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}'
}

run_yaml_merge() {  # $1 = registry path, $2 = manifest path
  local py
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
  Register testing by hand — add `testing` to `installed:` in
  .specify/extensions.yml:

    installed:
      - testing

  Then check extensions/testing/extension/extension.yml's `hooks:` key. As of
  this writing it declares none — this extension's complete/testing
  phase-boundary commits are git-ext's OWN after_complete / after_testing
  hooks (owned-source in extensions/git/, D57 §9), already registered if
  git-ext is installed. If a later extension.yml adds a hooks: entry, mirror
  it here using the same row shape as any existing entry in this file
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

# --- done -------------------------------------------------------------------
echo
bold "Done. The testing extension now provides:"
echo "  1. /speckit-complete → reads tasks.md + implement.log.md, writes completion-report.md (main thread, no new model role)"
echo "  2. /speckit-testing  → dispatches one Sonnet tester (separate session), writes testing.md (doc-only, executed: none)"
echo
echo "  Phase-tagged commits (complete(<id>), testing(<id>)) fire from git-ext's own after_complete/after_testing hooks — already wired if git-ext is installed (see warning above otherwise)."
