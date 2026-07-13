# Tasks: Unified Graph Context Management (graphify-context)

**Input**: Design documents from `/specs/005-graphify-context/`

**Prerequisites**: plan.md (required, APPROVED/D74), spec.md (required), research.md, data-model.md, contracts/commands.md, quickstart.md, graphify-context.md (grounding)

**Tests**: Test tasks are **REQUIRED** for this feature — `SC-009` mandates a *committed, named regression fixture per live consumer*, and each arm's sign-off (S01–S03/S10/S11/S13/S18) is gated on a committed golden. This is not the template's optional-tests case; the fixtures are contract-of-record.

**Organization**: Tasks are grouped by user story (US1–US4 ≙ the four severable arms of plan.md). Setup + Foundational are shared barriers; Polish carries the cross-cutting non-regression / severability / reinstall guarantees.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies) — **reconciled against the graph, not assumed** (see *Execution Waves → [P] provenance*).
- **[Story]**: US1=Coverage · US2=Freshness · US3=Tiered products · US4=Query ceiling.
- Exact file paths are in each description; full annotations in `## Execution Waves → Task annotations`.

## Path Conventions

- **Pipeline extensions** (this feature's `Project Type`): source lives under `extensions/<name>/`; the installer `rm -rf`+`cp`s each `extension/` + `skills/` tree, so **every edit is a source edit under `extensions/`** (D57/I-14 — the sole reinstall-survivable form). No new top-level `src/`.
- Arms 1–3 land in `extensions/graphify/`; arm 4 in `extensions/council/`; the categorizer lockstep in `extensions/workforce/`; the trace contract in `docs/contracts/`. `graphifyy` (the upstream pip package) is **never edited** (D75).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: The test-harness scaffolding every arm's fixtures plug into, plus the mechanical-script home.

- [X] T001 [P] Scaffold the graphify extension test harness `extensions/graphify/test/run.sh` (fixture-driven, byte-checkable goldens, a `§3 reinstall-survival` stage) modeled on `extensions/git/test/run.sh` and `extensions/workforce/test/`, and create `extensions/graphify/test/fixtures/`.
- [X] T002 [P] Scaffold the council extension test harness `extensions/council/test/run.sh` + `extensions/council/test/fixtures/`, same model (council has no `test/` today).
- [X] T003 [P] Create `extensions/graphify/extension/scripts/` and establish the shared POSIX-`sh` idiom preamble the arm-1/2 scripts follow — `set -eu`, no LLM, no trace, no `ANTHROPIC_API_KEY`, exit-code-is-the-contract (the `commit.sh`/`verify-gate.sh` house style, constitution V).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The one cross-arm contract that arm 2 (which *checks* freshness) and arm 3 (which *emits* products) must agree on before either is built.

**⚠️ CRITICAL**: US2 and US3 cannot begin until this is complete. (US1 and US4 do not depend on it — they may start once Setup is done.)

- [X] T004 Define + document the **shared-provenance header** contract — `graph path · node/edge count · generated-at · graph content-hash / generation-id` — that every arm-3 context product emits and `freshness.sh` (arm 2) reads to decide staleness per product (data-model.md *Context products*; S13). Documented in `extensions/graphify/skills/speckit-graphify-context/SKILL.md` (provenance section) as the arm-2↔arm-3 coherence contract.

**Checkpoint**: Provenance contract fixed — the freshness check and the product generator now share one definition of "current".

---

## Phase 3: User Story 1 - Plumbing blast-radius grounded in the graph, not a disjointness guess (Priority: P1) 🎯 MVP

**Goal**: The graph models the pipeline's own `.sh`/`.yml`/`.md` artifact types + the three plumbing edge kinds, so `explain`/`path` resolve the every-wave `verify-gate.sh ↔ implement-parallel` call and `[P]`/blast-radius rest on real edges (SC-001); the labeled-assertion fallback remains, used *as the exception* (SC-002).

**Independent Test**: On this feature's own `.sh`/`.yml` slice, `path "verify-gate.sh" "implement-parallel"` returns a path (today: "No path found", verified live at step-0) and the majority of tasks' `[P]` is graph-derived.

### Tests for User Story 1 (write FIRST, ensure they FAIL) ⚠️

- [ ] T005 [P] [US1] Arm-1 **success-branch** golden: a fixture repo slice with a known `.sh`/`.yml` topology → the pass emits the expected nodes + all three edge kinds (`registers_hook`, `installs`, `invokes`), byte-identical. `extensions/graphify/test/fixtures/arm1-success/`.
- [ ] T006 [P] [US1] Arm-1 **fallback-branch** golden (SC-002 honesty): a slice carrying a relationship *outside* the three modeled kinds → the pass emits the **labeled-assertion fallback**, never a silent gap. `extensions/graphify/test/fixtures/arm1-fallback/`.
- [ ] T007 [P] [US1] Arm-1 **messy-pattern** golden (S10): commented-out `source`, conditional `cp`, `"$VAR/script.sh"` indirection → the pass mints **no wrong edge**; every unresolvable construct falls to the labeled assertion. `extensions/graphify/test/fixtures/arm1-messy/`.

### Implementation for User Story 1

- [ ] T008 [US1] Implement the post-extraction coverage pass `extensions/graphify/extension/scripts/augment.sh` (+ its small merge helper `extensions/graphify/extension/scripts/augment_merge.py`, calling no upstream-modifying `graphifyy` code): parse the repo's `.sh`/`.yml`/`.md`, emit nodes + the three edge kinds, merge into `graph.json`; labeled-assertion fallback for the unmodellable; **byte-deterministic** — canonical JSON key order, sorted iteration, no FS-iteration-order dependence (S11); exit-code contract per contracts/commands.md. (depends on T005, T006, T007)
- [ ] T009 [P] [US1] Harden the `graphify explain` **ambiguous-match** footgun at the extension seam — a query guard `extensions/graphify/extension/scripts/explain-guard.sh` that post-processes `graphify explain` to emit `path`'s near-tie warning (today `explain` resolves a short name to the top node silently even on a near-tie); `graphifyy` untouched (D75). S04. (depends on T003)
- [ ] T010 [P] [US1] Adopt the **qualified-path/label citation convention** so a deck-cited or member-cited filename names an unambiguous anchor (arm 1 grows the same-named-node surface; arm 4 makes each query precious) — edit `extensions/council/extension/templates/deck-technical.md`, `deck-overview.md`, and `extensions/council/extension/templates/member-prompt.md`. S04. **⚠ shares `member-prompt.md` with T027 and `deck-technical.md` with T021 — never co-schedule (see Shared-file serialization).** (depends on T009)

**Checkpoint**: US1 independently testable — the plumbing edges resolve; fallback claims are labeled.

---

## Phase 4: User Story 2 - Graph freshness is a checkable property, not a full-rebuild ritual (Priority: P1)

**Goal**: A mechanical staleness check (hard-warn + route to regenerate, **not** a hard-block — S14) and a trustworthy incremental refresh whose result equals a full regen for the changed scope with **zero stale survivors** (SC-003, SC-004), at ≤25% of the ~753k-token full-ritual budget for a ≤~10%-file change (plan §Performance Goals).

**Independent Test**: (a) a `graphify-context.md` predating its plan → check reports stale; (b) a bounded change → `refresh.sh` yields a full-regen-equivalent graph, `stale_survivors: 0`, at materially lower cost.

### Tests for User Story 2 (write FIRST) ⚠️

- [ ] T011 [P] [US2] Freshness fixtures **(a) stale-positive** (graph + mutated worktree → **stale**) **and (b) stale-negative / no-false-alarm** (graph + *unmutated* worktree → **fresh**, no crying-wolf — S18, the inverse branch). `extensions/graphify/test/fixtures/arm2-freshness/`. (depends on T004)
- [ ] T012 [P] [US2] Refresh fixture **(c) equivalence, 0 survivors**: base graph + changed-file extraction → refresh yields a graph equivalent to a full regen, `stale_survivors: 0`. `extensions/graphify/test/fixtures/arm2-equiv/`.
- [ ] T013 [P] [US2] Refresh fixture **(d) negative-path survivor guard** (S01, precondition for arm-2 sign-off): a fixture that *manufactures* >0 stale survivors (the M3 86-node incident in miniature) → the guard **detects** them **and** performs the prune-or-rebuild recovery. `extensions/graphify/test/fixtures/arm2-survivors/`.
- [ ] T014 [P] [US2] Cross-arm composition fixture **(e)** (S06): a changed `.sh` + incremental refresh → the refreshed graph **carries arm-1's augment edges** for the changed file (coverage not silently regressed). `extensions/graphify/test/fixtures/arm2-compose/`. (depends on T008)

### Implementation for User Story 2

- [ ] T017 [P] [US2] Version-pin manifest + preventive check (R4/S16): record the installed `graphifyy` version in `extensions/graphify/extension/graphify-version.pin`; the refresh wrapper asserts the pin before calling `build_merge`/`detect_incremental`, and a mismatch routes to the **full-regen** branch (never a silent wrong-contract call).
- [ ] T015 [P] [US2] Implement `extensions/graphify/extension/scripts/freshness.sh <product-path>`: derive freshness from the shared-provenance header / graph manifest vs the worktree; exit `0` = fresh, non-zero + `stale: regenerate <product>` on stdout = stale (**hard-warn, not hard-block**); **no state file** (D32); **recomputed at every consumption point, never cached across hook calls** (S20). (depends on T004, T011)
- [ ] T016 [US2] Implement `extensions/graphify/extension/scripts/refresh.sh`: wrap the upstream incremental merge; run the **stale-survivor guard** → print `stale_survivors: <N>`; apply the S02 branch table (common cheap-refresh / prune+targeted-re-extract on survivors>0 / full-regen only on version-change or operator demand); **re-invoke `augment.sh` on the changed scope** (S06); equivalence-to-full-regen is the SC-004 exit test. (depends on T017, T008, T012, T013, T014)

**Checkpoint**: US2 independently testable — staleness is caught before consumption; incremental ≡ full-regen for the changed scope, 0 survivors.

---

## Phase 5: User Story 3 - Each consumer reads the slice it needs — one graph, several diets (Priority: P2)

**Goal**: One generator run emits **three separate token-bounded products** — `graphify-context.md` (unchanged shape, FR-013), a receipts diet, a type-signal diet — so no consumer pays for another's tokens (FR-010 structural, not prose); the council member's on-demand pulls drop vs the one-diet baseline (SC-005, the D62 3/5→1/5 direction).

**Independent Test**: three consumer classes each read only their slice; a cross-product coherence check proves all three carry the same generation-id.

### Tests for User Story 3 (write FIRST) ⚠️

- [ ] T018 [P] [US3] Per-product goldens (three): `graphify-context.md` (blast-radius, **unchanged** shape — the FR-013 tripwire), the receipts diet (concept/rationale), the type-signal diet (per-file `type` + path-convention fallback). `extensions/graphify/test/fixtures/arm3-products/`. (depends on T004)
- [ ] T019 [P] [US3] **Cross-product coherence** fixture (S13): one generator run → all three diets carry the **same graph-hash / generation-id** in their shared-provenance header (mutual coherence, not just per-product correctness). `extensions/graphify/test/fixtures/arm3-coherence/`. (depends on T004)

### Implementation for User Story 3

- [ ] T020 [US3] Extend the generator `extensions/graphify/skills/speckit-graphify-context/SKILL.md` to emit **three separate products from one graph pass**: `graphify-context.md` (unchanged path + section grammar, FR-013), the **receipts** diet (for council member + deck-prep), the **type-signal** diet (for the categorizer); each token-bounded, each carrying the shared-provenance header (T004). (depends on T004, T018, T019)
- [ ] T021 [P] [US3] Lockstep-update **deck-prep** to source the **receipts diet** (the D62 enrichment source) — edit `extensions/council/extension/templates/deck-technical.md` so Stage-0 deck-prep mines the receipts product (consumer 6). **⚠ shares `deck-technical.md` with T010 — never co-schedule.** (depends on T020)
- [ ] T022 [P] [US3] Lockstep-update the **categorizer** to read the **type-signal diet** with its path-convention fallback — edit `extensions/workforce/extension/templates/categorizer-prompt.md` (consumer 5). (depends on T020)

**Checkpoint**: US3 independently testable — three diets from one pass, mutually coherent, each consumer on its own slice.

---

## Phase 6: User Story 4 - A council member's graph-query loop is bounded and visible (Priority: P2)

**Goal**: A hard, tier-aware, enforced ceiling on a member's graph-query **count** (standard `N=15` per D77; full **unset/uncapped** until its own baseline), the count + ceiling-hit recorded in the trace **and** — the load-bearing guarantee — the reduced-grounding disclosure **mechanically appended by the orchestrator** the instant the cap fires (S09), so the chairman weights a ceiling-limited opinion (SC-006, SC-008).

**Independent Test**: drive a member fixture to the ceiling → its opinion carries the disclosure and its trace shows `ceiling_hit: true`; an ordinary round carries neither.

- [ ] T023 [US4] Amend the trace contract `docs/contracts/trace-schema.md`: add `graph_queries: <int>` and `ceiling_hit: <bool>`, **role-scoped to `council-member`** (the D72 role-gating pattern, mirroring `context_in`) — the contract change authorized at implement (data-model.md).

### Tests for User Story 4 (write FIRST) ⚠️

- [ ] T024 [P] [US4] **Ceiling** fixture (consumer fixture 4): a member reviewing-loop driven to the ceiling → the opinion carries the reduced-grounding disclosure **and** the trace records `ceiling_hit: true`. `extensions/council/test/fixtures/arm4-ceiling/`. (depends on T002, T023)
- [ ] T025 [P] [US4] **Non-disclosure-default inverse** fixture (S18): an ordinary non-ceiling round → **no** disclosure line and `ceiling_hit: false` (the quiet-path branch, so disclosure never fires spuriously). `extensions/council/test/fixtures/arm4-noceiling/`. (depends on T002, T023)

### Implementation for User Story 4

- [ ] T026 [P] [US4] Add `member.query_ceiling` to `extensions/council/extension/council-config.yml` — **tier-aware**: `standard: 15` (D77, calibrated from this round's uncapped max of 9); `full:` **unset / uncapped** until the first full-tier round measures its own baseline (D77 — no ceiling derived from the wrong tier).
- [ ] T027 [US4] Edit the member prompt `extensions/council/extension/templates/member-prompt.md`: the query-ceiling instruction, the ceiling-hit disclosure hook (extending the existing FR-019 reduced-grounding note), and point the member at its **receipts diet** (arm-3 consumer 4). **⚠ shares `member-prompt.md` with T010 — never co-schedule.** (depends on T020, T026)
- [ ] T028 [US4] Edit the council orchestrator `extensions/council/skills/speckit-council/SKILL.md` member-dispatch: **enforce** the query-count cap (the `N`th query is the last); **mechanically append** the reduced-grounding disclosure line the instant the cap is enforced (S09 — orchestrator appends, member prose is courtesy); record `graph_queries` + `ceiling_hit` per member trace fragment (FR-012); add the mid-implementation self-reopen guard note (S17 — a `--reopen delta` before arm 4 wires dispatches the pre-ceiling prompt). (depends on T023, T026)

**Checkpoint**: US4 independently testable — the loop is bounded, the ceiling-hit is never silent.

---

## Phase 7: Polish & Cross-Cutting Concerns (Non-regression · Severability · Reinstall)

**Purpose**: The FR-013/FR-014/SC-007/SC-009 guarantees that span all four arms — non-regression with teeth, the severability claim realized as a test, and reinstall survival.

- [ ] T029 [P] Consumer fixture 1 — `/speckit-plan` reads `graphify-context.md` (blast-radius diet) **unchanged in shape**. `extensions/graphify/test/fixtures/consumer-plan/`. (depends on T020)
- [ ] T030 [P] Consumer fixture 2 — `/speckit-tasks-graph` consumes the same diet; `[P]`/wave derivation unbroken. `extensions/graphify/test/fixtures/consumer-tasks-graph/`. (depends on T020)
- [ ] T031 [P] Consumer fixture 3 — `/speckit-implement-parallel` consumes the same diet; per-task blast-radius unbroken. `extensions/graphify/test/fixtures/consumer-implement/`. (depends on T020)
- [ ] T032 [P] Consumer fixture 5 — the categorizer reads the type-signal diet; `type` derivation + path-convention fallback intact. `extensions/graphify/test/fixtures/consumer-categorizer/`. (depends on T022)
- [ ] T033 [P] Consumer fixture 6 — deck-prep reads the receipts diet unbroken. `extensions/graphify/test/fixtures/consumer-deck-prep/`. (depends on T021)
- [ ] T034 [P] **Severability / detached-configuration** fixture (S12): assert arms **2 + 3 + 4 pass green with arm 1 absent** (the fallback story realized as a test, so detach stays a live, checked option). `extensions/graphify/test/fixtures/severability/`. (depends on T015, T016, T020, T028)
- [ ] T035 **Reinstall-survival** test (D57, quickstart §13): run `bash extensions/graphify/install.sh .` and `bash extensions/council/install.sh .`, then re-run every fixture against the *installed* copies → all edits survive the installer `rm -rf`+`cp` (model: `extensions/git/test/run.sh §3`). Touches both harnesses → serial. (depends on T008, T015, T016, T020, T021, T022, T027, T028)
- [ ] T036 Run the full `quickstart.md` validation (all 13 scenarios → each SC + each arm + non-regression + reinstall). Final integration gate. (depends on all prior)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies — start immediately.
- **Foundational (Phase 2, T004)**: after Setup; **blocks US2 + US3** (not US1/US4).
- **User Stories (Phases 3–6)**: after Setup (US1, US4) / after Foundational (US2, US3). The four arms are **severable** (plan §Detach order) and run **cross-story-parallel**, subject to the shared-file serializations below.
- **Polish (Phase 7)**: after the arms it tests are built.

### Story-level dependencies (the real cross-arm edges — not full independence)

- **US2 → US1**: `refresh.sh` (T016) and the composition fixture (T014) depend on `augment.sh` (T008) — S06's "refresh re-invokes augment" invariant is a genuine code edge, not just conceptual.
- **US2/US3 → Foundational**: both depend on the shared-provenance header (T004).
- **US3 → US4 / US1**: the receipts-diet + member-prompt + deck-template edits collide on `member-prompt.md` and `deck-technical.md` (see below).

### Within each user story

- Tests are written and FAIL before implementation.
- Arm-1: goldens → `augment.sh`; the `explain`-guard and citation convention are independent surfaces.
- Arm-2: fixtures → `freshness.sh` / `refresh.sh`; the version-pin (T017) precedes `refresh.sh`.
- Arm-3: goldens → generator → consumer lockstep updates.
- Arm-4: trace contract → fixtures → config → member-prompt → orchestrator.

---

## Parallel Example: the widest wave

```bash
# After Setup + Foundational (Wave 3): 12 disjoint tasks run at once —
# every arm's failing tests + the independent config/contract/manifest surfaces.
Task T005/T006/T007 [US1] : arm-1 goldens (success / fallback / messy)
Task T011/T012/T013 [US2] : arm-2 fixtures (freshness / equivalence / survivor-guard)
Task T018/T019      [US3] : arm-3 goldens (products / coherence)
Task T009           [US1] : explain-guard wrapper
Task T017           [US2] : graphify version-pin manifest
Task T023           [US4] : trace-schema amendment
Task T026           [US4] : council-config query_ceiling
```

---

## Implementation Strategy

### MVP First (User Story 1 — the headline I-13 fix)

1. Setup (T001–T003) → Foundational (T004).
2. US1 (T005–T010): the coverage pass + `explain`-hardening.
3. **STOP and VALIDATE**: `path "verify-gate.sh" "implement-parallel"` returns a path; fallback claims labeled.

### Incremental Delivery (severable arms, detach order = arm 1 detach-first)

- US1 (Coverage) → US2 (Freshness) → US3 (Tiered products) → US4 (Query ceiling). Each arm is independently shippable; only **arm 1** has a working fallback (detach-first). Arms 2+3+4 are core (ship together or the value doesn't land) — the severability fixture (T034) proves 2+3+4 green with arm 1 absent.

### Parallel Team Strategy

- With capacity, run US1/US2/US3/US4 concurrently after Foundational, honoring the shared-file serialization (`member-prompt.md`, `deck-technical.md`) and the US2→US1 code edge. See the wave plan below.

---

## Notes

- `[P]` = different files, no dependency — **but reconciled against the graph, honestly** (next section): for `.sh`/`.yml` script tasks the graph is blind (that is the very I-13 gap arm 1 closes), so their `[P]` is disjointness + source-read **assertion, not graph fact** (S22).
- `[Story]` maps a task to its arm for traceability.
- Every edit is a source edit under `extensions/` (D57); no `ANTHROPIC_API_KEY`; the arm-1/2 scripts write no trace (mechanical, constitution V).
- Commit after each task or logical group (the `after_tasks` git hook fires at phase close).

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries,
> [P] markers, TDD ordering, and graphify dependency edges. Tasks within one parallel
> wave have all dependencies satisfied by earlier waves and disjoint mutable-file sets.
> Setup and Foundational phases are serial barriers; parallelism is cross-story.

- Wave 1 [parallel] : T001, T002, T003                               # Phase 1 Setup — disjoint scaffolds; barrier before all stories
- Wave 2 [serial]   : T004                                            # Phase 2 Foundational — shared-provenance header (blocks US2+US3)
- Wave 3 [parallel] : T005 [US1], T006 [US1], T007 [US1], T009 [US1], T011 [US2], T012 [US2], T013 [US2], T017 [US2], T018 [US3], T019 [US3], T023 [US4], T026 [US4]   # widest wave (12): all failing tests + independent config/contract/manifest surfaces
- Wave 4 [parallel] : T008 [US1], T015 [US2], T020 [US3], T024 [US4], T025 [US4]   # arm cores + arm-4 fixtures (deps met by W3)
- Wave 5 [parallel] : T014 [US2], T010 [US1], T022 [US3], T028 [US4]   # compose fixture + citation convention + categorizer lockstep + orchestrator
- Wave 6 [parallel] : T016 [US2], T021 [US3], T027 [US4]              # refresh + deck-prep lockstep + member-prompt ceiling (council files freed by W5)
- Wave 7 [parallel] : T029, T030, T031, T032, T033, T034              # non-regression consumer fixtures + severability
- Wave 8 [serial]   : T035                                            # reinstall-survival — touches both harnesses, re-runs every fixture
- Wave 9 [serial]   : T036                                            # quickstart.md full validation — final gate

### Task annotations

- T001  files=extensions/graphify/test/run.sh                                      deps=-                     mutates=(new)
- T002  files=extensions/council/test/run.sh                                       deps=-                     mutates=(new)
- T003  files=extensions/graphify/extension/scripts/ (idiom preamble)              deps=-                     mutates=(new)
- T004  files=extensions/graphify/skills/speckit-graphify-context/SKILL.md (provenance §)   deps=-            mutates=SKILL.md   # foundational contract note; the generator body is T020
- T005  files=extensions/graphify/test/fixtures/arm1-success/                      deps=T001                  mutates=(new)
- T006  files=extensions/graphify/test/fixtures/arm1-fallback/                     deps=T001                  mutates=(new)
- T007  files=extensions/graphify/test/fixtures/arm1-messy/                        deps=T001                  mutates=(new)
- T008  files=extensions/graphify/extension/scripts/augment.sh,augment_merge.py    deps=T005,T006,T007        mutates=(new)
- T009  files=extensions/graphify/extension/scripts/explain-guard.sh               deps=T003                  mutates=(new)
- T010  files=extensions/council/extension/templates/{deck-technical.md,deck-overview.md,member-prompt.md}   deps=T009   mutates=deck-technical.md,deck-overview.md,member-prompt.md   # SHARED: member-prompt.md↔T027, deck-technical.md↔T021
- T011  files=extensions/graphify/test/fixtures/arm2-freshness/                    deps=T004                  mutates=(new)
- T012  files=extensions/graphify/test/fixtures/arm2-equiv/                        deps=-                     mutates=(new)
- T013  files=extensions/graphify/test/fixtures/arm2-survivors/                    deps=-                     mutates=(new)
- T014  files=extensions/graphify/test/fixtures/arm2-compose/                      deps=T008                  mutates=(new)
- T015  files=extensions/graphify/extension/scripts/freshness.sh                   deps=T004,T011             mutates=(new)
- T016  files=extensions/graphify/extension/scripts/refresh.sh                     deps=T017,T008,T012,T013,T014   mutates=(new)
- T017  files=extensions/graphify/extension/graphify-version.pin                   deps=-                     mutates=(new)
- T018  files=extensions/graphify/test/fixtures/arm3-products/                     deps=T004                  mutates=(new)
- T019  files=extensions/graphify/test/fixtures/arm3-coherence/                    deps=T004                  mutates=(new)
- T020  files=extensions/graphify/skills/speckit-graphify-context/SKILL.md         deps=T004,T018,T019        mutates=SKILL.md
- T021  files=extensions/council/extension/templates/deck-technical.md             deps=T020                  mutates=deck-technical.md   # SHARED with T010
- T022  files=extensions/workforce/extension/templates/categorizer-prompt.md       deps=T020                  mutates=categorizer-prompt.md
- T023  files=docs/contracts/trace-schema.md                                       deps=-                     mutates=trace-schema.md
- T024  files=extensions/council/test/fixtures/arm4-ceiling/                       deps=T002,T023             mutates=(new)
- T025  files=extensions/council/test/fixtures/arm4-noceiling/                     deps=T002,T023             mutates=(new)
- T026  files=extensions/council/extension/council-config.yml                      deps=-                     mutates=council-config.yml
- T027  files=extensions/council/extension/templates/member-prompt.md              deps=T020,T026             mutates=member-prompt.md    # SHARED with T010
- T028  files=extensions/council/skills/speckit-council/SKILL.md                   deps=T023,T026             mutates=speckit-council/SKILL.md
- T029  files=extensions/graphify/test/fixtures/consumer-plan/                     deps=T020                  mutates=(new)
- T030  files=extensions/graphify/test/fixtures/consumer-tasks-graph/              deps=T020                  mutates=(new)
- T031  files=extensions/graphify/test/fixtures/consumer-implement/                deps=T020                  mutates=(new)
- T032  files=extensions/graphify/test/fixtures/consumer-categorizer/              deps=T022                  mutates=(new)
- T033  files=extensions/graphify/test/fixtures/consumer-deck-prep/                deps=T021                  mutates=(new)
- T034  files=extensions/graphify/test/fixtures/severability/                      deps=T015,T016,T020,T028   mutates=(new)
- T035  files=extensions/graphify/test/run.sh,extensions/council/test/run.sh (reinstall stage)   deps=T008,T015,T016,T020,T021,T022,T027,T028   mutates=run.sh (both)
- T036  files=specs/005-graphify-context/quickstart.md (executed, not edited)      deps=<all>                 mutates=-

### Shared-file serialization

- `extensions/council/extension/templates/member-prompt.md` touched by **T010** (arm-1 citation convention) and **T027** (arm-4 ceiling) → pinned to different waves (W5, W6); never co-scheduled.
- `extensions/council/extension/templates/deck-technical.md` touched by **T010** (arm-1 citation convention) and **T021** (arm-3 deck-prep receipts lockstep) → pinned to different waves (W5, W6); never co-scheduled.
- `extensions/graphify/skills/speckit-graphify-context/SKILL.md` touched by **T004** (foundational provenance note) and **T020** (generator body) → sequenced across phases (W2 → W4), never concurrent.
- `.specify/extensions.yml` (the pipeline's highest-collision shared file) — **not touched by any 005 task**: the augment/freshness/refresh scripts are invoked by `refresh.sh` / the generator, not registered as new hooks, so the M2 live merge-collision (R1-S17) is not re-entered.

### [P] provenance — the honest degradation (S22 / I-13, this feature's own Exhibit A)

> `graphify-context.md` verified **live at step-0** (fresh, 2026-07-13, same D59 baseline) that the graph is **blind to `.sh`/`.yml`**: `explain "verify-gate.sh"` = degree-5 all-intra-file; `path "verify-gate.sh" "implement-parallel"` = **"No path found"** though the call happens every wave. Those are exactly the file types this feature edits.

- **`.sh`/`.yml`/`.pin` tasks** (T003, T008, T009, T015, T016, T017 + the `.sh`-topology fixtures) — their `[P]` and non-collision are **file-disjointness + source-read assertion, NOT graph edges** (S22). The graph cannot yet verify them; arm 1 is the fix, and until it runs on the repo the pass's own reach is graph-invisible.
- **`.md` tasks** (T004/T010/T020/T021/T027/T028 + categorizer prompt) — the graph has **partial** signal (`member-prompt.md` degree-16, the graphify `SKILL.md` degree-2 are graph-grounded); the `member-prompt.md` and `deck-technical.md` collisions above are taken from `graphify-context.md`'s shared/mutable list **and** confirmed by source-reading which task edits which file.
- **Test-fixture tasks** — `[P]` is graph-independent by construction: every fixture is a brand-new disjoint directory, no collision possible.
- **`[P]` markers vs naive generation**: none were added beyond the disjointness heuristic (the graph offers no plumbing edges to *promote* a marker); several were **withheld** — T010/T021/T027 are disjoint-by-path within their own stories but are **serialized cross-story** on `member-prompt.md`/`deck-technical.md`, and T016 is held un-`[P]` behind its own dependency chain. This is the degradation the skill's fallback clause anticipates, disclosed here rather than silently assumed.
