# Categorization — validate-categorization.py SC-001 fixture: missing field (T013 case 3a)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s SC-001 case (a): T002's `type`
> cell is present in shape (the row still has all 5 pipe-delimited columns, so this
> is NOT a "wrong column count" row-shape error) but its CONTENT is empty — the
> coverage requirement's "all four fields" breach (spec.md FR-002/SC-001). T001 is
> fully valid, isolating the breach to exactly one row/field. Hand-authored, not
> categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | scaffold, tree |
| T002 |  | `devtools-cli` | false | false | test |
