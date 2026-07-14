#!/usr/bin/env sh
#
# consumer-deck-prep/cmd.sh — T033 [US3] consumer fixture 6 (005-graphify-context).
#
# Non-regression guard: deck-prep reads the receipts diet unbroken. T021 edited the REAL
# production template extensions/council/extension/templates/deck-technical.md so deck-prep
# mines graphify-receipts.md (arm-3's D62 concept/rationale enrichment source) rather than
# restating spec.md/plan.md prose unverified. This fixture reads that real template (never a
# copy under input/ — the whole point is to catch a regression IN the production file) plus
# its own committed exemplar diet, and asserts both halves of the D62 lockstep:
#
#   (a) deck-technical.md's **Sources** line names graphify-receipts.md, AND a distinct
#       instruction in that same template tells deck-prep to mine the diet's two named
#       sections (## Concept / rationale receipts, ## Contracts cited) — grep-only, no LLM.
#   (b) this fixture's own minimal exemplar graphify-receipts.md actually carries both of
#       those sections, so the instruction in (a) has something real to point at.
#
# Line-based substring checks (a2-a4 below) assume deck-technical.md's convention of one
# paragraph per physical line (true of every paragraph in that file today, verified by hand
# against the committed template) -- a future reflow that hard-wraps the D62 blockquote across
# multiple lines would need this fixture's extraction updated to match, same as any other
# fixture pinned to a template's current prose shape.
#
# Runs under `sh` with $REPO exported by run.sh; does not depend on the caller's cwd.
set -u
cd "$(dirname "$0")"

DECK="$REPO/extensions/council/extension/templates/deck-technical.md"
EXEMPLAR="input/graphify-receipts.md"

overall_rc=0
n_pass=0
n_fail=0

# check <label> <command...> — PASS iff <command...> exits 0 (direct, no-pipe checks).
check() {
  label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    n_pass=$((n_pass + 1))
    printf '  PASS %s\n' "$label"
  else
    n_fail=$((n_fail + 1))
    overall_rc=1
    printf '  FAIL %s\n' "$label"
  fi
}

# check_str <label> <haystack> <needle> — PASS iff <needle> is a literal substring of
# <haystack>. A `case` glob match, not grep, so a haystack captured via command substitution
# needs no extra subshell/pipe (needles below contain no glob metacharacters).
check_str() {
  label="$1"
  haystack="$2"
  needle="$3"
  case "$haystack" in
    *"$needle"*)
      n_pass=$((n_pass + 1))
      printf '  PASS %s\n' "$label"
      ;;
    *)
      n_fail=$((n_fail + 1))
      overall_rc=1
      printf '  FAIL %s\n' "$label"
      ;;
  esac
}

echo "consumer-deck-prep:"

# --- (a) deck-technical.md: Sources line + mining instruction -----------------------------

check '(a1) **Sources** line names graphify-receipts.md' \
  grep -qE '^\*\*Sources\*\*.*graphify-receipts\.md`' "$DECK"

# Isolate the instructional line(s) that mention graphify-receipts.md, excluding the Sources
# line itself, so a2-a4 assert the MINING INSTRUCTION specifically, not just any mention.
mining_line="$(grep -F 'graphify-receipts.md' "$DECK" | grep -v '^\*\*Sources\*\*:')"

check_str '(a2) an instruction mines graphify-receipts.md ("Mine its")' \
  "$mining_line" 'Mine its'
check_str '(a3) that instruction cites the "## Concept / rationale receipts" section' \
  "$mining_line" '`## Concept / rationale receipts`'
check_str '(a4) that instruction cites the "## Contracts cited" section' \
  "$mining_line" '`## Contracts cited`'

# --- (b) exemplar diet: both sections present ----------------------------------------------

check '(b1) exemplar graphify-receipts.md carries "## Concept / rationale receipts"' \
  grep -qxF '## Concept / rationale receipts' "$EXEMPLAR"
check '(b2) exemplar graphify-receipts.md carries "## Contracts cited"' \
  grep -qxF '## Contracts cited' "$EXEMPLAR"

echo "consumer-deck-prep: $((n_pass + n_fail)) checks, $n_pass passed, $n_fail failed"

exit "$overall_rc"
