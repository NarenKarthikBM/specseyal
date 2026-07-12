---
description: "Match every categorized task to a base specialist + skills via the deterministic assemble.py, and write the agents/assignment.md roster"
---

# Agent Assign

Run the deterministic `assemble.py` matcher over `categorization.md` and the `.claude/agents`/`.claude/skills` library, writing the `### Roster approved` table and a pending `## Workforce Gate` into `agents/assignment.md`. Before assembling, verifies `categorization.md`'s recorded `tasks.md` SHA against the current one (S14) — a stale binding hard-warns and routes back to `/speckit-categorize` rather than assembling against stale classification.

## Behavior

- `assemble.py` (zero-AI, no model) matches every categorized task to a base + ≤3 ranked skills and writes the roster + `## Workforce Gate` `[PENDING ...]` markers into `agents/assignment.md` **itself** (S08) — this command never hand-edits the `### Roster approved` table.
- On a non-empty gap list, dispatches one Sonnet `skill-builder` session **per shared-tag gap cluster** — never one per task (dedup, FR-006/SC-007) — holding its declared `web_search` grant (D60); validates each candidate (`validate-skill.py`, S1–S3 + S04) and persists a pass into `.claude/skills/` (`origin: generated`, `source_feature`, FR-008), hard-failing/renaming on a live-library collision (S07) rather than silently skipping; a rejection is surfaced, never persisted (FR-007).
- Re-runs `assemble.py` once more, passing `--built-skill` for every skill persisted this run, so the final roster carries the `built` mark (FR-022) — stable per S15: only the originally-gapped rows may change. Reports the (possibly revised) `GAP_TASKS` and the `LIBRARY_SNAPSHOT_HASH` it stamped (S18); a run that started gap-free never dispatches anything and leaves zero `built` marks (SC-005).
- Under `gates.workforce.mode: human` the gate stays pending the signature (`/speckit-workforce-approve`, T017); under `auto` **and** no gap remains open, the assigner resolves the gate itself in the same write (FR-020, P4).
- `after_agent-assign` hook → phase-tagged `git.commit` (`agents(<spec-id>): …`) — mechanical, no trace. One `agent-creator` trace is appended per gap-cluster dispatch (zero on a gap-free run).

## Execution

Run the `/speckit-agent-assign` skill (this command file is its provenance source).
