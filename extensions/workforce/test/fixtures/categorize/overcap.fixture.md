# Categorization — validate-categorization.py over-cap fixture (T013 case 2 / SC-002/S22)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s case 2: `count(general) = 3` out
> of `total = 10` — strictly above the `0.20 × 10 = 2` cap (FR-004/SC-002,
> taxonomy-v0.md § The `general` cap). Every row is otherwise well-formed (all four
> fields present, closed-enum, boolean, kebab tags) so the ONLY breach this fixture
> triggers is the cap — isolating the S22 no-write assertion from any coverage/enum
> noise. Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (10 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | tags |
|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | scaffold |
| T002 | `service` | `general` | false | misc |
| T003 | `endpoint` | `general` | false | misc |
| T004 | `data-model` | `general` | false | misc |
| T005 | `ui` | `frontend-web` | false | component |
| T006 | `test` | `qa-automation` | false | test |
| T007 | `docs` | `ai-agents` | false | docs |
| T008 | `infra` | `infra-platform` | false | infra |
| T009 | `service` | `backend-service` | false | api |
| T010 | `test` | `security` | false | test |

## Cap Check

`general 3 / total 10 (≤ 0.20 × 10 = 2)` → **FAIL** (3 > 2). A conforming
`validate-categorization.py` run over this file MUST exit non-zero and write
NOTHING — not even into an explicit output-path argument (S22).
