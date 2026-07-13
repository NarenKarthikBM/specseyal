# Data Model — 005-graphify-context

Phase 1. The entities `005` introduces or changes. All are specseyal-owned (D75); `graphifyy`'s own graph schema is unchanged — arm 1 only *adds* conforming nodes/edges.

## Knowledge graph (existing, augmented)
- `graphify-out/graph.json` — gitignored working copy (D45); committed per-feature `graph-baseline.json` snapshot (D59). Nodes typed `code|document|paper|image|rationale|concept`; edges carry `relation`, `confidence`, `confidence_score`, `source_file`.
- **Arm-1 additions:** nodes for `.sh`/`.yml`/`.md` files not already emitted; edges of exactly three `relation` kinds — `registers_hook` (extension.yml→command), `installs` (install.sh→target tree), `invokes` (script→script). All `confidence: EXTRACTED` (deterministic parse) or the labeled fallback. **No schema change** — these are ordinary nodes/edges the existing `explain`/`path` already traverse.

## Augmentation pass (arm 1, new)
- **Input:** the repo's `.sh`/`.yml`/`.md` files + the just-built extraction/graph.
- **Output:** the added nodes/edges merged into the extraction (pre-build) or `graph.json`.
- **State:** stateless, deterministic (same repo → byte-identical additions). No LLM, no key.

## Context products (arm 3 — three separate diets, was one)
| Product | Consumer(s) | Slice | Token bound |
|---|---|---|---|
| `graphify-context.md` | plan, tasks-graph, implement-parallel | blast-radius · shared/mutable · `[P]` | ~1500 (unchanged, FR-013) |
| receipts diet | council member, deck-prep | concept/rationale nodes (requirements, D-rows, contracts) | bounded |
| type-signal diet | categorizer | per-file `type` signal + path-convention fallback | bounded |
- All three derive from **one generator run over one graph**; each carries a shared-provenance header (graph path, node/edge count, generated-at) so staleness is checkable per product (FR-005).

## Freshness state (arm 2, new — derived, no state file)
- **Computed** from: the graph's manifest/hashes vs the current working tree (D32 — no persisted state file).
- **Values:** `fresh` | `stale`. On `stale`: hard-warn + route to regenerate (S14 pattern). Never a hard-block.
- **Survivor count:** the incremental-refresh guard emits `stale_survivors: N` (0 = clean; >0 = prune-or-rebuild). The step-0-by-hand check, now mechanical.

## Query bound + trace fields (arm 4)
- **`council-config.yml` `member.query_ceiling`:** integer `N`, tier-aware; the enforced cap on a member's graph-query **count**.
- **Trace additions (per member record):** `graph_queries: <int>` (count this member ran) and `ceiling_hit: <bool>`. Role-scoped to `council-member` (mirrors how `context_in` is `tester`-gated, D72). `trace-schema.md` amendment is authorized at implement (contract-change discipline), not here.
- **Opinion disclosure:** a ceiling-hit member's opinion carries the reduced-grounding line (extends the existing FR-019 note) — so the chairman weights it (SC-008).
