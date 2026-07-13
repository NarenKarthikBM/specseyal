#!/bin/sh
#
# cmd.sh — arm4-ceiling golden driver (T024, 005-graphify-context)
#
# Arm 4 CEILING-HIT fixture — the S18 counterpart of the sibling arm4-noceiling fixture
# (T025): "a check that can only ever fire proves nothing about its quiet path" (plan.md
# Arm 4). Drives a council member's on-demand graph-query loop TO the `standard` tier's
# query_ceiling (council-config.yml `tiers.standard.query_ceiling: 15`, D77): exactly 15
# queries -- the boundary case (count == ceiling), not merely "a lot more than the
# ceiling" -- so a contract-conforming ceiling-check.sh must use `count >= ceiling`, not
# `count > ceiling`; a `>`-only implementation would wrongly report `ceiling_hit: false`
# right here and this golden would catch it.
#
# PINNED interface -- extensions/council/extension/scripts/ceiling-check.sh <tier>
# <query-count>. Coordinated byte-for-byte against the sibling T025/arm4-noceiling
# fixture (present on disk at authoring time -- both cmd.sh invocation shapes agree):
#
#   Reads cfg["tiers"][<tier>]["query_ceiling"] from council-config.yml. Prints to
#   stdout, exit 0:
#     - ALWAYS a first line: "ceiling_hit: true" or "ceiling_hit: false".
#     - iff hit (count >= ceiling, and ceiling is a number): a second line -- the
#       ceiling-hit reduced-grounding disclosure, pinned verbatim below (this fixture IS
#       its spec, since no earlier task fixed its exact text) -- same
#       "> **Reduced grounding** --" prefix the existing FR-019 note uses
#       (extensions/council/extension/templates/member-prompt.md ~L41/99), so the
#       chairman detects it identically, with no new detection logic.
#     - iff NOT hit, OR the tier's ceiling is null/unset: ONLY the first line. No second
#       line, ever (arm4-noceiling's expected.txt covers that branch: exactly
#       "ceiling_hit: false", nothing more).
#
# Canonical disclosure line (expected.txt is the byte-authoritative golden; restated here
# only for a reader who stops at cmd.sh) -- a template parameterized on the resolved
# ceiling N, N=15 in this fixture's case:
#
#   > **Reduced grounding** -- query ceiling (N) reached; further graph queries for this
#   review were not run.
#
# ceiling-check.sh does not exist yet -- authored in a LATER wave (S09 / D53: the
# mechanical embodiment of "the orchestrator mechanically appends the disclosure the
# instant it enforces the cap"), not by this task. This fixture is therefore intentionally
# RED right now, failing with "ceiling-check.sh: No such file or directory" (or
# equivalent, depending on shell) -- the correct TDD red-for-the-right-reason
# (test/run.sh's own fixture-discovery convention: a script-under-test that doesn't exist
# yet is expected to fail, not a malformed fixture). Requires NO edits to go green once it
# lands conforming to the interface above.
#
set -eu

exec "$REPO/extensions/council/extension/scripts/ceiling-check.sh" standard 15
