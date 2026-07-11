#!/usr/bin/env sh
#
# speckit-ext-workforce — assemble.py golden tests (T021)
#
# Zero-AI, CI-runnable, no model calls: exercises the deterministic §3 matcher/assembler
# (extension/scripts/assemble.py) against a frozen library snapshot + frozen categorization
# fixtures under extensions/workforce/test/fixtures/assemble/. Covers the five committed
# plan-time verifications (specs/003-workforce/plan.md § Plan-time verifications):
#
#   1. SC-005/S01  double-run determinism, INCLUDING grant order (not just membership) --
#                  a byte-for-byte diff of two runs over the same categorization+library,
#                  with PYTHONHASHSEED varied between them, plus a diff against a frozen
#                  golden roster.
#   2. SC-006/S03  D48 guard: a `prompt`-tagged task whose (type, specialization) resolves
#                  to the frozen SYNTHETIC non-Sonnet base (agt_fx_nonsonnet, model: haiku)
#                  -- assert assemble.py hard-errors (exit 2) and writes nothing (the guard's
#                  `else: hard-error` branch actually executing, not just existing in source).
#   3. SC-004      a task with >3 tag-matching skills -- exactly 3 injected, the 4th logged
#                  in the roster's Dropped-skill notes, never silently discarded.
#   4. SC-003/S09  a task assembling >=2 grant-declaring skills -- the Elevated-grants column
#                  is the exact total-ordered union: no grant dropped, none duplicated.
#   5. S15         a 2-task/1-gap fixture, re-run after a simulated skill-builder closes the
#                  gap (--built-skill) -- the non-gap task's roster row is byte-identical
#                  across both runs; only the gap task's row changes.
#
# Runs entirely against the frozen fixtures + a throwaway TMP dir; never touches the frozen
# fixtures, the live .claude/ library, or any file outside extensions/workforce/test/.
#
# Usage:  sh extensions/workforce/test/test_assemble.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"                 # repo root (…/specseyal)
WF="$REPO/extensions/workforce"
ASSEMBLE="$WF/extension/scripts/assemble.py"
FIX="$WF/test/fixtures/assemble"

AGENTS_DIR="$FIX/library/agents"
SKILLS_DIR="$FIX/library/skills"
MAIN_CATEG="$FIX/categorization.fixture.md"
D48_CATEG="$FIX/categorization.d48.fixture.md"
GAP_CATEG="$FIX/gap/categorization.fixture.md"
GAP_SKILLS_OPEN="$FIX/gap/skills-open"
GAP_SKILLS_CLOSED="$FIX/gap/skills-closed"
GOLDEN="$FIX/expected/assignment.roster.golden.md"

PY="${PYTHON:-python3}"

TMP="${TMPDIR:-/tmp}/speckit-assemble-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$1"; }

[ -f "$ASSEMBLE" ] || { echo "FATAL: assemble.py not found at $ASSEMBLE" >&2; exit 1; }
[ -f "$GOLDEN" ]   || { echo "FATAL: frozen golden not found at $GOLDEN" >&2; exit 1; }

# ===========================================================================
bold "1. SC-005/S01 -- double-run determinism (byte-identical roster, incl. grant ORDER)"

OUT1="$TMP/run1/assignment.md"; OUT2="$TMP/run2/assignment.md"
mkdir -p "$TMP/run1" "$TMP/run2"

rc=0
PYTHONHASHSEED=0 "$PY" "$ASSEMBLE" "$MAIN_CATEG" \
  --agents-dir "$AGENTS_DIR" --skills-dir "$SKILLS_DIR" \
  --output "$OUT1" >"$TMP/run1.stdout" 2>"$TMP/run1.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then ok "run 1 (PYTHONHASHSEED=0) exits 0"; else bad "run 1 exited $rc: $(cat "$TMP/run1.stderr")"; fi

rc=0
PYTHONHASHSEED=4294967295 "$PY" "$ASSEMBLE" "$MAIN_CATEG" \
  --agents-dir "$AGENTS_DIR" --skills-dir "$SKILLS_DIR" \
  --output "$OUT2" >"$TMP/run2.stdout" 2>"$TMP/run2.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then ok "run 2 (PYTHONHASHSEED=4294967295) exits 0"; else bad "run 2 exited $rc: $(cat "$TMP/run2.stderr")"; fi

if diff -u "$OUT1" "$OUT2" >"$TMP/run1v2.diff" 2>&1; then
  ok "run1 vs run2: byte-identical roster across PYTHONHASHSEED (S01 total-order holds)"
else
  bad "run1 vs run2 DIFFER -- nondeterminism leaked: $(cat "$TMP/run1v2.diff")"
fi

if diff -u "$GOLDEN" "$OUT1" >"$TMP/golden.diff" 2>&1; then
  ok "run1 matches the frozen golden (fixtures/assemble/expected/assignment.roster.golden.md)"
else
  bad "run1 DIFFERS from the frozen golden: $(cat "$TMP/golden.diff")"
fi

MAIN_GAP_LINE="$(grep -F -- 'GAP_TASKS:' "$TMP/run1.stdout" || true)"
if [ "$MAIN_GAP_LINE" = "GAP_TASKS: " ]; then
  ok "main fixture run is gap-free (GAP_TASKS: empty), as designed"
else
  bad "main fixture run unexpectedly reports a gap: [$MAIN_GAP_LINE]"
fi

if grep -qF -- '(built)' "$OUT1"; then
  bad "main fixture roster unexpectedly carries a (built) mark -- not gap-free (FR-022)"
else
  ok "main fixture roster carries zero (built) marks -- gap-free is a checkable artifact property (FR-022)"
fi

# T001/T002's expected rows are read straight off the frozen golden -- one source of truth,
# reused by sections 3 and 4 below -- rather than re-transcribed into this script.
EXPECT_T001="$(grep '^| T001 ' "$GOLDEN" || true)"
EXPECT_T002="$(grep '^| T002 ' "$GOLDEN" || true)"
EXPECT_DROPPED="$(grep -F -- 'dropped' "$GOLDEN" | grep -F -- 'T002' || true)"

T001_ROW="$(grep '^| T001 ' "$OUT1" || true)"
T002_ROW="$(grep '^| T002 ' "$OUT1" || true)"

if [ -n "$EXPECT_T001" ] && [ "$T001_ROW" = "$EXPECT_T001" ]; then
  ok "T001 grants column is the exact total order: aa_beta_only, web_search, zz_alpha_only (not raw injection order)"
else
  bad "T001 row does not match the golden's total-ordered grant union. Got: [$T001_ROW]"
fi

# ===========================================================================
bold "2. SC-006/S03 -- D48 guard hard-errors: prompt-tagged task -> non-Sonnet base"

D48_OUT="$TMP/d48/assignment.md"
mkdir -p "$TMP/d48"
rc=0
"$PY" "$ASSEMBLE" "$D48_CATEG" \
  --agents-dir "$AGENTS_DIR" --skills-dir "$SKILLS_DIR" \
  --output "$D48_OUT" >"$TMP/d48.stdout" 2>"$TMP/d48.stderr" || rc=$?

if [ "$rc" -eq 2 ]; then ok "D48 fixture exits 2 (D48GuardError, assemble.py's documented exit-code contract)"; else bad "D48 fixture exited $rc, expected 2"; fi
if grep -qF -- 'D48' "$TMP/d48.stderr"; then ok "stderr names the D48 guard"; else bad "stderr does not mention D48: $(cat "$TMP/d48.stderr")"; fi
if grep -qF -- 'agt_fx_nonsonnet' "$TMP/d48.stderr"; then ok "stderr names the offending non-Sonnet base (agt_fx_nonsonnet)"; else bad "stderr does not name agt_fx_nonsonnet: $(cat "$TMP/d48.stderr")"; fi
if grep -qF -- "model='haiku'" "$TMP/d48.stderr"; then ok "stderr names the offending model (haiku)"; else bad "stderr does not name the haiku model: $(cat "$TMP/d48.stderr")"; fi
if [ -f "$D48_OUT" ]; then bad "D48 guard should write NOTHING, but $D48_OUT exists"; else ok "D48 guard wrote nothing (the else: hard-error branch actually executed, not just declared)"; fi

# ===========================================================================
bold "3. SC-004 -- >3 candidate skills -> exactly 3 injected, remainder logged"

if [ -n "$EXPECT_T002" ] && [ "$T002_ROW" = "$EXPECT_T002" ]; then
  ok "T002 injects exactly 3 skills (delta, epsilon, gamma -- the id-ascending top 3 of 4 tied candidates)"
else
  bad "T002 row does not match the golden's expected 3-skill cap result. Got: [$T002_ROW]"
fi

case "$T002_ROW" in
  *skl_fx_zeta*) bad "T002 row WRONGLY includes the dropped skill skl_fx_zeta" ;;
  *) ok "T002 row correctly excludes skl_fx_zeta (the 4th candidate, dropped by the cap)" ;;
esac

ACTUAL_DROPPED="$(grep -F -- 'dropped' "$OUT1" | grep -F -- 'T002' || true)"
if [ -n "$EXPECT_DROPPED" ] && [ "$ACTUAL_DROPPED" = "$EXPECT_DROPPED" ]; then
  ok "the dropped skill (skl_fx_zeta) is logged in the roster's Dropped-skill notes, not silently discarded"
else
  bad "Dropped-skill note for T002 missing or wrong. Got: [$ACTUAL_DROPPED], golden: [$EXPECT_DROPPED]"
fi

# ===========================================================================
bold "4. SC-003/S09 -- grant union: >=2 grant-declaring skills, no grant dropped/mis-merged"

case "$T001_ROW" in
  *skl_fx_alpha*) ok "T001 injects the grant-declaring skl_fx_alpha" ;;
  *) bad "T001 row missing skl_fx_alpha: $T001_ROW" ;;
esac
case "$T001_ROW" in
  *skl_fx_beta*) ok "T001 injects the grant-declaring skl_fx_beta" ;;
  *) bad "T001 row missing skl_fx_beta: $T001_ROW" ;;
esac

for g in aa_beta_only web_search zz_alpha_only; do
  n="$(printf '%s\n' "$T001_ROW" | grep -oF -- "$g" | wc -l | tr -d ' ')"
  if [ "$n" = "1" ]; then
    ok "grant '$g' appears exactly once in T001's Elevated-grants column (no drop, no dup)"
  else
    bad "grant '$g' appears $n time(s) in T001's row, expected exactly 1: $T001_ROW"
  fi
done
# (exact ORDER -- aa_beta_only, web_search, zz_alpha_only, alphabetical rather than the raw
# concatenation/injection order web_search,zz_alpha_only,aa_beta_only -- is already asserted
# by section 1's byte-for-byte T001-vs-golden row check; S01 defines order as part of
# byte-identity, not a separate property, so it is not re-derived here.)

# ===========================================================================
bold "5. S15 -- gap-rerun stability (2-task/1-gap; only the gap task's row may change)"

GAP_OUT_OPEN="$TMP/gap-open/assignment.md"
GAP_OUT_CLOSED="$TMP/gap-closed/assignment.md"
mkdir -p "$TMP/gap-open" "$TMP/gap-closed"

rc=0
"$PY" "$ASSEMBLE" "$GAP_CATEG" \
  --agents-dir "$AGENTS_DIR" --skills-dir "$GAP_SKILLS_OPEN" \
  --output "$GAP_OUT_OPEN" >"$TMP/gap-open.stdout" 2>"$TMP/gap-open.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then ok "gap-open run exits 0 (an unclosed gap is reported, not a hard error)"; else bad "gap-open run exited $rc: $(cat "$TMP/gap-open.stderr")"; fi

GAP_LINE_OPEN="$(grep -F -- 'GAP_TASKS:' "$TMP/gap-open.stdout" || true)"
if [ "$GAP_LINE_OPEN" = "GAP_TASKS: T002" ]; then
  ok "gap-open run reports GAP_TASKS: T002"
else
  bad "gap-open run's GAP_TASKS line wrong: got [$GAP_LINE_OPEN]"
fi

rc=0
"$PY" "$ASSEMBLE" "$GAP_CATEG" \
  --agents-dir "$AGENTS_DIR" --skills-dir "$GAP_SKILLS_CLOSED" --built-skill skl_fx_novel \
  --output "$GAP_OUT_CLOSED" >"$TMP/gap-closed.stdout" 2>"$TMP/gap-closed.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then ok "gap-closed run exits 0"; else bad "gap-closed run exited $rc: $(cat "$TMP/gap-closed.stderr")"; fi

GAP_LINE_CLOSED="$(grep -F -- 'GAP_TASKS:' "$TMP/gap-closed.stdout" || true)"
if [ "$GAP_LINE_CLOSED" = "GAP_TASKS: " ]; then
  ok "gap-closed run reports an empty GAP_TASKS (the gap is closed)"
else
  bad "gap-closed run's GAP_TASKS line wrong, expected empty: got [$GAP_LINE_CLOSED]"
fi

OPEN_T001="$(grep '^| T001 ' "$GAP_OUT_OPEN" || true)"
CLOSED_T001="$(grep '^| T001 ' "$GAP_OUT_CLOSED" || true)"
EXPECT_GAP_T001='| T001 | `agt_fx_sonnet` | Sonnet | `skl_fx_known@1.0.0` (library) | none |'
if [ "$OPEN_T001" = "$EXPECT_GAP_T001" ] && [ "$CLOSED_T001" = "$EXPECT_GAP_T001" ]; then
  ok "non-gap task T001's roster row is BYTE-IDENTICAL before and after the gap closes"
else
  bad "T001's row is not stable across the gap rerun. open=[$OPEN_T001] closed=[$CLOSED_T001]"
fi

OPEN_T002="$(grep '^| T002 ' "$GAP_OUT_OPEN" || true)"
CLOSED_T002="$(grep '^| T002 ' "$GAP_OUT_CLOSED" || true)"
EXPECT_GAP_T002_OPEN='| T002 | `agt_fx_sonnet` | Sonnet | none | none |'
EXPECT_GAP_T002_CLOSED='| T002 | `agt_fx_sonnet` | Sonnet | `skl_fx_novel@1.0.0` (built) | none |'
if [ "$OPEN_T002" = "$EXPECT_GAP_T002_OPEN" ]; then
  ok "gap task T002's open-run row shows no injected skills (the gap, before closing)"
else
  bad "T002's open row unexpected. Got: [$OPEN_T002]"
fi
if [ "$CLOSED_T002" = "$EXPECT_GAP_T002_CLOSED" ]; then
  ok "gap task T002's closed-run row now injects skl_fx_novel, marked (built) per FR-022"
else
  bad "T002's closed row unexpected. Got: [$CLOSED_T002]"
fi
if [ -n "$OPEN_T002" ] && [ -n "$CLOSED_T002" ] && [ "$OPEN_T002" != "$CLOSED_T002" ]; then
  ok "T002's row DID change once the gap closed (as it must -- only the gap row changes)"
else
  bad "T002's row did NOT change across the gap rerun"
fi

# ===========================================================================
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
