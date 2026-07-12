# Completion Report — 003-workforce (The Workforce Pair)

> The `complete`-phase artifact for the M3 dogfood build. Format: dev-orchestrator completion report
> (`speckit-implement-parallel`) + milestone-close context. **No trace is written for this phase.** `003`'s
> only live model traces are its **council** round (D56's first `standard`-tier measurement, `council_spend`
> 2,830,593 tok) + the categorizer/skill-builder runtime; the build itself was hand-orchestrated (the
> grandfathered bootstrap, S28) and its per-wave subagents are non-council bootstrap phases (D46/D35).

## Implementation Complete — speckit-ext-workforce

**Waves run: 10** (widest parallel wave: **8** subagents — Wave 3). **Roster:** Sonnet implementation
subagents (dev-orchestrator model, ~30 dispatches, **zero elevated grants** — the roster the human signed
approved-with-notes was all `none` after the D63 correction) for the authoring/logic/test tasks;
orchestrator glue for the tree scaffold (T001), the two review-caught fixes, and the T028/T029
session-limit handoff. Committed at **every** wave boundary via the live `002` machinery — `commit.sh impl
"wave K/10"` (`f8f1038` … `e8270ee`), scoped `[extra-path]` staging, commit-before-`[X]`. **The workforce
freshness machinery was grandfathered N/A for `003`'s own implement** (owner Option A, I-16/I-17 — the
gate is hand-signed; the binding hook is what `003` builds); the per-wave **commit** half of that
machinery was live and used throughout (note 4) and behaved cleanly.

### Completed (32 / 32)

| Wave | Tasks | Outcome |
|---|---|---|
| 1 | T001 | `extensions/workforce/` tree + README (glue) |
| 2 | T002, T003 | `extension.yml` (3 commands + 2 phase hooks; the `after_workforce_approve` emit-vs-git-handler split, S25), `workforce-config.yml` (7+5 seed manifest, `web_search: true`) (2 Sonnet) |
| 3 | T004, T006, T007, T009, T010, T015, T022, T023 | shared `frontmatter.py` (S21, `body_sha256` §2-exact), **seed library** (7 bases + 5 skills, all `grants: []`, `refactor-discipline` relocated), uninstaller (S07), categorizer + skill-builder prompts, assignment + skill-module templates (5 Sonnet) |
| 4 | T005, T008, T011, T014, T024 | **`assemble.py`** (§3, S01 total-order, S08 write-boundary, S18 hash, D48 guard — 1077 lines), `install.sh` (S06 flock+atomic-rename, S07 additive seed), the two validators, parser units (5 Sonnet) |
| 5 | T012, T016, T017, T018, T019, T021 | 3 command+skill pairs, **git-ext generalization** (`on-council-approve.sh` → gate-agnostic `on-gate-approve.sh` + `after_workforce_approve`, own source D57 S2), assembly golden tests (28 assertions) (5 Sonnet) |
| 6 | T013, T025 | categorize tests (19, incl. S22 no-write on file-state), ∅-match **gap-handoff** wiring (connected-components dedup, serial persistence, `--built-skill` re-run) (2 Sonnet) |
| 7 | T020 | reinstall git-ext + **workforce reinstall-survival regression** (26/26) + **I-18 `gates.sh` path fix** (glue + 1 Sonnet source-edit) |
| 8 | T026, T027, T030, T031 | skill-builder tests (29), **trace-assembly wiring** (graphify source, D57/I-14 seam), **D62 deck-prep** enrichment (council source), extension docs (4 Sonnet) |
| 9 | T028, T029 | trace↔roster diff (SC-008) + aggregate `test/run.sh` — **authored by the orchestrator inline** after the subagent hit the account session limit (see Partial/Degraded) |
| 10 | T032 | SC-009 dogfood exit verification (glue) |

### Partial / Degraded

None with residual debt. Two items handled mid-run:

- **T028/T029 — subagent hit the account session limit** (an infra event, resets 03:20 IST), terminating before it wrote anything. The orchestrator **authored both inline** (the trace-roster diff + fixtures + the aggregate harness), then ran them green (self-test + 12/0). **Trace-honesty check (the T005 / `002` Finding-5 precedent):** this leaves **no phantom trace and no coverage gap** — `extensions/workforce/**/test/**` is zero-AI by construction, so a hand-authored test carries the same guarantee as a subagent-authored one, and no `traces.jsonl` record was owed for a test-authoring subagent that never ran. The stall is an infra event, not a coverage or trace gap.
- **The prompt-over-stamping and the `gates.sh`-path defects** were caught in per-wave review and fixed **before** their wave committed (see Key results) — no debt carried.

### Failed
None.

### Integration status

- **Pipeline end-to-end (SC-009).** `categorize → assign → workforce-gate(approved-with-notes) → implement` ran on `003` itself: the real `categorization.md` validates (**32 tasks, `general` 0/32**, closed enums — SC-001/002), `assemble.py` produced the roster the human signed, and all 32 tasks were implemented per the roster's Sonnet-base assignments. ✅
- **Determinism (SC-005) proven on the dogfood artifact**, not just fixtures: `assemble.py` on the real `categorization.md` is **byte-identical across `PYTHONHASHSEED`** (S01 total-order; S18 snapshot hash identical). The assembly golden test asserts grant *order*, the D48 non-Sonnet-fixture error branch, the >3-candidate drop, the ≥2-grant union, and S15 gap-rerun stability (28 assertions). ✅
- **S07 flywheel-survival** green in `test/run.sh`: after a self + foreign (graphify) reinstall, the 7 seeded bases, the 5 seed skills, a **hand-edited** seed base (byte-identical), and a **planted generated** skill all survive — the seed library lives outside the install `rm -rf` payload. ✅
- **S02 workforce gate-write correct + live end-to-end** (the council's blocking finding, fully resolved): `on-gate-approve.sh <gate>` + `after_workforce_approve` + the I-18 path + the `install.sh` manual-fallback entry + **26/26 reinstall-survival**; git-ext reinstalled into real `.specify/` (council `verify-gate` still fresh; R1-S07 verify-gate-ahead-of-graphify order held). ✅
- **Trace loop-closure (SC-008):** `/speckit-implement-parallel` (graphify source, T027) now reads the approved roster and carries `agent_id`/`skills[]`/`elevated_grants[]` per dispatch; `trace-roster-diff.sh` mechanically rejects any trace whose assembly the roster didn't approve (a grant/skill leak), proven by a negative control. ✅
- **Zero-AI scripts** (SC-005's precondition): `frontmatter.py`, `assemble.py`, both validators, `trace-roster-diff.sh`, and the harnesses invoke no model; all shell passes `sh -n`. ✅

### Key results

- **Per-wave review paid — twice.** (1) **Wave-3 skill-builder prompt over-stamped `grants: [web_search]` on every generated module.** This is the **D63 distinction re-asserting itself inside the machine's own prompt**: the builder *role* holds `web_search` (capability authorization), but a generated module is not the site of that grant (dispatch approval). Left unfixed, every future gap-built skill would have propagated network reach into whatever task injected it — a grant explosion, the exact inverse of the tight A-2/D41 model. Corrected in review to default `grants: []`. (2) **I-18 — `gates.sh` bound the workforce gate to flat `assignment.md`, not `agents/assignment.md`** (artifact-layout §8 home); the first real `/speckit-workforce-approve` would have `die`d. Both were caught in the wave they landed in and fixed before commit — the case for reviewing every wave rather than trusting subagent self-reports.
- **The seed library is sparse on purpose, and `assemble.py` said so out loud.** On `003`'s own 32 tasks the matcher flags **14 ∅-match gaps** (tasks whose tags miss the 5 narrow seed skills) — a real, quantified **flywheel signal**: a first feature against a thin library builds many skills. Two levers govern the volume, and both are v0→v1 questions (routed to the dossier): **seed breadth** (more/broader seed skills → fewer gaps) and **gap-batching** (the connected-components dedup already bounds builds to *distinct tag-clusters*, so 14 gapped tasks ≠ 14 skills). The gap-free hand roster the human signed is the *bootstrap* answer (the Sonnet bases suffice); the tool's aggressive gap-detection is the *steady-state* answer. Both legitimate.
- **SC-001–009 proven.** The mechanical SCs are committed tests (`test/run.sh` 12/0, aggregating the assembly golden, the two validators, the parser units, and the SC-008 loop-closure); SC-009 is the dogfood chain this report closes.

## Milestone-close context

### M3 "Done when" (docs/05) — status
docs/05's exit — *"a feature's tasks get categorized, agents matched/generated, human approves the roster
at the workforce gate, and `implement-parallel` consumes the assignments"* — is **met**: `003` was
categorized (0/32 `general`), assembled onto 7 base specialists (5 exercised), signed at the workforce gate
(`approved-with-notes`, the system's roster **the first a human signed for grants** — and the first he
*corrected*, D63), and its 32 tasks implemented per that roster. The flywheel (skill-builder) is built and
tested but **did not fire on `003`'s own build** (the hand roster is gap-free by owner judgment); its first
real firing is a future feature's ∅-match or the S08 integration path.

### Findings adjudicated (owner rulings already recorded)
- **D63 (grant correction, at the gate).** Capability authorization (D60 — the builder *role* holds `web_search`) and dispatch approval (a gate approving the grants a dispatch's *work* needs) are distinct acts; `003`'s roster carries `elevated: none` on every row. The wave-3 prompt fix is D63 applied to the builder's own prompt.
- **I-16 / I-17 (git-ext workforce-freshness, grandfathered for `003`).** ① no bootstrap binding path in `verify-gate` (the feature that builds the binding can't bind its own gate); ② `[X]`-marking stales the workforce binding — a **general** defect (every feature's implement), surfaced because `003` is the first implement run under the live workforce machinery. Both **booked, not fixed** (Option A) — owner: **git-ext, a follow-up feature**.
- **I-18 (git-ext `gates.sh` workforce path) — FIXED here.** Unlike I-16/I-17, corrected in the S02 cluster (own source), because `003` *builds* the workforce gate-write and shipping it broken defeats the council's blocking S02 finding.
- **I-19 (spec-vs-skill drift) — parked for a ruling.** `spec.md` FR-020 + `contracts/commands.md` say workforce auto-mode is "only within `full_auto`"; `profile-schema.md` P4 says `gates.workforce.mode: auto` is valid standalone. The shipped `/speckit-workforce-approve` skill follows **P4** (more specific/recent). Moot for `003` (`gates.workforce: human`), but the drift is now embedded in a skill and **needs a D-row** — owner: **v0→v1 / contracts review**.

### Deferred / carried (each with owner)
- **The 14-gap flywheel signal + its two levers** (seed breadth, gap-batching) → **v0→v1 taxonomy review** (`docs/reviews/taxonomy-v0-evidence.md`). Steady-state build volume is a real design question this dogfood surfaced with a number.
- **`docs × devtools-cli` empty lane** (T031's README fell to `agt_generic`, FR-016 by design) → **v0→v1** (seed the lane, or widen `agt_devtools_cli`'s accepted types). One task's evidence (I-15).
- **Provisional bases unexercised** (`agt_backend_service`, `agt_data_persistence`, S11) — no `data-model` work in `003`; stay `provisional` → **v0→v1**.
- **FR-010 auto-mode gate-write** — the `/speckit-workforce-approve` auto codepath + git-ext's signer-agnostic `on-gate-approve.sh` are built; the full `full_auto` auto-trigger wiring rides with **M5/M6** (platform/SDK).
- **Promotion of generated skills** (`origin: generated` → `promoted`) stays **manual** (FR-009/D24) — no auto-promotion on stats in v1.
- **Mechanical `HookExecutor`** — enforcement stays prose-level; the code dispatcher is **M6** (D53).

### Next steps (this close-out)
1. **`/speckit-git-cleanup` for `003`** — the `002` machinery running the **full lifecycle on a sibling feature for the first time**: merge to `main`, cut annotated `complete/003-workforce`, retire the branch.
2. **Verify the workforce install on `main`** post-merge (commands resolve, hooks registered, `test/run.sh` green); commit as repo infrastructure (M1/M2 precedent).
3. **Assemble the v0→v1 evidence dossier** (`docs/reviews/taxonomy-v0-evidence.md`) — input to the review, no positions taken.
4. **M4** (testing agent + completion-report format) starts fresh, carrying I-16/I-17/I-19 and the v0→v1 dossier.

## Decisions & log
D63 (gate), I-16/I-17/I-18/I-19 recorded across triage/gate/implement; the per-wave session-log rows and the
**M3-CLOSED** mark land in `docs/90` / `docs/05` at close-out. This report is the `complete`-phase output;
`testing.md` (M4) is out of M3 scope.
