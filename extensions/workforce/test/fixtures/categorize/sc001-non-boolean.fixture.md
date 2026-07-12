# Categorization — validate-categorization.py SC-001 fixture: non-boolean (T013 case 3c)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s SC-001 case (c): T002's
> `preserves_behavior` cell is `maybe` — not a boolean `true`/`false` token per the
> shared scalar parser (`frontmatter.py`'s `_parse_scalar_token`, reused verbatim by
> `validate-categorization.py` rather than a bespoke string check, taxonomy.md
> §2.3). T001 is fully valid, isolating the breach to one row/field. Hand-authored,
> not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | test |
| T002 | `service` | `qa-automation` | maybe | false | test |
