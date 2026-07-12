# Agent Assignment — trace-roster fixture (T028/SC-008)

> A minimal, frozen `### Roster approved` table for `trace-roster-diff.sh`. Three distinct
> assemblies: a bare base, a base + two skills carrying a `web_search` grant, and a base + one
> `grants: []` skill. The diff asserts every `implementer` trace's assembly (agent_id + skills +
> elevated_grants) is one the roster approved — the SC-008/D41 grant-integrity property.

## Workforce Gate — 2026-07-12

| Field | Value |
|---|---|
| reviewer | Fixture |
| decision | `approved` |
| reviewed | fixture |

### Roster approved

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
| T001 | `agt_devtools_cli` | Sonnet | *(none — base suffices)* | none |
| T002 | `agt_backend_service` | Sonnet | `skl_rate_limiting@1.2.0`, `skl_refactor_discipline@1.0.0` | `web_search` |
| T003 | `agt_qa_automation` | Sonnet | `skl_shell_scripting@1.0.0` *(library)* | none |
