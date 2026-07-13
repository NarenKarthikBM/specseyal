#!/usr/bin/env sh
#
# arm3-coherence fixture (T019, S13) — cross-product coherence invariant.
#
# One generator run stamps the IDENTICAL shared-provenance header (T004,
# extensions/graphify/skills/speckit-graphify-context/SKILL.md "Shared-provenance
# header") into all three arm-3 diets (graphify-context.md diet, receipts diet,
# type-signal diet), because `generation-id` is a pure function of the graph's
# own content, not of which diet is being written. This fixture proves MUTUAL
# coherence: all three exemplar products' `generation-id` fields match EACH
# OTHER, and — the part a per-product golden alone can never catch — all three
# also match the canonical id recomputed straight from input/graph.json. Tying
# the check to the real graph (not merely to internal agreement between the
# three files) matters because three products could all agree with each other
# and still all be stale/wrong in the same way if the comparison stopped at
# "do the three match".
#
# PINNED, currently-RED dependency: this calls
# extensions/graphify/extension/scripts/provenance.sh, an orchestrator-owned
# shared helper authored in a later wave. It does not exist yet, so this
# fixture currently fails with a "No such file or directory" (provenance.sh
# missing) — the correct red-for-the-right-reason TDD state, not a malformed
# fixture. See README.md.
set -eu

cd "$(dirname "$0")"

PROVENANCE="$REPO/extensions/graphify/extension/scripts/provenance.sh"

# extract_generation_id <product.md> -> stdout: the bare value of that
# product's `generation-id:` header field. Same recipe SKILL.md's provenance
# section documents as the normative extraction (sed isolates the HTML-comment
# block by its sentinel markers, grep picks the one field line, sed strips the
# "generation-id: " prefix) -- deliberately not a bespoke parser, so this
# fixture and any real consumer stay provably in sync.
extract_generation_id() {
  sed -n '/<!-- graphify-provenance:v1/,/-->/p' "$1" | grep '^generation-id:' | sed 's/^generation-id: //'
}

canonical=$("$PROVENANCE" generation-id input/graph.json)
ctx_id=$(extract_generation_id input/context.md)
receipts_id=$(extract_generation_id input/receipts.md)
typesignal_id=$(extract_generation_id input/typesignal.md)

printf 'canonical: %s\n' "$canonical"

# report <label> <got> -- prints MATCH only on exact string equality to the
# canonical id computed in step 1; never a hardcoded "MATCH" literal, so a
# real drift between a product and the graph (or between products) prints
# MISMATCH with the offending value, not a false green.
report() {
  if [ "$2" = "$canonical" ]; then
    printf '%s: MATCH\n' "$1"
  else
    printf '%s: MISMATCH (got %s)\n' "$1" "$2"
  fi
}

report "context.md" "$ctx_id"
report "receipts.md" "$receipts_id"
report "typesignal.md" "$typesignal_id"

if [ "$ctx_id" = "$canonical" ] && [ "$receipts_id" = "$canonical" ] && [ "$typesignal_id" = "$canonical" ]; then
  printf 'coherent: yes\n'
else
  printf 'coherent: no\n'
fi
