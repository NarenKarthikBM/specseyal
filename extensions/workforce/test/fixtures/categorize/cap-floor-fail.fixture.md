# Categorization — validate-categorization.py small-feature over-floor fixture (v1, D65 verdict 9)

> **Frozen test fixture.** The companion to `cap-floor-pass.fixture.md`: a **4-task**
> feature (n < 5) with **two** `general` tasks. The v1 floor is exactly ONE — `max(1,
> ⌊0.2 × 4⌋) = 1` — so `general 2/4` **exceeds** the cap and a conforming run MUST exit
> non-zero and write nothing. This proves the floor lifts the ceiling to 1, not to
> "unbounded for small n": the cap still bites, just one task later. Hand-authored, not
> categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (4 tasks) — a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | scaffold |
| T002 | `service` | `general` | false | false | misc |
| T003 | `endpoint` | `general` | false | false | misc |
| T004 | `test` | `qa-automation` | false | false | test |

## Cap Check

`general 2 / total 4 (≤ max(1, ⌊0.20 × 4⌋) = 1)` → **FAIL** (2 > 1). The floor admits one
`general` task, not two; the cap still fails an over-general small feature.
