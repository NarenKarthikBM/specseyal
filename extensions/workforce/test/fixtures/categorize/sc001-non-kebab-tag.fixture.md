# Categorization — validate-categorization.py SC-001 fixture: non-kebab tag (T013 case 3d)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s SC-001 case (d): T002's `tags`
> cell contains `BadTag_NotKebab`, which does not match `^[a-z0-9]+(-[a-z0-9]+)*$`
> (taxonomy-v0.md §6 — free tags must be lowercase-kebab). T001 is fully valid,
> isolating the breach to one row/field. Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | tags |
|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | test |
| T002 | `service` | `qa-automation` | false | BadTag_NotKebab |
