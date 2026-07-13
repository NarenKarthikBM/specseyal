---
description: "Dispatch one Sonnet tester subagent (separate session) over completion-report.md + spec.md only; the tester writes testing.md (doc-only, executed: none) and returns status-only; main appends one role: tester trace carrying context_in (R1-S06)"
---

# Testing

Run the pipeline's doc-only `testing` phase. After `/speckit-complete` has written a validated `completion-report.md`, `/speckit-testing` dispatches **one** Sonnet `tester` subagent — a separate session (context hygiene, `artifact-layout.md` §2) — that reads `completion-report.md` + `spec.md` **only** and writes `testing.md`: a coverage map mapping every Success Criterion **and** Functional Requirement in `spec.md` to a verification approach, grounded in the report's `### Integration status`, with any uncovered item flagged an honest `GAP`. The tester never executes a test — `executed: none` is fixed — and it returns **status-only** to main; no completion-report or spec body crosses back into the main thread.

## Behavior

- Dispatches **one Sonnet `tester` subagent** (the separate session `artifact-layout.md` §2 assigns this phase) — not a workforce-assembled agent: `agent_id: null`, `skills: []`, `elevated_grants: []`, exactly like every other non-`implementer` role.
- Context-in is **`completion-report.md` + `spec.md` only** (session-boundary rule, FR-006/SC-003) — main never opens either file itself, before or after dispatch. The tester MAY additionally, lazily read `implement.log.md` on doubt as a cross-check (R1-S05, the D10 pattern) and marks each coverage-map row's evidence source (`report-claimed`/`log-verified`) accordingly.
- Writes exactly one artifact, `testing.md`, and no other (principle 1): frontmatter `executed: none` (fixed) + `## Coverage map` (one row per every `SC-\d+`/`FR-\d+` id in `spec.md`) + `## Verified by reading vs. would-execute in v2` — validating against `docs/contracts/testing-doc.md`.
- Returns **status-only** to main (SC-003) — a single status line, never the coverage table or any file body; main copies its structured facts (row/gap counts, which files were actually read) straight through, never re-deriving them by opening `testing.md`/`completion-report.md`/`spec.md` itself.
- Main appends **exactly one** trace record: `role: "tester"`, `model: "claude-sonnet-5"`, `agent_id: null`, `skills: []`, `elevated_grants: []`, plus a **`context_in`** field naming the files the tester actually read (R1-S06) — sourced from the tester's own status line, never independently re-derived.
- Runs strictly **after** `/speckit-complete`: `testing.md`'s coverage map grounds every row in the completion report's `### Integration status` (FR-008), so an absent or invalid `completion-report.md` blocks this phase by construction.
- A malformed or absent `testing.md` leaves the `testing` phase **incomplete** — the pipeline stops here (resumability rule, `artifact-layout.md` §3).
- Honors the `after_testing` hook (git-ext's own, owned-source) when registered — an errored or empty invocation **halts the phase** (R1-S07); no row registered is not an error (the hook is a consequence of completion, not a precondition of it).

## Execution

Run the `/speckit-testing` skill (this command file is its provenance source). One subagent dispatch (the Sonnet `tester`, a separate session) and no standalone script: the orchestrator dispatches, then appends the trace and honors the `after_testing` hook, in its own turn.
