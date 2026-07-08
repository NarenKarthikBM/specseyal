# Agent Assignment — 000-sample

> Fixture. Written by the agents extension (M3). Rendered at the **workforce gate** (D9) —
> this is what a human approves before implementation spends a token.
> Matching algorithm: `docs/contracts/agent-library-schema.md` §3.

## Roster

| Task | `(type, specialization)` | Agent | `id` | ver | Model | Source |
|---|---|---|---|---|---|---|
| T001 | `(scaffold, devtools-cli)` | sample-generalist | `agt_sample_generalist` | 1.0.0 | sonnet | library |
| T002 | `(scaffold, devtools-cli)` | sample-generalist | `agt_sample_generalist` | 1.0.0 | sonnet | library |
| T003 | `(docs, devtools-cli)` | sample-generalist | `agt_sample_generalist` | 1.0.0 | sonnet | library |
| T004 | `(docs, devtools-cli)` | sample-generalist | `agt_sample_generalist` | 1.0.0 | sonnet | library |

**Agents required:** 1 · **Generated (gap):** 0 · **Library hits:** 4/4

## Match trace

Both distinct pairs resolve to exactly one candidate, so §3's rank steps never run:

```
(scaffold, devtools-cli) → { agt_sample_generalist }   |candidates| = 1 → assign
(docs,     devtools-cli) → { agt_sample_generalist }   |candidates| = 1 → assign
```

`scaffold` and `docs` are both in the entry's `taxonomy.type`; `devtools-cli` is its
`taxonomy.specialization`. No gap, so the generator (D2) is not invoked.

## Model policy check (D18)

All four assignments are implementation-typed and run `sonnet`. `agent-library-schema.md` §4 holds.

## Scheduling guard

No task's `mutates=` intersects the shared/mutable list (`tasks.md` → *Shared-file serialization:
none found*), so no task is reserved for orchestrator glue. Wave 3 dispatches T003 and T004 in
parallel to two instances of the same agent — same specialist, disjoint `files=`.

---

## Workforce Gate — 2026-07-08T16:05:00Z

| Field | Value |
|---|---|
| reviewer | Babu |
| decision | `approved` |
| reviewed | `tasks.md`, this roster |

**Notes:** Fixture. Authored as part of the fixture; no real review occurred. `000-sample` is never
implemented, so the roster above is never dispatched.

**Overrides:** none.
