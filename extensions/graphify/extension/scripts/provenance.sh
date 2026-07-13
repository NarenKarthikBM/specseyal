#!/bin/sh
# provenance.sh — shared provenance-header math for graphify context products (005 arm 2/3).
#
# The SINGLE implementation of the shared-provenance header defined in
# extensions/graphify/skills/speckit-graphify-context/SKILL.md § "Shared-provenance
# header" (T004). The generator (arm 3, T020) stamps a product's header by calling this;
# freshness.sh (arm 2, T015) recomputes generation-id by calling this — ONE recipe, never
# reimplemented twice (T004: "any divergence reproduces the exact false-staleness failure
# this contract exists to prevent"). Mechanical only: no model, no network, no
# ANTHROPIC_API_KEY, no traces.jsonl write (constitution V/IV).
#
# Usage:
#   provenance.sh header <graph.json> <scope> [<generated-at-iso>]
#       -> the 9-line "<!-- graphify-provenance:v1 ... -->" block on stdout.
#   provenance.sh generation-id <graph.json>
#       -> "sha256:<64hex>" on stdout.
#
# <scope> is repo|merged. <generated-at-iso> defaults to current UTC (second precision, Z)
# when omitted; a fixed value is passed for byte-stable golden fixtures.
#
# Exit: 0 on success (stdout as above); non-zero + diagnostic on stderr on failure. A graph
# with no top-level built_at_commit is a HARD error — the git-commit source-fingerprint is
# required; the T004 sha256/git-ls-files fallback (merged/stack scope only, marked unverified
# there) is intentionally NOT implemented, as no fixture or repo-scope graph needs it. Fail
# closed rather than emit an unverifiable fingerprint.

set -eu

die() { printf 'provenance.sh: error: %s\n' "$1" >&2; exit 1; }
usage() {
    printf 'usage: provenance.sh header <graph.json> <scope> [<generated-at-iso>]\n' >&2
    printf '       provenance.sh generation-id <graph.json>\n' >&2
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

[ "$#" -ge 2 ] || { usage; exit 1; }
mode="$1"
graph="$2"
[ -f "$graph" ] || die "graph.json not found: $graph"

# generation-id (T004 recipe): sha256 of the canonical graph.json with its own
# built_at_commit key removed (that is tracked separately as source-fingerprint;
# folding it in would correlate two checks designed to be independent). The pipeline
# is byte-identical to the recipe the SKILL.md documents and the committed goldens
# precomputed with — python's print() adds the trailing LF that reaches shasum, so
# the digest matches the goldens exactly. Keep it that way.
compute_gen_id() {
    _h=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
d.pop("built_at_commit",None)
print(json.dumps(d,sort_keys=True,separators=(",",":")))' "$graph" | shasum -a 256 | cut -d" " -f1) \
        || die "generation-id computation failed for $graph"
    [ -n "$_h" ] || die "empty generation-id digest for $graph"
    printf 'sha256:%s' "$_h"
}

if [ "$mode" = "generation-id" ]; then
    compute_gen_id
    printf '\n'
    exit 0
fi

[ "$mode" = "header" ] || { usage; exit 1; }

scope="$3"
gen_at="${4:-}"
[ -n "$gen_at" ] || gen_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

case "$scope" in
    repo)   graph_path="graphify-out/graph.json" ;;
    merged) graph_path="../graphify-out/graph.json" ;;
    *)      die "scope must be repo|merged, got: $scope" ;;
esac

# node/edge counts + built_at_commit in one pass (nodes; links = NetworkX edges).
_meta=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
print(len(d.get("nodes",[])), len(d.get("links",[])), d.get("built_at_commit","") or "")' "$graph") \
    || die "cannot read node/edge counts from $graph"
node_count=$(printf '%s' "$_meta" | cut -d" " -f1)
edge_count=$(printf '%s' "$_meta" | cut -d" " -f2)
built_at=$(printf '%s' "$_meta" | cut -d" " -f3)

[ -n "$built_at" ] || die "graph.json has no built_at_commit — the git-commit source-fingerprint is required (T004 merged-scope sha256 fallback intentionally not implemented; no case needs it)"

gen_id=$(compute_gen_id)

printf '%s\n' "<!-- graphify-provenance:v1"
printf 'graph-path: %s\n' "$graph_path"
printf 'graph-scope: %s\n' "$scope"
printf 'node-count: %s\n' "$node_count"
printf 'edge-count: %s\n' "$edge_count"
printf 'generated-at: %s\n' "$gen_at"
printf 'generation-id: %s\n' "$gen_id"
printf 'source-fingerprint: git-commit:%s\n' "$built_at"
printf '%s\n' "-->"
