# Tasks: Optional pptx Render of the Defense Deck

**Input**: Design documents from `/specs/006-deck-render/`

**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/commands.md ✓, quickstart.md ✓

**Council carried-constraints applied**: R1-S01…S14, S17 (see `council/decision-record.md` §Carried Constraints). Every accepted blocking/strong suggestion maps to a task below.

**Tests**: Explicitly requested — the spec's 10 Success Criteria + 16 Functional Requirements and the plan's Phase C ("the falsifiable checks… the bulk of the test work") mandate a committed `test/run.sh` with per-branch fixtures. Test tasks are therefore first-class, not optional.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel — different files, no dependency. Verified against disjoint file sets (graph absent — see the degradation note in `## Execution Waves`).
- **[Story]**: US1 / US2 / US3, or `[cross]` for boundary/reinstall concerns that serve all three.
- Exact file paths are in every description.

## Path Conventions

Single project, `extensions/` layout (plan.md §Project Structure). The entire feature is one new extension at `extensions/deck-render/`, plus five edits outside it (`.gitignore`, two `docs/contracts/*`, `specs/000-sample/profile.yaml`, `docs/90`).

---

## Phase 1: Setup — the seam and the contracts (plan Phase A)

**Purpose**: Scaffold the zero-hook extension and land the contract amendments that admit the `deck_render` key. Plan Phase A: "must land first; everything else depends on the key existing."

- [X] **T001** Scaffold the extension tree `extensions/deck-render/` (dirs: `extension/{commands,scripts}`, `skills/speckit-deck-render/`, `test/fixtures/`) and author `extensions/deck-render/README.md` describing the feature, the zero-hook seam (FR-008/FR-012), and the optional/lazy `python-pptx` posture (FR-015).
- [X] **T002** [P] Author `extensions/deck-render/extension/extension.yml` — the manifest declaring **zero hooks** (R8/FR-012), following the `extensions/testing/extension/extension.yml` precedent.
- [X] **T003** [P] Author `extensions/deck-render/install.sh` — copies payload → `.specify/extensions/deck-render/`, skill → `.claude/skills/`, and registers in `.specify/extensions.yml`'s `installed:` list using **`testing`'s flock + tempfile + `os.replace` atomic merge** (NOT git's unlocked write). Never requires `python-pptx`.
- [X] **T004** [P] Author `extensions/deck-render/uninstall.sh` — **deregister from `installed:` FIRST**, then remove payload + skill; must round-trip `.specify/extensions.yml` byte-identically (the `testing` model; verified by T034).
- [X] **T005** [P] Author `extensions/deck-render/extension/commands/speckit.deck-render.md` — the command provenance source (contracts/commands.md §1 signature: `[technical|overview|both] [--feature <dir>] [--validate-profile]`).
- [X] **T006** [P] Author `extensions/deck-render/skills/speckit-deck-render/SKILL.md` — a **thin wrapper**: resolves the feature dir and shells out to `render.py`; reads no deck content, invokes no model (FR-011, R9).
- [X] **T007** [P] Add `specs/*/renders/` to `.gitignore` (FR-014; makes SC-005's `git ls-files` true).
- [X] **T008** [P] Amend `docs/contracts/profile-schema.md` → **1.2**: add `deck_render` to the §1 schema, the §3 field table (closed enum `{none,technical,overview,both}`, default `none`, out-of-enum ⇒ validation error), §5 examples, and a new §8 (FR-005).
- [X] **T009** [P] Amend `docs/contracts/artifact-layout.md` → **1.5**: add `renders/` to §1 marked **GITIGNORED**, and a §6 writer row **deck-render → `renders/` and nothing else** (FR-014).
- [X] **T010** [P] Add `deck_render: none` to `specs/000-sample/profile.yaml` — the canonical fixture moves **in the same commit** as T008 (contract-change discipline, D47/D59).
- [X] **T011** [P] Reconcile the render-write + exit contract to the council-bound plan: amend `specs/006-deck-render/contracts/commands.md` (§1/§2/§4 the **unreadable/unparseable** case ⇒ **exit 3** (+ `data-model.md` §1 ladder V5) — landed pre-implement via analyze C1/U1; verify still present, per I-B1/S01; §4 map **all six** `both` per-deck-pair outcomes incl. `rendered+skipped⇒0`, `failed+skipped⇒2`, per I-B4/S05; **§2.4c replace "remove existing target before attempting" with the atomic temp-file + `os.replace`-on-success write** per I-B3/S04) **and** update `specs/006-deck-render/data-model.md` §5 **O5** to match (prior good render untouched on failure; staleness defended by the stamp + FRESH/STALE verdict, not by pre-deletion). ⚠️ Resolves the O5-vs-I-B3 write-semantics contradiction (analyze I1); the unreadable-branch contradiction (C1) + exit-code pin (U1) were reconciled ahead of this task.
- [X] **T012** [P] Record in `docs/90-DECISIONS-AND-IDEAS.md` the `006` D-row and the I-rows R4 booked (no general `profile.yaml` validator; `reopen_tier` is a dead key with zero consumers; `artifact-layout.md` §7's conformance checker unbuilt). Idempotent — add only what's missing.

**Checkpoint**: `deck_render` is admitted to the contract; the extension skeleton exists; `renders/` is gitignored. Foundational work can begin.

---

## Phase 2: Foundational — the deterministic transform (plan Phase B)

**Purpose**: The three scripts that are the feature's whole substance, plus the shared test infrastructure. **BLOCKS all user stories** — every story's checks exercise `render.py`.

**⚠️ CRITICAL**: No user-story test can run until `render.py` and the harness exist.

- [X] **T013** [P] Implement `extensions/deck-render/extension/scripts/deck_md.py` — markdown → ordered **block model** over the narrow census set (data-model.md §2: H1–H3, 2–5-col tables, bare/`text` fences with box-drawing preserved, flat bullets, numbered items, leading blockquotes, `---` HRs). Stdlib only, no deps. **Loud failure on any construct outside the set** — never a silent simplification (T10).
- [X] **T014** [P] Implement `extensions/deck-render/extension/scripts/profile_key.py` — the **single canonical source** of the closed enum `{none,technical,overview,both}`, exported (S12). Three-branch resolution (I-B1/S01): absent ⇒ `none`; out-of-enum (incl. mapping/list/empty) ⇒ fail, exit 3, write nothing; **unreadable/unparseable YAML ⇒ loud non-`none` failure, write nothing** — never folded into silent `none`. Standalone-runnable via `--validate-profile` (exit 0 valid/absent, exit 3 out-of-enum). Stdlib YAML-reading via the installers' interpreter ladder (003 R2).
- [X] **T015** Implement `extensions/deck-render/extension/scripts/render.py` — the integrating transform (depends on T013, T014). Carries **every** Phase-B invariant: T1–T10 blocks→slides in **source order**; full 64-hex sha256 derived-render stamp on the title slide + abbreviated footer stamp on every slide (I-B5/S09); selection resolution (explicit arg > profile > `none`, FR-016); **lazy `import pptx` inside the render fn** → `ImportError` routes to degrade-and-disclose (FR-015, R2); **atomic write** — temp file in target dir then `os.replace` only on full success (I-B3/S04); **per-deck isolation** — an exception on deck N never prevents deck N+1 (I-B2/S03); per-deck disclosure + exit codes 0/2/3/4 (I-B4/S05); **`FRESH`/`STALE` stdout verdict** when a prior render exists, stateless read-and-compare (I-B6/S13). Never writes under `council/`, never touches a `.md`, never writes `traces.jsonl` (I1–I7).
- [X] **T016** [P] Implement `extensions/deck-render/test/extract_pptx_text.py` — the **independent** stdlib OOXML text extractor (`zipfile` + `xml.etree` over every `<a:t>` run in `ppt/slides/*.xml`), NOT a `python-pptx` round-trip (R5). Shared test infra for the fidelity, stamp, and staleness checks.
- [X] **T017** Scaffold `extensions/deck-render/test/run.sh` — POSIX sh harness with PASS/FAIL counters and throwaway temp dirs (git/testing `run.sh` model). **Detect `python-pptx` presence up front**: the SC-003 fidelity arm MUST hard-fail with an "install python-pptx" demand + non-zero exit when absent, never a silent exit 0 (S10). (Depends on T001 for the tree.)

**Checkpoint**: The transform renders and the harness runs. User-story checks can now be added.

---

## Phase 3: User Story 1 — a presentable, stamped, faithful overview deck (Priority: P1) 🎯 MVP

**Goal**: Rendering `overview.md` yields a viewer-openable pptx that carries every claim of the markdown and no others, stamped on its face as a derived render.

**Independent Test**: `pip install python-pptx`; render a real `overview.md`; the file opens in a viewer, passes bidirectional fidelity, and shows the full-64-hex stamp.

- [ ] **T018** [P] [US1] Commit the **frozen golden fixture deck** `extensions/deck-render/test/fixtures/deck/{technical.md,overview.md}`, seeded from `005`'s heaviest real deck (201 lines, 38-row tables, H3s, a box-drawing fence). **Confirm it exceeds T7's per-slide line budget** — extend a cell until it does — so the `(cont.)` branch is forced (S08); record provenance in the fixture dir.
- [ ] **T019** [US1] Add the **SC-003 fidelity** section to `test/run.sh`: bidirectional containment via `extract_pptx_text.py` — (a) nothing dropped, (b) nothing invented beyond the stamp/`(cont.)`/slide-number allowlist — asserting **block sequence, not just presence** (S06); whitespace-only normalization (Unicode never folded). Hard-fails if `python-pptx` absent (S10). (Depends on T015, T016, T017, T018.)
- [ ] **T020** [US1] Add the **SC-002 / FR-003 stamp** section to `test/run.sh`: assert the title slide carries the full **64-hex** sha256 stamp (declaration + source path + SHA + pointer) and **every** slide's footer carries the abbreviated stamp (I-B5). Annotate the one irreducibly manual step — SC-002 "opens in a viewer" (quickstart Scenario 3) — as manual, not silently asserted. (Depends on T015, T016, T017.)
- [ ] **T021** [US1] Add the **T7 overflow** section to `test/run.sh`: assert the fixture deck reaches the `(cont.)` continuation branch and the split is deterministic (S08 — the mitigation for the risk register's one High-likelihood row). (Depends on T015, T017, T018.)

**Checkpoint**: The MVP renders faithfully and self-labels. US1 is independently testable.

---

## Phase 4: User Story 2 — off unless asked, per deck, with a closed enum (Priority: P1)

**Goal**: A feature that says nothing renders nothing; a typo'd value fails loudly; an explicit invocation overrides the profile.

**Independent Test**: Run against a no-key profile and a `none` profile → zero files, `council/` byte-identical; run against `sparkle` → exit 3.

- [ ] **T022** [P] [US2] Commit the profile fixtures `extensions/deck-render/test/fixtures/profiles/{none,overview,both,invalid,unreadable,absent-key}.yaml` — `invalid` = out-of-enum, `unreadable` = unparseable YAML (distinct fixtures, per I-B1/S01).
- [ ] **T023** [US2] Add the **SC-001 default-path** section to `test/run.sh`: `none` and absent-key both produce zero files, zero output difference, and a `council/` subtree byte-identical to pre-006 (FR-007/FR-013/FR-016). (Depends on T015, T017, T022.)
- [ ] **T024** [US2] Add the **SC-008 enum** section to `test/run.sh`: out-of-enum ⇒ exit 3, nothing written; **unreadable/unparseable ⇒ loud non-`none` failure, nothing written** (I-B1); `--validate-profile` returns the same codes. (Depends on T014, T015, T017, T022.)
- [ ] **T025** [US2] Add the **FR-016 explicit-override** section to `test/run.sh`: an explicit deck argument renders regardless of the profile, **including when the profile says `none`** — the boundary (derived/un-bound/un-traced/gitignored) unchanged. (Depends on T015, T017, T022.)
- [ ] **T026** [US2] Add the **enum SSOT drift** section to `test/run.sh`: read `profile_key.py`'s exported enum and assert `profile-schema.md`'s §1/§3 list and `contracts/commands.md`'s exit table match it; **fail on divergence** (S12 — closes the `council_tier: standrad` drift shape). (Depends on T014, T017, T008, T011.)

**Checkpoint**: The default path is provably inert; the enum is closed and single-sourced.

---

## Phase 5: User Story 3 — a render failure never blocks the gate (Priority: P1)

**Goal**: Missing toolchain, unrenderable markdown, disk-full, mid-write crash — the gate stays reachable, no `.md` is touched, and the human is told per deck.

**Independent Test**: Force `ImportError` on a `both` run → phase completes, gate reachable, every `council/` `.md` byte-identical, per-deck disclosure printed.

- [ ] **T027** [P] [US3] Commit the **asymmetric fixture** `extensions/deck-render/test/fixtures/deck-broken/` — one good deck + one deliberately-unrenderable deck, for the exit-2 partial-failure branch (S02).
- [ ] **T028** [US3] Add the **SC-004 degrade** section to `test/run.sh`: force `ImportError` via a **`PYTHONPATH` shadow** `pptx/__init__.py` that raises — a real import failure, **no test-only backdoor in production code** (R6). Assert the phase completes, the gate is reachable, every `council/` `.md` is byte-identical, no partial `.pptx` is left, and the per-deck disclosure reaches the human. (Depends on T015, T017.)
- [ ] **T029** [US3] Add the **partial-failure exit-2** section to `test/run.sh`: run the asymmetric `deck-broken` pair under `both` and assert **render-good / fail-broken / disclose-both / exit 2** — the per-deck isolation invariant (I-B2/S03) made mechanical, replacing "verify by hand once" (S02). (Depends on T015, T017, T018, T027.)
- [ ] **T030** [US3] Add the **atomic mid-write failure** section to `test/run.sh`: force a failure **during** the transform/write (not the pre-write import check) and assert **no partial `.pptx` at the target path AND any prior good render untouched** — the only mode that would violate O5 (I-B3/S04). (Depends on T015, T017.)
- [ ] **T031** [US3] Add the **SC-007 staleness** section to `test/run.sh`: render, mutate the source, recompute the source sha256, assert it **mismatches** the stale render's embedded stamp, and assert the **`STALE`** verdict fires on stdout (I-B6/S07/S13). Fully mechanized — committed, not carried as an open question. (Depends on T015, T016, T017.)

**Checkpoint**: Every failure mode degrades-and-discloses; staleness is visible and actionable.

---

## Phase 6: Polish & Cross-Cutting — the boundary, the seam, the dogfood exit (plan Phase C boundary + Phase D)

**Purpose**: The grep-able boundary proofs, reinstall survival, and the `006` dogfood exit.

- [ ] **T032** [cross] Add the **SC-005 boundary** section to `test/run.sh`: no rendered file in `git ls-files`, in `specs/*/gates.yml`, in any `traces.jsonl` record, or in any council session's context-in (FR-001/FR-014). (Depends on T015, T017.)
- [ ] **T033** [cross] Add the **SC-006 free** section to `test/run.sh`: a rendered run's `council_spend` / `traces.jsonl` role-count is identical to an unrendered run's — zero model calls, zero tokens (FR-011). (Depends on T017.)
- [ ] **T034** [cross] Add the **SC-010 reinstall-survival** section to `test/run.sh` (the `extensions/git/test/run.sh` §3 model): install deck-render → **reinstall `council` and `graphify`** → the payload, skill, and `installed:` entry all survive and the command still fires; assert **no file under `extensions/council/` or `extensions/graphify/` was modified**; assert `uninstall.sh` round-trips `.specify/extensions.yml` byte-identically (FR-012/FR-013). (Depends on T003, T004, T017.)
- [ ] **T035** [cross] Add the **co-install** section to `test/run.sh` (S11): stand up a combined `005`+`006` `.specify/extensions.yml` and assert install/uninstall of `deck-render` round-trips it **byte-identically without disturbing `005`'s entries** — instrumenting the shared `installed:`-list merge point. (Depends on T003, T004, T017.)
- [ ] **T036** [US1] Execute the **SC-009 dogfood exit** (plan Phase D): render `006`'s own committed `council/defense-deck/overview.md` via the **explicit-invocation path** (`/speckit-deck-render overview --feature specs/006-deck-render`), producing gitignored `specs/006-deck-render/renders/overview.pptx`; open it (the manual viewer check). (Depends on T015 and a green suite.)
- [ ] **T037** [cross] Run the full **quickstart.md** walkthrough (all 9 scenarios) as the integration gate, confirming every SC (SC-001…SC-010) and FR (FR-001…FR-016) binds to an executed check; the two irreducibly manual steps (SC-002 / SC-009 "opens in a viewer") are named, not skipped. (Depends on all prior tasks.)

**Checkpoint**: The boundary holds mechanically, the seam survives reinstall, and the feature renders its own deck.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)** → no dependencies; the contract amendments (T008–T012) and `.gitignore` (T007) don't even need the scaffold. Serial barrier before Foundational.
- **Foundational (Phase 2)** → depends on Setup. `render.py` (T015) depends on `deck_md.py` (T013) + `profile_key.py` (T014). **BLOCKS all stories.**
- **US1 / US2 / US3 (Phases 3–5)** → each depends only on Foundational; mutually independent in *logic*, but their `run.sh` sections **serialize on the shared file** (see below).
- **Polish (Phase 6)** → depends on the relevant code + harness; T036/T037 depend on a green suite.

### The one shared/mutable serializer

`extensions/deck-render/test/run.sh` is appended to by **every** test task (T019–T035). They therefore **cannot be `[P]` with each other** regardless of story — they are pinned to serial waves. Real parallelism lives in Setup (12 disjoint files), Foundational (4 disjoint files), and fixture creation (3 disjoint sets).

### Within each story

- Fixtures before the assertions that consume them.
- `render.py` + harness before any assertion.

---

## Parallel Opportunities

- **Setup**: T002–T012 are 11 disjoint files — one wide parallel wave (T001 scaffolds the tree first).
- **Foundational**: T013, T014, T016, T017 are disjoint — parallel; then T015.
- **Fixtures**: T018, T022, T027 are disjoint fixture sets — parallel.
- **Test assertions**: *not* parallelizable — shared `run.sh`.

---

## Implementation Strategy

**MVP = US1.** Setup → Foundational → US1 (render faithfully + stamp), stop and validate against a real deck. US2 (default-off/enum) and US3 (degrade/disclose) then harden the safety envelope; Polish proves the boundary and dogfoods. Commit per the phase-tagged `after_tasks` → `after_implement` git hooks.

---

## Execution Waves

> Machine-readable DAG for `/speckit-implement-parallel`. Derived from phase boundaries, disjoint-file analysis, TDD ordering, and the council's carried constraints. **Graphify degradation (disclosed):** `graphify-out/graph.json` is absent for this clone (research.md — a full graph build was deliberately skipped for this S-sized, self-contained new extension). `[P]` was therefore verified by the **stock heuristic — disjoint `files=` sets + no stated dependency — not** by symbol-level blast radius. This is sound here because the extension imports only stdlib + its own two modules + lazily `pptx`; it has no edges into existing repo code. The sole shared/mutable file is `test/run.sh`.

- Wave 1  [serial]   : T001                                              # scaffold the tree everything lands in
- Wave 2  [parallel] : T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012   # 11 disjoint scaffold + contract + docs files
- Wave 3  [parallel] : T013, T014, T016, T017                            # deck_md.py · profile_key.py · extract_pptx_text.py · run.sh scaffold
- Wave 4  [serial]   : T015                                              # render.py (needs deck_md + profile_key)
- Wave 5  [parallel] : T018 [US1], T022 [US2], T027 [US3]                # disjoint fixture sets
- Wave 6  [serial]   : T019 [US1], T020 [US1], T021 [US1]                # US1 run.sh sections (shared file → serial)
- Wave 7  [serial]   : T023 [US2], T024 [US2], T025 [US2], T026 [US2]    # US2 run.sh sections
- Wave 8  [serial]   : T028 [US3], T029 [US3], T030 [US3], T031 [US3]    # US3 run.sh sections
- Wave 9  [serial]   : T032, T033, T034, T035                            # boundary + reinstall + co-install run.sh sections
- Wave 10 [serial]   : T036 [US1], T037                                  # dogfood exit, then full quickstart integration gate

### Task annotations

- T001  files=extensions/deck-render/README.md (+ dir tree)                          deps=-              mutates=(new)
- T002  files=extensions/deck-render/extension/extension.yml                         deps=-              mutates=(new)
- T003  files=extensions/deck-render/install.sh                                      deps=-              mutates=(new)
- T004  files=extensions/deck-render/uninstall.sh                                    deps=-              mutates=(new)
- T005  files=extensions/deck-render/extension/commands/speckit.deck-render.md       deps=-              mutates=(new)
- T006  files=extensions/deck-render/skills/speckit-deck-render/SKILL.md             deps=-              mutates=(new)
- T007  files=.gitignore                                                             deps=-              mutates=.gitignore
- T008  files=docs/contracts/profile-schema.md                                       deps=-              mutates=docs/contracts/profile-schema.md
- T009  files=docs/contracts/artifact-layout.md                                      deps=-              mutates=docs/contracts/artifact-layout.md
- T010  files=specs/000-sample/profile.yaml                                          deps=-              mutates=specs/000-sample/profile.yaml   # same commit as T008
- T011  files=specs/006-deck-render/contracts/commands.md, specs/006-deck-render/data-model.md   deps=-  mutates=both   # reconciles O5↔I-B3
- T012  files=docs/90-DECISIONS-AND-IDEAS.md                                         deps=-              mutates=docs/90-DECISIONS-AND-IDEAS.md
- T013  files=extensions/deck-render/extension/scripts/deck_md.py                    deps=-              mutates=(new)
- T014  files=extensions/deck-render/extension/scripts/profile_key.py                deps=-              mutates=(new)   # SSOT for the enum
- T015  files=extensions/deck-render/extension/scripts/render.py                     deps=T013,T014      mutates=(new)
- T016  files=extensions/deck-render/test/extract_pptx_text.py                       deps=-              mutates=(new)
- T017  files=extensions/deck-render/test/run.sh                                     deps=T001           mutates=(new)
- T018  files=extensions/deck-render/test/fixtures/deck/{technical.md,overview.md}   deps=-              mutates=(new)
- T019  files=extensions/deck-render/test/run.sh                                     deps=T015,T016,T017,T018   mutates=run.sh
- T020  files=extensions/deck-render/test/run.sh                                     deps=T015,T016,T017 mutates=run.sh
- T021  files=extensions/deck-render/test/run.sh                                     deps=T015,T017,T018 mutates=run.sh
- T022  files=extensions/deck-render/test/fixtures/profiles/{none,overview,both,invalid,unreadable,absent-key}.yaml   deps=-   mutates=(new)
- T023  files=extensions/deck-render/test/run.sh                                     deps=T015,T017,T022 mutates=run.sh
- T024  files=extensions/deck-render/test/run.sh                                     deps=T014,T015,T017,T022   mutates=run.sh
- T025  files=extensions/deck-render/test/run.sh                                     deps=T015,T017,T022 mutates=run.sh
- T026  files=extensions/deck-render/test/run.sh                                     deps=T014,T017,T008,T011   mutates=run.sh
- T027  files=extensions/deck-render/test/fixtures/deck-broken/                      deps=-              mutates=(new)
- T028  files=extensions/deck-render/test/run.sh                                     deps=T015,T017      mutates=run.sh
- T029  files=extensions/deck-render/test/run.sh                                     deps=T015,T017,T018,T027   mutates=run.sh
- T030  files=extensions/deck-render/test/run.sh                                     deps=T015,T017      mutates=run.sh
- T031  files=extensions/deck-render/test/run.sh                                     deps=T015,T016,T017 mutates=run.sh
- T032  files=extensions/deck-render/test/run.sh                                     deps=T015,T017      mutates=run.sh
- T033  files=extensions/deck-render/test/run.sh                                     deps=T017           mutates=run.sh
- T034  files=extensions/deck-render/test/run.sh                                     deps=T003,T004,T017 mutates=run.sh
- T035  files=extensions/deck-render/test/run.sh                                     deps=T003,T004,T017 mutates=run.sh
- T036  files=specs/006-deck-render/renders/overview.pptx (gitignored output)        deps=T015           mutates=(new, untracked)
- T037  files=specs/006-deck-render/quickstart.md (executed, not edited)             deps=T001-T036      mutates=-

### Shared-file serialization

- `extensions/deck-render/test/run.sh` — appended by T017 (scaffold) then T019, T020, T021, T023, T024, T025, T026, T028, T029, T030, T031, T032, T033, T034, T035. All pinned to serial waves 6–9; **never co-scheduled**. This is the single largest `[P]`-removal versus naive generation.
- `docs/contracts/profile-schema.md` (T008) + `specs/000-sample/profile.yaml` (T010) — different files, so `[P]` for authoring, but the D47/D59 contract-change discipline requires them in the **same commit**. Commit grouping is the git hook's job, not a scheduling dependency.
- `extensions/deck-render/extension/scripts/render.py` (T015) — kept as one cohesive task (not split), because its invariants (per-deck loop wrapping the transform wrapping the atomic write producing the stamp) are one interdependent file; splitting would only serialize sub-edits with no parallelism gained.
