---
description: "Task list — 008 Pre-Public Maintenance & Adopter Experience"
---

# Tasks: Pre-Public Maintenance & Adopter Experience

**Input**: Design documents from `/specs/008-pre-public-maintenance/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, graphify-context.md ✅, council/decision-record.md § Carried Constraints ✅

**Tests**: Test tasks ARE included — the spec explicitly requires committed both-branch fixtures (FR-009/FR-011/SC-004/SC-006/SC-007) and the repo's golden-fixture discipline governs.

**Organization**: Grouped by user story (US1 P1 · US2 P2 · US3 P3) so each is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Verified parallel-safe against the graph — disjoint `files=`, no shared blast radius, no shared/mutable file.
- **[Story]**: US1 / US2 / US3.

## Path Conventions

Monorepo: `extensions/<name>/` (per-extension `install.sh`, `extension/`, `skills/`, `test/run.sh`), `docs/contracts/`, `specs/NNN-feature/`. Paths below are repo-root-relative and taken verbatim from plan.md § Source Code.

## ⚠️ Scope invariant governing every task (FR-015 / R1-S01)

Every task below edits **only** these declared sites. A change to any other path fails the T002 allowlist guard:

```
bootstrap.sh
extensions/workforce/extension/scripts/check-conformance.py
specs/008-pre-public-maintenance/fixtures/
extensions/git/install.sh
extensions/git/test/run.sh
extensions/graphify/extension/scripts/augment_merge.py
extensions/graphify/test/run.sh
extensions/council/skills/speckit-council/SKILL.md
extensions/council/skills/speckit-council-triage/SKILL.md
extensions/graphify/skills/speckit-implement-parallel/SKILL.md
extensions/workforce/test/run.sh
README.md
docs/90-DECISIONS-AND-IDEAS.md
```

> **Consequence (design note):** the FR-015 guard itself cannot live in a new file — a new file would fall outside its own allowlist and self-fail. It is therefore folded into `extensions/workforce/test/run.sh` (T002), an already-declared site that already hosts this feature's other machine checks.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the pre-change baseline every "witness FAIL → witness PASS" sub-order depends on.

- [X] T001 Record the pre-change green baseline: run `sh extensions/git/test/run.sh`, `sh extensions/graphify/test/run.sh`, `sh extensions/workforce/test/run.sh`, `sh extensions/testing/test/run.sh`, `sh extensions/deck-render/test/run.sh`; capture pass/fail counts. Required so T012's R1-S11 "witness the guard FAIL against the pre-fix manifest/block" is distinguishable from a pre-existing failure.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The FR-015 scope invariant every subsequent task is scored against.

**⚠️ CRITICAL**: No story work begins until T002 is in place — it is the guard that proves the whole feature stayed gate-semantics-neutral.

- [X] T002 Add the FR-015 branch-scope allowlist guard to `extensions/workforce/test/run.sh` (R1-S01): assert `git diff --name-only $(git merge-base <base_branch> HEAD)..HEAD` yields **no path outside** the declared allowlist above; FAIL naming the stray path. Read `base_branch` from the feature's git config/`profile.yaml` resolution rather than hard-coding `main`.

**Checkpoint**: Scope guard armed — story work can begin.

---

## Phase 3: User Story 1 - Clone-free one-command install (Priority: P1) 🎯 MVP

**Goal**: An adopter installs a chosen extension into a target repo with one documented command and zero manual clone (I-32, FR-001/002/003).

**Independent Test**: From a machine with no prior `specseyal` clone, run the documented command against a throwaway repo — the extension's skills land in `.claude/`, hooks in `.specify/`; a second run is idempotent; the local in-checkout `install.sh .` route still works unchanged.

### Implementation for User Story 1

- [X] T003 [P] [US1] Create `bootstrap.sh` (root, new) — argument surface + safety layer per `contracts/bootstrap-install-command.md`: `<extension-name>` constrained to the closed enum `git|graphify|council|workforce|testing|deck-render`; `<target-repo-dir>` defaulting to `.`; `--ref <pinned-ref>` defaulting to a **concrete released tag, never a moving branch** (R1-S05). Validate and escape both `--ref` and `<target-repo-dir>` before any interpolation — reject a `-`-leading ref as argument injection (R1-S05). Install a trap-based `EXIT` handler that removes the temp dir on every exit path and propagates the delegated command's non-zero status, leaving the target repo in a **named, documented state** on mid-install failure (R1-S24).

- [X] T004 [US1] Implement the fetch + delegate body of `bootstrap.sh` (depends on T003): primary path = shallow blobless sparse clone (`git clone --depth 1 --filter=blob:none --sparse` + `git sparse-checkout set extensions/<name>`) at the pinned ref; fallback = `codeload` tarball of the same pinned ref when sparse-checkout is unavailable (B6); then **delegate** to that extension's own `extensions/<name>/install.sh <target>` — never re-implement install logic (B2/FR-003/D45). Idempotency is inherited from the already-idempotent `install.sh` (B4).

- [X] T005 [US1] Add `bootstrap.sh --self-test` exercising **both** fetch branches — sparse-partial-clone and codeload-tarball fallback (R1-S08, depends on T004). Mirrors the `validate-profile.py` embedded-`_self_test()` precedent; folded into `bootstrap.sh` rather than a new harness file because a new file would breach the T002 allowlist.

- [X] T006 [US1] Update the `README.md` quickstart to document the clone-free install path (FR-002/SC-002, depends on T003): the **reviewable two-step form** (`curl -fsSLO <raw-url>/<pinned-ref>/bootstrap.sh` then `sh bootstrap.sh <ext> <target>`) is the documented default; any `curl | sh` convenience line is secondary and **never the sole instruction** (spec Edge: security posture). No undocumented acquisition step may remain.

**Checkpoint**: US1 independently shippable — the highest adopter-value slice on its own.

---

## Phase 4: User Story 2 - Contract drift caught by machine (Priority: P2)

**Goal**: A dependency-free checker validates a `specs/NNN-feature/` dir against the `docs/contracts/` schema set, delegating to the three existing per-artifact validators (I-11, FR-004–009).

**Independent Test**: `python3 extensions/workforce/extension/scripts/check-conformance.py specs/000-sample` exits 0; each injected-violation fixture exits non-zero naming artifact + rule; two runs on the same input produce an identical verdict.

### Tests for User Story 2 ⚠️

> Fixtures are authored FIRST — the checker's failure messages are written to match them.

- [X] T007 [P] [US2] Create the both-branch fixture tree under `specs/008-pre-public-maintenance/fixtures/` (new): `conformant/` (a valid feature dir → PASS) plus one injected-violation dir per **all six directly-checked contracts** (R1-S16) — `artifact-layout`, `decision-record`, `completion-report`, `testing-doc`, `trace-schema`, `agent-library-schema`. Per `contracts/conformance-checker-command.md` these surface as at least `violation-missing-section/`, `violation-bad-frontmatter/`, `violation-wrong-path/`, `violation-bad-trace-line/`; add cases so **no contract is left without an injected-violation case**, and explicitly call out any that is (FR-009). The `trace-schema` violation fixture doubles as I-31's pinning fixture (R1-S03), since no `run.sh` can drive that SKILL.md prose.

### Implementation for User Story 2

- [X] T008 [US2] Create `extensions/workforce/extension/scripts/check-conformance.py` (new) — CLI shell + delegation layer (depends on T007): single `python3` command taking `<feature-dir>`, Python-3-stdlib only, no third-party imports (C7/FR-007). **Delegate** to `validate-profile.py`, `validate-categorization.py`, `validate-skill.py` by `subprocess` shell-out to their installed copies, surfacing their verdicts — **never a source-level `import`** of them (C2/FR-008/R1-S22). Justification for the shell-out is the plain "a read is not a write" seam rule, **not** D57 (R1-S17). Distinguish a usage error (missing/nonexistent dir) from a conformance failure in the exit path.

- [X] T009 [US2] Implement the six direct contract checks in `check-conformance.py` (depends on T008): `artifact-layout` (required-file presence + layout paths), `decision-record` (required sections/frontmatter), `completion-report` (status enum + ordered core sections), `testing-doc` (SC/FR mapping shape), `trace-schema` (every field present, per `traces.jsonl` line), `agent-library-schema` (`agents/assignment.md` roster shape) — each rule read **from the contracts' own stated rules, not from the M0 fixture** (FR-005/C3). Honor documented D50 meta-feature rule-5 carve-outs as conformant, never as drift (C8/FR-006). Emit deterministic `<artifact> · <rule>` lines; exit non-zero on any nonconformance (C5/C6).

- [X] T010 [US2] Add `_self_test()` to `check-conformance.py` (depends on T009, C9/R1-S19): assert the contract **section headers and field names the checker parses still exist** in each `docs/contracts/*.md`, so a future contract-doc edit fails loudly instead of silently desyncing the only code kept in sync with that prose. Mirrors `validate-profile.py`'s embedded-self-test shape.

- [ ] T011 [US2] Wire the checker's assertions into `extensions/workforce/test/run.sh` (depends on T002, T007, T010 — **same file as T002, never co-scheduled**): invoke every both-branch fixture (conformant PASSES; each violation FAILS naming its cause); pin the standing `specs/000-sample` golden assertion (C4/FR-006/SC-004); add the **static no-import guard** asserting `check-conformance.py`'s source contains no source-level `import` of the three validators, only `subprocess`/shell-out (R1-S22); add the **double-run byte-diff determinism assertion** replacing the manual re-run-and-eyeball step, moving SC-005 from manual to code-verified (R1-S21).

**Checkpoint**: US1 AND US2 both independently functional.

---

## Phase 5: User Story 3 - Latent defects hardened before outside eyes (Priority: P3)

**Goal**: Four surgical, gate-semantics-neutral hardenings at graph-confirmed sites (I-23, I-26, I-29, I-31).

**Independent Test**: Each fix has a standalone check — see the four tasks below.

> **Honest coverage statement (R1-S15)**: I-23 lands a both-branch `run.sh` fixture; I-26 is **partial** (primary fix + `dequote()`'s other two callers); I-29 and I-31 edit LLM-interpreted `SKILL.md` prose that **no `run.sh` can drive** and therefore carry **no** `run.sh` fixture — I-31 is pinned instead by T007's `trace-schema` violation fixture, and I-29 carries a real, disclosed gap. Three of the four hardenings carry a coverage gap.

### Implementation for User Story 3

- [ ] T012 [US3] I-23 — git-ext manual-fallback completeness + divergence guard. **One lock-step task in this fixed sub-order (R1-S11)**, touching `extensions/git/install.sh` and `extensions/git/test/run.sh`:
  1. **Mirror resync first (R1-S23)** — if the work triggers a git-ext reinstall, re-sync `extension/extension.yml` → `.specify/extensions.yml` **strictly before** the guard runs, so the guard never validates a stale installed mirror. Not an independently-ordered separate commit.
  2. **Generalize the guard** in `extensions/git/test/run.sh` — replace the current single-hook grep (L164, `after_workforce_approve` only) with an assertion that **every** hook registered in `extensions/git/extension/extension.yml` appears in the manual block, **scoped to `extensions/git/install.sh` specifically** — not a bare `print_manual_block` name match, which any of the five identical copies would satisfy (R1-S10/FR-011).
  3. **Witness it FAIL** against the current pre-fix state (`after_complete`/`after_testing` missing from the block) — a guard that passes on real divergence is not a guard (spec Edge).
  4. **Apply the fix** — extend `print_manual_block()` in `extensions/git/install.sh` to declare 100% of registered hooks, including the `after_complete` and `after_testing` commit seams (FR-010/H1.1).
  5. **Witness it PASS** (H1/SC-006).

  `extensions/git/extension/extension.yml` is **read-only** here — the manifest already registers both seam hooks; it is the guard's source of truth, not an edit site (plan.md § Source Code marks only `install.sh` and `test/run.sh` as EDIT).

- [X] T013 [P] [US3] I-29 — council apparatus provenance. Edit `extensions/council/skills/speckit-council/SKILL.md` (the `suggestions.md` provenance writer) and `extensions/council/skills/speckit-council-triage/SKILL.md` (`decision-record.md` §5 Metadata) to record `Council apparatus: extensions/council/ @ <git rev-parse HEAD -- extensions/council/>` alongside the existing plan and deck SHAs (FR-013/H3.1). When `extensions/council/` has uncommitted edits, **note/flag the dirty working tree** so the recorded sha's completeness is honest (H3.2/spec Edge). Additive metadata only — no gate-semantics change (H3.3/FR-015). **Applies forward only** (R1-S13): this feature's own already-written round artifacts predate the change and are **not** back-filled.

- [ ] T014 [US3] I-26 — augment inline-comment strip. In `extensions/graphify/extension/scripts/augment_merge.py`, make `parse_hook_commands()` (L120) strip a **whitespace-preceded trailing `#…`** before calling `dequote()`, so `command: <id>  # <comment>` mints a clean `<id>` with zero ` # …` captured (FR-012/H2.1). Stay **line-based and PyYAML-free** (H2.2) — this file deliberately carries no PyYAML dependency. Then add fixture cases to `extensions/graphify/test/run.sh` covering the whitespace variants `#x`, `  #  x`, and tab-separated (H2.3/SC-007/spec Edge), **plus regression cases for `dequote()`'s other two callers — `parse_shell` (L166+) and `resolve_target` (L84) — proving they are unaffected** (R1-S03). Serialized after T012 and away from T015: both edit graphify installed surfaces and contend on the `.specify/` installed mirror.

- [X] T015 [P] [US3] I-31 — implement-parallel gitignored-artifact guard. In `extensions/graphify/skills/speckit-implement-parallel/SKILL.md`, add the trace-writing rule that a task whose **sole** output is gitignored or untracked records `artifact: null` — never the ignored path (FR-014/H4.1/SC-009). Probe tracked-state via `git` (`git check-ignore` / `git ls-files`) (H4.2). This generalizes `006`'s SC-005 one-off data fix into a root-cause guard. **`trace-schema.md`-compliant — a value change only, no field added or removed** (H4.3/Constitution IV). No `run.sh` fixture is possible; pinned by T007's `trace-schema` violation fixture (R1-S03/R1-S15).

**Checkpoint**: All three user stories independently functional.

---

## Phase 6: Polish, Validation & Close-out

- [ ] T016 Execute `quickstart.md` end-to-end as the feature's **integration gate**, under the `quickstart-integration-gate` discipline, **before `/speckit-complete`** (R1-S09, depends on T006, T011, T012, T014, T015). Bind **every** one of SC-001…SC-010 to a concrete executed check — no sampled spot-check. Name the **executor and timing** for the six manual-only criteria (SC-001/002/003, SC-008/009/010), since `/speckit-testing` is doc-only (`executed: none`) and cannot discharge them. Mark **SC-001/002/003's sign-off `provisional`** (R1-S06): run pre-D73 by an authenticated maintainer against a still-private repo, it cannot exercise the unauthenticated true-outsider path and **must be re-confirmed against the real public repo immediately after the D73 visibility flip**.

- [ ] T017 `docs/90-DECISIONS-AND-IDEAS.md` close-out — **the final serialized step, gated on all five owner piles completing** (R1-S20/FR-016, depends on T016): resolve and update the status of all six ripe I-rows (I-32, I-11, I-23, I-26, I-29, I-31) **in the same session** (log discipline). Add a new I-row recording that **four of the five identical `print_manual_block()` copies remain unclosed** — `deck-render`, `graphify`, `testing`, `workforce` — since I-23 closes git's copy only and does not close the pattern repo-wide (R1-S07). Add the explicit **FR-015 gate sign-off line** confirming no gate-schema or gate-semantics file changed — **distinct from** SC-010's `docs/90` I-code grep, which proves close-out bookkeeping, not non-interference (R1-S01).

- [ ] T018 Final verification (depends on T017): re-run the T002 FR-015 allowlist guard over the complete branch diff and the full test suite across all five extensions; confirm a green result against T001's baseline. SC-010's `grep -nE 'I-32|I-11|I-23|I-26|I-29|I-31' docs/90-DECISIONS-AND-IDEAS.md` returns all six resolved.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001)**: no dependencies — starts immediately.
- **Foundational (T002)**: depends on T001; **blocks all stories** (arms the FR-015 scope invariant).
- **US1 (P1) / US2 (P2) / US3 (P3)**: all depend on T002; then proceed in parallel where the graph permits.
- **Polish (T016–T018)**: depends on all three stories; T017 is the mandated final serialized close-out (R1-S20).

### User Story Dependencies

- **US1 (P1)**: independent. No dependency on US2 or US3.
- **US2 (P2)**: independent of US1. Supplies T007's `trace-schema` fixture that pins US3's I-31.
- **US3 (P3)**: independent of US1. T015's coverage is pinned by US2's T007 fixture (a test-coverage dependency, not a code dependency).

### Within Each User Story

- US1: `bootstrap.sh` is a single new file — T003 → T004 → T005 is strictly serial; T006 (README) needs only T003's settled command shape.
- US2: fixtures (T007) precede the checker so failure messages are written to match; T008 → T009 → T010 are serial (one file); T011 last (shares a file with T002).
- US3: T012 is internally lock-step and non-splittable (R1-S11). T014 is serialized behind T012 on the `.specify/` mirror. T013 and T015 are prose-only and parallel-safe.

### Parallel Opportunities

- Cross-story: US1's `bootstrap.sh`, US2's fixture tree, and US3's two prose-only hardenings all proceed concurrently (Wave 3, width 4).
- US1 and US2 pipeline against each other through Waves 4–6.
- **No intra-`bootstrap.sh` or intra-`check-conformance.py` parallelism** — each is one file; splitting would only serialize on itself.

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries,
> [P] markers, TDD ordering, and graphify dependency edges. Tasks within one parallel
> wave have all dependencies satisfied by earlier waves and disjoint mutable-file sets.
> Setup and Foundational phases are serial barriers; parallelism is cross-story.

- Wave 1  [serial]   : T001                                    # Phase 1 Setup — pre-change baseline
- Wave 2  [serial]   : T002                                    # Phase 2 Foundational — FR-015 allowlist guard (blocks all stories)
- Wave 3  [parallel] : T003 [US1], T007 [US2], T013 [US3], T015 [US3]   # widest wave (4)
- Wave 4  [parallel] : T004 [US1], T008 [US2]
- Wave 5  [parallel] : T005 [US1], T009 [US2]
- Wave 6  [parallel] : T006 [US1], T010 [US2]
- Wave 7  [serial]   : T012 [US3]                              # I-23 lock-step; .specify/ mirror resync + git run.sh guard
- Wave 8  [serial]   : T014 [US3]                              # I-26; contends with T012 on the .specify/ installed mirror
- Wave 9  [serial]   : T011 [US2]                              # shares extensions/workforce/test/run.sh with T002
- Wave 10 [serial]   : T016                                    # quickstart integration gate (all 10 SCs)
- Wave 11 [serial]   : T017                                    # docs/90 close-out — mandated final step (R1-S20)
- Wave 12 [serial]   : T018                                    # final allowlist guard + full-suite verification

### Task annotations

- T001  files=(none — read-only harness run)                       deps=-                          mutates=-
- T002  files=extensions/workforce/test/run.sh                      deps=T001                       mutates=extensions/workforce/test/run.sh
- T003  files=bootstrap.sh                                          deps=T002                       mutates=(new)
- T004  files=bootstrap.sh                                          deps=T003                       mutates=bootstrap.sh
- T005  files=bootstrap.sh                                          deps=T004                       mutates=bootstrap.sh
- T006  files=README.md                                             deps=T003                       mutates=README.md
- T007  files=specs/008-pre-public-maintenance/fixtures/            deps=T002                       mutates=(new)
- T008  files=extensions/workforce/extension/scripts/check-conformance.py  deps=T007                 mutates=(new)
- T009  files=extensions/workforce/extension/scripts/check-conformance.py  deps=T008                 mutates=check-conformance.py
- T010  files=extensions/workforce/extension/scripts/check-conformance.py  deps=T009                 mutates=check-conformance.py
- T011  files=extensions/workforce/test/run.sh                      deps=T002,T007,T010             mutates=extensions/workforce/test/run.sh
- T012  files=extensions/git/install.sh, extensions/git/test/run.sh, .specify/extensions.yml   deps=T002   mutates=all three (extension.yml read-only)
- T013  files=extensions/council/skills/speckit-council/SKILL.md, extensions/council/skills/speckit-council-triage/SKILL.md   deps=T002   mutates=both
- T014  files=extensions/graphify/extension/scripts/augment_merge.py, extensions/graphify/test/run.sh, .specify/extensions.yml   deps=T012   mutates=all three
- T015  files=extensions/graphify/skills/speckit-implement-parallel/SKILL.md   deps=T002, T007 (coverage-only)   mutates=implement-parallel/SKILL.md
- T016  files=(none — executes quickstart.md)                       deps=T006,T011,T012,T014,T015   mutates=-
- T017  files=docs/90-DECISIONS-AND-IDEAS.md                        deps=T016                       mutates=docs/90-DECISIONS-AND-IDEAS.md
- T018  files=(none — read-only verification)                       deps=T017                       mutates=-

### Shared-file serialization

Encoding the four collision-watch constraints from `graphify-context.md` as explicit depends-on edges (R1-S12):

- `extensions/workforce/test/run.sh` — touched by **T002** (FR-015 allowlist guard) and **T011** (checker fixture wiring + R1-S21/S22 guards) → `T011 deps=T002`, pinned to separate serial waves (2 and 9); never co-scheduled.
- `.specify/extensions.yml` (installed manifest mirror) — touched by **T012** (explicit R1-S23 resync) and **T014** (graphify script reinstall) → `T014 deps=T012`, serial waves 7 and 8. Concurrent installs would lost-update the shared merged manifest (install-mirror-drift precedent). **R1-S23 satisfied**: the resync is sub-step 1 of T012, strictly before the guard runs in sub-step 2.
- `docs/90-DECISIONS-AND-IDEAS.md` — the single append target all six items close into. Confined to **T017 alone** in a terminal serial wave rather than split per-item (R1-S20/FR-016); no other task writes it.
- `README.md` — touched only by **T006** (I-32 quickstart). No other item touches it, so no serialization is forced; retained on the watch list in case a later task claims it.
- `extensions/git/extension/extension.yml` — **read-only** in T012 (guard source of truth), so the graphify-context "manifest ↔ manual block edited in lock-step" pairing resolves to a single-writer case; both are still held in one non-splittable task per R1-S11.

### `[P]` reconciliation vs. naive generation

| Task | Naive | Verified | Reason |
|------|-------|----------|--------|
| T013 | `[P]` | **`[P]` kept** | Council `SKILL.md` prose only; disjoint from every other wave-3 file; no reinstall, no shared mirror. |
| T015 | `[P]` | **`[P]` kept** | `implement-parallel/SKILL.md` prose only; disjoint from T013/T003/T007. Its T007 edge is test-coverage, not code — it does not force serialization. |
| T003 | `[P]` | **`[P]` kept** | New root file, no importers in the graph (`graphify-context.md`: "not in graph — new code"). |
| T007 | `[P]` | **`[P]` kept** | New fixture tree; no existing node depends on it. |
| T014 | `[P]` | **`[P]` STRIPPED** | Contends with T012 on `.specify/extensions.yml`, the shared installed-manifest mirror — not visible from `files=` disjointness alone; surfaced by the collision-watch list. |
| T011 | `[P]` | **`[P]` STRIPPED** | Same file as T002 (`extensions/workforce/test/run.sh`). |
| T004, T005 | `[P]` | **`[P]` STRIPPED** | Same file as T003 (`bootstrap.sh`). |
| T009, T010 | `[P]` | **`[P]` STRIPPED** | Same file as T008 (`check-conformance.py`). |
| T012 | `[P]` | **`[P]` STRIPPED** | Writes the shared `.specify/` mirror; internally lock-step (R1-S11) and non-splittable. |
| T017 | `[P]` | **`[P]` STRIPPED** | Single shared `docs/90` append target; mandated final serialized step (R1-S20). |

**Graph confidence**: `graphify-context.md` was generated 2026-07-16 from `graphify-out/graph.json` (4863 nodes, 5788 edges, repo scope) and is fresh as of this run. Two deliverables — `bootstrap.sh` and `check-conformance.py` — are **new code absent from the graph**, so their `[P]` markers rest on the stock heuristic (new file, no importers) rather than verified edges. Every other marker is graph-backed. The `.specify/extensions.yml` contention is drawn from the collision-watch list, not from import edges — it is an installer side-effect the import graph cannot see.

---

## Implementation Strategy

### MVP First (US1 only)

1. T001 → T002 (setup + scope guard)
2. T003 → T004 → T005 → T006
3. **STOP and VALIDATE**: run the `quickstart.md` US1 block against a throwaway repo — SC-001/002/003 (provisional, per R1-S06)
4. US1 is independently shippable and delivers the highest adopter value alone.

### Incremental Delivery

1. Setup + Foundational → scope invariant armed
2. + US1 → clone-free install (MVP)
3. + US2 → contract drift caught by machine
4. + US3 → four latent defects hardened
5. + Polish → quickstart gate, `docs/90` close-out, final verification

---

## Notes

- `[P]` = graph-verified disjoint, not an LLM guess — see the reconciliation table.
- Commit after each task or logical group; the `after_implement` hook backstops the phase boundary.
- **Do NOT wire `check-conformance.py` into any `before_*`/`after_*` hook** (R1-S14) — it is detectable-on-demand, like `/speckit-validate-profile`. Wiring an enforcement point would touch the gate/phase semantics FR-015 forbids.
- **I-29 applies forward only** (R1-S13) — no back-fill of already-written council round artifacts.
- Three of the four US3 hardenings carry a disclosed coverage gap (R1-S15); this is stated, not hidden.
