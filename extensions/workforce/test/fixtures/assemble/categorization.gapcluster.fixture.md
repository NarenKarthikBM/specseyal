# Categorization — assemble.py gap-batching fixture (v1, D66 verdict 11)

> **Frozen test fixture.** Three gap tasks against the frozen main library — none of their
> tags (`gapcluster-*`) intersect any fixture skill (`alpha`/`beta`/`cap-test`), so all
> three are ∅-match gaps. Their tag graph has exactly two connected components:
>
> - **T001** (`gapcluster-x`, `gapcluster-shared`) and **T002** (`gapcluster-shared`,
>   `gapcluster-y`) share `gapcluster-shared` → one cluster.
> - **T003** (`gapcluster-solo`) shares nothing → its own cluster of one.
>
> `assemble.py`'s `compute_gap_clusters` (D66 verdict 11) MUST emit `GAP_CLUSTERS:
> [T001,T002] [T003]` on stdout and record the same two clusters in the roster's
> `**Gap clusters …**` notes — the gap-batching that was formerly the /speckit-agent-assign
> command's prose, now the assembler's deterministic output (one skill-builder dispatch per
> cluster, never one per gap task). All three tasks resolve to `agt_fx_sonnet` (Sonnet), so
> the run exits 0 (a gap is reported, not an error) with no elevated grants (`GRANT_TRIPWIRE:
> none`). Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (3 tasks) — a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `service` | `qa-automation` | false | false | gapcluster-x, gapcluster-shared |
| T002 | `test` | `qa-automation` | false | false | gapcluster-shared, gapcluster-y |
| T003 | `service` | `qa-automation` | false | false | gapcluster-solo |
