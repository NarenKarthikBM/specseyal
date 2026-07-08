# Categorization — 000-sample

> Fixture. Written by the categorize extension (M3). Keyed by task ID from `tasks.md`.
> Does **not** mutate `tasks.md` (D37, `artifact-layout.md` §6).
> Enums are closed: `docs/contracts/taxonomy-v0.md` — **still a DRAFT**, so these keys are provisional.

| Task | `type` | `specialization` | `tags` | Derivation (`taxonomy-v0.md` §2) |
|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | `fixture` | Phase 1 Setup; `files=` is a directory skeleton |
| T002 | `scaffold` | `devtools-cli` | `yaml`, `fixture` | Phase 2; `files=` is a tooling config file |
| T003 | `docs` | `devtools-cli` | `jsonl`, `observability` | `files=` outside `docs/`, but the deliverable is a reference document, not code |
| T004 | `docs` | `devtools-cli` | `markdown`, `fixture` | `files=` matches `*.md` outside `specs/`… |

## Categorizer notes

Two honest problems this fixture surfaces, both belonging to `taxonomy-v0.md`'s open questions:

1. **T003/T004 stress the `docs` derivation rule.** The rule reads *"`files=` under `docs/`, or `*.md`
   outside `specs/`"* — and both tasks write files *inside* `specs/`. The rule as drafted classifies
   them `general`-adjacent nothing. They are tagged `docs` here on the deliverable's nature, which is
   precisely the interpretive judgment §1 claims `type` does not require. **The rule needs `specs/`
   carved out, or `type` is not as mechanical as §1 asserts.** Recorded as a review note, not patched —
   the taxonomy is awaiting Babu's blessing.

2. **Every task lands in `devtools-cli`.** Expected for a fixture, but it means this artifact exercises
   the *shape* of categorization and only 2 of 9 types × 1 of 11 specializations. The taxonomy's real
   test is the worked example in `taxonomy-v0.md` §5, against graphify's own `tasks.md`.

## Roster implication

Distinct `(type, specialization)` pairs: `(scaffold, devtools-cli)`, `(docs, devtools-cli)`.
Both are accepted by `agt_sample_generalist` (`.claude/agents/agt-sample-generalist.md`), so this
feature needs one agent and the gap generator is not invoked.
