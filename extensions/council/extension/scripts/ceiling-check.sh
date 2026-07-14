#!/bin/sh
# ceiling-check.sh — arm-4 query-ceiling decision (005-graphify-context).
#
# The mechanical embodiment of S09/D53: given a council member's graph-query COUNT and
# its tier, decide whether the enforced ceiling was hit and, if so, emit the reduced-
# grounding disclosure line the orchestrator appends to that member's opinion. The
# council orchestrator (skills/speckit-council/SKILL.md, T028) calls this at member
# dispatch; the arm4-ceiling / arm4-noceiling goldens (T024/T025) pin its output.
# Mechanical only: no model, no network, no ANTHROPIC_API_KEY, no traces.jsonl write.
#
# Usage:  ceiling-check.sh <tier> <query-count>
#
# Reads member query_ceiling for <tier> from ../council-config.yml
# (tiers.<tier>.query_ceiling) with a plain-text parse — PyYAML is NOT assumed present.
# Prints to stdout, exit 0:
#   line 1 (always):  "ceiling_hit: true"  |  "ceiling_hit: false"
#   line 2 (iff hit): the "> **Reduced grounding** — ..." disclosure line.
# Hit iff the tier's ceiling is a number AND <query-count> >= it. A null/unset ceiling
# (e.g. the uncapped full tier) is never hit — the quiet path stays quiet (S18).

set -eu

die() { printf 'ceiling-check.sh: error: %s\n' "$1" >&2; exit 1; }
usage() { printf 'usage: ceiling-check.sh <tier> <query-count>\n' >&2; }

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

[ "$#" -ge 2 ] || { usage; exit 1; }

tier="$1"
count="$2"

case "$count" in
    ''|*[!0-9]*) die "query-count must be a non-negative integer, got: $count" ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve own directory from \$0 ($0)"
config="$script_dir/../council-config.yml"
[ -f "$config" ] || die "council-config.yml not found at $config"

# Extract tiers.<tier>.query_ceiling. Value may be an int, 'null', or absent; a trailing
# '# comment' is stripped. Block-scoped so a different tier's key never leaks across.
ceiling=$(awk -v tier="$tier" '
    /^tiers:/ { in_tiers = 1; in_tier = 0; next }
    /^[^[:space:]]/ { in_tiers = 0; in_tier = 0; next }
    in_tiers && $0 ~ ("^  " tier ":") { in_tier = 1; next }
    in_tiers && /^  [A-Za-z]/ { in_tier = 0 }
    in_tier && /^[[:space:]]+query_ceiling:/ {
        v = $0
        sub(/^[[:space:]]+query_ceiling:[[:space:]]*/, "", v)
        sub(/[[:space:]]*#.*/, "", v)
        gsub(/[[:space:]]/, "", v)
        print v
        exit
    }
' "$config")

# Uncapped: no ceiling value, or an explicit YAML null.
case "$ceiling" in
    ''|null|Null|NULL|'~')
        printf 'ceiling_hit: false\n'
        exit 0
        ;;
    *[!0-9]*)
        die "tiers.$tier.query_ceiling is neither a non-negative integer nor null: '$ceiling'"
        ;;
esac

if [ "$count" -ge "$ceiling" ]; then
    printf 'ceiling_hit: true\n'
    printf '> **Reduced grounding** — query ceiling (%s) reached; further graph queries for this review were not run.\n' "$ceiling"
else
    printf 'ceiling_hit: false\n'
fi
