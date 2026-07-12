# Categorization — validate-categorization.py SC-001 fixture: duplicate task_id (T013 case 3e)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s SC-001 case (e): `T001` appears
> TWICE, on two otherwise-valid rows — data-model.md §1's "present, unique"
> requirement on `task_id`. Both rows are individually well-formed (all four fields,
> closed-enum, boolean, kebab tags), isolating the breach to exactly the duplicate
> identity, not a row-content defect. Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | test |
| T001 | `service` | `qa-automation` | false | false | test |
