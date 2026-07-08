# Categorization — 000-sample

> Fixture. Written by the categorize extension (M3). Keyed by task ID from `tasks.md`.
> Does **not** mutate `tasks.md` (D37, `artifact-layout.md` §6).
> Enums are closed: `docs/contracts/taxonomy-v0.md` — **v0 BLESSED (normative), 2026-07-09**.

| Task | `type` | `specialization` | `preserves_behavior` | `tags` | Derivation (`taxonomy-v0.md` §2) |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | `false` | `fixture` | Phase 1 Setup; `files=` is a directory skeleton |
| T002 | `scaffold` | `devtools-cli` | `false` | `yaml`, `fixture` | Phase 2; `files=` is a tooling config file |
| T003 | `docs` | `devtools-cli` | `false` | `jsonl`, `observability` | `files=` outside `docs/`, but the deliverable is a reference document, not code |
| T004 | `docs` | `devtools-cli` | `false` | `markdown`, `fixture` | `files=` matches `*.md`… |

**`preserves_behavior` is `false` for all four** (`taxonomy-v0.md` §2.3): every task's `mutates=` is
`(new)`, so no file it touches pre-exists in the graph. The `refactor-discipline` auto-injection
therefore never fires here — the modifier's `true` branch is unexercised, exactly as `taxonomy-v0.md`
§8 carry-forward item 4 records.

## `general` cap check (`taxonomy-v0.md` §4)

`count(general) = 0`, `count(tasks) = 4`. `0 ≤ 0.20 × 4 = 0.8` ✓ — categorization passes.

Note the edge the cap creates: with 4 tasks the budget is `0.8`, i.e. **zero** `general` tasks are
permitted. This fixture happens to need none. A four-task feature that needed one would fail
categorization outright. Flagged in `taxonomy-v0.md` §8 (item 3), not patched.

## Categorizer notes

Two honest problems this fixture surfaces, both booked against the taxonomy's own review:

1. **T003/T004 stress the `docs` derivation rule.** The rule reads *"`files=` under `docs/`, or `*.md`
   outside `specs/`"* — and both tasks write files *inside* `specs/`. The rule as drafted classifies
   them as nothing at all. They are typed `docs` here on the deliverable's nature, which is precisely
   the interpretive judgment §1 claims `type` does not require. **The rule needs `specs/` carved out,
   or `type` is not as mechanical as §1 asserts.** Recorded as a review note, not patched.

2. **Every task lands in `devtools-cli`.** Expected for a fixture, but it means this artifact exercises
   the *shape* of categorization and only 2 of 8 types × 1 of 11 specializations. The taxonomy's real
   test is the worked example in `taxonomy-v0.md` §5, against graphify's own `tasks.md`.

## Assembly implication (D40)

Distinct lanes: `(scaffold, devtools-cli)` and `(docs, devtools-cli)`. Both resolve to the base
specialist `agt_sample_generalist`. No task's tags intersect any skill module's tags, and no task is
behavior-preserving — so **zero skills are injected** and the assembly cap of 3 never binds. See
`agents/assignment.md`.
