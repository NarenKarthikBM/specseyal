---
description: "Record the human-gate decision on a triaged plan and unlock /speckit-tasks"
---

# Council Human Gate

Record the human's gate decision (approved / approved-with-notes / rejected) as a `## Human Gate` section appended to `council/decision-record.md`. Approval unlocks `/speckit-tasks`; rejection returns the plan for one more revision round. Human review is the council's final arbiter (D3/D9).

## Behavior

- The human reads `defense-deck/overview.md`, `suggestions.md`, and `decision-record.md`.
- Appends a contract-conforming `## Human Gate` section (reviewer, decision, reviewed, notes, overrides).
- Runs **no session** and writes **no trace** (a human acts; `artifact-layout.md` §2).
- Under `gates.council.mode: auto` (only within `full_auto`), triage writes the gate section; this command is verify-only. `disable-model-invocation: true` — the human gate is never model-invoked.

## Execution

Run the `/speckit-council-approve` skill (this command file is its provenance source).
