# Tasks: OSS Front Door + Profile Contract Validator

**Input**: Design documents from `/specs/007-oss-docs/`

**Prerequisites**: plan.md (required, council-bound @ `a147b4d`), spec.md, research.md, data-model.md, contracts/validate-profile.md, quickstart.md, graphify-context.md

**Tests**: Included for Arm B (US3) — the spec *explicitly requires* committed golden/regression coverage (FR-017/SC-007) and the mechanical docs-check (FR-010/FR-011). Arm A (docs) carries no unit tests; its acceptance is the committed reference-resolution + leakage script.

**Organization**: Two independent arms (plan §Structure Decision, R1-S17), sequenced as separate task chains so a stall in one never blocks the other:

- **Arm A — OSS front door** = US1 (README, P1 · MVP) + US2 (community-health docs, P2). Greenfield markdown, no code blast radius.
- **Arm B — profile validator** = US3 (`validate-profile.py` + tests + FR-018 enum pin + FR-019 enforcement wiring, P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: graph-verified parallel-safe — disjoint files, no blast-radius overlap, no shared/mutable-file collision with its wave-mates (Step D reconciled against `graphify-context.md`).
- **[Story]**: US1 / US2 / US3.
- Exact file paths in every description; full annotations in **## Execution Waves**.

## Path Conventions

Monorepo pipeline-extension + docs feature (plan §Project Type) — **not** a `src/`+`tests/` app. Real homes:
- Validator: `extensions/workforce/extension/scripts/` (+ tracked install mirror `.specify/extensions/workforce/scripts/`) — beside the two existing general validators.
- Validator tests: `extensions/workforce/test/`.
- FR-019 wrapper skill: `extensions/git/skills/` (mirrors `verify-gate`, D-f).
- OSS docs: repo root + `.github/`.

---

## Phase 1: Setup (Shared Infrastructure)

**None.** The sole feature-config artifact — `specs/007-oss-docs/profile.yaml` (standard tier, both gates `human`) — **already exists on disk** (authored at plan time; it is Arm B's first dogfood subject). The two arms share no other scaffolding, so there is no Setup barrier.

---

## Phase 2: Foundational (Blocking Prerequisites)

**None.** Arm A and Arm B share zero code; neither arm has cross-story foundational work. Within Arm B, `validate-profile.py` (T009) is US3 *implementation*, not a cross-arm prerequisite — it blocks only its own tests/wiring, never Arm A.

**Checkpoint**: Both arms may begin immediately (Wave 1).

---

## Phase 3: User Story 1 - A newcomer understands what SpecSeyal is and how to run it (Priority: P1) 🎯 MVP

**Goal**: A root `README.md` that lets a context-free reader learn what SpecSeyal is, the pipeline shape, the first command, and where the canonical docs live — without opening another file.

**Independent Test**: Hand the README alone to an unfamiliar reader; verify they can state (a) what SpecSeyal does, (b) the pipeline phase sequence, (c) the first command to run, (d) the location of `docs/00`/`docs/05`/`docs/90` — without opening any other file (SC-001/SC-002).

### Implementation for User Story 1

- [X] T001 [P] [US1] Author `README.md` at repo root — **FR-001** one-paragraph elevator pitch (what SpecSeyal is; problem solved; relation to GitHub Spec Kit + graphify); **FR-002** the full end-to-end pipeline sequence verbatim: `specify → clarify → plan → council → tasks → analyze → categorize → agents → parallel-implement → complete → testing` (data-model §4, verified against `.claude/skills/speckit-*`); **FR-003** quickstart — prereqs (Claude Code on subscription auth, `ANTHROPIC_API_KEY` unset), install (D45), first commands `/graphify` then `/speckit-specify`; **FR-004** repo layout (`extensions/`, `platform/`, `docs/`, `specs/`) + links to `docs/00-VISION-AND-ARCHITECTURE.md`, `docs/05-IMPLEMENTATION-PLAN.md`, `docs/90-DECISIONS-AND-IDEAS.md`; **FR-005** license (MIT, `LICENSE`) + subscription-only billing stance (D28 — never sets/relies on `ANTHROPIC_API_KEY`); **FR-012** graphify's in-repo home `extensions/graphify/` (engine is the upstream `graphifyy` pip package, D75). Every cited path/command/extension MUST resolve at authoring (FR-010); zero machine-specific paths or private data (FR-011).

**Checkpoint**: Shipping only T001 already yields a non-embarrassing public repo (the irreducible MVP).

---

## Phase 4: User Story 2 - A prospective contributor knows how to contribute correctly (Priority: P2)

**Goal**: Contribution guide + community-health files + `.github/` templates so a would-be contributor can commit correctly, file issues/PRs, and report vulnerabilities privately — without reading source.

**Independent Test**: Hand CONTRIBUTING + CODE_OF_CONDUCT + SECURITY + templates to a contributor; verify they can (a) produce a phase-tagged commit + matching D-row/I-row, (b) find how to file an issue/PR, (c) find the private vulnerability channel — without reading source (SC-005/SC-006).

### Implementation for User Story 2

- [X] T002 [P] [US2] Author `CONTRIBUTING.md` at repo root — **FR-006**: the non-negotiable log discipline (every decision → a D-row in docs/90 same session; every idea → an I-row); the dogfooding rule (the pipeline builds itself, each milestone through the pipeline); artifact-is-the-contract; commit/branch conventions (phase-tagged commits; branch named from the spec ID — D25). All cited paths/commands resolve (FR-010); no leakage (FR-011).
- [X] T003 [P] [US2] Author `CODE_OF_CONDUCT.md` at repo root — **FR-007**: Contributor Covenant (data-model §1), with a real contact/enforcement channel (no leaked personal data beyond the author name already in `LICENSE`, FR-011).
- [X] T004 [P] [US2] Author `SECURITY.md` at repo root — **FR-008**: a **private** vulnerability-reporting channel (GitHub private security advisories) + supported scope. No machine-specific paths (FR-011).
- [X] T005 [P] [US2] Author `.github/ISSUE_TEMPLATE/bug_report.md` — **FR-009**: prompts for repro steps + affected artifact/phase (creates `.github/ISSUE_TEMPLATE/`).
- [X] T006 [P] [US2] Author `.github/ISSUE_TEMPLATE/feature_request.md` — **FR-009**: prompts for motivation + which pipeline phase/extension it touches.
- [X] T007 [P] [US2] Author `.github/PULL_REQUEST_TEMPLATE.md` — **FR-009**: prompts for a phase-tagged commit + the matching D-row/I-row per log discipline.
- [ ] T008 [US2] Author `scripts/check-oss-docs.sh` — the **committed, standalone, re-runnable** Arm-A acceptance check (R1-S20; no CI wiring, matching feature scope). Covers **all** Arm A docs (US1 + US2): (a) **I-REF / SC-003** — extract every cited repo path/command/extension from `README.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md .github/` and assert each resolves (quickstart D2); (b) **I-CLEAN / SC-004** — grep for machine-specific absolute paths (`/Users/…`, `/home/…`) and private data, asserting none (quickstart D3). Non-zero + named offender on any failure; runs green at authoring. *(Home `scripts/` is a new top-level dir — analyze/implement may relocate to `.specify/scripts/bash/`; keep it out of the FR-004 "canonical layout" prose either way.)*

**Checkpoint**: US1 + US2 both independently satisfied; front door presentable.

---

## Phase 5: User Story 3 - A malformed profile.yaml fails mechanically instead of degrading silently (Priority: P3)

**Goal**: `validate-profile.py` — a dependency-free general contract validator that enforces `docs/contracts/profile-schema.md` exactly, makes `specs/000-sample/profile.yaml` executable, catches the `council_tier: standrad` silent-degrade class, subsumes 006's `deck_render` check, and is (per the council-bound plan) wired fail-closed at the pipeline's consumption points.

**Independent Test**: Run the validator over the committed fixture set — conformant profiles pass; each malformed class (out-of-enum, unknown key, unsatisfied `full_auto` handshake, gate-scalar, feature-mismatch, `max_rounds>1`, out-of-enum `deck_render`, bad YAML) fails non-zero with a named cause; `specs/000-sample/profile.yaml` passes (SC-007/SC-008/SC-009).

### Tests & fixtures for User Story 3 ⚠️

- [X] T010 [P] [US3] Author the committed fixture set under `extensions/workforce/test/fixtures/profile/` (pure data — verdicts derived from the **contract**, not the validator, so parallel-safe with T009). One conformant + one per targeted malformed class (FR-017), plus the council-pinned extras:
  - `conformant.yaml` → exit 0
  - `full-auto-satisfied.yaml` → exit 0 — `full_auto: true` + **both** gates `auto` (P2∧P3 PASS branch, **R1-S01**)
  - `defaults-omitted.yaml` → exit 0 — `council_tier`/`max_rounds`/`reopen_tier` absent ⇒ defaults `full`/`1`/`auto`; kept **separate** from wrong-value fixtures (**R1-S22**)
  - `workforce-auto-alone.yaml` → exit 0 — `gates.workforce.mode: auto` with `full_auto: false` (P4 — MUST NOT over-reject)
  - `out-of-enum.yaml` → non-zero — `council_tier: standrad` (**SC-009**)
  - `unknown-key.yaml` → non-zero — a top-level unknown key
  - `unknown-key-nested.yaml` → non-zero — unknown key under `gates.council` (**R1-S19**, so a recursive-validation bug can't pass one depth)
  - `schema-version-mismatch.yaml` → non-zero — `schema_version: "2.0"` value-check (**R1-S04**; enforce equals **`"1.0"`**, the value every real profile uses — NOT the plan's "1.2", which is the contract-*doc* version)
  - `full-auto-unsatisfied.yaml` → non-zero — `full_auto: true` with a `human` mode (P3)
  - `council-auto-no-fullauto.yaml` → non-zero — `gates.council.mode: auto` with `full_auto: false` (P2)
  - `gate-scalar.yaml` → non-zero — `gates.council: human` scalar (mapping required)
  - `feature-mismatch.yaml` → non-zero — `feature` ≠ containing dir name
  - `max-rounds-2.yaml` → non-zero — `gates.council.max_rounds: 2`
  - `deck-render-out-of-enum.yaml` → non-zero — `deck_render: sparkle` (**FR-018**)
  - `bad-yaml.yaml` → non-zero (loud) — malformed YAML / merge-conflict marker
- [ ] T011 [US3] Author `extensions/workforce/test/test_profile.sh` and **register it in `extensions/workforce/test/run.sh`** — the both-branch golden/regression harness (FR-017/SC-007), asserting: every T010 fixture's exit code; the **real** `specs/000-sample/profile.yaml` passes (**SC-008**); an absent path exits 0 (P1); **≥1 case asserts on stderr *content*** — the message names the offending key and is never a raw parser traceback (**R1-S10**); the **FR-018 enum-equivalence** assertion — the validator's accepted `deck_render` set **equals** `profile_key.DECK_RENDER_ENUM` (**R1-S07**); the **no-PyYAML-interpreter** branch forced via a **PATH/interpreter-shadowing shim** the harness introduces (**R1-S09**); a **committed wall-clock `<2s` assertion** (**R1-S18/SC-010**). Depends on T009 + T010. *(Mutates the shared `run.sh` — sole toucher.)*

### Implementation for User Story 3

- [X] T009 [P] [US3] Author `extensions/workforce/extension/scripts/validate-profile.py` — the general contract validator (mirrors `validate-skill.py` / `validate-categorization.py`: `main()` → non-zero on failure, small `check_*`/`validate_*` predicates, a `ValidationResult`-style accumulator, a shape-error exception, embedded self-test). Implements contracts/validate-profile.md + data-model §3 in full:
  - **CLI**: `[--feature <dir> | <profile-path>]`, defaulting to `./profile.yaml`; runnable directly, single reserved non-zero code.
  - **YAML (FR-016/SC-010)**: no hard `import yaml`, no `requirements.txt`; reuse `profile_key.py`'s interpreter ladder (current → `graphify`/`specify` shebang → `python3` → `python` → `uv run --with pyyaml`), the final `uv` rung **bounded by a short timeout, fail-fast non-zero on timeout** so an offline host cannot hang (**R1-S06**). No reachable PyYAML interpreter ⇒ **loud non-zero**, never a silent "absent".
  - **Rules (D-c)**: required keys (`schema_version` string **== `"1.0"`** value-check R1-S04, `feature` == containing dir name, `full_auto` bool, `gates`/`gates.council`/`gates.council.mode`/`gates.workforce`/`gates.workforce.mode`); gate blocks are **mappings not scalars**; closed enums `council_tier∈{full,standard}`, `mode∈{human,auto}`, `reopen_tier∈{auto,delta,full}`, `deck_render∈DECK_RENDER_ENUM`; `max_rounds` optional int **must be `1`**; **unknown key ⇒ error at every nesting level** (recursive).
  - **`full_auto` handshake**: P1 absent-file ⇒ VALID; P2 `council.mode: auto` requires `full_auto: true`; P3 `full_auto: true` requires **both** modes `auto`; P4 workforce-auto-alone valid; **P5 not machine-enforced** (contract says human-reviewed).
  - **D-e (R1-S12)**: enforce `reopen_tier` (a *live* triage key) **and** `max_rounds` (genuinely inert) as written — **prune neither**; the closed-enum check catches a typo in either.
  - **FR-018 (D-d/R1-S07)**: hold `DECK_RENDER_ENUM` as a **pinned local constant** (= `("none","technical","overview","both")`), guaranteed non-divergent by T011's committed equivalence test — **not** a fragile cross-tree runtime import; `profile_key.py` stays unchanged as SSOT + render-time resolver.
  - **Messages (FR-014/SC-007)**: every failure is non-zero **and** a human-readable stderr line naming the offending key/value — **never** an opaque traceback, never a silent fall-through to a "safe" default.
- [ ] T012 [US3] Materialize + commit the tracked install mirror `.specify/extensions/workforce/scripts/validate-profile.py` by running the workforce **install/reinstall** (`extensions/workforce/install.sh`) — the copy is produced by the repo's existing installer, **no second sync path** (R1-S15); confirm `run.sh` §1 reinstall-survival still guards it against drift. Depends on T009.
- [ ] T013 [US3] **Adoption pre-flight** (R1-S05): run `validate-profile.py` against **every** currently-committed `specs/*/profile.yaml` (`000,001,003,004,005,006,007`) and confirm all PASS — so wiring the fail-closed hook live cannot retroactively hard-block an in-flight feature's `plan` phase on a legitimate pre-existing profile. Must complete **before** T015. Verification-only (writes no file). Depends on T009.
- [ ] T014 [US3] Author the thin FR-019 wrapper skill `extensions/git/skills/speckit-validate-profile/SKILL.md` + command provenance `extensions/git/extension/commands/speckit.git.validate-profile.md` (cli-command-wrapper pattern, D-f — git ext owns it, mirroring `verify-gate`): resolve the feature's `profile.yaml` path → shell out to `validate-profile.py` → **hard-block on non-zero**. Installs to `.claude/skills/speckit-validate-profile/` via git install. Depends on T009.
- [ ] T015 [US3] Register the **mandatory, fail-closed** validate-profile hook at **PRIORITY 1** in `.specify/extensions.yml` (via the git-ext manifest `extensions/git/extension/extension.yml` + reinstall — not a hand-edit of the generated file), fired at **`before_plan` AND `before_tasks` AND `before_implement`** — the actual profile-consumption points, not `before_plan` alone (**R1-S03/S21**); non-zero ⇒ hard-block, **no fail-open bypass by design** (R1-S08). Depends on T011 (green suite — script hardened, R1-S11), T012 (installed copy the hook runs), T013 (pre-flight clean), T014 (wrapper skill). *(Mutates shared `.specify/extensions.yml` + git-ext manifest — gate-critical, serial.)*

**Checkpoint**: The profile contract is mechanically enforced; the M0 fixture is executable; the silent-degrade class is closed.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T017 [US3] Run the full `quickstart.md` validation as the on-branch integration gate — Arm B `V1–V7` (SC-007/008/009/010 + FR-018 subsumption + regression V6) and Arm A `D1–D5` (SC-001..006, SC-011) — binding **every** SC to an executed check per the quickstart SC→check map. Depends on T008, T011, T015.
- [ ] T016 [P] **Post-merge** graphify graph refresh (R1-S13) — after the feature branch integrates to `base_branch`, regenerate `graphify-out/graph.json` (via `/speckit-graphify-context` / graphify) so FR-018's new cross-extension coupling (`validate-profile.py` → `profile_key.py`) is **graph-checkable**, not resting on the stale graph + the equivalence test alone. Housekeeping — runs after `git-cleanup`, outside the implement waves.

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup / Foundational**: empty (see above) — no barrier; both arms start at Wave 1.
- **Arm A (US1 T001, US2 T002–T008)** and **Arm B (US3 T009–T015)**: fully independent chains (R1-S17) — run concurrently; a stall in one never blocks the other.
- **Polish (T016/T017)**: after the arms complete (T017 on-branch; T016 post-merge).

### Within Arm A
- T001 (README) and T002–T007 (community docs) are mutually independent, single-file, greenfield.
- T008 (docs-check) depends on **all** Arm A docs existing (it greps across them).

### Within Arm B
- T009 (validator) and T010 (fixtures) are independent (fixtures are contract-derived data).
- T011 (harness) depends on T009 + T010.
- T012 (install mirror), T013 (pre-flight), T014 (wrapper skill) each depend on T009.
- T015 (fail-closed hook — the go-live step) depends on **T011 (green) + T012 (installed) + T013 (pre-flight) + T014 (wrapper)** — R1-S11: a wave cannot register the hook before the script is hardened.

### Parallel Opportunities
- **Cross-arm**: all of Arm A and Arm B's leaf tasks run together in Wave 1.
- **Within Wave 1**: T001, T002, T003, T004, T005, T006, T007 (docs) ∥ T009 (validator) ∥ T010 (fixtures) — 9-wide, all disjoint files.
- **Not parallel**: T011 (touches shared `run.sh`), T015 (touches shared `.specify/extensions.yml`, gate-critical), T017 (integration gate over everything).

---

## Parallel Example: Wave 1

```bash
# Arm A docs (each a distinct new file):
Task: "Author README.md"                              # T001 [US1]
Task: "Author CONTRIBUTING.md"                         # T002 [US2]
Task: "Author CODE_OF_CONDUCT.md"                      # T003 [US2]
Task: "Author SECURITY.md"                             # T004 [US2]
Task: "Author .github/ISSUE_TEMPLATE/bug_report.md"    # T005 [US2]
Task: "Author .github/ISSUE_TEMPLATE/feature_request.md" # T006 [US2]
Task: "Author .github/PULL_REQUEST_TEMPLATE.md"        # T007 [US2]
# Arm B core (concurrently — disjoint tree):
Task: "Author extensions/workforce/extension/scripts/validate-profile.py"  # T009 [US3]
Task: "Author extensions/workforce/test/fixtures/profile/*.yaml"           # T010 [US3]
```

---

## Implementation Strategy

### MVP First (US1 only)
Ship **T001** (README) → a non-embarrassing public repo. Stop and validate against SC-001/SC-002.

### Incremental Delivery
1. Arm A: T001 → T002–T007 → T008 (front door presentable; SC-001..006).
2. Arm B: T009+T010 → T011 → T012/T013/T014 → T015 (contract enforced; SC-007..010).
3. T017 (quickstart integration gate) → T016 (post-merge graph refresh) → publishable (SC-011).

### Parallel Team Strategy
Assign Arm A and Arm B to independent workers from Wave 1; they never contend (disjoint trees). Only T015 (extensions.yml) and T011 (run.sh) are serial pinch-points inside Arm B.

---

## Notes

- `[P]` = graph-verified different files, no dependency, no shared/mutable collision (reconciled against `graphify-context.md`).
- **`profile_key.py` and `docs/contracts/profile-schema.md` are NOT edited** (D-d pins a local enum constant; D-e enforces the schema as written) — the two graphify-flagged collision files stay untouched, so no Arm B task contends on them.
- **Flag for `/speckit-analyze`**: plan.md D-c says the `schema_version` value-check is "exact-match `1.2`", but `1.2` is the *contract-document* version — the `schema_version` **field** is `"1.0"` in every committed profile; enforcing `"1.2"` would fail the FR-015/SC-008/V6 regression. Tasks T009/T010 target `"1.0"`.
- **Residual accepted (R1-S16)**: only the `deck_render` enum is equivalence-guarded; the broader prose-vs-code drift between `profile-schema.md` and `validate-profile.py` has no automated guard — flagged, out of scope, deferred to the future schema amendment (D-e).

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries,
> [P] markers, TDD/golden-fixture ordering, and graphify dependency edges. Tasks within one
> parallel wave have all dependencies satisfied by earlier waves and disjoint mutable-file sets.
> Setup and Foundational are empty for this feature (no shared code), so cross-arm parallelism
> begins at Wave 1; parallelism is cross-story (Arm A ∥ Arm B), never intra-chain past a shared file.

- Wave 1 [parallel] : T001 [US1], T002 [US2], T003 [US2], T004 [US2], T005 [US2], T006 [US2], T007 [US2], T009 [US3], T010 [US3]   # both arms' leaves — 9-wide, all disjoint
- Wave 2 [parallel] : T008 [US2], T011 [US3], T012 [US3], T013 [US3], T014 [US3]                                                   # arm-A docs-check + arm-B harness/mirror/pre-flight/wrapper
- Wave 3 [serial]   : T015 [US3]                                                                                                    # fail-closed hook go-live (mutates .specify/extensions.yml; gate-critical)
- Wave 4 [serial]   : T017 [US3]                                                                                                    # quickstart integration gate over both arms
- Wave 5 [serial]   : T016 [US3]                                                                                                    # post-merge graphify refresh (housekeeping, after git-cleanup)

### Task annotations
- T001  files=README.md                                                    deps=-              mutates=(new)
- T002  files=CONTRIBUTING.md                                              deps=-              mutates=(new)
- T003  files=CODE_OF_CONDUCT.md                                           deps=-              mutates=(new)
- T004  files=SECURITY.md                                                  deps=-              mutates=(new)
- T005  files=.github/ISSUE_TEMPLATE/bug_report.md                         deps=-              mutates=(new)
- T006  files=.github/ISSUE_TEMPLATE/feature_request.md                    deps=-              mutates=(new)
- T007  files=.github/PULL_REQUEST_TEMPLATE.md                             deps=-              mutates=(new)
- T008  files=scripts/check-oss-docs.sh                                    deps=T001,T002,T003,T004,T005,T006,T007   mutates=(new)
- T009  files=extensions/workforce/extension/scripts/validate-profile.py   deps=-              mutates=(new)
- T010  files=extensions/workforce/test/fixtures/profile/*.yaml            deps=-              mutates=(new)
- T011  files=extensions/workforce/test/test_profile.sh, extensions/workforce/test/run.sh   deps=T009,T010   mutates=extensions/workforce/test/run.sh
- T012  files=.specify/extensions/workforce/scripts/validate-profile.py    deps=T009           mutates=(new, via installer)
- T013  files=(none — verification run over specs/*/profile.yaml)          deps=T009           mutates=-
- T014  files=extensions/git/skills/speckit-validate-profile/SKILL.md, extensions/git/extension/commands/speckit.git.validate-profile.md   deps=T009   mutates=(new)
- T015  files=extensions/git/extension/extension.yml, .specify/extensions.yml   deps=T011,T012,T013,T014   mutates=.specify/extensions.yml, extensions/git/extension/extension.yml
- T016  files=graphify-out/graph.json                                      deps=T009 (post-merge)   mutates=graphify-out/graph.json
- T017  files=(none — quickstart validation run)                           deps=T008,T011,T015   mutates=-

### Shared-file serialization
- `extensions/workforce/test/run.sh` — touched only by **T011** (test registration). Sole toucher → no co-scheduling risk; pinned to its own wave slot.
- `.specify/extensions.yml` — touched only by **T015** (hook registration), regenerated from the git-ext manifest **after** T012's workforce reinstall → pinned to serial Wave 3, never co-scheduled.
- `extensions/git/extension/extension.yml` — touched only by **T015**.
- `extensions/deck-render/extension/scripts/profile_key.py` and `docs/contracts/profile-schema.md` — the two graphify-flagged shared/mutable files — are **not touched by any task** (D-d local-constant pin; D-e enforce-as-written), so they force no serialization.
