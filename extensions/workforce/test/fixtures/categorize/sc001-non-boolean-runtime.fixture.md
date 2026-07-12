# Categorization — validate-categorization.py SC-001 fixture: non-boolean runtime_consumed (v1, D65)

> **Frozen test fixture.** The `runtime_consumed` sibling of `sc001-non-boolean.fixture.md`:
> T002's `runtime_consumed` cell is `maybe` — not a boolean `true`/`false` token per the
> shared scalar parser (`frontmatter.py`'s `_parse_scalar_token`, reused verbatim by
> `validate-categorization.py` for both modifier columns, taxonomy.md §2.4). T001 is fully
> valid, isolating the breach to the one new v1 field. Proves the validator holds
> `runtime_consumed` to the same boolean discipline as `preserves_behavior`. Hand-authored,
> not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) — a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | test |
| T002 | `service` | `qa-automation` | false | maybe | test |
