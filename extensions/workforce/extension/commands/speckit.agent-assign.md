---
description: "Match every categorized task to a base specialist + skills via the deterministic assemble.py, and write the agents/assignment.md roster"
---

# Agent Assign

Run the deterministic `assemble.py` matcher over `categorization.md` and the `.claude/agents`/`.claude/skills` library, writing the `### Roster approved` table and a pending `## Workforce Gate` into `agents/assignment.md`. Before assembling, verifies `categorization.md`'s recorded `tasks.md` SHA against the current one (S14) — a stale binding hard-warns and routes back to `/speckit-categorize` rather than assembling against stale classification.

## Behavior

- Zero-AI: `assemble.py` runs no model, and this command currently dispatches no session either — the static-library path (US2). The ∅-match skill-builder handoff is wired by a later task (T025), which edits this same command file at its marked `## 2. Gap handoff` section.
- `assemble.py` writes the roster + `## Workforce Gate` `[PENDING ...]` markers into `agents/assignment.md` **itself** (S08) — this command never hand-edits the `### Roster approved` table.
- Reports the `GAP_TASKS` list (∅-match tasks) and the `LIBRARY_SNAPSHOT_HASH` it stamped (S18), without fabricating a skill for any gap; a gap-free run leaves zero `built` marks (SC-005).
- Under `gates.workforce.mode: human` the gate stays pending the signature (`/speckit-workforce-approve`, T017); under `auto` **and** gap-free, the assigner resolves the gate itself in the same write (FR-020, P4).
- `after_agent-assign` hook → phase-tagged `git.commit` (`agents(<spec-id>): …`) — mechanical, no trace.

## Execution

Run the `/speckit-agent-assign` skill (this command file is its provenance source).
