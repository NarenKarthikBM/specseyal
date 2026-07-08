# Tasks — 001-council-extension (speckit-ext-council)

> Stock spec-kit checklist format (so `/speckit-analyze` works) + the `## Execution Waves` section
> appended by `/speckit-tasks-graph`. Story labels map to the spec's user stories via the command
> that realizes them: **US1** → `/speckit-council` · **US2** → `/speckit-council-approve` ·
> **US3/US4** → `/speckit-council-triage` · **US5/FR-019** ride inside `/speckit-council`.
>
> **Graph note:** every file is new (`extensions/council/` does not exist), so `[P]` is verified by
> **disjoint new-file sets** — the documented fallback when the graph has no edges for the target
> files (`speckit-tasks-graph` step D). No task mutates an existing file.
>
> Sources live in `extensions/council/`; `install.sh` copies `skills/*` → `.claude/skills/` and
> `extension/` → `.specify/extensions/council/` (the graphify packaging pattern).

## Phase 1 — Setup (shared scaffold)

- [X] T001 Scaffold `extensions/council/` (dir tree) + `install.sh` + `uninstall.sh`, mirroring `extensions/graphify/` — **simpler**: council registers no `before_*` hooks, so drop the PyYAML hook-merge; the installer only copies `extension/` and `skills/*` and (optionally) adds `council` to `.specify/extensions.yml` `installed:`.
- [ ] T002 [P] `extension/extension.yml` (id: council; provides the 3 commands; `hooks: none`) + `extension/README.md`.
- [ ] T003 [P] `extension/council-config.yml` — `member_count: 5`, `member_lenses: [correctness, risk, simplicity, testability, sequencing]`, `models: {chairman: opus, member: sonnet, deck_prep: sonnet}`, `max_rounds: 1` (the member-count trim lever, R2/S3).
- [ ] T004 [P] `extensions/council/README.md` (top-level: what it installs, the flow, requirements).

## Phase 2 — Foundational (blocks all commands)

- [ ] T005 **Token-capture spike (S1 / R1 — timeboxed, ≤1 investigation session).** Determine whether the Claude Code transcript JSONL yields per-subagent token usage. Outcome sets the `capture_method` policy (`transcript` vs `unavailable`). **Spike failure = a D-row + `capture_method: unavailable`, never a blocker** (carried constraint R1-S01). Produces `extensions/council/docs/token-capture-spike.md`.
- [ ] T006 [P] `extension/templates/trace-fragment.md` — the per-session trace fragment format (`trace-schema.md` **1.2**: `skills:[]`, `elevated_grants:[]`, `capture_method`, `cost_usd:null`) + the **orchestrator-serialized append** rule (never a parallel append). Consumes T005's policy.
- [ ] T007 [P] `extension/templates/deck-technical.md` — D15 deck: problem, chosen approach + rejected alternatives, dependency/graph impact, risk register, cost/complexity, testability.
- [ ] T008 [P] `extension/templates/deck-overview.md` — one page: what/why, what could go wrong, cost, "done".
- [ ] T009 [P] `extension/templates/member-prompt.md` — base reviewer + `{{lens}}` slot (FR-003); graphify query-tool instructions (D10); **status-only return** (S2); **lens recorded in opinion metadata** (S4); reduced-grounding note (FR-019).
- [ ] T010 [P] `extension/templates/chairman-prompt.md` — synthesis; classify `blocking`/`strong`/`consider`; stable IDs `R<n>-S<nn>`; delta-check; **reduced-grounding banner** (FR-019).
- [ ] T011 [P] `extension/templates/suggestions.md` — chairman output structure (verdict, classified/ID'd table, reduced-grounding banner slot).

## Phase 3 — User Story 1: `/speckit-council` (Priority: P1) 🎯 MVP  *(also US5, FR-019, FR-017)*

**Goal**: deck prep + one council round → `suggestions.md`. **Independent Test**: run on a fixture `plan.md`; expect deck + `round-1/opinions/**` + a classified `suggestions.md`; only `suggestions.md` returns to the main thread.

- [ ] T012 [US1] `skills/speckit-council/SKILL.md` — the orchestrator: deck-prep (Sonnet) → members stage 1 (5 × Sonnet ∥, lensed) → stage 2 peer review (5 ∥) → chairman (Opus) → `round-N/suggestions.md`; **status-only returns / file-mediated content** (S2, SC-005); reduced-grounding flag (FR-019); serial trace assembly (T006); **`--reopen delta|full`** interface (FR-017, D46).
- [ ] T013 [P] [US1] `extension/commands/speckit.council.md` (provenance stub).

## Phase 4 — User Story 3: `/speckit-council-triage` (Priority: P2)  *(also US4)*

**Goal**: apply accepted suggestions → `plan.md`; write the decision record. **Independent Test**: on a fixture `suggestions.md`, expect every suggestion dispositioned with reasoning, and — if any `blocking` — one revision + a chairman delta check.

- [ ] T014 [US3] `skills/speckit-council-triage/SKILL.md` — reads `suggestions.md` **only**; applies accepted → `plan.md`; writes `decision-record.md` (every disposition; `rejected`/`deferred` ⟹ reasoning, D13.5; accepted `blocking` ⟹ commit-named delta); **one-revision-cycle + chairman-only delta check** (US4, D13); `## Reopen` handling (FR-017); trace.
- [ ] T015 [P] [US3] `extension/commands/speckit.council.triage.md` (provenance stub).

## Phase 5 — User Story 2: `/speckit-council-approve` (Priority: P1)

**Goal**: record the human-gate decision; unlock `/speckit-tasks`. **Independent Test**: on a fixture decision record, `approved` appends a `## Human Gate` section and unlocks tasks; `rejected` returns the plan for one more round.

- [ ] T016 [US2] `skills/speckit-council-approve/SKILL.md` — appends `## Human Gate` (reviewer, decision, reviewed, notes, overrides) to `decision-record.md`; unlocks tasks on `approved*`; `auto` mode (only within `full_auto`) writes the section with `reviewer: auto`. No session → no trace.
- [ ] T017 [P] [US2] `extension/commands/speckit.council.approve.md` (provenance stub).

## Phase 6 — Polish & Validation

- [ ] T018 Install/uninstall verification: idempotent `install.sh` → re-install (no dup) → `uninstall.sh` clean, against a target (mirrors graphify's D31 check).
- [ ] T019 [P] Conformance + quickstart scenarios: `decision-record.md` (SC-003/US3), `traces.jsonl` 1.2 (SC-006), the **SC-005 two-part** check (grep + status-only invariant), reduced-grounding (SC-008), one-revision convergence (SC-004).
- [ ] T020 [P] Finalize `extensions/council/README.md` + `quickstart.md` results, incl. the **SC-002 measurement + `capture_method: unavailable` count** reporting shape (D47).

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries,
> [P] markers, TDD ordering, and disjoint new-file sets (the graph has no council edges yet).
> Setup and Foundational phases are serial barriers; parallelism is cross-story (the 3 commands).

- Wave 1 [serial]   : T001                          # scaffold — the dir tree must exist first
- Wave 2 [serial]   : T002, T003, T004              # rest of Setup (disjoint, but a barrier)
- Wave 3 [serial]   : T005                           # token-capture spike — informs the trace fragment
- Wave 4 [serial]   : T006, T007, T008, T009, T010, T011   # Foundational templates (disjoint) — barrier before stories
- Wave 5 [parallel] : T012 [US1], T014 [US3], T016 [US2]   # the 3 command skills — disjoint skill dirs, cross-story
- Wave 6 [parallel] : T013 [US1], T015 [US3], T017 [US2]   # provenance stubs — disjoint
- Wave 7 [serial]   : T018                           # install/uninstall verification — needs every file
- Wave 8 [parallel] : T019, T020                     # conformance + docs — disjoint

### Task annotations
- T001  files=extensions/council/install.sh,extensions/council/uninstall.sh   deps=-                        mutates=(new)
- T002  files=extensions/council/extension/extension.yml,extensions/council/extension/README.md  deps=T001  mutates=(new)
- T003  files=extensions/council/extension/council-config.yml                  deps=T001                     mutates=(new)
- T004  files=extensions/council/README.md                                     deps=T001                     mutates=(new)
- T005  files=extensions/council/docs/token-capture-spike.md                   deps=T001                     mutates=(new)
- T006  files=extensions/council/extension/templates/trace-fragment.md         deps=T005                     mutates=(new)
- T007  files=extensions/council/extension/templates/deck-technical.md         deps=T001                     mutates=(new)
- T008  files=extensions/council/extension/templates/deck-overview.md          deps=T001                     mutates=(new)
- T009  files=extensions/council/extension/templates/member-prompt.md          deps=T001                     mutates=(new)
- T010  files=extensions/council/extension/templates/chairman-prompt.md        deps=T001                     mutates=(new)
- T011  files=extensions/council/extension/templates/suggestions.md            deps=T001                     mutates=(new)
- T012  files=extensions/council/skills/speckit-council/SKILL.md               deps=T006,T007,T008,T009,T010,T011  mutates=(new)
- T013  files=extensions/council/extension/commands/speckit.council.md         deps=T001                     mutates=(new)
- T014  files=extensions/council/skills/speckit-council-triage/SKILL.md        deps=T006,T011                mutates=(new)
- T015  files=extensions/council/extension/commands/speckit.council.triage.md  deps=T001                     mutates=(new)
- T016  files=extensions/council/skills/speckit-council-approve/SKILL.md       deps=T001                     mutates=(new)
- T017  files=extensions/council/extension/commands/speckit.council.approve.md deps=T001                     mutates=(new)
- T018  files=(verification run; touches .claude/skills/, .specify/extensions.yml at install time)  deps=T012,T013,T014,T015,T016,T017,T002,T003,T004  mutates=(install artifacts, not authored)
- T019  files=specs/001-council-extension/quickstart.md (results)              deps=T018                     mutates=(new run)
- T020  files=extensions/council/README.md,specs/001-council-extension/quickstart.md  deps=T018             mutates=extensions/council/README.md

### Shared-file serialization
- (none among authoring tasks — every `files=` set is disjoint and brand-new.)
- T018 alone touches shared install targets (`.claude/skills/`, `.specify/extensions.yml`) at **install time**; it is a single serial wave, so no co-scheduling hazard.
- T020 re-touches `extensions/council/README.md` (first written by T004) — serialized after all authoring; never co-scheduled with T004.
