# Data Model — 004-testing-completion

Entities are the two finalized artifacts, the I-17 classification mechanism, and the tester assembly. All map onto existing `artifact-layout.md` §2 rows and the resumability rule (§3): a phase completes iff its artifact-out exists **and** validates against its contract.

## CompletionReport — `specs/<id>/completion-report.md`

The `complete` phase's sole output (§2: `complete | main | tasks.md, implement.log.md | completion-report.md`). Finalized format = **frontmatter + normative core + optional appendix**.

| Field / Section | Rule |
|---|---|
| frontmatter `feature` | spec ID, string. |
| frontmatter `phase` | literal `complete`. |
| frontmatter `status` | **∈ {success, partial, failed}** (FR-003). Machine-readable; derivable without prose; aligns to `trace-schema.md` §1 `outcome` and **is** the D19 event `status`. Never silently `success` when a task failed/partialed (US1 scenario 2). |
| `## Implementation Complete — <name>` | waves run + roster summary (FR-004 core). |
| `### Completed (N / N)` | the completed-task record (FR-004 core). |
| `### Partial / Degraded` | detail for any partial/degraded task; empty-but-present when none. |
| `### Failed` | detail for any failed task; empty-but-present when none. |
| `### Integration status` | the claims `testing.md` grounds its coverage on (FR-008). |
| `### Key results` | the headline outcomes (FR-004 core). |
| `## Milestone-close context`, `## Decisions & log` | **optional appendix OUTSIDE the validated core** (FR-004). A generic feature omits it; a dogfood milestone (like M4's own) carries it. |

- **Validation (SC-001/005):** `status` present and valid; **100 %** of the required core sections present; the contract **passes with or without** the appendix.
- **Relationship (FR-005):** the whole file **is** the D19 `phase.completed` `artifact.body` (`trace-schema.md` §6) — no reshaping; the event is idempotent on `artifact.sha256`, its `status` is the frontmatter `status`. M4 makes the body conform; M5 builds the push.
- **Precedent:** finalizes 003's ad-hoc `completion-report.md` structure (graph: `Finalized completion-report contract --references--> 003 Completion Report`).

## TestingDoc — `specs/<id>/testing.md`

The `testing` phase's sole output (§2: `testing | separate | completion-report.md, spec.md | testing.md`). Doc-only.

| Field / Section | Rule |
|---|---|
| frontmatter `feature` | spec ID. |
| frontmatter `phase` | literal `testing`. |
| frontmatter `executed` | literal `none` (FR-009/010) — the doc-only boundary, legible in the doc. |
| `## Coverage map` | one row per item: **every Success Criterion AND every Functional Requirement** in `spec.md` (Clarifications 2026-07-12) → a **verification approach** = the kind of check + how to perform it + what evidence confirms it (manual steps + citations to existing automated tests) + the completion-report grounding + status ∈ {covered, GAP}. |
| gap rows | any SC/FR the completion report does not evidence → **GAP**, never a fabricated "covered" (edge cases; honesty ethos, 001-FR-019 / I-13). |
| `## Verified by reading vs. would-execute in v2` | the honest split (FR-010): what the tester confirmed by reading vs. what v2 would execute. |

- **Validation (SC-002/004):** frontmatter present with `executed: none`; **100 %** of the spec's SCs **and** FRs appear in the coverage map with an approach; uncovered items flagged as gaps.
- **Relationship:** context-in is `completion-report.md` + `spec.md` **only**; returns **status-only** to the main thread (SC-003) — no report/spec body re-imported.

## CheckboxDeltaClassification — the I-17 mechanism (in `verify-gate.sh`)

Not an artifact — a read-only decision inside the workforce freshness check.

| Aspect | Rule |
|---|---|
| Inputs | the recorded `tasks.md` SHA (from `gates.yml` via `gates.sh read workforce`); the current committed + working-tree `tasks.md`. |
| Admissible predicate | **every** changed line in the delta `recorded-SHA → working-tree` is a pure GFM checkbox flip: the line is byte-identical except its task marker advanced `- [ ]` → `- [x]`/`- [X]`. |
| PASS | admissible (checkbox-only progression) — the approved *content* is unchanged; the gate is fresh for the phase. |
| BLOCK | any non-checkbox change (task added/removed, description/dep/ID edited, any other text) **or** an unparseable/unreachable diff — fail-closed (R1-S10 ethos). |
| Invariants | **read-only** (no `gates.yml` write, no git state change); **zero-AI** (git diff + per-line regex, FR-007); **scoped** to `workforce`/`tasks.md` — `agents/assignment.md` and the council gate/`plan.md` keep the strict check. |

- **State:** {pass = admissible staleness, block = content edit / unclassifiable}. The recorded SHA never moves (no re-bind); the cumulative checkbox delta keeps classifying clean across waves.

## TesterAssembly — the `testing` session

| Field | Value |
|---|---|
| `role` | `tester` (`trace-schema.md` §2). |
| `model` | `claude-sonnet-5` (D18 — mechanical/generative role). |
| `agent_id` | `null` (not an `implementer`). |
| `skills` | `[]`. |
| `elevated_grants` | `[]` — core toolset only (D67 tripwire clear). |
| trace | exactly one record (principle 4); `artifact` = `testing.md`; returns status-only. |

## Contract & ownership deltas (the finalization deliverable)

- **New schemas** (`docs/contracts/`): `completion-report.md`, `testing-doc.md` — the normative section contracts both artifacts validate against (resumability, D46 rule 3).
- **`artifact-layout.md` §6 ownership edit:** add rows — `completion-report.md` ← the `complete` phase (`/speckit-complete`, main orchestrator); `testing.md` ← the testing extension (`tester`). (Today §6 lists no writer for either — a contract gap this feature closes.)
- **No new writer of an existing artifact:** principle I holds; each new phase writes exactly one new file.
