---
feature: 099-generic-example
phase: complete
status: success
---

## Implementation Complete — a-generic-feature

**Waves run: 2** (widest parallel wave: **3** subagents — Wave 2). **Roster:** Sonnet
implementation subagents for all tasks; no orchestrator-inline glue was needed.

### Completed (5/5)

| Wave | Tasks | Outcome |
|---|---|---|
| 1 | T001, T002 | scaffold + config |
| 2 | T003, T004, T005 | logic, tests, docs |

### Partial/Degraded

None.

### Failed

None.

### Integration status

- `extensions/example/test/run.sh` is green (12/0); the feature's own contract (if any) validates.

### Key results

- A generic, non-dogfood feature: no milestone to close, so this report carries no appendix (the
  edge case `spec.md` names) — the contract validates identically either way (SC-005).
