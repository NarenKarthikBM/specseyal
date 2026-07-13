---
description: "Re-read tasks.md + implement.log.md from disk and author the finalized completion-report.md — main thread only, no dispatch, no new model role"
---

# Complete

Close out an `implement` run. Read `tasks.md` and `implement.log.md` fresh off disk and write `completion-report.md` — the `complete` phase's sole artifact, in the finalized, contract-validated format (`docs/contracts/completion-report.md`). This is the first phase-command in the pipeline where the **main thread itself is the author**: every sibling command either dispatches a subagent (`/speckit-categorize`, `/speckit-council`) or runs a human/mechanical step with no model at all (`/speckit-workforce-approve`, `speckit.git.commit`) — here the orchestrator (Opus) writes the artifact directly, in its own turn. No new model role is introduced (FR-001).

## Behavior

- Re-reads `tasks.md` + `implement.log.md` from disk on **every** invocation — never from context already held earlier in this same conversation (`R1-S02`, council-ratified). Resumability (Constitution III) beats context retention: the assumption would silently break across a long multi-wave run, a `/clear`, or a resumed session.
- Writes **exactly one** artifact, `completion-report.md`, and no other (principle 1): frontmatter `status ∈ {success, partial, failed}` (FR-003) plus the six ordered core sections `docs/contracts/completion-report.md` §2 fixes — a dogfood/milestone-close build may add the optional appendix (§3), which never changes what validates.
- `status` is derived truthfully from the run's own record in `tasks.md`/`implement.log.md` — never `success` when any task finished partial or failed (`spec.md` US1 scenario 2).
- Runs entirely in `main`: no `Agent`-tool dispatch, no standalone script (FR-001). The phase's trace is the main-thread orchestrator's own record — not a dispatched session's.
- A malformed or absent `completion-report.md` leaves the `complete` phase **incomplete** — the pipeline stops here (resumability rule, `artifact-layout.md` §3); nothing downstream (the `after_complete` commit, `/speckit-testing`) proceeds.
- Exists as a command boundary (ratified `R1-S17`: every other pipeline phase is already a `/speckit-*` command) so git-ext's `after_complete` hook (the `complete(<id>)` phase-tagged commit) and M5's future `after_complete` D19 push have something to hang on (FR-005/012).

## Execution

Run the `/speckit-complete` skill (this command file is its provenance source). No subagent dispatch and no standalone script: the orchestrator authors `completion-report.md` directly, in the main thread's own turn.
