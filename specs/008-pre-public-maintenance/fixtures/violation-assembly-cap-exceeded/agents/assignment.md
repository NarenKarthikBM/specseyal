# Agent Assignment — violation-assembly-cap-exceeded

> Fixture (T007). Written by the agents extension (M3). Rendered at the workforce gate (D9) —
> this is what a human approves before implementation spends a token.
> Assembly algorithm: `agent-library-schema.md` §3. Agents are **assembled, not stored** (D40).

## Roster

Each row is an *assembled* agent: a base specialist selected by `(type, specialization)`, plus up
to three tag-selected skill modules, plus the union of those skills' tool grants (D41).

| Task | Lane `(type, specialization)` | Base | Base `id` | Model | Injected skills | **Tool grants (D41)** |
|---|---|---|---|---|---|---|
| T001 | `(scaffold, devtools-cli)` | fixture-generalist | `agt_fixture_generalist` | sonnet | `skl_a@1.0.0`, `skl_b@1.0.0`, `skl_c@1.0.0`, `skl_d@1.0.0` | *(core only)* |
| T002 | `(docs, devtools-cli)` | fixture-generalist | `agt_fixture_generalist` | sonnet | *(none)* | *(core only)* |

**Lanes resolved:** 1/1 · **Bases used:** 1 · **Skills injected:** 4 · **Skills authored (gap):** 0
**Network access requested by any agent:** **none.** Core toolset only: `Read, Write, Edit, Bash, Glob, Grep`.

## Assembly trace

```
base = agt_fixture_generalist (unique lane for T001's (scaffold, devtools-cli) pair)
candidates = { skl_a, skl_b, skl_c, skl_d }   (all four tag-matched T001)
forced = ∅
ranked = [skl_a, skl_b, skl_c, skl_d]           (Jaccard tie broken by id, ascending)
injected = first 3 of (forced ++ ranked)         # ASSEMBLY CAP = 3 (D40) -- VIOLATED BELOW:
                                                  # this roster injects all 4, never trimming
dropped = ∅                                      # WRONG: skl_d should have been dropped+logged
grants = ⋃ {skl_a, skl_b, skl_c, skl_d}.grants = ∅ → core toolset only
```

## Model policy check (D18)

`agt_fixture_generalist` accepts implementation types (`scaffold`, `docs`) and runs `sonnet`.
`agent-library-schema.md` §4 holds.

---

## Workforce Gate — 2026-07-15T12:00:00Z

| Field | Value |
|---|---|
| reviewer | Fixture |
| decision | `approved` |
| reviewed | `tasks.md`, this roster, **and its grant column** |

### Roster approved

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
| T001 | `fixture-generalist` | Sonnet | `skl_a@1.0.0`, `skl_b@1.0.0`, `skl_c@1.0.0`, `skl_d@1.0.0` | none |
| T002 | `fixture-generalist` | Sonnet | *(none)* | none |

**Notes:** Fixture. Authored as part of T007; no real review occurred.

**Overrides:** none.
