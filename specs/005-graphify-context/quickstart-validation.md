# Quickstart validation — 005-graphify-context (final integration gate, T036)

Executed 2026-07-14. **Read-only**: harnesses + live graph-*copy* checks only; no source file and no working `graphify-out/graph.json` was mutated. Discipline (quickstart-integration-gate): every SC + FR + quickstart scenario is bound to a **concrete executed check**; anything unmet is an **explicit GAP** — never fabricated coverage.

## Evidence base (committed, green)

- `sh extensions/graphify/test/run.sh` → **28 passed, 0 failed** — 15 fixtures (arm1-success/fallback/messy · arm2-freshness/equiv/survivors/compose · arm3-products/coherence · consumer-plan/tasks-graph/implement/categorizer/deck-prep · severability) + the §3 reinstall-survival stage (all 005 scripts/edits survive install **and** reinstall; installed `provenance.sh` functional).
- `sh extensions/council/test/run.sh` → **9 passed, 0 failed** — arm4-ceiling/noceiling + §3 reinstall-survival (installed `ceiling-check.sh` functional both branches).
- **Live SC-001 probe** (on a `mktemp` copy of the real graph): `augment.sh <copy> .` → `augmented: +476 nodes / +64 edges` (registers_hook 17, installs 19, invokes 5, asserted 23), then `graphify path "verify-gate.sh" "implement-parallel" --graph <copy>`.

## Success Criteria

| SC | Executed check | Verdict |
|---|---|---|
| **SC-001** *(coverage — path resolves)* | Live probe above → **"No path found"** (unchanged from step-0). `augment.sh` emits the 3 edge kinds (arm1-success proves it; live adds 476 nodes/64 edges incl. `registers_hook: extensions.yml → speckit.git.verify-gate`), but the verify-gate↔implement-parallel relationship is **command-mediated**: implement-parallel → the `speckit.git.verify-gate` *command* → verify-gate.sh *script*. The 3 ratified kinds create `extensions.yml → command`, but neither `command → script` nor `.md-skill → command`, so no traversal bridges the two. | **GAP** — see GAP 1 |
| **SC-002** *(honesty — zero unlabeled fallback)* | arm1-fallback + arm1-messy (every out-of-model / unresolvable relation → `asserted`/`ASSERTED`, never a silent gap); the live run's 23 `asserted` edges are all labeled. | **PASS** |
| **SC-003** *(freshness check)* | arm2-freshness — stale-positive → `stale: regenerate <product>`; stale-negative → fresh (no false alarm). | **PASS** |
| **SC-004** *(incremental equivalence + cost)* | arm2-equiv (`stale_survivors: 0`; changed-scope byte-equivalent to a full regen) + arm2-survivors (guard detects 3, prunes to 0) + arm2-compose (S06 augment re-invoke). | **PASS (equivalence)** · token-cost ≤25%-of-753k bound **DEFERRED** to a live refresh |
| **SC-005** *(tiered diets)* | arm3-products (3 separate diets; `graphify-context.md` shape unchanged) + arm3-coherence (one `generation-id` across all three). | **PASS (3 coherent diets)** · member pull-reduction vs one-diet baseline **DEFERRED** to a live round |
| **SC-006** *(query-cost)* | arm4-ceiling/noceiling (enforced ceiling decision) + orchestrator wiring (T028) + trace fields `graph_queries`/`ceiling_hit` (T023). | **PASS (mechanism)** · spend-vs-unbounded **DEFERRED** (booked vs `006`'s first post-arm-4 round, plan §SC-006) |
| **SC-007** *(non-regression / dogfood)* | 5 consumer fixtures + arm4-ceiling (council-member). | **PASS (fixtures)** · live spec→…→testing end-to-end **DEFERRED** to the real pipeline pass |
| **SC-008** *(ceiling disclosure)* | arm4-ceiling (`ceiling_hit: true` + the `> **Reduced grounding** — query ceiling (15) reached…` line) + arm4-noceiling (quiet path) + member/orchestrator wiring (T027/T028). | **PASS** |
| **SC-009** *(non-regression teeth — one fixture per consumer)* | 6 committed, named consumer fixtures (plan/tasks-graph/implement/categorizer/deck-prep + arm4-ceiling for council-member), all green. | **PASS** |

## Functional Requirements

| FR | Executed check | Verdict |
|---|---|---|
| FR-001 (nodes for .sh/.yml/.md) | arm1-success NODE lines; live +476 nodes | PASS |
| FR-002 (3 cross-file edge kinds) | arm1-success (registers_hook/installs/invokes) | PASS |
| FR-003 ([P]/blast-radius graph-derivable) | The 3 kinds add real edges, but command-mediated plumbing paths don't resolve (SC-001), so this feature's own `.sh`/`.yml` `[P]` still rests on the labeled assertion (S22; tasks.md `[P]` provenance discloses it) | **GAP** — tied to SC-001 (GAP 1) |
| FR-004 (labeled fallback remains + used) | arm1-fallback/messy; live 23 `asserted` | PASS |
| FR-005 (mechanical staleness check) | arm2-freshness + freshness.sh | PASS |
| FR-006 (regenerate stale, never hand-edit) | freshness.sh hard-warn → regenerate contract | PASS |
| FR-007 (incremental ≡ full regen for scope) | arm2-equiv | PASS |
| FR-008 (full-regen fallback when invariant unmet) | refresh.sh version-pin mismatch → full-regen branch (T017) | PASS |
| FR-009 (distinct products per consumer) | arm3-products (3 diets) | PASS |
| FR-010 (token-bounded, only its slice — structural) | arm3-products (separate files, not one sectioned file) | PASS |
| FR-011 (hard enforced query ceiling) | ceiling-check.sh + council-config `query_ceiling` + arm4-ceiling | PASS |
| FR-012 (bound observable, exhaustion never silent) | trace `graph_queries`+`ceiling_hit` (T023) + mechanical disclosure (arm4-ceiling) | PASS |
| FR-013 (6 consumers unbroken) | consumer fixtures (5) + arm4-ceiling | PASS |
| FR-014 (cross-extension seam at hook/config — D57/I-14) | reinstall-survival §3 (T035) + seam design (refresh→augment sibling; ceiling-check in council source; no foreign-source edits) | PASS |
| FR-019 (reduced-grounding disclosure) | member-prompt FR-019 note + arm4-ceiling disclosure line | PASS |

## Quickstart scenarios (1–13)

| # | Scenario | Verdict |
|---|---|---|
| 1–2 | augment on repo graph → explain gains cross-file edges | PARTIAL — 476 nodes/64 edges added; but see 3 |
| 3 | `path verify-gate.sh implement-parallel` returns a path (**SC-001**) | **GAP** — "No path found" (command-mediated) |
| 4 | labeled fallback, zero unlabeled (**SC-002**) | PASS |
| 5 | freshness → stale→regenerate (**SC-003**) | PASS |
| 6 | refresh → `stale_survivors: 0`, ≡ full regen (**SC-004**) | PASS (cost DEFERRED) |
| 7 | 3 separate products (**SC-005**) | PASS |
| 8 | member pull-diff vs baseline (**SC-005**) | DEFERRED (live round) |
| 9 | `005` council round: counts bounded (**SC-006**) | DEFERRED (live round); mechanism PASS |
| 10 | member→ceiling: disclosure + `ceiling_hit` (**SC-008**) | PASS |
| 11 | six consumer fixtures green (**SC-009**) | PASS |
| 12 | `005` end-to-end, six consumers function (**SC-007**) | DEFERRED (live pipeline); consumers PASS |
| 13 | reinstall survival (**D57**) | PASS (§3 both harnesses) |

## Summary

- **SC:** 8/9 PASS (SC-004/005/006/007 each carry a DEFERRED live-measurement component); **1 GAP (SC-001)**.
- **FR:** 14/15 PASS; **1 GAP (FR-003, tied to SC-001)**.
- **Scenarios:** 8 PASS · 1 GAP (#3) · 3 DEFERRED (#8/#9/#12, model-driven) · 1 partial (#1–2).
- **Harnesses:** graphify **28/28**, council **9/9**.

## GAPs (explicit — not fabricated coverage)

1. **SC-001 / FR-003 — `verify-gate.sh ↔ implement-parallel` does not resolve** even after augment. Cause: the relationship is **command-mediated** (skill → `speckit.git.verify-gate` command → script); the 3 ratified edge kinds (registers_hook/installs/invokes) create `extensions.yml → command` but not `command → implementing-script` or `.md-skill → command`. This is the **S22/I-13 doubly-reduced grounding the plan disclosed as Exhibit A** — arm 1 covers the modeled kinds (fixtures green), but the specific plumbing path SC-001 names needs a 4th edge behavior. **Resolution:** a skill/command→implementing-script edge, admitted as an evidence-backed follow-up (the **D76/I-24** seeding-bar pattern), **not** added mid-implement on momentum.
2. **Deferred live measurements** (mechanism verified by a committed fixture; the *number* awaits a real pipeline run): SC-004 token-cost budget · SC-005 pull-reduction · SC-006 spend-vs-unbounded (booked vs `006`) · SC-007 end-to-end. Honest partials, not failures.
3. **Minor** — augment's `.yml` `command:` parse captured a trailing inline comment on one real-repo hook entry (`speckit.git.record-gate  # …`), yielding a malformed command-node id. Non-blocking; no fixture covers inline-comment stripping. Booked for a follow-up fix.
