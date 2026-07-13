# Quickstart — validation guide (005-graphify-context)

Runnable scenarios that prove each arm + each Success Criterion. Doc-level (implementation lives in `tasks.md`); every check is mechanical or a committed fixture.

**Prerequisites:** the built graph (`graphify-out/graph.json`); the graphify + council extensions installed; `graph-baseline.json` (the D59 snapshot) for the before/after.

## Arm 1 — coverage (SC-001, SC-002)
1. Run `augment.sh` on the repo graph.
2. `graphify explain "verify-gate.sh"` → now shows cross-file caller edges (`implement-parallel`, `before_implement`), not only intra-file `defines`.
3. `graphify path "verify-gate.sh" "implement-parallel"` → **returns a path** (before: "No path found", verified live at step-0). **SC-001.**
4. Grep the products for any blast-radius/`[P]` claim still on the fallback → each is **labeled** "assertion, not graph fact"; zero unlabeled. **SC-002.**

## Arm 2 — freshness (SC-003, SC-004)
5. Mutate a file the current `graphify-context.md` grounds; run `freshness.sh graphify-context.md` → reports **stale → regenerate** (the 002 mtime case, now caught). **SC-003.**
6. Change a bounded file subset; run `refresh.sh` → prints `stale_survivors: 0` and a graph equivalent to a full regen for that scope, at cost materially below the ~753k-tok/~11-min full ritual (compare `graph-baseline-measure.md`). **SC-004.**

## Arm 3 — tiered products (SC-005)
7. Run the `speckit-graphify-context` skill → three separate files exist, each carrying only its slice.
8. Diff the council member's on-demand graph pulls this feature vs the one-diet baseline → **reduced** (the D62 3/5→1/5 direction), because the receipts diet pre-serves them. **SC-005.**

## Arm 4 — query ceiling (SC-006, SC-008)
9. Run the `005` council round → each member's `graph_queries` count is recorded and bounded by `member.query_ceiling`; round cache-creation spend is below an equivalent unbounded loop at the same tier. **SC-006.**
10. Drive a member fixture to the ceiling → its opinion carries the reduced-grounding disclosure **and** its trace shows `ceiling_hit: true`; the chairman can weight it. **SC-008.**

## Non-regression (SC-007, SC-009)
11. Run the six named consumer fixtures (plan · tasks-graph · implement-parallel · council-member · categorizer · deck-prep) → all green; each reads its product/diet unbroken. **SC-009.**
12. Run `005` end-to-end (spec→…→implement→complete→testing) → all six live consumers function, no regression. **SC-007.**

## Reinstall survival (D57)
13. `bash extensions/graphify/install.sh .` then re-run 1–12 against the installed scripts → all edits survive the installer `rm -rf`+`cp` (the model: `extensions/git/test/run.sh §3`).
