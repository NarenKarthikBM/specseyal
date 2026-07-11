# Categorization — validate-categorization.py cap-boundary fixture (T013 case 4)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s case 4: `count(general) = 2` out
> of `total = 10` — EXACTLY `0.20 × 10`, the cap boundary itself. `validate_cap()`
> (extension/scripts/validate-categorization.py) evaluates the breach as the exact
> integer inequality `general * 5 > total * 1` (never a float `>` / `>=` comparison),
> so at this exact boundary `2*5 == 10*1` — NOT a breach: the cap is `>`, not `≥`.
> A conforming run over this file MUST exit 0. Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (10 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | tags |
|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | scaffold |
| T002 | `service` | `general` | false | misc |
| T003 | `endpoint` | `general` | false | misc |
| T004 | `data-model` | `data-persistence` | false | schema |
| T005 | `ui` | `frontend-web` | false | component |
| T006 | `test` | `qa-automation` | false | test |
| T007 | `docs` | `ai-agents` | false | docs |
| T008 | `infra` | `infra-platform` | false | infra |
| T009 | `service` | `backend-service` | false | api |
| T010 | `test` | `security` | false | test |

## Cap Check

`general 2 / total 10 (≤ 0.20 × 10 = 2)` → **PASS** (2 ≤ 2, the boundary itself).
