#!/usr/bin/env sh
#
# consumer-plan fixture (T029, 005-graphify-context) — FR-013 non-regression tripwire for
# /speckit-plan's (and, identically, /speckit-tasks-graph's and /speckit-implement-parallel's)
# consumption of graphify-context.md's blast-radius diet.
#
# Arm 3 (T020) grew the generator from one product to three, but FR-013 requires
# graphify-context.md itself to keep its CURRENT path and section grammar unchanged — the graph-
# aware speckit variants read it as-is. This is a consumer-NAMED fixture (golden-fixture-
# discipline: "give every named consumer of a shared artifact its own committed fixture"),
# distinct from arm3-products' own per-product shape check: arm3-products checks the shape
# against a fixture-local, hand-authored stand-in for one generator run's output; THIS fixture
# checks the two LIVE, committed sources of truth directly —
#   1. the generator's own contract: the `## Output template — `graphify-context.md`` fenced
#      block inside extensions/graphify/skills/speckit-graphify-context/SKILL.md
#   2. the committed worked example: extensions/graphify/examples/graphify-context.example.md
# — so an edit to either one trips this guard directly, with no regenerated exemplar required
# as an intermediary.
#
# Checks both presence AND relative order of the 5 headings, for each source independently: a
# per-heading check alone cannot catch a pure reorder (all 5 still present, none renamed) —
# the "in original order" check closes that gap. Every check prints its own deterministic
# PASS/FAIL line, so a future regression names exactly which heading, and in which source,
# broke — never a bare "shape check failed".
#
# Runs under `sh` with $REPO exported by run.sh; does not depend on the caller's cwd. All
# printed labels use REPO-RELATIVE paths only (never $REPO itself, which is an absolute path
# that varies by checkout location) so expected.txt stays byte-identical from any clean clone.
set -u
cd "$(dirname "$0")"

SKILL_REL="extensions/graphify/skills/speckit-graphify-context/SKILL.md"
EXAMPLE_REL="extensions/graphify/examples/graphify-context.example.md"
SKILL="$REPO/$SKILL_REL"
EXAMPLE="$REPO/$EXAMPLE_REL"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/consumer-plan.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

overall_rc=0
n_pass=0
n_fail=0

check() {
  # check <label> <command...> — PASS iff <command...> exits 0.
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

# The FR-013 heading set, in the generator's own documented order (SKILL.md's Output template).
cat > "$WORK/expected-order.txt" <<'HEADINGS'
## Graph scope
## Relevant existing modules
## Blast radius (per anchor)
## Shared / mutable files (collision watch)
## Patterns to follow
HEADINGS

echo "consumer-plan (FR-013): /speckit-plan blast-radius-diet consumption — unchanged shape"

# --- Source 1: the generator's own SKILL.md Output template -------------------------------
check "$SKILL_REL :: source file exists" test -f "$SKILL"

# Isolate just the graphify-context.md Output template block: its own heading line through to
# (not including) the NEXT "## Output template" heading (graphify-receipts.md's) — so a
# heading string appearing only in a later template or in surrounding prose can never
# false-positive this check.
awk '/^## Output template/{c++} c==1' "$SKILL" > "$WORK/skill-block.md" 2>/dev/null

check "$SKILL_REL :: heading \"## Graph scope\" present" \
  grep -qxF '## Graph scope' "$WORK/skill-block.md"
check "$SKILL_REL :: heading \"## Relevant existing modules\" present" \
  grep -qxF '## Relevant existing modules' "$WORK/skill-block.md"
check "$SKILL_REL :: heading \"## Blast radius (per anchor)\" present" \
  grep -qxF '## Blast radius (per anchor)' "$WORK/skill-block.md"
check "$SKILL_REL :: heading \"## Shared / mutable files (collision watch)\" present" \
  grep -qxF '## Shared / mutable files (collision watch)' "$WORK/skill-block.md"
check "$SKILL_REL :: heading \"## Patterns to follow\" present" \
  grep -qxF '## Patterns to follow' "$WORK/skill-block.md"

grep -xF \
  -e '## Graph scope' -e '## Relevant existing modules' -e '## Blast radius (per anchor)' \
  -e '## Shared / mutable files (collision watch)' -e '## Patterns to follow' \
  "$WORK/skill-block.md" > "$WORK/skill-order.actual" 2>/dev/null
check "$SKILL_REL :: all 5 headings present, in original order" \
  diff -q "$WORK/expected-order.txt" "$WORK/skill-order.actual"

# --- Source 2: the committed worked example ------------------------------------------------
check "$EXAMPLE_REL :: source file exists" test -f "$EXAMPLE"

check "$EXAMPLE_REL :: heading \"## Graph scope\" present" \
  grep -qxF '## Graph scope' "$EXAMPLE"
check "$EXAMPLE_REL :: heading \"## Relevant existing modules\" present" \
  grep -qxF '## Relevant existing modules' "$EXAMPLE"
check "$EXAMPLE_REL :: heading \"## Blast radius (per anchor)\" present" \
  grep -qxF '## Blast radius (per anchor)' "$EXAMPLE"
check "$EXAMPLE_REL :: heading \"## Shared / mutable files (collision watch)\" present" \
  grep -qxF '## Shared / mutable files (collision watch)' "$EXAMPLE"
check "$EXAMPLE_REL :: heading \"## Patterns to follow\" present" \
  grep -qxF '## Patterns to follow' "$EXAMPLE"

grep -xF \
  -e '## Graph scope' -e '## Relevant existing modules' -e '## Blast radius (per anchor)' \
  -e '## Shared / mutable files (collision watch)' -e '## Patterns to follow' \
  "$EXAMPLE" > "$WORK/example-order.actual" 2>/dev/null
check "$EXAMPLE_REL :: all 5 headings present, in original order" \
  diff -q "$WORK/expected-order.txt" "$WORK/example-order.actual"

echo "consumer-plan: $((n_pass + n_fail)) checks, $n_pass passed, $n_fail failed"

exit "$overall_rc"
