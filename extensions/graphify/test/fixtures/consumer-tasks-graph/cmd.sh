#!/usr/bin/env sh
#
# consumer-tasks-graph fixture (T030) — FR-013 non-regression tripwire for
# /speckit-tasks-graph's consumption of graphify-context.md.
#
# Consumer fixture 2 of 3 (siblings: consumer-plan/ T029, consumer-implement/ T031). Per
# golden-fixture-discipline, each NAMED consumer of the shared graphify-context.md diet gets
# its own committed fixture — a regression that only breaks /speckit-tasks-graph's own
# consumption must be caught here even while the other two consumers' fixtures stay green.
#
# What this proves: /speckit-tasks-graph derives its `[P]` markers and `## Execution Waves`
# DAG from exactly two graphify-context.md sections — "## Blast radius (per anchor)" (per-file
# depends-on / depended-on-by edges) and "## Shared / mutable files (collision watch)" (the
# collision list that forces serialization). This is a pure documentation/shape check — no
# script-under-test, no graph.json, no LLM — because the "consumer" here is the natural-
# language SKILL.md speckit-tasks-graph itself, read by an agent at runtime, not a binary.
# The mechanical, deterministic proxy for "the consumption contract still holds" is: the
# generator's Output template still emits both sections in their documented shape, the worked
# example still populates them realistically, the consumer skill still cites both by name, and
# the worked tasks+waves example still shows the derivation actually landing (a naive `[P]`
# stripped because two tasks collide on a shared/mutable file). Break any one link in that
# chain and a specific, named check below goes red — never a single opaque failure.
#
# No pinned dependency on unbuilt scripts (T020, the generator body, is done) — this fixture is
# GREEN now, by design, and stays a live regression guard from here on.
set -u

cd "$(dirname "$0")"

GEN="$REPO/extensions/graphify/skills/speckit-graphify-context/SKILL.md"
EXAMPLE="$REPO/extensions/graphify/examples/graphify-context.example.md"
CONSUMER="$REPO/extensions/graphify/skills/speckit-tasks-graph/SKILL.md"
WAVES_EXAMPLE="$REPO/extensions/graphify/examples/tasks-with-waves.example.md"

n_pass=0
n_fail=0
overall_rc=0

check() {
  # check <label> <command...> -- PASS iff <command...> exits 0. Never a bare boolean: the
  # label always names the SPECIFIC link in the chain being tested, so a future break points
  # straight at which file/section/citation regressed, not just "shape check failed".
  label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    n_pass=$((n_pass + 1))
    printf 'PASS %s\n' "$label"
  else
    n_fail=$((n_fail + 1))
    overall_rc=1
    printf 'FAIL %s\n' "$label"
  fi
}

# Section-scoped bodies (heading line inclusive, up to the next "## " heading or EOF). Body
# checks below run against THESE excerpts, never the whole file — so a populated-body check can
# never be satisfied by an unrelated bullet living under some other heading (e.g. "## Relevant
# existing modules" also uses backtick-quoted file bullets; scoping rules that false pass out).
blast_section_gen="$(sed -n '/^## Blast radius (per anchor)/,/^## /p' "$GEN")"
shared_section_gen="$(sed -n '/^## Shared \/ mutable files (collision watch)/,/^## /p' "$GEN")"
blast_section_example="$(sed -n '/^## Blast radius (per anchor)/,/^## /p' "$EXAMPLE")"
shared_section_example="$(sed -n '/^## Shared \/ mutable files (collision watch)/,/^## /p' "$EXAMPLE")"

gen_blast_has_depends()      { printf '%s\n' "$blast_section_gen" | grep -qE '^  - depends on: '; }
gen_blast_has_dependedonby() { printf '%s\n' "$blast_section_gen" | grep -qE '^  - depended on by: '; }
gen_shared_has_guidance()    { printf '%s\n' "$shared_section_gen" | grep -qF 'must be serialized'; }
example_blast_populated()    { printf '%s\n' "$blast_section_example" | grep -qE '^  - depends on: `'; }
example_shared_populated()   { printf '%s\n' "$shared_section_example" | grep -qE '^- `[^`]+` '; }

echo "consumer-tasks-graph: FR-013 parallelism-derivation tripwire for /speckit-tasks-graph"
echo

echo "-- generator Output template (speckit-graphify-context/SKILL.md) --"
check 'generator template carries heading "## Blast radius (per anchor)"' \
  grep -qxF '## Blast radius (per anchor)' "$GEN"
check 'generator template carries heading "## Shared / mutable files (collision watch)"' \
  grep -qxF '## Shared / mutable files (collision watch)' "$GEN"
check 'generator template :: blast-radius section shapes a "depends on" edge' \
  gen_blast_has_depends
check 'generator template :: blast-radius section shapes a "depended on by" edge' \
  gen_blast_has_dependedonby
check 'generator template :: shared/mutable section carries serialization guidance' \
  gen_shared_has_guidance

echo
echo "-- worked diet example (examples/graphify-context.example.md) --"
check 'example mirrors heading "## Blast radius (per anchor)" byte-for-byte' \
  grep -qxF '## Blast radius (per anchor)' "$EXAMPLE"
check 'example mirrors heading "## Shared / mutable files (collision watch)" byte-for-byte' \
  grep -qxF '## Shared / mutable files (collision watch)' "$EXAMPLE"
check 'example :: blast-radius section populated with a real "depends on" edge' \
  example_blast_populated
check 'example :: shared/mutable section populated with a real shared file (not just "none found")' \
  example_shared_populated

echo
echo "-- consumer skill (speckit-tasks-graph/SKILL.md) still reads the diet --"
check 'Step A names graphify-context.md as the file it grounds in' \
  grep -qF 'graphify-context.md` exists and is fresh, read it' "$CONSUMER"
check 'Step D ties [P] derivation to the shared/mutable list in graphify-context.md' \
  grep -qF 'shared/mutable** list in `graphify-context.md`' "$CONSUMER"
check 'Wave rules pull any shared/mutable-file task into a serial wave' \
  grep -qF 'shared/mutable file is pulled out of parallel waves into a serial wave' "$CONSUMER"

echo
echo "-- worked tasks+waves example demonstrates the end-to-end derivation --"
check 'Shared-file serialization section names the real T011/T021 routes.ts collision' \
  grep -qF 'src/api/routes.ts` touched by T011, T021' "$WAVES_EXAMPLE"
check 'note records a naive [P] stripped because of the graph-informed collision' \
  grep -qF 'stripped it' "$WAVES_EXAMPLE"

echo
echo "consumer-tasks-graph: $((n_pass + n_fail)) checks, $n_pass passed, $n_fail failed"

exit "$overall_rc"
