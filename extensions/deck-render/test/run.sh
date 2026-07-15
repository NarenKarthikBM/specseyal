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

# ---------------------------------------------------------------------------
section "3. SC-003 fidelity, both directions + block sequence (S06, FR-002)"
# Bidirectional containment on the frozen fixture deck, via the INDEPENDENT
# stdlib OOXML extractor (extract_pptx_text.py) -- never a python-pptx
# round-trip, which would only prove the library round-trips its own output
# (see that module's docstring). (a) nothing dropped: every source block's
# normalized plain text is a substring of the render's extracted text. (b)
# nothing invented: every extracted run's text, minus the allowlist (stamp
# lines, `(cont.)`, slide numbers -- see the inline python helper for the one
# deliberate extension: the T3 "Preamble" slide title, structural chrome of
# the identical kind as `(cont.)`, not enumerated by data-model.md's literal
# allowlist prose but not a content claim either), is a substring of the
# source's normalized plain text. (c) block SEQUENCE (S06): a pure
# containment test cannot catch a content-present-but-reordered defect (two
# H2 sections swapped), so this additionally asserts order-of-first-
# occurrence of successive source blocks in the extracted stream.
# Normalization is whitespace-only (data-model.md Sec 4) -- Unicode is never
# folded. The SOURCE side reuses render.py's OWN T9 helper (_plain_text)
# rather than re-implementing inline-marker stripping, so the two sides stay
# apples-to-apples.
if require_pptx "SC-003 fidelity (bidirectional containment + block sequence)"; then
  SC003="$TMP/sc003"
  mkdir -p "$SC003/council/defense-deck"
  cp "$FIXTURES/deck/technical.md" "$SC003/council/defense-deck/technical.md"
  cp "$FIXTURES/deck/overview.md" "$SC003/council/defense-deck/overview.md"

  SC003_LOG="$SC003/render.log"
  sc003_render_rc=0
  "$PY" "$RENDER_PY" both --feature "$SC003" >"$SC003_LOG" 2>&1 || sc003_render_rc=$?

  if [ "$sc003_render_rc" -eq 0 ] \
     && [ -f "$SC003/renders/technical.pptx" ] \
     && [ -f "$SC003/renders/overview.pptx" ]; then
    pass "SC-003 setup -- render.py both --feature <fixture dir> exited 0 and wrote both .pptx renders"
  else
    fail "SC-003 setup -- render.py both exited $sc003_render_rc or a render is missing (see $SC003_LOG) -- fidelity checks below cannot be trusted"
  fi

  # The comparison logic itself: a small inline python3 helper (the harness
  # already shells to python for every other pptx-dependent check). Written
  # to a scratch file rather than a `python3 -c` one-liner purely for
  # readability; it never ships (lives only under $TMP).
  SC003_CHECK_PY="$SC003/check_fidelity.py"
  cat > "$SC003_CHECK_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-003 bidirectional fidelity + block-sequence checker (T019 inline helper).

Invoked once by run.sh's SC-003 section for both fixture decks together.
Reuses render.py's OWN T9 inline-stripping helper (`_plain_text`) to
normalize the SOURCE side, so the two sides of the comparison are
apples-to-apples (data-model.md Sec 4) rather than a second, drift-prone
reimplementation of T9. Reads the render back ONLY through the independent
stdlib extractor (extract_pptx_text.py) -- never through python-pptx --
mirroring that module's own "independent oracle" rationale.

Prints one result per line to stdout, "RESULT <PASS|FAIL> <label>". run.sh
reads this back from a temp FILE (never a pipe, so its PASS/FAIL counters
are not evaluated inside a subshell) and calls its own pass()/fail().
"""
import re
import sys
import zipfile
from pathlib import Path

SCRIPTS_DIR, EXTRACT_PY_DIR, FEATURE_DIR = sys.argv[1], sys.argv[2], sys.argv[3]

sys.path.insert(0, SCRIPTS_DIR)
sys.path.insert(0, EXTRACT_PY_DIR)

import deck_md                # noqa: E402
import render as render_mod   # noqa: E402 -- module under test; pptx is NOT imported at its top level
import extract_pptx_text      # noqa: E402 -- the independent stdlib OOXML extractor

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")  # Unicode (curly quotes, arrows) survives regardless of host locale

feature_dir = Path(FEATURE_DIR)

_WS_RE = re.compile(r"\s+")


def normalize(s):
    """Whitespace-only normalization (data-model.md Sec 4): collapse any run
    of whitespace to a single ASCII space, strip the ends. Every other
    character -- curly quotes, arrows, box-drawing -- passes through
    untouched; Unicode is never folded.
    """
    return _WS_RE.sub(" ", s).strip()


_SHA_RE = re.compile(r"Source SHA-256: [0-9a-f]{64}")


def emit(verdict, label):
    label = normalize(label)
    if len(label) > 240:
        label = label[:240] + " ...(truncated)"
    print("RESULT %s %s" % (verdict, label))


def block_plain_text(block):
    """The exact text render.py's OWN construction produces for one block's
    run sequence, concatenated with NO separator -- mirrors
    `_tokenize_inline`'s documented invariant (segments concatenate back to
    the marker-stripped text exactly), so this reconstruction is
    byte-identical to what ends up in the pptx's <a:t> runs for that block,
    before whitespace normalization is applied by the caller.
    """
    if block.kind == deck_md.NUMBERED:
        return "%s. %s" % (block.number, render_mod._plain_text(block.text))
    if block.kind in (deck_md.H1, deck_md.H2, deck_md.H3, deck_md.PARAGRAPH,
                      deck_md.BULLET, deck_md.BLOCKQUOTE):
        return render_mod._plain_text(block.text)
    if block.kind == deck_md.TABLE:
        cells = list(block.header) + [c for row in block.rows for c in row]
        return "".join(render_mod._plain_text(c) for c in cells)
    if block.kind == deck_md.CODE:
        return "".join(block.lines)
    return ""  # HR: structural, carries no text (T8) -- never reached, callers filter HR out


def table_cell_pieces(block):
    for c in block.header:
        yield render_mod._plain_text(c)
    for row in block.rows:
        for c in row:
            yield render_mod._plain_text(c)


def sequence_anchor(block):
    """A single, reasonably short, LOCATABLE substring for the (c) ordering
    check. For TABLE/CODE blocks this is deliberately the first non-empty
    cell/line rather than the whole glued block (already validated in full
    by the (a) per-cell/per-line checks) -- a shorter anchor is more robust
    against any OOXML serialization quirk between cells/paragraphs, and a
    repeated anchor (e.g. two tables both starting "Risk") still proves
    order correctly: a monotonically-advancing `.find()` locates the NEXT
    occurrence after the previous block's position either way.
    """
    if block.kind == deck_md.TABLE:
        for c in table_cell_pieces(block):
            t = normalize(c)
            if t:
                return t
        return ""
    if block.kind == deck_md.CODE:
        for ln in block.lines:
            t = normalize(ln)
            if t:
                return t
        return ""
    return normalize(block_plain_text(block))


def check_deck(deck):
    src_path = feature_dir / "council" / "defense-deck" / ("%s.md" % deck)
    pptx_path = feature_dir / "renders" / ("%s.pptx" % deck)
    label_prefix = "SC-003 %s" % deck

    if not pptx_path.is_file():
        emit("FAIL", "%s setup -- no render at %s (render step did not produce a file)" % (label_prefix, pptx_path))
        return

    text = src_path.read_bytes().decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")
    try:
        blocks = deck_md.parse(text)
    except deck_md.DeckMdError as exc:
        emit("FAIL", "%s setup -- fixture source failed deck_md.parse(): %s" % (label_prefix, exc))
        return

    non_hr_blocks = [b for b in blocks if b.kind != deck_md.HR]

    # ---- render-side extraction (independent of python-pptx) --------------
    runs = extract_pptx_text.extract_runs(str(pptx_path))
    # Zero-separator join: mirrors render.py's OWN zero-separator run
    # concatenation WITHIN a shape (_tokenize_inline's invariant) -- using
    # any non-empty separator here would break a real corpus case (an inline
    # code span glued directly to the next word, e.g. "...installer `rm
    # -rf`+`cp`s these trees..." in the technical fixture) by inserting a
    # word-break that never existed in the source.
    render_glued = "".join(runs)
    render_glued_norm = normalize(render_glued)

    with zipfile.ZipFile(pptx_path) as zf:
        slide_count = len(extract_pptx_text._numbered_slide_members(zf.namelist()))

    # ---- (a) nothing dropped -----------------------------------------------
    missing = []
    checked_pieces = 0
    for b in non_hr_blocks:
        if b.kind == deck_md.TABLE:
            pieces = [("line %d table cell %d" % (b.line, i), p) for i, p in enumerate(table_cell_pieces(b), 1)]
        elif b.kind == deck_md.CODE:
            pieces = [("line %d code line %d" % (b.line, i), ln) for i, ln in enumerate(b.lines, 1)]
        else:
            pieces = [("line %d %s" % (b.line, b.kind), block_plain_text(b))]
        for piece_label, piece_text in pieces:
            piece_norm = normalize(piece_text)
            if not piece_norm:
                continue
            checked_pieces += 1
            if piece_norm not in render_glued_norm:
                missing.append("%s: %r" % (piece_label, piece_norm))
    if missing:
        emit("FAIL", "%s (a) nothing dropped -- %d piece(s) missing from the render, e.g. %s" % (label_prefix, len(missing), missing[0]))
    else:
        emit("PASS", "%s (a) nothing dropped -- all %d source block piece(s) (%d block(s)) found in the render's extracted text" % (label_prefix, checked_pieces, len(non_hr_blocks)))

    # ---- (b) nothing invented -----------------------------------------------
    source_whole_norm = normalize("\n".join(block_plain_text(b) for b in non_hr_blocks))
    expected_source_line = "Source: %s" % src_path.as_posix()
    invented = []
    for i, run_text in enumerate(runs):
        remainder = run_text
        remainder = _SHA_RE.sub("", remainder)
        remainder = remainder.replace(render_mod.STAMP_DECLARATION, "")
        remainder = remainder.replace(render_mod.STAMP_POINTER, "")
        remainder = remainder.replace(expected_source_line, "")
        remainder = remainder.replace("(cont.)", "")
        # T3's fixed "Preamble" slide title: structural chrome injected by
        # the SAME rule-class as `(cont.)` (a slide title, never a content
        # claim) -- data-model.md Sec 4's allowlist prose does not spell it
        # out alongside the stamp/(cont.)/slide-number trio, but it is the
        # identical kind of addition, so it is allowlisted here too.
        remainder = remainder.replace("Preamble", "")
        remainder_norm = normalize(remainder)
        if not remainder_norm:
            continue
        if re.fullmatch(r"\d+", remainder_norm):
            n = int(remainder_norm)
            if 1 <= n <= slide_count:
                continue  # allowlisted slide number
        if remainder_norm not in source_whole_norm:
            invented.append("run %d: %r" % (i, remainder_norm))
    if invented:
        emit("FAIL", "%s (b) nothing invented -- %d extracted run(s) not traceable to the source (minus the allowlist), e.g. %s" % (label_prefix, len(invented), invented[0]))
    else:
        emit("PASS", "%s (b) nothing invented -- all %d extracted run(s) (minus the stamp/(cont.)/Preamble/slide-number allowlist) trace back to the source" % (label_prefix, len(runs)))

    # ---- (c) block sequence (S06) -------------------------------------------
    search_pos = 0
    out_of_order = None
    checked_blocks = 0
    for b in non_hr_blocks:
        anchor = sequence_anchor(b)
        if not anchor:
            continue
        idx = render_glued_norm.find(anchor, search_pos)
        if idx == -1:
            out_of_order = "line %d %s anchor %r not found at or after the prior block's render position (dropped, or rendered out of source order)" % (b.line, b.kind, anchor[:60])
            break
        search_pos = idx + len(anchor)
        checked_blocks += 1
    if out_of_order:
        emit("FAIL", "%s (c) block sequence (S06) -- %s" % (label_prefix, out_of_order))
    else:
        emit("PASS", "%s (c) block sequence (S06) -- %d block(s) appear in the render in source order (order-of-first-occurrence)" % (label_prefix, checked_blocks))


for deck_name in ("technical", "overview"):
    try:
        check_deck(deck_name)
    except Exception as exc:  # noqa: BLE001 -- isolate one deck's crash from the other (I-B2 idiom)
        emit("FAIL", "SC-003 %s -- checker crashed: %r" % (deck_name, exc))
PYEOF

  SC003_RESULTS="$SC003/results.txt"
  sc003_check_rc=0
  "$PY" "$SC003_CHECK_PY" "$SCRIPTS" "$TEST_DIR" "$SC003" > "$SC003_RESULTS" 2>"$SC003/check_fidelity.err" || sc003_check_rc=$?

  if [ "$sc003_check_rc" -ne 0 ]; then
    fail "SC-003 fidelity checker exited $sc003_check_rc (a bug in the checker itself, not necessarily in render.py) -- see $SC003/check_fidelity.err"
  fi

  sc003_result_count=0
  # Read from a FILE, never a pipe: piping into `while read` would run the
  # loop body in a subshell, and pass()/fail() updating PASS/FAIL there would
  # be lost the moment the pipeline exits (a real POSIX-sh subshell trap).
  while read -r sc003_tag sc003_verdict sc003_label; do
    [ "$sc003_tag" = "RESULT" ] || continue
    sc003_result_count=$((sc003_result_count + 1))
    case "$sc003_verdict" in
      PASS) pass "$sc003_label" ;;
      FAIL) fail "$sc003_label" ;;
      *) fail "SC-003 checker produced an unparseable result line: $sc003_tag $sc003_verdict $sc003_label" ;;
    esac
  done < "$SC003_RESULTS"

  if [ "$sc003_result_count" -eq 0 ] && [ "$sc003_check_rc" -eq 0 ]; then
    fail "SC-003 fidelity checker produced zero result lines -- a silent 0-assertion pass, which S10's discipline forbids"
  fi
fi

# ---------------------------------------------------------------------------
section "2. SC-002 derived-render stamp (FR-003, I-B5)"
# The derived-render stamp (data-model.md Sec 3): a stakeholder holding only
# the .pptx must never mistake it for the reviewed markdown. Two placements,
# checked independently, both against the FROZEN fixture deck:
#   - Slide 1 (the title slide) carries the FULL 4-element stamp: the
#     declaration, the source path, the full 64-hex source sha256, and the
#     pointer sentence.
#   - EVERY slide's footer carries the ABBREVIATED stamp -- declaration + the
#     source sha256 -- where "abbreviated" means the source-path and pointer
#     are dropped, NOT that the hash itself is shortened (plan I-B5: the SHA
#     is never truncated to a 7-8 hex git-style abbreviation; its full
#     64-hex length is what makes it self-evidently not a git commit SHA).
# The embedded sha256 is compared against an INDEPENDENTLY computed
# hashlib.sha256() of the source markdown's bytes -- never trusting
# render.py's own arithmetic -- which is exactly the equality SC-007's
# later staleness check relies on. Text is pulled per-slide straight out of
# the raw OOXML (zipfile + xml.etree over ppt/slides/slideN.xml), the same
# independent-oracle technique extract_pptx_text.py documents, kept
# per-slide here (rather than flattened) so a stamp element can be
# attributed to slide 1 specifically vs. every slide's footer.
if require_pptx "SC-002 derived-render stamp"; then
  SC002="$TMP/sc002"
  mkdir -p "$SC002/council/defense-deck"
  cp "$FIXTURES/deck/technical.md" "$SC002/council/defense-deck/technical.md"
  cp "$FIXTURES/deck/overview.md" "$SC002/council/defense-deck/overview.md"

  SC002_LOG="$SC002/render.log"
  sc002_render_rc=0
  "$PY" "$RENDER_PY" both --feature "$SC002" >"$SC002_LOG" 2>&1 || sc002_render_rc=$?

  if [ "$sc002_render_rc" -eq 0 ] \
     && [ -f "$SC002/renders/technical.pptx" ] \
     && [ -f "$SC002/renders/overview.pptx" ]; then
    pass "SC-002 setup -- render.py both --feature <fixture dir> exited 0 and wrote both .pptx renders"
  else
    fail "SC-002 setup -- render.py both exited $sc002_render_rc or a render is missing (see $SC002_LOG) -- stamp checks below cannot be trusted"
  fi

  # The comparison logic itself: a small inline python3 helper, written to a
  # scratch file (never a `python3 -c` one-liner) purely for readability --
  # it never ships (lives only under $TMP). Mirrors the SC-003 section's own
  # idiom immediately above.
  SC002_CHECK_PY="$SC002/check_stamp.py"
  cat > "$SC002_CHECK_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-002 derived-render stamp checker (T020 inline helper).

Invoked once by run.sh's SC-002 section for both fixture decks together.
Reads each render's slide text directly out of the raw OOXML, per slide
(zipfile + xml.etree over ppt/slides/slideN.xml, the same independent-oracle
technique extract_pptx_text.py documents and check_fidelity.py's own
_numbered_slide_members() precedent already relies on) -- never through
python-pptx, and never flattened across slides, so a stamp element can be
attributed to slide 1 (the title slide) specifically vs. every slide's
footer.

Prints one result per line to stdout, "RESULT <PASS|FAIL> <label>". run.sh
reads this back from a temp FILE (never a pipe, so its PASS/FAIL counters
are not evaluated inside a subshell) and calls its own pass()/fail().
"""
import hashlib
import re
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree

SCRIPTS_DIR, EXTRACT_PY_DIR, FEATURE_DIR = sys.argv[1], sys.argv[2], sys.argv[3]

sys.path.insert(0, SCRIPTS_DIR)
sys.path.insert(0, EXTRACT_PY_DIR)

import render as render_mod   # noqa: E402 -- STAMP_DECLARATION / STAMP_POINTER, the exact stamp strings
import extract_pptx_text      # noqa: E402 -- the independent stdlib OOXML slide reader

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")  # Unicode survives regardless of host locale

feature_dir = Path(FEATURE_DIR)

# The full, never-truncated 64-hex sha256 -- the SAME pattern render.py's
# own I-B6 reader (`_SHA256_RE`) uses to read a prior render's stamp back.
# A truncated/abbreviated hash (a 7-8 hex git-style abbreviation) simply
# will not match this pattern, which is precisely how "abbreviated must
# never mean shortened" (plan I-B5) gets enforced here: no match -> FAIL.
_SHA256_RE = re.compile(r"\b([0-9a-f]{64})\b")


def emit(verdict, label):
    label = " ".join(label.split())
    if len(label) > 240:
        label = label[:240] + " ...(truncated)"
    print("RESULT %s %s" % (verdict, label))


def slide_texts(pptx_path):
    """list of lists: one entry per numbered slide (sorted numerically, the
    same convention extract_pptx_text.extract_runs() uses), each holding
    that slide's ordered <a:t> run texts. Kept per-slide rather than
    flattened across the whole deck so a stamp element can be attributed to
    a SPECIFIC slide (slide 1's full stamp vs. every slide's footer).
    """
    with zipfile.ZipFile(pptx_path) as archive:
        numbered = extract_pptx_text._numbered_slide_members(archive.namelist())
        numbered.sort(key=lambda pair: pair[0])
        out = []
        for _, member_name in numbered:
            slide_xml = archive.read(member_name)
            root = ElementTree.fromstring(slide_xml)
            texts = [t.text if t.text is not None else "" for t in root.iter(extract_pptx_text._A_T_TAG)]
            out.append(texts)
        return out


def check_deck(deck):
    src_path = feature_dir / "council" / "defense-deck" / ("%s.md" % deck)
    pptx_path = feature_dir / "renders" / ("%s.pptx" % deck)
    label_prefix = "SC-002 %s" % deck

    if not pptx_path.is_file():
        emit("FAIL", "%s setup -- no render at %s (render step did not produce a file)" % (label_prefix, pptx_path))
        return

    source_bytes = src_path.read_bytes()
    # data-model.md Sec 3 / research.md R3: sha256 of the source markdown's
    # BYTES, computed INDEPENDENTLY here rather than trusting render.py's
    # own arithmetic -- this equality is what SC-007's later staleness check
    # relies on being trustworthy.
    expected_sha = hashlib.sha256(source_bytes).hexdigest()

    try:
        slides = slide_texts(pptx_path)
    except Exception as exc:
        emit("FAIL", "%s setup -- could not read slide XML via zipfile+ElementTree: %r" % (label_prefix, exc))
        return

    if not slides:
        emit("FAIL", "%s setup -- render has zero slides" % label_prefix)
        return

    title_joined = "\n".join(slides[0])

    # ---- slide 1: the FULL 4-element stamp (data-model.md Sec 3) -----------
    expected_source_line = "Source: %s" % src_path.as_posix()
    expected_sha_line = "Source SHA-256: %s" % expected_sha
    title_elements = [
        ("declaration (%r)" % render_mod.STAMP_DECLARATION, render_mod.STAMP_DECLARATION in title_joined),
        ("source path (%r)" % expected_source_line, expected_source_line in title_joined),
        ("full 64-hex source sha256 (%r)" % expected_sha_line, expected_sha_line in title_joined),
        ("pointer sentence (%r)" % render_mod.STAMP_POINTER, render_mod.STAMP_POINTER in title_joined),
    ]
    missing = [name for name, present in title_elements if not present]
    if missing:
        emit("FAIL", "%s title slide (slide 1) full stamp -- missing element(s): %s" % (label_prefix, "; ".join(missing)))
    else:
        emit("PASS", "%s title slide (slide 1) full stamp -- all 4 elements present: declaration, source path, full 64-hex source sha256, pointer sentence" % label_prefix)

    # ---- sha256 equality, independent of the literal "Source SHA-256: " ----
    # label text matching -- extracted via the same 64-hex regex render.py's
    # OWN I-B6 reader uses, so this equality stands on its own even if the
    # title-slide element check above were ever weakened.
    title_sha_match = _SHA256_RE.search(title_joined)
    if title_sha_match is None:
        emit("FAIL", "%s sha256 equality -- no full 64-hex string found anywhere on the title slide (a truncated/abbreviated hash would fail exactly here, per plan I-B5)" % label_prefix)
    elif title_sha_match.group(1) != expected_sha:
        emit("FAIL", "%s sha256 equality -- title slide's embedded sha256 (%s) != hashlib.sha256(<source bytes>) computed independently here (%s)" % (label_prefix, title_sha_match.group(1), expected_sha))
    else:
        emit("PASS", "%s sha256 equality -- title slide's embedded sha256 == hashlib.sha256(<source markdown bytes>).hexdigest(), independently recomputed here (%s)" % (label_prefix, expected_sha))

    # ---- every slide's footer: abbreviated stamp = declaration + FULL ------
    # 64-hex sha256 (I-B5: "abbreviated" drops the source-path + pointer, it
    # does NOT shorten the hash -- a 7-8 hex git-style abbreviation is a FAIL
    # here, caught by _SHA256_RE simply failing to match it).
    bad_footers = []
    for idx, texts in enumerate(slides, start=1):
        joined = "\n".join(texts)
        has_decl = render_mod.STAMP_DECLARATION in joined
        sha_match = _SHA256_RE.search(joined)
        if not has_decl or sha_match is None:
            bad_footers.append(
                "slide %d: declaration_present=%s full_64_hex_sha_present=%s"
                % (idx, has_decl, sha_match is not None)
            )
        elif sha_match.group(1) != expected_sha:
            bad_footers.append(
                "slide %d: footer sha256 (%s) != source sha256 (%s)"
                % (idx, sha_match.group(1), expected_sha)
            )
    if bad_footers:
        emit("FAIL", "%s every-slide footer stamp -- %d of %d slide(s) missing the declaration or a full 64-hex sha256 matching the source, e.g. %s" % (label_prefix, len(bad_footers), len(slides), bad_footers[0]))
    else:
        emit("PASS", "%s every-slide footer stamp -- all %d slide(s) carry the declaration + the full 64-hex source sha256 (never truncated, plan I-B5)" % (label_prefix, len(slides)))


for deck_name in ("technical", "overview"):
    try:
        check_deck(deck_name)
    except Exception as exc:  # noqa: BLE001 -- isolate one deck's crash from the other (I-B2 idiom)
        emit("FAIL", "SC-002 %s -- checker crashed: %r" % (deck_name, exc))
PYEOF

  SC002_RESULTS="$SC002/results.txt"
  sc002_check_rc=0
  "$PY" "$SC002_CHECK_PY" "$SCRIPTS" "$TEST_DIR" "$SC002" > "$SC002_RESULTS" 2>"$SC002/check_stamp.err" || sc002_check_rc=$?

  if [ "$sc002_check_rc" -ne 0 ]; then
    fail "SC-002 stamp checker exited $sc002_check_rc (a bug in the checker itself, not necessarily in render.py) -- see $SC002/check_stamp.err"
  fi

  sc002_result_count=0
  # Read from a FILE, never a pipe: piping into `while read` would run the
  # loop body in a subshell, and pass()/fail() updating PASS/FAIL there would
  # be lost the moment the pipeline exits (mirrors the SC-003 section above).
  while read -r sc002_tag sc002_verdict sc002_label; do
    [ "$sc002_tag" = "RESULT" ] || continue
    sc002_result_count=$((sc002_result_count + 1))
    case "$sc002_verdict" in
      PASS) pass "$sc002_label" ;;
      FAIL) fail "$sc002_label" ;;
      *) fail "SC-002 checker produced an unparseable result line: $sc002_tag $sc002_verdict $sc002_label" ;;
    esac
  done < "$SC002_RESULTS"

  if [ "$sc002_result_count" -eq 0 ] && [ "$sc002_check_rc" -eq 0 ]; then
    fail "SC-002 stamp checker produced zero result lines -- a silent 0-assertion pass, which S10's discipline forbids"
  fi

  # ---- the one irreducibly manual step (quickstart.md Scenario 3) ---------
  # SC-002 also requires the file to "open in a standard presentation viewer
  # without a repair prompt" -- no mechanical check in this suite can assert
  # that on the reader's behalf. Printed as a clearly-labeled (manual) note,
  # never folded into pass()/fail() and never counted as an automated pass.
  printf '  \033[2m(manual)\033[0m SC-002 -- "opens in a standard presentation viewer without a repair prompt" (quickstart.md Scenario 3) is NOT asserted by this suite; open %s and %s by hand to confirm.\n' \
    "$SC002/renders/technical.pptx" "$SC002/renders/overview.pptx"
fi

# ---------------------------------------------------------------------------
section "7. T7 overflow -- (cont.) continuation reached + deterministic split (S08)"
# T7 (data-model.md Sec 4): a logical slide whose body exceeds the fixed
# LINE_BUDGET_PER_SLIDE constant is split onto one or more further physical
# slides, each titled "<section title> (cont.)" -- the one piece of invented
# text T7 allowlists (SC-003's own (b) check already treats it that way).
# The frozen fixture technical.md is confirmed (PROVENANCE.md) to force this
# branch as seeded: 12 of its 20 physical slides are (cont.) continuations,
# the risk register's one High-likelihood mitigation (long table cells).
# Two properties are asserted here, independently of the SC-002/SC-003
# sections above:
#   (1) the fixture actually REACHES the branch in a real, assembled .pptx --
#       not just in render.py's pure-python split (which PROVENANCE.md
#       already recorded at freeze time), but in the slide titles a real
#       viewer would open.
#   (2) the split is DETERMINISTIC (I6, contracts/commands.md: same input
#       bytes -> byte-comparable output CONTENT): the SAME source path
#       rendered TWICE, sequentially, produces content-identical results --
#       same slide count, same (cont.) placement, identical extracted text
#       per slide. Deliberately the SAME feature directory (not two separate
#       ones): render.py's own stamp embeds the source path itself
#       (`Source: <path>`, data-model.md Sec 3), so two DIFFERENT feature
#       directories would legitimately differ on that one line even with
#       byte-identical source CONTENT -- that is render.py behaving
#       correctly (SC-002 already covers it), not the I6 property this
#       section exists to isolate. The first render's output is copied out
#       before the second render's atomic os.replace() (I-B3) overwrites it
#       at the same target path, so both copies are compared afterward.
#       "Content-identical" is asserted via extract_pptx_text-style raw XML
#       reads, NEVER a byte-for-byte zip comparison -- a .pptx zip's own
#       member metadata (timestamps, compression bookkeeping) carries no
#       determinism promise from I6, which is scoped to output CONTENT, not
#       the zip container.
if require_pptx "T7 overflow / determinism (S08)"; then
  T7="$TMP/t7"
  mkdir -p "$T7/feature/council/defense-deck"
  cp "$FIXTURES/deck/technical.md" "$T7/feature/council/defense-deck/technical.md"

  T7_PPTX_A="$T7/render_a.pptx"
  T7_PPTX_B="$T7/render_b.pptx"
  T7_LOG_A="$T7/render_a.log"
  T7_LOG_B="$T7/render_b.log"
  t7_rc_a=0
  t7_rc_b=0
  "$PY" "$RENDER_PY" technical --feature "$T7/feature" >"$T7_LOG_A" 2>&1 || t7_rc_a=$?
  if [ -f "$T7/feature/renders/technical.pptx" ]; then
    cp "$T7/feature/renders/technical.pptx" "$T7_PPTX_A"
  fi
  "$PY" "$RENDER_PY" technical --feature "$T7/feature" >"$T7_LOG_B" 2>&1 || t7_rc_b=$?
  if [ -f "$T7/feature/renders/technical.pptx" ]; then
    cp "$T7/feature/renders/technical.pptx" "$T7_PPTX_B"
  fi

  if [ "$t7_rc_a" -eq 0 ] && [ -f "$T7_PPTX_A" ] \
     && [ "$t7_rc_b" -eq 0 ] && [ -f "$T7_PPTX_B" ]; then
    pass "T7 setup -- render.py technical --feature <fixture dir> exited 0 and wrote a .pptx render on BOTH sequential renders of the IDENTICAL source path (see $T7_LOG_A, $T7_LOG_B)"
  else
    fail "T7 setup -- render.py technical exited $t7_rc_a (render 1) / $t7_rc_b (render 2) or a render is missing -- overflow/determinism checks below cannot be trusted (see $T7_LOG_A, $T7_LOG_B)"
  fi

  # The comparison logic itself: an inline python3 helper, written to a
  # scratch file (never a `python3 -c` one-liner) purely for readability --
  # it never ships (lives only under $TMP). Mirrors the SC-003/SC-002
  # sections' own idiom above.
  T7_CHECK_PY="$T7/check_overflow.py"
  cat > "$T7_CHECK_PY" <<'PYEOF'
#!/usr/bin/env python3
"""T7 overflow + determinism checker (T021 inline helper).

Invoked once by run.sh's T7 section, after the SAME fixture source has been
rendered TWICE into two independent feature directories. Two properties are
checked:

  (1) the fixture REACHES the T7 (cont.) overflow branch in a real,
      assembled .pptx -- not merely in render.py's pure-python split (which
      PROVENANCE.md already records at freeze time), but in the slide titles
      a real viewer would open. The "expected" split is computed by calling
      render.py's OWN `_to_logical_slides()` / `_split_for_overflow()`
      directly on the fixture source -- reusing the module under test's own
      T7 logic (the same idiom the SC-003/SC-002 checkers already use for
      `_plain_text()`), never a second, drift-prone reimplementation of the
      line-budget arithmetic -- and then asserted to MATCH what actually
      landed in each render's slide titles.
  (2) the split is DETERMINISTIC (I6: same input bytes -> byte-comparable
      output CONTENT): the two independent renders' extracted slide text is
      compared for exact equality. This is content identity, never a
      byte-for-byte zip comparison -- a .pptx zip's own member metadata
      carries no determinism promise from I6.

Slide text is read directly out of the raw OOXML (zipfile + xml.etree over
ppt/slides/slideN.xml), the same independent-oracle technique
extract_pptx_text.py documents and the SC-002 checker's own slide_texts()
precedent already relies on -- never through python-pptx, and kept
per-slide (not flattened) so a physical slide's TITLE (its first <a:t> run,
per render.py's own `_assemble_presentation()` shape-construction order:
the title textbox is added first among a physical slide's shapes, before
the body/footer/slide-number shapes) can be compared against render.py's
own expected title strings.

Prints one result per line to stdout, "RESULT <PASS|FAIL> <label>". run.sh
reads this back from a temp FILE (never a pipe, so its PASS/FAIL counters
are not evaluated inside a subshell) and calls its own pass()/fail().
"""
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree

SCRIPTS_DIR, EXTRACT_PY_DIR, PPTX_A, PPTX_B, FIXTURE_MD = sys.argv[1:6]

sys.path.insert(0, SCRIPTS_DIR)
sys.path.insert(0, EXTRACT_PY_DIR)

import deck_md                # noqa: E402
import render as render_mod   # noqa: E402 -- module under test; pptx is NOT imported at its top level
import extract_pptx_text      # noqa: E402 -- the independent stdlib OOXML extractor (_numbered_slide_members, _A_T_TAG)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")  # Unicode survives regardless of host locale

# PROVENANCE.md's committed golden shape for this frozen fixture (recorded
# when technical.md was frozen under test/fixtures/deck/) -- pinned here so
# a silent drift in the fixture OR in render.py's T7 arithmetic is caught,
# not just "some overflow happened."
_PROVENANCE_CONT_COUNT = 12
_PROVENANCE_TOTAL_PHYSICAL = 20


def emit(verdict, label):
    label = " ".join(label.split())
    if len(label) > 240:
        label = label[:240] + " ...(truncated)"
    print("RESULT %s %s" % (verdict, label))


def slide_texts(pptx_path):
    """list of lists: one entry per numbered slide (sorted numerically),
    each holding that slide's ordered <a:t> run texts -- mirrors the SC-002
    checker's own slide_texts() precedent."""
    with zipfile.ZipFile(pptx_path) as archive:
        numbered = extract_pptx_text._numbered_slide_members(archive.namelist())
        numbered.sort(key=lambda pair: pair[0])
        out = []
        for _, member_name in numbered:
            slide_xml = archive.read(member_name)
            root = ElementTree.fromstring(slide_xml)
            texts = [t.text if t.text is not None else "" for t in root.iter(extract_pptx_text._A_T_TAG)]
            out.append(texts)
        return out


def physical_titles(slides):
    """The title text of every PHYSICAL slide (everything after slide 1, the
    title slide) -- render.py's `_assemble_presentation()` adds the title
    textbox first among a physical slide's shapes, so its first <a:t> run IS
    the title, exactly as `_split_for_overflow()` computed it."""
    return [texts[0] if texts else "" for texts in slides[1:]]


# ---- (1) the expected split, via render.py's OWN T7 helpers ---------------
fixture_path = Path(FIXTURE_MD)
source_text = fixture_path.read_bytes().decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")

try:
    blocks = deck_md.parse(source_text)
    logical = render_mod._to_logical_slides(blocks)
    physical = render_mod._split_for_overflow(logical)
    expected_titles = [title for title, _items in physical]
    expected_cont_count = sum(1 for t in expected_titles if "(cont.)" in t)
except Exception as exc:  # noqa: BLE001 -- isolate the setup step's own crash (I-B2 idiom)
    emit("FAIL", "T7 setup -- could not compute the expected split via render.py's own _to_logical_slides()/_split_for_overflow(): %r" % exc)
    expected_titles = None
    expected_cont_count = None

if expected_titles is not None:
    if expected_cont_count >= 1:
        emit("PASS", "T7 fixture forces overflow (render.py's own split) -- %d of %d physical slide(s) computed by _split_for_overflow() carry the (cont.) marker (>=1 required, S08)" % (expected_cont_count, len(expected_titles)))
    else:
        emit("FAIL", "T7 fixture forces overflow (render.py's own split) -- 0 of %d physical slide(s) carry (cont.); the frozen fixture no longer forces the T7 branch (PROVENANCE.md recorded %d/%d at freeze time)" % (len(expected_titles), _PROVENANCE_CONT_COUNT, _PROVENANCE_TOTAL_PHYSICAL))

    if expected_cont_count == _PROVENANCE_CONT_COUNT and len(expected_titles) == _PROVENANCE_TOTAL_PHYSICAL:
        emit("PASS", "T7 matches PROVENANCE.md's committed golden shape -- %d (cont.) slide(s) of %d physical slide(s), exactly as recorded when technical.md was frozen" % (expected_cont_count, len(expected_titles)))
    else:
        emit("FAIL", "T7 PROVENANCE.md drift -- render.py's own split now computes %d (cont.) of %d physical slide(s), but PROVENANCE.md records %d of %d at freeze time; per golden-fixture discipline this is either a real regression or a deliberate, reviewed re-seed that PROVENANCE.md must be updated to match -- never a silent drift" % (expected_cont_count, len(expected_titles), _PROVENANCE_CONT_COUNT, _PROVENANCE_TOTAL_PHYSICAL))


# ---- (1b) the REAL renders actually reach the branch, per render ----------
def check_render_reaches_overflow(label, pptx_path):
    try:
        slides = slide_texts(pptx_path)
    except Exception as exc:  # noqa: BLE001 -- isolate this render's own crash from the other (I-B2 idiom)
        emit("FAIL", "%s setup -- could not read slide XML via zipfile+ElementTree: %r" % (label, exc))
        return None
    if len(slides) < 2:
        emit("FAIL", "%s -- render has %d slide(s), expected a title slide plus >=1 physical slide" % (label, len(slides)))
        return None
    titles = physical_titles(slides)
    cont_titles = [t for t in titles if "(cont.)" in t]
    if len(cont_titles) >= 1:
        emit("PASS", "%s reaches the (cont.) branch in the assembled .pptx -- %d of %d physical slide(s) carry the marker in their title (>=1 required, S08)" % (label, len(cont_titles), len(titles)))
    else:
        emit("FAIL", "%s does not reach the (cont.) branch in the assembled .pptx -- 0 of %d physical slide(s) carry the marker" % (label, len(titles)))
    if expected_titles is not None:
        if titles == expected_titles:
            emit("PASS", "%s physical slide titles exactly match render.py's own _split_for_overflow() output, in order (%d title(s), %d carrying (cont.))" % (label, len(titles), len(cont_titles)))
        else:
            first_diff = next((i for i, (a, b) in enumerate(zip(titles, expected_titles)) if a != b), min(len(titles), len(expected_titles)))
            got = titles[first_diff] if first_diff < len(titles) else None
            want = expected_titles[first_diff] if first_diff < len(expected_titles) else None
            emit("FAIL", "%s physical slide titles diverge from render.py's own _split_for_overflow() output at index %d: rendered %r vs expected %r" % (label, first_diff, got, want))
    return slides


slides_a = check_render_reaches_overflow("T7 run_a", PPTX_A)
slides_b = check_render_reaches_overflow("T7 run_b", PPTX_B)

# ---- (2) determinism: the SAME source rendered TWICE is content-identical -
if slides_a is not None and slides_b is not None:
    if len(slides_a) != len(slides_b):
        emit("FAIL", "T7 determinism -- slide COUNT differs between the two independent renders of the identical source: run_a=%d run_b=%d" % (len(slides_a), len(slides_b)))
    else:
        emit("PASS", "T7 determinism -- both independent renders of the identical source produced the same slide count (%d)" % len(slides_a))

    titles_a = physical_titles(slides_a)
    titles_b = physical_titles(slides_b)
    if titles_a == titles_b:
        emit("PASS", "T7 determinism -- (cont.) placement is identical between the two independent renders (%d physical slide title(s) compared, %d carrying (cont.) in each)" % (len(titles_a), sum(1 for t in titles_a if "(cont.)" in t)))
    else:
        cont_idx_a = [i for i, t in enumerate(titles_a) if "(cont.)" in t]
        cont_idx_b = [i for i, t in enumerate(titles_b) if "(cont.)" in t]
        emit("FAIL", "T7 determinism -- (cont.) placement differs between the two independent renders of the identical source: run_a (cont.) at physical index(es) %r, run_b at %r" % (cont_idx_a, cont_idx_b))

    if slides_a == slides_b:
        emit("PASS", "T7 determinism -- extracted text is IDENTICAL, run-for-run and slide-for-slide, between the two independent renders (%d slide(s); content identity, not a byte-for-byte zip comparison -- the .pptx zip's own member metadata carries no determinism promise from I6)" % len(slides_a))
    else:
        diverge_slide = next((i for i in range(min(len(slides_a), len(slides_b))) if slides_a[i] != slides_b[i]), min(len(slides_a), len(slides_b)))
        got_a = slides_a[diverge_slide] if diverge_slide < len(slides_a) else None
        got_b = slides_b[diverge_slide] if diverge_slide < len(slides_b) else None
        emit("FAIL", "T7 determinism -- extracted text diverges at slide %d between the two independent renders of the identical source (run_a=%r run_b=%r)" % (diverge_slide, got_a, got_b))
else:
    emit("FAIL", "T7 determinism -- skipped, one or both renders could not be read (see the setup FAIL(s) above)")
PYEOF

  T7_RESULTS="$T7/results.txt"
  t7_check_rc=0
  "$PY" "$T7_CHECK_PY" "$SCRIPTS" "$TEST_DIR" "$T7_PPTX_A" "$T7_PPTX_B" "$FIXTURES/deck/technical.md" > "$T7_RESULTS" 2>"$T7/check_overflow.err" || t7_check_rc=$?

  if [ "$t7_check_rc" -ne 0 ]; then
    fail "T7 overflow/determinism checker exited $t7_check_rc (a bug in the checker itself, not necessarily in render.py) -- see $T7/check_overflow.err"
  fi

  t7_result_count=0
  # Read from a FILE, never a pipe: piping into `while read` would run the
  # loop body in a subshell, and pass()/fail() updating PASS/FAIL there would
  # be lost the moment the pipeline exits (mirrors the SC-003/SC-002 sections
  # above).
  while read -r t7_tag t7_verdict t7_label; do
    [ "$t7_tag" = "RESULT" ] || continue
    t7_result_count=$((t7_result_count + 1))
    case "$t7_verdict" in
      PASS) pass "$t7_label" ;;
      FAIL) fail "$t7_label" ;;
      *) fail "T7 checker produced an unparseable result line: $t7_tag $t7_verdict $t7_label" ;;
    esac
  done < "$T7_RESULTS"

  if [ "$t7_result_count" -eq 0 ] && [ "$t7_check_rc" -eq 0 ]; then
    fail "T7 overflow/determinism checker produced zero result lines -- a silent 0-assertion pass, which S10's discipline forbids"
  fi
fi

report
