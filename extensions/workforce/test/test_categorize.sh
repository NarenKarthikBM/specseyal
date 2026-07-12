#!/usr/bin/env sh
#
# speckit-ext-workforce — validate-categorization.py CODE-gate tests (T013)
#
# Zero-AI, CI-runnable, no model calls: the categorizer session itself is an LLM
# and not unit-testable (its output is non-reproducible prose-to-table authorship).
# What IS unit-testable, and what this harness exercises exhaustively, is the CODE
# gate in front of it -- extension/scripts/validate-categorization.py -- plus its
# no-write-on-breach guarantee, against fixtures under
# extensions/workforce/test/fixtures/categorize/. Covers:
#
#   1. A conforming categorization.md (all four fields, closed-enum, `general`
#      under cap) -> exit 0.
#   2. SC-002/S22: an over-cap (`general` > 20%) categorization -> exit non-zero
#      AND no write. Since validate-categorization.py's write-gate only exists in
#      its 2-arg (gate+write) CLI form, this section runs that form and asserts
#      the file-state directly (not just the exit code): a FRESH output path is
#      left ABSENT, and a PRE-SEEDED (stale) output path is left BYTE-UNCHANGED
#      (`cmp -s` against a saved copy) -- exactly the two halves the script's own
#      module docstring ("HOW THE NO-WRITE-ON-BREACH GUARANTEE (S22) IS REALIZED")
#      documents. A positive control (a PASSING run DOES write) runs first, so the
#      negative assertions aren't vacuously true because the write path is simply
#      broken/unreachable.
#   3. SC-001: six independent malformed fixtures, each isolating exactly one
#      breach -- (a) a field present in shape but empty, (b) an out-of-enum `type`
#      and `specialization`, (c) a non-boolean `preserves_behavior`, (d) a
#      non-kebab tag, (e) a duplicate `task_id`, (f) a non-boolean
#      `runtime_consumed` (the v1 modifier, D65) -- each -> exit non-zero.
#   4. The cap boundary: `general == floor(0.20 x N)` exactly -> exit 0 (the cap
#      is validate_cap()'s `>`, never `>=`).
#   5. The v1 one-task floor (D65 verdict 9): `max(1, floor(0.2n))`. A 4-task
#      feature (n<5) with 1 general -> exit 0 (v0's literal cap would have FAILED
#      it); the same with 2 general -> exit non-zero (the floor is 1, not unbounded).
#
# Usage:  sh extensions/workforce/test/test_categorize.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"                 # repo root (…/specseyal)
WF="$REPO/extensions/workforce"
VALIDATE="$WF/extension/scripts/validate-categorization.py"
FIX="$WF/test/fixtures/categorize"

PY="${PYTHON:-python3}"

TMP="${TMPDIR:-/tmp}/speckit-categorize-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$1"; }

[ -f "$VALIDATE" ] || { echo "FATAL: validate-categorization.py not found at $VALIDATE" >&2; exit 1; }
[ -d "$FIX" ]       || { echo "FATAL: fixtures dir not found at $FIX" >&2; exit 1; }

# ===========================================================================
bold "1. Valid fixture -> exit 0"

rc=0
"$PY" "$VALIDATE" "$FIX/valid.fixture.md" >"$TMP/valid.stdout" 2>"$TMP/valid.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then
  ok "valid fixture (10 tasks, all FIVE fields incl. runtime_consumed, closed-enum, general 1/10 under cap) exits 0"
else
  bad "valid fixture exited $rc, expected 0: $(cat "$TMP/valid.stderr")"
fi

# ===========================================================================
bold "2. SC-002/S22 -- over-cap (general > 20%) -> non-zero exit AND no write"

# 2a. Positive control: a PASSING run over the 2-arg (gate+write) form DOES
#     write -- so the negative checks below aren't vacuously true because the
#     write path is simply broken or unreachable.
CONTROL_OUT="$TMP/control/categorization.md"
mkdir -p "$TMP/control"
rc=0
"$PY" "$VALIDATE" "$FIX/valid.fixture.md" "$CONTROL_OUT" >"$TMP/control.stdout" 2>"$TMP/control.stderr" || rc=$?
if [ "$rc" -eq 0 ] && [ -f "$CONTROL_OUT" ]; then
  ok "positive control: a PASSING run's 2-arg form DOES write the output path (proves the write mechanism works at all)"
else
  bad "positive control failed: rc=$rc, $CONTROL_OUT exists=$([ -f "$CONTROL_OUT" ] && echo yes || echo no)"
fi

# 2b. Gate-only form (1 arg): non-zero exit, breach reported on stderr.
rc=0
"$PY" "$VALIDATE" "$FIX/overcap.fixture.md" >"$TMP/overcap-gateonly.stdout" 2>"$TMP/overcap-gateonly.stderr" || rc=$?
if [ "$rc" -ne 0 ]; then
  ok "over-cap fixture (general 3/10 > cap 2) exits non-zero (gate-only 1-arg form)"
else
  bad "over-cap fixture exited 0, expected non-zero"
fi
if grep -qF -- 'general cap breach' "$TMP/overcap-gateonly.stderr"; then
  ok "stderr names the general cap breach"
else
  bad "stderr does not mention the cap breach: $(cat "$TMP/overcap-gateonly.stderr")"
fi

# 2c. Gate+write form (2 args), FRESH (not-yet-existing) output path: must be
#     left ABSENT -- file-state asserted directly, not just the exit code.
FRESH_OUT="$TMP/fresh/categorization.md"
mkdir -p "$TMP/fresh"
if [ -e "$FRESH_OUT" ]; then echo "FATAL: $FRESH_OUT unexpectedly pre-exists" >&2; exit 1; fi
rc=0
"$PY" "$VALIDATE" "$FIX/overcap.fixture.md" "$FRESH_OUT" >"$TMP/overcap-fresh.stdout" 2>"$TMP/overcap-fresh.stderr" || rc=$?
if [ "$rc" -ne 0 ]; then
  ok "over-cap + fresh output path: exits non-zero"
else
  bad "over-cap + fresh output path exited 0, expected non-zero"
fi
if [ ! -e "$FRESH_OUT" ]; then
  ok "fresh output path left ABSENT on breach (S22 no-write, half 1/2 -- file-state checked directly)"
else
  bad "fresh output path was CREATED on breach: $FRESH_OUT"
fi

# 2d. Gate+write form (2 args), PRE-SEEDED (stale) output path: must be left
#     BYTE-FOR-BYTE UNCHANGED -- `cmp -s` against a saved copy, not just "still
#     exists" and not just the exit code.
STALE_OUT="$TMP/stale/categorization.md"
mkdir -p "$TMP/stale"
printf 'stale pre-existing content that must survive untouched\n' >"$STALE_OUT"
cp "$STALE_OUT" "$TMP/stale/categorization.md.orig"
rc=0
"$PY" "$VALIDATE" "$FIX/overcap.fixture.md" "$STALE_OUT" >"$TMP/overcap-stale.stdout" 2>"$TMP/overcap-stale.stderr" || rc=$?
if [ "$rc" -ne 0 ]; then
  ok "over-cap + pre-seeded stale output path: exits non-zero"
else
  bad "over-cap + pre-seeded stale output path exited 0, expected non-zero"
fi
if cmp -s "$STALE_OUT" "$TMP/stale/categorization.md.orig"; then
  ok "pre-seeded stale output path left BYTE-FOR-BYTE UNCHANGED on breach (S22 no-write, half 2/2 -- cmp -s, not just exit code)"
else
  bad "pre-seeded stale output path was MODIFIED on breach"
fi

# ===========================================================================
bold "3. SC-001 -- coverage/enum/boolean/tag/task_id breaches -> non-zero exit"

check_fails() {
  # $1 = fixture path   $2 = human label   $3 = expected substring in stderr
  rc=0
  "$PY" "$VALIDATE" "$1" >"$TMP/sc001.stdout" 2>"$TMP/sc001.stderr" || rc=$?
  if [ "$rc" -ne 0 ]; then
    ok "$2 exits non-zero"
  else
    bad "$2 exited 0, expected non-zero"
  fi
  if grep -qF -- "$3" "$TMP/sc001.stderr"; then
    ok "$2 stderr names the breach (contains: $3)"
  else
    bad "$2 stderr missing expected substring [$3]: $(cat "$TMP/sc001.stderr")"
  fi
}

check_fails "$FIX/sc001-missing-field.fixture.md"    "(a) missing field (empty 'type' cell)"     "missing 'type'"
check_fails "$FIX/sc001-bad-enum.fixture.md"         "(b) out-of-enum type/specialization"       "is not a member of the closed"
check_fails "$FIX/sc001-non-boolean.fixture.md"      "(c) non-boolean preserves_behavior"        "is not a boolean"
check_fails "$FIX/sc001-non-kebab-tag.fixture.md"    "(d) non-kebab tag"                         "not lowercase-kebab"
check_fails "$FIX/sc001-duplicate-task-id.fixture.md" "(e) duplicate task_id"                    "duplicate task_id"
check_fails "$FIX/sc001-non-boolean-runtime.fixture.md" "(f) non-boolean runtime_consumed (v1, D65)" "runtime_consumed 'maybe' is not a boolean"

# ===========================================================================
bold "4. Cap boundary -- general == floor(0.20 x N) exactly -> exit 0 (> not >=)"

rc=0
"$PY" "$VALIDATE" "$FIX/cap-boundary.fixture.md" >"$TMP/boundary.stdout" 2>"$TMP/boundary.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then
  ok "cap-boundary fixture (general 2/10 == floor(0.20*10)=2) exits 0 -- the cap is '>', not '>='"
else
  bad "cap-boundary fixture exited $rc, expected 0: $(cat "$TMP/boundary.stderr")"
fi

# ===========================================================================
bold "5. v1 one-task floor (D65 verdict 9) -- max(1, floor(0.2n)) for n<5"

# 5a. A 4-task feature with ONE general task: under v0's literal 20% cap this FAILED
#     (floor(0.2*4)=0 -> zero allowed); under the v1 floor max(1,0)=1 -> PASS. This is
#     the whole point of adopting the floor -- it deletes the n<5 "zero general" absurdity.
rc=0
"$PY" "$VALIDATE" "$FIX/cap-floor-pass.fixture.md" >"$TMP/floorpass.stdout" 2>"$TMP/floorpass.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then
  ok "cap-floor-pass (general 1/4, n<5) exits 0 -- the floor admits exactly one general (v0 would have FAILED this)"
else
  bad "cap-floor-pass exited $rc, expected 0: $(cat "$TMP/floorpass.stderr")"
fi

# 5b. The SAME 4-task feature with TWO general tasks: the floor is exactly 1, so 2>1 -> FAIL.
#     Proves the floor lifts the ceiling to 1, not to "unbounded for small n".
rc=0
"$PY" "$VALIDATE" "$FIX/cap-floor-fail.fixture.md" >"$TMP/floorfail.stdout" 2>"$TMP/floorfail.stderr" || rc=$?
if [ "$rc" -ne 0 ]; then
  ok "cap-floor-fail (general 2/4, n<5) exits non-zero -- the floor is 1, not unbounded"
else
  bad "cap-floor-fail exited 0, expected non-zero"
fi
if grep -qF -- 'general cap breach' "$TMP/floorfail.stderr" && grep -qF -- 'max(1, floor' "$TMP/floorfail.stderr"; then
  ok "cap-floor-fail stderr names the floor'd cap breach (max(1, floor(...)))"
else
  bad "cap-floor-fail stderr missing the floor'd-cap breach message: $(cat "$TMP/floorfail.stderr")"
fi

# ===========================================================================
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
