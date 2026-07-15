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

# ---------------------------------------------------------------------------
section "1. SC-001 default path is untouched (FR-007/FR-013/FR-016)"
# The feature's default-off safety property: with `deck_render: none` (V1's
# explicit spelling) OR the key entirely absent (the silent default --
# profile_key.py's ABSENT branch 1, data-model.md Sec 1), a render.py
# invocation with NO explicit deck argument -- so selection comes from the
# profile alone -- must produce ZERO rendered files, leave `council/`
# byte-identical, and write nothing else in the feature directory either
# (FR-007/FR-013/FR-016). This is deliberately NOT the same code path as
# O4's "skipped" outcome (data-model.md Sec 5): O4 is "a deck IS selected
# but its source markdown is not present yet"; this section instead starts
# from commands.md Sec 2 step 3's earlier "nothing selected at all" exit,
# which never even enters the per-deck render loop.
#
# This check is entirely library-independent -- render.py's lazy `import
# pptx` (FR-015/R2) is never reached on the nothing-selected path, since
# `_render_deck()` is never called -- so, unlike every SC-003/SC-002/T7
# section above, it runs (and must PASS) with NO require_pptx guard, even
# on this pptx-absent host.
#
# Both fixture profiles are exercised, since they reach the SAME 'none'
# resolution via two DIFFERENT profile_key.py branches (see each fixture's
# own header comment in $FIXTURES/profiles/): none.yaml (explicit
# `deck_render: none`, branch 3) and absent-key.yaml (the key entirely
# omitted, branch 1) -- two independent code paths landing on the identical
# observable outcome, both must be proven separately.
#
# Byte-identity is proven by an independently-computed sha256 manifest
# (relpath -> hashlib.sha256 of the file's bytes, sorted) rather than a
# mtime or file-count proxy, which could miss an in-place content rewrite.
# Two manifests are taken per profile: one scoped to `council/` alone (the
# artifact of record FR-007/FR-013 promise this SC exists to protect), and
# one scoped to the WHOLE feature directory minus `renders/` (whose
# presence/absence/emptiness is already asserted independently below) --
# proving nothing else in the tree (e.g. profile.yaml itself) moved either.
SC001="$TMP/sc001"
mkdir -p "$SC001"

SC001_MANIFEST_PY="$SC001/manifest_council.py"
cat > "$SC001_MANIFEST_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-001 sha256 manifest (T023 inline helper).

Prints one "<sha256>  <relpath>" line per regular file under ROOT_DIR,
sorted by relpath, to stdout -- an independently-computed byte-identity
fingerprint of a directory subtree, never a mtime or file-count proxy
(either of which could miss an in-place content rewrite that happens to
land on the same size/count). Invoked twice per sc001 profile run
(before/after a render.py invocation) by run.sh's SC-001 section, so the
two manifests can be `cmp -s`'d.

Usage: manifest_council.py ROOT_DIR [EXCLUDE_TOPLEVEL_NAME ...]
EXCLUDE_TOPLEVEL_NAME entries are top-level child names of ROOT_DIR (not
full paths), skipped entirely -- used to manifest a feature directory MINUS
its own renders/, whose presence/absence/emptiness run.sh already asserts
independently; this manifest exists only to prove nothing ELSE in the tree
(e.g. profile.yaml itself) moved.
"""
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
excluded = set(sys.argv[2:])

lines = []
if root.is_dir():
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        if rel.parts and rel.parts[0] in excluded:
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append("%s  %s" % (digest, rel.as_posix()))

for line in lines:
    print(line)
PYEOF

for sc001_profile in none absent-key; do
  # The feature directory under test lives at "$sc001_scratch/feature" --
  # deliberately a SIBLING of, never inside, the scratch dir that holds this
  # loop's own manifest/log files below. If the scratch files lived inside
  # the feature dir itself, the "feature minus renders/" before/after
  # manifest would trivially disagree (the manifest/log files did not exist
  # yet at the "before" snapshot) -- a false positive that would make this
  # very check untrustworthy.
  sc001_scratch="$SC001/$sc001_profile"
  sc001_dir="$sc001_scratch/feature"
  mkdir -p "$sc001_dir/council/defense-deck"
  cp "$FIXTURES/deck/technical.md" "$sc001_dir/council/defense-deck/technical.md"
  cp "$FIXTURES/deck/overview.md" "$sc001_dir/council/defense-deck/overview.md"
  cp "$FIXTURES/profiles/$sc001_profile.yaml" "$sc001_dir/profile.yaml"

  sc001_council_before="$sc001_scratch/council-before.manifest"
  sc001_council_after="$sc001_scratch/council-after.manifest"
  sc001_feature_before="$sc001_scratch/feature-before.manifest"
  sc001_feature_after="$sc001_scratch/feature-after.manifest"
  "$PY" "$SC001_MANIFEST_PY" "$sc001_dir/council" > "$sc001_council_before"
  "$PY" "$SC001_MANIFEST_PY" "$sc001_dir" renders > "$sc001_feature_before"

  sc001_log="$sc001_scratch/render.log"
  sc001_rc=0
  "$PY" "$RENDER_PY" --feature "$sc001_dir" >"$sc001_log" 2>&1 || sc001_rc=$?

  "$PY" "$SC001_MANIFEST_PY" "$sc001_dir/council" > "$sc001_council_after"
  "$PY" "$SC001_MANIFEST_PY" "$sc001_dir" renders > "$sc001_feature_after"

  if [ "$sc001_rc" -eq 0 ]; then
    pass "SC-001 $sc001_profile -- render.py --feature <fixture dir>, NO explicit deck arg (selection from profile alone), exited 0 (see $sc001_log)"
  else
    fail "SC-001 $sc001_profile -- render.py exited $sc001_rc, expected 0 for the default nothing-selected path (see $sc001_log)"
  fi

  if [ -d "$sc001_dir/renders" ]; then
    sc001_render_count=$(find "$sc001_dir/renders" -type f | wc -l | tr -d ' ')
  else
    sc001_render_count=0
  fi
  if [ "$sc001_render_count" -eq 0 ]; then
    pass "SC-001 $sc001_profile -- zero files under renders/ (dir is absent or empty; FR-007/FR-016)"
  else
    fail "SC-001 $sc001_profile -- renders/ contains $sc001_render_count file(s), expected 0 -- deck_render: none (or the absent key) must render nothing"
  fi

  if grep -q "nothing selected" "$sc001_log"; then
    pass "SC-001 $sc001_profile -- run discloses the nothing-selected outcome (commands.md Sec 2 step 3): $(cat "$sc001_log")"
  else
    fail "SC-001 $sc001_profile -- expected disclosure did not mention 'nothing selected' -- got: $(cat "$sc001_log")"
  fi

  if cmp -s "$sc001_council_before" "$sc001_council_after"; then
    pass "SC-001 $sc001_profile -- council/ subtree byte-identical (sha256 manifest) before and after the run -- the renderer never writes under council/ (FR-007/FR-013)"
  else
    fail "SC-001 $sc001_profile -- council/ subtree changed by the run -- the renderer must NEVER write under council/ (manifest diff: $(diff "$sc001_council_before" "$sc001_council_after" | head -10))"
  fi

  if cmp -s "$sc001_feature_before" "$sc001_feature_after"; then
    pass "SC-001 $sc001_profile -- feature directory minus renders/ is byte-identical before and after the run -- no stray output written anywhere outside renders/"
  else
    fail "SC-001 $sc001_profile -- feature directory (minus renders/) changed by the run -- something was written outside renders/ (manifest diff: $(diff "$sc001_feature_before" "$sc001_feature_after" | head -10))"
  fi
done

# ---------------------------------------------------------------------------
section "8. SC-008 invalid/unreadable deck_render profile fails loud, nothing written (I-B1, data-model.md Sec 1 V2/V3/V5)"
# The guarantee under test: a typo'd/invalid `deck_render` must fail LOUDLY,
# never silently. Two DISTINCT branches, both hard failures (exit 3), and
# BOTH kept apart from each other and from SC-001's quiet "nothing selected
# (deck_render: none)" outcome above -- folding either one into that quieter
# signal is exactly what SC-008 forbids:
#   - invalid.yaml   -- OUT-OF-ENUM (data-model.md V2/V3): the YAML itself
#     parses cleanly; `deck_render: sparkle` is simply not one of
#     {none,technical,overview,both}. profile_key.py's branch 2.
#   - unreadable.yaml -- UNREADABLE/UNPARSEABLE (V5): a merge-conflict
#     marker corrupts the YAML document before any deck_render value could
#     even be inspected. profile_key.py's branch 3.
# Both are exercised two ways -- a bare `render.py --feature <dir>` (no
# explicit deck arg, so selection comes from the broken profile alone) and
# `render.py --validate-profile --feature <dir>` -- and both must exit 3 and
# write NOTHING (renders/ absent or empty, council/ byte-identical, same
# sha256-manifest technique SC-001 above already established). A closing
# sanity arm re-runs `--validate-profile` against overview.yaml (a genuinely
# valid selection) and asserts exit 0, proving the exit-3 assertions above
# are actually discriminating rather than a blanket nonzero from a harness
# bug. Library-independent: profile_key.py's resolver raises before
# render.py's lazy `import pptx` site is ever reached, so this section runs
# (and must PASS) with no require_pptx guard, even on this pptx-absent host.
SC008="$TMP/sc008"
mkdir -p "$SC008"

SC008_MANIFEST_PY="$SC008/manifest.py"
cat > "$SC008_MANIFEST_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-008 sha256 manifest (T024 inline helper) -- mirrors SC-001's own
manifest_council.py idiom above, kept section-local (never imported across
sections) per the harness's per-section "$TMP/<name>" isolation convention.
Prints one "<sha256>  <relpath>" line per regular file under ROOT_DIR,
sorted by relpath, to stdout -- an independently-computed byte-identity
fingerprint, never a mtime or file-count proxy.

Usage: manifest.py ROOT_DIR [EXCLUDE_TOPLEVEL_NAME ...]
"""
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
excluded = set(sys.argv[2:])

lines = []
if root.is_dir():
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        if rel.parts and rel.parts[0] in excluded:
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append("%s  %s" % (digest, rel.as_posix()))

for line in lines:
    print(line)
PYEOF

for sc008_profile in invalid unreadable; do
  case "$sc008_profile" in
    invalid) sc008_kind="out-of-enum (parseable YAML, deck_render value not in the enum)" ;;
    unreadable) sc008_kind="unreadable/unparseable (broken YAML)" ;;
  esac

  # A SIBLING scratch dir holds this loop's own manifest/log files, never
  # inside the feature dir itself -- mirrors SC-001's own rationale above
  # (otherwise the "feature minus renders/" before/after manifest would
  # trivially disagree on the scratch files' own late arrival).
  sc008_scratch="$SC008/$sc008_profile"
  sc008_dir="$sc008_scratch/feature"
  mkdir -p "$sc008_dir/council/defense-deck"
  cp "$FIXTURES/deck/technical.md" "$sc008_dir/council/defense-deck/technical.md"
  cp "$FIXTURES/deck/overview.md" "$sc008_dir/council/defense-deck/overview.md"
  cp "$FIXTURES/profiles/$sc008_profile.yaml" "$sc008_dir/profile.yaml"

  sc008_council_before="$sc008_scratch/council-before.manifest"
  sc008_council_after="$sc008_scratch/council-after.manifest"
  sc008_feature_before="$sc008_scratch/feature-before.manifest"
  sc008_feature_after="$sc008_scratch/feature-after.manifest"
  "$PY" "$SC008_MANIFEST_PY" "$sc008_dir/council" > "$sc008_council_before"
  "$PY" "$SC008_MANIFEST_PY" "$sc008_dir" renders > "$sc008_feature_before"

  sc008_log="$sc008_scratch/render.log"
  sc008_rc=0
  "$PY" "$RENDER_PY" --feature "$sc008_dir" >"$sc008_log" 2>&1 || sc008_rc=$?

  "$PY" "$SC008_MANIFEST_PY" "$sc008_dir/council" > "$sc008_council_after"
  "$PY" "$SC008_MANIFEST_PY" "$sc008_dir" renders > "$sc008_feature_after"

  if [ "$sc008_rc" -eq 3 ]; then
    pass "SC-008 $sc008_profile -- render.py --feature <fixture dir>, NO explicit deck arg ($sc008_kind), exited 3 (see $sc008_log)"
  else
    fail "SC-008 $sc008_profile -- render.py exited $sc008_rc, expected 3 for a $sc008_kind deck_render profile (see $sc008_log)"
  fi

  if [ -d "$sc008_dir/renders" ]; then
    sc008_render_count=$(find "$sc008_dir/renders" -type f | wc -l | tr -d ' ')
  else
    sc008_render_count=0
  fi
  if [ "$sc008_render_count" -eq 0 ]; then
    pass "SC-008 $sc008_profile -- zero files under renders/ (dir is absent or empty) -- a $sc008_kind profile must write NOTHING"
  else
    fail "SC-008 $sc008_profile -- renders/ contains $sc008_render_count file(s), expected 0 -- a $sc008_kind deck_render profile must render nothing"
  fi

  if cmp -s "$sc008_council_before" "$sc008_council_after"; then
    pass "SC-008 $sc008_profile -- council/ subtree byte-identical (sha256 manifest) before and after the run"
  else
    fail "SC-008 $sc008_profile -- council/ subtree changed by the run (manifest diff: $(diff "$sc008_council_before" "$sc008_council_after" | head -10))"
  fi

  if cmp -s "$sc008_feature_before" "$sc008_feature_after"; then
    pass "SC-008 $sc008_profile -- feature directory minus renders/ is byte-identical before and after the run -- no stray output written anywhere"
  else
    fail "SC-008 $sc008_profile -- feature directory (minus renders/) changed by the run (manifest diff: $(diff "$sc008_feature_before" "$sc008_feature_after" | head -10))"
  fi

  # The failure must be LOUD/disclosed, not routed to the quieter 'none'
  # branch (SC-008's own point): assert the disclosure names the failure as
  # INVALID, and separately assert it does NOT print SC-001's silent
  # "nothing selected (deck_render: none)" sentence -- the worse signal
  # (a corrupt/typo'd profile) must never resolve to the quieter outcome.
  if grep -q "INVALID" "$sc008_log"; then
    pass "SC-008 $sc008_profile -- disclosure names the failure as INVALID (loud, non-'none'): $(cat "$sc008_log")"
  else
    fail "SC-008 $sc008_profile -- expected disclosure to mention INVALID -- got: $(cat "$sc008_log")"
  fi

  if grep -q "nothing selected" "$sc008_log"; then
    fail "SC-008 $sc008_profile -- disclosure wrongly resolved to SC-001's silent 'nothing selected (deck_render: none)' outcome -- a $sc008_kind profile must fail loud, never fold into the quiet none branch (SC-008)"
  else
    pass "SC-008 $sc008_profile -- disclosure does NOT fall back to the silent 'nothing selected (deck_render: none)' sentence"
  fi

  # `--validate-profile` surfaces the SAME exit code on the SAME broken
  # profile. It renders nothing by construction (render.py's
  # --validate-profile branch returns before ever calling
  # _expand_selection()/_render_deck()), so no further manifest check is
  # needed here -- only the exit code.
  sc008_validate_log="$sc008_scratch/validate.log"
  sc008_validate_rc=0
  "$PY" "$RENDER_PY" --validate-profile --feature "$sc008_dir" >"$sc008_validate_log" 2>&1 || sc008_validate_rc=$?
  if [ "$sc008_validate_rc" -eq 3 ]; then
    pass "SC-008 $sc008_profile -- render.py --validate-profile --feature <fixture dir> exited 3 (see $sc008_validate_log)"
  else
    fail "SC-008 $sc008_profile -- render.py --validate-profile exited $sc008_validate_rc, expected 3 for a $sc008_kind deck_render profile (see $sc008_validate_log)"
  fi
done

# ---- sanity: a genuinely valid profile still resolves cleanly ------------
# The discriminating counterpart to the two exit-3 arms above: without this,
# a harness bug that made --validate-profile exit 3 unconditionally would
# pass every assertion above undetected. overview.yaml is a real, in-enum
# selection (profile_key.py's "parsed" + present + in-enum branch) -- no
# council/defense-deck fixture is needed, since --validate-profile never
# reads past profile.yaml itself.
SC008_VALID="$SC008/valid"
mkdir -p "$SC008_VALID"
cp "$FIXTURES/profiles/overview.yaml" "$SC008_VALID/profile.yaml"

sc008_valid_log="$SC008_VALID/validate.log"
sc008_valid_rc=0
"$PY" "$RENDER_PY" --validate-profile --feature "$SC008_VALID" >"$sc008_valid_log" 2>&1 || sc008_valid_rc=$?
if [ "$sc008_valid_rc" -eq 0 ]; then
  pass "SC-008 sanity -- render.py --validate-profile --feature <fixture dir with overview.yaml> exited 0 (see $sc008_valid_log) -- confirms the exit-3 assertions above are discriminating, not a blanket failure"
else
  fail "SC-008 sanity -- render.py --validate-profile exited $sc008_valid_rc, expected 0 for a valid deck_render=overview profile (see $sc008_valid_log)"
fi

# ---------------------------------------------------------------------------
section "16. FR-016 explicit override beats profile: none (V4, boundary unchanged)"
# The guarantee under test (data-model.md Sec 1 V4, FR-016): `deck_render` is
# a DEFAULT SELECTION, not a hard gate. An invocation that explicitly names a
# deck renders that deck regardless of the profile's value -- including when
# the profile says `none`. Contrast with SC-001 above (T023): a NO-ARG
# invocation against this exact SAME `none.yaml` profile renders nothing at
# all ("nothing selected (deck_render: none). No file written."); this
# section proves that giving `overview` as an explicit argument against the
# identical profile takes a completely different path.
#
# Two properties, kept deliberately apart:
#   (selection, unguarded -- runs on ANY host, pptx present or not) the
#   overview deck is ATTEMPTED: its disclosure line reads `rendered` (pptx
#   present) or `FAILED ... toolchain absent` (pptx absent) -- never
#   `skipped`, and the run never falls back to SC-001's silent
#   "nothing selected" sentence. Being attempted at all -- reaching
#   `_render_deck()`'s per-deck body instead of stopping at commands.md Sec 2
#   step 3's earlier "nothing selected" exit -- is what proves the explicit
#   arg was SELECTED OVER the profile's `none`; whether that attempt then
#   succeeds or fails on toolchain grounds is a separate, orthogonal fact
#   (SC-003/T7 above already cover the real-render case; SC-008 above
#   already covers profile-driven failure).
#   (file produced, require_pptx-guarded) with the toolchain present, the
#   SAME invocation actually writes `renders/overview.pptx` and exits 0 --
#   this is the only part of this section that needs a real render.
#
# The boundary is unchanged either way (FR-016's own closing sentence,
# spec.md): an explicitly-rendered deck is still derived, still un-bound
# (never in gates.yml), still un-traced (no traces.jsonl record), and the
# markdown under council/ remains the untouched artifact of record. These
# boundary assertions are unguarded -- library-independent, like SC-001's --
# and must PASS on this pptx-absent host exactly as they must on a host with
# the toolchain installed.
FR016="$TMP/fr016"
FR016_DIR="$FR016/feature"
mkdir -p "$FR016_DIR/council/defense-deck"
cp "$FIXTURES/deck/technical.md" "$FR016_DIR/council/defense-deck/technical.md"
cp "$FIXTURES/deck/overview.md" "$FR016_DIR/council/defense-deck/overview.md"
cp "$FIXTURES/profiles/none.yaml" "$FR016_DIR/profile.yaml"

# The byte-identity manifest: an independently-computed sha256 fingerprint
# (relpath -> hashlib.sha256 of the file's bytes, sorted), never a mtime or
# file-count proxy -- mirrors SC-001's own manifest_council.py idiom above,
# kept section-local per the harness's per-section "$TMP/<name>" isolation
# convention rather than shared across sections.
FR016_MANIFEST_PY="$FR016/manifest.py"
cat > "$FR016_MANIFEST_PY" <<'PYEOF'
#!/usr/bin/env python3
"""FR-016 sha256 manifest (T025 inline helper) -- mirrors SC-001's own
manifest_council.py idiom above. Prints one "<sha256>  <relpath>" line per
regular file under ROOT_DIR, sorted by relpath, to stdout. Invoked twice
(before/after the explicit-arg render) by run.sh's FR-016 section, so the
two manifests can be `cmp -s`'d.

Usage: manifest.py ROOT_DIR [EXCLUDE_TOPLEVEL_NAME ...]
"""
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
excluded = set(sys.argv[2:])

lines = []
if root.is_dir():
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        if rel.parts and rel.parts[0] in excluded:
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append("%s  %s" % (digest, rel.as_posix()))

for line in lines:
    print(line)
PYEOF

fr016_council_before="$FR016/council-before.manifest"
fr016_council_after="$FR016/council-after.manifest"
fr016_feature_before="$FR016/feature-before.manifest"
fr016_feature_after="$FR016/feature-after.manifest"
"$PY" "$FR016_MANIFEST_PY" "$FR016_DIR/council" > "$fr016_council_before"
"$PY" "$FR016_MANIFEST_PY" "$FR016_DIR" renders > "$fr016_feature_before"

fr016_log="$FR016/render.log"
fr016_rc=0
"$PY" "$RENDER_PY" overview --feature "$FR016_DIR" >"$fr016_log" 2>&1 || fr016_rc=$?

"$PY" "$FR016_MANIFEST_PY" "$FR016_DIR/council" > "$fr016_council_after"
"$PY" "$FR016_MANIFEST_PY" "$FR016_DIR" renders > "$fr016_feature_after"

# ---- selection: the explicit arg beat the profile's none (unguarded) ------
if grep -qE '^  overview   rendered   ' "$fr016_log"; then
  fr016_overview_status="rendered"
elif grep -qE '^  overview   FAILED     ' "$fr016_log"; then
  fr016_overview_status="FAILED (attempted, toolchain or other render failure -- see SC-003/T7 above for the real-render case)"
else
  fr016_overview_status=""
fi
if [ -n "$fr016_overview_status" ]; then
  pass "FR-016 override selected -- render.py overview --feature <dir> (profile: none) ATTEMPTED the overview deck ($fr016_overview_status, never skipped) -- the explicit arg was selected over the profile's none (see $fr016_log)"
else
  fail "FR-016 override selected -- expected the overview deck's disclosure line to show rendered or FAILED (i.e. attempted), got: $(cat "$fr016_log")"
fi

if grep -q '^  overview   skipped' "$fr016_log"; then
  fail "FR-016 override selected -- overview line shows skipped -- the explicit arg did NOT beat the profile's none (see $fr016_log)"
else
  pass "FR-016 override selected -- overview line is never skipped"
fi

if grep -q "nothing selected" "$fr016_log"; then
  fail "FR-016 override selected -- disclosure fell back to SC-001/T023's silent 'nothing selected (deck_render: none)' sentence -- an explicit overview argument must beat profile: none, not resolve to the no-arg outcome (see $fr016_log)"
else
  pass "FR-016 override selected -- disclosure does NOT fall back to the silent 'nothing selected (deck_render: none)' sentence that the SAME none.yaml profile produces on a no-arg run (SC-001/T023) -- proves the explicit arg overrode the profile"
fi

# ---- boundary unchanged: derived / un-bound / un-traced (unguarded) -------
fr016_traces_count=$(find "$FR016_DIR" -name 'traces.jsonl' 2>/dev/null | wc -l | tr -d ' ')
if [ "$fr016_traces_count" -eq 0 ]; then
  pass "FR-016 boundary -- zero traces.jsonl anywhere under the feature dir -- the explicit-arg render writes no trace record (un-traced)"
else
  fail "FR-016 boundary -- found $fr016_traces_count traces.jsonl file(s) under the feature dir, expected 0 -- an explicit-arg render must remain un-traced"
fi

if [ -f "$FR016_DIR/gates.yml" ]; then
  fail "FR-016 boundary -- gates.yml exists under the feature dir after an explicit-arg render -- the render must remain un-bound, never entering gates.yml"
else
  pass "FR-016 boundary -- no gates.yml created under the feature dir -- the render remains un-bound"
fi

if cmp -s "$fr016_council_before" "$fr016_council_after"; then
  pass "FR-016 boundary -- council/ subtree byte-identical (sha256 manifest) before and after the explicit-arg render -- the markdown remains the untouched artifact of record"
else
  fail "FR-016 boundary -- council/ subtree changed by the explicit-arg render (manifest diff: $(diff "$fr016_council_before" "$fr016_council_after" | head -10))"
fi

if cmp -s "$fr016_feature_before" "$fr016_feature_after"; then
  pass "FR-016 boundary -- feature directory minus renders/ is byte-identical before and after the run -- the explicit-arg render writes ONLY under renders/ (no traces.jsonl, no gates.yml, nothing else)"
else
  fail "FR-016 boundary -- feature directory (minus renders/) changed by the explicit-arg render -- something was written outside renders/ (manifest diff: $(diff "$fr016_feature_before" "$fr016_feature_after" | head -10))"
fi

# ---- file actually produced (require_pptx-guarded) -------------------------
if require_pptx "FR-016 override renders a file"; then
  if [ "$fr016_rc" -eq 0 ] && [ -f "$FR016_DIR/renders/overview.pptx" ]; then
    pass "FR-016 override renders a file -- render.py overview --feature <dir> (profile: none) exited 0 and wrote renders/overview.pptx (see $fr016_log)"
  else
    fail "FR-016 override renders a file -- render.py overview exited $fr016_rc or renders/overview.pptx is missing -- expected the explicit arg to actually produce the file once python-pptx is present (see $fr016_log)"
  fi
fi

# ---------------------------------------------------------------------------
section "12. S12 deck_render enum SSOT drift -- profile_key.py vs. the contract docs, both directions (T026)"
# The guarantee under test (plan.md S12): the closed enum {none, technical,
# overview, both} is defined EXACTLY ONCE, in profile_key.py, exported as
# DECK_RENDER_ENUM -- every contract doc that names this enum is asserted
# AGAINST that export, never re-typed as an independent copy. plan.md cites
# a live cautionary precedent for what happens when this discipline is
# skipped: `council_tier: standrad` (sic) degrades silently today precisely
# because ITS enum lives in two unlinked places with nothing checking them
# against each other. This section is the fixture Phase C promises to close
# that exact drift shape for deck_render specifically.
#
# Two docs, each checked at the SPECIFIC anchor(s) where they name the
# enum -- never a whole-file substring scan, which a stray, unrelated
# occurrence of the word "both" or "none" elsewhere in the prose could
# satisfy vacuously:
#   - docs/contracts/profile-schema.md Sec 1 (the ```yaml schema block's
#     `deck_render:` comment, e.g. "none | technical | overview | both.")
#     and Sec 3 (the field table's `deck_render` row, "One of `none` |
#     `technical` | `overview` | `both`").
#   - specs/006-deck-render/contracts/commands.md Sec 1 (the command
#     signature's `[technical|overview|both]` bracket group and the
#     Arguments table's matching backtick-quoted row) and Sec 4 (the `both`
#     outcome matrix's own per-deck naming sentence, "`technical` and
#     `overview` are interchangeable in this table", combined with its
#     "Under `deck_render: both`" lead-in) -- deliberately NOT a blind scan
#     of that table's cells, which are full of unrelated backtick-quoted
#     OUTCOME values (`rendered`, `failed`, `skipped`) that are not
#     deck-selector values at all.
# Every comparison is a SET, both directions: a doc value the code doesn't
# export (extra) is a FAIL exactly like a code value the doc omits
# (missing) -- neither direction is favored, per S12's own wording ("fails
# if the contract doc's list diverges from it").
# commands.md's three anchors are compared against the SSOT MINUS `none`
# (the three CLI-selectable decks -- `none` is expressed by omitting the
# argument entirely, never a literal selector token, per commands.md Sec 1's
# own Arguments table: "(none) | Render exactly what the feature's
# profile.yaml selects").
# Pure text/code inspection -- profile_key.py has no pptx dependency and
# neither contract doc does either -- so this runs (and must PASS) on any
# host, no require_pptx guard.
S12="$TMP/s12"
mkdir -p "$S12"
S12_PROFILE_SCHEMA_MD="$REPO/docs/contracts/profile-schema.md"
S12_COMMANDS_MD="$REPO/specs/006-deck-render/contracts/commands.md"

S12_CHECK_PY="$S12/check_enum_drift.py"
cat > "$S12_CHECK_PY" <<'PYEOF'
#!/usr/bin/env python3
"""S12 deck_render enum SSOT-drift checker (T026 inline helper).

Invoked once by run.sh's S12 section. Imports profile_key.py DIRECTLY (the
module under test IS the SSOT -- DECK_RENDER_ENUM -- so this checker never
re-types a second copy of the four literals) and compares it, as a SET in
BOTH directions, against the exact anchors where docs/contracts/
profile-schema.md and specs/006-deck-render/contracts/commands.md name the
enum. A doc value the code does not export (extra) and a code value the
doc omits (missing) are both a FAIL -- this is the drift shape plan.md's
S12 paragraph cites `council_tier: standrad` as the cautionary precedent
for.

Prints one result per line to stdout, "RESULT <PASS|FAIL> <label>". run.sh
reads this back from a temp FILE (never a pipe, so its PASS/FAIL counters
are not evaluated inside a subshell) and calls its own pass()/fail().
"""
import re
import sys
from pathlib import Path

SCRIPTS_DIR, PROFILE_SCHEMA_MD, COMMANDS_MD = sys.argv[1:4]

sys.path.insert(0, SCRIPTS_DIR)

import profile_key  # noqa: E402 -- the SSOT itself; never re-typed here

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

SSOT = set(profile_key.DECK_RENDER_ENUM)
# The three CLI-selectable decks: SSOT minus 'none' -- 'none' is expressed
# by omitting the argument, never a literal selector token (commands.md
# Sec 1's own Arguments table, the "(none)" row).
SSOT_SELECTABLE = SSOT - {profile_key.DECK_RENDER_DEFAULT}


def emit(verdict, label):
    label = " ".join(label.split())
    if len(label) > 240:
        label = label[:240] + " ...(truncated)"
    print("RESULT %s %s" % (verdict, label))


def compare(anchor_label, found, expected):
    """Both-direction SET comparison -- never a loose substring check a
    stray occurrence could satisfy. A value found in the doc that the SSOT
    does not export (extra), OR an SSOT value the doc omits (missing), is a
    FAIL either way.
    """
    extra = found - expected
    missing = expected - found
    if not extra and not missing:
        emit("PASS", "%s -- %s matches profile_key.DECK_RENDER_ENUM exactly" % (anchor_label, sorted(found)))
        return
    detail = []
    if extra:
        detail.append("doc lists %s which profile_key.py does NOT export" % sorted(extra))
    if missing:
        detail.append("profile_key.py exports %s which the doc omits" % sorted(missing))
    emit("FAIL", "%s -- diverges from the SSOT (expected %s): %s" % (anchor_label, sorted(expected), "; ".join(detail)))


def check_profile_schema(path):
    text = Path(path).read_bytes().decode("utf-8")

    # Sec 1: the FIRST fenced ```yaml schema block's `deck_render:` comment
    # line, e.g. "deck_render: none  # optional, default none (D73(3)).
    # none | technical | overview | both." -- the trailing period-terminated
    # "a | b | c | d" segment is the doc's own enumeration, independent of
    # the Sec 3 table below.
    block_match = re.search(r"```yaml\n(.*?)```", text, re.DOTALL)
    if block_match is None:
        emit("FAIL", "profile-schema.md Sec1 -- no ```yaml fenced schema block found at all; cannot locate the deck_render line")
    else:
        line_match = re.search(r"^deck_render:.*$", block_match.group(1), re.MULTILINE)
        if line_match is None:
            emit("FAIL", "profile-schema.md Sec1 -- the ```yaml schema block has no `deck_render:` line at all")
        else:
            list_match = re.search(r"\.\s*([a-z]+(?:\s*\|\s*[a-z]+)+)\.\s*$", line_match.group(0))
            if list_match is None:
                emit("FAIL", "profile-schema.md Sec1 -- deck_render line has no trailing 'a | b | c' enum list: %r" % line_match.group(0))
            else:
                found = {tok.strip() for tok in list_match.group(1).split("|")}
                compare("profile-schema.md Sec1 (schema block deck_render comment)", found, SSOT)

    # Sec 3: the field table's `deck_render` row, e.g. "| `deck_render` |
    # enum scalar | `none` | One of `none` \\| `technical` \\| `overview` \\|
    # `both` (D73(3)); ..." -- only the "One of ..." list segment is
    # captured, never the whole row (which also re-mentions `none` twice
    # elsewhere in its own prose).
    row_match = re.search(r"^\|\s*`deck_render`\s*\|.*$", text, re.MULTILINE)
    if row_match is None:
        emit("FAIL", "profile-schema.md Sec3 -- no field-table row starting with `deck_render` found at all")
    else:
        list_match = re.search(r"One of\s+((?:`[a-zA-Z_]+`\s*\\?\|\s*)+`[a-zA-Z_]+`)", row_match.group(0))
        if list_match is None:
            emit("FAIL", "profile-schema.md Sec3 -- deck_render row has no 'One of `a` | `b` ...' enum list: %r" % row_match.group(0))
        else:
            found = set(re.findall(r"`([a-zA-Z_]+)`", list_match.group(1)))
            compare("profile-schema.md Sec3 (field-table deck_render row 'One of' list)", found, SSOT)


def check_commands(path):
    text = Path(path).read_bytes().decode("utf-8")

    # Sec 1: the command signature's bracketed deck-selector group --
    # "/speckit-deck-render [technical|overview|both] [--feature <dir>]
    # [--validate-profile]" -- only the FIRST bracket group is a
    # pipe-delimited alpha list; the other two never match this pattern.
    sig_match = re.search(r"/speckit-deck-render\s+\[([a-z]+(?:\|[a-z]+)+)\]", text)
    if sig_match is None:
        emit("FAIL", "commands.md Sec1 -- no '/speckit-deck-render [a|b|c]' signature line found at all")
    else:
        found = set(sig_match.group(1).split("|"))
        compare("commands.md Sec1 (command signature [technical|overview|both])", found, SSOT_SELECTABLE)

    # Sec 1: the Arguments table's enum row, e.g. "| `technical` \\|
    # `overview` \\| `both` | **Explicit selection ...` |" -- anchored on
    # the unique "**Explicit selection" text that follows it on the SAME
    # line, so this can never accidentally latch onto an unrelated
    # backtick-pipe-backtick row elsewhere in the doc (e.g. the Sec 4
    # outcome-matrix's own `rendered`/`rendered` rows).
    arg_row_match = re.search(
        r"^\|\s*((?:`[a-zA-Z]+`\s*\\?\|\s*)+`[a-zA-Z]+`)\s*\|\s*\*\*Explicit selection",
        text, re.MULTILINE,
    )
    if arg_row_match is None:
        emit("FAIL", "commands.md Sec1 -- no Arguments-table 'Explicit selection' row enumerating backtick-quoted deck values found at all")
    else:
        found = set(re.findall(r"`([a-zA-Z]+)`", arg_row_match.group(1)))
        compare("commands.md Sec1 (Arguments table deck-selector row)", found, SSOT_SELECTABLE)

    # Sec 4: the `both` outcome matrix's own per-deck naming -- "`technical`
    # and `overview` are interchangeable in this table" plus its "Under
    # `deck_render: both`" lead-in -- deliberately NOT a blind scan of the
    # whole outcome-matrix table, whose cells are full of unrelated
    # backtick-quoted OUTCOME values (`rendered`, `failed`, `skipped`) that
    # are not deck-selector values at all.
    pair_match = re.search(r"`([a-zA-Z]+)`\s+and\s+`([a-zA-Z]+)`\s+are interchangeable in this table", text)
    under_match = re.search(r"Under\s+`deck_render:\s*([a-zA-Z]+)`", text)
    if pair_match is None or under_match is None:
        emit("FAIL", "commands.md Sec4 -- could not locate the both-outcome-matrix's per-deck naming sentence ('`X` and `Y` are interchangeable in this table') and/or its 'Under `deck_render: Z`' lead-in")
    else:
        found = {pair_match.group(1), pair_match.group(2), under_match.group(1)}
        compare("commands.md Sec4 (both-outcome-matrix per-deck naming)", found, SSOT_SELECTABLE)


emit("PASS", "S12 SSOT read -- profile_key.DECK_RENDER_ENUM = %s (from %s)" % (profile_key.DECK_RENDER_ENUM, profile_key.__file__))

for doc_label, checker, doc_path in (
    ("profile-schema.md", check_profile_schema, PROFILE_SCHEMA_MD),
    ("commands.md", check_commands, COMMANDS_MD),
):
    try:
        checker(doc_path)
    except Exception as exc:  # noqa: BLE001 -- isolate one doc's crash from the other (I-B2 idiom)
        emit("FAIL", "%s -- checker crashed: %r" % (doc_label, exc))
PYEOF

S12_RESULTS="$S12/results.txt"
s12_check_rc=0
"$PY" "$S12_CHECK_PY" "$SCRIPTS" "$S12_PROFILE_SCHEMA_MD" "$S12_COMMANDS_MD" > "$S12_RESULTS" 2>"$S12/check_enum_drift.err" || s12_check_rc=$?

if [ "$s12_check_rc" -ne 0 ]; then
  fail "S12 enum SSOT-drift checker exited $s12_check_rc (a bug in the checker itself, not necessarily a real doc divergence) -- see $S12/check_enum_drift.err"
fi

s12_result_count=0
# Read from a FILE, never a pipe: piping into `while read` would run the
# loop body in a subshell, and pass()/fail() updating PASS/FAIL there would
# be lost the moment the pipeline exits (mirrors every prior section above).
while read -r s12_tag s12_verdict s12_label; do
  [ "$s12_tag" = "RESULT" ] || continue
  s12_result_count=$((s12_result_count + 1))
  case "$s12_verdict" in
    PASS) pass "$s12_label" ;;
    FAIL) fail "$s12_label" ;;
    *) fail "S12 checker produced an unparseable result line: $s12_tag $s12_verdict $s12_label" ;;
  esac
done < "$S12_RESULTS"

if [ "$s12_result_count" -eq 0 ] && [ "$s12_check_rc" -eq 0 ]; then
  fail "S12 enum SSOT-drift checker produced zero result lines -- a silent 0-assertion pass, which S10's discipline forbids"
fi

# ---------------------------------------------------------------------------
section "4. SC-004 degrade-and-disclose under a forced toolchain-absent failure (FR-009/FR-010, R6)"
# The guarantee under test (SC-004, data-model.md Sec 5 O1/O2/O3): when the
# render toolchain is absent, render.py DEGRADES rather than crashing -- the
# council phase completes, the gate stays reachable/approvable, EVERY .md
# under council/ stays byte-identical, and a per-deck failure notice
# (naming the deck and the reason) reaches the human, who is told the
# markdown is unaffected (FR-009 and FR-010 together, per SC-004's own
# wording -- "the phase survives and the human is told, per deck").
#
# Forcing the failure (research.md R6): a PYTHONPATH SHADOW, never a
# production-code backdoor. A temp dir holding pptx/__init__.py that
# unconditionally `raise ImportError(...)` is prepended to PYTHONPATH, so
# render.py's OWN lazy `import pptx` (FR-015 -- the ONE import site, inside
# `_render_deck()`'s try block) hits a REAL ImportError -- the exact
# exception class the production degrade path already catches -- rather
# than a simulated failure behind an env-var flag that would ship to users
# and could be tripped in the field (R6's own rejected alternative). Because
# the shadow forces the failure regardless of whether real python-pptx
# happens to be installed on this host, this section is deliberately
# INDEPENDENT of ambient pptx -- expect_no_pptx (informational only), never
# require_pptx; it must PASS on a pptx-absent host and identically on a
# pptx-equipped one.
expect_no_pptx "SC-004 degrade-and-disclose (toolchain-absent failure forced via a PYTHONPATH shadow)"

SC004="$TMP/sc004"
SC004_SHADOW="$SC004/shadow"
mkdir -p "$SC004_SHADOW/pptx"
cat > "$SC004_SHADOW/pptx/__init__.py" <<'PYEOF'
raise ImportError("shadowed python-pptx for SC-004 test (research.md R6) -- this package intentionally always fails to import")
PYEOF

# Sanity-check the shadow mechanism itself BEFORE relying on it for the real
# assertions below: prepending $SC004_SHADOW to PYTHONPATH must make a bare
# `import pptx` raise, on THIS host, regardless of whether real python-pptx
# is also installed (sys.path resolves in order; PYTHONPATH entries are
# prepended ahead of any site-packages entry, so the shadow package wins).
sc004_shadow_rc=0
PYTHONPATH="$SC004_SHADOW:${PYTHONPATH:-}" "$PY" -c 'import pptx' >"$SC004/shadow_check.log" 2>&1 || sc004_shadow_rc=$?
if [ "$sc004_shadow_rc" -ne 0 ]; then
  pass "SC-004 setup -- the PYTHONPATH shadow (research.md R6) genuinely forces \"import pptx\" to raise, confirmed via a standalone $PY -c 'import pptx' before relying on it for the render below"
else
  fail "SC-004 setup -- the PYTHONPATH shadow did NOT force \"import pptx\" to fail (exited 0) -- the degrade assertions below cannot be trusted; see $SC004/shadow_check.log"
fi

# ---- the fixture feature directory: a GOOD deck pair (both fixtures, so
# `both` attempts and fails BOTH decks), plus a pre-existing gates.yml stub
# so this section can prove BOTH "not created" and "not modified" with one
# before/after comparison rather than only proving absence -----------------
SC004_FEATURE="$SC004/feature"
mkdir -p "$SC004_FEATURE/council/defense-deck"
cp "$FIXTURES/deck/technical.md" "$SC004_FEATURE/council/defense-deck/technical.md"
cp "$FIXTURES/deck/overview.md" "$SC004_FEATURE/council/defense-deck/overview.md"
cat > "$SC004_FEATURE/gates.yml" <<'YAMLEOF'
# pre-existing gate stub for the SC-004 harness -- a render failure must
# never create OR modify this file (FR-009: "the phase survives"; the gate
# stays reachable/approvable exactly as it was before the render attempt).
schema_version: "1.0"
gates: {}
YAMLEOF

# The sha256 manifest technique: an independently-computed fingerprint
# (relpath -> hashlib.sha256 of the file's bytes, sorted), never a mtime or
# file-count proxy -- mirrors SC-001/SC-008/FR-016's own manifest.py idiom
# above, kept section-local per the harness's per-section "$TMP/<name>"
# isolation convention.
SC004_MANIFEST_PY="$SC004/manifest.py"
cat > "$SC004_MANIFEST_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-004 sha256 manifest (T028 inline helper) -- mirrors SC-001/SC-008/
FR-016's own manifest.py idiom above. Prints one "<sha256>  <relpath>" line
per regular file under ROOT_DIR, sorted by relpath, to stdout.

Usage: manifest.py ROOT_DIR [EXCLUDE_TOPLEVEL_NAME ...]
"""
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
excluded = set(sys.argv[2:])

lines = []
if root.is_dir():
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        if rel.parts and rel.parts[0] in excluded:
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append("%s  %s" % (digest, rel.as_posix()))

for line in lines:
    print(line)
PYEOF

SC004_SHA_PY="$SC004/sha_one.py"
cat > "$SC004_SHA_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-004 single-file sha256 (T028 inline helper) -- used only for the
gates.yml before/after comparison, which is checked independently of (and
in addition to) the council/ subtree manifest above.

Usage: sha_one.py FILE
"""
import hashlib
import sys

print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())
PYEOF

sc004_council_before="$SC004/council-before.manifest"
sc004_council_after="$SC004/council-after.manifest"
sc004_gates_sha_before="$SC004/gates-before.sha256"
sc004_gates_sha_after="$SC004/gates-after.sha256"
"$PY" "$SC004_MANIFEST_PY" "$SC004_FEATURE/council" > "$sc004_council_before"
"$PY" "$SC004_SHA_PY" "$SC004_FEATURE/gates.yml" > "$sc004_gates_sha_before"

# ---- the render itself: PYTHONPATH-shadowed, so the toolchain-absent
# degrade path is forced regardless of ambient pptx -------------------------
SC004_LOG="$SC004/render.log"
sc004_rc=0
PYTHONPATH="$SC004_SHADOW:${PYTHONPATH:-}" "$PY" "$RENDER_PY" both --feature "$SC004_FEATURE" >"$SC004_LOG" 2>&1 || sc004_rc=$?

"$PY" "$SC004_MANIFEST_PY" "$SC004_FEATURE/council" > "$sc004_council_after"
if [ -f "$SC004_FEATURE/gates.yml" ]; then
  "$PY" "$SC004_SHA_PY" "$SC004_FEATURE/gates.yml" > "$sc004_gates_sha_after"
else
  : > "$sc004_gates_sha_after"
fi

# ---- (1) phase completes: no hang (the run above already returned), no
# uncaught traceback, and the contract's degraded exit code (commands.md
# Sec 4: EXIT_ALL_FAILED=4 -- every SELECTED deck failed, none rendered or
# skipped, since BOTH decks hit the toolchain-absent branch here) ----------
if [ "$sc004_rc" -eq 4 ]; then
  pass "SC-004 phase completes -- render.py both --feature <dir> (PYTHONPATH-shadowed) returned exit 4 (EXIT_ALL_FAILED, commands.md Sec 4 -- both selected decks failed, none rendered/skipped), never a hang or an uncaught crash (see $SC004_LOG)"
else
  fail "SC-004 phase completes -- render.py both exited $sc004_rc, expected 4 (EXIT_ALL_FAILED) when both selected decks hit the toolchain-absent branch (see $SC004_LOG)"
fi

if grep -q "Traceback (most recent call last)" "$SC004_LOG"; then
  fail "SC-004 phase completes -- render.py's own stdout/stderr contains an uncaught Python traceback -- the toolchain-absent ImportError must be CAUGHT and turned into a disclosed per-deck failure, never allowed to crash the process (see $SC004_LOG)"
else
  pass "SC-004 phase completes -- no uncaught Python traceback in render.py's output -- the forced ImportError was caught and degraded, not crashed"
fi

# ---- (2) gate reachable / never blocks: no gates.yml created or modified,
# nothing under council/ touched --------------------------------------------
if [ -f "$SC004_FEATURE/gates.yml" ]; then
  pass "SC-004 gate reachable -- gates.yml still exists after the forced-failure render (never deleted)"
else
  fail "SC-004 gate reachable -- gates.yml is MISSING after the forced-failure render -- a render failure must never remove/block the gate"
fi

if cmp -s "$sc004_gates_sha_before" "$sc004_gates_sha_after"; then
  pass "SC-004 gate never blocks -- gates.yml's sha256 is unchanged before/after the forced-failure render (FR-009: 'the phase survives' -- the gate stays exactly as it was, never created fresh and never edited)"
else
  fail "SC-004 gate never blocks -- gates.yml's sha256 CHANGED across the forced-failure render -- a render failure must never create or modify the gate binding"
fi

sc004_gates_count=$(find "$SC004_FEATURE" -name 'gates.yml' | wc -l | tr -d ' ')
if [ "$sc004_gates_count" -eq 1 ]; then
  pass "SC-004 gate never blocks -- exactly 1 gates.yml under the feature dir after the run (the one pre-existing stub -- no second/stray gates.yml was written anywhere else)"
else
  fail "SC-004 gate never blocks -- found $sc004_gates_count gates.yml file(s) under the feature dir, expected exactly 1 (the pre-existing stub)"
fi

# ---- (3) every council/ .md byte-identical ---------------------------------
if cmp -s "$sc004_council_before" "$sc004_council_after"; then
  pass "SC-004 council/ byte-identical -- council/ subtree sha256 manifest unchanged before/after the forced-failure render -- the renderer never modifies a markdown artifact even when it fails (FR-009)"
else
  fail "SC-004 council/ byte-identical -- council/ subtree changed by the forced-failure render (manifest diff: $(diff "$sc004_council_before" "$sc004_council_after" | head -10))"
fi

# ---- (4) no partial .pptx: the atomic write (I-B3) never produced a file
# at all -- the ImportError trips before assembly, let alone the atomic
# os.replace() ---------------------------------------------------------------
if [ -d "$SC004_FEATURE/renders" ]; then
  sc004_pptx_count=$(find "$SC004_FEATURE/renders" -name '*.pptx' | wc -l | tr -d ' ')
else
  sc004_pptx_count=0
fi
if [ "$sc004_pptx_count" -eq 0 ]; then
  pass "SC-004 no partial .pptx -- zero .pptx files under renders/ (dir is absent or contains none) -- the atomic write never landed a partial or finished render for either deck"
else
  fail "SC-004 no partial .pptx -- found $sc004_pptx_count .pptx file(s) under renders/, expected 0 -- a forced toolchain-absent failure must never leave a rendered (or partially-rendered) file behind"
fi

# ---- (5) per-deck disclosure reaches the human -----------------------------
# Both decks named individually as FAILED with the toolchain-absent reason
# (never a folded/summary line) -- the grep patterns are column-width
# tolerant (technical/overview differ in length, and _print_disclosure()
# left-pads the shorter label to match), so each matches the label + FAILED
# + reason regardless of the exact inter-column spacing.
if grep -qE '^  technical[[:space:]]+FAILED[[:space:]]+toolchain absent \(python-pptx not installed\)' "$SC004_LOG"; then
  pass "SC-004 per-deck disclosure -- technical is individually disclosed FAILED with the toolchain-absent reason (see $SC004_LOG)"
else
  fail "SC-004 per-deck disclosure -- expected a 'technical ... FAILED ... toolchain absent (python-pptx not installed)' line -- got: $(cat "$SC004_LOG")"
fi

if grep -qE '^  overview[[:space:]]+FAILED[[:space:]]+toolchain absent \(python-pptx not installed\)' "$SC004_LOG"; then
  pass "SC-004 per-deck disclosure -- overview is individually disclosed FAILED with the toolchain-absent reason (see $SC004_LOG)"
else
  fail "SC-004 per-deck disclosure -- expected an 'overview ... FAILED ... toolchain absent (python-pptx not installed)' line -- got: $(cat "$SC004_LOG")"
fi

if grep -qF "The markdown decks are unaffected and remain the artifact of record." "$SC004_LOG"; then
  pass "SC-004 per-deck disclosure -- the disclosure states the markdown is unaffected and remains the artifact of record (FR-010)"
else
  fail "SC-004 per-deck disclosure -- expected the 'markdown decks are unaffected' sentence, got: $(cat "$SC004_LOG")"
fi

if grep -qiE 'install.*python-pptx' "$SC004_LOG"; then
  pass "SC-004 per-deck disclosure -- the disclosure additionally hints how to install the optional toolchain, since every failure here is toolchain-absent"
else
  fail "SC-004 per-deck disclosure -- expected an 'install ... python-pptx' hint since every failure here is toolchain-absent, got: $(cat "$SC004_LOG")"
fi

# ---------------------------------------------------------------------------
section "29. Partial-failure exit 2 -- per-deck isolation under deck_render: both (I-B2, S02/S03)"
# The guarantee under test (plan.md I-B2): "an exception rendering deck N
# MUST NOT prevent deck N+1 from being attempted and reported." S02/S03's
# committed asymmetric fixture (test/fixtures/deck-broken/, T027,
# PROVENANCE.md) pairs one GOOD deck (technical.md -- parses clean, 14
# blocks) with one deliberately BROKEN deck (overview.md -- an out-of-census
# markdown link on line 17 makes deck_md.parse() raise DeckMdError) under
# the SAME `both` invocation. render.py's per-deck loop
# (`ordered = (technical, overview)`, RENDERABLE_DECKS' canonical order --
# profile_key.py) attempts technical first (succeeds) and overview second
# (raises internally, caught inside _render_deck()'s own try/except and
# turned into a Result(OUTCOME_FAILED, ...) rather than propagating). This
# proves the SECOND deck's internal exception can never retroactively
# swallow or un-disclose the FIRST deck's already-completed render -- an
# uncaught exception mid-list-comprehension (`results = [_render_deck(deck,
# feature_dir) for deck in ordered]`, render.py's main()) would crash the
# process before _print_disclosure()/_compute_exit_code() ever ran, losing
# technical's already-good render along with overview's failure, and
# collapsing what should be exit 2 into an uncaught-traceback exit. Needs a
# REAL render for the outcome to be meaningful (contracts/commands.md Sec 4
# "rendered + failed -> 2" row of the `both` outcome matrix, I-B4) --
# without python-pptx BOTH decks would instead hit the toolchain-absent
# branch and collapse to exit 4, the wrong assertion (PROVENANCE.md's own
# "what T029 still needs to observe end-to-end" note) -- so the entire body
# is guarded by require_pptx, mirroring the SC-003/SC-002/T7/SC-004 sections
# above.
if require_pptx "partial-failure exit 2 (render-good / fail-broken / disclose-both)"; then
  EXIT2="$TMP/exit2"
  EXIT2_FEATURE="$EXIT2/feature"
  mkdir -p "$EXIT2_FEATURE/council/defense-deck"
  cp "$FIXTURES/deck-broken/technical.md" "$EXIT2_FEATURE/council/defense-deck/technical.md"
  cp "$FIXTURES/deck-broken/overview.md" "$EXIT2_FEATURE/council/defense-deck/overview.md"

  EXIT2_LOG="$EXIT2/render.log"
  exit2_rc=0
  "$PY" "$RENDER_PY" both --feature "$EXIT2_FEATURE" >"$EXIT2_LOG" 2>&1 || exit2_rc=$?

  # ---- exit 2, never 4 (or any other code) -- commands.md Sec 4's
  # rendered+failed -> 2 row, I-B4's outcome matrix --------------------------
  if [ "$exit2_rc" -eq 2 ]; then
    pass "partial-failure exit 2 -- render.py both --feature <asymmetric fixture> exited 2 (EXIT_PARTIAL), never 4 (see $EXIT2_LOG)"
  else
    fail "partial-failure exit 2 -- render.py both exited $exit2_rc, expected 2 (EXIT_PARTIAL) -- collapsing to 4 (or crashing) would mean the broken deck's exception was NOT isolated from the good deck's already-completed result (I-B2) (see $EXIT2_LOG)"
  fi

  if grep -q "Traceback (most recent call last)" "$EXIT2_LOG"; then
    fail "partial-failure exit 2 -- render.py's own stdout/stderr contains an uncaught Python traceback -- overview's DeckMdError must be CAUGHT and turned into a disclosed per-deck failure, never allowed to crash the process (I-B2) (see $EXIT2_LOG)"
  else
    pass "partial-failure exit 2 -- no uncaught Python traceback in render.py's output -- overview's DeckMdError was caught and degraded, not crashed"
  fi

  # ---- technical (good) -- actually rendered, a real .pptx on disk --------
  if [ -f "$EXIT2_FEATURE/renders/technical.pptx" ]; then
    pass "partial-failure exit 2 -- technical (the good deck) actually rendered: renders/technical.pptx exists on disk"
  else
    fail "partial-failure exit 2 -- technical (the good deck) did NOT render: renders/technical.pptx is missing -- the broken sibling must never prevent the good deck from rendering (I-B2) (see $EXIT2_LOG)"
  fi

  # Captured via a subshell '|| true' rather than a bare command
  # substitution: under 'set -e', a var=$(grep ...) assignment whose grep
  # finds nothing (exit 1) would otherwise abort the whole suite -- mirrors
  # the file-vs-pipe discipline the SC-003/SC-002/T7/S12 checkers use for
  # the identical reason (a subshell's own exit status must never propagate
  # and silently truncate the run).
  exit2_technical_line=$(grep -E '^  technical[[:space:]]+rendered[[:space:]]' "$EXIT2_LOG" || true)
  if [ -n "$exit2_technical_line" ]; then
    pass "partial-failure exit 2 -- technical is individually disclosed 'rendered' (see: $exit2_technical_line)"
  else
    fail "partial-failure exit 2 -- expected a 'technical ... rendered ...' disclosure line -- got: $(cat "$EXIT2_LOG")"
  fi

  # ---- overview (broken) -- NOT rendered, disclosed FAILED (never
  # skipped, never silently dropped) with the actual deck_md parse-error
  # reason (line 17's out-of-census link, PROVENANCE.md) --------------------
  if [ -f "$EXIT2_FEATURE/renders/overview.pptx" ]; then
    fail "partial-failure exit 2 -- overview (the broken deck) has a renders/overview.pptx on disk -- a deck whose source fails deck_md.parse() must never produce a render file"
  else
    pass "partial-failure exit 2 -- overview (the broken deck) has no renders/overview.pptx -- the failed parse never produced a file"
  fi

  exit2_overview_line=$(grep -E '^  overview[[:space:]]+FAILED[[:space:]]' "$EXIT2_LOG" || true)
  if [ -n "$exit2_overview_line" ]; then
    pass "partial-failure exit 2 -- overview is individually disclosed FAILED, not skipped and not silently dropped (see: $exit2_overview_line)"
  else
    fail "partial-failure exit 2 -- expected an 'overview ... FAILED ...' disclosure line -- got: $(cat "$EXIT2_LOG")"
  fi

  if [ -n "$exit2_overview_line" ] \
     && printf '%s\n' "$exit2_overview_line" | grep -qF 'line 17' \
     && printf '%s\n' "$exit2_overview_line" | grep -qF 'link syntax is out of census'; then
    pass "partial-failure exit 2 -- overview's FAILED reason names the actual deck_md parse error (line 17's out-of-census markdown link), not a generic message"
  else
    fail "partial-failure exit 2 -- overview's FAILED reason does not name line 17's out-of-census link parse error -- got: $exit2_overview_line"
  fi

  if grep -qE '^  overview[[:space:]]+skipped' "$EXIT2_LOG"; then
    fail "partial-failure exit 2 -- overview is disclosed 'skipped', not 'FAILED' -- a deck whose source exists but fails to parse must be FAILED, never skipped (skipped is reserved for absent source, O4)"
  else
    pass "partial-failure exit 2 -- overview is never disclosed as 'skipped' -- skipped is reserved for absent source (O4); a present-but-broken deck is FAILED"
  fi

  # ---- both disclosed together (I-B2 isolation, not just two independent
  # facts checked separately above) -- one render.py invocation, one log,
  # both deck names present with their correct, differing outcomes ----------
  if [ -n "$exit2_technical_line" ] && [ -n "$exit2_overview_line" ]; then
    pass "partial-failure exit 2 -- both decks disclosed by the SAME render.py both invocation (technical rendered + overview FAILED in one run) -- the broken deck's failure did not prevent the good deck from being attempted, rendered, AND disclosed (I-B2 per-deck isolation)"
  else
    fail "partial-failure exit 2 -- expected BOTH technical and overview disclosure lines from a single 'both' invocation, got only: technical=[$exit2_technical_line] overview=[$exit2_overview_line]"
  fi
fi

# ---------------------------------------------------------------------------
section "30. I-B3 atomic write -- mid-write failure leaves no partial .pptx, prior good render untouched (O5, plan.md I-B3/S04)"
# The guarantee under test (data-model.md Sec 5 O5 / plan.md I-B3, S04): the
# write is atomic -- render.py writes the new render to a temp file INSIDE
# the target directory, then os.replace()s it into renders/<deck>.pptx only
# on full success. No target is ever pre-deleted, so a mid-write failure
# must leave a prior good render completely untouched. This is the ONLY
# failure mode that would actually violate O5, so plan.md's Phase C
# requires it be forced by a committed test -- exactly this section.
#
# How this differs from SC-004 (the section immediately above): SC-004
# shadows `import pptx` itself via a PYTHONPATH trick, so ITS failure trips
# BEFORE the write begins -- python-pptx is never actually imported, the
# deck is never parsed or assembled, and no temp file is ever attempted
# (plan.md is explicit: "This trips before the write begins; it is not the
# same as I-B3's mid-write failure test below"). THIS section does the
# opposite: guarded by require_pptx (not expect_no_pptx), python-pptx REALLY
# imports, the deck REALLY parses and assembles into a real `Presentation`,
# and the failure is forced squarely INSIDE the atomic-write step itself --
# render.py's `tempfile.mkstemp(dir=<renders/>)` call, the first move of
# I-B3's temp-file-in-target-dir mechanism, immediately before its
# `prs.save(tmp_name)` / `os.replace(tmp_name, target_path)` pair. Forced by
# making `renders/` itself READ-ONLY (chmod 500 -- r-x, no write) AFTER a
# prior good render already sits there: creating a NEW file inside a
# non-writable directory is a real OSError from the OS (render.py's own
# `except OSError as exc: return Result(..., f"cannot prepare the renders/
# directory: {exc}")`), no production-code backdoor of any kind. Permissions
# are restored IMMEDIATELY after the forced-failure invocation, before any
# assertion below runs, so the harness's own EXIT trap (`rm -rf "$TMP"`,
# near the top of this file) can still clean up even if an assertion below
# were to fail.
if require_pptx "I-B3 atomic mid-write failure (no partial .pptx + prior good render untouched)"; then
  MIDWRITE="$TMP/midwrite"
  MIDWRITE_FEATURE="$MIDWRITE/feature"
  MIDWRITE_RENDERS="$MIDWRITE_FEATURE/renders"
  MIDWRITE_TARGET="$MIDWRITE_RENDERS/technical.pptx"
  mkdir -p "$MIDWRITE_FEATURE/council/defense-deck"
  cp "$FIXTURES/deck/technical.md" "$MIDWRITE_FEATURE/council/defense-deck/technical.md"

  # A single-file sha256 helper, mirrors SC-004's own sha_one.py idiom above
  # -- an INDEPENDENTLY recomputed fingerprint, never a trust-render.py's-
  # own-arithmetic shortcut, and never a byte-for-byte `cmp` of the whole
  # .pptx zip alone (a zip's own member metadata carries no promise here;
  # sha256-of-bytes is the same "prior render untouched" oracle SC-004's
  # gates.yml before/after check already relies on).
  MIDWRITE_SHA_PY="$MIDWRITE/sha_one.py"
  cat > "$MIDWRITE_SHA_PY" <<'PYEOF'
#!/usr/bin/env python3
"""I-B3 atomic mid-write failure: single-file sha256 (T030 inline helper) --
mirrors SC-004's sha_one.py idiom above.

Usage: sha_one.py FILE
"""
import hashlib
import sys

print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())
PYEOF

  # ---- step 1: a PRIOR GOOD render, established for real -------------------
  MIDWRITE_LOG_GOOD="$MIDWRITE/render_1_good.log"
  midwrite_rc_good=0
  "$PY" "$RENDER_PY" technical --feature "$MIDWRITE_FEATURE" >"$MIDWRITE_LOG_GOOD" 2>&1 || midwrite_rc_good=$?

  if [ "$midwrite_rc_good" -eq 0 ] && [ -f "$MIDWRITE_TARGET" ]; then
    pass "I-B3 setup -- render.py technical --feature <fixture dir> exited 0 and wrote a PRIOR GOOD render at renders/technical.pptx (see $MIDWRITE_LOG_GOOD)"
  else
    fail "I-B3 setup -- render.py technical exited $midwrite_rc_good or renders/technical.pptx is missing -- the mid-write failure assertions below cannot be trusted (see $MIDWRITE_LOG_GOOD)"
  fi

  MIDWRITE_SHA_BEFORE="$MIDWRITE/prior.sha256"
  "$PY" "$MIDWRITE_SHA_PY" "$MIDWRITE_TARGET" > "$MIDWRITE_SHA_BEFORE"
  midwrite_files_before=$(find "$MIDWRITE_RENDERS" -type f | wc -l | tr -d ' ')

  # ---- step 2: force the NEXT render's WRITE (post-import) to fail --------
  # chmod 500 on renders/ AFTER the prior good render is already sitting
  # there -- the deck's markdown source is untouched, so this retries the
  # very same invocation that just succeeded, and this time the atomic
  # write's own temp-file creation is what fails.
  chmod 500 "$MIDWRITE_RENDERS"

  MIDWRITE_LOG_FAIL="$MIDWRITE/render_2_forced_midwrite_fail.log"
  midwrite_rc_fail=0
  "$PY" "$RENDER_PY" technical --feature "$MIDWRITE_FEATURE" >"$MIDWRITE_LOG_FAIL" 2>&1 || midwrite_rc_fail=$?

  # Restore perms IMMEDIATELY -- before any assertion below runs, so a
  # read-only renders/ never outlives the one invocation it exists to break,
  # and the harness's own EXIT trap (`rm -rf "$TMP"`) can still unlink
  # everything under it.
  chmod 700 "$MIDWRITE_RENDERS"

  if [ "$midwrite_rc_fail" -eq 4 ]; then
    pass "I-B3 mid-write failure -- render.py technical --feature <dir> (renders/ made read-only) exited 4 (EXIT_ALL_FAILED -- the one selected deck failed, none rendered/skipped), never a hang or a silent success (see $MIDWRITE_LOG_FAIL)"
  else
    fail "I-B3 mid-write failure -- render.py technical exited $midwrite_rc_fail, expected 4 (EXIT_ALL_FAILED) when the write itself fails on a read-only renders/ (see $MIDWRITE_LOG_FAIL)"
  fi

  # ---- render.py disclosed the failure (O2) and did not crash -------------
  if grep -q "Traceback (most recent call last)" "$MIDWRITE_LOG_FAIL"; then
    fail "I-B3 mid-write failure -- render.py's own stdout/stderr contains an uncaught Python traceback -- the mkstemp() OSError on a read-only renders/ must be CAUGHT and turned into a disclosed per-deck failure, never allowed to crash the process (see $MIDWRITE_LOG_FAIL)"
  else
    pass "I-B3 mid-write failure -- no uncaught Python traceback in render.py's output -- the forced mkstemp() OSError was caught and degraded, not crashed"
  fi

  if grep -qE '^  technical[[:space:]]+FAILED[[:space:]]' "$MIDWRITE_LOG_FAIL"; then
    pass "I-B3 mid-write failure -- technical is disclosed FAILED (per-deck outcome reaches the human, O2 -- silence is never an acceptable degradation) (see $MIDWRITE_LOG_FAIL)"
  else
    fail "I-B3 mid-write failure -- expected a 'technical ... FAILED ...' disclosure line -- got: $(cat "$MIDWRITE_LOG_FAIL")"
  fi

  if grep -qF "cannot prepare the renders/ directory" "$MIDWRITE_LOG_FAIL"; then
    pass "I-B3 mid-write failure -- the disclosed reason names the write-preparation failure (render.py's OWN message for the tempfile.mkstemp() OSError), not a generic/unrelated reason"
  else
    fail "I-B3 mid-write failure -- expected the disclosed reason to mention 'cannot prepare the renders/ directory' -- got: $(cat "$MIDWRITE_LOG_FAIL")"
  fi

  # ---- no partial .pptx and no leftover temp file --------------------------
  midwrite_files_after=$(find "$MIDWRITE_RENDERS" -type f | wc -l | tr -d ' ')
  if [ "$midwrite_files_after" -eq "$midwrite_files_before" ]; then
    pass "I-B3 no partial .pptx -- renders/ holds the SAME number of files after the forced mid-write failure as before ($midwrite_files_before) -- nothing partial, nothing extra was left behind"
  else
    fail "I-B3 no partial .pptx -- renders/ holds $midwrite_files_after file(s) after the forced mid-write failure, expected $midwrite_files_before (unchanged) -- a mid-write failure must never leave a partial or stray file"
  fi

  midwrite_tmp_count=$(find "$MIDWRITE_RENDERS" -name '*.tmp' | wc -l | tr -d ' ')
  if [ "$midwrite_tmp_count" -eq 0 ]; then
    pass "I-B3 no partial .pptx -- zero leftover *.tmp file(s) under renders/ -- the atomic write's own temp-file naming (.<deck>.*.pptx.tmp) left nothing behind"
  else
    fail "I-B3 no partial .pptx -- found $midwrite_tmp_count leftover *.tmp file(s) under renders/, expected 0"
  fi

  if [ -f "$MIDWRITE_TARGET" ]; then
    pass "I-B3 no partial .pptx -- renders/technical.pptx still exists at the target path (never pre-deleted, I-B3) after the forced mid-write failure"
  else
    fail "I-B3 no partial .pptx -- renders/technical.pptx is MISSING after the forced mid-write failure -- the prior good render must never be removed by a failed write attempt"
  fi

  # ---- the prior good render is byte-identical (sha256 unchanged) ---------
  MIDWRITE_SHA_AFTER="$MIDWRITE/prior_after.sha256"
  if [ -f "$MIDWRITE_TARGET" ]; then
    "$PY" "$MIDWRITE_SHA_PY" "$MIDWRITE_TARGET" > "$MIDWRITE_SHA_AFTER"
  else
    : > "$MIDWRITE_SHA_AFTER"
  fi

  if cmp -s "$MIDWRITE_SHA_BEFORE" "$MIDWRITE_SHA_AFTER"; then
    pass "I-B3 prior render untouched -- renders/technical.pptx's sha256 is UNCHANGED across the forced mid-write failure (independently recomputed both times: $(cat "$MIDWRITE_SHA_BEFORE" 2>/dev/null || echo '?')) -- never pre-deleted, never partially overwritten (O5)"
  else
    fail "I-B3 prior render untouched -- renders/technical.pptx's sha256 CHANGED across the forced mid-write failure (before: $(cat "$MIDWRITE_SHA_BEFORE" 2>/dev/null || echo MISSING), after: $(cat "$MIDWRITE_SHA_AFTER" 2>/dev/null || echo MISSING)) -- a failed write must never disturb a prior good render (O5)"
  fi
fi

# ---------------------------------------------------------------------------
section "31. SC-007 render staleness -- FRESH/STALE stateless read-and-compare (I-B6/S13)"
# The guarantee under test (SC-007; data-model.md Sec 3; plan.md I-B6/S13): a
# stale render -- a `.pptx` whose embedded source sha256 no longer matches
# the CURRENT source markdown's sha256 -- must be DETECTABLE and SURFACED,
# never silently trusted. render.py's own mechanism (`_fresh_stale_verdict()`
# / `_read_embedded_sha256()`) is a STATELESS read-and-compare: no state file
# is written anywhere; every invocation simply reads whatever prior render
# already sits at the target path (via plain zipfile + xml.etree -- no
# `python-pptx` needed to READ, only to write) and compares its embedded
# stamp to the CURRENT source's freshly-computed sha256. Two branches, both
# exercised here, discriminating rather than one-sided (golden-fixture
# discipline): an UNCHANGED source must print `FRESH`; a MUTATED source must
# print `STALE`. The verdict line (`"<deck>: FRESH"` / `"<deck>: STALE"`,
# `render.py`'s own literal f-string) is printed to STDOUT, unconditionally,
# BEFORE the lazy `import pptx` site is even reached -- so it fires
# regardless of whether the render attempt that follows goes on to succeed --
# and is asserted here to land on stdout specifically (never stderr), since
# a silent or misrouted verdict is not the human-usable disclosure SC-007
# requires (a reviewer on a phone can act on a plain stdout line).
#
# The sha-MISMATCH itself (the fact the STALE verdict is built on) is proven
# independently of render.py's own arithmetic, mirroring SC-002's own stamp
# section above: the still-on-disk PRIOR render's embedded 64-hex stamp is
# extracted via `extract_pptx_text.py` (the harness's independent stdlib
# OOXML oracle -- never `python-pptx`, and never render.py's own
# `_read_embedded_sha256()`, which is the exact function under test here),
# and compared against an independently, freshly recomputed
# `hashlib.sha256()` of the MUTATED source's bytes.
if require_pptx "SC-007 staleness detection (FRESH/STALE verdict)"; then
  SC007="$TMP/sc007"
  SC007_DIR="$SC007/feature"
  mkdir -p "$SC007_DIR/council/defense-deck"
  cp "$FIXTURES/deck/technical.md" "$SC007_DIR/council/defense-deck/technical.md"
  SC007_SRC="$SC007_DIR/council/defense-deck/technical.md"
  SC007_TARGET="$SC007_DIR/renders/technical.pptx"

  # A single-file sha256 helper -- mirrors I-B3's/SC-004's own sha_one.py
  # idiom above, written to a scratch file (never a `python3 -c` one-liner)
  # purely for readability; it never ships (lives only under $TMP).
  SC007_SHA_PY="$SC007/sha_of.py"
  cat > "$SC007_SHA_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-007 staleness: single-file sha256 (T031 inline helper) -- mirrors
I-B3's/SC-004's own sha_one.py idiom above.

Usage: sha_of.py FILE
"""
import hashlib
import sys

print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())
PYEOF

  # ---- step 1: baseline -- render source_v1 for the very first time -------
  # No prior render sits at the target path yet, so `_fresh_stale_verdict()`
  # returns `None` (I-B6) -- no FRESH/STALE line is expected on THIS
  # invocation; it exists only to establish the on-disk v1 render the
  # FRESH/STALE checks below compare against.
  SC007_LOG1_OUT="$SC007/render_1_baseline.stdout"
  SC007_LOG1_ERR="$SC007/render_1_baseline.stderr"
  sc007_rc1=0
  "$PY" "$RENDER_PY" technical --feature "$SC007_DIR" >"$SC007_LOG1_OUT" 2>"$SC007_LOG1_ERR" || sc007_rc1=$?

  if [ "$sc007_rc1" -eq 0 ] && [ -f "$SC007_TARGET" ]; then
    pass "SC-007 setup -- render.py technical --feature <fixture dir> exited 0 and wrote the BASELINE render at renders/technical.pptx (source_v1; see $SC007_LOG1_OUT)"
  else
    fail "SC-007 setup -- render.py technical exited $sc007_rc1 or renders/technical.pptx is missing -- the FRESH/STALE checks below cannot be trusted (see $SC007_LOG1_OUT, $SC007_LOG1_ERR)"
  fi

  if grep -qE '^technical: (FRESH|STALE)$' "$SC007_LOG1_OUT"; then
    fail "SC-007 setup -- the BASELINE render (nothing to compare against yet) unexpectedly printed a FRESH/STALE verdict -- got: $(cat "$SC007_LOG1_OUT")"
  else
    pass "SC-007 setup -- the BASELINE render prints NO FRESH/STALE verdict (I-B6: \`_fresh_stale_verdict()\` returns None when no prior render sits at the target path -- proves the checks below are genuinely comparative, not unconditional)"
  fi

  # A path-only manifest (never content -- the STALE arm below deliberately
  # mutates council/defense-deck/technical.md's CONTENT in place, so a
  # content-based manifest would spuriously fail on our own test action) of
  # every file under the feature dir, taken once the baseline render exists.
  # Compared again at the very end of this section, after the STALE re-run:
  # the set of file PATHS must stay identical throughout -- I-B6's "no state
  # file is written anywhere" promise means the read-and-compare must never
  # introduce a NEW file (e.g. a cached ".stale" marker) anywhere in the tree.
  SC007_PATHS_BEFORE="$SC007/paths-before.txt"
  find "$SC007_DIR" -type f | sort > "$SC007_PATHS_BEFORE"

  # ---- step 2: FRESH -- immediate re-run on the UNCHANGED source ----------
  SC007_LOG2_OUT="$SC007/render_2_fresh.stdout"
  SC007_LOG2_ERR="$SC007/render_2_fresh.stderr"
  sc007_rc2=0
  "$PY" "$RENDER_PY" technical --feature "$SC007_DIR" >"$SC007_LOG2_OUT" 2>"$SC007_LOG2_ERR" || sc007_rc2=$?

  if [ "$sc007_rc2" -eq 0 ]; then
    pass "SC-007 FRESH -- render.py technical --feature <dir>, source UNCHANGED, exited 0 (see $SC007_LOG2_OUT)"
  else
    fail "SC-007 FRESH -- render.py technical exited $sc007_rc2, expected 0 on an unchanged source (see $SC007_LOG2_OUT, $SC007_LOG2_ERR)"
  fi

  if grep -qxF 'technical: FRESH' "$SC007_LOG2_OUT"; then
    pass "SC-007 FRESH -- render.py prints the exact one-line 'technical: FRESH' verdict to STDOUT (the prior render's embedded sha == the current source's sha, I-B6/S13) -- see $SC007_LOG2_OUT"
  else
    fail "SC-007 FRESH -- expected a 'technical: FRESH' line on stdout -- got stdout: $(cat "$SC007_LOG2_OUT") / stderr: $(cat "$SC007_LOG2_ERR")"
  fi

  if grep -qxF 'technical: FRESH' "$SC007_LOG2_ERR"; then
    fail "SC-007 FRESH -- the verdict line leaked onto STDERR instead of (or in addition to) STDOUT -- SC-007 requires it be a STDOUT disclosure a reviewer can act on"
  else
    pass "SC-007 FRESH -- the verdict line is NOT on stderr -- confirms it is a genuine stdout disclosure, not a diagnostic aside"
  fi

  # ---- step 3: STALE -- mutate the source, then re-run --------------------
  # Independently recomputed sha256 of the source AS IT STILL STANDS (v1),
  # taken before the mutation below, so it can be compared against the
  # prior render's OWN embedded stamp as a sanity check that the extraction
  # technique itself is trustworthy before it is relied on for the real
  # mismatch assertion.
  SC007_V1_SHA="$SC007/v1_source.sha256"
  "$PY" "$SC007_SHA_PY" "$SC007_SRC" > "$SC007_V1_SHA"

  # The still-on-disk v1 render's embedded 64-hex stamp, extracted via
  # extract_pptx_text.py -- the harness's INDEPENDENT stdlib OOXML oracle
  # (SC-002's own precedent above), never via render.py's own
  # `_read_embedded_sha256()` (the exact function under test here -- using
  # it to check itself would prove nothing). Taken BEFORE the source is
  # mutated below, while the v1 render still sits untouched at the target
  # path.
  SC007_EXTRACTED_RUNS="$SC007/v1_render_runs.txt"
  SC007_EXTRACT_ERR="$SC007/extract.stderr"
  sc007_extract_rc=0
  "$PY" "$EXTRACT_PPTX_TEXT_PY" "$SC007_TARGET" > "$SC007_EXTRACTED_RUNS" 2>"$SC007_EXTRACT_ERR" || sc007_extract_rc=$?

  if [ "$sc007_extract_rc" -eq 0 ]; then
    pass "SC-007 STALE setup -- extract_pptx_text.py (independent stdlib OOXML oracle) read the still-on-disk v1 render's runs (see $SC007_EXTRACTED_RUNS)"
  else
    fail "SC-007 STALE setup -- extract_pptx_text.py exited $sc007_extract_rc reading the v1 render -- see $SC007_EXTRACT_ERR"
  fi

  SC007_EMBEDDED_SHA=$(grep -oE '[0-9a-f]{64}' "$SC007_EXTRACTED_RUNS" | head -n 1)
  if [ -n "$SC007_EMBEDDED_SHA" ] && [ "$SC007_EMBEDDED_SHA" = "$(cat "$SC007_V1_SHA")" ]; then
    pass "SC-007 STALE setup -- the v1 render's embedded 64-hex sha256 ($SC007_EMBEDDED_SHA), extracted independently via extract_pptx_text.py, matches hashlib.sha256(<source_v1 bytes>) computed independently here -- confirms the extraction below is trustworthy"
  else
    fail "SC-007 STALE setup -- the v1 render's extracted embedded sha256 ('$SC007_EMBEDDED_SHA') does not match the independently computed source_v1 sha256 ($(cat "$SC007_V1_SHA")) -- the mismatch assertion below cannot be trusted"
  fi

  # Mutate the source IN PLACE (same path, new bytes -- a plain appended
  # paragraph, safely inside deck_md.py's census: no image/link/footnote/
  # autolink/raw-HTML construct) so the path-only manifest above stays
  # valid, and so the STILL-ON-DISK render at renders/technical.pptx keeps
  # pointing at the SAME source path with its OLD (v1) stamp until the next
  # render.py invocation overwrites it.
  printf '\nSC-007 staleness probe -- source mutated after the v1 render.\n' >> "$SC007_SRC"

  SC007_V2_SHA="$SC007/v2_source.sha256"
  "$PY" "$SC007_SHA_PY" "$SC007_SRC" > "$SC007_V2_SHA"

  if [ "$(cat "$SC007_V2_SHA")" != "$(cat "$SC007_V1_SHA")" ]; then
    pass "SC-007 STALE setup -- mutating the source produced a genuinely DIFFERENT sha256 (v1: $(cat "$SC007_V1_SHA"), v2: $(cat "$SC007_V2_SHA")) -- the mutation is real, not a no-op"
  else
    fail "SC-007 STALE setup -- source sha256 is UNCHANGED after the mutation ($(cat "$SC007_V1_SHA")) -- the mutation did not take effect, the STALE assertions below would be meaningless"
  fi

  # THE sha-mismatch assertion (the full 64-hex embedded stamp, both sides):
  # the v1 render's embedded stamp -- extracted independently above, while
  # the render still sat untouched on disk -- must NOT equal
  # sha256(source_v2). This is the discriminating fact render.py's own STALE
  # verdict below is built on: a stale render IS detectable by a plain
  # recompute-and-compare (SC-007), before render.py is even asked again.
  if [ -n "$SC007_EMBEDDED_SHA" ] && [ "$SC007_EMBEDDED_SHA" != "$(cat "$SC007_V2_SHA")" ]; then
    pass "SC-007 STALE sha mismatch -- the still-on-disk v1 render's embedded 64-hex stamp ($SC007_EMBEDDED_SHA) != sha256(source_v2) ($(cat "$SC007_V2_SHA")), independently computed and independently extracted"
  else
    fail "SC-007 STALE sha mismatch -- the v1 render's embedded stamp ('$SC007_EMBEDDED_SHA') equals sha256(source_v2) ($(cat "$SC007_V2_SHA")) or was empty -- expected a mismatch after mutating the source"
  fi

  SC007_LOG3_OUT="$SC007/render_3_stale.stdout"
  SC007_LOG3_ERR="$SC007/render_3_stale.stderr"
  sc007_rc3=0
  "$PY" "$RENDER_PY" technical --feature "$SC007_DIR" >"$SC007_LOG3_OUT" 2>"$SC007_LOG3_ERR" || sc007_rc3=$?

  if [ "$sc007_rc3" -eq 0 ]; then
    pass "SC-007 STALE -- render.py technical --feature <dir>, source MUTATED (v2), exited 0 (re-rendering over a prior good render; see $SC007_LOG3_OUT)"
  else
    fail "SC-007 STALE -- render.py technical exited $sc007_rc3, expected 0 re-rendering a mutated source over a prior good render (see $SC007_LOG3_OUT, $SC007_LOG3_ERR)"
  fi

  if grep -qxF 'technical: STALE' "$SC007_LOG3_OUT"; then
    pass "SC-007 STALE -- render.py prints the exact one-line 'technical: STALE' verdict to STDOUT (the prior render's embedded sha != the current source's sha, I-B6/S13) -- see $SC007_LOG3_OUT"
  else
    fail "SC-007 STALE -- expected a 'technical: STALE' line on stdout -- got stdout: $(cat "$SC007_LOG3_OUT") / stderr: $(cat "$SC007_LOG3_ERR")"
  fi

  if grep -qxF 'technical: STALE' "$SC007_LOG3_ERR"; then
    fail "SC-007 STALE -- the verdict line leaked onto STDERR instead of (or in addition to) STDOUT -- SC-007 requires it be a STDOUT disclosure a reviewer can act on"
  else
    pass "SC-007 STALE -- the verdict line is NOT on stderr -- confirms it is a genuine stdout disclosure, not a diagnostic aside"
  fi

  # ---- no state file anywhere in the feature tree (I-B6: stateless) -------
  SC007_PATHS_AFTER="$SC007/paths-after.txt"
  find "$SC007_DIR" -type f | sort > "$SC007_PATHS_AFTER"
  if cmp -s "$SC007_PATHS_BEFORE" "$SC007_PATHS_AFTER"; then
    pass "SC-007 stateless -- the set of file PATHS under the feature dir is IDENTICAL before and after the FRESH + STALE re-runs -- no cached staleness marker or state file was written anywhere (I-B6: a stateless read-and-compare against the render's OWN embedded stamp, never a state file)"
  else
    fail "SC-007 stateless -- the set of file paths under the feature dir CHANGED across the FRESH/STALE re-runs -- I-B6 requires FRESH/STALE be a stateless read-and-compare, never backed by a state file (diff: $(diff "$SC007_PATHS_BEFORE" "$SC007_PATHS_AFTER" | head -10))"
  fi
fi

# ---------------------------------------------------------------------------
section "5. SC-005 boundary -- render never in git, gates.yml, traces.jsonl, or council context-in (FR-001/FR-014)"
# SC-005's own text: "no rendered file appears in gates.yml, in any
# traces.jsonl record, in any council session's context-in, or in git's
# tracked file set" -- the falsifiable form of FR-001 ("MUST NOT be bound by
# any gate... MUST NOT be an input to any pipeline phase... MUST NOT appear
# in traces.jsonl") + FR-014 ("derived build product, not a committed
# artifact... written under a gitignored path"). Unlike every other section
# in this file, the claim under test is a static fact about the ALREADY-
# COMMITTED repository (an untracked .gitignore rule; zero gate/trace/
# council references), not about anything a fresh invocation of render.py
# does -- so, deliberately, this section inspects the REAL repo tree ($REPO)
# rather than rendering into a $TMP fixture. No require_pptx guard: every
# check below is git plumbing or grep against files already on disk; it
# PASSES even on a host where python-pptx is not installed (confirmed
# absent on this host per section 0's banner above) -- exactly the S10
# posture the task calls for. A scratch dir is still used, per the file's
# own per-section "$TMP/<short-name>" convention, purely to hold
# intermediate grep/find output for readable FAIL detail.
SC005="$TMP/sc005"
mkdir -p "$SC005"

# ---- (a) not in git: the .gitignore rule exists, AND the current tracked --
# set is already clean. Two independent checks on purpose: the RULE check
# proves a FUTURE render is ignored before it can be staged (FR-014's
# "written under a gitignored path"); the ls-files checks prove no render
# has EVER slipped past it (e.g. before the rule was ever added). The
# second ls-files check (bare *.pptx, not path-scoped) is deliberately
# stronger than SC-005's literal "specs/*/renders/" wording -- a rendered
# deck must never be tracked, full stop, regardless of where it landed.
if grep -qxF 'specs/*/renders/' "$REPO/.gitignore"; then
  pass "SC-005 not in git -- .gitignore carries the exact 'specs/*/renders/' rule (FR-014), so a future render is ignored before it can ever be staged"
else
  fail "SC-005 not in git -- .gitignore does NOT carry a literal 'specs/*/renders/' line -- a future render would be stageable by accident, breaking FR-014's gitignored-path guarantee"
fi

SC005_GIT_TRACKED="$SC005/git-ls-files.txt"
git -C "$REPO" ls-files > "$SC005_GIT_TRACKED"

SC005_GIT_RENDERS="$SC005/git-tracked-renders.txt"
grep -E 'specs/[^/]+/renders/' "$SC005_GIT_TRACKED" > "$SC005_GIT_RENDERS" || true
if [ -s "$SC005_GIT_RENDERS" ]; then
  fail "SC-005 not in git -- git ls-files tracks $(wc -l < "$SC005_GIT_RENDERS" | tr -d ' ') file(s) under a specs/*/renders/ path, e.g. $(head -n 1 "$SC005_GIT_RENDERS") -- the boundary is broken"
else
  pass "SC-005 not in git -- git -C \"\$REPO\" ls-files contains ZERO tracked files under any specs/*/renders/ path (SC-005's literal wording)"
fi

SC005_GIT_PPTX="$SC005/git-tracked-pptx.txt"
grep -E '\.pptx$' "$SC005_GIT_TRACKED" > "$SC005_GIT_PPTX" || true
if [ -s "$SC005_GIT_PPTX" ]; then
  fail "SC-005 not in git -- git ls-files tracks $(wc -l < "$SC005_GIT_PPTX" | tr -d ' ') .pptx file(s) anywhere in the repo, e.g. $(head -n 1 "$SC005_GIT_PPTX") -- a rendered deck must never be tracked, regardless of path"
else
  pass "SC-005 not in git -- git -C \"\$REPO\" ls-files contains ZERO tracked .pptx files anywhere in the repo (stronger than the path-scoped check above)"
fi

# ---- (b) not in any gates.yml: gates bind .md SHAs only (data-model.md's --
# GateSHABinding; see e.g. specs/006-deck-render/gates.yml's own
# 'plan.md: <sha>' / 'tasks.md: <sha>' shape) -- grep every committed
# gates.yml for a renders/ path or a .pptx reference; zero is the only
# correct answer.
SC005_GATES_FILES="$SC005/gates-files.txt"
find "$REPO/specs" -maxdepth 2 -name 'gates.yml' -type f | sort > "$SC005_GATES_FILES"

if [ -s "$SC005_GATES_FILES" ]; then
  pass "SC-005 not in gates.yml setup -- found $(wc -l < "$SC005_GATES_FILES" | tr -d ' ') committed gates.yml file(s) under $REPO/specs to inspect (see $SC005_GATES_FILES)"
else
  fail "SC-005 not in gates.yml setup -- found ZERO gates.yml files under $REPO/specs -- the check below would be a silent 0-file pass, which S10's discipline forbids"
fi

SC005_GATES_HITS="$SC005/gates-hits.txt"
: > "$SC005_GATES_HITS"
while read -r sc005_gates_file; do
  [ -n "$sc005_gates_file" ] || continue
  grep -HnE 'renders/|\.pptx' "$sc005_gates_file" >> "$SC005_GATES_HITS" || true
done < "$SC005_GATES_FILES"

if [ -s "$SC005_GATES_HITS" ]; then
  fail "SC-005 not in gates.yml -- $(wc -l < "$SC005_GATES_HITS" | tr -d ' ') line(s) across the committed gates.yml files reference a renders/ path or a .pptx file, e.g. $(head -n 1 "$SC005_GATES_HITS") -- gates bind .md SHAs only"
else
  pass "SC-005 not in gates.yml -- none of the $(wc -l < "$SC005_GATES_FILES" | tr -d ' ') committed gates.yml file(s) reference a renders/ path or a .pptx file -- every binding is an .md SHA, as data-model.md's GateSHABinding requires"
fi

# ---- (c) not in any traces.jsonl: a mechanical, model-free transform ------
# leaves no trace record at all (FR-011; the render write itself is never a
# session) -- but FR-001 also forbids a render being "an input to any
# pipeline phase," which would show up as some OTHER session's own
# context-in reference (e.g. a tester's role-gated `context_in` array,
# trace-schema.md Sec 1) naming a renders/ path. One grep across every
# committed traces.jsonl record covers both: no record's `artifact` field,
# and no record's `context_in` field, ever names a renders/ path or a
# .pptx file.
SC005_TRACES_FILES="$SC005/traces-files.txt"
find "$REPO/specs" -maxdepth 2 -name 'traces.jsonl' -type f | sort > "$SC005_TRACES_FILES"

if [ -s "$SC005_TRACES_FILES" ]; then
  pass "SC-005 not in traces.jsonl setup -- found $(wc -l < "$SC005_TRACES_FILES" | tr -d ' ') committed traces.jsonl file(s) under $REPO/specs to inspect (see $SC005_TRACES_FILES)"
else
  fail "SC-005 not in traces.jsonl setup -- found ZERO traces.jsonl files under $REPO/specs -- the check below would be a silent 0-file pass, which S10's discipline forbids"
fi

SC005_TRACES_HITS="$SC005/traces-hits.txt"
: > "$SC005_TRACES_HITS"
while read -r sc005_traces_file; do
  [ -n "$sc005_traces_file" ] || continue
  grep -HnE 'renders/|\.pptx' "$sc005_traces_file" >> "$SC005_TRACES_HITS" || true
done < "$SC005_TRACES_FILES"

if [ -s "$SC005_TRACES_HITS" ]; then
  fail "SC-005 not in traces.jsonl -- $(wc -l < "$SC005_TRACES_HITS" | tr -d ' ') record(s) across the committed traces.jsonl files reference a renders/ path or a .pptx file (in 'artifact', 'context_in', or any other field), e.g. $(head -n 1 "$SC005_TRACES_HITS") -- a render must never be a phase/session artifact"
else
  pass "SC-005 not in traces.jsonl -- none of the $(wc -l < "$SC005_TRACES_FILES" | tr -d ' ') committed traces.jsonl file(s) have any record whose fields reference a renders/ path or a .pptx file -- a mechanical render leaves no trace (FR-011), and no OTHER session's context-in ever names one either (FR-001)"
fi

# ---- (d) not in any council session's context-in --------------------------
# artifact-layout.md's phase table pins EXACTLY what each council-family
# session reads as context-in: `council` reads `defense-deck/`, `plan.md`,
# `spec.md` + the graphify query tool; `council-gate` (the human) reads
# `overview.md`, `suggestions.md`, `decision-record.md` -- neither row ever
# names `renders/`. That table itself is grepped first, below, as the
# contract-level guarantee.
#
# The grep across the ACTUAL committed council/ subtrees is deliberately
# NARROWER than a bare 'renders/' or '.pptx' substring search: 006-deck-
# render is dogfooding review of the deck-render FEATURE ITSELF, so its own
# council/defense-deck/technical.md, opinions, and decision-record.md
# legitimately DISCUSS the renders/ mechanism in prose ("write
# `renders/<deck>.pptx`", ".gitignore | + specs/*/renders/", "a truncated
# `.pptx`" describing the atomic-write hazard, etc.) while proposing and
# reviewing this very feature -- a bare substring grep for 'renders/' or
# '.pptx' independently would flag that legitimate design commentary as a
# false positive (confirmed by hand against this repo's own
# specs/006-deck-render/council/ tree while authoring this section). What
# SC-005 actually forbids is a council session's context-in NAMING a real
# rendered ARTIFACT PATH -- i.e. a literal 'renders/<name>.pptx'-shaped
# path fragment, the thing a session would have had to read FROM, not the
# word "renders" appearing in prose ABOUT the mechanism. That precise
# pattern is what is grepped for below, and it correctly returns zero
# matches even across 006's own self-referential review.
SC005_AL_HITS="$SC005/artifact-layout-hits.txt"
grep -nE '^\| (council|council-gate) \|' "$REPO/docs/contracts/artifact-layout.md" > "$SC005_AL_HITS" || true

if [ -s "$SC005_AL_HITS" ]; then
  pass "SC-005 context-in contract setup -- found $(wc -l < "$SC005_AL_HITS" | tr -d ' ') council/council-gate row(s) in artifact-layout.md's phase table to inspect (see $SC005_AL_HITS)"
else
  fail "SC-005 context-in contract setup -- found ZERO council/council-gate rows in $REPO/docs/contracts/artifact-layout.md's phase table -- the check below would be a silent 0-row pass, which S10's discipline forbids"
fi

if grep -qE 'renders/|\.pptx' "$SC005_AL_HITS"; then
  fail "SC-005 not in council context-in -- artifact-layout.md's council/council-gate phase-table row(s) reference a renders/ path or a .pptx file: $(cat "$SC005_AL_HITS") -- the contract itself would admit a render as context-in"
else
  pass "SC-005 not in council context-in -- artifact-layout.md's council row (context-in: defense-deck/, plan.md, spec.md, graphify query tool) and council-gate row (context-in: overview.md, suggestions.md, decision-record.md) name no renders/ path or .pptx file"
fi

SC005_COUNCIL_DIRS="$SC005/council-dirs.txt"
find "$REPO/specs" -maxdepth 2 -type d -name 'council' | sort > "$SC005_COUNCIL_DIRS"

if [ -s "$SC005_COUNCIL_DIRS" ]; then
  pass "SC-005 not in council context-in setup -- found $(wc -l < "$SC005_COUNCIL_DIRS" | tr -d ' ') committed council/ subtree(s) under $REPO/specs to inspect (see $SC005_COUNCIL_DIRS)"
else
  fail "SC-005 not in council context-in setup -- found ZERO council/ subtrees under $REPO/specs -- the check below would be a silent 0-tree pass, which S10's discipline forbids"
fi

SC005_COUNCIL_HITS="$SC005/council-hits.txt"
: > "$SC005_COUNCIL_HITS"
while read -r sc005_council_dir; do
  [ -n "$sc005_council_dir" ] || continue
  grep -rHnE 'renders/[A-Za-z0-9_.-]*\.pptx' "$sc005_council_dir" >> "$SC005_COUNCIL_HITS" 2>/dev/null || true
done < "$SC005_COUNCIL_DIRS"

if [ -s "$SC005_COUNCIL_HITS" ]; then
  fail "SC-005 not in council context-in -- $(wc -l < "$SC005_COUNCIL_HITS" | tr -d ' ') line(s) across the committed council/ subtrees reference a literal renders/<name>.pptx artifact path, e.g. $(head -n 1 "$SC005_COUNCIL_HITS") -- a council session's context-in must be .md decks only"
else
  pass "SC-005 not in council context-in -- none of the $(wc -l < "$SC005_COUNCIL_DIRS" | tr -d ' ') committed council/ subtree(s) (decision-record.md, defense-deck/, round-N/opinions/, suggestions.md, across every feature including 006's own self-referential review) contain a literal renders/<name>.pptx artifact-path reference -- a council session's inputs are the .md decks under council/defense-deck/, never a renders/ path"
fi

# ---------------------------------------------------------------------------
section "6. SC-006 free -- render is trace-free and costs zero tokens (FR-011, /speckit-git-cleanup precedent)"
# The guarantee under test (SC-006/FR-011; plan.md's "model-free => trace-
# free => free" reasoning): render.py is a deterministic, mechanical
# transform -- never a session -- so it appends NO record to traces.jsonl
# and spends NO tokens, exactly the /speckit-git-cleanup FR-007 precedent
# plan.md names ("mechanical, model-free steps leave no trace record --
# traces record sessions", D35). This is a LIBRARY-INDEPENDENT property:
# render.py never even reaches its one lazy `import pptx` site (FR-015/R2,
# inside `_render_deck()`'s try block) until long after any traces.jsonl
# write would have had to happen -- so the trace-free guarantee holds
# identically whether the render below actually RENDERS or DEGRADES-and-
# discloses (SC-004's branch; python-pptx is confirmed ABSENT on this host
# per section 0's banner, so both renders below are expected to degrade).
# No require_pptx guard, deliberately -- mirroring SC-001/SC-005/SC-008
# above, the other library-independent sections.
#
# Setup: a throwaway feature dir (a SIBLING of this section's own scratch
# dir, never inside it -- the SC-001 precedent above, so this section's own
# helper/log files can never pollute the "no other trace/cost file under
# the feature dir" check below) carries BOTH fixture decks, a profile.yaml
# that actually SELECTS a render (fixtures/profiles/overview.yaml --
# deck_render: overview), and a PRE-SEEDED traces.jsonl of three realistic
# records (deck-prep, council-member, chairman -- the exact record shape
# docs/contracts/trace-schema.md Sec 1 documents, including the
# council-member role's role-scoped graph_queries/ceiling_hit pair, Sec
# 1/Sec 7 rule 12) -- so there IS a file with real content for "unchanged"
# to be a meaningful claim, never a vacuous empty-file check.
#
# Two renders run against the SAME feature dir, back to back: an EXPLICIT-
# arg render (`render.py technical --feature <dir>`, which per FR-016
# ignores the profile entirely) and a PROFILE-driven render (`render.py
# --feature <dir>`, no deck arg, so selection comes from profile.yaml's
# `deck_render: overview`) -- covering both of render.py's selection paths
# in one pass.
#
# The core assertion is byte-identity of traces.jsonl's sha256 before vs.
# after BOTH renders -- the strongest possible form (stronger than a
# record-count or role-count check alone, either of which a same-length,
# different-content mutation could pass vacuously). Record count, per-role
# counts, and a council_spend rollup computed per trace-schema.md Sec 5's
# OWN formula (tokens_billable = input+output+cache_creation, cache_read
# excluded -- "it is the saving, not the spend"; council_spend =
# phase_spend(council) + phase_spend(deck-prep)) are ALSO computed and
# compared independently below -- logically implied by the byte-identical
# check, but asserted explicitly anyway, since SC-006's own spec text names
# "council_spend... identical" as the falsifiable claim, not merely "the
# file didn't change".
SC006_SCRATCH="$TMP/sc006"
SC006="$SC006_SCRATCH/feature"
mkdir -p "$SC006/council/defense-deck"
cp "$FIXTURES/deck/technical.md" "$SC006/council/defense-deck/technical.md"
cp "$FIXTURES/deck/overview.md" "$SC006/council/defense-deck/overview.md"
cp "$FIXTURES/profiles/overview.yaml" "$SC006/profile.yaml"

SC006_TRACES="$SC006/traces.jsonl"
cat > "$SC006_TRACES" <<'JSONLEOF'
{"schema_version": "1.0", "trace_id": "trc_01SC006DECKPREP001", "parent_trace_id": null, "feature": "006-deck-render-sc006-fixture", "phase": "deck-prep", "role": "deck-prep", "agent_id": null, "skills": [], "elevated_grants": [], "model": "claude-sonnet-5", "effort": "medium", "started_at": "2026-07-10T09:00:00.000Z", "ended_at": "2026-07-10T09:04:12.500Z", "duration_ms": 252500, "tokens": {"input": 8000, "output": 2200, "cache_read": 1500, "cache_creation": 0}, "capture_method": "transcript", "outcome": "success", "artifact": "specs/006-deck-render-sc006-fixture/council/defense-deck/technical.md", "cost_usd": null}
{"schema_version": "1.0", "trace_id": "trc_01SC006COUNCILMEM01", "parent_trace_id": "trc_01SC006CHAIRMAN0001", "feature": "006-deck-render-sc006-fixture", "phase": "council", "role": "council-member", "agent_id": null, "skills": [], "elevated_grants": [], "model": "claude-sonnet-5", "effort": "medium", "started_at": "2026-07-10T09:10:00.000Z", "ended_at": "2026-07-10T09:13:45.000Z", "duration_ms": 225000, "tokens": {"input": 15000, "output": 3400, "cache_read": 9000, "cache_creation": 500}, "capture_method": "sdk", "outcome": "success", "artifact": null, "cost_usd": null, "graph_queries": 9, "ceiling_hit": false}
{"schema_version": "1.0", "trace_id": "trc_01SC006CHAIRMAN0001", "parent_trace_id": null, "feature": "006-deck-render-sc006-fixture", "phase": "council", "role": "chairman", "agent_id": null, "skills": [], "elevated_grants": [], "model": "claude-opus-4-8", "effort": "xhigh", "started_at": "2026-07-10T09:15:00.000Z", "ended_at": "2026-07-10T09:18:31.900Z", "duration_ms": 211900, "tokens": {"input": 22000, "output": 5100, "cache_read": 12000, "cache_creation": 1000}, "capture_method": "transcript", "outcome": "success", "artifact": "specs/006-deck-render-sc006-fixture/council/round-1/suggestions.md", "cost_usd": null}
JSONLEOF

SC006_SHA_PY="$SC006_SCRATCH/sha_one.py"
cat > "$SC006_SHA_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-006 single-file sha256 (T033 inline helper) -- mirrors SC-004's own
sha_one.py idiom (run.sh Sec 4 above): the strongest form of "unchanged" is
byte-identity of the raw file, independent of any parsed-content rollup.

Usage: sha_one.py FILE
"""
import hashlib
import sys

print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())
PYEOF

SC006_ROLLUP_PY="$SC006_SCRATCH/rollup.py"
cat > "$SC006_ROLLUP_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-006 trace rollup (T033 inline helper).

Three metrics off a traces.jsonl file, computed per
docs/contracts/trace-schema.md Sec 5's OWN rollup formulas -- never a
re-derived one:

  records        total record (line) count.
  roles          role -> count for every DISTINCT role present, one
                 "role:count" entry per role, sorted alphabetically by role
                 name for a stable, diffable ordering.
  council_spend  phase_spend(f, "council") + phase_spend(f, "deck-prep"),
                 where phase_spend sums tokens_billable(r) = 0 if
                 r["tokens"] is None else input+output+cache_creation
                 (cache_read excluded -- Sec 5: "it is the saving, not the
                 spend") over every record in that phase.

Invoked TWICE by run.sh's SC-006 section -- once before, once after the
render(s) under test -- so the two output files can be `cmp -s`'d for exact
rollup equality, independently of (and in addition to) the raw-file sha256
byte-identity check.

Usage: rollup.py TRACES_JSONL_PATH
"""
import json
import sys
from collections import Counter

path = sys.argv[1]

records = []
with open(path, "r", encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        records.append(json.loads(line))

role_counts = Counter(r.get("role") for r in records)


def tokens_billable(r):
    tokens = r.get("tokens")
    if tokens is None:
        return 0
    return tokens["input"] + tokens["output"] + tokens["cache_creation"]


council_spend = sum(
    tokens_billable(r) for r in records if r.get("phase") in ("council", "deck-prep")
)

print("records=%d" % len(records))
print("roles=" + ",".join("%s:%d" % (role, count) for role, count in sorted(role_counts.items())))
print("council_spend=%d" % council_spend)
PYEOF

# ---- BEFORE snapshot: raw sha256, parsed rollup, and the feature dir's own
# trace/cost-file inventory (scoped to $SC006 -- the feature dir under test
# -- never $SC006_SCRATCH, which holds this section's own helper/log files
# and would otherwise self-pollute the "no other trace/cost file" check).
SC006_SHA_BEFORE="$SC006_SCRATCH/traces-before.sha256"
SC006_ROLLUP_BEFORE="$SC006_SCRATCH/rollup-before.txt"
"$PY" "$SC006_SHA_PY" "$SC006_TRACES" > "$SC006_SHA_BEFORE"
"$PY" "$SC006_ROLLUP_PY" "$SC006_TRACES" > "$SC006_ROLLUP_BEFORE"

SC006_TRACE_FILES_BEFORE="$SC006_SCRATCH/trace-files-before.txt"
find "$SC006" -type f \( -iname '*trace*' -o -iname '*.jsonl' \) | sort > "$SC006_TRACE_FILES_BEFORE"

# ---- the renders themselves: an explicit-arg render, then a profile-driven
# render, both against the SAME feature dir -----------------------------
SC006_LOG_EXPLICIT="$SC006_SCRATCH/render-explicit.log"
sc006_explicit_rc=0
"$PY" "$RENDER_PY" technical --feature "$SC006" >"$SC006_LOG_EXPLICIT" 2>&1 || sc006_explicit_rc=$?

SC006_LOG_PROFILE="$SC006_SCRATCH/render-profile.log"
sc006_profile_rc=0
"$PY" "$RENDER_PY" --feature "$SC006" >"$SC006_LOG_PROFILE" 2>&1 || sc006_profile_rc=$?

if grep -q "Traceback (most recent call last)" "$SC006_LOG_EXPLICIT" "$SC006_LOG_PROFILE" 2>/dev/null; then
  fail "SC-006 setup -- render.py produced an uncaught Python traceback in the explicit-arg (exit $sc006_explicit_rc) or profile-driven (exit $sc006_profile_rc) render -- see $SC006_LOG_EXPLICIT / $SC006_LOG_PROFILE"
else
  pass "SC-006 setup -- ran BOTH an explicit-arg render (render.py technical --feature <dir>, exit $sc006_explicit_rc, FR-016 ignores the profile entirely) and a profile-driven render (render.py --feature <dir>, deck_render: overview via fixtures/profiles/overview.yaml, exit $sc006_profile_rc) against the SAME feature dir, neither producing an uncaught traceback -- library-independent (no require_pptx): whichever outcome fired (rendered, or degrade-and-disclose since python-pptx is ABSENT on this host per section 0's banner) is irrelevant to the trace-free property under test"
fi

# ---- AFTER snapshot: guarded against a (hypothetical) deleted traces.jsonl
# so a bug under test fails this check cleanly instead of crashing the
# harness via an unhandled Python exception under `set -eu`.
SC006_SHA_AFTER="$SC006_SCRATCH/traces-after.sha256"
SC006_ROLLUP_AFTER="$SC006_SCRATCH/rollup-after.txt"
if [ -f "$SC006_TRACES" ]; then
  "$PY" "$SC006_SHA_PY" "$SC006_TRACES" > "$SC006_SHA_AFTER"
  "$PY" "$SC006_ROLLUP_PY" "$SC006_TRACES" > "$SC006_ROLLUP_AFTER"
  pass "SC-006 traces.jsonl still exists -- render.py never deletes the pre-seeded trace file (it never opens traces.jsonl at all, FR-011)"
else
  : > "$SC006_SHA_AFTER"
  : > "$SC006_ROLLUP_AFTER"
  fail "SC-006 traces.jsonl MISSING after the render(s) -- the pre-seeded trace file was deleted; every comparison below will correctly fail as a consequence"
fi

SC006_TRACE_FILES_AFTER="$SC006_SCRATCH/trace-files-after.txt"
find "$SC006" -type f \( -iname '*trace*' -o -iname '*.jsonl' \) | sort > "$SC006_TRACE_FILES_AFTER"
SC006_COST_FILES_AFTER="$SC006_SCRATCH/cost-files-after.txt"
find "$SC006" -type f \( -iname '*cost*' -o -iname '*spend*' \) | sort > "$SC006_COST_FILES_AFTER"

# ---- (1) byte-identical: the strongest form of "unchanged" ----------------
if cmp -s "$SC006_SHA_BEFORE" "$SC006_SHA_AFTER"; then
  pass "SC-006 byte-identical -- traces.jsonl's sha256 is UNCHANGED across both the explicit-arg and the profile-driven render ($(cat "$SC006_SHA_BEFORE")) -- render.py appended NO record (FR-011); the strongest possible form of 'unchanged'"
else
  fail "SC-006 byte-identical -- traces.jsonl's sha256 CHANGED across the render(s) (before=$(cat "$SC006_SHA_BEFORE" 2>/dev/null || echo MISSING), after=$(cat "$SC006_SHA_AFTER" 2>/dev/null || echo MISSING)) -- a supposedly model-free, session-free transform wrote to the trace ledger"
fi

# ---- (2) record count / role-count / council_spend, computed per
# trace-schema.md Sec 5's own formula -- logically implied by (1) above, but
# asserted explicitly per SC-006's own "council_spend... identical" wording.
sc006_records_before=$(grep '^records=' "$SC006_ROLLUP_BEFORE" | cut -d= -f2)
sc006_records_after=$(grep '^records=' "$SC006_ROLLUP_AFTER" | cut -d= -f2)
sc006_roles_before=$(grep '^roles=' "$SC006_ROLLUP_BEFORE" | cut -d= -f2-)
sc006_roles_after=$(grep '^roles=' "$SC006_ROLLUP_AFTER" | cut -d= -f2-)
sc006_spend_before=$(grep '^council_spend=' "$SC006_ROLLUP_BEFORE" | cut -d= -f2)
sc006_spend_after=$(grep '^council_spend=' "$SC006_ROLLUP_AFTER" | cut -d= -f2)

if [ -n "$sc006_records_before" ] && [ "$sc006_records_before" = "$sc006_records_after" ]; then
  pass "SC-006 record count unchanged -- traces.jsonl carries $sc006_records_before record(s) both before and after the render(s) -- render.py appends none"
else
  fail "SC-006 record count changed -- traces.jsonl carried $sc006_records_before record(s) before the render(s), $sc006_records_after after -- render.py must never append a record (FR-011)"
fi

if [ -n "$sc006_roles_before" ] && [ "$sc006_roles_before" = "$sc006_roles_after" ]; then
  pass "SC-006 role-count unchanged -- per-role record counts ($sc006_roles_before) are identical before and after the render(s) -- a rendered run's role-count is identical to an unrendered run's, exactly SC-006's own wording"
else
  fail "SC-006 role-count changed -- per-role counts were '$sc006_roles_before' before the render(s), '$sc006_roles_after' after -- render.py must never add (or remove) a role's trace record"
fi

if [ -n "$sc006_spend_before" ] && [ "$sc006_spend_before" = "$sc006_spend_after" ]; then
  pass "SC-006 council_spend unchanged -- the trace-schema.md Sec 5 council_spend rollup (phase_spend(council) + phase_spend(deck-prep)) is $sc006_spend_before token(s) both before and after the render(s) -- the render adds ZERO tokens (FR-011/SC-006)"
else
  fail "SC-006 council_spend changed -- council_spend rollup was $sc006_spend_before token(s) before the render(s), $sc006_spend_after after -- a model-free transform must add zero tokens"
fi

# ---- (3) no OTHER trace/cost file anywhere under the feature dir ----------
if cmp -s "$SC006_TRACE_FILES_BEFORE" "$SC006_TRACE_FILES_AFTER"; then
  pass "SC-006 no new trace file -- the set of trace-/.jsonl-named files under the feature dir is UNCHANGED by the render(s): exactly the one pre-seeded traces.jsonl, nothing else (see $SC006_TRACE_FILES_AFTER)"
else
  fail "SC-006 no new trace file -- the set of trace-/.jsonl-named files under the feature dir CHANGED (diff: $(diff "$SC006_TRACE_FILES_BEFORE" "$SC006_TRACE_FILES_AFTER" | head -10)) -- render.py must never create a second trace file anywhere in the feature dir"
fi

if [ -s "$SC006_COST_FILES_AFTER" ]; then
  fail "SC-006 no cost/spend file -- found $(wc -l < "$SC006_COST_FILES_AFTER" | tr -d ' ') cost-/spend-named file(s) under the feature dir after the render(s), e.g. $(head -n 1 "$SC006_COST_FILES_AFTER") -- render.py's cost is zero and nothing should record otherwise (D28: cost_usd is a field WITHIN traces.jsonl, never a separate ledger)"
else
  pass "SC-006 no cost/spend file -- zero cost-/spend-named files anywhere under the feature dir after the render(s) -- the only ledger this repo ever writes is traces.jsonl (D28), and SC-006 proves the render doesn't even touch that"
fi

# ---------------------------------------------------------------------------
section "10. SC-010 reinstall-survival + zero-hook seam integrity (FR-012/FR-013)"
# The guarantee under test (SC-010/FR-012/FR-013): deck-render declares ZERO
# hooks and makes NO source edit into the council or graphify extensions (its
# own extension.yml's header comment: "this extension cannot rot the council
# or graphify trees because it never reaches into them"). This section proves
# that claim mechanically, mirroring extensions/git/test/run.sh's own §3
# reinstall-survival model (S17 class) but with the roles reversed: THERE the
# git extension is the one under test and graphify/council are reinstalled
# around it; HERE deck-render is the one under test and council/graphify are
# reinstalled around it -- entirely inside a throwaway sandbox under $TMP,
# never touching this repo's own .specify/ or .claude/.
#
# Five properties, in order:
#   (1) a baseline ecosystem -- council + graphify installed ONCE into the
#       sandbox, exactly the "sandbox target with a .specify/extensions.yml
#       and the payload/skill dirs the installers expect" setup, produced the
#       same way extensions/git/test/run.sh's §3 produces it: by actually
#       running the sibling installers, never by hand-authoring extensions.yml
#       (council's own install.sh writes nothing there by design -- "no
#       before_* hooks to register" -- so this baseline's extensions.yml
#       content comes entirely from graphify's merge).
#   (2) deck-render installs cleanly on TOP of that ecosystem: payload, skill,
#       and the `installed:` entry all appear, and the installed render.py
#       resolves as a real, invokable command (`--help` exits 0).
#   (3) council + graphify are REINSTALLED (the actual regression class this
#       section exists to catch) -- and deck-render's payload, skill,
#       `installed:` entry, and command-resolves property all SURVIVE.
#   (4) FR-012's "seam cannot rot" property: a sha256 manifest of EVERY file
#       under the extensions/council/ and extensions/graphify/ SOURCE trees
#       (never the sandbox copies) is snapshotted before step (1) and again
#       after step (5) below, and asserted byte-identical -- deck-render's
#       install/reinstall/uninstall dance touches the sandbox only, never the
#       source trees of the extensions it coexists with.
#   (5) uninstall.sh round-trips .specify/extensions.yml BYTE-IDENTICALLY to
#       its pre-deck-render-install snapshot (captured at the end of step 1,
#       before deck-render ever touched the file) -- proving install-then-
#       uninstall leaves no residue in the shared registry even after two
#       foreign extensions wrote into it in between -- and removes the
#       payload + skill.
#
# No require_pptx guard: this is a pure install/uninstall lifecycle property,
# no python-pptx toolchain involved anywhere (library-independent, like
# SC-001/SC-005/SC-006/SC-008 above).
SC010="$TMP/sc010"
SC010_TARGET="$SC010/target"
mkdir -p "$SC010_TARGET/.specify" "$SC010_TARGET/.claude/skills"

SC010_COUNCIL_EXT="$REPO/extensions/council"
SC010_GRAPHIFY_EXT="$REPO/extensions/graphify"

# ---- manifest helper: sha256 of every regular file under one or more
# LABEL:ROOTDIR arguments, sorted for a stable diffable ordering. Written to a
# scratch file (never a `python3 -c` one-liner) purely for readability,
# mirroring the SC-003/SC-002/SC-006 sections' own idiom above -- it never
# ships (lives only under $TMP).
SC010_MANIFEST_PY="$SC010/manifest.py"
cat > "$SC010_MANIFEST_PY" <<'PYEOF'
#!/usr/bin/env python3
"""SC-010 source-tree manifest (T034 inline helper).

Recursively hashes every regular file under one or more given root
directories, printing one line per file: "<sha256>  <label>/<relpath>",
sorted for a stable, diffable ordering. Used by run.sh's SC-010 section to
snapshot the extensions/council/ and extensions/graphify/ SOURCE trees before
and after a deck-render install/reinstall/uninstall dance, and assert
byte-for-byte that no file anywhere in either tree was added, removed, or
modified (FR-012's "seam cannot rot" property).

Usage: manifest.py LABEL:ROOTDIR [LABEL:ROOTDIR ...]
"""
import hashlib
import sys
from pathlib import Path

lines = []
for arg in sys.argv[1:]:
    label, root = arg.split(":", 1)
    root_path = Path(root)
    for path in sorted(root_path.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root_path).as_posix()
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append("%s  %s/%s" % (digest, label, rel))

lines.sort()
print("\n".join(lines))
PYEOF

# ---- BEFORE snapshot: taken before ANY install below runs, so it captures
# the two source trees exactly as this repo's own working tree has them.
SC010_MANIFEST_BEFORE="$SC010/manifest-before.txt"
"$PY" "$SC010_MANIFEST_PY" "council:$SC010_COUNCIL_EXT" "graphify:$SC010_GRAPHIFY_EXT" > "$SC010_MANIFEST_BEFORE"

# ---- (1) baseline ecosystem: council + graphify installed ONCE ------------
sc010_council_rc1=0
sh "$SC010_COUNCIL_EXT/install.sh" "$SC010_TARGET" >"$SC010/council-install-1.log" 2>&1 || sc010_council_rc1=$?
sc010_graphify_rc1=0
sh "$SC010_GRAPHIFY_EXT/install.sh" "$SC010_TARGET" >"$SC010/graphify-install-1.log" 2>&1 || sc010_graphify_rc1=$?

if [ "$sc010_council_rc1" -eq 0 ] && [ "$sc010_graphify_rc1" -eq 0 ]; then
  pass "SC-010 setup -- baseline council + graphify install into the throwaway sandbox both exited 0 (see $SC010_TARGET)"
else
  fail "SC-010 setup -- baseline council (exit $sc010_council_rc1) or graphify (exit $sc010_graphify_rc1) install failed -- see $SC010/council-install-1.log / $SC010/graphify-install-1.log -- every check below cannot be trusted"
fi

SC010_EXT_YML="$SC010_TARGET/.specify/extensions.yml"
SC010_YML_PRE="$SC010/extensions.yml.pre-deck-render"
if [ -f "$SC010_EXT_YML" ]; then
  cp "$SC010_EXT_YML" "$SC010_YML_PRE"
else
  : > "$SC010_YML_PRE"   # council's own install.sh writes nothing to extensions.yml by design; graphify's merge is what creates the file above
fi

# ---- (2) install deck-render on top of that ecosystem ---------------------
SC010_DECK_PAYLOAD="$SC010_TARGET/.specify/extensions/deck-render"
SC010_DECK_SKILL="$SC010_TARGET/.claude/skills/speckit-deck-render"
sc010_deck_install_rc=0
sh "$DECK_EXT/install.sh" "$SC010_TARGET" >"$SC010/deck-install.log" 2>&1 || sc010_deck_install_rc=$?

if [ "$sc010_deck_install_rc" -eq 0 ]; then
  pass "SC-010 deck-render install -- install.sh exited 0 against the sandbox (see $SC010/deck-install.log)"
else
  fail "SC-010 deck-render install -- install.sh exited $sc010_deck_install_rc -- see $SC010/deck-install.log -- survival checks below cannot be trusted"
fi

if [ -f "$SC010_DECK_PAYLOAD/scripts/render.py" ]; then
  pass "SC-010 payload present -- .specify/extensions/deck-render/scripts/render.py after install"
else
  fail "SC-010 payload MISSING -- .specify/extensions/deck-render/scripts/render.py not found after install"
fi
if [ -f "$SC010_DECK_SKILL/SKILL.md" ]; then
  pass "SC-010 skill present -- .claude/skills/speckit-deck-render/SKILL.md after install"
else
  fail "SC-010 skill MISSING -- .claude/skills/speckit-deck-render/SKILL.md not found after install"
fi
# `installed:` is the top-level, zero-indent list PyYAML's default_flow_style
# writer produces (verified against install.sh's own merge output); every
# nested hook-list item is indented under its hooks:/<hook-name>: key, so an
# anchored zero-indent match is unambiguous here -- deck-render is never a
# value anywhere else in the file.
if grep -q '^- deck-render$' "$SC010_EXT_YML" 2>/dev/null; then
  pass "SC-010 installed: entry present -- 'deck-render' listed in .specify/extensions.yml's installed: list after install"
else
  fail "SC-010 installed: entry MISSING -- 'deck-render' not found in .specify/extensions.yml's installed: list after install"
fi
if "$PY" "$SC010_DECK_PAYLOAD/scripts/render.py" --help >"$SC010/render-help-1.log" 2>&1; then
  pass "SC-010 command resolves -- the installed render.py --help exits 0 right after install (see $SC010/render-help-1.log)"
else
  fail "SC-010 command does not resolve -- the installed render.py --help failed right after install -- see $SC010/render-help-1.log"
fi

# ---- (3) THE regression: reinstall council + graphify, then re-check ------
sc010_council_rc2=0
sh "$SC010_COUNCIL_EXT/install.sh" "$SC010_TARGET" >"$SC010/council-install-2.log" 2>&1 || sc010_council_rc2=$?
sc010_graphify_rc2=0
sh "$SC010_GRAPHIFY_EXT/install.sh" "$SC010_TARGET" >"$SC010/graphify-install-2.log" 2>&1 || sc010_graphify_rc2=$?

if [ "$sc010_council_rc2" -eq 0 ] && [ "$sc010_graphify_rc2" -eq 0 ]; then
  pass "SC-010 reinstall -- council + graphify install.sh both exited 0 a SECOND time against the same sandbox (the S17 reinstall-survival class)"
else
  fail "SC-010 reinstall -- council (exit $sc010_council_rc2) or graphify (exit $sc010_graphify_rc2) reinstall failed -- see $SC010/council-install-2.log / $SC010/graphify-install-2.log -- survival checks below cannot be trusted"
fi

if [ -f "$SC010_DECK_PAYLOAD/scripts/render.py" ]; then
  pass "SC-010 payload SURVIVED council + graphify reinstall"
else
  fail "SC-010 payload WIPED by council + graphify reinstall -- the S17 hazard, FR-012"
fi
if [ -f "$SC010_DECK_SKILL/SKILL.md" ]; then
  pass "SC-010 skill SURVIVED council + graphify reinstall"
else
  fail "SC-010 skill WIPED by council + graphify reinstall -- the S17 hazard, FR-012"
fi
if grep -q '^- deck-render$' "$SC010_EXT_YML" 2>/dev/null; then
  pass "SC-010 installed: entry SURVIVED council + graphify reinstall"
else
  fail "SC-010 installed: entry LOST after council + graphify reinstall -- the S17 hazard, FR-012"
fi
if "$PY" "$SC010_DECK_PAYLOAD/scripts/render.py" --help >"$SC010/render-help-2.log" 2>&1; then
  pass "SC-010 command SURVIVED reinstall -- the installed render.py --help still exits 0 after council + graphify reinstall (see $SC010/render-help-2.log)"
else
  fail "SC-010 command no longer resolves -- the installed render.py --help failed after council + graphify reinstall -- see $SC010/render-help-2.log"
fi

# ---- (5) uninstall deck-render; byte-identical registry round-trip --------
sc010_deck_uninstall_rc=0
sh "$DECK_EXT/uninstall.sh" "$SC010_TARGET" >"$SC010/deck-uninstall.log" 2>&1 || sc010_deck_uninstall_rc=$?

if [ "$sc010_deck_uninstall_rc" -eq 0 ]; then
  pass "SC-010 deck-render uninstall -- uninstall.sh exited 0 (see $SC010/deck-uninstall.log)"
else
  fail "SC-010 deck-render uninstall -- uninstall.sh exited $sc010_deck_uninstall_rc -- see $SC010/deck-uninstall.log -- round-trip checks below cannot be trusted"
fi

if cmp -s "$SC010_YML_PRE" "$SC010_EXT_YML"; then
  pass "SC-010 byte-identical round-trip -- .specify/extensions.yml after uninstall is BYTE-IDENTICAL to its pre-deck-render-install snapshot ($(wc -c < "$SC010_YML_PRE" | tr -d ' ') bytes) -- install-then-uninstall leaves no residue in the shared registry even after two foreign extensions wrote into it in between"
else
  fail "SC-010 byte-identical round-trip -- .specify/extensions.yml after uninstall DIFFERS from its pre-deck-render-install snapshot (diff: $(diff "$SC010_YML_PRE" "$SC010_EXT_YML" | head -10))"
fi
if [ -d "$SC010_DECK_PAYLOAD" ]; then
  fail "SC-010 payload NOT removed -- .specify/extensions/deck-render/ still present after uninstall"
else
  pass "SC-010 payload removed -- .specify/extensions/deck-render/ absent after uninstall"
fi
if [ -d "$SC010_DECK_SKILL" ]; then
  fail "SC-010 skill NOT removed -- .claude/skills/speckit-deck-render/ still present after uninstall"
else
  pass "SC-010 skill removed -- .claude/skills/speckit-deck-render/ absent after uninstall"
fi

# ---- (4) FR-012: the two SOURCE trees are byte-for-byte untouched ---------
# Taken AFTER the whole dance (baseline install, deck-render install,
# reinstall, uninstall) -- the strongest available window, since it covers
# every filesystem-mutating step this section runs, not just the reinstall.
SC010_MANIFEST_AFTER="$SC010/manifest-after.txt"
"$PY" "$SC010_MANIFEST_PY" "council:$SC010_COUNCIL_EXT" "graphify:$SC010_GRAPHIFY_EXT" > "$SC010_MANIFEST_AFTER"

if cmp -s "$SC010_MANIFEST_BEFORE" "$SC010_MANIFEST_AFTER"; then
  pass "SC-010 source trees untouched -- sha256 manifest of every file under extensions/council/ and extensions/graphify/ (SOURCE, never the sandbox copies) is byte-identical before vs. after the whole install/reinstall/uninstall dance -- FR-012's 'seam cannot rot' property"
else
  fail "SC-010 source trees MODIFIED -- the sha256 manifest of extensions/council/ and/or extensions/graphify/ changed across the dance (diff: $(diff "$SC010_MANIFEST_BEFORE" "$SC010_MANIFEST_AFTER" | head -10)) -- deck-render's install/reinstall/uninstall must never write into another extension's source tree (FR-012)"
fi

# ---------------------------------------------------------------------------
section "11. S11 co-install -- realistic multi-extension installed: list survives a round-trip (FR-012/FR-013)"
# The guarantee under test (S11, plan.md's SC-010 paragraph): the
# `.specify/extensions.yml` `installed:` list is a SHARED-mutation point --
# every extension's install.sh/uninstall.sh merges into the SAME file, and
# deck-render's own install.sh header comments name this merge point as
# otherwise un-instrumented. SC-010 above already proves deck-render
# SURVIVES being reinstalled AROUND BY council/graphify; this section proves
# the reverse direction: deck-render's OWN install/uninstall, run against a
# manifest that ALREADY carries several other extensions' entries, never
# disturbs, reorders, or corrupts what was there first.
#
# The baseline is not a hand-authored fixture -- it is a byte-for-byte COPY
# of THIS repo's own real .specify/extensions.yml (opened for reading
# exactly once, to make the copy; never written to), the actual "graphify +
# git + workforce + testing" installed state a real checkout of this repo
# carries today -- a realistic combined manifest, not an invented one (the
# same reason SC-003/SC-002 above read fixtures from $FIXTURES rather than
# inlining invented markdown). Everything else happens in a throwaway
# sandbox under $TMP.
#
# No require_pptx guard: this is a pure registry-merge lifecycle property,
# no python-pptx toolchain involved anywhere -- library-independent, like
# SC-001/SC-005/SC-006/SC-008/SC-010 above, so it PASSES on this host.
S11="$TMP/s11"
S11_TARGET="$S11/target"
mkdir -p "$S11_TARGET/.specify"

S11_REAL_EXT_YML="$REPO/.specify/extensions.yml"
S11_EXT_YML="$S11_TARGET/.specify/extensions.yml"

if [ -f "$S11_REAL_EXT_YML" ]; then
  cp "$S11_REAL_EXT_YML" "$S11_EXT_YML"
  pass "S11 setup -- combined baseline manifest copied from this repo's own .specify/extensions.yml (read-only source) into the throwaway sandbox"
else
  : > "$S11_EXT_YML"   # keep the rest of this section running on an (empty) file rather than crashing the whole suite
  fail "S11 setup -- this repo's own .specify/extensions.yml is missing -- cannot build a realistic combined baseline; every check below cannot be trusted"
fi

# ---- (1) snapshot the combined baseline, BEFORE deck-render ever touches it
S11_YML_PRE="$S11/extensions.yml.pre-deck-render"
cp "$S11_EXT_YML" "$S11_YML_PRE"

# `installed:` is the top-level, zero-indent list (see SC-010's own note
# above); every foreign extension id this repo's real manifest lists today
# must be present in the baseline for this to be a REALISTIC co-install
# fixture, per S11's own requirement (at least graphify, git, workforce,
# testing).
s11_missing_baseline=""
for s11_ext in graphify git workforce testing; do
  if ! grep -q "^- ${s11_ext}\$" "$S11_YML_PRE"; then
    s11_missing_baseline="$s11_missing_baseline $s11_ext"
  fi
done
if [ -z "$s11_missing_baseline" ]; then
  pass "S11 baseline realism -- the combined manifest's installed: list already carries graphify, git, workforce, and testing (this repo's real co-install state) before deck-render is ever installed"
else
  fail "S11 baseline realism --$s11_missing_baseline missing from the copied manifest's installed: list -- this repo's own .specify/extensions.yml no longer matches the S11 baseline this test assumes"
fi

# The pre-existing installed: entries, in order -- extracted once here so
# both the install-time and uninstall-time assertions below compare against
# the SAME expected ordering, never a second, drift-prone re-derivation.
S11_PRE_INSTALLED="$S11/installed-pre.txt"
awk '/^installed:$/ { flag=1; next } /^[^ -]/ { flag=0 } flag' "$S11_YML_PRE" > "$S11_PRE_INSTALLED"

# ---- (2) install deck-render on top of the combined baseline --------------
S11_INSTALL_LOG="$S11/install.log"
s11_install_rc=0
sh "$DECK_EXT/install.sh" "$S11_TARGET" >"$S11_INSTALL_LOG" 2>&1 || s11_install_rc=$?

if [ "$s11_install_rc" -eq 0 ]; then
  pass "S11 install -- deck-render's install.sh exited 0 against the combined multi-extension sandbox (see $S11_INSTALL_LOG)"
else
  fail "S11 install -- deck-render's install.sh exited $s11_install_rc against the combined multi-extension sandbox -- see $S11_INSTALL_LOG -- checks below cannot be trusted"
fi

if grep -q '^- deck-render$' "$S11_EXT_YML" 2>/dev/null; then
  pass "S11 installed: entry added -- 'deck-render' now listed in the combined manifest's installed: list"
else
  fail "S11 installed: entry MISSING -- 'deck-render' not found in the combined manifest's installed: list after install"
fi

# The pre-existing entries survive, IN ORDER, with deck-render appended as
# the sole new entry -- never reordered, dropped, or duplicated.
S11_EXPECTED_POST_INSTALLED="$S11/installed-post-expected.txt"
cat "$S11_PRE_INSTALLED" > "$S11_EXPECTED_POST_INSTALLED"
printf -- '- deck-render\n' >> "$S11_EXPECTED_POST_INSTALLED"
S11_POST_INSTALLED="$S11/installed-post-actual.txt"
awk '/^installed:$/ { flag=1; next } /^[^ -]/ { flag=0 } flag' "$S11_EXT_YML" > "$S11_POST_INSTALLED" 2>/dev/null || : > "$S11_POST_INSTALLED"

if cmp -s "$S11_EXPECTED_POST_INSTALLED" "$S11_POST_INSTALLED"; then
  pass "S11 install doesn't disturb others -- every pre-existing installed: entry (graphify, git, workforce, testing) is present in the SAME order after install, with deck-render appended as the sole new line"
else
  fail "S11 install DISTURBED the pre-existing installed: entries -- expected [$(tr '\n' ' ' < "$S11_EXPECTED_POST_INSTALLED")] but got [$(tr '\n' ' ' < "$S11_POST_INSTALLED")]"
fi

# The strongest form of the same claim, at the whole-FILE level rather than
# just the installed: block: a diff between the pre-install snapshot and the
# post-install file must show EXACTLY one added line (deck-render's row) and
# ZERO removed/changed lines anywhere else in the file -- hooks: blocks,
# settings:, every other extension's rows included. This is what "byte-for-
# byte unchanged except for the single added line" (this task's own wording)
# means mechanically: not merely that the installed: list still contains the
# same ids, but that no other byte in the file moved.
S11_INSTALL_DIFF="$S11/diff-after-install.txt"
diff "$S11_YML_PRE" "$S11_EXT_YML" > "$S11_INSTALL_DIFF" 2>&1 || true
S11_ADDED="$S11/diff-added.txt"
S11_REMOVED="$S11/diff-removed.txt"
grep '^> ' "$S11_INSTALL_DIFF" > "$S11_ADDED" 2>/dev/null || : > "$S11_ADDED"
grep '^< ' "$S11_INSTALL_DIFF" > "$S11_REMOVED" 2>/dev/null || : > "$S11_REMOVED"
s11_added_count=$(wc -l < "$S11_ADDED" | tr -d ' ')
s11_removed_count=$(wc -l < "$S11_REMOVED" | tr -d ' ')

if [ "$s11_removed_count" -eq 0 ] && [ "$s11_added_count" -eq 1 ] && grep -q '^> - deck-render$' "$S11_INSTALL_DIFF"; then
  pass "S11 whole-file diff -- install added EXACTLY one line ('- deck-render') and changed/removed NOTHING else in the file (0 removed, 1 added) -- the shared installed:-merge point left every other extension's hooks/rows byte-for-byte untouched"
else
  fail "S11 whole-file diff -- install's diff against the pre-install snapshot shows $s11_removed_count removed line(s) and $s11_added_count added line(s), not the expected 0 removed / 1 added -- see $S11_INSTALL_DIFF"
fi

# ---- (3) uninstall deck-render; the combined manifest round-trips ---------
S11_UNINSTALL_LOG="$S11/uninstall.log"
s11_uninstall_rc=0
sh "$DECK_EXT/uninstall.sh" "$S11_TARGET" >"$S11_UNINSTALL_LOG" 2>&1 || s11_uninstall_rc=$?

if [ "$s11_uninstall_rc" -eq 0 ]; then
  pass "S11 uninstall -- deck-render's uninstall.sh exited 0 against the combined multi-extension sandbox (see $S11_UNINSTALL_LOG)"
else
  fail "S11 uninstall -- deck-render's uninstall.sh exited $s11_uninstall_rc -- see $S11_UNINSTALL_LOG -- the round-trip check below cannot be trusted"
fi

if cmp -s "$S11_YML_PRE" "$S11_EXT_YML"; then
  pass "S11 byte-identical round-trip -- the combined manifest after uninstall is BYTE-IDENTICAL to its pre-deck-render-install snapshot ($(wc -c < "$S11_YML_PRE" | tr -d ' ') bytes) -- graphify/git/workforce/testing's entries are perfectly restored, undisturbed by deck-render's own install-then-uninstall"
else
  fail "S11 byte-identical round-trip -- the combined manifest after uninstall DIFFERS from its pre-deck-render-install snapshot (diff: $(diff "$S11_YML_PRE" "$S11_EXT_YML" | head -10))"
fi

report
