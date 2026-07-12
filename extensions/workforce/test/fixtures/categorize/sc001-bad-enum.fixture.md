# Categorization — validate-categorization.py SC-001 fixture: out-of-enum (T013 case 3b)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s SC-001 case (b): T001 carries a
> `type` value (`refactor`) that is not one of the closed 8 (taxonomy.md §2);
> T002 carries a `specialization` value (`frontend-mobile`) that is not one of the
> closed 11 (taxonomy.md §4). Neither value is a typo of a real enum member —
> deliberately un-enumerable, per the module docstring's "never invents or coerces
> a value into one it recognizes." Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `refactor` | `devtools-cli` | false | false | test |
| T002 | `service` | `frontend-mobile` | false | false | test |
