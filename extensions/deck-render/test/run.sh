#!/bin/sh
#
# speckit-ext-deck-render — CI test harness skeleton (006-deck-render, T017)
#
# This file is the SHARED, serially-appended harness for the deck-render
# extension: T017 (this task) builds only the scaffold below — counters,
# temp-dir lifecycle, path resolution, and the python-pptx detection contract.
# T019-T035 each append exactly one numbered section (SC-001..SC-010, plus the
# I-B1..I-B6 invariant checks named in plan.md's Phase C) at the marked
# insertion point near the bottom of this file. No SC test bodies live here.
#
# Style mirrors extensions/git/test/run.sh and extensions/testing/test/run.sh:
# PASS/FAIL counters, colorized pass/fail/section-header helpers, a throwaway
# temp root cleaned up by an EXIT trap, and a final `Result: N passed, M
# failed` line that exits non-zero on any failure. Runs entirely in throwaway
# dirs under a temp root; never touches this repo's own specs/ or .specify/.
#
# Usage:  sh extensions/deck-render/test/run.sh
#
# ============================================================================
# CONTRACT for T019-T035 — the helper API this scaffold exposes
# ============================================================================
#
# Counters / reporting
#   pass "<label>"        record a PASS, print it green.
#   fail "<label>"        record a FAIL, print it red. Embed the "expected X,
#                          got Y" detail directly in <label> (see the
#                          exemplar harnesses for the idiom).
#   section "<title>"     print a bold section header. Purely cosmetic; call
#                          it once at the top of each appended SC section,
#                          e.g. `section "3. SC-003 fidelity, both directions"`.
#   report                 prints the final "Result: N passed, M failed" line
#                          and exits non-zero iff FAIL > 0. Called exactly
#                          once, at the very end of this file (see the
#                          insertion-point comment below). Sections must
#                          never call report() themselves.
#
# python-pptx detection (S10) — read this before writing any pptx-dependent
# section. HAVE_PPTX is computed ONCE, up front, by actually attempting
# `import pptx` under the resolved interpreter ($PY). Two helpers consume it,
# and they are DELIBERATE MIRROR IMAGES — never conflate them:
#
#   require_pptx "<label>"
#       For the SC-003 fidelity arm (and any other check that needs a REAL
#       python-pptx render to be meaningful, e.g. the I-B3 atomic-write
#       test). If HAVE_PPTX=1 it is a no-op returning 0, and the calling
#       section proceeds. If HAVE_PPTX=0 it prints an explicit "install
#       python-pptx" demand, records a FAIL, and RETURNS NON-ZERO — it does
#       NOT abort the suite, so the library-independent sections that follow
#       (SC-001/004/005/006/008/010, the dogfood + quickstart gates) still
#       run on a pptx-absent host, and SC-004's degrade arm — which is meant
#       to be exercised precisely when the library is absent — is not shut
#       out by an earlier SC-003 abort. The recorded FAIL forces a non-zero
#       SUITE exit at report(), so a pptx-dependent check can never silently
#       no-op to a 0-assertion pass (plan.md's Testing paragraph, S10) — the
#       run is loudly red, just not truncated. CALLING CONVENTION (set -e
#       safe): guard the render-dependent body with
#           if require_pptx "<label>"; then <real render + assertions>; fi
#       so the body is skipped (not aborted) when the toolchain is absent.
#
#   expect_no_pptx "<label>"
#       For the SC-004 degrade arm. Absence of python-pptx is that arm's
#       EXPECTED, default condition (confirmed absent on the dev host per
#       research.md R2 — there is no CI) — so this NEVER blocks and NEVER
#       fails, regardless of HAVE_PPTX. It only prints an informational note
#       about the ambient state, because SC-004's actual test technique (a
#       PYTHONPATH shadow that forces a real ImportError — see research.md
#       R6) is deliberately independent of whether python-pptx happens to be
#       installed on the host running the suite; the degrade path must be
#       exercised identically either way.
#
#   Do not call require_pptx for an SC-004-style check, or expect_no_pptx for
#   an SC-003-style check — that is precisely the conflation plan.md warns
#   against.
#
# Path variables (all absolute, resolved once at startup)
#   REPO                  repo root
#   DECK_EXT               extensions/deck-render
#   SCRIPTS                 $DECK_EXT/extension/scripts (installed at
#                          .specify/extensions/deck-render/scripts/ on a
#                          real target; these are the SOURCE-tree copies)
#   RENDER_PY               $SCRIPTS/render.py
#   DECK_MD_PY              $SCRIPTS/deck_md.py
#   PROFILE_KEY_PY          $SCRIPTS/profile_key.py
#   TEST_DIR                this directory (extensions/deck-render/test)
#   EXTRACT_PPTX_TEXT_PY    $TEST_DIR/extract_pptx_text.py (the INDEPENDENT
#                          stdlib OOXML extractor for SC-003 — lives beside
#                          run.sh, not under extension/scripts/, precisely
#                          because it is test-only and must never ship)
#   FIXTURES                $TEST_DIR/fixtures
#   PY                      resolved python interpreter for THIS HARNESS's
#                          own use (python3 preferred, python fallback).
#                          The shipped skill hardcodes `python3` verbatim
#                          (see skills/speckit-deck-render/SKILL.md) — PY
#                          exists only so the suite itself keeps running on a
#                          host that lacks a `python3` symlink, and MUST NOT
#                          be treated as evidence of what the real command
#                          invokes in production.
#
# Temp-dir convention
#   TMP                    one throwaway root for the whole run, removed by
#                          an EXIT trap. Each appended section creates and
#                          uses its OWN subdirectory under $TMP (e.g.
#                          "$TMP/sc003") — never share mutable fixture state
#                          across sections unless the sharing itself is the
#                          property under test (mirrors the exemplar
#                          harnesses' per-section "$TMP/<short-name>" idiom).
#
# Insertion point
#   Appended sections go IMMEDIATELY ABOVE the marked block near the end of
#   this file, in increasing numeric order. The `report` call must remain
#   the last executable line.
# ============================================================================

set -eu

# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$TEST_DIR/../../.." && pwd)"
DECK_EXT="$REPO/extensions/deck-render"
SCRIPTS="$DECK_EXT/extension/scripts"

RENDER_PY="$SCRIPTS/render.py"
DECK_MD_PY="$SCRIPTS/deck_md.py"
PROFILE_KEY_PY="$SCRIPTS/profile_key.py"
EXTRACT_PPTX_TEXT_PY="$TEST_DIR/extract_pptx_text.py"
FIXTURES="$TEST_DIR/fixtures"

# ---------------------------------------------------------------------------
# Throwaway temp root — trap-based cleanup, never touches this repo's tree
# ---------------------------------------------------------------------------
TMP="${TMPDIR:-/tmp}/speckit-deck-render-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# PASS/FAIL counters + report/section-header helpers
# ---------------------------------------------------------------------------
PASS=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  printf '  \033[32mPASS\033[0m %s\n' "${1:-}"
}

fail() {
  FAIL=$((FAIL + 1))
  printf '  \033[31mFAIL\033[0m %s\n' "${1:-}"
}

section() {
  printf '\n\033[1m%s\033[0m\n' "${1:-}"
}

report() {
  printf '\n\033[1mResult: %s passed, %s failed\033[0m\n' "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ] || exit 1
}

# ---------------------------------------------------------------------------
# Interpreter resolution — for THIS HARNESS's own use only (see CONTRACT
# above: the shipped skill always invokes `python3` literally).
# ---------------------------------------------------------------------------
PY=""
for _cand in python3 python; do
  if command -v "$_cand" >/dev/null 2>&1; then
    PY="$_cand"
    break
  fi
done
if [ -z "$PY" ]; then
  printf '\033[1;31mFATAL\033[0m no python interpreter (python3/python) found on PATH -- deck-render tests cannot run at all.\n' >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# python-pptx detection (S10) — computed ONCE, up front. See the CONTRACT
# block above for the full require_pptx / expect_no_pptx semantics; this is
# only the detection itself plus the two helper definitions.
# ---------------------------------------------------------------------------
if "$PY" -c 'import pptx' >/dev/null 2>&1; then
  HAVE_PPTX=1
else
  HAVE_PPTX=0
fi

require_pptx() {  # SC-003-class checks: fail-loud-if-absent (non-zero suite exit), never a silent 0
  _label="${1:-a python-pptx-dependent check}"
  [ "$HAVE_PPTX" -eq 1 ] && return 0
  FAIL=$((FAIL + 1))
  printf '  \033[31mFAIL\033[0m %s -- python-pptx is NOT installed on this host (detected via "%s -c '"'"'import pptx'"'"'")\n' "$_label" "$PY"
  printf '  \033[2m(hint)\033[0m install the toolchain and re-run to exercise this arm for real:  pip install python-pptx\n'
  printf '  \033[2m(note)\033[0m a python-pptx-dependent check never silently no-ops to a 0-assertion pass; this FAIL forces a non-zero SUITE exit (plan.md Testing paragraph, S10). The remaining library-independent sections still run.\n'
  return 1
}

expect_no_pptx() {  # SC-004-class checks: absence IS the expected condition
  _label="${1:-the degrade-and-disclose path}"
  if [ "$HAVE_PPTX" -eq 1 ]; then
    printf '  \033[2m(note)\033[0m %s: python-pptx IS present on this host; the degrade arm still forces a real ImportError via a PYTHONPATH shadow (research.md R6), so it is unaffected either way.\n' "$_label"
  else
    printf '  \033[2m(note)\033[0m %s: python-pptx is absent on this host -- the expected/default state (research.md R2, S10); exercising this arm directly.\n' "$_label"
  fi
}

# ---------------------------------------------------------------------------
# Up-front toolchain banner — printed once, before any section runs, so a
# human scanning the top of a run's output immediately knows which arm(s)
# are about to be exercised for real vs. which will hard-abort.
# ---------------------------------------------------------------------------
section "0. Toolchain detection"
if [ "$HAVE_PPTX" -eq 1 ]; then
  printf '  python-pptx: PRESENT (via %s) -- SC-003-class checks will render for real.\n' "$PY"
else
  printf '  python-pptx: ABSENT (via %s) -- SC-003-class checks will FAIL loud (non-zero suite exit, S10) but the suite runs on; SC-004-class checks treat this as expected.\n' "$PY"
fi

# ============================================================================
# >>> APPEND NEW "N. <title> (SC-... / I-B... / FR-...)" SECTIONS BELOW <<<
#
# Each appended section should, at minimum:
#   - open with `section "N. <title> (<ids>)"` for a readable run log
#   - create and use its own scratch dir under "$TMP/<short-name>"
#   - if its correctness depends on a REAL render, guard the render-dependent
#     body with `if require_pptx "<label>"; then ... fi` (set -e safe; the body
#     is skipped, not aborted, when python-pptx is absent — the FAIL it records
#     still forces a non-zero suite exit). Use `expect_no_pptx "<label>"` for an
#     SC-004-style degrade check. Never conflate the two.
#   - read fixtures from "$FIXTURES" rather than inventing inline decks that
#     can drift from the frozen golden fixture set
#   - report every assertion through `pass "<label>"` / `fail "<label>"`
#
# Nothing below the final `report` call. Do not move or remove it.
# ============================================================================

report
