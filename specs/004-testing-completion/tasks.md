---
description: "Dependency-ordered tasks for 004-testing-completion (graph-verified [P] + Execution Waves DAG)"
---

# Tasks: The Testing Agent & the Finalized Completion Report

**Input**: Design documents from `/specs/004-testing-completion/`
**Prerequisites**: plan.md (@`9f018ad`, council-APPROVED) · spec.md · research.md · data-model.md · contracts/commands.md · quickstart.md · council/decision-record.md (21 Carried Constraints, binding)

**Two concerns** (plan): **Concern 1** — the testing extension (the `complete` phase + the `testing` phase + the git-ext commit seam). **Concern 2** — the I-17 workforce-freshness fix (a distinct, gate-integrity prerequisite). Per **D69/R1-S01**, both concerns' git-ext edits are a **single PRE-WAVE unit**, provisioned by `implement-parallel`'s pre-flight *before* Wave 1 — **never a wave node**. *Machinery that gates the waves is never itself a wave.*

**Tests**: test tasks are included — the spec/plan require reinstall-survival regressions (FR-013/015), the two-golden contract validation (R1-S10), and the mechanical coverage validator (R1-S03).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: graph-verified parallel-safe (disjoint `files=`, no blast-radius overlap, no shared/mutable collision)
- **[Story]**: `US1` (complete phase) · `US2` (testing phase) · `US3` (phase-tagged commits/seam) · `PREREQ` (I-17, the distinct second concern — named honestly, not smuggled into the testing FRs, D68)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: scaffold the 4th pipeline extension. Serial barrier.

- [X] T001 Scaffold `extensions/testing/` — the 4th pipeline extension tree + `install.sh` + `uninstall.sh` + `README.md`, mirroring graphify/council/workforce packaging (install: extension tree → `.specify/extensions/testing/`, skills → `.claude/skills/`, hook rows merged into `.specify/extensions.yml`; uninstall: deregister-first, byte-identical round-trip — the 002 FR-014 pattern).
- [X] T002 Author `extensions/testing/extension/extension.yml` (`provides.commands: speckit.complete, speckit.testing`) + `extensions/testing/extension/testing-config.yml` (`tester.model: sonnet` [D18], doc-only guard `executed: none`). (depends on T001)

**Checkpoint**: the extension shell exists and declares its two commands.

---

## Phase 2: PRE-WAVE Prerequisite — the bundled git-ext change (Concern 2 I-17 + Concern 1 seam)

**⚠️ PRE-FLIGHT barrier — NOT a wave (D69/R1-S01).** These six tasks are **one git-ext source change → one reinstall → one survival regression** (R1-S13/S20). `implement-parallel`'s pre-flight **refuses to enter Wave 1 until T008 reports done**. They are provisioned *ahead of* the `tasks.md` wave loop, never scheduled *inside* it, so a wave-DAG misorder is impossible by construction (R1-S21 moot). **Non-circularity (R1-S11):** `verify-gate`'s first firing (`before_implement`, ahead of Wave 1) inspects a pristine just-bound `tasks.md` and passes pre-fix — Wave 1's own `[X]`-mark is the sole hazard, so this window is safe. All serial (collision watch: every task touches git-ext owned source).

- [X] T003 [PREREQ] `extensions/git/extension/scripts/verify-gate.sh` — add the **checkbox-delta classification** branch for the **workforce gate's `tasks.md` only**: on a freshness failure (SHA mismatch **or** dirty tree) compute the delta `recorded-SHA → working-tree`; **PASS iff every changed line is a pure GFM checkbox advance** `- [ ]` → `- [x]`/`- [X]` (line otherwise byte-identical); **BLOCK** on any other change, a **reverse** flip `[x]`→`[ ]` (direction-asymmetric — R1-S14/S18), or an unparseable/unreachable diff (fail-closed). Stays **read-only** (no `gates.yml` write, no git-state change), **zero-AI** (`git diff` + per-line regex, FR-007), **scoped** (`agents/assignment.md` and the council gate/`plan.md` keep the strict check). Emit a **durable audit line** when the checkbox-delta branch (not the exact-match fast path) produces the PASS (R1-S09). *Any future simplification MUST preserve the direction asymmetry (R1-S18).* (FR-014/015/016)
- [X] T004 [US3] `extensions/git/extension/scripts/commit.sh` — add **`testing`** to the phase enum (`case "$phase"`; `complete` already present). (FR-013 seam)
- [X] T005 [US3] `extensions/git/extension/extension.yml` — add **`after_testing`** (phase `testing`) + **`after_complete`** (phase `complete`) hooks, `optional: false`, each firing `speckit.git.commit <phase> "<summary>"`. An **errored/empty invocation halts the phase** — no silent no-op (R1-S07). (FR-012/013)
- [X] T006 [PREREQ] `extensions/git/test/run.sh` — add the **I-17 checkbox-delta survival regression**: bind a fixture `tasks.md` → flip a box (**PASS**) → edit a task line (**BLOCK**) → **unpaired insertion/deletion, a task added/removed (BLOCK)** (R1-S04) → **reverse flip `[x]`→`[ ]` (BLOCK)** (R1-S14); each case re-checked **after a git-ext reinstall AND a foreign-extension reinstall** (R1-S15). (FR-015) (depends on T003)
- [X] T007 [US3] `extensions/git/test/run.sh` — add the **SC-008 seam survival regression**: dispatch a fixture `/speckit-complete` + `/speckit-testing` → assert a `complete(<id>)` **AND** a `testing(<id>)` phase-tagged commit exist → **re-assert after a git-ext reinstall AND a foreign-extension reinstall** (R1-S08). (SC-006/008) (depends on T004, T005, T006)
- [X] T008 [PREREQ] Reinstall git-ext **once** (`bash extensions/git/install.sh .`) — the **single bundled reinstall** carrying BOTH concerns' edits (R1-S13/S20) — then run `extensions/git/test/run.sh` and confirm **both** survival regressions green. This green report is the pre-flight "done" signal `implement-parallel` gates Wave 1 on. (SC-010 provisioning) (depends on T003, T004, T005, T006, T007)

**Checkpoint**: the corrected, reinstall-survived git-ext machinery is live *before* Wave 1 — waves 2+ of M4's own implement will pass the freshness check unassisted (SC-010), and the `complete`/`testing` commit seam is armed for the post-implement tail.

---

## Phase 3: User Story 1 — the `complete` phase & finalized completion-report (Priority: P1) 🎯 MVP

**Goal**: the `complete` phase writes `completion-report.md` in a finalized, contract-validated format that *is* the D19 `phase.completed` `artifact.body`.
**Independent Test**: run `/speckit-complete` against a real `tasks.md` + `implement.log.md` → a `completion-report.md` that validates against `docs/contracts/completion-report.md` (status ∈ {success,partial,failed}; 100% of the core sections).

- [X] T009 [P] [US1] Author `docs/contracts/completion-report.md` — the normative section contract: frontmatter `status` ∈ {success,partial,failed} (FR-003) + **exactly** the core sections (`## Implementation Complete — <name>`, `### Completed (N/N)`, `### Partial/Degraded`, `### Failed`, `### Integration status`, `### Key results`) + the **optional appendix OUTSIDE the validated core** (`## Milestone-close context`, `## Decisions & log`); validates **with or without** the appendix (SC-005). Two contract files, not one (R1-S16). (FR-002/003/004; SC-001/005)
- [X] T010 [US1] Author the **`/speckit-complete`** command boundary — `extensions/testing/extension/commands/speckit.complete.md` + `extensions/testing/extension/skills/speckit-complete/SKILL.md`: runs in **main** (Opus authors — **no new model role**, FR-001); **re-reads `tasks.md` + `implement.log.md` from disk on EVERY invocation** — never from assumed context (R1-S02); writes `completion-report.md` and no other artifact; a malformed/absent report leaves `complete` **incomplete**. A real command so M5's `after_complete` push + FR-012's commit have a boundary (R1-S17). (FR-001/005) (depends on T002, T009)
- [X] T011 [P] [US1] Author `extensions/testing/extension/templates/completion-report.template.md` — the emitted skeleton matching the contract core + the optional appendix. (FR-004) (depends on T009)

**Checkpoint**: `/speckit-complete` authors a validating report; the `complete`-event body is well-formed and replayable.

---

## Phase 4: User Story 2 — the doc-only `testing` phase (Priority: P1) 🎯

**Goal**: a separate-session Sonnet `tester` maps every SC **and** FR to a verification approach, `executed: none`, returning status-only.
**Independent Test**: run `/speckit-testing` against a validated `completion-report.md` + `spec.md` → a `testing.md` that validates against `docs/contracts/testing-doc.md`, maps 100% of the spec's 10 SCs + 17 FRs, marks `executed: none`, and returns only `testing.md`.

- [X] T012 [P] [US2] Author `docs/contracts/testing-doc.md` — the coverage contract: frontmatter `executed: none` (FR-009/010); `## Coverage map` (one row per **every SC AND FR** → a verification approach = kind of check + how + confirming evidence, + the completion-report grounding, + status ∈ {covered, GAP}); **gap rows** never a fabricated "covered"; a per-item **evidence-source marking (`report-claimed` vs `log-verified`)** (R1-S05); the `## Verified by reading vs. would-execute in v2` honest split (FR-010). Two contract files, not one (R1-S16). (FR-007/008/010; SC-002/004)
- [X] T013 [US2] Author the **`/speckit-testing`** command — `extensions/testing/extension/commands/speckit.testing.md` + `extensions/testing/extension/skills/speckit-testing/SKILL.md`: **main dispatches ONE Sonnet `tester` subagent** (the separate session); context-in `completion-report.md` + `spec.md` **only**; returns **status-only** to main (SC-003); appends **exactly one** trace (`role: tester`, `model: claude-sonnet-5`, `agent_id: null`, `skills: []`, `elevated_grants: []`) carrying a **`context_in`** field recording the files read (R1-S06). (FR-006/011; SC-003) (depends on T002, T012)
- [X] T014 [P] [US2] Author `extensions/testing/extension/templates/tester-prompt.md` — the Sonnet tester's separate-session prompt: map every SC+FR to a verification approach grounded in the report's Integration-status; **mark each item `report-claimed` vs `log-verified`** (R1-S05); MAY **lazily read `implement.log.md` on doubt** as a cross-check (the D10 lazy-grounding pattern); record `executed: none`; cite implement-time tests as **existing** evidence, never re-run (FR-009). (FR-008/009/010; R1-S05) (depends on T012)
- [X] T015 [P] [US2] Author `extensions/testing/extension/templates/testing.template.md` + `extensions/testing/extension/templates/trace-fragment.md` — the `testing.md` skeleton (frontmatter + `## Coverage map` + honest split) and the tester's one trace record (`role: tester`, Sonnet, `context_in`, `elevated_grants: []`). (FR-010/011; R1-S06) (depends on T012)
- [X] T016 [US2] Implement the **SC/FR coverage validator** (in `extensions/testing/test/run.sh`) — a mechanical check that **greps every `SC-\d+` and `FR-\d+` ID from `spec.md`** and asserts each appears in `testing.md`'s coverage map; **contract validation FAILS on any gap** (the 003 categorization-completeness-validator precedent — code-enforced, not prompt-enforced). Also holds the **two-golden completion-report validation** (appendix-bearing + appendix-free, each independently validated — R1-S10) + a golden `testing.md`, with **golden assertions derived from `docs/contracts/*.md`'s own section lists** so contract and validator cannot silently diverge (R1-S19), + the install/uninstall round-trip. (SC-001/002/004/005; R1-S03/S10/S19) (depends on T012)

**Checkpoint**: the testing phase produces a 100%-mapped, gap-honest, status-only `testing.md`; coverage is code-enforced.

---

## Phase 5: User Story 3 — phase-tagged commits for `complete` & `testing` (Priority: P2)

**Goal**: each new phase boundary leaves a phase-tagged commit; the git-ext seam survives reinstall.
**Independent Test**: run `complete` then `testing` → `git log` shows `complete(004-testing-completion)` + `testing(004-testing-completion)`; a git-ext + foreign reinstall leaves the seam firing.

> **US3's git-ext side is provisioned PRE-WAVE** (bundled per R1-S13/S20): **T004** (commit.sh `testing` enum), **T005** (`after_testing`/`after_complete` hooks), **T007** (seam survival regression). Its **command boundaries** are **T010** (`/speckit-complete`) + **T013** (`/speckit-testing`). US3 has **no separate implementation task** — it is realized by the pre-wave seam firing on the US1/US2 command boundaries; its acceptance is the T007 regression (SC-006/008) plus the live `complete(004)`/`testing(004)` commits M4's own run produces (SC-009).

**Checkpoint**: the per-feature git lifecycle is phase-tagged end to end.

---

## Phase 6: Polish & Integration

**Purpose**: the contract-ownership edit, the extension install, and the end-to-end quickstart validation.

- [X] T017 [P] [US1/US2] Edit `docs/contracts/artifact-layout.md` §6 ownership table — add rows: `completion-report.md` ← the `complete` phase (`/speckit-complete`, main orchestrator); `testing.md` ← the testing extension (`tester`). A D46-rule-3-authorized contract edit (no new writer of an existing artifact). **Collision watch (R1-S22): serialize — `artifact-layout.md` is a shared/mutable file.**
- [X] T018 Install the testing extension (`bash extensions/testing/install.sh .`) + run `extensions/testing/test/run.sh` → contracts validate (both goldens), coverage validator green, install/uninstall round-trip byte-identical. (Touches `.specify/extensions.yml` — serial integration.) (depends on T001–T016)
- [ ] T019 Run the `quickstart.md` validation scenarios (SC-001…SC-010 map). SC-009 (M4 exit — validated report + testing doc, both committed) and SC-010 (wave 2+ unassisted freshness) are proven on **M4's own downstream run**, not simulated here. (depends on T018)

**Checkpoint**: the tail is validated end to end; M4 is ready for its own `complete` + `testing` phases.

---

## Dependencies & Execution Order

- **Pre-flight (Phase 2)** — provisioned by `implement-parallel`'s pre-flight **before** Wave 1; **not a wave** (D69). Blocks the entire wave loop.
- **Setup (Phase 1)** — Wave 1–2 serial barrier; blocks all stories.
- **US1 (Phase 3)** / **US2 (Phase 4)** — independent after Setup; parallel across stories.
- **US3 (Phase 5)** — realized by the pre-flight seam + US1/US2 boundaries (no separate tasks).
- **Polish (Phase 6)** — after all stories.

FR-017 (the I-17 fix design is council-reviewed as gate-integrity) is **already satisfied** — round-1 council reviewed it as the second concern and the human gate APPROVED (`de0e62d`); no build task.

---

## Execution Waves

> Machine-readable DAG for `/speckit-implement-parallel`. Derived from phase boundaries, graph-verified `[P]` markers, TDD/ownership ordering, and graphify dependency edges (note: the `.sh`/`.yml` edits are graph-invisible — shell has no import graph, I-13 — so their `[P]`/serial calls lean on the `graphify-context.md` shared/mutable list + direct source reads, not graph edges).
>
> **⚠️ PRE-FLIGHT (D69/R1-S01): the bundled git-ext change is NOT a wave.** The I-17 checkbox-delta fix **and** the testing seam are one git-ext source change → one reinstall → one survival pass, provisioned by `implement-parallel`'s **pre-flight** *before* Wave 1. *Machinery that gates the waves is never itself a wave.* The pre-flight **refuses to enter Wave 1 until T008 reports done.** The numbered wave loop below contains **only** the testing-extension build.

### Pre-flight [barrier — provisioned before the wave loop; NOT a numbered wave]

- Pre-flight [serial] : T003 → T004 → T005 → T006 → T007 → T008    # one git-ext source change → one reinstall → one survival pass (R1-S13/S20)
  - **gate**: `implement-parallel` MUST NOT enter Wave 1 until **T008** reports done (both survival regressions green). (SC-010 provisioning; D69)

### Wave loop [the testing-extension build]

- Wave 1 [serial]   : T001                                              # scaffold extensions/testing/ tree (shared scaffolding)
- Wave 2 [serial]   : T002                                              # testing-ext manifest + config (packaging barrier)
- Wave 3 [parallel] : T009 [US1], T012 [US2], T017 [US1/US2]            # three disjoint docs/contracts/ files
- Wave 4 [parallel] : T010 [US1], T011 [US1], T013 [US2], T014 [US2], T015 [US2], T016 [US2]   # commands/templates/validator — all disjoint new files
- Wave 5 [serial]   : T018                                              # install testing-ext + test/run.sh green (touches .specify/extensions.yml)
- Wave 6 [serial]   : T019                                              # quickstart SC-001..010 validation

### Task annotations

- T001  files=extensions/testing/{install.sh,uninstall.sh,README.md}                     deps=-              mutates=(new)
- T002  files=extensions/testing/extension/{extension.yml,testing-config.yml}             deps=T001           mutates=(new)
- T003  files=extensions/git/extension/scripts/verify-gate.sh                             deps=-              mutates=verify-gate.sh
- T004  files=extensions/git/extension/scripts/commit.sh                                  deps=-              mutates=commit.sh
- T005  files=extensions/git/extension/extension.yml                                      deps=-              mutates=git-ext/extension.yml
- T006  files=extensions/git/test/run.sh                                                  deps=T003           mutates=git-ext/test/run.sh
- T007  files=extensions/git/test/run.sh                                                  deps=T004,T005,T006 mutates=git-ext/test/run.sh
- T008  files=.specify/extensions/git/** (redeploy), .specify/extensions.yml              deps=T003,T004,T005,T006,T007  mutates=installed git-ext + registry
- T009  files=docs/contracts/completion-report.md                                         deps=-              mutates=(new)
- T010  files=extensions/testing/extension/commands/speckit.complete.md, extensions/testing/extension/skills/speckit-complete/SKILL.md   deps=T002,T009  mutates=(new)
- T011  files=extensions/testing/extension/templates/completion-report.template.md        deps=T009           mutates=(new)
- T012  files=docs/contracts/testing-doc.md                                               deps=-              mutates=(new)
- T013  files=extensions/testing/extension/commands/speckit.testing.md, extensions/testing/extension/skills/speckit-testing/SKILL.md     deps=T002,T012  mutates=(new)
- T014  files=extensions/testing/extension/templates/tester-prompt.md                     deps=T012           mutates=(new)
- T015  files=extensions/testing/extension/templates/{testing.template.md,trace-fragment.md}  deps=T012       mutates=(new)
- T016  files=extensions/testing/test/run.sh                                              deps=T012           mutates=(new)
- T017  files=docs/contracts/artifact-layout.md                                           deps=-              mutates=artifact-layout.md
- T018  files=.specify/extensions/testing/** (deploy), .specify/extensions.yml            deps=T001..T016     mutates=installed testing-ext + registry
- T019  files=specs/004-testing-completion/quickstart.md (run, read-only)                 deps=T018           mutates=-

### Shared-file serialization (collision watch — graphify-context.md §Shared/mutable + R1-S22)

- `extensions/git/extension/scripts/verify-gate.sh` — T003 (pre-flight; sole toucher, but git-ext owned source).
- `extensions/git/extension/scripts/commit.sh` — T004 (pre-flight; sole toucher).
- `extensions/git/extension/extension.yml` — T005 (pre-flight; sole toucher).
- `extensions/git/test/run.sh` — **T006, T007** → both pinned serial in the pre-flight, never co-scheduled.
- `docs/contracts/artifact-layout.md` — **T017** (R1-S22; sole toucher, kept out of any wave that edits it concurrently — none do).
- `.specify/extensions.yml` — **T008** (pre-flight, git-ext reinstall) and **T018** (Wave 5, testing-ext install) → temporally separated (pre-flight vs final wave); never co-scheduled.

### Notes

- `[P]` reconciled against the graph where edges exist; for the graph-invisible `.sh`/`.yml` edits, serialization is derived from the `graphify-context.md` shared/mutable list (I-13 honest degradation noted).
- The pre-flight unit (T003–T008) carries **both** concerns per R1-S13/S20 — one reinstall, one survival pass — and is enforced mechanically by `implement-parallel`'s pre-flight, not by wave-DAG prose (D69).
