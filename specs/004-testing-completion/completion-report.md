---
feature: 004-testing-completion
phase: complete
status: success
---

## Implementation Complete — speckit-ext-testing (+ the I-17 workforce-freshness fix)

M4 built the pipeline's **4th extension** — the doc-only `testing` phase and the finalized `complete` phase — **and** landed the distinct I-17 gate-integrity prerequisite (workforce-freshness under `implement`). It is the pipeline's **first fully-unassisted run**: every upstream station was live machinery, not a grandfathered hand-pass.

**Shape:** 6 waves (widest parallel wave: **6 agents**, wave 4), preceded by a **pre-flight** that is *not* a wave (D69 — machinery that gates the waves is never itself a wave). Orchestrator: main-thread Opus (xhigh); every task dispatched as a Sonnet assembled agent per the workforce-gate-approved roster (`agents/assignment.md` @ `5a7f705`, bound in `gates.yml`).

**Roster (distinct assemblies that ran):**
- `agt_devtools_cli` — with `skl_installer_hygiene`+`skl_shell_scripting` (T001), `skl_yaml_hooks` (T002, T005), `skl_shell_scripting` (T004), `skl_docs_contract_authoring` (T009, T011, T017), and **bare, no skills** (T010 — the modal zero-injection case, not an omission).
- `agt_security` + `skl_shell_scripting` (T003 — the checkbox-delta classifier).
- `agt_qa_automation` — with `skl_shell_scripting` (T006, T007, T016), `skl_installer_hygiene`+`skl_shell_scripting` (T008, T018), `skl_refactor_discipline` (T019).
- `agt_ai_agents` — with `skl_docs_contract_authoring` (T012, T015), `skl_orchestration` (T013), `skl_dispatched_prompt_authoring` (T014).

All 19 elevated-grant cells were `none` — every dispatch ran on its base's core toolset alone (`elevated_grants: []` throughout; the workforce gate's grant tripwire was clear).

### Completed (19/19)

| Wave | Tasks | Outcome |
|---|---|---|
| pre-flight (not a wave) | T003–T008 | the bundled git-ext change: verify-gate.sh checkbox-delta classifier (T003), commit.sh `testing` enum (T004), `after_complete`/`after_testing` hooks (T005), the §6 I-17 + §7 SC-008 survival regressions (T006/T007), one reinstall + both regressions green (T008) |
| 1 | T001 | scaffold `extensions/testing/` packaging shell |
| 2 | T002 | testing-ext manifest + config (no hooks — D57 §9; `tester.model: sonnet`, `executed: none`) |
| 3 | T009, T012, T017 | completion-report + testing-doc contracts; artifact-layout §6 ownership |
| 4 | T010, T011, T013, T014, T015, T016 | both commands+skills, 4 templates, the SC/FR coverage validator |
| 5 | T018 | testing extension installed live |
| 6 | T019 | quickstart SC-001…010 validation map |

Every task is `[X]`; every wave's logged outcome is `success`.

### Partial/Degraded

None. One **infrastructure** interruption occurred but left no degraded artifact: Wave 3's first 3-concurrent dispatch hit a transient session-usage limit and all three agents failed **mid-read (wrote nothing)** — re-dispatched cleanly (a solo probe cleared the limit), and Wave 4 was then batched 3+3 (never 6) to stay under it. No task finished partial or degraded; no committed state was reworked.

### Failed

None.

### Integration status

The load-bearing section — every claim below is backed by a re-runnable check (`testing.md`'s coverage map grounds its verification approaches here):

- **testing-ext self-tests: `sh extensions/testing/test/run.sh` → 43 passed, 0 failed.** Covers: the **SC/FR coverage validator** (greps `spec.md`, excludes `\d{3}-`-prefixed cross-refs → exactly **27 ids = 10 SC + 17 FR**; the naive grep's 28 is asserted wrong; fails-on-any-gap); the **two-golden completion-report validation** (appendix-bearing + appendix-free both validate — SC-005) with 6 adversarial rejections; a **golden `testing.md`** 27-id bijection with a real GAP row + 7 rejections; the **install/uninstall byte-identical round-trip** (002 FR-014). Golden section assertions are derived at test time from the two contracts' own §-lists (R1-S19), so contract and validator cannot silently diverge.
- **git-ext self-tests: `sh extensions/git/test/run.sh` → 46 passed, 0 failed.** §6 = the **I-17 checkbox-delta survival regression** (forward-flip PASS with the audit line; reverse-flip `[X]`→`[ ]`, unpaired insert/delete, edited-text, and scope-guard all BLOCK — R1-S04/S14/S18/S05); §7 = the **SC-008 seam survival** (`complete(<id>)`/`testing(<id>)` commits + hook routing) — both surviving a git-ext reinstall **and** a foreign-extension reinstall (R1-S08/S15).
- **SC-010 proven live on this run (the headline).** Waves 2–6 each cleared the per-wave `verify-gate workforce` freshness check **via the checkbox-delta branch, unassisted**, against a `tasks.md` drifted from its bound SHA `9601bcd` by pure `[ ]`→`[X]` advances (7→8→11→17→18), each emitting the durable S09 audit line. The refuse-then-release pair is closed end to end: pre-flight REFUSE (Wave 1 blocked until T008) → RELEASE (T008 green) → wave-2+ PASS-unassisted. The block-half of the invariant (a content edit / reverse flip still BLOCKS) is held by the §6 regression above.
- **Install state:** the testing extension is live in `.specify/` — `installed: [graphify, git, workforce, testing]` (append-only; git-ext's `after_complete`/`after_testing` rows intact), payload byte-identical to source, both command skills in `.claude/skills/`; git-ext was reinstalled once carrying the bundled I-17 + seam fix. All shared-registry merges are clean.
- **Observability:** 19 `implementer` trace records (one per dispatched task) + this `orchestrator` record are appended to `traces.jsonl`; `agent_id`/`skills`/`elevated_grants` per the approved roster row, `[]` (never `null`) where a row carries none (FR-021/SC-008). `ANTHROPIC_API_KEY` is unset everywhere (D28, subscription-only).

### Key results

- The **4th pipeline extension** (`speckit-ext-testing`) is built, installed, and green: the doc-only `testing` phase (a separate-session Sonnet `tester`, `executed: none`) and the finalized, contract-validated `complete` phase.
- The **I-17 workforce-freshness defect** — a general defect that would hard-block wave 2+ of every feature's own implement — is **fixed in git-ext's own source, reinstall-survival-tested, and proven live** on M4's own run (SC-010).
- Two normative contracts shipped (`completion-report.md`, `testing-doc.md`), each with a machine-checkable §Validation the testing-ext harness enforces (R1-S03/S19).
- **This report is itself the evidence for SC-001 and (with `testing.md`) SC-009** — the M4 exit. It is authored entirely by the main-thread orchestrator, **no new model role** (FR-001).

<!-- Everything below this line is the OPTIONAL appendix (docs/contracts/completion-report.md §3) — outside the validated core. M4 is a docs/05 milestone-close (dogfood) build, so it carries the appendix; a generic feature would omit both sections. -->

## Milestone-close context

**This file IS the D19 `phase.completed` `artifact.body` (FR-005).** Per `docs/contracts/completion-report.md` §5 and `trace-schema.md` §6, the `complete`-phase `phase.completed` event carries this file — frontmatter and body, core and this appendix, exactly as written to disk — as its `artifact.body`, with **no reshaping**; the frontmatter `status: success` is that event's `status`. The event is idempotent on `artifact.sha256` (this file's own bytes). Building the M5 MCP push is out of scope (M5); M4's job was to make the body well-formed and replayable — done.

M4 was the pipeline's **first fully-unassisted run**, so its product is findings about the live stations. Two moments define it:
- **The pre-flight (D69).** The I-17 fix is machinery that gates the waves, so it was provisioned *before* Wave 1, never as a wave node — `implement-parallel` mechanically refused Wave 1 until the single bundled git-ext change reinstalled and both survival regressions went green. That refuse-then-release is itself SC-010's provisioning evidence.
- **SC-010 becoming true, live.** The first wave-2+ freshness check faced a checkbox-advanced `tasks.md` and passed unassisted via the checkbox-delta branch, leaving an independently-auditable audit line — the zero-hand-assistance claim made real on the dogfood run, not simulated.

**Checkpoint α (docs/05 §4.1 / M4):** the whole notebook pipeline now runs CLI-only, spec → council-defended plan → specialized parallel implementation → **testing** → completion. This `completion-report.md` + the forthcoming `testing.md` are the last two artifacts of that arc. The α declaration itself is the owner's act.

## Decisions & log

### Findings adjudicated (F1–F5)

Per `findings.md`'s own model, each M4 finding adjudicates to a `docs/90` D-row or I-row, folded here:

- **F1** — the D66 flywheel's first live firing is a *seed-breadth* signal, not a threshold artifact (8/19 ∅-match, all zero-overlap). **RESOLVED → D71** (seed two general authoring skills; 6 gaps closed, 2 residual accepted; zero builder dispatches — the seeding clause, not flywheel failure). Observability sub-finding → **I-21**.
- **F2** — the workforce-gate binding requires commit-BEFORE-bind (its decision section lives inside the bound `assignment.md`). **Booked → I-22** (M6 HookExecutor must fire `after_workforce_approve` after the gate-resolution commit); handled correctly by hand this run.
- **F3** — git-ext `install.sh`'s PyYAML-less manual-fallback block is stale for the new seam (missing `after_complete`/`after_testing`). **Booked → I-23** (git-ext follow-up pile, joins I-16/I-17). Latent only — the auto-merge path (exercised by T008/T018) is unaffected.
- **F4** — the SC/FR coverage validator must exclude cross-feature `NNN-FR-`/`NNN-SC-` references (`001-FR-019` in this spec). **RESOLVED this run** — T016's `extract_ids()` excludes `\d{3}-`-prefixed tokens (asserted naive 28 → correct 27); standing generalization noted for future coverage validators.
- **F5** — R1-S06's tester-trace `context_in` field was not sanctioned by `trace-schema.md` (§1 didn't list it; §7 rejected unknown fields). Caught **independently by T013 AND T015**. **RESOLVED → D72** — `trace-schema.md` amended to 1.3, admitting `context_in` as the one role-gated field; committed `0ef22e5` **before** this phase's own testing session, so M4's first live tester trace is schema-conforming from the start.

### Decisions & ideas booked this milestone

D68 (spec-review adjudications), **D69** (pre-flight invariant), D70 (D62 closed / metric correction), D71 (seed-don't-build), **D72** (trace-schema 1.3 / `context_in`); ideas I-20 (flywheel seed-breadth), I-21 (D47 token-attribution tooling), I-22 (commit-before-bind), I-23 (git-ext manual-fallback). All in `docs/90-DECISIONS-AND-IDEAS.md`.
