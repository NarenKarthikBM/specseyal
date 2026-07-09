# Feature Specification: speckit-ext-git — Per-Feature Git Lifecycle

**Feature Branch**: `002-speckit-ext-git`

**Created**: 2026-07-09

**Status**: Draft

**Input**: User description: "speckit-ext-git: automate the per-feature git lifecycle M0/M1 did by hand — branch (named from the spec ID) at a defined birth moment, a phase-tagged commit at every phase boundary, gate approvals bound to the commit SHA they approved, and completion cleanup that preserves the phase trail. Plus a timeboxed worktrees-per-wave spike (I-4). Mechanical git only, zero AI. Per D25."

> **Reading note.** This feature is a pipeline extension — developer tooling — so its "user" is the engineer driving the SDD pipeline. The requirements below describe the extension's **observable git behavior and the refs/commits/records it produces**; the *how* (exact git commands, hook wiring, message grammar) is deferred to `/speckit-plan`. Decisions already ratified in `docs/90` (D25, D32, D35, D45, D46) and the M0/M1 contracts (`artifact-layout.md` incl. the new §8, `decision-record.md`) appear under **Constraints & Assumptions** as givens citing their D-row, not open choices — this is a dogfood build of a designed component (D25), not greenfield. The extension does **zero AI work**: it is mechanical git, so subscription/model policy (D28/D18) governs its *build*, not its *runtime*.

> **Positions taken.** The description named four contested points and required the spec to commit to a stance rather than defer them. Each is resolved in Functional Requirements with its rationale and rejected alternative: **branch birth moment** (FR-001), **cleanup/merge policy** (FR-011), **gate-approval↔commit-SHA binding** (FR-008/FR-009), **commit granularity** (FR-005/FR-006). Two of these refine an existing contract or decision and are flagged for ratification at the gate: FR-001 refines `artifact-layout.md` §2's phase ordering; FR-011 standardizes a merge policy D25 left open.

## Clarifications

### Session 2026-07-09

- Q: When an artifact is edited after its gate approval, how is the now-stale approval treated? → A: **Hard-block** — a recorded approval SHA that no longer matches the artifact's current SHA does not authorize the dependent phase; the engineer must re-run the gate on the new content (FR-009). An explicit override would defeat the binding; auto-reopen overlaps the automated-reopen deliberately deferred out of v1 council scope (D11/FR-017 of `001`).
- Q: How is completion cleanup (trail-preserving integration + branch retirement) triggered? → A: **Explicit, engineer-invoked step** — a dedicated pipeline command performs the merge and retires the branch; never automatic, because retiring a branch is consequential (FR-011). "Zero manual git" (US1) still holds: the engineer runs a *pipeline* command, not raw `git`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The feature's git lifecycle runs itself, with zero manual git (Priority: P1)

An engineer runs the pipeline (`/speckit-specify` → `plan` → `tasks` → `implement` → completion). Without ever typing a `git` command, the feature gets its own branch — named exactly for the spec ID — at the moment the feature is born, and a phase-tagged commit lands at every phase boundary as the durable, resumable checkpoint. The mechanical branch-and-commit discipline that M0 and M1 performed by hand is now automatic.

**Why this priority**: This is the reason the extension exists and is precisely the M2 exit condition (docs/05 M2: "a full pipeline run happens on an auto-created branch with phase-tagged commits"). Every other story builds on the branch existing and the phase commits landing. It is also the story that finally retires the hand-made feature branch — the manual step this very feature's build exercises one last time.

**Independent Test**: Drive a feature from specify through at least one later phase; verify (a) a git branch whose name equals the spec ID (`NNN-slug`) exists and is checked out, (b) `spec.md` and every subsequent phase artifact are committed on that branch and **not** on the base branch, and (c) each completed phase boundary has exactly one phase-tagged commit whose message names the phase and the spec ID.

**Acceptance Scenarios**:

1. **Given** a base branch and a new feature description, **When** `/speckit-specify` runs, **Then** a feature branch named identically to the assigned spec ID is created and checked out before `spec.md` is committed, and `spec.md` lands on the feature branch while the base branch stays unchanged.
2. **Given** a feature branch mid-pipeline, **When** a phase (e.g. `plan`) completes, **Then** exactly one phase-tagged commit is made at that boundary with a conventional message (`<phase>(<spec-id>): <summary>`).
3. **Given** a phase is re-run after interruption, **When** the branch already exists and the boundary is already committed, **Then** the extension switches to the existing branch and does not duplicate the branch or the commit (idempotent).

---

### User Story 2 - Implementation is resumable at wave granularity (Priority: P1)

During `/speckit-implement-parallel`, work proceeds in dependency-ordered waves. Each completed wave is committed as its own cold-resumable checkpoint, so an interrupted implementation resumes at the first uncommitted wave with nothing duplicated and nothing lost.

**Why this priority**: `implement` is the longest, most parallel, and most interruption-prone phase; wave-granular commits are what make principle 3 (resumability) real *inside* a phase rather than only at its edges. M1 already committed per wave by hand (`impl(001) wave K/8: …`) — this story makes that automatic and is P1 because a phase-only checkpoint would force re-running an entire multi-wave implementation after any interruption.

**Independent Test**: Run an implementation of N≥3 waves, interrupt after wave 2, and resume; verify each completed wave is its own commit tagged `impl(<spec-id>) wave K/N`, that resumption begins at wave 3, and that no wave-1/2 work is redone or lost.

**Acceptance Scenarios**:

1. **Given** an implementation in progress, **When** a wave completes, **Then** a per-wave commit is made (`impl(<spec-id>) wave K/N: …`) in addition to the phase-boundary commit at implement's end.
2. **Given** an implementation interrupted mid-run, **When** it resumes, **Then** the first uncommitted wave is the restart point and already-committed waves are left untouched.

---

### User Story 3 - A gate approval is provably about a specific, unchanged artifact (Priority: P2)

When the engineer approves at a gate — the council gate on `plan.md`, or the workforce gate on the roster — the approval records the exact commit SHA of the artifact it approved. If that artifact is later edited, the recorded SHA no longer matches the artifact's current state, the mismatch is detectable, and the stale approval does not silently authorize the work downstream of it.

**Why this priority**: An approval that floats free of the content it approved is worthless — it is the difference between "the human approved *this plan*" and "the human approved *a* plan that has since changed." Binding the approval to an immutable SHA closes that hole. It is P2 rather than P1 because the pipeline runs without it (M1 had no binding); it is an integrity upgrade the git extension is uniquely placed to provide, since only it holds the commit graph.

**Independent Test**: Approve `plan.md` at commit `S1`; edit `plan.md` and commit `S2`; verify the gate record names `S1`, that the `S1`≠current-SHA mismatch is surfaced, and that the phase gated by that approval (`/speckit-tasks`) refuses to proceed as approved until re-approval.

**Acceptance Scenarios**:

1. **Given** a human approves the council gate, **When** the approval is recorded, **Then** the `## Human Gate` section names `plan.md @ <sha>` (and the decision record's own SHA), binding the approval to that immutable plan state.
2. **Given** a workforce-gate approval, **When** it is recorded, **Then** the `## Workforce Gate` section (artifact-layout §8) names `tasks.md @ <sha>` and `assignment.md @ <sha>`.
3. **Given** an approved artifact edited after approval, **When** the dependent phase starts, **Then** the extension detects the approved-SHA↔current-SHA mismatch and the stale approval does not authorize that phase.

---

### User Story 4 - On completion, the feature integrates with its full phase trail preserved, and the branch is retired (Priority: P2)

When a feature is complete and the engineer invokes cleanup, its work is integrated into the base branch in a way that keeps **every** phase-tagged commit individually visible (no squashing that collapses the phase history), and the now-redundant feature branch pointer is removed. The feature's `specs/NNN/` tree and its whole commit trail remain reachable in the base branch afterward.

**Why this priority**: The phase-tagged trail is the observability spine of a feature (D25 asks explicitly to preserve it); squashing at merge would erase exactly the per-phase record the pipeline spent the whole feature building. Retiring the branch keeps the branch namespace clean. It is P2 because a feature delivers its value before cleanup (M1's completion merge was done by hand this session), but cleanup must not betray the trail.

**Independent Test**: Complete a feature and integrate it; verify every phase-tagged commit of that feature is individually reachable from the base branch tip (count preserved, none squashed), the feature branch ref no longer exists, and `specs/NNN/` is fully present on the base branch.

**Acceptance Scenarios**:

1. **Given** a completed feature branch, **When** it is integrated, **Then** all of its phase-tagged commits remain individually present in the base branch history (no squash, no phase-collapsing rewrite).
2. **Given** the feature has been integrated, **When** cleanup finishes, **Then** the feature branch ref is deleted while its commits and `specs/NNN/` tree persist on the base branch.

---

### User Story 5 - Timeboxed spike: does a worktree-per-wave improve parallel isolation? (Priority: P3)

As a bounded experiment — **not** a shipped v1 behavior — the build evaluates whether giving each parallel implementation wave its own git worktree improves isolation between concurrent subagents, merging per wave. The spike is timeboxed; whatever the result, its finding and an adopt-later/abandon recommendation are recorded in the log.

**Why this priority**: I-4 is a promising idea but unproven and explicitly *not* committed scope (D25: "worktrees-per-wave = timeboxed spike, not committed scope"). It is P3 and firewalled from the v1 loop: no P1/P2 behavior may depend on it. Its deliverable is knowledge, not a feature.

**Independent Test**: Confirm the spike ran within its timebox and produced a written outcome (what was tried, what happened, adopt-later vs abandon) in the implementation log / a decision row — and that removing the spike entirely leaves US1–US4 fully functional.

**Acceptance Scenarios**:

1. **Given** the spike's timebox, **When** it concludes (success or abandonment), **Then** a recorded outcome with a recommendation exists, and no v1 requirement references worktrees.

---

### Edge Cases

- **Base branch advanced before completion** — if other work landed on the base branch since the feature was cut, a fast-forward integration is impossible; the trail-preserving merge (FR-011) still applies via a merge-commit, never a squash or a history-collapsing rebase. A textual conflict **aborts and is surfaced for manual resolution** — the extension never auto-resolves (no silent loss).
- **Branch already exists on (re-)specify** — the extension switches to it and continues rather than erroring or creating a divergent second branch (idempotent, FR-012).
- **A phase produces no artifact change** — a boundary with nothing to commit makes no empty commit; the absence of a commit is itself the true resumable state (D32: state is inferred from artifacts, not forced).
- **Approved artifact edited after approval** — the stale approval is detected via SHA mismatch and does not authorize the dependent phase until re-approval (FR-009).
- **`gates.*.mode: auto`** — an auto-written gate section still records the approved SHA; autonomy changes *who signs*, never *whether the approval is bound to content* (D9, D32).
- **Feature abandoned before completion** — retiring an abandoned branch is a manual/explicit act; the extension never deletes a branch that has not been integrated (no silent loss of work).
- **`.specify/feature.json` points at a different feature than the checked-out branch** — downstream phase resolution follows `feature.json` (D45), not the branch name; the extension must not couple them (FR-013).
- **Commit convention drift** — a boundary committed with a non-conforming message is still a valid commit; the convention is a readability contract, not a gate (mirrors the trace "flag, don't rewrite" ethos, D18).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** *(branch birth moment — position taken)*: The extension MUST create the feature branch during the **`specify`** phase — as soon as the spec ID (the `specs/NNN-slug/` directory) is assigned and **before `spec.md` is committed** — so that every feature artifact, `spec.md` included, is committed on the feature branch and the base branch accrues no per-feature spec churn. *Rationale:* this matches M0/M1 manual practice (branch first) and stock spec-kit's `before_specify` hook, and satisfies D25's "branch-before-plan" a fortiori. *Rejected alternative:* a separate branch step after `clarify` (the literal ordering in `artifact-layout.md` §2) would force `spec.md`/`clarify` onto the base branch and then need a retro-commit. **This FR refines `artifact-layout.md` §2's phase ordering (branch becomes co-incident with `specify`, context-in = the assigned spec ID) — flagged for ratification at the gate.**
- **FR-002**: The feature branch name MUST equal the spec ID exactly (`^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$`), identical to the feature directory name under `specs/` (D25). The branch is the sole phase state that lives outside `specs/` (D32).
- **FR-003**: The extension MUST make a **phase-tagged commit at every pipeline phase boundary** that produces or revises an artifact (specify, clarify, plan, council/triage, tasks, categorize, analyze, agent-assign, implement, complete). Each such commit is the durable, resumable checkpoint for that boundary (D32, principle 3).
- **FR-004**: A phase boundary that produced **no** artifact change MUST NOT be forced into an empty commit; the resumable state is inferred from the artifact tree, not from a mandatory commit per phase (D32).
- **FR-005** *(commit granularity — position taken)*: Commit granularity MUST be **phase-boundary commits for all phases, PLUS an additional per-wave commit inside `implement`.** *Rationale:* implement is the long, parallel, interruption-prone phase where sub-phase checkpoints pay for themselves (M1 evidence: it committed `impl(001) wave K/8`). *Rejected alternative:* phase-boundary-only commits would force re-running a whole multi-wave implementation after any mid-phase interruption.
- **FR-006**: Commit messages MUST follow a phase-tagged convention naming the phase and spec ID — `<phase>(<spec-id>): <summary>` for phase boundaries and `impl(<spec-id>) wave K/N: <summary>` for implementation waves (the convention already used across the M1 trail: `spec(...)`, `plan(...)`, `gate(...)`, `impl(...) wave …`, `complete(...)`).
- **FR-007**: The extension MUST perform **only mechanical git operations and no AI/model work**; it therefore appends **no** records of its own to `traces.jsonl` (its operations are not AI sessions — consistent with `artifact-layout.md` §2, where `branch` and the gate rows "run no session and so leave no trace"). It reads and writes no `specs/` artifact except by committing artifacts other phases already wrote.
- **FR-008** *(gate↔SHA binding — position taken)*: At each gate approval, the extension MUST record the immutable commit SHA of every artifact the gate approved into that gate's section: the **council gate** records `plan.md @ <sha>` (extending `decision-record.md`, whose rounds already cite artifacts `@ <sha>` and whose R4 names an applying commit); the **workforce gate** records `tasks.md @ <sha>` and `assignment.md @ <sha>` in its `## Workforce Gate` section (`artifact-layout.md` §8). The binding lives in the gate artifact, never in a state file (D32).
- **FR-009**: Because the approved SHA is recorded, the extension MUST **detect a stale approval** — an approved artifact whose current SHA differs from the recorded approval SHA (it was edited after approval) — surface the mismatch, and **hard-block** the phase gated by that approval: the stale approval does **not** authorize downstream work until the gate is re-run on the new content (clarified 2026-07-09; a warn-and-override was rejected as defeating the binding). *(This is the reason FR-008's binding is worth recording.)*
- **FR-010**: The extension MUST bind an approval to content **regardless of who signs**: under `gates.*.mode: auto` (D9), an auto-written gate section still records the approved SHA. Autonomy changes the signer, not whether the approval is anchored to immutable content (D32).
- **FR-011** *(cleanup/merge policy — position taken)*: On completion, an **explicit, engineer-invoked** cleanup step (a dedicated pipeline command — never automatic, since retiring a branch is consequential; clarified 2026-07-09) MUST integrate the feature into the base branch **preserving every phase-tagged commit individually** (no squash, no phase-collapsing rewrite), then **retire (delete) the feature branch ref** while its commits and `specs/NNN/` tree remain reachable on the base branch. *Position:* the default integration is a **merge-commit (`--no-ff`)** that marks the feature+milestone as a legible integration point uniformly, whether or not the base advanced; a **fast-forward** is the acceptable degenerate case when history is linear (as this session's manual M1→`main` completion used). A textual merge conflict **aborts and is surfaced for manual resolution** — mechanical git never guesses at a merge (no silent loss). *This standardizes a policy D25 left open — flagged for ratification at the gate.*
- **FR-012**: Every git operation the extension performs MUST be **idempotent and resumable**: re-running a phase never duplicates a branch or a boundary commit; the extension derives what to do from the git + artifact state alone (principle 3, D32). Re-invoking `specify` when the branch exists switches to it.
- **FR-013**: The extension MUST **compose without conflict** with the council extension and graphify's `before_*` hooks, and MUST NOT disturb branch-agnostic feature tracking: downstream phases resolve the active feature from `.specify/feature.json` (gitignored, transient), never from the branch name, so git branch and feature tracking stay decoupled (D45).
- **FR-014**: The extension MUST be installable and uninstallable in the manner of the graphify and council extensions (payload under `.specify/extensions/`, hooks registered in `.specify/extensions.yml`), leaving no pre-existing file modified on uninstall except the hook registrations it added.
- **FR-015** *(spike — not committed scope)*: The build MUST include a **timeboxed spike** on worktrees-per-implementation-wave (I-4), executed as its own experiment with a recorded outcome (finding + adopt-later/abandon recommendation) whether it succeeds or is abandoned. No FR-001…FR-014 behavior may depend on the spike's outcome (D25).

### Key Entities

- **Feature branch** — the git branch whose name equals the spec ID; born at `specify` (FR-001), the sole phase-state living outside `specs/` (D32), retired at completion (FR-011).
- **Phase commit** — a phase-tagged commit at a phase boundary; the durable resumable checkpoint (FR-003) with a conventional message (FR-006).
- **Wave commit** — a per-wave commit inside `implement` (FR-005); the sub-phase cold-resume checkpoint.
- **Gate-SHA binding** — the `(approved artifact, commit-SHA)` pair recorded in a gate section (`## Human Gate` / `## Workforce Gate`) that anchors a human approval to immutable content (FR-008) and makes staleness detectable (FR-009).
- **Wave worktree** *(spike only)* — an isolated git worktree per implementation wave, merged per wave; exists only within the I-4 experiment (FR-015), never in the v1 loop.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A full pipeline run completes on an **auto-created branch with phase-tagged commits** — no manual `git` command was needed to create the branch or land any phase-boundary commit. *(The M2 exit condition, docs/05 M2.)*
- **SC-002**: For 100% of features, the branch name equals the spec ID, and the base branch carries **zero** per-feature spec/plan artifacts before the feature is integrated (branch-first isolation, FR-001).
- **SC-003**: Every completed phase boundary that changed an artifact has **exactly one** corresponding phase-tagged commit, and every completed implementation wave has its own commit — verifiable by walking the branch history against the phase/wave sequence.
- **SC-004**: 100% of gate approvals record the SHA of each approved artifact, and a post-approval edit to an approved artifact is detected and blocks the dependent phase until re-approval in 100% of injected-edit tests (FR-008/FR-009).
- **SC-005**: On completion, 100% of the feature's phase-tagged commits remain **individually reachable** from the base-branch tip (zero squashed), and the feature branch ref is removed (FR-011).
- **SC-006**: An implementation interrupted mid-run **resumes at the first uncommitted wave** with no duplicated or lost work (FR-012, FR-005).
- **SC-007**: The extension adds **zero** AI/token cost and **zero** `traces.jsonl` records of its own — verifiable from `traces.jsonl` containing no git-extension session record for a full run (FR-007).
- **SC-008**: The worktrees-per-wave spike produces a **recorded outcome with a recommendation within its timebox**, regardless of result, and removing the spike leaves SC-001…SC-007 unaffected (FR-015).

## Constraints & Assumptions

*Ratified decisions and M0/M1 contracts, treated as givens for this dogfood build. **Standing rule (D46): every entry here cites a D-row; anything that cannot is a design choice and belongs in the plan, not the spec.***

- **Scope — git-ext v1 (D25)**: the committed scope is branch-before-plan, naming from spec ID, phase-tagged commit conventions, and per-feature cleanup. Worktrees-per-wave (I-4) is a **timeboxed spike, not committed scope**. Remote/push/PR automation is **not** in D25's enumerated scope → v1 is **local-git only**.
- **Gate decisions are artifacts (D32)**: SHA bindings (FR-008) are written **into** the gate sections (artifacts), never into a state file or database; phase state — including the branch — stays inferred from artifacts and refs. Adding a state file is forbidden.
- **Traces (D35, artifact-layout §2)**: the extension's git operations are mechanical, not AI sessions, and append **no** trace records — consistent with §2's rule that `branch` and the gate rows run no session and leave no trace.
- **Branch-agnostic feature tracking (D45)**: git branch and feature tracking are **decoupled**; `.specify/feature.json` (gitignored, transient) remains the feature resolver, and the extension must not make any downstream phase depend on the branch name.
- **Contracts are the interface (D4, artifact-layout incl. §8, decision-record)**: the SHA bindings **extend existing artifact fields** — `decision-record.md`'s `@ <sha>` citations and R4's applying-commit, and §8's workforce-gate roster — rather than inventing a sidecar record.
- **AI-free runtime; build follows policy (D25, D28, D18)**: the extension is mechanical git and makes **no** model calls, so runtime billing is moot; its **build** follows subscription-only billing (D28) and the model policy (D18: Sonnet implementers, Opus main thread), like every milestone.
- **Build-phase tracing (D46, D35)**: this feature's own non-council build sessions (specify/clarify/plan/tasks/implement) still write **no** `traces.jsonl` — the tracing capability is wired to council sessions, and per D46 the bootstrap phases are not backfilled. The council phase of *this* feature's plan is the exception: it is the council's **first live run** and produces the first real trace records (M1's exit test).
- **Dogfooding (D45, docs/05 M2)**: M2 is built through the pipeline, and this feature's plan is the council's **first live review** — so this build both exercises the manual feature branch one last time (the step it retires) and supplies the M1 exit measurement.
