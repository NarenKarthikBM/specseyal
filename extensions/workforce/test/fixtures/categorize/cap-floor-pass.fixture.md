# Categorization — validate-categorization.py small-feature floor fixture (v1, D65 verdict 9)

> **Frozen test fixture.** A **4-task** feature (n < 5) with **one** `general` task.
> Under v0's literal 20% cap this FAILED (`⌊0.20 × 4⌋ = 0`, so zero `general` allowed —
> D44's formal absurdity). Under the v1 floor'd cap `max(1, ⌊0.2·n⌋)` (taxonomy.md §4,
> D65 verdict 9) the ceiling is `max(1, 0) = 1`, so `general 1/4` is **within cap → exit 0**.
> This fixture is what makes the floor a checked property, not just a documented one.
> Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (4 tasks) — a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | scaffold |
| T002 | `service` | `general` | false | false | misc |
| T003 | `endpoint` | `backend-service` | false | false | http |
| T004 | `test` | `qa-automation` | false | false | test |

## Cap Check

`general 1 / total 4 (≤ max(1, ⌊0.20 × 4⌋) = max(1, 0) = 1)` → the floor admits exactly
one `general` task for a sub-5-task feature; `1 ≤ 1`, so a conforming run exits 0.
