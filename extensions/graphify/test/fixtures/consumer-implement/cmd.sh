#!/usr/bin/env sh
#
# consumer-implement fixture (T031, S-consumer-3, 005-graphify-context) -- non-regression
# guard for ONE named consumer (golden-fixture-discipline's own rule: "give every named
# consumer of a shared artifact its own committed, individually-named fixture") of the
# graphify-context.md blast-radius diet: /speckit-implement-parallel
# (extensions/graphify/skills/speckit-implement-parallel/SKILL.md), sibling to consumer-plan
# (T029) and consumer-tasks-graph (T030), which cover the other two named readers of the
# SAME diet.
#
# UNLIKE the arm2/arm3 fixtures in this directory, this one depends on NO not-yet-built
# script -- both sides of the contract it checks are already-committed prose documents (the
# generator's own SKILL.md, its worked example, and the consumer's own SKILL.md), so this
# fixture is GREEN today and stays green until one of those documents actually regresses
# (per the task brief: "Non-regression guard: GREEN now; breaks if the per-task
# blast-radius shape changes"). Reading the REAL, live files under $REPO -- never a
# fixture-local stand-in copy -- is deliberate: a stand-in could silently drift out of sync
# with the real prose and this guard would never fire on a real edit.
#
# What "unbroken" means, concretely (FR-013 + the "Graphify blast radius" subagent-prompt
# section speckit-implement-parallel/SKILL.md documents):
#   1. The generator's Output template for graphify-context.md
#      (speckit-graphify-context/SKILL.md) still emits a "## Blast radius (per anchor)"
#      section with its three per-anchor relations, in order: depends on / depended on by /
#      follow the pattern in.
#   2. The worked example (examples/graphify-context.example.md) still REALIZES that
#      grammar with concrete (non-placeholder) file paths, not just documents it in the
#      abstract.
#   3. speckit-implement-parallel/SKILL.md still (a) reads graphify-context.md specifically
#      for grounding, and (b) its "Subagent task prompt template"'s
#      "### Graphify blast radius" section still carries the same three relations, in the
#      same order, sourced from graphify-context.md.
#   4. The two sides' relation sequences (producer grammar vs. consumer prompt grammar)
#      stay in lockstep -- checked structurally (extract-and-diff), not just "both mention
#      the words somewhere", so a silent reorder/rename on either side is caught even when
#      each individual phrase still appears in its file somewhere.
#
# Runs under `sh` with $REPO exported by run.sh; does not depend on the caller's cwd.
set -eu
cd "$(dirname "$0")"

GEN_SKILL="$REPO/extensions/graphify/skills/speckit-graphify-context/SKILL.md"
EXAMPLE="$REPO/extensions/graphify/examples/graphify-context.example.md"
IMPL_SKILL="$REPO/extensions/graphify/skills/speckit-implement-parallel/SKILL.md"

n_pass=0
n_fail=0
overall_rc=0

check() {
  # check <label> <command...> -- PASS iff <command...> exits 0.
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

# Isolate each side's relevant section once, reused by several checks below.
# gen_block / example_block: from "## Blast radius (per anchor)" up to (excluding) the
# next "## " heading. impl_block: from "### Graphify blast radius" up to (excluding) the
# next "### " heading. (Range-address end-pattern search starts on the line AFTER the
# start match, so the heading line itself never falsely closes its own range.)
gen_block="$(sed -n '/^## Blast radius (per anchor)$/,/^## /p' "$GEN_SKILL" | sed '$d')"
example_block="$(sed -n '/^## Blast radius (per anchor)$/,/^## /p' "$EXAMPLE" | sed '$d')"
impl_block="$(sed -n '/^### Graphify blast radius/,/^### /p' "$IMPL_SKILL" | sed '$d')"

echo "generator-shape (speckit-graphify-context/SKILL.md, Output template -- graphify-context.md):"

check 'heading "## Blast radius (per anchor)" present' \
  grep -qxF '## Blast radius (per anchor)' "$GEN_SKILL"

check 'per-anchor entry line "- **<anchor>** (`<source_file>`)" present' \
  sh -c 'printf "%s\n" "$1" | grep -qE "^- \*\*<anchor>\*\* \(\`<source_file>\`\)\$"' _ "$gen_block"

check 'sub-field "depends on:" present' \
  sh -c 'printf "%s\n" "$1" | grep -qF "depends on:"' _ "$gen_block"

check 'sub-field "depended on by:" present' \
  sh -c 'printf "%s\n" "$1" | grep -qF "depended on by:"' _ "$gen_block"

check 'sub-field "follow the pattern in:" present' \
  sh -c 'printf "%s\n" "$1" | grep -qF "follow the pattern in:"' _ "$gen_block"

check 'FR-013 unchanged-shape marker present' \
  grep -qF 'Unchanged from before this task (FR-013)' "$GEN_SKILL"

echo
echo "example-realization (examples/graphify-context.example.md):"

check 'heading "## Blast radius (per anchor)" present' \
  grep -qxF '## Blast radius (per anchor)' "$EXAMPLE"

check 'concrete (non-placeholder) "depends on:" line present' \
  sh -c 'printf "%s\n" "$1" | grep -qE "^  - depends on: \`"' _ "$example_block"

check 'concrete (non-placeholder) "depended on by:" line present' \
  sh -c 'printf "%s\n" "$1" | grep -qE "^  - depended on by: \`"' _ "$example_block"

check 'concrete (non-placeholder) "follow the pattern in:" line present' \
  sh -c 'printf "%s\n" "$1" | grep -qE "^  - follow the pattern in: \`"' _ "$example_block"

echo
echo "consumer-shape (speckit-implement-parallel/SKILL.md):"

check 'Pre-Execution reads FEATURE_DIR/graphify-context.md for grounding' \
  grep -qF 'read `FEATURE_DIR/graphify-context.md`' "$IMPL_SKILL"

check 'subagent prompt template heading "### Graphify blast radius" present' \
  grep -qE '^### Graphify blast radius' "$IMPL_SKILL"

check 'template line "This code depends on:" cites graphify-context.md' \
  sh -c 'printf "%s\n" "$1" | grep -qF "This code depends on: <from graphify-context.md>"' _ "$impl_block"

check 'template line "Depended on by (do not break these):" cites graphify-context.md' \
  sh -c 'printf "%s\n" "$1" | grep -qF "Depended on by (do not break these): <from graphify-context.md>"' _ "$impl_block"

check 'template line "Follow the existing pattern in:" present' \
  sh -c 'printf "%s\n" "$1" | grep -qF "Follow the existing pattern in:"' _ "$impl_block"

echo
echo "cross-file coherence (producer grammar == consumer prompt grammar, order-preserving):"

# Canonicalize each side's ORDERED relation sequence to the same 3-token vocabulary, then
# compare. This is what actually discriminates a rename/reorder/removal on EITHER side of
# the producer/consumer boundary -- the per-string presence checks above cannot, since they
# each only prove a phrase appears somewhere in its own file, not that the two files still
# agree on the same three relations in the same order.
gen_seq="$(printf '%s\n' "$gen_block" | grep -oE '^  - (depends on|depended on by|follow the pattern in):' \
  | sed -e 's/^  - depends on:/depends-on/' -e 's/^  - depended on by:/depended-on-by/' -e 's/^  - follow the pattern in:/follow-the-pattern/')"
impl_seq="$(printf '%s\n' "$impl_block" | grep -oE '^- (This code depends on|Depended on by|Follow the existing pattern in)' \
  | sed -e 's/^- This code depends on/depends-on/' -e 's/^- Depended on by/depended-on-by/' -e 's/^- Follow the existing pattern in/follow-the-pattern/')"

check 'generator per-anchor relation sequence == implement-parallel per-task relation sequence' \
  test "$gen_seq" = "$impl_seq"

echo
echo "consumer-implement: $((n_pass + n_fail)) checks, $n_pass passed, $n_fail failed"

exit "$overall_rc"
