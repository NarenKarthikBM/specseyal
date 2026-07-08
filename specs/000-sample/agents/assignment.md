# Agent Assignment — 000-sample

> Fixture. Written by the agents extension (M3). Rendered at the **workforce gate** (D9) —
> this is what a human approves before implementation spends a token.
> Assembly algorithm: `agent-library-schema.md` §3. Agents are **assembled, not stored** (D40).

## Roster

Each row is an *assembled* agent: a base specialist selected by `(type, specialization)`, plus up to
three tag-selected skill modules, plus the union of those skills' tool grants (D41).

| Task | Lane `(type, specialization)` | Base | Base `id` | Model | Injected skills | **Tool grants (D41)** |
|---|---|---|---|---|---|---|
| T001 | `(scaffold, devtools-cli)` | sample-generalist | `agt_sample_generalist` | sonnet | *(none)* | *(core only)* |
| T002 | `(scaffold, devtools-cli)` | sample-generalist | `agt_sample_generalist` | sonnet | *(none)* | *(core only)* |
| T003 | `(docs, devtools-cli)` | sample-generalist | `agt_sample_generalist` | sonnet | *(none)* | *(core only)* |
| T004 | `(docs, devtools-cli)` | sample-generalist | `agt_sample_generalist` | sonnet | *(none)* | *(core only)* |

**Lanes resolved:** 2/2 · **Bases used:** 1 · **Skills injected:** 0 · **Skills authored (gap):** 0
**Network access requested by any agent:** **none.** Core toolset only: `Read, Write, Edit, Bash, Glob, Grep`.

> **Approving this roster approves its grant column** (D41). No agent above can reach the network,
> because no injected skill declares `web_search` — because no skill is injected at all.

## Assembly trace

```
# Base — fixed core, exactly one lane each
(scaffold, devtools-cli) → agt_sample_generalist    (unique lane)
(docs,     devtools-cli) → agt_sample_generalist    (unique lane)

# Skills — free tags, ranked, capped at 3
library skills = { skl_refactor_discipline : tags [refactor, blast-radius, behavior-preserving] }
task tags      = { fixture, yaml, jsonl, observability, markdown }
candidates     = ∅            (no tag intersection)
forced         = ∅            (preserves_behavior = false for all four tasks)
injected       = ∅            (cap of 3 never binds)
dropped        = ∅            (nothing to log)

# Grants — union of injected skills' declarations
grants = ⋃ ∅ = ∅              → core toolset only
```

`skl_refactor_discipline` is present in the library and matched by nothing. That is the correct
outcome, not a miss: no sample task is behavior-preserving (`categorization.md`).

**Gap:** none. `candidates = ∅` would normally invoke the skill builder (D2, D40.2), but only when the
task carries tags no skill covers *and* the work needs knowledge the base lacks. A fixture that writes
markdown needs neither.

## Model policy check (D18)

`agt_sample_generalist` accepts implementation types (`scaffold`, `data-model`, `test`) and runs
`sonnet`. `agent-library-schema.md` §4 holds. No skill declares a model — skills are not dispatch
targets.

## Scheduling guard

No task's `mutates=` intersects the shared/mutable list (`tasks.md` → *Shared-file serialization:
none found*), so no task is reserved for orchestrator glue. Wave 3 dispatches T003 and T004 in
parallel — same assembled agent, disjoint `files=`.

## Unexercised by this fixture — flagged, not fabricated

The roster below is honest about what it does *not* demonstrate. Each is booked in `taxonomy-v0.md` §8:

- **Skill injection.** Zero skills are injected, so tag-Jaccard ranking, the assembly cap of 3, and
  the drop-and-log rule are all unexercised.
- **A non-empty grant set.** No sample task needs the network, so the D41 grant column is uniformly
  empty. The column's *presence* is exercised; its *content* is not.
- **The `refactor-discipline` auto-injection.** No task is behavior-preserving.

Inventing a task that needed `web_search` would have exercised the column at the cost of making the
fixture lie about what `000-sample` is. The column stays empty and the gap stays visible.

---

## Workforce Gate — 2026-07-08T16:05:00Z

| Field | Value |
|---|---|
| reviewer | Babu |
| decision | `approved` |
| reviewed | `tasks.md`, this roster, **and its grant column** |

**Notes:** Fixture. Authored as part of the fixture; no real review occurred. `000-sample` is never
implemented, so the roster above is never dispatched.

**Overrides:** none.
