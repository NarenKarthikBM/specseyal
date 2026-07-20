#!/usr/bin/env sh
#
# speckit-ext-graphify — CI test harness (005-graphify-context, T001 scaffold)
#
# Scripted, model-free tests for the graphify extension. No LLM, no network, no
# ANTHROPIC_API_KEY — every check here is mechanical (diff, exit code), never a judgment
# call. Runs entirely in throwaway dirs under a temp root; NEVER touches this repo.
#
# Stages:
#   1. fixture goldens      — auto-discovered golden-output fixtures (convention below).
#   2. inline-comment strip — I-26/FR-012 (008-pre-public-maintenance, T014): fills the stage-2
#                             gap this file's scaffold reserved for "a later wave, not yet
#                             specified". Unit-level (imports augment_merge.py directly), not a
#                             fixture-goldens repo-tree diff — T014's edit list scopes new
#                             coverage to this file itself, not a new fixtures/*/ directory.
#   3. reinstall-survival   — STUB. T035 (a later wave) fills this in.
#
# ---------------------------------------------------------------------------------------
# Fixture convention — the CONTRACT every later fixture-adding task follows. Read this
# before adding a fixture. Adding a fixture NEVER requires editing this file.
#
#   - Each fixture is a self-contained directory: test/fixtures/<name>/
#   - It contains an executable cmd.sh that prints the ACTUAL output to stdout, and an
#     expected.txt golden (the byte-identical target). Optionally an input/ subdirectory
#     with fixture inputs, and a short README.md stating what the fixture asserts plus its
#     provenance.
#   - cmd.sh receives the repo root as $REPO (exported by this script) and references any
#     script-under-test by path under $REPO, e.g.:
#       "$REPO/extensions/graphify/extension/scripts/augment.sh"
#     cmd.sh must NOT depend on the caller's working directory.
#   - This script auto-discovers fixtures/*/: for each directory containing BOTH cmd.sh and
#     expected.txt, it runs cmd.sh with REPO exported, captures stdout, and byte-diffs the
#     result against expected.txt -> PASS iff identical. A fixture whose script-under-test
#     does not exist yet naturally FAILs (the intended TDD "fails first" state — that is
#     correct, not a harness bug).
#   - Decoupling guarantee: a later task adds a fixture by dropping in a new directory; it
#     NEVER edits this file. A directory missing either required file is not yet a fixture
#     and is silently skipped (the in-progress-authoring case), not treated as a failure.
#
# Usage:  sh extensions/graphify/test/run.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"          # repo root (…/specseyal)
export REPO
FIXTURES_DIR="$REPO/extensions/graphify/test/fixtures"
TMP="${TMPDIR:-/tmp}/speckit-graphify-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
bold "1. fixture goldens"
# Auto-discovery loop — see the header comment above for the convention this walks. The
# trailing "/" on the glob makes it match directories only; when fixtures/ holds no
# subdirectories yet, the pattern is left unexpanded and the `[ -d "$d" ]` guard below
# turns that into a clean zero-iteration loop rather than a spurious literal-string pass.
n_fixtures=0
for d in "$FIXTURES_DIR"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  cmd="${d}cmd.sh"
  exp="${d}expected.txt"
  # Missing either file: not yet a conforming fixture (in-progress authoring) — skip, don't fail.
  [ -f "$cmd" ] && [ -f "$exp" ] || continue
  n_fixtures=$((n_fixtures + 1))
  actual="$TMP/${name}.actual"
  stderr_log="$TMP/${name}.stderr"
  cmd_rc=0
  sh "$cmd" >"$actual" 2>"$stderr_log" || cmd_rc=$?
  if diff -q "$exp" "$actual" >/dev/null 2>&1; then
    ok "fixture $name: stdout matches expected.txt"
  elif [ "$cmd_rc" -ne 0 ]; then
    bad "fixture $name: cmd.sh exited $cmd_rc and stdout differs from expected.txt (see $stderr_log)"
  else
    bad "fixture $name: stdout differs from expected.txt"
  fi
done
[ "$n_fixtures" -eq 0 ] && printf '  (no fixtures present yet — scaffold only; see header above for the convention)\n'

# ---------------------------------------------------------------------------
bold "2. hook-command inline-comment strip (I-26/FR-012, T014)"
# parse_hook_commands() (augment_merge.py) must strip a whitespace-preceded trailing '#…'
# from a `command: <id>  # <comment>` line BEFORE calling dequote(), so the minted
# command-node id is clean (H2.1/SC-007) — extensions/git/extension/extension.yml's
# `speckit.git.record-gate  # hook-internal action: …` lines are the real-world, non-
# hypothetical shape this fixes. Unit-level: imports augment_merge.py directly (never
# shells out to augment.sh) so each assertion pins the exact function under test. Also
# carries the R1-S03 regressions: dequote()'s other two callers — resolve_target() and
# parse_shell() — must be provably unaffected, since the strip is scoped to
# parse_hook_commands() only and dequote() itself is untouched.
CS2_PY="$TMP/check-inline-comment-strip.py"
CS2_RESULTS="$TMP/check-inline-comment-strip.results"
cat > "$CS2_PY" <<'PYEOF'
#!/usr/bin/env python3
"""check-inline-comment-strip.py -- T014/I-26 checker (008-pre-public-maintenance).

Invoked once by run.sh's stage 2. Imports augment_merge.py directly (never shells out
to augment.sh) so each assertion pins the exact function under test named in this
task: parse_hook_commands() (the fix site) plus its sibling callers resolve_target()
and parse_shell() (the two other callers of dequote() that must stay unaffected,
R1-S03). Prints one result per line, "RESULT <PASS|FAIL> <label>"; run.sh reads this
back from a FILE (never a pipe -- a piped `while read` runs in a subshell and would
lose ok()/bad()'s PASS/FAIL counter updates) and calls ok()/bad().
"""
import sys

SCRIPTS_DIR, GIT_MANIFEST = sys.argv[1], sys.argv[2]
sys.path.insert(0, SCRIPTS_DIR)

import augment_merge as am  # noqa: E402 -- module under test


def check(label, got, expected):
    if got == expected:
        print("RESULT PASS %s" % label)
    else:
        print("RESULT FAIL %s -- got %r, want %r" % (label, got, expected))


# --- H2.3: inline-comment whitespace variants (parse_hook_commands, the fix site) ---

check(
    "I-26/H2.1: single-space before '#x' strips to a clean id (minimal whitespace case)",
    am.parse_hook_commands("hooks:\n  before_a:\n    command: speckit.t14.alpha #x\n    optional: true\n"),
    ["speckit.t14.alpha"],
)

check(
    "I-26/H2.3: '  #  x' (2-space, #, 2-space) strips to a clean id",
    am.parse_hook_commands("hooks:\n  before_b:\n    command: speckit.t14.beta  #  y\n    optional: true\n"),
    ["speckit.t14.beta"],
)

check(
    "I-26/H2.3: tab-separated '\\t#z' strips to a clean id",
    am.parse_hook_commands("hooks:\n  before_c:\n    command: speckit.t14.gamma\t#z\n    optional: true\n"),
    ["speckit.t14.gamma"],
)

check(
    "I-26/H2.2 boundary: '#' glued with NO preceding whitespace is part of the id, not stripped",
    am.parse_hook_commands("hooks:\n  before_d:\n    command: speckit.t14.delta#glued\n    optional: true\n"),
    ["speckit.t14.delta#glued"],
)

check(
    "I-26: a clean command (no comment at all) is unaffected -- no false-positive stripping",
    am.parse_hook_commands("hooks:\n  before_e:\n    command: speckit.t14.epsilon\n    optional: true\n"),
    ["speckit.t14.epsilon"],
)

# --- Real-world hazard: extensions/git/extension/extension.yml's actual
# `record-gate  # ...` lines (the exact shape this task's prompt calls out as
# non-hypothetical, not a synthetic-only fix). ---
git_text = open(GIT_MANIFEST, encoding="utf-8").read()
git_cmds = am.parse_hook_commands(git_text)
check(
    "I-26 real-world: extensions/git/extension/extension.yml's record-gate hooks mint a clean id",
    ("speckit.git.record-gate" in git_cmds, any(" #" in c for c in git_cmds)),
    (True, False),
)

# --- R1-S03: dequote() itself carries NO comment-stripping logic -- proven directly.
# The I-26 strip is scoped to parse_hook_commands() only; dequote() must return an
# internal, whitespace-preceded '#' completely unchanged. ---
check(
    "R1-S03: dequote() itself does not strip an internal ' #' -- the fix lives in the caller, not here",
    am.dequote("speckit.t14.zeta #not-stripped-by-dequote"),
    "speckit.t14.zeta #not-stripped-by-dequote",
)

# --- R1-S03 regression: resolve_target() (dequote() caller #2) is unaffected. A
# quoted path whose content legitimately CONTAINS a whitespace-preceded '#' (not a
# YAML comment -- an ordinary shell string) must resolve intact, not truncated. ---
check(
    "R1-S03: resolve_target() leaves an internal whitespace+'#' inside a quoted path intact",
    am.resolve_target('".specify/extensions/commentwidget/notes #1.md"', "", set()),
    ".specify/extensions/commentwidget/notes #1.md",
)

check(
    "R1-S03: resolve_target()'s ordinary self-locating quote-strip still works (unrelated baseline)",
    am.resolve_target('"$SCRIPT_DIR/helper.sh"', "", {"SCRIPT_DIR"}),
    "helper.sh",
)

# --- R1-S03 regression: parse_shell() (dequote() caller #3, via last_operand +
# resolve_target) is unaffected end-to-end -- a `cp` line whose quoted destination
# carries the same whitespace+'#' sequence must still mint a full, untruncated
# `installs` edge, never a truncated one. ---
check(
    "R1-S03: parse_shell() cp-destination with an internal ' #' mints a full, untruncated edge",
    am.parse_shell("regress.sh", 'cp "notes.txt" ".specify/extensions/commentwidget/notes #1.md"\n'),
    [("installs", "regress.sh", ".specify/extensions/commentwidget/notes #1.md", "EXTRACTED")],
)

check(
    "R1-S03: parse_shell()'s own column-0 '#'-comment-line skip is untouched (independent of I-26)",
    am.parse_shell("x.sh", '# a full-line comment, never a source line\ncp "a" "b"\n'),
    [("installs", "x.sh", "b", "EXTRACTED")],
)

check(
    "R1-S03: parse_shell() self-locating `source` still resolves via resolve_target() end-to-end",
    am.parse_shell(
        "regress.sh",
        'SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"\n. "$SCRIPT_DIR/helper.sh"\n',
    ),
    [("invokes", "regress.sh", "helper.sh", "EXTRACTED")],
)
PYEOF

cs2_rc=0
python3 "$CS2_PY" "$REPO/extensions/graphify/extension/scripts" "$REPO/extensions/git/extension/extension.yml" \
  > "$CS2_RESULTS" 2>"$TMP/check-inline-comment-strip.err" || cs2_rc=$?

if [ "$cs2_rc" -ne 0 ]; then
  bad "inline-comment-strip checker exited $cs2_rc (a bug in the checker itself, not necessarily in augment_merge.py) -- see $TMP/check-inline-comment-strip.err"
fi

cs2_result_count=0
# Read from a FILE, never a pipe: piping into `while read` would run the loop body in a
# subshell, and ok()/bad() updating PASS/FAIL there would be lost the moment the pipeline
# exits (a real POSIX-sh subshell trap) — same discipline as extensions/deck-render/test/run.sh.
while read -r cs2_tag cs2_verdict cs2_label; do
  [ "$cs2_tag" = "RESULT" ] || continue
  cs2_result_count=$((cs2_result_count + 1))
  case "$cs2_verdict" in
    PASS) ok "$cs2_label" ;;
    FAIL) bad "$cs2_label" ;;
    *) bad "inline-comment-strip checker produced an unparseable result line: $cs2_tag $cs2_verdict $cs2_label" ;;
  esac
done < "$CS2_RESULTS"

if [ "$cs2_result_count" -eq 0 ] && [ "$cs2_rc" -eq 0 ]; then
  bad "inline-comment-strip checker produced zero result lines -- a silent 0-assertion pass"
fi

# ---------------------------------------------------------------------------
bold "3. reinstall-survival (D57 — T035)"
# The installer rm -rf + cp -R's extensions/graphify/extension/ -> .specify/extensions/graphify/
# and each skills/*/ -> .claude/skills/. Every 005 source edit under those trees must survive an
# install AND a REINSTALL (the S04 hazard extensions/git/test/run.sh §3 and workforce §1 regress
# for their own extensions). Install graphify into a throwaway target, assert the 005 edits are
# present + functional in the INSTALLED copies, reinstall, and re-assert they survived.
RT="$TMP/reinstall-graphify"
mkdir -p "$RT/.specify" "$RT/.claude/skills"
GSRC="$REPO/extensions/graphify"
sh "$GSRC/install.sh" "$RT" >/dev/null 2>&1 || bad "graphify install.sh failed"

isc="$RT/.specify/extensions/graphify/scripts"
iskill="$RT/.claude/skills/speckit-graphify-context/SKILL.md"
for s in augment.sh augment_merge.py explain-guard.sh freshness.sh refresh.sh refresh_merge.py provenance.sh; do
  [ -f "$isc/$s" ] && ok "installed $s present" || bad "installed $s MISSING after install"
done
[ -f "$RT/.specify/extensions/graphify/graphify-version.pin" ] && ok "installed graphify-version.pin present" || bad "installed .pin MISSING"
grep -q 'arm 1 detached' "$isc/refresh.sh" && ok "refresh.sh arm-1-detached branch survived install" || bad "refresh.sh detach branch MISSING after install"
grep -q 'graphify-provenance:v1' "$iskill" && ok "provenance-header contract survived install" || bad "provenance contract MISSING in installed SKILL.md"
grep -q 'graphify-receipts.md' "$iskill" && grep -q 'graphify-type-signal.md' "$iskill" && ok "3-product generator survived install" || bad "3-product generator MISSING in installed SKILL.md"
# FUNCTIONAL: the installed provenance.sh actually runs (not just copied bytes).
rgj="$RT/reinstall-probe.json"
printf '{"directed":true,"multigraph":false,"graph":{},"nodes":[],"links":[],"hyperedges":[],"built_at_commit":"abc"}' > "$rgj"
if sh "$isc/provenance.sh" generation-id "$rgj" 2>/dev/null | grep -q '^sha256:'; then ok "installed provenance.sh functional"; else bad "installed provenance.sh broken"; fi
# THE S04 property: a reinstall must not wipe the 005 edits.
sh "$GSRC/install.sh" "$RT" >/dev/null 2>&1 || bad "graphify reinstall failed"
if [ -f "$isc/augment.sh" ] && grep -q 'graphify-provenance:v1' "$iskill" && grep -q 'arm 1 detached' "$isc/refresh.sh"; then
  ok "005 graphify edits SURVIVED reinstall (source-owned, D57)"
else
  bad "005 graphify edits WIPED by reinstall — the S04 hazard"
fi

# ---------------------------------------------------------------------------
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
