# Quickstart — 004-testing-completion

Runnable validation scenarios that prove the tail works end to end. Each maps to a Success Criterion. References the contracts (`docs/contracts/completion-report.md`, `docs/contracts/testing-doc.md`) and `data-model.md` rather than duplicating them. Run from the repo root.

**Prerequisites:** the testing extension installed (`bash extensions/testing/install.sh .`); the git extension reinstalled to carry the seam + I-17 fix (`bash extensions/git/install.sh .`); a feature with a finished implement phase (`tasks.md` all `[X]`, `implement.log.md` present).

## SC-001 — completion report validates
- **Do:** run `/speckit-complete`.
- **Expect:** `completion-report.md` exists with frontmatter `status ∈ {success, partial, failed}` and **100 %** of the required core sections (§ data-model CompletionReport). The contract validator (testing-ext `test/run.sh`) exits 0.

## SC-002 — testing doc validates
- **Do:** run `/speckit-testing` against the report + `spec.md`.
- **Expect:** `testing.md` validates against `docs/contracts/testing-doc.md` (frontmatter `executed: none`, `## Coverage map`, the honest split).

## SC-003 — separate session, status-only
- **Do:** run `/speckit-testing`; inspect the trace + the main-thread return.
- **Expect:** exactly one `role: tester` (Sonnet) trace; only `testing.md` crossed back — no `completion-report.md`/`spec.md` body re-imported into the main thread.

## SC-004 — 100 % SC + FR coverage, gaps flagged, executed:none
- **Do:** count the spec's SCs (N) + FRs (M); diff against `testing.md`'s coverage map.
- **Expect:** all N + M appear with a verification approach; every item the completion report does not evidence is a **GAP**, never a fabricated "covered"; `executed: none` recorded.

## SC-005 — core validates with or without the dogfood overlay
- **Do:** validate a generic `completion-report.md` (core only) and M4's own (core + `## Milestone-close context` appendix).
- **Expect:** both pass — the contract validates the **core**, and the appendix is optional (outside the validated set).

## SC-006 — both phases leave a phase-tagged commit
- **Do:** run `complete` then `testing`; `git log --oneline`.
- **Expect:** a `complete(004-testing-completion)` and a `testing(004-testing-completion)` commit at their boundaries (D25/FR-006 grammar).

## SC-007 — exactly one net-new AI role, no API key
- **Do:** review the roster + traces; `env | grep ANTHROPIC_API_KEY` (expect empty).
- **Expect:** the only net-new role is the Sonnet `tester`; `complete` adds no model call beyond the orchestrator; `ANTHROPIC_API_KEY` unset everywhere (D28).

## SC-008 — the git-ext testing seam survives reinstall
- **Do:** `bash extensions/git/install.sh .`; then reinstall a foreign extension (e.g. `bash extensions/workforce/install.sh .`); run the `testing` phase again.
- **Expect:** the `testing`-phase commit still fires — the seam lives in git-ext's own source (artifact-layout §9/S3); `extensions/git/test/run.sh` §3 asserts it green.

## SC-009 (M4 exit) — validated report + testing doc, both committed
- **Do:** complete M4's own run.
- **Expect:** both a validated `completion-report.md` **and** a validated `testing.md`, each phase-tagged-committed (docs/05 M4 done-when).

## SC-010 (I-17 prerequisite) — wave 2+ passes freshness, zero hand assistance
- **Do:** during M4's own implement, let wave 1 (or a pre-wave task) land the verify-gate.sh checkbox-delta fix + reinstall git-ext; run waves 2+.
- **Expect:** the per-wave `verify-gate workforce` check **passes** for waves 2+ under the live installed machinery with **no hand assistance** — `tasks.md`'s cumulative `[ ]`→`[X]` delta classifies as admissible; a deliberately-injected content edit to `tasks.md` still **blocks** (the S05/FR-009 invariant held). Proves the fix on the dogfood run itself.
