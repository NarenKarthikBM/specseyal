#!/usr/bin/env sh
#
# speckit-ext-council — CI test harness (005-graphify-context, T002 scaffold)
#
# Scripted, model-free tests for the council extension. No LLM, no network, no
# ANTHROPIC_API_KEY — every check here is mechanical (diff, exit code), never a judgment
# call. Runs entirely in throwaway dirs under a temp root; NEVER touches this repo.
#
# Stages:
#   1. fixture goldens     — auto-discovered golden-output fixtures (convention below).
#   3. reinstall-survival  — STUB. T035 (a later wave) fills this in. Stage "2." is
#                            intentionally absent: it is reserved for a later wave, not yet
#                            specified. Do not renumber stage 3 to close the gap.
#
# ---------------------------------------------------------------------------------------
# Fixture convention — the CONTRACT every later fixture-adding task follows. Read this
# before adding a fixture. Adding a fixture NEVER requires editing this file. (Siblings with
# extensions/graphify/test/run.sh's own convention — identical in spirit, so a contributor
# who has read one has read both.)
#
#   - Each fixture is a self-contained directory: test/fixtures/<name>/
#   - It contains an executable cmd.sh that prints the ACTUAL output to stdout, and an
#     expected.txt golden (the byte-identical target). Optionally an input/ subdirectory
#     with fixture inputs, and a short README.md stating what the fixture asserts plus its
#     provenance.
#   - cmd.sh receives the repo root as $REPO (exported by this script) and references any
#     script-under-test by path under $REPO, e.g.:
#       "$REPO/extensions/council/extension/council-config.yml"
#     cmd.sh must NOT depend on the caller's working directory. Council arm-4 fixtures will
#     typically have cmd.sh print a simulated trace-fragment / disclosure decision computed
#     from a council-config.yml input, but the convention is identical regardless of what's
#     under test: stdout vs. expected.txt.
#   - This script auto-discovers fixtures/*/: for each directory containing BOTH cmd.sh and
#     expected.txt, it runs cmd.sh with REPO exported, captures stdout, and byte-diffs the
#     result against expected.txt -> PASS iff identical. A fixture whose script-under-test
#     does not exist yet naturally FAILs (the intended TDD "fails first" state — that is
#     correct, not a harness bug).
#   - Decoupling guarantee: a later task adds a fixture by dropping in a new directory; it
#     NEVER edits this file. A directory missing either required file is not yet a fixture
#     and is silently skipped (the in-progress-authoring case), not treated as a failure.
#
# Usage:  sh extensions/council/test/run.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"          # repo root (…/specseyal)
export REPO
FIXTURES_DIR="$REPO/extensions/council/test/fixtures"
TMP="${TMPDIR:-/tmp}/speckit-council-test.$$"
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
bold "3. reinstall-survival (D57 — T035)"
# The installer rm -rf + cp -R's extensions/council/extension/ -> .specify/extensions/council/
# and skills/*/ -> .claude/skills/. Every 005 arm-4 source edit must survive an install AND a
# REINSTALL (the S04 hazard). Install council into a throwaway target, assert the arm-4 edits are
# present + functional in the INSTALLED copies, reinstall, and re-assert.
RT="$TMP/reinstall-council"
mkdir -p "$RT/.specify" "$RT/.claude/skills"
CSRC="$REPO/extensions/council"
sh "$CSRC/install.sh" "$RT" >/dev/null 2>&1 || bad "council install.sh failed"

ics="$RT/.specify/extensions/council/scripts"
icfg="$RT/.specify/extensions/council/council-config.yml"
imember="$RT/.specify/extensions/council/templates/member-prompt.md"
iorch="$RT/.claude/skills/speckit-council/SKILL.md"
[ -f "$ics/ceiling-check.sh" ] && ok "installed ceiling-check.sh present" || bad "installed ceiling-check.sh MISSING after install"
grep -q 'query_ceiling' "$icfg" && ok "council-config query_ceiling survived install" || bad "query_ceiling MISSING in installed config"
grep -qE 'query ceiling|graph_queries' "$imember" && ok "member-prompt ceiling instruction survived install" || bad "member-prompt ceiling MISSING after install"
grep -qE 'ceiling-check.sh|Query-ceiling enforcement' "$iorch" && ok "orchestrator ceiling wiring survived install" || bad "orchestrator ceiling wiring MISSING after install"
# FUNCTIONAL: the installed ceiling-check.sh runs — and resolves ../council-config.yml in the
# installed layout too (both branches, to prove the quiet path also survived).
if sh "$ics/ceiling-check.sh" standard 15 2>/dev/null | head -1 | grep -q 'ceiling_hit: true'; then ok "installed ceiling-check.sh functional (ceiling hit)"; else bad "installed ceiling-check.sh broken (hit path)"; fi
if sh "$ics/ceiling-check.sh" standard 8 2>/dev/null | head -1 | grep -q 'ceiling_hit: false'; then ok "installed ceiling-check.sh functional (quiet path)"; else bad "installed ceiling-check.sh broken (quiet path)"; fi
# THE S04 property: a reinstall must not wipe the arm-4 edits.
sh "$CSRC/install.sh" "$RT" >/dev/null 2>&1 || bad "council reinstall failed"
if [ -f "$ics/ceiling-check.sh" ] && grep -q 'query_ceiling' "$icfg" && grep -qE 'ceiling-check.sh|Query-ceiling enforcement' "$iorch"; then
  ok "005 council arm-4 edits SURVIVED reinstall (source-owned, D57)"
else
  bad "005 council arm-4 edits WIPED by reinstall — the S04 hazard"
fi

# ---------------------------------------------------------------------------
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
