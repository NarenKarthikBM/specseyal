#!/usr/bin/env sh
#
# arm2-equiv/cmd.sh -- SC-004 equivalence exit test, case (c): 0 survivors (T012,
# 005-graphify-context, plan.md "Arm 2"; contracts/commands.md `refresh.sh`).
#
# Shares its refresh.sh test-seam contract with the sibling arm2-survivors fixture
# (T013, case (d) -- the negative-path/manufactured-survivor inverse this fixture's
# 0-survivor positive case pairs with). Both fixtures bind the SAME not-yet-built
# script, so both adopt ONE contract here rather than leaving T016 two conflicting
# invocation proposals to reconcile:
#   Invocation:  refresh.sh <scratch-dir>  -- run with cwd ALSO set to <scratch-dir>,
#     so either a cwd-relative or an argv-based refresh.sh implementation is satisfied.
#   Reads   <scratch-dir>/graphify-out/graph.json   -- the graph to refresh (D45 path
#     convention); MUTATED IN PLACE.
#   Reads   <scratch-dir>/changed-files.txt         -- newline list of changed file
#     paths, matching the graph nodes' "source_file" values (stands in for
#     detect_incremental's changed-file output).
#   Reads   <scratch-dir>/fresh-extraction.json     -- {"nodes":[...],"links":[...]}:
#     the AUTHORITATIVE, already-computed fresh node/edge set for the file(s) named
#     above -- a deliberate test seam standing in for a live AST re-extraction (that
#     fidelity is arm-1/upstream's own concern, S22, not this equivalence check's).
#   Prints  "stale_survivors: <N>" to stdout (contracts/commands.md); other lines
#     around it (e.g. from re-invoking augment.sh per the S06 composition invariant)
#     are tolerated -- this fixture greps for that one line, never diffing the whole
#     stream verbatim.
#
# Scenario (input/graph.json, 3 files -- see README.md for the full rationale):
#   - src/cli/stable.sh -- UNTOUCHED (outside the changed scope). Must survive the
#     refresh byte-identical, proving the merge is scoped, not a whole-graph rebuild.
#   - src/cli/parse.sh  -- its one function is renamed: `parse_args` (base) is
#     replaced by `parse_input` (fresh). Exercises full purge-then-insert.
#   - src/cli/format.sh -- its existing `format_output` is RETAINED but UPDATED
#     (source_location shifts L2->L3, as a real edit inserting a line above it would
#     cause), a new function `format_error` is added, and a new intra-file `calls`
#     edge (format_output -> format_error) is added. Exercises attribute
#     refresh-in-place, not just blind add/remove.
#
# Asserts BOTH:
#   1. the stale-survivor guard reports 0 -- the base's `parse_args` node (absent from
#      the fresh extraction) must be purged, not left dangling alongside `parse_input`;
#   2. equivalence -- the refreshed graph's changed-scope slice (nodes+links whose
#      source_file is one of the two changed files) is byte-identical, under canonical
#      JSON (sorted keys, stable ordering, compact form -- canonicalize_scope.py), to
#      input/fresh-extraction.json's own content. Not circular: extraction is
#      deterministic (no LLM -- the same arm-1/S11 byte-determinism argument), so the
#      fresh extraction of a file legitimately IS what an independent full regen of
#      that file would produce -- one committed file honestly serves double duty as
#      both refresh.sh's merge input and the fixture's full-regen answer key. See
#      README.md for the full argument and the assumptions flagged for T016.
#
# Until refresh.sh exists, invoking it fails naturally (no such file) and this
# fixture is red FOR THAT REASON -- the intended TDD red (see
# extensions/graphify/test/run.sh's fixture-discovery convention), not a malformed
# fixture.
#
set -eu

FIXTURE_DIR="$(cd "$(dirname "$0")" && pwd)"
REFRESH="$REPO/extensions/graphify/extension/scripts/refresh.sh"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/arm2-equiv.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$SCRATCH/graphify-out"
cp "$FIXTURE_DIR/input/graph.json"            "$SCRATCH/graphify-out/graph.json"
cp "$FIXTURE_DIR/input/changed-files.txt"     "$SCRATCH/changed-files.txt"
cp "$FIXTURE_DIR/input/fresh-extraction.json" "$SCRATCH/fresh-extraction.json"

out="$(cd "$SCRATCH" && "$REFRESH" "$SCRATCH" 2>"$SCRATCH/.refresh.stderr")" && rc=0 || rc=$?
if [ "$rc" -ne 0 ]; then
  echo "refresh.sh exited $rc -- stderr:" >&2
  cat "$SCRATCH/.refresh.stderr" >&2
  exit 1
fi

survivors_line="$(printf '%s\n' "$out" | grep '^stale_survivors: ' | head -n1)"
if [ -z "$survivors_line" ]; then
  echo "refresh.sh printed no 'stale_survivors: <N>' line. Full stdout was:" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi
printf '%s\n' "$survivors_line"

# Equivalence: canonicalize the refreshed graph's changed-scope slice and the
# fixture's fresh-extraction answer key the same way, then byte-diff.
python3 "$FIXTURE_DIR/canonicalize_scope.py" \
  "$SCRATCH/graphify-out/graph.json" "$FIXTURE_DIR/input/changed-files.txt" \
  >"$SCRATCH/refreshed-scope.json"
python3 "$FIXTURE_DIR/canonicalize_scope.py" \
  "$FIXTURE_DIR/input/fresh-extraction.json" "$FIXTURE_DIR/input/changed-files.txt" \
  >"$SCRATCH/expected-scope.json"

if diff -q "$SCRATCH/expected-scope.json" "$SCRATCH/refreshed-scope.json" >/dev/null 2>&1; then
  printf 'equivalent: yes\n'
else
  printf 'equivalent: no\n'
fi
