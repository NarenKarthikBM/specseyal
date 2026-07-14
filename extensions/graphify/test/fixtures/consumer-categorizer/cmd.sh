#!/usr/bin/env sh
#
# consumer-categorizer fixture (T032 [US3]) — non-regression guard, consumer 5.
#
# T022 already lockstep-updated extensions/workforce/extension/templates/categorizer-prompt.md
# to read the per-file type-signal diet (graphify-type-signal.md, T020's generator output) as a
# CORROBORATING signal for its own `type` derivation — never a substitute for it. This fixture is
# GREEN now (a non-regression guard, not a red-then-green TDD fixture): it asserts that property
# stays true with NO script-under-test invoked — a static content/shape check against a real,
# already-committed template plus a fixture-local exemplar, exactly like arm3-products' "shape-
# conformance" half.
#
# Asserts, against the CURRENT committed state:
#
#   (a) categorizer-prompt.md still references graphify-type-signal.md by name, still frames it
#       as "corroborating signal, never a substitute/replacement", still carries its OWN 8-value
#       `type` derivation table intact (header row + all 8 enum values), and still cites the
#       diet's own "## Path-convention fallback (not in graph)" section. Together these prove
#       corroboration, not substitution: the diet was not allowed to quietly replace the
#       categorizer's own mechanical derivation table.
#   (b) this fixture's own minimal exemplar input/graphify-type-signal.md (the diet shape T020's
#       generator, extensions/graphify/skills/speckit-graphify-context/SKILL.md, defines) carries
#       both of its required sections.
#
# Runs under sh with $REPO exported by run.sh; never depends on the caller's cwd.
set -u

fixture_dir="$(cd "$(dirname "$0")" && pwd)"
PROMPT="$REPO/extensions/workforce/extension/templates/categorizer-prompt.md"
DIET="$fixture_dir/input/graphify-type-signal.md"

overall_rc=0
n_pass=0
n_fail=0

report() {
  # report <label> <exit-status-of-the-check-just-run> — PASS iff status -eq 0.
  label="$1"
  status="$2"
  if [ "$status" -eq 0 ]; then
    n_pass=$((n_pass + 1))
    printf '  PASS %s\n' "$label"
  else
    n_fail=$((n_fail + 1))
    overall_rc=1
    printf '  FAIL %s\n' "$label"
  fi
}

echo "consumer-categorizer:"

# --- (a) categorizer-prompt.md: diet referenced, corroboration framing + own derivation intact --

grep -q 'graphify-type-signal\.md' "$PROMPT"
report 'categorizer-prompt.md :: references graphify-type-signal.md (the diet)' $?

grep -Eqi 'corroborating signal, never a (substitute|replacement)' "$PROMPT"
report 'categorizer-prompt.md :: frames the diet as corroboration, never substitution' $?

grep -qxF '| `type` | Deliverable | Derivation rule |' "$PROMPT"
report 'categorizer-prompt.md :: own 8-value `type` derivation table header intact' $?

types_ok=0
for t in scaffold data-model service endpoint ui test docs infra; do
  grep -qF "| \`$t\` |" "$PROMPT" || types_ok=1
done
report 'categorizer-prompt.md :: all 8 `type` enum values still present in the table' "$types_ok"

# The diet's own fallback-section heading is cited inside word-wrapped prose in
# categorizer-prompt.md (the citation spans a line break in the committed source), so flatten
# newlines to single spaces before the substring search rather than risk a false negative on
# re-wrapping. No file is written to disk — flattened text stays in a shell variable.
flat_prompt=$(tr '\n' ' ' <"$PROMPT" | tr -s ' ')
printf '%s' "$flat_prompt" | grep -qF '## Path-convention fallback (not in graph)'
report 'categorizer-prompt.md :: still cites the diet own "Path-convention fallback (not in graph)" section' $?

# --- (b) this fixture's own exemplar diet carries both required sections ------------------------

grep -qxF '## Per-file type signal (graph-grounded)' "$DIET"
report 'input/graphify-type-signal.md :: has "## Per-file type signal (graph-grounded)"' $?

grep -qxF '## Path-convention fallback (not in graph)' "$DIET"
report 'input/graphify-type-signal.md :: has "## Path-convention fallback (not in graph)"' $?

echo "consumer-categorizer: $((n_pass + n_fail)) checks, $n_pass passed, $n_fail failed"

exit "$overall_rc"
