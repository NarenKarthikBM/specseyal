---
description: "Record the human-gate decision on the assembled workforce roster and unlock /speckit-implement-parallel"
---

# Workforce Human Gate

Record the human's gate decision (approved / approved-with-notes / rejected) into the `## Workforce Gate` section of `agents/assignment.md` — resolving its six `[PENDING …]` fields in place. Approval fires the git-ext gate-write and unlocks `/speckit-implement-parallel`; rejection returns the roster for reassignment (W3). Mirrors `/speckit-council-approve` exactly (S13); human review is this gate's final arbiter, same as the council's (D3/D9).

## Behavior

- The human reads `agents/assignment.md`'s `### Roster approved` table (base, model, skills, elevated grants per assembled agent) against `tasks.md`.
- Resolves the six decision fields of the existing `## Workforce Gate` section (timestamp, reviewer, decision, reviewed, notes, overrides) — **never** the `### Roster approved` table nested inside the same section, which is `assemble.py`'s alone (T014; the principle-I within-file write boundary).
- Runs **no session** and writes **no trace** (a human acts; `artifact-layout.md` §2 / `trace-schema.md` R9).
- On `approved`/`approved-with-notes` only, fires `after_workforce_approve` — handled entirely in git-ext's own source (D57 S2) via the generalized `on-gate-approve.sh workforce`, which binds `tasks.md` + `assignment.md @ <sha>` into `gates.yml` (S02) and is what lets the `before_implement` verify-gate pass. Never fires on `rejected` — that event denotes an approval existing, not merely this command having run.
- Under `gates.workforce.mode: auto`, `/speckit-agent-assign` writes the gate section itself and fires the same gate-write; this command is then verify-only. `disable-model-invocation: true` — the human gate is never model-invoked.

## Execution

Run the `/speckit-workforce-approve` skill (this command file is its provenance source).
