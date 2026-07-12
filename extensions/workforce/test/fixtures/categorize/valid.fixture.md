# Categorization — validate-categorization.py conforming fixture (T013 case 1)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_categorize.sh`'s case 1 (a fully conforming
> `categorization.md`): all five fields present on every row, every `type` and
> `specialization` a member of the closed taxonomy enums, `preserves_behavior`
> a real boolean (both spellings exercised), `runtime_consumed` likewise (T007's
> prompt asset is `true`, the D65 v1 modifier — taxonomy.md §2.4), tags
> lowercase-kebab, and `general` under the cap. Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (10 tasks) — a
> fixture value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | scaffold, tree |
| T002 | `service` | `backend-service` | false | false | api, service |
| T003 | `endpoint` | `backend-service` | false | false | http, endpoint |
| T004 | `data-model` | `data-persistence` | false | false | schema, model |
| T005 | `ui` | `frontend-web` | false | false | component, view |
| T006 | `test` | `qa-automation` | false | false | test, unit |
| T007 | `docs` | `ai-agents` | false | true | docs, prompt |
| T008 | `infra` | `infra-platform` | false | false | infra, deploy |
| T009 | `service` | `general` | false | false | misc |
| T010 | `test` | `security` | true | false | test, security |

## Cap Check

`general 1 / total 10 (≤ 0.20 × 10 = 2)` → **PASS** (1 ≤ 2). One task legitimately
falls to the `general` escape hatch, well under the cap — exercising that `general`
is allowed (just bounded), not forbidden outright.
