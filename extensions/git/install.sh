#!/usr/bin/env bash
#
# speckit-ext-git — installer
# Layers the per-feature git-lifecycle extension + the /speckit-git-cleanup skill onto a
# repo already initialized with GitHub spec-kit (`specify init`). Mechanical git, zero AI.
#
# Packaging = council's (payload + skills copy) PLUS graphify's hook-merge variant, but with
# git's richer registry merge: 9 hooks across 3 shapes — 7 new keys (after_specify/clarify/
# plan/analyze/tasks/implement + after_council_approve) and 2 APPEND targets (before_tasks/
# before_implement) where git's verify-gate MUST run AHEAD of graphify (R1-S07). Ordering is
# implemented by sorting each hook list on `priority` (verify-gate=1 < graphify=5), so the
# `priority` field is LIVE, not a zombie schema (R1-S07). Append-only: graphify's entries are
# never overwritten. Idempotent. The hook set is READ from git's own extension.yml manifest
# (single source of truth), never hardcoded here.
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

bold "speckit-ext-git → $TARGET"

# --- preconditions ----------------------------------------------------------
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target. Initialize spec-kit first:
    https://github.com/github/spec-kit  (run: specify init)"
command -v git >/dev/null 2>&1 || die "git not found on PATH (git >= 2.20 required)."
ok "git found ($(git --version 2>/dev/null))"

# --- 1. install the extension payload ---------------------------------------
EXT_DEST="$SPECIFY_DIR/extensions/git"
mkdir -p "$SPECIFY_DIR/extensions"
rm -rf "$EXT_DEST"
cp -R "$SCRIPT_DIR/extension" "$EXT_DEST"
ok "extension → .specify/extensions/git/"

# --- 2. install the human skill ---------------------------------------------
SKILLS_DEST="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DEST"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -R "$skill_dir" "$SKILLS_DEST/$name"
  ok "skill → .claude/skills/$name/"
done

# --- 3. register hooks in .specify/extensions.yml ---------------------------
# Idempotent YAML merge. Reads git's hook set from the installed manifest (extension.yml),
# transforms each into a registry row, merges append-only into the target registry, and sorts
# each touched hook list by `priority` so verify-gate (1) precedes graphify (5) — R1-S07.
# PyYAML required; we search the interpreters most likely to have it, then fall back to
# `uv run --with pyyaml`, then a hand-merge paste block. (Mirrors graphify's fallback ladder.)
EXT_YML="$SPECIFY_DIR/extensions.yml"
MANIFEST="$EXT_DEST/extension.yml"

PY_MERGE="$(mktemp)"
trap 'rm -f "$PY_MERGE"' EXIT
cat > "$PY_MERGE" <<'PYEOF'
import sys, os, yaml

registry_path, manifest_path = sys.argv[1], sys.argv[2]

with open(manifest_path) as fh:
    manifest = yaml.safe_load(fh) or {}
ext_id = manifest.get("extension", {}).get("id", "git")
manifest_hooks = manifest.get("hooks", {}) or {}

data = {}
if os.path.exists(registry_path):
    with open(registry_path) as fh:
        data = yaml.safe_load(fh) or {}

data.setdefault("installed", [])
if ext_id not in data["installed"]:
    data["installed"].append(ext_id)
data.setdefault("settings", {}).setdefault("auto_execute_hooks", True)
hooks = data.setdefault("hooks", {})

def to_registry_row(hook_name, decl):
    # R1-S07: verify-gate (the before_* hard-block) must precede graphify's context hook, so
    # give every before_* hook priority 1 and everything else 5; the sort below makes it live.
    priority = 1 if hook_name.startswith("before_") else 5
    row = {
        "extension": ext_id,
        "command": decl["command"],
        "enabled": True,
        "optional": decl.get("optional", False),  # R1-S01: git hooks are optional:false
        "priority": priority,
        "prompt": None,   # optional:false hooks are auto-invoked, not prompted
        "description": decl.get("description", ""),
        "condition": None,
    }
    # carry git's live phase:/gate: metadata (the argument the primitive needs) into the row
    if "phase" in decl:
        row["phase"] = decl["phase"]
    if "gate" in decl:
        row["gate"] = decl["gate"]
    return row

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
        entries.append(row)                       # append-only: graphify's rows untouched
    # sort by priority ascending so verify-gate(1) precedes graphify(5) — R1-S07, stable
    entries.sort(key=lambda e: e.get("priority", 5) if isinstance(e, dict) else 5)
    hooks[hook_name] = entries

with open(registry_path, "w") as fh:
    yaml.safe_dump(data, fh, default_flow_style=False, sort_keys=False)
print("registered")
PYEOF

shebang_python() {  # resolve the #! interpreter of a CLI on PATH (e.g. graphify, specify)
  command -v "$1" >/dev/null 2>&1 || return 1
  head -n1 "$(command -v "$1")" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}'
}

run_yaml_merge() {  # $1 = registry path, $2 = manifest path
  local py
  for py in "$(shebang_python graphify)" "$(shebang_python specify)" python3 python; do
    [ -n "$py" ] || continue
    if command -v "$py" >/dev/null 2>&1 && "$py" -c 'import yaml' >/dev/null 2>&1; then
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
  Merge git's hooks into .specify/extensions.yml by hand — add `git` to `installed:`, and
  under `hooks:` add each entry below. On before_tasks / before_implement, git's verify-gate
  row must come BEFORE graphify's context row (priority 1 < 5):

    installed:
      - git
    hooks:
      after_specify:   [ {extension: git, command: speckit.git.commit,      optional: false, phase: spec,    priority: 5} ]
      after_clarify:   [ {extension: git, command: speckit.git.commit,      optional: false, phase: spec,    priority: 5} ]
      after_plan:      [ {extension: git, command: speckit.git.commit,      optional: false, phase: plan,    priority: 5} ]
      after_analyze:   [ {extension: git, command: speckit.git.commit,      optional: false, phase: analyze, priority: 5} ]
      after_tasks:     [ {extension: git, command: speckit.git.commit,      optional: false, phase: tasks,   priority: 5} ]
      after_implement: [ {extension: git, command: speckit.git.commit,      optional: false, phase: impl,    priority: 5} ]
      after_council_approve: [ {extension: git, command: speckit.git.record-gate, optional: false, gate: council, priority: 5} ]
      before_tasks:     # verify-gate FIRST (priority 1), then graphify's existing row (priority 5)
        - {extension: git, command: speckit.git.verify-gate, optional: false, gate: council,   priority: 1}
      before_implement:
        - {extension: git, command: speckit.git.verify-gate, optional: false, gate: workforce, priority: 1}
MANUAL
}

set +e
out="$(run_yaml_merge "$EXT_YML" "$MANIFEST" 2>/dev/null)"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  ok "registered hooks in .specify/extensions.yml (verify-gate ordered ahead of graphify)"
else
  warn "automatic registration skipped"
  print_manual_block
fi

# --- done -------------------------------------------------------------------
echo
bold "Done. The git lifecycle now runs itself:"
echo "  • /speckit-specify → auto-branch <spec-id> + spec(<id>) commit"
echo "  • every phase boundary → a phase-tagged commit"
echo "  • council / workforce gates → SHA-bound; a stale approval hard-blocks"
echo "  • /speckit-git-cleanup → integrate + tag complete/<spec-id> + retire the branch"
