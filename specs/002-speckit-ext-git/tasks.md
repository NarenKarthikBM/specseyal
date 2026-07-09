# Tasks: speckit-ext-git — Per-Feature Git Lifecycle

**Input**: Design documents from `/specs/002-speckit-ext-git/`

**Prerequisites**: plan.md (required), spec.md (required), data-model.md, contracts/commands.md, research.md, quickstart.md, `council/decision-record.md` **Carried Constraints** (binding on this generation)

**Tests**: The feature spec did **not** request per-story TDD, but the plan's Testability section and the Carried Constraints **explicitly require** a scripted CI harness (`test/run.sh`, R1-S17: `branch.sh` units + concurrency test R1-S13 + reinstall-survival regression) and quickstart SC-proofs (R1-S18/S29). Those are included as dedicated Polish tasks; no speculative per-story test scaffolding is added.

**Organization**: Grouped by user story (spec.md US1–US5, priority order). The extension is mechanical git, **zero AI** (FR-007) — its runtime makes no model calls and writes no `traces.jsonl` record.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency, not on the shared/mutable list).
- **[Story]**: US1–US5 from spec.md.
- Exact file paths in every task.

## Graph-grounding note (I-13 / R1-S22 — read before trusting `[P]`)

`graphify explain`/`path` return **"No node matching"** for `.sh` and `.yml` (I-13, filed at triage as R1-S22): the dependency graph has **no nodes for this feature's file types**. Therefore `[P]` on the new `extensions/git/**` scripts is **NOT graph-verified** — it falls back to the stock heuristic (disjoint `files=` + no stated dependency), per the `speckit-tasks-graph` degradation rule. Only the shared/mutable list from `graphify-context.md` is graph-grounded: **`.specify/extensions.yml`** and **`.specify/feature.json`** are the sole collision points; every `extensions/git/**` file is new and disjoint. Blast-radius claims here are **engineer assertion re-derived by reading files**, not graph fact (R1-S22).

## Path Conventions

Sibling-of-graphify extension. Payload lives under `extensions/git/`; the one human skill installs to `.claude/skills/`; the installer merges hooks into `.specify/extensions.yml`. See plan.md §Project Structure.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: The `extensions/git/` skeleton, config, and provenance stubs — mirrors `extensions/council/` + `extensions/graphify/`.

- [X] T001 Create the `extensions/git/` tree per plan §Project Structure — `extension/` (`commands/`, `scripts/`), `skills/speckit-git-cleanup/`, `test/`, and placeholder top-level `README.md` — mirroring the `extensions/council/` + `extensions/graphify/` layout. `files=extensions/git/` `deps=-` `mutates=(new)`
- [X] T002 [P] Author `extensions/git/extension/git-config.yml` — `base_branch: main`; `merge.policy` = **`ff`-permitted, merge-commit only when base diverged** (D52); `anchor` = **mandatory annotated tag `complete/<spec-id>`** (D52/R1-S27); `branch.pattern` = `^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$` (**FR-002**, name = spec ID) **plus the `YYYYMMDD-HHMMSS-slug` carve-out under `feature_numbering: timestamp`** (R1-S25); `commit.grammar` (PhaseCommit/WaveCommit shapes, FR-006); `phases: [specify, clarify, plan, tasks, implement]`; `gates` map (council→`plan.md`/before-`tasks`; workforce→`tasks.md`,`assignment.md`/before-`implement`). `files=extensions/git/extension/git-config.yml` `deps=T001` `mutates=(new)`
- [X] T003 [P] Author the four provenance command stubs (dots→hyphens on install) — `extension/commands/speckit.git.commit.md`, `speckit.git.sha.md`, `speckit.git.verify-gate.md`, `speckit.git.cleanup.md`. `files=extensions/git/extension/commands/*.md` `deps=T001` `mutates=(new)`
- [X] T004 [P] Author `extensions/git/README.md` + `extension/README.md` (packaging + install/uninstall docs, mirror council/graphify). `files=extensions/git/README.md,extensions/git/extension/README.md` `deps=T001` `mutates=(new)`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The hook manifest + installer/uninstaller — every story's hooks route through these. **⚠️ No story hook fires until the extension is declared and merged.**

**Enforcement honesty (R1-S08 / D53):** these tasks register hooks `optional: false` and add stop-on-nonzero clauses, but v1 enforcement is **prose-level** — the stock dispatcher has no implemented `HookExecutor`. Tasks MUST NOT claim mechanical hook enforcement; a mechanical executor is deferred to M6 (D53).

- [X] T005 Author `extensions/git/extension/extension.yml` — `id: git`; declares **every** git-ext hook `optional: false` with auto-invoke semantics (**R1-S01**, its own task, distinct from the stop-on-nonzero clause **T015**). Hook set (the **FR-003** phase-commit boundaries that have a stock hook slot): `after_specify`, `after_clarify`, `after_plan`, `after_tasks`, `after_implement`, **`after_analyze`** (R1-S14 — analyze can revise `tasks.md`, so its boundary needs a commit), **`after_council_approve`** (R1-S04, the reinstall-surviving gate-record hook), `before_tasks`/`before_implement` (verify-gate). Lists provided primitives `commit`/`sha`/`verify-gate` + the `cleanup` command. See the **FR-003 coverage map** in §Notes for the boundaries that have *no* hook slot. `files=extensions/git/extension/extension.yml` `deps=T002` `mutates=(new)`
- [X] T006 Author `extensions/git/install.sh` — **the `.specify/extensions.yml` hook-merge, BUDGETED AS ITS OWN TASK (R1-S15)**: this is the largest/most-failure-prone piece, not "a short sh script" (graphify needed ~193 lines to merge 3 uniform entries; this merges **7 git-ext entries across 3 shapes into 5 new keys + 2 append targets**). **Append-only, never overwrite** the existing graphify `before_*` entries; **insert `verify-gate` AHEAD of graphify** on the shared `before_tasks`/`before_implement` keys so the hard-block runs before graphify's context regen (**R1-S07**; this is FR-013 composition — git-ext composes with graphify's `before_*` without conflict); **`priority` is implemented or deleted — no zombie schema** (R1-S07); parse-check the merged YAML. Also copy `extension/` → `.specify/extensions/git/` and the cleanup skill → `.claude/skills/` (mirror council packaging + graphify's hook-merge variant). Idempotent (`rm -rf`+`cp -R`). *(This is existing-file edit #1 of the five enumerated at R1-S03: `.specify/extensions.yml`.)* `files=extensions/git/install.sh` `deps=T005` `mutates=.specify/extensions.yml`
- [X] T007 Author `extensions/git/uninstall.sh` — **deregister hook entries from `.specify/extensions.yml` BEFORE removing the payload, or fail hard** (R1-S26a / R4: else `extensions.yml` references deleted commands and a dangling `optional:false` hook hard-blocks every phase). Remove only what install added — payload, skill, and its hook entries — modifying no pre-existing file except the hook registrations (FR-014). `files=extensions/git/uninstall.sh` `deps=T006` `mutates=.specify/extensions.yml`

**Checkpoint**: Extension declares its hooks and installs/uninstalls cleanly — story scripts can now be filled in behind the declared primitives.

---

## Phase 3: User Story 1 - Git lifecycle runs itself: branch birth + phase commits (Priority: P1) 🎯 MVP

**Goal**: A feature gets its own branch (named = spec ID) at `specify`, and a phase-tagged commit lands at every phase boundary — zero manual git (FR-001/003/006).

**Independent Test**: Drive specify→plan→tasks; assert a branch `NNN-slug` exists + is checked out, `spec.md` is on it and **not** on base, and each boundary has exactly one `<phase>(<id>): …` commit (SC-001/002/003).

- [ ] T008 [US1] Author `extension/scripts/branch.sh` — ensure-branch-from-spec-id: read the spec ID from `.specify/feature.json` (D45, **never recompute** NNN+slug — **FR-013**: git branch and feature tracking stay decoupled; the resolver is `feature.json`, never the branch name), branch name **equals the spec ID** (**FR-002**), `git checkout -b <id>` iff absent (idempotent, FR-012); **`flock` on NNN allocation AND loud-fail on NNN-exists-with-different-slug** (**R1-S13** / R3 — a same-slug guard misses this; create-if-absent would otherwise turn a collision into a silent shared branch); accept both the `NNN-slug` and `YYYYMMDD-HHMMSS-slug` (timestamp mode) patterns (R1-S25). `files=extensions/git/extension/scripts/branch.sh` `deps=T001` `mutates=(new)`
- [ ] T009 [US1] Author `extension/scripts/commit.sh` — phase-tagged commit in the FR-006 grammar `<phase>(<spec-id>): <summary>`; **no-op (exit 0, no commit) when the tree is clean** (FR-004); **self-heal: ensure the feature branch via `branch.sh` before committing** so a failed brancher never lets commits land on base (**R1-S12** — one self-healing entry point); **staging scoped to `specs/NNN-feature/**` + the task's declared outputs — never a repo-wide `git add -A`** (**R1-S11** — an unattended repo-wide add would sweep a stray secret into permanent history). The `after_specify` branch-birth (FR-001/D-R1) IS this self-heal firing on the first commit. `files=extensions/git/extension/scripts/commit.sh` `deps=T008` `mutates=(new)`

**Checkpoint**: `after_specify/clarify/plan/tasks/implement/analyze` hooks (declared T005, merged T006) now checkpoint every boundary through `commit.sh`; the branch is born on the first commit. MVP complete.

---

## Phase 4: User Story 2 - Implementation resumable at wave granularity (Priority: P1)

**Goal**: Each completed implement wave is its own cold-resumable commit (`impl(<id>) wave K/N`), so an interrupted run resumes at the first uncommitted wave (FR-005, SC-006).

**Independent Test**: Run ≥3 waves, kill after wave 2, resume; assert per-wave commits, restart at wave 3, nothing duplicated/lost (Scenario 3b).

- [ ] T010 [US2] Edit `.claude/skills/speckit-implement-parallel/SKILL.md` — after each wave call `speckit.git.commit impl "wave K/N …"` **BEFORE marking the task `[X]`** (**R1-S06** — commit-before-`[X]` closes the interrupt window; an `[X]`-first order can't distinguish "done, commit missing" from "partial, discard"; principle III / SC-006), and **re-verify gate freshness at each wave boundary** (**R1-S23** — closes R2's mid-`implement` blind spot). This is the **one genuinely coupled edit** (no per-wave hook vocabulary exists) — named in Risk R1 and covered by the reinstall-survival regression (T021). *(Existing-file edit #3 of five, R1-S03.)* `files=.claude/skills/speckit-implement-parallel/SKILL.md` `deps=T009,T013` `mutates=.claude/skills/speckit-implement-parallel/SKILL.md`

**Checkpoint**: `implement` is wave-resumable; the `after_implement` hook still backstops the phase boundary if a per-wave call is missed (coarser, never lost — D-R7).

---

## Phase 5: User Story 3 - Gate approval provably bound to unchanged content (Priority: P2)

**Goal**: Each gate approval records the approved artifacts' SHAs into a git-ext-owned `gates.yml`; a later edit (committed **or** uncommitted) is detected and hard-blocks the dependent phase until re-approval (FR-008/009).

**Independent Test**: Approve council gate at S1; edit `plan.md` (both committed and dirty-tree); assert `before_tasks` → `verify-gate` non-zero → `tasks` hard-blocked until reopen (SC-004).

- [ ] T011 [P] [US3] Author `extension/scripts/sha.sh` — print the SHA of the HEAD commit that last touched a given artifact path (the value a gate records, FR-008). Read-only, no trace. `files=extensions/git/extension/scripts/sha.sh` `deps=T001` `mutates=(new)`
- [ ] T012 [US3] Author `extension/scripts/gates.sh` — write/read the **git-ext-owned `specs/NNN-feature/gates.yml`** bindings record (**R1-S09/S20**, dissolving the D-R3 supply/record seam so no other command's artifact is co-written): council→`plan.md @ <sha>`; workforce→`tasks.md @ <sha>` + `assignment.md @ <sha>`. `gates.yml` is a **bindings record**, not phase state (D32). `files=extensions/git/extension/scripts/gates.sh` `deps=T011` `mutates=(new)`
- [ ] T013 [US3] Author `extension/scripts/verify-gate.sh` — parse `gates.yml`, compare each recorded SHA to `sha.sh <artifact>`; **working-tree-aware — a dirty approved artifact reads stale** (**R1-S05**, comparing committed HEADs alone false-passes an uncommitted hand-edit); **fail-closed** — an unparseable binding or gate-format-version drift is treated as stale, never fail-open (**R1-S10**). Exit non-zero + human-readable mismatch on stale (FR-009 hard-block). `files=extensions/git/extension/scripts/verify-gate.sh` `deps=T011,T012` `mutates=(new)`
- [ ] T014 [P] [US3] Author the **reinstall-surviving `after_council_approve` hook action** (`extension/scripts/on-council-approve.sh` + its `extension.yml` entry) that calls `gates.sh` to write `plan.md @ <sha>` and makes `## Human Gate` carry a one-line `gates.yml` reference. **No edit to `speckit-council-approve`'s installer-overwritten source** (**R1-S04** — a source edit is `rm -rf`+`cp -R`-wiped on reinstall and an ownership violation; a hook is neither). **Signer-agnostic (FR-010):** the SHA-record MUST fire regardless of who signs — under `gates.council.mode:auto` (D9/D33) the gate section is auto-written by `speckit-council-triage` with **no `approve` event**, so the auto-path must trigger the same `gates.sh` write (an `after`-triage-auto-write trigger, not the human-`approve` hook alone). *002's own gates are `human`, so the human path is exercised here; the auto path is the FR-010 completeness requirement (M1 analyze finding).* *(Existing-file edit #2 of five, R1-S03.)* `files=extensions/git/extension/scripts/on-council-approve.sh` `deps=T012` `mutates=(new)`
- [ ] T015 [P] [US3] Edit `.claude/skills/speckit-tasks/SKILL.md` + `.claude/skills/speckit-implement/SKILL.md` — add the explicit **"if the invoked `before_*` hook exits non-zero, STOP"** pre-check clause (**R1-S02**, its own task, **distinct from R1-S01's `optional:false` flag** — flipping the flag makes the hook *run* but a missing stop-clause still won't *block*). Prose-level enforcement only (R1-S08 — no mechanical-enforcement claim). *(Existing-file edit #4 of five, R1-S03.)* `files=.claude/skills/speckit-tasks/SKILL.md,.claude/skills/speckit-implement/SKILL.md` `deps=-` `mutates=.claude/skills/speckit-tasks/SKILL.md,.claude/skills/speckit-implement/SKILL.md`

**Checkpoint**: A stale approval (committed or dirty) hard-blocks its dependent phase; re-approval routes by gate type (council→D14 reopen tiers; workforce→re-run, D-R5).

---

## Phase 6: User Story 4 - Completion integrates with the full trail; branch retired (Priority: P2)

**Goal**: An explicit human cleanup integrates the feature preserving every phase-tagged commit, stamps the mandatory `complete/<spec-id>` tag anchor, and deletes the branch (FR-011, SC-005).

**Independent Test**: Complete a feature; assert every phase/wave commit is reachable from base tip (per-SHA `merge-base --is-ancestor`), the `complete/<spec-id>` tag exists, and the branch ref is gone; a conflict aborts and is surfaced (Scenario 3).

- [ ] T016 [US4] Author `extension/scripts/cleanup.sh` — integrate into `base_branch`: **`ff` permitted**, `git merge --no-ff` only when base diverged (D52 — the anchor is the tag, not the topology); **create the MANDATORY annotated tag `complete/<spec-id>`** at the integration commit (the D19/M5 binding anchor, enumerable via `git for-each-ref refs/tags/complete/*`, **R1-S27**); then `git branch -d <feature>`. On textual conflict → `git merge --abort` + surface, **never auto-resolve, never delete an unmerged branch** (FR-011, no silent loss). Idempotent re-run (branch gone, tag present). **No squash/rebase-collapse** (D25). `files=extensions/git/extension/scripts/cleanup.sh` `deps=T001` `mutates=(new)`
- [ ] T017 [US4] Author `extensions/git/skills/speckit-git-cleanup/SKILL.md` — the one human command wrapping `cleanup.sh` (installed to `.claude/skills/`; `disable-model-invocation` **not** set — the human runs it; never automatic, since retiring a branch is consequential). `files=extensions/git/skills/speckit-git-cleanup/SKILL.md` `deps=T016` `mutates=(new)`

**Checkpoint**: Feature integrates trail-preserved, tag anchored, branch retired.

---

## Phase 7: User Story 5 - Timeboxed wave-worktree spike (Priority: P3)

**Goal**: Bounded experiment — does a git-worktree-per-*wave* improve isolation between concurrent implement subagents? Deliverable is a recorded finding, not a shipped behavior (FR-015, SC-008).

**Independent Test**: Confirm the spike ran in its timebox and left a written outcome + adopt-later/abandon recommendation; removing it leaves US1–US4 green.

- [ ] T018 [US5] Run the **wave-worktree spike** — **timeboxed to a single implement-phase sitting (≤ ~2h of build time), 1 spike attempt** *(provisional bound — the spec/plan say only "timeboxed"; **confirm the magnitude at the workforce gate**, M2 analyze finding)*. **Distinct name** from `speckit-implement-parallel`'s pre-existing per-*story* `Agent isolation: worktree` guardrail (**R1-S24**, so `implement.log.md` attribution stays clean). Give each parallel implement *wave* its own `git worktree`, merge per wave, measure isolation vs the shared-tree default; record finding + adopt-later/abandon in `implement.log.md` + a `docs/90` I-row. **Firewalled**: no v1 hook/command references `worktree`; deleting the spike re-runs Scenarios 1–4 green (SC-008). MUST NOT block any P1/P2 task. Runs **after** the implement path it experiments on exists (L1: analyze fix). `files=specs/002-speckit-ext-git/implement.log.md,docs/90-DECISIONS-AND-IDEAS.md` `deps=T010` `mutates=docs/90-DECISIONS-AND-IDEAS.md`

**Checkpoint**: Knowledge recorded; v1 loop unchanged.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T019 [P] Regenerate/correct `specs/002-speckit-ext-git/graphify-context.md` — **retract the false "only `.specify/extensions.yml` touched, no source mutated" manifest** and reconcile the shared/mutable + dependency list with the **true five existing-file edits** (**R1-S03** — the false manifest would have let this very `/speckit-tasks` run omit the seam); label installer/`extensions.yml` blast-radius as **engineer assertion, not graph fact** (graph has no `.sh`/`.yml` nodes, **R1-S22 / I-13**). *(Existing-file edit #5 of five, R1-S03.)* `files=specs/002-speckit-ext-git/graphify-context.md` `deps=-` `mutates=specs/002-speckit-ext-git/graphify-context.md`
- [ ] T020 Correct the **two stale `before_specify` assertions** that point a future implementer at the *rejected* design (the ratified design is branch-birth folded into `after_specify`, D-R1) — `.claude/skills/speckit-specify/SKILL.md` closing NOTE **and** `specs/002-speckit-ext-git/graphify-context.md` (**R1-S16**, its own task). `files=.claude/skills/speckit-specify/SKILL.md,specs/002-speckit-ext-git/graphify-context.md` `deps=T019` `mutates=.claude/skills/speckit-specify/SKILL.md,specs/002-speckit-ext-git/graphify-context.md`
- [ ] T021 Author `extensions/git/test/run.sh` — the CI-able harness (**R1-S17**): `branch.sh` create-if-absent **unit tests** (scratch repo + fabricated `feature.json`, no model), the **NNN concurrency test** (R1-S13), and the **reinstall-survival regression** (reinstall council+graphify, assert the R1-seam call sites survived — the `after_council_approve` hook T014 and the `implement-parallel` per-wave edit T010 — the S04 class a manual quickstart never catches). `files=extensions/git/test/run.sh` `deps=T006,T010,T014` `mutates=(new)`
- [ ] T022 Wire the **`before_specify` drift lint** (**R1-S29**) — mechanically catch the `before_specify`-style assertion-drift class, partially compensating the prose-level enforcement gap (R1-S08 / D53). R1-S29's intended home is **the D50 conformance checker**, but D50 records that *"building the checker stays open"* — so the concrete v1 vehicle is **`extensions/git/test/run.sh`** (T021), with a one-line pointer to relocate the lint into the D50 checker once that ships (M4 finding). `files=extensions/git/test/run.sh` `deps=T020,T021` `mutates=extensions/git/test/run.sh`
- [ ] T023 Run `quickstart.md` validation end-to-end as **existence proofs** (R1-S18/S29, not "100%"): Scenario 1 (auto branch + phase commits, SC-001/002/003), Scenario 2 (gate stale hard-block — **both committed and uncommitted** edits, SC-004/R1-S05), Scenario 3 (cleanup: `complete/<id>` tag + **per-SHA `merge-base --is-ancestor`** reachability, SC-005), Scenario 3b (interrupt/resume at wave, SC-006), Scenario 4 (zero-AI **by construction** — no `extensions/git/**` path invokes a model, not a vacuous grep, SC-007), Scenario 5 (spike removal re-run, SC-008). `files=specs/002-speckit-ext-git/quickstart.md` `deps=T007,T010,T015,T016,T021` `mutates=(none — validation run)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup; declares + installs the hooks all stories route through. Serial (edits the shared `.specify/extensions.yml`).
- **User Stories (Phases 3–7)**: depend on Foundational. US1 is the MVP (the commit spine). US2's per-wave edit reuses `commit.sh` (US1) and `verify-gate.sh` (US3, for the R1-S23 per-wave re-verify). US3/US4 are otherwise independent new scripts. US5 is firewalled and blocks nothing.
- **Polish (Phase 8)**: doc reconciliation, the test harness, and the quickstart validation run last.

### Cross-story dependency (the one real coupling)

- **T010 [US2] → T009 [US1] + T013 [US3]**: the single `implement-parallel` edit carries both the per-wave commit (needs `commit.sh`) and the per-wave gate re-verify (needs `verify-gate.sh`). This is why US2 (P1) sequences after US3's `verify-gate.sh` in the DAG even though US3 is P2 — the edit is atomic. The MVP path (US1 alone) does not need it.

### Within stories

- US1: `branch.sh` → `commit.sh` (self-heal calls the brancher).
- US3: `sha.sh` → `gates.sh` → `verify-gate.sh`; `on-council-approve.sh` needs `gates.sh`; the stop-on-nonzero edit is independent.
- US4: `cleanup.sh` → `speckit-git-cleanup` skill.

### Parallel Opportunities

- Setup T002/T003/T004 in parallel after T001.
- Once Foundational lands: US1 (`branch.sh`), US3 (`sha.sh`, stop-on-nonzero edit), US4 (`cleanup.sh`), US5 (spike) all kick off in parallel — disjoint files.
- `sha.sh`, `after_council_approve` action, and the stop-on-nonzero skill edit are `[P]` within US3 (different files).

---

## Implementation Strategy

**MVP = User Story 1** (branch birth + phase commits) after Setup + Foundational — this alone satisfies the M2 exit condition (SC-001). Then layer US2 (wave resumability), US3 (gate binding), US4 (cleanup), and the firewalled US5 spike. Polish reconciles the docs and runs the SC proofs.

---

## Notes

### FR-003 phase-commit coverage map (H1 analyze finding — all 10 enumerated boundaries)

FR-003 names **10** phase-commit boundaries. Not all have a stock hook slot; this map makes each one's mechanism explicit so none is silently uncovered:

| Boundary (FR-003) | Mechanism in M2 | Task |
|---|---|---|
| specify · clarify · plan · tasks · implement | `after_*` commit hook → `commit.sh` | T005 (decl) + T009 |
| analyze | `after_analyze` hook (R1-S14) → `commit.sh` | T005 + T009 |
| **council / triage** | **orchestrator-level `commit.sh` call** — **prose-level** (D53), no coupled council-source edit (R1-S04) and no `after_council`/`after_triage` hook vocabulary exists; the primitive (T009) is available, the main thread invokes it at the boundary | T009 (primitive) + prose |
| **complete** | `/speckit-git-cleanup` does integrate+tag+delete (T016/T017); the `completion-report.md` (M4) phase commit is an **orchestrator prose-level** `commit.sh` call | T016/T017 + prose |
| **categorize · agent-assign** | **deferred to M3/M4** — no skill exists yet to carry the call (per R1-S14's disposition); not buildable in M2 | *(M3/M4)* |

**Consequence (honesty, R1-S08 / D53):** the council/triage/complete commits are **prose-level** (an LLM following pipeline prose calls the primitive), exactly the enforcement class the plan names as prose-level in v1; a mechanical `HookExecutor` for these is M6 (D53). For **002 itself** — the last hand-built feature — council/triage/gate/categorize/complete commits are made **by hand** this milestone (the very step this feature retires).

- **Zero AI (FR-007)**: no task adds a model call or a `traces.jsonl` record; SC-007 is satisfied *by construction* and checked as such (T023), not by a vacuous grep.
- **No state file (D32)**: `gates.yml` is a bindings record, not phase state; phase state stays inferred from artifacts + the branch ref.
- **Prose-level enforcement (R1-S08 / D53)**: T005/T014/T015 register `optional:false` + stop-on-nonzero, but v1 enforcement is an LLM following skill prose; a mechanical `HookExecutor` is M6. No task claims otherwise.
- Commit each task or logical group; the extension's own build follows D18 (Sonnet implementers, Opus main thread) and D28 (subscription auth, `ANTHROPIC_API_KEY` unset).

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries, [P] markers,
> and dependency edges. `[P]`-verification for `extensions/git/**` uses the file-disjointness heuristic —
> the graph has no `.sh`/`.yml` nodes (I-13 / R1-S22). Setup and Foundational are serial barriers;
> parallelism is cross-story.

- Wave 1 [serial]   : T001                              # Setup skeleton (creates the tree — barrier)
- Wave 2 [parallel] : T002, T003, T004                  # Setup config/stubs/docs (disjoint new files)
- Wave 3 [serial]   : T005                              # Foundational: extension.yml manifest (R1-S01)
- Wave 4 [serial]   : T006                              # Foundational: install.sh hook-merge (R1-S15) — edits shared .specify/extensions.yml
- Wave 5 [serial]   : T007                              # Foundational: uninstall.sh (R1-S26a) — edits shared .specify/extensions.yml
- Wave 6 [parallel] : T008 [US1], T011 [US3], T015 [US3], T016 [US4]   # story kickoffs, disjoint (T018 moved late — L1 fix)
- Wave 7 [parallel] : T009 [US1], T012 [US3], T017 [US4]                           # depend on wave-6 siblings
- Wave 8 [parallel] : T013 [US3], T014 [US3]            # verify-gate.sh + on-council-approve.sh — both deps=T012 (wave 7), disjoint files [DAG fix: T014 was mis-scheduled in wave 7 alongside its own dep T012]
- Wave 9 [parallel] : T010 [US2]                        # implement-parallel edit (deps commit.sh + verify-gate.sh)
- Wave 10 [parallel]: T018 [US5], T019                  # spike now after the implement path it experiments on (deps T010, L1 fix); + graphify-context regen (disjoint)
- Wave 11 [serial]  : T020                              # before_specify assertion fix (shares graphify-context.md with T019)
- Wave 12 [serial]  : T021                              # test harness (branch units + concurrency + reinstall-survival)
- Wave 13 [serial]  : T022                              # drift lint (extends test/run.sh — shares file with T021)
- Wave 14 [serial]  : T023                              # quickstart SC validation run (deps ~all)

### Task annotations

- T001  files=extensions/git/                                          deps=-           mutates=(new)
- T002  files=extensions/git/extension/git-config.yml                  deps=T001        mutates=(new)
- T003  files=extensions/git/extension/commands/*.md                   deps=T001        mutates=(new)
- T004  files=extensions/git/README.md,extension/README.md             deps=T001        mutates=(new)
- T005  files=extensions/git/extension/extension.yml                   deps=T002        mutates=(new)
- T006  files=extensions/git/install.sh                                deps=T005        mutates=.specify/extensions.yml
- T007  files=extensions/git/uninstall.sh                              deps=T006        mutates=.specify/extensions.yml
- T008  files=extensions/git/extension/scripts/branch.sh              deps=T001        mutates=(new)
- T009  files=extensions/git/extension/scripts/commit.sh              deps=T008        mutates=(new)
- T010  files=.claude/skills/speckit-implement-parallel/SKILL.md       deps=T009,T013   mutates=.claude/skills/speckit-implement-parallel/SKILL.md
- T011  files=extensions/git/extension/scripts/sha.sh                 deps=T001        mutates=(new)
- T012  files=extensions/git/extension/scripts/gates.sh              deps=T011        mutates=(new)
- T013  files=extensions/git/extension/scripts/verify-gate.sh         deps=T011,T012   mutates=(new)
- T014  files=extensions/git/extension/scripts/on-council-approve.sh  deps=T012        mutates=(new)
- T015  files=.claude/skills/speckit-tasks/SKILL.md,.claude/skills/speckit-implement/SKILL.md   deps=-   mutates=.claude/skills/speckit-tasks/SKILL.md,.claude/skills/speckit-implement/SKILL.md
- T016  files=extensions/git/extension/scripts/cleanup.sh            deps=T001        mutates=(new)
- T017  files=extensions/git/skills/speckit-git-cleanup/SKILL.md       deps=T016        mutates=(new)
- T018  files=specs/002-speckit-ext-git/implement.log.md,docs/90-DECISIONS-AND-IDEAS.md   deps=T010   mutates=docs/90-DECISIONS-AND-IDEAS.md
- T019  files=specs/002-speckit-ext-git/graphify-context.md            deps=-           mutates=specs/002-speckit-ext-git/graphify-context.md
- T020  files=.claude/skills/speckit-specify/SKILL.md,specs/002-speckit-ext-git/graphify-context.md   deps=T019   mutates=.claude/skills/speckit-specify/SKILL.md,specs/002-speckit-ext-git/graphify-context.md
- T021  files=extensions/git/test/run.sh                               deps=T006,T010,T014   mutates=(new)
- T022  files=extensions/git/test/run.sh                               deps=T020,T021   mutates=extensions/git/test/run.sh
- T023  files=specs/002-speckit-ext-git/quickstart.md                  deps=T007,T010,T015,T016,T021   mutates=(none — validation run)

### Shared-file serialization

- `.specify/extensions.yml` (the single graph-grounded shared/mutable file) — touched by **T006** (install merge) and **T007** (uninstall deregister); both are orchestrator glue, pinned serial, never co-scheduled with each other or any parallel wave.
- `specs/002-speckit-ext-git/graphify-context.md` — touched by **T019** (manifest correction, wave 10) and **T020** (before_specify fix, wave 11) → consecutive serial waves, never co-scheduled.
- `extensions/git/test/run.sh` — authored by **T021** (wave 12), extended by **T022** (wave 13) → serialized (T022 after T021).
- Stock-skill edits (**T010** `implement-parallel`, **T015** `tasks`+`implement`, **T020** `specify`) touch **distinct** files → parallelizable among themselves; none is on the graph-grounded shared/mutable list.
