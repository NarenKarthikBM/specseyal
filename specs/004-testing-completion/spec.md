# Feature Specification: The Testing Agent & the Finalized Completion Report

**Feature Branch**: `004-testing-completion`

**Created**: 2026-07-12

**Status**: Draft

**Input**: User description: "M4 — speckit-ext-testing: the doc-only testing agent (creates a testing doc, does not run tests) + the completion-report format finalized so M5 can bind it as a D19 phase-event payload. Built through the pipeline; the first fully-unassisted run. Owner positions encoded."

> **Reading note.** This feature is Milestone 4 (docs/00 §4.1 `speckit-ext-testing`; docs/05 M4) — the **last pipeline extension before Checkpoint α** (the whole notebook pipeline running CLI-only). It delivers two things the pipeline's tail has been producing *ad hoc* across 001/002/003: a **doc-only testing agent** (the `testing` phase) and a **finalized completion-report format** (the `complete` phase's artifact, pinned as a contract). Its "users" are the engineer driving the SDD pipeline and the human who reads the testing doc and signs the gates. The requirements describe **observable behavior and the artifacts produced** (`completion-report.md` in its finalized format; `testing.md`); the *how* — the command topology, the exact section grammar, the git hook wiring — is deferred to `/speckit-plan`.
>
> Decisions already ratified in `docs/90` and the M0 contracts appear under **Constraints & Assumptions** as givens citing their D-row (D46 spec-hygiene rule), not open choices: the two phase-table rows already exist (`artifact-layout.md` §2), the D19 envelope is already defined (`trace-schema.md` §6), and `role: tester` is already a Sonnet role in the trace enum (§2). This is a dogfood build of a *designed* tail, not greenfield.
>
> Like `003` and unlike `002`, this extension **does AI work at runtime**: the `testing` phase is a model session (Sonnet, D18), so subscription/model policy (D28/D18) governs both its build *and* its runtime. The `complete` phase is **not** a new AI role — it runs in the main thread (the Opus orchestrator), so the extension adds exactly **one** net-new model role: the Sonnet `tester`.
>
> **The testing agent PRODUCES a document; it does not EXECUTE tests** (docs/00 line 37: "a testing agent produces the doc now; runs tests later"). Running tests, pass/fail results, and a remediation feedback loop are **testing-agent v2** (I-3), explicitly out of scope. That boundary is a first-class requirement, not a limitation to hide.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Every pipeline run ends with a completion report in a finalized, validated format (Priority: P1)

After `/speckit-implement-parallel` finishes the last wave, the `complete` phase (main session) reads `tasks.md` + `implement.log.md` and writes `completion-report.md` in a **finalized, normative format**: a machine-readable overall status plus the fixed core section set. Because the format is now a contract, the report **validates** (resumability rule) — an absent or malformed report leaves the `complete` phase incomplete, and the pipeline stops there. Because the format is finalized to be the D19 `complete`-event body, M5 can bind it as a phase-event payload with zero rework.

**Why this priority**: The completion report is the testing agent's only input (US2 reads it) *and* the M5 phase-event payload — it is the foundational half of the tail. Finalizing its format is the deliverable docs/05 M4 names ("completion report format finalized — it becomes a phase-event payload in M5").

**Independent Test**: Run the `complete` phase against a real `tasks.md` + `implement.log.md` → a `completion-report.md` that validates against its contract: a machine-readable status ∈ {success, partial, failed} and every required core section present.

**Acceptance Scenarios**:

1. **Given** a finished implement phase with `tasks.md` (all tasks `[X]`) and an `implement.log.md`, **When** the `complete` phase runs, **Then** `completion-report.md` is written with a machine-readable status and the fixed core sections, and it validates against the completion-report contract.
2. **Given** an implement phase that ended with a failed or partial task, **When** the `complete` phase runs, **Then** the report's machine-readable status is `failed` / `partial` accordingly (never silently `success`), and the Partial/Degraded and Failed sections carry the detail.
3. **Given** a validated `completion-report.md`, **When** M5's D19 `phase.completed` envelope (`trace-schema.md` §6) is constructed for the `complete` phase, **Then** the report *is* the `artifact.body` — no reshaping — and re-sending the event is idempotent on `artifact.sha256`.

---

### User Story 2 - The doc-only testing agent produces a testing doc from the completion report + spec (Priority: P1)

The engineer runs the testing agent. It runs in a **separate session** (context hygiene), reads `completion-report.md` + `spec.md`, and writes `testing.md`: a test plan / coverage assessment / manual-verification steps that **maps every Success Criterion in `spec.md` to how it would be verified**, grounded in the completion report's Integration-status claims, and surfaces any SC with no evident coverage as a **gap**. It **asserts** what should be tested and how; it **does not execute** anything — `testing.md` records `executed: none`, and the doc-only boundary is legible in the document itself.

**Why this priority**: This is the headline deliverable — the extension is named for it (`speckit-ext-testing`) — and it completes the pipeline through to a testing doc, the last step before Checkpoint α. It is independently viable against any conforming completion report.

**Independent Test**: With a validated `completion-report.md` + a `spec.md`, run the testing phase → a `testing.md` that validates against its contract, maps 100% of the spec's SCs to a verification approach, marks `executed: none`, and returns only `testing.md` to the main thread.

**Acceptance Scenarios**:

1. **Given** a `completion-report.md` + a `spec.md` with N Success Criteria, **When** the testing agent runs, **Then** `testing.md` contains a verification approach for each of the N SCs and flags any SC the completion report does not evidence as a coverage gap.
2. **Given** the testing agent runs, **When** it produces `testing.md`, **Then** the document states `executed: none` and legibly separates what it verified-by-reading from what a future v2 would execute — it runs no test and reports no pass/fail of its own (I-3).
3. **Given** the testing phase is a separate session, **When** it completes, **Then** only `testing.md` crosses back to the main thread (no completion-report or spec body is re-imported — context hygiene) and exactly one trace record (`role: tester`, model Sonnet) is appended.
4. **Given** a completion report that already evidences tests run during implement, **When** the testing agent writes `testing.md`, **Then** it cites those as **existing** evidence, never as its own execution.

---

### User Story 3 - The complete and testing phases each leave a phase-tagged commit (Priority: P2)

Each new phase boundary produces a phase-tagged git commit, exactly as every earlier phase does (D25) — the `complete`-phase commit path that `002` explicitly deferred to M4, plus a new `testing`-phase commit. Where this requires the git extension to learn the `testing` phase, that edit lives in the git extension's **own source** and survives reinstall.

**Why this priority**: It closes the last gap in the per-feature git lifecycle (FR-003, carried from `002`), so a full pipeline run is phase-tagged end to end and the completion anchor still enumerates cleanly. It matters, but the tail is already valuable (US1 + US2) even before the commit wiring is automated.

**Independent Test**: Run the `complete` and `testing` phases → `git log` shows a `complete(<id>)` and a `testing(<id>)` phase-tagged commit; a git-extension reinstall (plus a foreign-extension reinstall) leaves the `testing`-phase commit path still firing.

**Acceptance Scenarios**:

1. **Given** the `complete` phase writes `completion-report.md`, **When** its boundary is reached, **Then** a `complete(<id>)`-tagged commit lands (D25/FR-006 grammar).
2. **Given** the `testing` phase writes `testing.md`, **When** its boundary is reached, **Then** a `testing(<id>)`-tagged commit lands — and the git extension recognizes `testing` as a valid phase.
3. **Given** the git-ext change that teaches it `testing`, **When** the git extension (and a foreign extension) is reinstalled, **Then** the seam still fires — the edit lives in git-ext's own source, reinstall-survival-tested (artifact-layout §9).

---

### Edge Cases

- **Partial / failed implement** → the completion report's machine-readable status is `partial` / `failed` (not `success`), and the report is still produced and validates; the testing agent still runs, grounding its coverage assessment on whatever Integration-status the report carries.
- **`completion-report.md` missing or invalid** → the `testing` phase cannot run (its context-in is the completion report); by the resumability rule the pipeline stops at `complete` until a conforming report exists (no fabricated input).
- **A spec Success Criterion with no evident coverage in the completion report** → `testing.md` surfaces it as an explicit **gap**, never a fabricated "covered" — the honesty ethos of the reduced-grounding flag (001-FR-019) and graph-vs-assertion labeling (I-13).
- **The testing agent tempted to execute** → forbidden in v1; it records `executed: none`. Tests already run during implement are cited as existing evidence, not re-run (I-3).
- **The dogfood milestone-close overlay** (M4's own report carries an "M4 done-when" / findings / carried-items appendix) → permitted as an **optional appendix outside** the validated core; the contract validates the core, not the overlay (a generic, non-dogfood feature has no milestone to close).
- **The git extension does not yet know `testing`** → the `testing`-phase commit fails until git-ext learns it; teaching it via an edit to the *installed copy* would be silently wiped on the next reinstall (D57/S4) — so the edit must live in git-ext's own source and be reinstall-survival-tested.

## Requirements *(mandatory)*

### Functional Requirements

**Completion phase & finalized format** (the `complete` phase; `completion-report.md`)

- **FR-001**: The `complete` phase MUST run in the **main** session, read `tasks.md` + `implement.log.md`, and write `completion-report.md` and no other artifact (artifact-layout §2/§6, principle 1). It adds no new model role — the main-thread orchestrator authors it.
- **FR-002**: `completion-report.md` MUST conform to a **normative contract** (a `docs/contracts/` schema, this feature's deliverable) so that it *validates* under the resumability rule (artifact-layout §3) — a malformed report leaves the `complete` phase incomplete.
- **FR-003**: The finalized format MUST carry a **machine-readable overall status** ∈ {`success`, `partial`, `failed`}, aligned to `trace-schema.md` §1 `outcome` and the D19 `status` field, derivable without reading prose.
- **FR-004**: The **normative per-feature core** MUST be exactly: the machine-readable status; an *Implementation Complete* summary (waves run + roster summary); a *Completed (N/N)* record; a *Partial/Degraded* section; a *Failed* section; an *Integration status* section; and a *Key results* section — the section set a generic (non-dogfood) feature needs. The milestone-close / dogfooding material (milestone done-when status, findings adjudicated, deferred/carried, next steps, decision-log) MUST be an **optional appendix outside the validated core**.
- **FR-005**: The completion report MUST be usable **as-is** as the `artifact.body` of the `complete`-phase `phase.completed` D19 event (`trace-schema.md` §6) — the format is finalized to be that payload. Building the M5 MCP push is **out of scope** (M5); this feature only makes the body well-formed and replayable (the event is idempotent on `artifact.sha256`).

**Testing phase & doc-only agent** (the `testing` phase; `testing.md`)

- **FR-006**: The `testing` phase MUST run as a **separate session** (session-boundary rule / context hygiene), read `completion-report.md` + `spec.md`, and write `testing.md` and no other artifact (artifact-layout §2, principle 1/2).
- **FR-007**: `testing.md` MUST conform to a **normative contract** (a `docs/contracts/` schema, this feature's deliverable) so that it *validates* under the resumability rule.
- **FR-008**: `testing.md` MUST map **every** Success Criterion in `spec.md` to a verification approach (how it would be checked), grounded in the completion report's Integration-status claims, and MUST surface any SC with no evident coverage as an explicit **gap** — never a fabricated "covered".
- **FR-009**: The testing agent MUST NOT **execute** tests — no test runs, no pass/fail results of its own, no remediation feedback loop (that is v2, I-3). It records `executed: none`; where the completion report already evidences tests run during implement, it cites them as **existing** evidence.
- **FR-010**: The doc-only boundary MUST be **legible in `testing.md`** — the document states what it verified-by-reading versus what a future v2 would execute (the honesty ethos of 001-FR-019 and I-13).
- **FR-011**: The `testing` session MUST run at `role: tester`, model **Sonnet** (D18; `trace-schema.md` §2), append exactly one trace record (principle 4), and return only `testing.md` to the main thread (status-only, principle 2).

**Git lifecycle** (the phase-commit seam)

- **FR-012**: The `complete` and `testing` phases MUST each leave a **phase-tagged commit** at their boundary (D25) — the completion-phase commit path `002` deferred to M4, plus a new `testing`-phase commit.
- **FR-013**: Any change teaching the git extension the `testing` phase (or wiring the complete/testing commit path) MUST land in the **git extension's own source** and be **reinstall-survival-tested** — never an edit to an installed copy (artifact-layout §9 / D57: prefer a hook point S1; an unavoidable source edit lives in the owning extension's source S2 + is reinstall-survival-tested S3).

### Key Entities

- **Completion report (`completion-report.md`)** — the `complete` phase's sole output; the finalized-format record of the implement phase's outcome and the D19 `complete`-event body. Carries a machine-readable status + the fixed core sections; an optional dogfood appendix rides outside the validated core.
- **Testing doc (`testing.md`)** — the `testing` phase's sole output; a **doc-only** test plan / coverage assessment / manual-verification steps mapping every spec Success Criterion to a verification approach; records `executed: none`.
- **Completion-report contract / Testing-doc contract** (`docs/contracts/`) — the normative section schemas the two artifacts validate against (resumability). Whether these are two files or one combined contract is a **plan-level format choice** (D46 rule 3); both artifacts MUST have a contract they validate against.
- **D19 `phase.completed` envelope** (`trace-schema.md` §6) — the already-defined generic event whose `complete`-phase `artifact.body` is the completion report. M4 makes the body conform; it does **not** build the M5 push.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `completion-report.md` validates against its contract — a valid machine-readable status ∈ {success, partial, failed} plus 100% of the required core sections present.
- **SC-002**: `testing.md` validates against its contract.
- **SC-003**: The `testing` phase runs in a **separate session** and returns only `testing.md` to the main thread — no completion-report or spec body is re-imported (context hygiene held).
- **SC-004**: `testing.md` maps **100%** of the spec's Success Criteria to a verification approach; every SC lacking evident coverage is flagged as a gap; `executed: none` is recorded.
- **SC-005**: The completion report carries a machine-readable status and **exactly** the core section set the D19 `complete`-event body needs; a dogfood overlay, if present, is outside the validated core (the contract passes with or without it).
- **SC-006**: Both the `complete` and `testing` phases leave a phase-tagged commit (`git log` shows the `complete(<id>)` and `testing(<id>)` boundaries).
- **SC-007**: The extension adds **exactly one** net-new AI role (the Sonnet `tester`); the `complete` phase adds no model call beyond the main orchestrator; no `ANTHROPIC_API_KEY` is set or relied on anywhere (D28).
- **SC-008**: The git-ext `testing`-phase seam **survives reinstall** — the commit path still fires after a git-ext reinstall (and a foreign-extension reinstall), per artifact-layout §9/S3.
- **SC-009** (**M4 exit**): M4's **own** run ends with **both** a validated `completion-report.md` **and** a validated `testing.md` (docs/05 M4 done-when — "every pipeline run ends with a completion report + testing doc"), each phase-tagged-committed.

## Constraints & Assumptions

Every entry is a ratified given — a `docs/90` D-row or an M0 contract — per the D46 spec-hygiene rule, not an open choice.

- **The two phase-table rows already exist** (`artifact-layout.md` §2): `complete` — main session, context-in `tasks.md` + `implement.log.md`, artifact-out `completion-report.md`; `testing` — separate session, context-in `completion-report.md` + `spec.md`, artifact-out `testing.md`. This feature **implements** those rows; it does not redefine them.
- **Resumability governs validity** (D32, artifact-layout §3): a phase completes iff its artifact-out exists **and** validates against its contract — so **both** artifacts need a contract, and authoring those contracts is this feature's format-finalization deliverable (docs/05 M4).
- **The D19 envelope is already defined** (`trace-schema.md` §6, D19/D35): the completion report is the `complete`-event `artifact.body`; M4 makes the body conform, and does **not** build the M5 MCP push (M5 scope).
- **`role: tester` is a Sonnet role** (D18, `trace-schema.md` §2): the testing agent is a mechanical/generative role — Sonnet, not Opus.
- **Doc-only v1** (docs/00 §4.1 + line 37; I-3): the testing agent produces the doc now and **runs tests later** — executing tests, pass/fail results, and remediation feedback are v2, out of scope.
- **Phase commits** (D25; FR-003 carried from `002` to M4): both new phases commit; teaching the git extension the `testing` phase is an **owned-source** edit, reinstall-survival-tested (D57 / artifact-layout §9).
- **Not a meta-feature** (artifact-layout §7): the testing/completion phases never touch the council `opinions/` subtree, so this feature carries **no** rule-5 exemption marker (confirmed in the quality checklist).
- **`profile.yaml` — `council_tier: standard`** (D61): M4 is **S-sized and not architecture-changing**, so the cost-controlled standard tier applies (`full` is recommended only for L-sized/architecture-changing features); its plan's council review is measured against the baselines.
- **`profile.yaml` — both gates `human`** (D33): `gates.council.mode: human` and `gates.workforce.mode: human` (the explicit safest profile). **The D67 grant tripwire is armed:** M4's roster is expected to be **grant-free** (a doc-only testing agent reads two files and writes one — core toolset only, no `web_search`/no network), so the tripwire is **clear**. Standalone `gates.workforce.mode: auto` would be *permissible* (P4/D67, resolving I-19), but this run keeps `human` deliberately so it exercises the **first machine-written, machine-bound workforce gate** (003's was hand-written + grandfathered; the binding machinery 003 shipped now governs a feature for the first time). Were any assembled agent ever to carry an elevated grant, the tripwire would force the gate to `human` regardless of profile (D67).
- **Model policy & subscription** (D18/D28): the `tester` runs Sonnet on the Claude subscription; no `ANTHROPIC_API_KEY`.
- **Contracts are the finalization vehicle** (D46 rule 3): the completion-report and testing-doc formats are finalized as `docs/contracts/` schema(s); one-file-versus-two is a plan-level choice, but both artifacts MUST validate against a contract.

## OPEN — flagged for spec review; the owner rules at the gate (deliberately **not** silently resolved)

- **I-17 — M4's own implement depends on a git-ext workforce-freshness fix.** `[X]`-marking a task during implement stales the workforce binding (a **general** git-ext defect: `verify-gate` is working-tree-aware, so the first per-wave `[X]` mark on `tasks.md` makes the binding stale and the per-wave re-verify hard-blocks wave 2+). **M4 is the first feature to run its OWN implement under the live workforce machinery WITHOUT the `003` grandfather** — I-16 was `003`-only (a feature *building* the binding cannot bind its own gate; M4 does not build the binding, so its gate binds normally). Therefore **I-17 will bite M4's implement phase** unless dispositioned. It is booked as a git-ext follow-up (owner ruling, M3 close), but M4's own run hits it, so the sequencing is an **owner decision at spec review**, not something to compensate for silently downstream:
  - **(a) Fix I-17 in-scope** as a git-ext **owned-source** edit, bundled with M4's own `testing`-phase git-ext edit (M4 already opens git-ext source per D57/S2 for FR-013) — one reinstall-survival pass covers both.
  - **(b) A separate git-ext prerequisite feature** built before M4's implement.
  - **(c) Grandfather M4's run once more** (defer the fix), accepting a hand-managed implement for M4 alone.
  - *This is genuinely a plan/gate decision; the spec surfaces it, the owner rules. (If (a), the git-ext workforce-freshness fix — and likely a bootstrap-escape for I-16 — enters this feature's scope, adding a git-ext source deliverable beside the testing extension.)*

- **The git-ext seam mechanism** (an `after_testing` hook + `testing` added to `commit.sh`'s phase enum, **versus** the complete/testing skill calling `commit.sh` directly as `implement-parallel` does) — a **plan/council** design point, not a `/speckit-clarify` target.

- **Completion authorship topology** (a thin `/speckit-complete` command versus orchestrator-inline authorship in the main session) — plan-level; the phase runs in `main` either way (artifact-layout §2).
