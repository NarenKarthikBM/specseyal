#!/usr/bin/env sh
#
# speckit-ext-workforce — validate-skill.py CODE-gate tests (T026)
#
# Zero-AI, CI-runnable, no model calls: the skill-builder session itself is an LLM
# and not unit-testable (its output is non-reproducible prose-to-module authorship
# -- the same reasoning test_categorize.sh's own header gives for the categorizer
# session). What IS unit-testable, and what this harness exercises exhaustively, is
# the CODE gate that stands between a generated draft and persistence --
# extension/scripts/validate-skill.py -- against fixtures under
# extensions/workforce/test/fixtures/skill-builder/. Covers:
#
#   1. Additive-only PASS -- a conforming generated SKILL.md (the fixed anchor line,
#      grants: [], tags intersecting the triggering task) -> exit 0.
#   2. FR-007/S9 -- four ISOLATED violations, each its own fixture differing from
#      the PASS fixture by exactly one property (so the failure is attributable to
#      that one property, not some other latent defect):
#        (a) S1 negation        -- the body says "ignore" the base
#        (b) S3 relaxation      -- "optional:" / "at your discretion"
#        (c) S3 structural      -- the fixed additive anchor line is omitted
#        (d) S2 dispatch content -- a top-level `model:` key in the frontmatter
#      each -> exit non-zero, reported via REJECTED:/"Not persisted" on stderr.
#      NOTE: unlike validate-categorization.py's 2-arg gate+write CLI form (S22,
#      test_categorize.sh section 2), validate-skill.py has NO write-capable code
#      path at all -- validate_skill() only reads, main() only prints (read the
#      module: there is no open(...,'w') anywhere in it). "Not persisted" is
#      therefore a structural guarantee by absence of any write, not a file-state
#      race this harness needs to assert by diffing a directory; persistence is a
#      *caller* action (/speckit-agent-assign step 2.b.vi) gated on this script's
#      exit code, which is exactly what these assertions confirm fires correctly.
#   3. S04 -- a structurally-valid skill whose taxonomy.tags do NOT intersect the
#      triggering task's tags -> exit non-zero (the check that actually closes the
#      ∅-match gap assemble.py found; skill-module.md/data-model.md S3). A positive
#      control re-validates the SAME fixture against its OWN tag -> exit 0, so the
#      rejection above is attributable to S04 alone.
#   4. D41 -- a skill re-declaring a core-toolset name as a grant (`grants: [Bash]`)
#      -> exit non-zero (agent-library-schema.md S6 rule 9).
#   5. SC-007/S24 dedup -- see the long comment in section 5 below for exactly how
#      this harness draws the testable-vs-orchestration line: the "exactly ONE
#      persisted, not one-per-task" half is /speckit-agent-assign's (T025)
#      connected-components GROUPING of GAP_TASKS -- LLM-dispatch orchestration
#      logic living in a command's prose, with no script entry point this harness
#      could call. What's proven here instead is the necessary VALIDATOR-side
#      precondition that grouping design relies on: one persisted skill is CAPABLE
#      of covering >=2 tasks' shared-tag gap at once.
#
# Runs entirely against the frozen fixtures + a throwaway TMP dir; never touches the
# frozen fixtures, the live .claude/ library, or any file outside
# extensions/workforce/test/. Writes nothing itself -- validate-skill.py has no
# write-capable code path (see section 2's note above).
#
# Usage:  sh extensions/workforce/test/test_skill_builder.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"                 # repo root (…/specseyal)
WF="$REPO/extensions/workforce"
VALIDATE="$WF/extension/scripts/validate-skill.py"
FIX="$WF/test/fixtures/skill-builder"

PY="${PYTHON:-python3}"

TMP="${TMPDIR:-/tmp}/speckit-skill-builder-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# An empty, throwaway library dir for every invocation below. validate-skill.py's
# 3rd positional arg (`library_dir`) is scanned ONLY for id-COLLISION checking
# (`_find_id_collision`, globbing `<library_dir>/*/SKILL.md`); none of the five
# case groups below turn on collision behavior -- that is validate-skill.py's own
# 11-fixture inline self-test (`_self_test()`, run with no args), not this file's
# job to re-derive. An empty dir is therefore the correct, minimal fixture here.
LIBDIR="$TMP/empty-library"
mkdir -p "$LIBDIR"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$1"; }

[ -f "$VALIDATE" ] || { echo "FATAL: validate-skill.py not found at $VALIDATE" >&2; exit 1; }
[ -d "$FIX" ]       || { echo "FATAL: fixtures dir not found at $FIX" >&2; exit 1; }

check_passes() {
  # $1 = fixture path   $2 = task-tags CLI arg   $3 = human label
  rc=0
  "$PY" "$VALIDATE" "$1" "$2" "$LIBDIR" >"$TMP/chk.stdout" 2>"$TMP/chk.stderr" || rc=$?
  if [ "$rc" -eq 0 ]; then
    ok "$3 -- exits 0"
  else
    bad "$3 -- exited $rc, expected 0: $(cat "$TMP/chk.stderr")"
  fi
  if grep -qF -- 'OK:' "$TMP/chk.stdout"; then
    ok "$3 -- stdout confirms OK: (safe to persist)"
  else
    bad "$3 -- stdout missing the OK: confirmation: $(cat "$TMP/chk.stdout")"
  fi
}

check_rejected() {
  # $1 = fixture path   $2 = task-tags CLI arg   $3 = human label   $4 = expected substring in stderr
  rc=0
  "$PY" "$VALIDATE" "$1" "$2" "$LIBDIR" >"$TMP/chk.stdout" 2>"$TMP/chk.stderr" || rc=$?
  if [ "$rc" -ne 0 ]; then
    ok "$3 -- exits non-zero"
  else
    bad "$3 -- exited 0, expected non-zero (must be rejected, not persisted)"
  fi
  if grep -qF -- 'REJECTED:' "$TMP/chk.stderr" && grep -qF -- 'Not persisted' "$TMP/chk.stderr"; then
    ok "$3 -- stderr reports REJECTED + Not persisted (fail-closed report contract)"
  else
    bad "$3 -- stderr missing the REJECTED:/Not persisted report: $(cat "$TMP/chk.stderr")"
  fi
  if grep -qF -- "$4" "$TMP/chk.stderr"; then
    ok "$3 -- stderr names the specific violation (contains: $4)"
  else
    bad "$3 -- stderr missing expected substring [$4]: $(cat "$TMP/chk.stderr")"
  fi
}

# ===========================================================================
bold "1. Additive-only PASS -- conforming generated SKILL.md -> exit 0"

check_passes "$FIX/additive-pass.fixture.md" "t026-shared-tag, unrelated-context-tag" \
  "conforming fixture (anchor present, grants: [], tags intersect)"

# ===========================================================================
bold "2. FR-007/S9 -- four isolated violations -> exit non-zero, not persisted"

check_rejected "$FIX/reject-negation.fixture.md" "t026-shared-tag" \
  "(a) S1 negation ('ignore' the base)" "S1 violation"

check_rejected "$FIX/reject-relaxation.fixture.md" "t026-shared-tag" \
  "(b) S3 relaxation ('optional:'/'at your discretion')" "S3 violation"

check_rejected "$FIX/reject-missing-anchor.fixture.md" "t026-shared-tag" \
  "(c) S3 structural (missing additive anchor)" "S3 structural check failed"

check_rejected "$FIX/reject-model-key.fixture.md" "t026-shared-tag" \
  "(d) S2 dispatch content (top-level model: key)" "top-level 'model' key present"

# ===========================================================================
bold "3. S04 -- structurally-valid skill, tags MISS the triggering task -> exit non-zero"

check_rejected "$FIX/reject-tag-miss.fixture.md" "gap-task-tag, another-gap-tag" \
  "tag-miss fixture against a disjoint task-tag set" "S04 violation"

# Positive control on the SAME fixture: a task-tag set that DOES intersect its own
# taxonomy.tags passes -- isolates section 3's rejection to S04 alone, proving the
# fixture has no other latent defect.
check_passes "$FIX/reject-tag-miss.fixture.md" "covers-something-else" \
  "positive control -- same fixture, given its own tag"

# ===========================================================================
bold "4. D41 -- grant re-declares a core-toolset name -> exit non-zero"

check_rejected "$FIX/reject-grant-collision.fixture.md" "t026-shared-tag" \
  "grants: [Bash] re-declares a core tool" "core tool"

# ===========================================================================
bold "5. SC-007/S24 dedup -- validator-side property (testable/orchestration boundary)"

# The FULL SC-007/S24 property is: "two tasks sharing one novel tag => exactly ONE
# persisted skill, not one-per-task." Its "exactly ONE, not one-per-task" half is
# enforced by /speckit-agent-assign's own connected-components GROUPING of
# GAP_TASKS (extensions/workforce/skills/speckit-agent-assign/SKILL.md, "## 2. Gap
# handoff", step (a): "build one graph over just the gap tasks -- an edge between
# two whenever their tag lists intersect -- and take its connected components as
# clusters... exactly one skill-builder dispatch between them, never one each").
# That grouping is LLM-dispatch orchestration logic living entirely in a command's
# prose -- there is no script, function, or CLI entry point this zero-AI harness
# could call to exercise "did exactly one dispatch happen for two gap tasks,"
# because dispatch-count is a property of a *live agent-assign run*, not of
# validate-skill.py. It is out of scope here for the same reason the categorizer
# session itself is out of scope for test_categorize.sh (see this file's header).
#
# What IS mechanical, and what this section proves instead: the VALIDATOR-side
# precondition the grouping design relies on -- that ONE persisted skill, whose
# tags cover the novel tag two gap tasks share, is capable of independently
# satisfying BOTH tasks' own tag-sets. This is exactly why T025 groups gap tasks by
# shared tag in the first place (one well-scoped module covers the whole cluster);
# if a single skill could NOT validate against both tasks' tags, the dedup grouping
# would be unsound, not merely unverified. Two PASSes below (against two DIFFERENT
# tag-sets that share only the novel tag) plus a negative control (a tag-set
# WITHOUT the shared tag, still correctly rejected -- proving S04 stays live and
# the two PASSes are not vacuous) is the complete validator-side proof.

check_passes "$FIX/dedup-shared-tag.fixture.md" "shared-novel-tag, task-a-only-tag" \
  "the one shared-tag skill validates against task A's own tag set"

check_passes "$FIX/dedup-shared-tag.fixture.md" "shared-novel-tag, task-b-only-tag" \
  "the SAME one skill also validates against task B's own tag set -- one module can close both tasks' gap, never one-per-task"

check_rejected "$FIX/dedup-shared-tag.fixture.md" "wholly-unrelated-tag" \
  "negative control -- a task tag set WITHOUT the shared tag" "S04 violation"

# ===========================================================================
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
