# Contracts — command & config surface (005-graphify-context)

Phase 1. The interface `005` exposes. All specseyal-owned; `graphifyy` CLI/API consumed, never modified (D75). Mechanical scripts follow the `commit.sh`/`verify-gate.sh` idiom (POSIX `sh`, no LLM, no trace, exit-code contract).

## Arm 1 — `augment.sh` (post-extraction coverage pass)
- **Invocation:** `augment.sh <graph-or-extraction-path>` — run after the upstream extraction, before/at build.
- **Behavior:** parse the repo's `.sh`/`.yml`/`.md`; emit nodes + the three edge kinds (`registers_hook`, `installs`, `invokes`); merge into the graph. Deterministic.
- **Exit:** `0` on success (prints `augmented: +<nodes> nodes / +<edges> edges`); non-zero on parse failure (never a silent partial).
- **Fallback (S22/FR-004):** an unmodellable relation is emitted as a labeled-assertion node/annotation, never dropped.

## Arm 2 — `freshness.sh` + `refresh.sh`
- **`freshness.sh <product-path>`:** exit `0` = fresh; exit non-zero + `stale: regenerate <product>` on stdout = stale (hard-warn, **not** a hard-block — callers warn+route, they do not die). Derives freshness from graph manifest vs worktree; writes no state (D32).
- **`refresh.sh`:** wraps the upstream incremental merge; after merge, runs the **stale-survivor guard** → prints `stale_survivors: <N>`. `N=0` → proceed; `N>0` → prune-or-rebuild + report (FR-008). Equivalence-to-full-regen is the SC-004 property.

## Arm 3 — `speckit-graphify-context` skill (three products)
- **One run → three files:** `graphify-context.md` (blast-radius, unchanged shape), the receipts diet, the type-signal diet. Each token-bounded; each carries the shared-provenance header.
- **Backward compatibility (FR-013):** `graphify-context.md`'s path and section grammar are unchanged — plan/tasks/implement read it exactly as today.

## Arm 4 — council member query ceiling
- **`council-config.yml`:** `member.query_ceiling: <int>` (tier-aware default).
- **Enforcement:** the orchestrator/member-prompt bounds the member's graph-query loop to `N`; the `(N)`th query is the last.
- **Trace (per member):** `graph_queries: <int>`, `ceiling_hit: <bool>` (role-scoped `council-member`).
- **Opinion:** on `ceiling_hit: true`, the opinion MUST carry the reduced-grounding disclosure line (FR-019 lineage) so the chairman weights it (SC-008).

## Hook / seam registration (D57/I-14)
- Arm-1/2 attach to the graphify context-generation flow at its existing hook points (`before_plan`/`before_tasks`/`before_implement`), or as steps the `speckit-graphify-context` skill invokes — **in `extensions/graphify/` source** (reinstall-survival-tested). No foreign-extension source edit; arm-4's council changes live in `extensions/council/` source.
- `trace-schema.md` gains the two `council-member` fields at implement (authorized contract change, the D72 role-gating pattern), not in this plan.
