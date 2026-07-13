#!/usr/bin/env sh
#
# arm2-freshness fixture (T011, US2) — freshness.sh (T015, a later wave) golden.
#
# freshness.sh does not exist yet, so this fixture is intentionally RED right now —
# the correct "red for the right reason" TDD state (see test/run.sh's own header
# comment on fixture discovery), not a malformed fixture. Once T015 lands
# extensions/graphify/extension/scripts/freshness.sh, this file requires NO edits to
# go green.
#
# Proves BOTH branches of the same guard in one cmd.sh (S18: a check that can only
# ever fire proves nothing about its quiet path — see README.md):
#
#   (a) stale-positive — a tracked source file is edited after the graph was built;
#       the graph itself is NOT rebuilt -> freshness.sh's check 2 (source-fingerprint
#       vs. worktree) must fire -> STALE.
#   (b) stale-negative / no-false-alarm — a byte-for-byte pristine copy of the same
#       repo/graph/product -> both of freshness.sh's checks pass -> FRESH, and
#       nothing is warned (no crying wolf).
#
# Setup mirrors contracts/commands.md's Arm 2 and the shared-provenance-header
# contract in extensions/graphify/skills/speckit-graphify-context/SKILL.md
# ("Shared-provenance header (arm-2 <-> arm-3 coherence contract)", T004):
#
#   1. A throwaway git repo (never this repo — all mutable state lives under a
#      mktemp scratch, cleaned up on EXIT via trap) with two tracked source files
#      and a .gitignore'd graphify-out/ (mirrors D45: the graph artifact itself is
#      never tracked source, so rebuilding it can never by itself perturb a
#      source-fingerprint diff).
#   2. One commit -> a real, reachable commit SHA.
#   3. A small, valid graphify-out/graph.json (schema verified against
#      specs/005-graphify-context/graph-baseline.json: top-level directed,
#      multigraph, graph, nodes, links, hyperedges, built_at_commit; 2 nodes + 1
#      edge) stamped with built_at_commit = that SHA.
#   4. generation-id computed from that graph.json using the EXACT canonicalization
#      recipe the SKILL.md contract specifies verbatim (parse JSON, drop
#      built_at_commit, re-serialize with sort_keys + compact separators, SHA-256)
#      — independently re-derivable, not a fabricated placeholder.
#   5. product.md carrying the 7-field shared-provenance header (fixed field order,
#      one HTML comment block), left UNTRACKED — this mirrors the real
#      generate-then-commit-later sequencing (freshness is checked in the window
#      before the product itself is committed) and, as a side effect, keeps the
#      product's own arrival from perturbing its own source-fingerprint check.
#   6. Two independent copies of the whole repo: stale-positive and stale-negative.
#      Copying (cp -R, including .git) rather than re-running `git init` keeps both
#      copies pinned to the SAME commit SHA, so the header's recorded
#      source-fingerprint stays reachable and meaningful in both.
#
# generation-id is computed here directly per the SKILL.md's own documented,
# normative recipe (python3 + shasum) — deliberately NOT via any speculative
# shared helper script, since T011 depends only on T004 (tasks.md) and nothing
# else in this wave is a pinned dependency. Whatever internal implementation T015
# ultimately uses for freshness.sh, correctness only requires it follow the same
# documented, fully-specified algorithm — which yields an identical digest for
# identical graph.json content regardless of which script computed it.
set -eu

FRESHNESS="$REPO/extensions/graphify/extension/scripts/freshness.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/arm2-freshness.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# portable shasum/sha256sum wrapper (SKILL.md's own footnote: both emit the
# identical lowercase-hex digest for identical bytes)
sha256_hex() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | cut -d' ' -f1
  else
    sha256sum | cut -d' ' -f1
  fi
}

# ---------------------------------------------------------------------------
# 1. throwaway git repo: tracked sources + a .gitignore'd graph-output dir.
# ---------------------------------------------------------------------------
BASE="$WORK/base"
mkdir -p "$BASE/src" "$BASE/graphify-out"
printf 'graphify-out/\n' > "$BASE/.gitignore"
printf 'alpha fixture source, line 1\n' > "$BASE/src/alpha.txt"
printf 'beta fixture source, line 1\n'  > "$BASE/src/beta.txt"

(
  cd "$BASE" \
    && git init -q \
    && git config user.email fixture@example.invalid \
    && git config user.name  "arm2-freshness fixture" \
    && git add -A \
    && git commit -q -m 'fixture base: tracked sources'
)
SHA=$(cd "$BASE" && git rev-parse HEAD)

# ---------------------------------------------------------------------------
# 2. small, valid graph.json — 2 nodes, 1 edge, empty hyperedges.
# ---------------------------------------------------------------------------
GRAPH_JSON="$BASE/graphify-out/graph.json"
cat > "$GRAPH_JSON" <<JSON
{
  "directed": false,
  "multigraph": false,
  "graph": {"hyperedges": []},
  "nodes": [
    {
      "id": "src_alpha_txt",
      "label": "alpha.txt",
      "file_type": "code",
      "source_file": "src/alpha.txt",
      "source_location": "L1",
      "metadata": {"language": "text", "kind": "file"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "alpha.txt"
    },
    {
      "id": "src_beta_txt",
      "label": "beta.txt",
      "file_type": "code",
      "source_file": "src/beta.txt",
      "source_location": "L1",
      "metadata": {"language": "text", "kind": "file"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "beta.txt"
    }
  ],
  "links": [
    {
      "relation": "defines",
      "confidence": "EXTRACTED",
      "source_file": "src/alpha.txt",
      "source_location": "L1",
      "weight": 1.0,
      "confidence_score": 1.0,
      "source": "src_alpha_txt",
      "target": "src_beta_txt"
    }
  ],
  "hyperedges": [],
  "built_at_commit": "$SHA"
}
JSON

# ---------------------------------------------------------------------------
# 3. generation-id — SKILL.md's canonicalization recipe, applied verbatim:
#    parse JSON, drop built_at_commit, re-serialize sort_keys + compact
#    separators, SHA-256.
# ---------------------------------------------------------------------------
GEN_ID=$(python3 -c "
import json
d = json.load(open('$GRAPH_JSON'))
d.pop('built_at_commit', None)
print(json.dumps(d, sort_keys=True, separators=(',', ':')))
" | sha256_hex)

# ---------------------------------------------------------------------------
# 4. product.md — the 7-field shared-provenance header, fixed field order, one
#    HTML comment block placed after the title/intro and before the first ##
#    section (SKILL.md "Placement"). Left UNTRACKED (mirrors the real
#    generate -> [freshness-checked here] -> commit-later sequencing).
# ---------------------------------------------------------------------------
cat > "$BASE/product.md" <<MD
# Graphify Context — arm2-freshness fixture

_Generated 2026-07-14T00:00:00Z from \`graphify-out/graph.json\` (2 nodes, 1 edges, scope: repo). Stale after large merges — regenerate with \`/speckit-graphify-context\`._

<!-- graphify-provenance:v1
graph-path: graphify-out/graph.json
graph-scope: repo
node-count: 2
edge-count: 1
generated-at: 2026-07-14T00:00:00Z
generation-id: sha256:$GEN_ID
source-fingerprint: git-commit:$SHA
-->

## Relevant existing modules
- \`src/alpha.txt\` — fixture source file
- \`src/beta.txt\` — fixture source file
MD

# ---------------------------------------------------------------------------
# 5. fork into stale-positive / stale-negative copies. cp -R of the whole tree
#    (including .git) — not a fresh `git init` — keeps both copies pinned to
#    the SAME commit SHA, so the header's source-fingerprint stays reachable
#    and meaningful in both without a second commit.
# ---------------------------------------------------------------------------
POS="$WORK/stale-positive"
NEG="$WORK/stale-negative"
cp -R "$BASE" "$POS"
cp -R "$BASE" "$NEG"

# (a) mutate a TRACKED source file, uncommitted; do NOT touch graph.json —
#     isolates the failure to check 2 (source-fingerprint), never check 1.
printf 'mutated after the graph was built -- tracked, uncommitted\n' >> "$POS/src/alpha.txt"

# (b) NEG is left byte-for-byte untouched — the pristine copy.

# ---------------------------------------------------------------------------
# 6. run freshness.sh <product.md> from each copy and classify its behavior
#    against contracts/commands.md's contract (exit 0 = fresh; exit non-zero +
#    "stale: regenerate <product>" on stdout = stale). Any token other than
#    STALE/FRESH is deliberate: it makes the byte-diff against expected.txt
#    fail loudly instead of the harness silently coercing unexpected behavior
#    into a false PASS.
# ---------------------------------------------------------------------------
check_one() {
  label="$1"; dir="$2"; product="$3"
  if [ ! -x "$FRESHNESS" ]; then
    printf '%s: NOT-EXECUTABLE (freshness.sh missing or not chmod +x -- T015)\n' "$label"
    return 0
  fi
  if out=$(cd "$dir" && "$FRESHNESS" "$product"); then
    if [ -z "$out" ]; then
      printf '%s: FRESH\n' "$label"
    else
      printf '%s: UNEXPECTED-EXIT0\n' "$label"
    fi
  else
    if [ "$out" = "stale: regenerate $product" ]; then
      printf '%s: STALE\n' "$label"
    else
      printf '%s: UNEXPECTED-NONZERO\n' "$label"
    fi
  fi
}

check_one "stale-positive" "$POS" "product.md"
check_one "stale-negative" "$NEG" "product.md"
