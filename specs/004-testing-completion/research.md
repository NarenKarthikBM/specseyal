# Research — 004-testing-completion

Phase 0 design decisions. Every entry resolves a plan-level choice the spec deferred (D68) or a design question the two concerns raise. No `NEEDS CLARIFICATION` remain — the spec's Clarifications (2026-07-12) fixed coverage scope (SC + FR) and verification depth (a verification approach per item).

## D-R1 — Testing seam: the 002 pattern (hook + owned-source enum entry)

- **Decision.** Add `testing` to `commit.sh`'s phase enum, and register `after_testing` + `after_complete` hooks — **all in the git extension's own source** (`extensions/git/`). The testing extension provides the phase *commands*; the git extension hooks its commit primitive onto their boundaries (D57 §9 cross-extension seam).
- **Rationale.** This is the exact shape 002 established and M2 validated: a `after_<phase>` hook + one owned-source enum line, redeployed by git-ext's own `install.sh` and reinstall-survival-tested (FR-013, `extensions/git/test/run.sh` §3). `complete` is *already* in the enum (only `testing` is new). It keeps ownership clean — no extension patches another's installed tree.
- **Alternatives considered.** (a) Edit the *installed* `commit.sh`/`extension.yml` copy — rejected: silently wiped on the next git-ext reinstall (D57/S4, the M2 live bug R1-S17). (b) Give the testing extension its own commit logic — rejected: duplicates the git-ext primitive and splits the phase-commit lifecycle across two owners.

## D-R2 — Completion authorship: a thin `/speckit-complete` command

- **Decision.** A **thin `/speckit-complete` command** (testing extension) that runs in `main` and has the **orchestrator (Opus) author** `completion-report.md`. No new model role (FR-001).
- **Rationale.** M5's `after_complete` D19 phase-event push (FR-005) and the `complete(<id>)` phase-tagged commit (FR-012) each need a **hook point**, and a hook fires on a **command boundary**. The git extension already has `after_implement` but **no `after_complete`**, and the `complete` phase has no command to hang one on. A thin command supplies that boundary now → M5 is plumbing, and the complete-commit path 002 deferred closes. The phase still runs in `main` (artifact-layout §2 unchanged).
- **Alternatives considered.** Orchestrator-inline authorship with no command — rejected: leaves M5's push and FR-012's commit with **no boundary to hook**, reproducing the exact gap 002 deferred to M4.

## D-R3 — I-17 fix: mechanical checkbox-delta classification (classify the diff, not the committer)

- **Decision.** `verify-gate.sh` gains, for the **workforce gate's `tasks.md` only**, a read-only branch: on a freshness failure (SHA mismatch or dirty tree), compute the full delta from the recorded-SHA `tasks.md` to the current working-tree `tasks.md` and **PASS iff every changed line is a pure GFM checkbox flip** (`- [ ]` → `- [x]`/`- [X]`, line otherwise byte-identical); **BLOCK on any other change**.
- **Rationale.** This refines D68's non-binding "refresh on machinery-**authored** wave commits" lean by classifying the **diff**, not the committer. `commit.sh` is used by every phase, so an authorship check could be spoofed — a human could smuggle a content edit into a wave commit and have authorship bless it. Classifying the diff as checkbox-only is **strictly stronger**: it admits *only* progress-marking and blocks *all* content change, which is exactly the S05/FR-009 invariant made mechanical. It stays **read-only** (no `gates.yml` re-bind — the recorded SHA holds at approval-time and the cumulative checkbox delta keeps classifying clean as more boxes flip), **zero-AI** (a `git diff` + a per-line regex, FR-007), **fail-closed** (unclassifiable/unreachable ⇒ block), and **scoped** (council gate and `assignment.md` keep the strict check).
- **Alternatives considered.** (a) **Authorship-based refresh** (bless staleness whose commits are machinery phase commits) — rejected: spoofable, trusts *who* over *what*. (b) **Re-bind on wave commit** (rewrite `gates.yml` each wave) — rejected: breaks `verify-gate.sh`'s core "changes no git state / never writes `gates.yml`" invariant and needs a writer in the read path. (c) **Exclude the checkbox column from the binding** — rejected: a structural change to *what* is bound, and it stops catching a content edit that also flips a box. (d) **Grandfather like 003** — rejected: undercuts the SC-010 exit test; M4 is *not* a meta-feature w.r.t. this machinery (003 built it, live), so the honest move is fix-first.

## D-R4 — Two contract files, not one

- **Decision.** Two separate `docs/contracts/` schemas: `completion-report.md` and `testing-doc.md`.
- **Rationale.** Matches the one-schema-per-file convention of the seven existing `docs/contracts/` siblings; each artifact gets its own named contract, so the §3 resumability mapping ("validates against its contract") points at a file, not a section. The coupling (testing reads the completion report) is a one-line pointer, not a reason to co-locate.
- **Alternatives considered.** One combined `tail-artifacts.md` with two sections — rejected for convention consistency + independent validation; noted as the council's to prefer if it disagrees (D46 rule 3 — a format choice).

## D-R5 — Machine-readable status via YAML frontmatter

- **Decision.** `completion-report.md` carries YAML frontmatter `status: success|partial|failed`; `testing.md` carries `executed: none`.
- **Rationale.** Frontmatter is **derivable without reading prose** (FR-003), so the completion report's `status` **is** the D19 `phase.completed` event `status` (trace-schema §6) and aligns to the trace `outcome` vocabulary (§1). `executed: none` makes the doc-only boundary **legible in the document itself** (FR-010). Both are trivially machine-parseable for the resumability validator.
- **Alternatives considered.** A prose status line ("Status: success") — rejected: not cleanly machine-parseable, invites drift between prose and the D19 payload.

## D-R6 — I-16 bootstrap-escape is out of scope

- **Decision.** No I-16 bootstrap-escape ships with M4.
- **Rationale.** I-16 is the *meta-feature circularity* (a feature building the binding machinery cannot bind its own gate). M4 does not build that machinery — 003 shipped it and it is live — so M4's `after_workforce_approve` binds `tasks.md` + `assignment.md` normally. An escape would be unused code. (The spec left it optional, "a plan call"; this is the call.)
- **Alternatives considered.** Ride an I-16 escape along "while we're here" — rejected: no live need on M4, and speculative machinery violates evidence-based restraint.

## D-R7 — The tester is grant-free (D67 tripwire clear)

- **Decision.** The `tester` assembly declares **no elevated grants** (`elevated_grants: []`).
- **Rationale.** A doc-only tester reads two files (`completion-report.md`, `spec.md`) and writes one (`testing.md`) — the base core toolset (`Read, Write, Edit, Bash, Glob, Grep`) suffices; there is no network reach. So the D67 grant tripwire is **clear**, and `gates.workforce.mode: auto` *would* be permissible — but the profile keeps `human` (D68) to exercise the first machine-bound workforce gate.
- **Alternatives considered.** Grant the tester `web_search` (e.g. to check upstream test frameworks) — rejected: out of the doc-only v1 boundary (I-3); the tester grounds on the completion report + spec, not the live web.
