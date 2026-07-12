#!/usr/bin/env bash
#
# speckit-ext-workforce — installer
# Layers the workforce pair (/speckit-categorize, /speckit-agent-assign,
# /speckit-workforce-approve) onto a repo already initialized with GitHub
# spec-kit (`specify init`). Sonnet categorizer + deterministic assemble.py +
# Sonnet skill-builder (spec 003-workforce).
#
# Packaging = git/council's own-payload idiom (rm -rf + cp -R under
# .specify/extensions/workforce/ and .claude/skills/) PLUS two things neither
# of those extensions needed:
#
#   (a) an ADDITIVE seed step (R5/S07) — 7 base specialists into
#       .claude/agents/ and 5 seed skills into .claude/skills/, read from the
#       workforce-config.yml `seed_library` manifest (never hardcoded here).
#       This is the one step that must NEVER live inside the extension's own
#       rm -rf payload: .claude/agents/ and .claude/skills/ are the live,
#       per-repo library (D17) — user data the skill-builder's flywheel also
#       writes into (D24, origin: generated) — so a reinstall, this
#       extension's own OR a completely foreign one's, must not clobber a
#       generated skill, a hand-edited seed, or a custom agent a user added.
#       Every seed file below is therefore copied ONLY IF ABSENT at its
#       destination — never overwritten — and .claude/agents/ /
#       .claude/skills/ are never rm -rf'd, in whole or in part. This is the
#       reinstall-survival property this repo's test suite exercises
#       (git-ext's own T020 proves the analogous gate-wiring case; workforce's
#       T029 harness proves this one). See uninstall.sh for the mirrored
#       invariant on the removal side.
#
#   (b) a REAL lock + atomic-rename on the `.specify/extensions.yml` hook
#       merge (S06). Round-1 triage on this feature's own plan flagged that
#       merge as a lock-free read-modify-write; the fix is a `flock` around
#       the whole read-modify-write PLUS a write-to-temp+rename so a reader
#       (or a second, concurrent installer) never observes a torn file and a
#       mid-write crash never leaves the shared registry half-written. Done
#       here with Python's stdlib `fcntl.flock` + `os.replace` (no new
#       runtime — Python 3 is already established by graphify, S19; the
#       `flock` CLI is not reliably present on macOS, so we don't shell out
#       to it — fcntl is stdlib on every POSIX Python). Note for future
#       readers: extensions/git/install.sh (feature 002) predates this
#       finding and still does a direct, non-atomic write to the same file;
#       this installer is where S06 actually lands in code.
#
# The two hooks merged in (b) — after_categorize, after_agent-assign, both
# targeting git-ext's OWN speckit.git.commit — are read from workforce's own
# extension.yml manifest (R7/D57 S1/S25: a hook point into another
# extension's command, never a foreign source edit; named explicitly here,
# not assumed to "just work" by analogy). The merge is append-only: git's and
# graphify's existing rows in the registry are read, resorted-in-place by
# `priority` ONLY within the two keys workforce itself declares, and
# otherwise never touched — so this script cannot re-order git's hooks even
# by accident (it never iterates any hook key outside its own manifest).
#
# Install order: git BEFORE workforce (S06) — the two hooks above target a
# git-ext command, so they no-op (harmlessly) until git-ext is installed.
# This script WARNS, not dies, if git-ext isn't detected: workforce still
# installs cleanly either way; the order is a documented convention, not a
# hard runtime dependency this script enforces.
#
# Usage:  ./install.sh [TARGET_REPO]      (default: current directory)
#
set -euo pipefail

# --- locate ourselves & the target -----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"

# One scratch dir + one EXIT trap for every temp file this script creates
# (the hook-merge script in step 4, the seed-path list in step 3) — POSIX-sh
# parseable throughout (no process substitution), unlike a `mktemp`-per-step
# approach where a second `trap ... EXIT` would silently replace the first.
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

[ -n "$TARGET" ] && [ -d "$TARGET" ] || die "Target repo not found: ${1:-$(pwd)}"

bold "speckit-ext-workforce → $TARGET"

# --- preconditions ----------------------------------------------------------
SPECIFY_DIR="$TARGET/.specify"
[ -d "$SPECIFY_DIR" ] || die "No .specify/ in target. Initialize spec-kit first:
    https://github.com/github/spec-kit  (run: specify init)"

# Install order (S06/S25): assume git-ext already installed. Advisory only —
# never a hard block — because workforce installs cleanly regardless; the
# after_categorize/after_agent-assign hooks registered below simply won't
# fire anything (speckit.git.commit won't exist) until git-ext lands.
if [ -d "$SPECIFY_DIR/extensions/git" ]; then
  ok "git-ext detected under .specify/extensions/git (install order satisfied)"
else
  warn "git-ext not detected under .specify/extensions/git"
  warn "  install order is git BEFORE workforce (S06). The after_categorize / after_agent-assign"
  warn "  hooks registered below target speckit.git.commit and will no-op until speckit-ext-git"
  warn "  is installed — install it first, or continue now and install it after."
fi

# --- 1. install the extension payload ---------------------------------------
EXT_DEST="$SPECIFY_DIR/extensions/workforce"
mkdir -p "$SPECIFY_DIR/extensions"
rm -rf "$EXT_DEST"
cp -R "$SCRIPT_DIR/extension" "$EXT_DEST"
ok "extension → .specify/extensions/workforce/"

# --- 2. install the 3 command skills -----------------------------------------
# workforce's OWN payload (speckit-categorize, speckit-agent-assign,
# speckit-workforce-approve) — same rm -rf + cp -R idiom as step 1 and as
# git/council's own command-skill install. This is NOT the seed library
# (step 3): these are extension-owned skill dirs we fully control by exact
# name, safe to replace wholesale on every install.
SKILLS_DEST="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DEST"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -R "$skill_dir" "$SKILLS_DEST/$name"
  ok "skill → .claude/skills/$name/"
done

# --- 3. seed the library ADDITIVELY (R5/S07 — READ THIS BEFORE TOUCHING) ----
# .claude/agents/ and .claude/skills/ are the live, per-repo library (D17):
# user/flywheel data that the skill-builder ALSO writes into at runtime (D24,
# origin: generated). They are NOT this extension's payload and must NEVER
# be reached by an rm -rf — not here, not on any future edit to this file.
#
# Every seed file below is copied ONLY IF its destination is absent; an
# existing file — whether it's our own previously-seeded copy, a user's
# hand-edit, or something unrelated entirely — is left byte-for-byte alone.
# This is what makes a reinstall, this extension's own OR a completely
# foreign extension's, safe: nothing in this step can ever clobber a
# generated skill, a hand-edited seed, or a custom agent a user added, and
# .claude/agents/ / .claude/skills/ are never wiped wholesale, in whole or in
# part (contrast step 2 above, which DOES rm -rf — but only its own 3 named,
# extension-owned dirs, never the seed/generated ones living alongside them).
#
# The workforce-config.yml `seed_library` manifest (not this script) is the
# single source of truth for WHICH 7 bases + 5 skills to seed; install.sh
# only knows how to copy `file:` paths additively, never what the set is.
SEED_MANIFEST="$EXT_DEST/workforce-config.yml"
[ -f "$SEED_MANIFEST" ] || die "seed manifest missing: $SEED_MANIFEST (step 1 above should have created it)"

seed_manifest_paths() {   # emit each seed_library `file:` path, one per line
  awk '
    /^seed_library:/            { infile = 1; next }
    /^[A-Za-z_][A-Za-z0-9_-]*:/ { infile = 0 }
    infile
  ' "$SEED_MANIFEST" | sed -n 's/^[[:space:]]*file:[[:space:]]*//p'
}

# Materialize the path list into a real file under WORK_DIR (not a process
# substitution / pipe into the `while read` below): redirecting a `while`
# loop from a plain file keeps it in THIS shell, so seeded/present below
# actually persist past the loop — a pipe (`... | while read; do :; done`)
# would silently run the loop in a subshell on this bash and lose them both.
SEED_LIST="$WORK_DIR/seed_paths.txt"
seed_manifest_paths > "$SEED_LIST"

seeded=0
present=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  src="$SCRIPT_DIR/$rel"
  dest="$TARGET/.claude/${rel#seed/}"
  if [ ! -f "$src" ]; then
    warn "seed source missing, skipping: $rel"
    continue
  fi
  if [ -e "$dest" ]; then
    present=$((present + 1))            # already there — NEVER overwritten (S07)
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    seeded=$((seeded + 1))
    ok "seed → .claude/${rel#seed/}"
  fi
done < "$SEED_LIST"

ok "seed library: $seeded new, $present already present and left untouched (additive — R5/S07)"

# --- 4. register hooks in .specify/extensions.yml ----------------------------
# Idempotent YAML merge, same technique as git-ext's own installer (R1-S06
# idiom): read workforce's OWN extension.yml manifest for its hook set
# (single source of truth, never hardcoded here), transform each declared
# hook into a registry row, and merge append-only into the shared registry.
#
# This merge additionally does what S06 asked for in full (git-ext's own
# install.sh does not, yet — see header note above): the whole
# read-modify-write runs under an `fcntl.flock` (so a second, concurrent
# installer blocks instead of racing) and the write lands via a tempfile +
# `os.replace` in the SAME directory as extensions.yml (an atomic rename on
# every POSIX filesystem) — never a direct `>` write that a crash mid-write
# could leave torn or a race could clobber. PyYAML required; we search the
# interpreters most likely to have it, then fall back to
# `uv run --with pyyaml`, then a hand-merge paste block (mirrors git-ext's
# and graphify's own fallback ladder).
EXT_YML="$SPECIFY_DIR/extensions.yml"
HOOK_MANIFEST="$EXT_DEST/extension.yml"

PY_MERGE="$WORK_DIR/merge.py"    # lives under WORK_DIR — the one EXIT trap set above cleans it up
cat > "$PY_MERGE" <<'PYEOF'
import sys, os, fcntl, tempfile, yaml

registry_path, manifest_path = sys.argv[1], sys.argv[2]

with open(manifest_path) as fh:
    manifest = yaml.safe_load(fh) or {}
ext_id = manifest.get("extension", {}).get("id", "workforce")
manifest_hooks = manifest.get("hooks", {}) or {}
# manifest_hooks is exactly {after_categorize: {...}, after_agent-assign: {...}}
# (extension.yml deliberately does NOT declare after_workforce_approve — that
# event is emitted by /speckit-workforce-approve and handled by git-ext's OWN
# on-gate-approve.sh, registered in git-ext's OWN extension.yml, D57 S2/R8 —
# so this loop, driven purely by workforce's manifest, never touches it).

def to_registry_row(hook_name, decl):
    # Same row shape git-ext's merge writes (R1-S06 idiom, mirrored). workforce
    # declares only after_* hooks (no before_*), so every row here lands at
    # priority 5 — the before_*-gets-1 branch is inert for us today, but kept
    # so `priority` stays a live, uniformly-sortable field across every
    # extension's rows, not a per-extension special case (the same field
    # git-ext's verify-gate relies on to sort ahead of graphify on
    # before_tasks/before_implement — R1-S07, git-ext's own council).
    priority = 1 if hook_name.startswith("before_") else 5
    row = {
        "extension": ext_id,
        "command": decl["command"],
        "enabled": True,
        "optional": decl.get("optional", False),  # both workforce hooks: false (auto-invoked)
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

lock_path = registry_path + ".lock"    # persistent on purpose: the stable path every future install/reinstall re-flocks; never deleted after use
lockfh = open(lock_path, "a+")
fcntl.flock(lockfh, fcntl.LOCK_EX)     # S06: serialize concurrent installers/merges on this file
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
            entries.append(row)        # append-only: git's / graphify's rows in OTHER keys untouched
        # stable sort by priority — a no-op today (workforce's rows are the
        # only occupants of these two keys) but keeps this key's ordering
        # rule identical to every other hook list in the registry (R1-S06).
        entries.sort(key=lambda e: e.get("priority", 5) if isinstance(e, dict) else 5)
        hooks[hook_name] = entries

    # S06: atomic write — stage in a tempfile NEXT TO extensions.yml (same
    # directory => same filesystem => the rename is atomic), then os.replace()
    # it over the real path. Nobody — another process reading the file, or
    # this process dying mid-write — ever observes a torn or half-written
    # registry; a crash here leaves the ORIGINAL file exactly as it was.
    # Never a direct `>` write, which a crash mid-write could leave torn.
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
  Merge workforce's hooks into .specify/extensions.yml by hand — add
  `workforce` to `installed:`, and under `hooks:` add each entry below
  (append to any existing list for that key; never remove or reorder
  another extension's rows):

    installed:
      - workforce
    hooks:
      after_categorize:    [ {extension: workforce, command: speckit.git.commit, optional: false, phase: categorize, priority: 5} ]
      after_agent-assign:  [ {extension: workforce, command: speckit.git.commit, optional: false, phase: agents,     priority: 5} ]
MANUAL
}

set +e
out="$(run_yaml_merge "$EXT_YML" "$HOOK_MANIFEST" 2>/dev/null)"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  ok "registered hooks in .specify/extensions.yml (after_categorize, after_agent-assign — locked + atomic, S06)"
else
  warn "automatic registration skipped"
  print_manual_block
fi

# --- done -------------------------------------------------------------------
echo
bold "Done. The workforce pair now runs itself:"
echo "  1. /speckit-categorize        → Sonnet tags every task (taxonomy v1), code-capped at general ≤ max(1, ⌊0.2n⌋)"
echo "  2. /speckit-agent-assign      → assemble.py matches the roster deterministically (skill-builder on a ∅-match gap)"
echo "  3. /speckit-workforce-approve → records the human gate signature, unlocks /speckit-implement-parallel"
echo
echo "  .claude/agents/ and .claude/skills/ were seeded additively — a reinstall (this one's or a foreign one's) never overwrites what's already there (R5/S07)."
