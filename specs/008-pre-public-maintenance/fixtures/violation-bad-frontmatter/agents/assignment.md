# Agent Assignment — violation-bad-frontmatter

> Fixture (T007). Written by the agents extension (M3). Rendered at the workforce gate (D9) —
> this is what a human approves before implementation spends a token.
> Assembly algorithm: `agent-library-schema.md` §3. Agents are **assembled, not stored** (D40).

## Roster

Each row is an *assembled* agent: a base specialist selected by `(type, specialization)`, plus up
to three tag-selected skill modules, plus the union of those skills' tool grants (D41).

| Task | Lane `(type, specialization)` | Base | Base `id` | Model | Injected skills | **Tool grants (D41)** |
|---|---|---|---|---|---|---|
| T001 | `(scaffold, devtools-cli)` | fixture-generalist | `agt_fixture_generalist` | sonnet | *(none)* | *(core only)* |
| T002 | `(docs, devtools-cli)` | fixture-generalist | `agt_fixture_generalist` | sonnet | *(none)* | *(core only)* |

**Lanes resolved:** 1/1 · **Bases used:** 1 · **Skills injected:** 0 · **Skills authored (gap):** 0
**Network access requested by any agent:** **none.** Core toolset only: `Read, Write, Edit, Bash, Glob, Grep`.

## Assembly trace

```
base = agt_fixture_generalist (unique lane for both tasks' (type, specialization) pairs)
candidates = ∅   (no skill library ships with this fixture -- agent-library-schema's direct
                  check is scoped to this roster's shape, not the base/skill library files,
                  per specs/008-pre-public-maintenance/data-model.md E3)
injected = ∅
grants = ⋃ ∅ = ∅ → core toolset only
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
| T001, T002 | `fixture-generalist` | Sonnet | *(none)* | none |

**Notes:** Fixture. Authored as part of T007; no real review occurred.

**Overrides:** none.
