#!/usr/bin/env bash
#
# speckit-graphifyy — installer
# Layers the graphify grounding extension + 3 companion Claude skills onto a
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

bold "speckit-graphifyy → $TARGET"

# --- preconditions ----------------------------------------------------------
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target. Initialize spec-kit first:
    https://github.com/github/spec-kit  (run: specify init)"

if command -v graphify >/dev/null 2>&1; then
  ok "graphify CLI found ($(command -v graphify))"
else
  warn "graphify CLI not found. Install it before using the graph-aware skills:"
  warn "    pip install graphifyy   # then build a graph with /graphify"
fi

# --- 1. install the extension ----------------------------------------------
EXT_DEST="$SPECIFY_DIR/extensions/graphify"
mkdir -p "$SPECIFY_DIR/extensions"
rm -rf "$EXT_DEST"
cp -R "$SCRIPT_DIR/extension" "$EXT_DEST"
ok "extension → .specify/extensions/graphify/"

# --- 2. install the companion skills ---------------------------------------
SKILLS_DEST="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DEST"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -R "$skill_dir" "$SKILLS_DEST/$name"
  ok "skill → .claude/skills/$name/"
done

# --- 3. register hooks in .specify/extensions.yml --------------------------
# Idempotent YAML merge. PyYAML is required; we search the interpreters most
# likely to have it (graphify's, specify's, then system python), and finally
# fall back to `uv run --with pyyaml`. If none works, we print a paste block.
EXT_YML="$SPECIFY_DIR/extensions.yml"

PY_MERGE="$(mktemp)"
trap 'rm -f "$PY_MERGE"' EXIT
cat > "$PY_MERGE" <<'PYEOF'
import sys, os, yaml

path = sys.argv[1]
data = {}
if os.path.exists(path):
    with open(path) as fh:
        data = yaml.safe_load(fh) or {}

data.setdefault("installed", [])
if "graphify" not in data["installed"]:
    data["installed"].append("graphify")

data.setdefault("settings", {}).setdefault("auto_execute_hooks", True)
hooks = data.setdefault("hooks", {})

HOOKS = {
    "before_plan": ("Generate graphify codebase context before planning?",
                    "Ground the plan in the existing dependency graph"),
    "before_tasks": ("Generate graphify codebase context before task generation?",
                     "Verify task parallelism against real dependency edges"),
    "before_implement": ("Generate graphify codebase context before implementation?",
                         "Pre-resolve per-task blast radius before parallel execution"),
}

for hook, (prompt, desc) in HOOKS.items():
    entries = hooks.get(hook) or []
    if not isinstance(entries, list):
        entries = []
    already = any(
        isinstance(e, dict)
        and e.get("extension") == "graphify"
        and e.get("command") == "speckit.graphify.context"
        for e in entries
    )
    if not already:
        entries.append({
            "extension": "graphify",
            "command": "speckit.graphify.context",
            "enabled": True,
            "optional": True,
            "priority": 5,
            "prompt": prompt,
            "description": desc,
            "condition": None,
        })
    hooks[hook] = entries

with open(path, "w") as fh:
    yaml.safe_dump(data, fh, default_flow_style=False, sort_keys=False)
print("registered")
PYEOF

# Resolve the #! interpreter of a CLI on PATH (e.g. graphify, specify).
shebang_python() {
  command -v "$1" >/dev/null 2>&1 || return 1
  head -n1 "$(command -v "$1")" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}'
}

run_yaml_merge() {  # $1 = yaml path → runs $PY_MERGE with a yaml-capable runner
  local py
  for py in "$(shebang_python graphify)" "$(shebang_python specify)" python3 python; do
    [ -n "$py" ] || continue
    if command -v "$py" >/dev/null 2>&1 && "$py" -c 'import yaml' >/dev/null 2>&1; then
      "$py" "$PY_MERGE" "$1" && return 0
    fi
  done
  if command -v uv >/dev/null 2>&1; then
    uv run --quiet --with pyyaml python "$PY_MERGE" "$1" && return 0
  fi
  return 70
}

print_manual_block() {
  cat <<'MANUAL'

  Could not find a Python with PyYAML (and no `uv` to borrow one).
  Merge this into .specify/extensions.yml by hand:

    installed:
      - graphify
    settings:
      auto_execute_hooks: true
    hooks:
      before_plan:
        - extension: graphify
          command: speckit.graphify.context
          enabled: true
          optional: true
          priority: 5
          prompt: Generate graphify codebase context before planning?
          description: Ground the plan in the existing dependency graph
          condition: null
      before_tasks:
        - extension: graphify
          command: speckit.graphify.context
          enabled: true
          optional: true
          priority: 5
          prompt: Generate graphify codebase context before task generation?
          description: Verify task parallelism against real dependency edges
          condition: null
      before_implement:
        - extension: graphify
          command: speckit.graphify.context
          enabled: true
          optional: true
          priority: 5
          prompt: Generate graphify codebase context before implementation?
          description: Pre-resolve per-task blast radius before parallel execution
          condition: null
MANUAL
}

set +e
out="$(run_yaml_merge "$EXT_YML" 2>/dev/null)"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  ok "registered hooks in .specify/extensions.yml"
else
  warn "automatic registration skipped"
  print_manual_block
fi

# --- done -------------------------------------------------------------------
echo
bold "Done. Next:"
echo "  1. Build the graph:        /graphify"
echo "  2. Spec it:                /speckit-specify  →  /speckit-plan"
echo "  3. Graph-aware tasks:      /speckit-tasks-graph"
echo "  4. Parallel implement:     /speckit-implement-parallel"
