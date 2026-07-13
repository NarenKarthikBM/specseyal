#!/bin/sh
#
# cmd.sh — arm4-noceiling golden driver (T025, 005-graphify-context)
#
# Arm 4 QUIET-PATH fixture — the S18 inverse of the sibling arm4-ceiling fixture (T024):
# "a check that can only ever fire proves nothing about its quiet path" (plan.md Arm 4).
# Drives ONE ordinary council-member round, well under the `standard` tier's
# query_ceiling of 15 (council-config.yml `tiers.standard.query_ceiling`): 8 queries,
# this round's near-max per D77 (measured baseline A=8 B=7 C=9 D=2 E=6, actual max 9 —
# 8 is near-max, not the max, and still comfortably under the ceiling of 15). The
# disclosure must never fire on a round that never hit its cap — crying-wolf coverage
# IS coverage (see README.md).
#
# PINNED interface — extensions/council/extension/scripts/ceiling-check.sh <tier>
# <query-count>. Coordinate this exact contract against the sibling T024/arm4-ceiling
# fixture; if that fixture already exists on disk, its cmd.sh's invocation shape must
# match this one byte-for-byte:
#
#   Reads cfg["tiers"][<tier>]["query_ceiling"] from council-config.yml. Prints to
#   stdout, exit 0:
#     - ALWAYS a first line: "ceiling_hit: true" or "ceiling_hit: false".
#     - iff hit (count >= ceiling): a second line — the ceiling-hit reduced-grounding
#       disclosure (a "> **Reduced grounding** --" line, extending the existing FR-019
#       note at extensions/council/extension/templates/member-prompt.md ~L41/99).
#     - iff NOT hit, OR the tier's ceiling is null/unset: ONLY the first line. No
#       second line, ever.
#
# ceiling-check.sh does not exist yet — it is authored in a later wave, NOT by this
# task. This fixture is therefore intentionally RED right now, failing with
# "ceiling-check.sh: No such file or directory" (or equivalent, depending on shell) —
# the correct TDD red-for-the-right-reason (see test/run.sh's own fixture-discovery
# convention: a script-under-test that doesn't exist yet is expected to fail, not a
# malformed fixture). Once ceiling-check.sh lands conforming to the interface above,
# this file requires NO edits to go green: standard/8 is under the ceiling of 15, so a
# contract-conforming script must print exactly "ceiling_hit: false" and nothing else.
#
set -eu

exec "$REPO/extensions/council/extension/scripts/ceiling-check.sh" standard 8
