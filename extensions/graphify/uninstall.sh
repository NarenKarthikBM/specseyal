#!/usr/bin/env bash
#
# speckit-graphifyy — uninstaller
# Removes the graphify extension, the 3 companion skills, and de-registers the
# graphify hooks from .specify/extensions.yml. Stock spec-kit is left untouched.
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

bold "speckit-graphifyy uninstall → $TARGET"

# 1. extension
rm -rf "$TARGET/.specify/extensions/graphify"
ok "removed .specify/extensions/graphify/"

# 2. skills
for name in speckit-graphify-context speckit-tasks-graph speckit-implement-parallel; do
  if [ -d "$TARGET/.claude/skills/$name" ]; then
    rm -rf "$TARGET/.claude/skills/$name"
    ok "removed .claude/skills/$name/"
  fi
done

# 3. de-register hooks
EXT_YML="$TARGET/.specify/extensions.yml"
if [ ! -f "$EXT_YML" ]; then
  echo; bold "Done."
  exit 0
fi

PY_CLEAN="$(mktemp)"
trap 'rm -f "$PY_CLEAN"' EXIT
cat > "$PY_CLEAN" <<'PYEOF'
import sys, yaml

path = sys.argv[1]
with open(path) as fh:
    data = yaml.safe_load(fh) or {}

if isinstance(data.get("installed"), list):
    data["installed"] = [x for x in data["installed"] if x != "graphify"]

for hook, entries in list(data.get("hooks", {}).items()):
    if isinstance(entries, list):
        data["hooks"][hook] = [
            e for e in entries
            if not (isinstance(e, dict) and e.get("extension") == "graphify")
        ]

with open(path, "w") as fh:
    yaml.safe_dump(data, fh, default_flow_style=False, sort_keys=False)
print("cleaned")
PYEOF

shebang_python() {
  command -v "$1" >/dev/null 2>&1 || return 1
  head -n1 "$(command -v "$1")" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}'
}

run_yaml_clean() {
  local py
  for py in "$(shebang_python graphify)" "$(shebang_python specify)" python3 python; do
    [ -n "$py" ] || continue
    if command -v "$py" >/dev/null 2>&1 && "$py" -c 'import yaml' >/dev/null 2>&1; then
      "$py" "$PY_CLEAN" "$1" && return 0
    fi
  done
  if command -v uv >/dev/null 2>&1; then
    uv run --quiet --with pyyaml python "$PY_CLEAN" "$1" && return 0
  fi
  return 70
}

set +e
run_yaml_clean "$EXT_YML" >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  ok "de-registered hooks in .specify/extensions.yml"
else
  warn "could not auto-edit extensions.yml — remove the 'graphify' entries by hand"
fi

echo
bold "Done."
