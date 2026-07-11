# Tasks: The Workforce Pair — Task Categorization & Agent Assembly

**Input**: Design documents from `specs/003-workforce/` (plan.md @`5ca7957`, spec.md, research.md, data-model.md, contracts/commands.md, quickstart.md)

**Architecture**: **one** `extensions/workforce/` extension exposing **three** commands — `/speckit-categorize`, `/speckit-agent-assign`, `/speckit-workforce-approve` (S10/S13) — plus a seed library (7 bases + 5 skills), a git-ext own-source generalization (S02), and the D62 deck-prep improvement. Tests are in scope (the plan mandates committed per-SC tests, S12).

**Grounding**: [graphify-context.md](./graphify-context.md) (D59 baseline). All source is **new code** (no existing graph nodes), so `[P]` is derived from **file-disjointness** (I-13 fallback); the one high-collision file `.specify/extensions.yml` is touched only by the installer's `flock`/atomic-rename hook-merge (S06), never co-scheduled. The git-ext and council-ext own-source edits (T018–T020, T030) touch **existing** files and are serialized.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: file-disjoint from every other task in its wave, no dependency → parallel-safe.
- **[Story]**: US1 (categorize) · US2 (assemble + gate) · US3 (skill builder / flywheel) · US4 (implement consumes + traces).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Stand up the single `extensions/workforce/` tree (the `extensions/<name>/` sibling pattern, mirroring `extensions/council/`).

- [X] T001 Scaffold the `extensions/workforce/` source tree: `extension/{commands,scripts,templates}/`, `seed/{agents,skills}/`, `skills/`, `test/`, and the top-level `README.md` placeholder. Per plan § Project Structure.
- [X] T002 [P] Author `extensions/workforce/extension/extension.yml` — registers the **3 commands** (`speckit.categorize`, `speckit.agent-assign`, `speckit.workforce-approve`) and declares the `after_categorize` / `after_agent-assign` / `after_workforce_approve` **fire-points** dispatched by the installed registry (S25).
- [X] T003 [P] Author `extensions/workforce/extension/workforce-config.yml` — `general_cap: 0.20`, `assembly_cap: 3`, `model: sonnet`, `taxonomy: docs/contracts/taxonomy-v0.md`, the `seed_library` manifest (7 bases + 5 skills), and **`skill_builder.web_search: true`** (D60 — the first elevated grant).

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: the shared parser + seed library + installer block ALL story work. No story begins until Phase 2 is complete.

- [X] T004 Author `extensions/workforce/extension/scripts/frontmatter.py` — the **one shared** closed-shape `specseyal:` parser (S21), stdlib-only, `body_sha256` per `agent-library-schema.md` §2; imported by both `assemble.py` and `validate-skill.py`. (No new runtime — Python 3 via graphify, S19.)
- [X] T005 [P] Unit-test `frontmatter.py` independently in `extensions/workforce/test/test_frontmatter.py` (S21 — the shared parser is the one place a silent divergence would poison both scripts).
- [X] T006 [P] Author the **7 seed base specialists** `extensions/workforce/seed/agents/agt-*.md` (all `model: sonnet`, core toolset, no tags; `agt_backend_service` + `agt_data_persistence` carry **`provisional: true`**, S11; the type-coverage matrix holds, S16). Per plan § Seed Library.
- [X] T007 [P] Author the **5 seed skills** `extensions/workforce/seed/skills/*/SKILL.md` (all **`grants: []`**); **relocate `refactor-discipline`** from `specs/000-sample/.claude/skills/` into the seed set (it lives in the repo-root library, outside any install `rm -rf` payload — S07).
- [X] T008 Author `extensions/workforce/install.sh` — copy source → `.specify/extensions/workforce/` + skills → `.claude/skills/`; seed the library **additively and OUTSIDE the `rm -rf` payload** (S07); deregister-first; the `.specify/extensions.yml` hook-merge under **`flock`/atomic write-to-temp+rename** (S06); documented install order **git before workforce** (S06/S25).
- [X] T009 [P] Author `extensions/workforce/uninstall.sh` — deregister-first, mirroring the git/council uninstallers.

**Checkpoint**: parser + seed library + installer ready — stories can begin.

---

## Phase 3: User Story 1 — Categorizer (Priority: P1) 🎯 MVP

**Goal**: `/speckit-categorize` tags every task by taxonomy v0 and fails loudly over the 20% `general` cap.
**Independent Test**: run the categorizer on a real `tasks.md` → a valid `categorization.md`; an over-cap fixture writes nothing and exits non-zero.

- [X] T010 [P] [US1] Author `extensions/workforce/extension/templates/categorizer-prompt.md` — the Sonnet `categorizer` session prompt: `type`/`preserves_behavior` mechanical from graphify signals, `specialization` interpretive from plan+domain; records the source `tasks.md` SHA (S14).
- [X] T011 [US1] Author `extensions/workforce/extension/scripts/validate-categorization.py` (imports `frontmatter.py`) — **code-validates** coverage + closed-enum membership (SC-001/S05) **and** the `count(general) ≤ 0.20 × count(tasks)` cap; on breach **exit non-zero and write nothing** (FR-004/SC-002/S22).
- [X] T012 [US1] Author the `/speckit-categorize` command — `extension/commands/speckit.categorize.md` + `skills/speckit-categorize/SKILL.md`: dispatch the `categorizer` session, run the validator, write `categorization.md` **only** on pass (D37; never mutates `tasks.md`); append one `categorizer` trace.
- [X] T013 [P] [US1] Committed categorize tests in `extensions/workforce/test/test_categorize.sh` + fixtures: an **over-cap** fixture asserts **non-zero exit AND file-absence** (SC-002/S22); a malformed/out-of-enum fixture asserts FAIL (SC-001).

**Checkpoint**: US1 categorizer functional and independently testable.

---

## Phase 4: User Story 2 — Assembler + workforce gate (Priority: P1)

**Goal**: `/speckit-agent-assign` proposes the roster deterministically; `/speckit-workforce-approve` records the human signature and binds the gate.
**Independent Test**: assemble twice over the same `categorization.md` + library → byte-identical roster; a human `approved` section unlocks implement.

- [X] T014 [US2] Author `extensions/workforce/extension/scripts/assemble.py` (imports `frontmatter.py`) — `agent-library-schema.md` §3 verbatim: base by `(type, specialization)` (∅ ⇒ `agt_generic` + empty-lane note, FR-016); tag-Jaccard rank → `success_rate` → `version` → `id`; force `refactor-discipline` on `preserves_behavior`; inject first-3, **log dropped** (SC-004); **grant union TOTAL-ORDERED before serialize** (S01); **D48 guard** — `prompt`⇒Sonnet base else **hard-error** (FR-014); mark `library`/`built` (FR-022); **write the roster itself** — the `### Roster approved` sub-table under `## Workforce Gate` (S08), **never** the reviewer/decision/reviewed fields, which are `/speckit-workforce-approve`'s alone (T017) — principle-I within-file boundary; **stamp the library-snapshot hash** (S18). The Elevated-grants column surfaces **`web_search`** on any row whose assembly injects a web_search-declaring skill (D60).
- [X] T015 [P] [US2] Author `extensions/workforce/extension/templates/assignment.template.md` — the `agents/assignment.md` shell: roster table + `## Workforce Gate` in the `artifact-layout.md` §8 / I-12 format (mandatory Model + Elevated-grants columns).
- [X] T016 [US2] Author the `/speckit-agent-assign` command — `extension/commands/speckit.agent-assign.md` + `skills/speckit-agent-assign/SKILL.md`: check `categorization.md` freshness vs `tasks.md` SHA (hard-warn + re-categorize on drift, S14); run `assemble.py`; emit roster + **gap list** (no builder yet — US2 is viable against the static seed library); write `agents/assignment.md`, leaving `## Workforce Gate` pending the signature.
- [X] T017 [US2] Author the `/speckit-workforce-approve` command — `extension/commands/speckit.workforce-approve.md` + `skills/speckit-workforce-approve/SKILL.md`: record **only** reviewer · `decision ∈ {approved, approved-with-notes, rejected}` · reviewed in `## Workforce Gate` (§8) — never the `### Roster approved` sub-table, which is `assemble.py`'s (T014); fire `after_workforce_approve`; mechanical, **no session/trace** (mirrors `/speckit-council-approve`); signer-agnostic auto codepath (FR-010/W4).
- [X] T018 [US2] **git-ext own source (D57 S2)**: generalize `extensions/git/extension/scripts/on-council-approve.sh` → gate-agnostic **`on-gate-approve.sh`** taking a `{council|workforce}` arg → `gates.sh write <gate>` (S02). `gates.sh` already knows the `workforce` artifact set (`tasks.md`+`assignment.md`) — no change there.
- [X] T019 [US2] **git-ext own source**: register `after_workforce_approve` → `on-gate-approve.sh workforce` in `extensions/git/extension/extension.yml` (mirrors the existing `after_council_approve`). (depends on T018)
- [ ] T020 [US2] **Reinstall git-ext** and add the **reinstall-survival regression** to `extensions/git/test/run.sh`: assert **both** gate wirings fire after reinstall — `after_council_approve` (council) **and** `after_workforce_approve` (workforce → `gates.yml` gets `tasks.md`+`assignment.md@sha`) (S02/S07/S17). (depends on T018, T019)
- [X] T021 [P] [US2] Committed **assembly golden tests** in `extensions/workforce/test/test_assemble.sh` + a frozen library snapshot: **byte-identical roster including grant ORDER** on a double run (SC-005/S01); a **synthetic non-Sonnet fixture base** so the D48 guard's `else: hard-error` branch executes (SC-006/S03); a **>3-candidate** task (SC-004); a **≥2-grant-declaring-skills** grant-union correctness case (SC-003/S09); a **≥2-task one-gap** gap-rerun stability case (S15).

**Checkpoint**: US1 + US2 = the viable pair against the static seed library; the human can sign and unlock implement.

---

## Phase 5: User Story 3 — Skill builder / flywheel (Priority: P2)

**Goal**: a ∅-match grows the library by one additive-only `SKILL.md`, not a bespoke agent.
**Independent Test**: a novel-tag task → exactly one persisted `SKILL.md` (`origin: generated`, `source_feature` set), additive-only, tags ∩ the triggering task's tags.

- [X] T022 [P] [US3] Author `extensions/workforce/extension/templates/skill-builder-prompt.md` — the Sonnet `skill-builder` (`agent-creator`) session prompt; **declares `grants: [web_search]`** in its skill-module frontmatter (D60/A-2); stamps `provenance.stale_risk: true` when authoring a post-cutoff framework **without** searching (S17).
- [X] T023 [P] [US3] Author `extensions/workforce/extension/templates/skill-module.template.md` — the generated-`SKILL.md` shell (`skl_` id, semver, `origin: generated`, `provenance.source_feature`, `taxonomy.tags`, `grants`).
- [X] T024 [US3] Author `extensions/workforce/extension/scripts/validate-skill.py` (imports `frontmatter.py`) — `skill-module.md` **S1–S3** (additive-only) **plus S04**: the generated skill's tags **MUST intersect** the triggering task's tags; `skl_` id unique, semver, `grants` disjoint from the core toolset; `origin`→`source_feature` rule.
- [X] T025 [US3] Wire the ∅-match handoff into `/speckit-agent-assign` (edit `speckit.agent-assign.md`): for each gap dispatch the `skill-builder` (with its `web_search` grant) → `validate-skill.py` → persist to `.claude/skills/` (`origin: generated`, `source_feature: 003-workforce`); **check the live `.claude/skills/` listing and hard-fail/rename on collision** (S07); then **re-run `assemble.py`** — stable, only the gap row changes (S15). (depends on T016, T022, T024)
- [ ] T026 [P] [US3] Committed skill-builder tests in `extensions/workforce/test/test_skill_builder.sh` + fixtures: an additive-only **violation is rejected**, not persisted (FR-007/S9); **two tasks sharing one novel tag → exactly one** persisted skill, not one-per-task (SC-007/S24); a tags-miss is rejected (S04). (depends on T024, T025)

**Checkpoint**: the flywheel closes; the long tail is covered.

---

## Phase 6: User Story 4 — Implementation consumes the roster, every dispatch auditable (Priority: P2)

**Goal**: `/speckit-implement-parallel` dispatches each assembled agent; every trace carries the approved assembly.
**Independent Test**: an approved `assignment.md` → each per-task trace carries `skills: [{id,version}]` + `elevated_grants: [...]` matching its roster row.

- [ ] T027 [US4] Wire the assembly into implement dispatch traces: `/speckit-implement-parallel` reads the approved `agents/assignment.md` roster and each dispatch trace carries `skills[]` + `elevated_grants[]`, `agent_id` = the base (FR-021/D43); a builder dispatch that searched records `elevated_grants: ["web_search"]` (D60). **Cross-extension seam** — implement-parallel is graphify-owned; couple via the roster **artifact** and keep the edit in graphify's **source** (D57 §9). (depends on T016, T017, T025)
- [ ] T028 [P] [US4] Author the committed **trace↔roster diff script** `extensions/workforce/test/trace-roster-diff.sh` — mechanically diffs each dispatch trace's `skills[]`/`elevated_grants[]` against its approved roster row (SC-008/S23, replaces human inspection). (depends on T027)

**Checkpoint**: the loop is closed; the grant approval is auditable end-to-end.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T029 Author `extensions/workforce/test/run.sh` — the one harness (git-ext model, D57 S3): install → reinstall-survival → the deterministic-assembly golden test → validator unit checks → the committed per-SC tests. (aggregates T005, T013, T021, T026, T028)
- [ ] T030 [P] **D62 deck-prep improvement (council own source, D57 S2)**: mine round-1's five member transcripts for which `plan.md` sections the readers pulled, then enrich the deck-prep template in `extensions/council/extension/templates/` so those high-demand sections ride in the technical deck by default; **reinstall council**. After-metric: `plan.md` read-rate at the next council run (target: majority of the bench trusts the deck).
- [ ] T031 [P] Author the workforce-extension docs — `extensions/workforce/README.md` + `extension/README.md` (packaging, the three commands, the D60 grant, the S02 seam).
- [ ] T032 Run `quickstart.md` scenarios S1–S12 and the **SC-009 dogfood exit** on `003` itself (`categorize → assign → workforce-gate → implement-parallel`). The M3 exit criterion. (depends on T029, T020, T027)

---

## Dependencies & Execution Order

- **Setup (T001–T003)**: T001 first; T002/T003 parallel after.
- **Foundational (T004–T009)**: blocks all stories. `frontmatter.py` (T004) blocks the three scripts (T011/T014/T024). Seed (T006/T007) blocks `assemble.py` (T014) + `install.sh` (T008).
- **US1 (T010–T013)** and **US2 (T014–T021)** are independent after Foundational; **US2 is viable without the builder** (the static-library path). The git-ext generalization T018→T019→T020 is a serial chain.
- **US3 (T022–T026)** extends US2's assign command (T025 edits T016's file → serial after T016).
- **US4 (T027–T028)** depends on the assign/approve/handoff being in place.
- **Polish (T029–T032)**: T029 aggregates the test tasks; T032 (SC-009 dogfood) is last.

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries, [P] markers,
> TDD/dependency ordering, and file-disjointness (all-new code — no graph nodes, so [P] = disjoint
> files, I-13). Setup + Foundational are serial barriers; parallelism is cross-story. The git-ext /
> council-ext own-source edits touch EXISTING files and are serialized; the installer's
> `.specify/extensions.yml` hook-merge (T008) is never co-scheduled with another registry-touching task.

- Wave 1 [serial]   : T001                                   # scaffold the tree (everything lives in it)
- Wave 2 [parallel] : T002, T003                             # extension.yml, workforce-config.yml (disjoint)
- Wave 3 [parallel] : T004, T006, T007, T009, T010, T015, T022, T023   # shared parser + seed + leaf templates (all deps=T001)
- Wave 4 [parallel] : T005, T008, T011, T014, T024           # tests+scripts over the parser/seed (deps T004/T006/T007)
- Wave 5 [parallel] : T012, T016, T017, T018, T021           # commands + git-ext generalize + assembly golden tests
- Wave 6 [parallel] : T013, T019, T025                        # categorize tests; git-ext hook register; gap-handoff wiring
- Wave 7 [serial]   : T020                                   # reinstall git-ext + survival regression (touches .specify)
- Wave 8 [parallel] : T026, T027, T030, T031                 # skill-builder tests; trace wiring (graphify seam); D62 deck-prep; docs
- Wave 9 [parallel] : T028, T029                              # trace↔roster diff script; aggregate test/run.sh
- Wave 10 [serial]  : T032                                   # SC-009 dogfood exit on 003 itself (the M3 exit)

### Task annotations
- T001  files=extensions/workforce/**                                          deps=-              mutates=(new)
- T002  files=extensions/workforce/extension/extension.yml                      deps=T001           mutates=(new)
- T003  files=extensions/workforce/extension/workforce-config.yml              deps=T001           mutates=(new)
- T004  files=extensions/workforce/extension/scripts/frontmatter.py            deps=T001           mutates=(new)
- T005  files=extensions/workforce/test/test_frontmatter.py                     deps=T004           mutates=(new)
- T006  files=extensions/workforce/seed/agents/agt-*.md (7)                     deps=T001           mutates=(new)
- T007  files=extensions/workforce/seed/skills/*/SKILL.md (5)                   deps=T001           mutates=(new; refactor-discipline relocated from specs/000-sample/)
- T008  files=extensions/workforce/install.sh                                   deps=T001,T006,T007 mutates=(new; runtime merges .specify/extensions.yml via flock/atomic-rename, S06)
- T009  files=extensions/workforce/uninstall.sh                                 deps=T001           mutates=(new)
- T010  files=extensions/workforce/extension/templates/categorizer-prompt.md    deps=T001           mutates=(new)
- T011  files=extensions/workforce/extension/scripts/validate-categorization.py deps=T004           mutates=(new)
- T012  files=extensions/workforce/extension/commands/speckit.categorize.md, extensions/workforce/skills/speckit-categorize/SKILL.md  deps=T010,T011  mutates=(new)
- T013  files=extensions/workforce/test/test_categorize.sh (+fixtures)          deps=T011,T012      mutates=(new)
- T014  files=extensions/workforce/extension/scripts/assemble.py                deps=T004,T006,T007 mutates=(new)
- T015  files=extensions/workforce/extension/templates/assignment.template.md   deps=T001           mutates=(new)
- T016  files=extensions/workforce/extension/commands/speckit.agent-assign.md, extensions/workforce/skills/speckit-agent-assign/SKILL.md  deps=T014,T015  mutates=(new)
- T017  files=extensions/workforce/extension/commands/speckit.workforce-approve.md, extensions/workforce/skills/speckit-workforce-approve/SKILL.md  deps=T015  mutates=(new)
- T018  files=extensions/git/extension/scripts/on-gate-approve.sh               deps=-              mutates=extensions/git/extension/scripts/on-council-approve.sh (RENAME+parameterize, git own source)
- T019  files=extensions/git/extension/extension.yml                            deps=T018           mutates=extensions/git/extension/extension.yml (register after_workforce_approve)
- T020  files=extensions/git/test/run.sh                                        deps=T018,T019      mutates=.specify/extensions/git/** (reinstall) — SERIAL
- T021  files=extensions/workforce/test/test_assemble.sh (+frozen snapshot)     deps=T014           mutates=(new)
- T022  files=extensions/workforce/extension/templates/skill-builder-prompt.md  deps=T001           mutates=(new; declares grants:[web_search] D60, stale_risk S17)
- T023  files=extensions/workforce/extension/templates/skill-module.template.md deps=T001           mutates=(new)
- T024  files=extensions/workforce/extension/scripts/validate-skill.py          deps=T004           mutates=(new)
- T025  files=extensions/workforce/extension/commands/speckit.agent-assign.md   deps=T016,T022,T024 mutates=extensions/workforce/extension/commands/speckit.agent-assign.md (edit — serial after T016)
- T026  files=extensions/workforce/test/test_skill_builder.sh (+fixtures)       deps=T024,T025      mutates=(new)
- T027  files=extensions/graphify/skills/speckit-implement-parallel/SKILL.md    deps=T016,T017,T025 mutates=extensions/graphify/... (cross-extension seam, D57) — SERIAL
- T028  files=extensions/workforce/test/trace-roster-diff.sh                     deps=T027           mutates=(new)
- T029  files=extensions/workforce/test/run.sh                                   deps=T005,T013,T021,T026,T028  mutates=(new)
- T030  files=extensions/council/extension/templates/<deck-prep>                 deps=-              mutates=extensions/council/... (council own source, D57 S2) + reinstall council
- T031  files=extensions/workforce/README.md, extensions/workforce/extension/README.md  deps=T001   mutates=(new)
- T032  files=specs/003-workforce/quickstart.md (validation run)                 deps=T029,T020,T027 mutates=- (dogfood run, no source write)

### Shared-file serialization
- `.specify/extensions.yml` (the hook registry, the single highest-collision file, S06) — touched only by `install.sh` (T008) and the git-ext reinstall (T020) at **runtime**, via `flock`/atomic-rename; never two authoring tasks co-scheduled on it.
- `.claude/skills/` — the skill-builder writes generated `SKILL.md`s here (T025, runtime) and installers seed it (T007/T008); the persistence path lives OUTSIDE the install `rm -rf` payload (S07), so runtime writes and reinstalls don't collide.
- `extensions/git/extension/{scripts,extension.yml}` (T018/T019/T020) — existing git-ext source; serialized as a chain (own-source edit, D57 S2).
- `extensions/workforce/extension/commands/speckit.agent-assign.md` (T016 then T025) — same file; T025 edits it, serial after T016.
- `extensions/graphify/skills/speckit-implement-parallel/SKILL.md` (T027) — existing graphify source (cross-extension seam); serial.
