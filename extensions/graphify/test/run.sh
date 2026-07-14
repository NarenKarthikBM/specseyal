#!/usr/bin/env sh
#
# speckit-ext-graphify — CI test harness (005-graphify-context, T001 scaffold)
#
# Scripted, model-free tests for the graphify extension. No LLM, no network, no
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
