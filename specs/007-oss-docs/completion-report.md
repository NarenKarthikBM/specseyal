---
feature: 007-oss-docs
phase: complete
status: partial
---

## Implementation Complete — OSS Front Door + Profile Contract Validator

**Waves run:** 4 (all `outcome: success` per `implement.log.md`). **Widest parallel wave:** 9 agents — Wave 1 dispatched both arms' leaves concurrently (T001–T007, T009, T010), disjoint trees, no shared-file contention. Wave 2 = 5 agents (T008, T011–T014); Wave 3 = 1 (T015, the fail-closed hook go-live, serial by design — mutates `.specify/extensions.yml`); Wave 4 = 1 (T017, the quickstart integration gate over both arms). Wave 5 (T016) is **not** an implement wave — it is post-merge housekeeping and has not run (see `### Partial/Degraded`).

**Roster summary** (from `agents/assignment.md` `### Roster approved` — gate `approved` by Naren Karthik B M @ 2026-07-16T17:02:35Z; 12 distinct assemblies over the 17 roster tasks, 11 dispatched + 1 deferred). Every assembly ran on **Sonnet**; every injected skill was **library**-sourced — a gap-free roster (SC-005), zero `built` skills — and **every row carried zero elevated grants** (grant tripwire clear):

- **`agt_devtools_cli`** — T001 (+ `skl_extension_tree_scaffold`, `skl_cli_command_wrapper`, `skl_quickstart_integration_gate`), T002/T005/T006/T007 (+ `skl_cli_command_wrapper`), T008 (+ `skl_shell_scripting`), T009 (+ `skl_yaml_hooks`, `skl_docs_contract_authoring`, `skl_cli_command_wrapper`). *(T016's row is also `agt_devtools_cli` + `skl_refactor_discipline`/`skl_golden_fixture_discipline` — assembled but **not dispatched**, deferred to post-merge.)*
- **`agt_qa_automation`** — T010 (+ `skl_yaml_hooks`, `skl_golden_fixture_discipline`), T011 (+ `skl_shell_scripting`, `skl_golden_fixture_discipline`), T012 (+ `skl_installer_hygiene`, `skl_shell_scripting`), T013/T017 (+ `skl_refactor_discipline`, `skl_quickstart_integration_gate`).
- **`agt_generic`** ⚠ **empty-lane fallback (FR-016)** — T003 (`docs × general`), T004 (`docs × security`), T015 (`scaffold × security`); each matched no `(type, specialization)` base lane, assembled onto `agt_generic` with relevant skills, accepted at the gate with no new base lane opened.
- **`agt_security`** — T014 (+ `skl_cli_command_wrapper`).

One skill trimmed at the cap-3 (T009: `skl_quickstart_integration_gate`, tag-Jaccard rank 4), recorded at the gate — never silently dropped.

### Completed (16/17)

16 of 17 tasks marked `[X]` in `tasks.md`, across 4 green waves. The 17th (T016) is a post-merge task that structurally cannot run at the `complete` phase — detailed under `### Partial/Degraded`, not here.

| Task | Arm / Story | What | Wave |
|---|---|---|---|
| T001 | A · US1 | `README.md` — elevator pitch, full pipeline sequence, quickstart, repo layout, license/billing stance, graphify home (FR-001–005/012) | 1 |
| T002 | A · US2 | `CONTRIBUTING.md` — log discipline, dogfooding rule, commit/branch conventions (FR-006) | 1 |
| T003 | A · US2 | `CODE_OF_CONDUCT.md` — Contributor Covenant + contact channel (FR-007) | 1 |
| T004 | A · US2 | `SECURITY.md` — private vulnerability channel + scope (FR-008) | 1 |
| T005 | A · US2 | `.github/ISSUE_TEMPLATE/bug_report.md` (FR-009) | 1 |
| T006 | A · US2 | `.github/ISSUE_TEMPLATE/feature_request.md` (FR-009) | 1 |
| T007 | A · US2 | `.github/PULL_REQUEST_TEMPLATE.md` (FR-009) | 1 |
| T009 | B · US3 | `validate-profile.py` — dependency-free contract validator (FR-014/016, D-c/D-d/D-e) | 1 |
| T010 | B · US3 | Committed fixture set under `test/fixtures/profile/` — 1 conformant + malformed classes (FR-017) | 1 |
| T008 | A · US2 | `scripts/check-oss-docs.sh` — reference-resolution (I-REF/SC-003) + leakage (I-CLEAN/SC-004) check | 2 |
| T011 | B · US3 | `test_profile.sh` + `run.sh` registration — both-branch golden/regression harness (FR-017/SC-007) | 2 |
| T012 | B · US3 | Tracked install mirror `.specify/extensions/workforce/scripts/validate-profile.py` via workforce reinstall (R1-S15) | 2 |
| T013 | B · US3 | Adoption pre-flight — validator PASSes on every committed `specs/*/profile.yaml` (000,001,003–007) before go-live | 2 |
| T014 | B · US3 | FR-019 wrapper skill + command provenance (`speckit-validate-profile`, git-ext owned, D-f) | 2 |
| T015 | B · US3 | Fail-closed validate-profile hook @ priority 1 on `before_plan`+`before_tasks`+`before_implement` (R1-S03/S08) | 3 |
| T017 | B · US3 | Quickstart integration gate — Arm B V1–V7 + Arm A D1–D5, binding every SC to an executed check | 4 |

### Partial/Degraded

**T016 — post-merge graphify graph refresh — deliberately deferred, not degraded.** T016 is the sole unchecked task (`[ ]`). This is **by design, not a failure or a partial result**: the task itself (`tasks.md` §Phase 6) and the Execution Waves DAG both classify it as **"Post-merge … housekeeping — runs after `git-cleanup`, outside the implement waves"** (Wave 5). It regenerates `graphify-out/graph.json` so FR-018's new cross-extension coupling (`validate-profile.py` → `profile_key.py`) becomes graph-checkable. It **cannot** run at the `complete` phase — its precondition is branch integration to `base_branch`, which happens downstream in `/speckit-git-cleanup`. No implement wave attempted it; no wave reported partial or degraded.

Consequently `### Completed` reads 16/17 and `status` is `partial` rather than `success` — the honest signal that one task genuinely remains. It is not an unresolved defect. Once T016 runs post-merge, a re-run of `/speckit-complete` (idempotent, re-derives from `tasks.md`) will read 17/17 and `success`.

### Failed

None. All 4 implement waves logged `outcome: success`; no task failed.

### Integration status

Evidence source: `implement.log.md` (all 4 waves `success`) + `tasks.md` task definitions + the branch's `T017` gate commit. Claims below are what the run can back, not a general "looks fine."

- **Arm B — profile validator, mechanically enforced end-to-end.**
  - `validate-profile.py` (T009) authored dependency-free (no hard `import yaml`, no `requirements.txt`) reusing `profile_key.py`'s interpreter ladder with a timeout-bounded final `uv` rung (R1-S06); a missing PyYAML interpreter is a **loud non-zero**, never a silent "absent" (SC-010/FR-016).
  - The both-branch harness `test_profile.sh`, registered in `run.sh` (T011, sole toucher), passes on the wave's `success` outcome: every T010 fixture asserts its exit code; the **real** `specs/000-sample/profile.yaml` PASSes (SC-008); an absent path exits 0 (P1); ≥1 case asserts on **stderr content** — the message names the offending key, never a raw traceback (R1-S10); the FR-018 **enum-equivalence** assertion holds — the validator's accepted `deck_render` set equals `profile_key.DECK_RENDER_ENUM` (R1-S07); the no-PyYAML branch is forced via an interpreter-shadowing shim (R1-S09); the committed wall-clock `<2s` assertion holds (SC-010/R1-S18).
  - **Adoption pre-flight clean (T013):** the validator PASSes on every currently-committed `specs/*/profile.yaml` (`000,001,003,004,005,006,007`) — so wiring the hook live cannot retroactively hard-block an in-flight feature's `plan` phase.
  - **Fail-closed hook live (T015):** registered at **priority 1** in `.specify/extensions.yml` at `before_plan` AND `before_tasks` AND `before_implement` — the actual profile-consumption points, not `before_plan` alone (R1-S03/S21) — via the git-ext manifest + reinstall, not a hand-edit of the generated file. Non-zero ⇒ hard-block, **no fail-open bypass by design** (R1-S08). Install mirror (T012) produced by the workforce installer, `run.sh` §1 reinstall-survival still guards it against drift.
- **Arm A — OSS front door, reference-clean.** All front-door docs authored (README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, `.github/ISSUE_TEMPLATE/*`, `.github/PULL_REQUEST_TEMPLATE.md`). The committed, standalone acceptance check `scripts/check-oss-docs.sh` (T008) covers all Arm A docs: every cited repo path/command/extension resolves (I-REF/SC-003) and no machine-specific absolute paths (`/Users/…`, `/home/…`) or private data leak (I-CLEAN/SC-004) — green at authoring.
- **Integration gate — GATE PASS (T017, Wave 4, `success`).** The full `quickstart.md` validation ran as the on-branch gate: Arm B `V1–V7` (SC-007/008/009/010 + the FR-018 `deck_render` subsumption + the V6 `schema_version=="1.0"` regression) and Arm A `D1–D5` (SC-001..006, SC-011) — every Success Criterion SC-001..011 bound to an executed check per the quickstart SC→check map, not a sampled spot-check.
- **Shared-file integrations clean.** `run.sh` (sole toucher T011) and `.specify/extensions.yml` + `extensions/git/extension/extension.yml` (sole toucher T015, regenerated after the T012 reinstall) each had exactly one writer, no co-scheduling. The two graphify-flagged shared/mutable files — `extensions/deck-render/extension/scripts/profile_key.py` and `docs/contracts/profile-schema.md` — were **not touched by any task** (D-d local-constant pin; D-e enforce-as-written), so they forced no serialization and carry no merge risk.

### Key results

- **OSS front door complete** — README + community-health docs (CONTRIBUTING/CODE_OF_CONDUCT/SECURITY) + `.github/` issue & PR templates, all reference-resolving and leakage-free (SC-001..006), with a committed re-runnable acceptance check (`check-oss-docs.sh`).
- **Profile contract now mechanically enforced** — `validate-profile.py` closes the `council_tier: standrad` silent-degrade class (SC-009), makes the M0 fixture `specs/000-sample/profile.yaml` executable (SC-008), subsumes 006's `deck_render` check via a T011-guarded enum-equivalence (FR-018), and is wired **fail-closed** at all three profile-consumption points with no fail-open bypass (FR-019/R1-S08). Dependency-free, `<2s` (SC-010).
- **Integration gate GATE PASS** — all of SC-001..011 bound to executed checks (V1–V7 + D1–D5).
- **16/17 tasks over 4 green waves**; T016 (post-merge graph refresh) intentionally outstanding, to run after `/speckit-git-cleanup`.
- **Tasks-note flag resolved in-implement:** the plan's D-c said the `schema_version` value-check is exact-match `1.2`, but `1.2` is the contract-*document* version — the field is `"1.0"` in every committed profile; T009/T010 correctly target `"1.0"`, so the FR-015/SC-008/V6 regression passes rather than failing. Residual accepted (R1-S16): only the `deck_render` enum is equivalence-guarded; broader prose-vs-code drift between `profile-schema.md` and the validator remains unautomated, flagged and deferred to the future schema amendment (D-e).
- **α-polish arc note:** 007 is the third and closing α-polish feature (005 → 006 → 007). With the OSS front door in place, the D73 public-flip visibility commit (repo → public + `speckit-graphifyy` archival with a pointer) is unblocked — a separate downstream commit, not part of this phase.
