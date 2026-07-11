# Categorization — validate-categorization.py conforming fixture (T013 case 1)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s case 1 (a fully conforming
> `categorization.md`): all four fields present on every row, every `type` and
> `specialization` a member of the closed taxonomy v0 enums, `preserves_behavior`
> a real boolean (both spellings exercised), tags lowercase-kebab, and `general`
> under the 20% cap. Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (10 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | tags |
|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | scaffold, tree |
| T002 | `service` | `backend-service` | false | api, service |
| T003 | `endpoint` | `backend-service` | false | http, endpoint |
| T004 | `data-model` | `data-persistence` | false | schema, model |
| T005 | `ui` | `frontend-web` | false | component, view |
| T006 | `test` | `qa-automation` | false | test, unit |
| T007 | `docs` | `ai-agents` | false | docs, prompt |
| T008 | `infra` | `infra-platform` | false | infra, deploy |
| T009 | `service` | `general` | false | misc |
| T010 | `test` | `security` | true | test, security |

## Cap Check

`general 1 / total 10 (≤ 0.20 × 10 = 2)` → **PASS** (1 ≤ 2). One task legitimately
falls to the `general` escape hatch, well under the cap — exercising that `general`
is allowed (just bounded), not forbidden outright.
