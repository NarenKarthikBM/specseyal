#!/usr/bin/env sh
#
# arm3-products fixture (T018 [US3]) — combined stdout of two deterministic checks:
#
#   1. Header golden — runs provenance.sh's `header` subcommand against this fixture's own
#      small input/graph.json with a FIXED generated-at, so the full shared-provenance
#      header block (extensions/graphify/skills/speckit-graphify-context/SKILL.md, "Shared-
#      provenance header" section) is byte-stable. provenance.sh is an orchestrator-owned
#      shared helper authored in a LATER wave — until it exists, this call finds no such
#      file, prints nothing to stdout for part 1, and the fixture is red FOR THAT REASON
#      (intended TDD red, not a malformed fixture). Once provenance.sh lands, this becomes a
#      real byte-diff golden.
#
#   2. Shape conformance — the FR-013 "graphify-context.md's shape is unchanged" tripwire
#      plus a grammar guard for the two NEW diets (receipts, type-signal), checked against
#      this fixture's own three committed exemplar product files
#      (expected-context.md / expected-receipts.md / expected-typesignal.md — a hand-authored
#      stand-in for "one generator (T020) run's output" over input/graph.json). This part
#      needs no script-under-test, so it runs — and passes — independently of part 1's red
#      state; a reviewer reading the diff sees exactly which half is red and why.
#
# Runs under `sh` with $REPO exported by run.sh; does not depend on the caller's cwd.
set -u
cd "$(dirname "$0")"

overall_rc=0

# --- Part 1: header golden ---------------------------------------------------------------
PROVENANCE="$REPO/extensions/graphify/extension/scripts/provenance.sh"
"$PROVENANCE" header input/graph.json repo 2026-01-01T00:00:00Z
rc=$?
[ "$rc" -eq 0 ] || overall_rc=1

# --- Part 2: shape conformance ------------------------------------------------------------
printf '\n'
echo "shape-conformance:"

n_pass=0
n_fail=0

check() {
  # check <label> <command...>  — PASS iff <command...> exits 0.
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

# FR-013 tripwire: graphify-context.md retains its current section headings, unchanged.
check 'graphify-context.md :: heading "## Graph scope"' \
  grep -qxF '## Graph scope' expected-context.md
check 'graphify-context.md :: heading "## Relevant existing modules"' \
  grep -qxF '## Relevant existing modules' expected-context.md
check 'graphify-context.md :: heading "## Blast radius (per anchor)"' \
  grep -qxF '## Blast radius (per anchor)' expected-context.md
check 'graphify-context.md :: heading "## Shared / mutable files (collision watch)"' \
  grep -qxF '## Shared / mutable files (collision watch)' expected-context.md
check 'graphify-context.md :: heading "## Patterns to follow"' \
  grep -qxF '## Patterns to follow' expected-context.md

# New diet 1: receipts carries a concept/rationale section.
check 'receipts diet :: concept/rationale section present' \
  grep -qiE '^##[[:space:]].*(concept|rationale)' expected-receipts.md

# New diet 2: type-signal carries per-file file_type lines.
check 'type-signal diet :: per-file file_type lines present' \
  grep -qE '^- `[^`]+`.*file_type: ' expected-typesignal.md

echo "shape-conformance: $((n_pass + n_fail)) checks, $n_pass passed, $n_fail failed"

exit "$overall_rc"
