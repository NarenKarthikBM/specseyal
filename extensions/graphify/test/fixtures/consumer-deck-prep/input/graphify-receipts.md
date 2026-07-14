# Graphify Receipts — demo-deck-prep

_Generated 2026-01-01T00:00:00Z from `graphify-out/graph.json` (12 nodes, 9 edges, scope: repo) — concept/rationale diet for the council member and deck-prep. Stale after large merges — regenerate with `/speckit-graphify-context`._

<!-- graphify-provenance:v1
graph-path: graphify-out/graph.json
graph-scope: repo
node-count: 12
edge-count: 9
generated-at: 2026-01-01T00:00:00Z
generation-id: sha256:c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0
source-fingerprint: git-commit:7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
-->

## Concept / rationale receipts
- **Widget cache invalidation concept** (`specs/demo-deck-prep/spec.md`) — Cached widget reads must invalidate the instant the underlying record's soft-delete flag flips, never on a fixed TTL alone. (`rationale_for` → D-901: soft-delete flips invalidate the cache synchronously)
- **D-901: soft-delete flips invalidate the cache synchronously** (`docs/90-DECISIONS-AND-IDEAS.md`) — A TTL-only cache let a soft-deleted widget serve stale reads for up to 60s in a prior incident; synchronous invalidation on the same write closes that window.

## Contracts cited
- `specs/demo-deck-prep/contracts/cache-invalidation.md` — the cache invalidation contract: write path, invalidation trigger, and the read-after-write guarantee it makes.
