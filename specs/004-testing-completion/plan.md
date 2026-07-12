# Implementation Plan: The Testing Agent & the Finalized Completion Report

**Branch**: `004-testing-completion` | **Date**: 2026-07-12 | **Spec**: [`spec.md`](./spec.md)

**Input**: Feature specification from `specs/004-testing-completion/spec.md` (APPROVED with adjudications, D68)

## Summary

M4 delivers the pipeline's **tail**, finalizing two things 001/002/003 produced *ad hoc*: a **doc-only testing agent** (the `testing` phase — a Sonnet `tester` in a separate session that maps every spec SC **and** FR to a verification approach and records `executed: none`) and a **finalized completion-report format** (the `complete` phase — a validatable contract whose body M5 binds as the D19 `phase.completed` payload). It is the **first fully-unassisted pipeline run**, so it also carries a **distinct second concern** (D68): the **I-17 workforce-freshness fix** — a mechanical, gate-integrity change to `verify-gate.sh` so wave 2+ of an implement run passes the freshness check with zero hand assistance.

The plan takes **positions** on the three items the spec deferred (D68), each rejectable by the council with reasons:
1. **Testing seam** → the 002 pattern: `after_testing` + `after_complete` hooks in **git-ext's own source** + `testing` added to `commit.sh`'s phase enum.
2. **Completion authorship** → a **thin `/speckit-complete` command** over orchestrator-inline authorship (M5's `after_complete` push and FR-012's `complete`-commit both need a command boundary to hang on).
3. **I-17 fix design** → a **mechanical checkbox-delta classification** in `verify-gate.sh` (admit staleness iff the whole `tasks.md` delta since the recorded SHA is checkbox progression; block on any content change) — a refinement of D68's trust-classification lean that classifies the **diff**, not the committer.

## Technical Context

**Language/Version**: POSIX `sh` (git-ext primitives, mechanical git); Markdown + YAML-frontmatter artifacts; Claude Code skill Markdown (the two commands + the tester prompt). No new runtime language.

**Primary Dependencies**: the live git extension (`commit.sh`, `verify-gate.sh`, `gates.sh`, `sha.sh`, `extension.yml`, `install.sh`, `test/run.sh`); the D19 envelope + `role: tester` already in `trace-schema.md`; the `complete`/`testing` phase-table rows already in `artifact-layout.md` §2. The two new SpecSeyal schemas live in `docs/contracts/`.

**Storage**: files only (principle 1). New artifacts: `completion-report.md`, `testing.md` (per feature); new schemas: `docs/contracts/completion-report.md`, `docs/contracts/testing-doc.md`. Git-ext-owned `gates.yml` is read (never written) by `verify-gate.sh`.

**Testing**: `extensions/testing/test/run.sh` (new — the testing extension's harness: contract-validation of **two** golden `completion-report.md`s, one **appendix-bearing** and one **appendix-free**, each independently validated so SC-005's with/without-appendix claim has a genuine two-branch test (R1-S10), plus a golden `testing.md`, and the install/uninstall round-trip; the harness's golden assertions are **derived from `docs/contracts/*.md`'s own section lists**, not hand-maintained parallel prose, so contract and validator cannot silently diverge (R1-S19)); `extensions/git/test/run.sh` **extended** (the testing-seam survival test + the I-17 checkbox-delta regression, §3 model — S17 class).

**Target Platform**: the SpecSeyal SDD pipeline, CLI-only (Checkpoint α). Interactive Claude subscription sessions (D28); no `ANTHROPIC_API_KEY`.

**Project Type**: pipeline extension (the 4th, after graphify/council/workforce) + owned-source edits to the git extension.

**Performance Goals**: n/a (mechanical git + one Sonnet doc session). **Constraints**: the `tester` is doc-only (`executed: none`, I-3); `verify-gate.sh` stays zero-AI, read-only, fail-closed (FR-007). **Scale/Scope**: one net-new AI role (Sonnet `tester`, SC-007); ~1 new extension + 4 git-ext owned-source edits + 2 new contracts.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Assessment |
|---|---|
| **I. Artifacts are the contract** | PASS. `complete` writes **exactly** `completion-report.md`; `testing` writes **exactly** `testing.md` (spec FR-001/006, §2 rows). The git-ext edits are **code**, not phase artifacts — mechanical git, no artifact-out (FR-007). No phase gains a second writer. **Contract touch flagged:** `artifact-layout.md` §6 ownership table lists no writer for `completion-report.md`/`testing.md` — Phase 1 adds those rows (a D46-rule-3 authorized contract edit, not a new writer of an existing artifact). |
| **II. Context hygiene** | PASS. `testing` runs in a **separate session** (a dispatched Sonnet `tester`), returns **only** `testing.md` status-only — no completion-report/spec body re-imported (SC-003). `complete` runs in `main` (no offload; it reads tasks.md + implement.log.md which the orchestrator already holds). |
| **III. Resumability (NON-NEGOTIABLE)** | PASS. Both artifacts validate against a **new `docs/contracts/` schema** (SC-001/002); no state file. A malformed report leaves `complete` incomplete; a malformed `testing.md` leaves `testing` incomplete (§3). |
| **IV. Observability** | PASS. `testing` appends **one** trace (`role: tester`, Sonnet, SC-007/FR-011). `complete` runs in the orchestrator session (its trace is the main-thread record). The git-ext edits run **no session** and write **no trace** (FR-007 — consistent with git-ext's zero-AI charter, §2 "three rows leave no trace" ethos extended to mechanical primitives). |
| **V. Subscription-only billing (NON-NEGOTIABLE)** | PASS. `tester` = Sonnet on subscription; no `ANTHROPIC_API_KEY` anywhere (SC-007). |
| **Model policy (D18)** | PASS. `tester` = **Sonnet** (mechanical/generative role, `trace-schema.md` §2). `complete` = the **main orchestrator (Opus)** — **no new model role** (FR-001). Net-new roles = **exactly one** (the Sonnet `tester`, SC-007). |
| **Autonomy & gates (D9)** | PASS. `profile.yaml`: `council_tier: standard` (D61, S-sized), **both gates `human`** (D33/D68 — deliberately, to exercise the first machine-written, machine-bound workforce gate). The D67 **grant tripwire is expected clear** (roster is grant-free — see below). |

**Result: Constitution Check PASSES — no violations.** Complexity Tracking is empty.

**Grant-tripwire pre-assessment (D67).** The M4 roster is expected **grant-free**: the doc-only `tester` reads two files and writes one (core toolset — no `web_search`, no network), and the git-ext edits run on the base shell toolset. So the tripwire is **clear** and `gates.workforce.mode: auto` *would* be permissible (P4/D67) — but this run keeps **`human`** (D68) to exercise the first machine-bound workforce gate. Were any assembled agent ever to carry an elevated grant, the tripwire would force `human` regardless of profile.

---

## Concern 1 — The testing extension (the `testing` phase + the finalized `complete` phase)

### 1.1 Packaging — a 4th pipeline extension `extensions/testing/`

Mirror graphify/council/workforce: `install.sh` copies the extension tree → `.specify/extensions/testing/` and the command skills → `.claude/skills/`, and merges its hook rows into `.specify/extensions.yml`; `uninstall.sh` deregisters-first with a byte-identical round-trip (FR-014 pattern from 002). The extension **provides two commands** and **owns two prompt/trace templates**; it does **not** own the phase-commit hooks (those are git-ext's — §1.4).

```
extensions/testing/
├── install.sh · uninstall.sh · README.md
├── extension/
│   ├── extension.yml               # provides: speckit.complete, speckit.testing
│   ├── testing-config.yml          # tester model (sonnet, D18), doc-only guard
│   ├── commands/
│   │   ├── speckit.complete.md      # provenance for /speckit-complete
│   │   └── speckit.testing.md       # provenance for /speckit-testing
│   ├── templates/
│   │   ├── tester-prompt.md         # the Sonnet tester's separate-session prompt
│   │   ├── completion-report.template.md
│   │   ├── testing.template.md
│   │   └── trace-fragment.md        # the tester's one trace record
│   └── skills/{speckit-complete,speckit-testing}/SKILL.md
└── test/run.sh                     # contract-validation + install round-trip
```

### 1.2 The `complete` phase — a thin `/speckit-complete` command (POSITION on D68 lean B)

**Position:** a **thin `/speckit-complete` command** over orchestrator-inline authorship.

- The command runs in **`main`** (artifact-layout §2 unchanged): the **orchestrator (Opus) authors** `completion-report.md` from `tasks.md` + `implement.log.md`. **No new model role** (FR-001) — it is a command *boundary*, not a dispatched session.
- **Re-reads from disk every invocation** (R1-S02): `/speckit-complete` re-reads `tasks.md` + `implement.log.md` **from disk** on each run — never assuming they are "already in main's context." Resumability (Constitution III) beats context retention: the assumption would silently break across a long multi-wave run, a compaction, or a resumed session.
- **Why a command and not inline prose:** M5's `after_complete` D19 push (FR-005) and the `complete(<id>)` phase-tagged commit (FR-012) each need a **hook point**, and a hook fires on a **command boundary**. The git-ext has `after_implement` but **no `after_complete`** today, and the `complete` phase has no command to hang one on. A thin command supplies that boundary now, so M5 is plumbing (FR-005) and the 002-deferred complete-commit closes (FR-012). **Ratified by the council** (R1-S17): every other pipeline phase is already a `/speckit-*` command, so inline authorship would be the sole exception to the one-command-per-phase convention.
- **Alternative rejected:** orchestrator-inline authorship with no command — leaves M5 with no `after_complete` boundary and FR-012's complete-commit with no hook, reproducing exactly the gap 002 deferred.

**The finalized format (FR-002/003/004).** `completion-report.md` = **YAML frontmatter** + normative core + optional appendix:

```markdown
---
feature: 004-testing-completion
phase: complete
status: success            # ∈ {success, partial, failed} — FR-003, machine-readable,
                           # aligns to trace-schema §1 outcome + the D19 event `status`
---
## Implementation Complete — <extension/feature name>   # waves run + roster summary
### Completed (N / N)
### Partial / Degraded
### Failed
### Integration status
### Key results
<!-- optional dogfood appendix, OUTSIDE the validated core (FR-004/SC-005): -->
## Milestone-close context   ### <M-N "Done when">  ### Findings adjudicated  ### Deferred/carried  ### Next steps
## Decisions & log
```

The normative core is the finalize of 003's ad-hoc `completion-report.md` (the graph confirms `Finalized completion-report contract --references--> 003 Completion Report`). The frontmatter `status` makes the overall outcome **derivable without reading prose** (FR-003) and **is** the D19 event `status`; the whole file **is** the D19 `artifact.body` — no reshaping (FR-005), idempotent on `artifact.sha256`.

### 1.3 The `testing` phase — a dispatched Sonnet `tester` (FR-006–011)

`/speckit-testing` (main) **dispatches one Sonnet `tester` subagent** (the separate session, §2) with context-in = `completion-report.md` + `spec.md` **only**; the subagent authors `testing.md` and returns **status-only** (SC-003). One trace record (`role: tester`, Sonnet, `agent_id: null`, `skills: []`, `elevated_grants: []` — not an implementer, grant-free).

**`testing.md` format (FR-007/008/010):**

```markdown
---
feature: 004-testing-completion
phase: testing
executed: none             # FR-009/010 — the doc-only boundary, legible in the doc itself
---
## Coverage map            # every SC AND every FR (Clarifications 2026-07-12) → a verification approach
| item | approach (kind of check + how to perform + confirming evidence) | grounding | status |
| SC-001 | contract-validate completion-report.md against docs/contracts/… | report §Integration | covered |
| FR-014 | run implement wave 2+ under live machinery, observe freshness pass | report §Integration | covered |
| SC-00x | … | — | **GAP** (no evident coverage in the completion report) |
## Verified by reading vs. would-execute in v2   # the honest split (FR-010; 001-FR-019, I-13)
```

Every SC/FR maps to a **verification approach** (the kind of check + how + confirming evidence, incl. manual steps and citations to existing automated tests), grounded in the report's Integration-status; any SC/FR the report does not evidence is a flagged **GAP**, never a fabricated "covered" (edge cases, honesty ethos). The tester **executes nothing** (`executed: none`); tests already run during implement are cited as **existing** evidence, never re-run (FR-009).

**Round-1 refinements (R1-S03/S05/S06):**
- **Coverage is code-enforced, not prompt-enforced** (R1-S03): a mechanical validator greps every `SC-\d+` and `FR-\d+` ID from `spec.md` and asserts each appears in `testing.md`'s coverage map — **contract validation fails on any gap** — so SC-004's "100% mapped" is enforced by code (the 003 categorization-completeness-validator precedent), not by trusting the tester's prompt.
- **Second-hand evidence is grounded and labeled** (R1-S05): the tester's primary context-in stays `completion-report.md` + `spec.md`, but `implement.log.md` is available as a **read-on-doubt cross-check** (the D10 lazy-grounding pattern, mirroring the council's graphify tool) so an over-claiming or mistranscribed report can be caught — and `testing.md` marks **each item's evidence source** (`report-claimed` vs `log-verified`). It stays doc-only (`executed: none`); it gains honesty about *what* it actually verified.
- **The context-hygiene claim is auditable** (R1-S06): the `tester` trace gains a `context_in` field (the D43 assembly-provenance spirit) recording the files it read, so an SC-003 violation is detectable after the fact — strengthening the trace rather than softening the risk claim it backs.

### 1.4 The testing seam (POSITION on D68 lean A) — the 002 pattern, in git-ext source

**Position:** the 002 pattern — an **owned-source enum entry + `after_*` hooks in git-ext**.

- `extensions/git/extension/scripts/commit.sh`: add **`testing`** to the phase enum (`case "$phase"`, L89-92). `complete` is **already** in the enum — no edit needed there.
- `extensions/git/extension/extension.yml`: add **`after_testing`** (phase: `testing`) and **`after_complete`** (phase: `complete`) hooks, `optional: false`, each firing `speckit.git.commit <phase> "<summary>"` — modeled on the existing `after_<phase>` rows. `after_complete` hangs on the new `/speckit-complete` boundary (§1.2); `after_testing` on `/speckit-testing`.
- **Ownership (D57 §9):** the testing extension provides the phase **commands**; the git extension hooks its **commit primitive** onto their boundaries in git-ext's **own source** (the seam attaches at a hook + one owned-source enum line — never an edit to the testing ext's installed copy). Reinstall-survival-tested (`extensions/git/test/run.sh` §3 model, FR-013).
- **Hook failure is phase-halting** (R1-S07): an errored or empty `after_complete`/`after_testing` invocation **halts the phase**, symmetric with `complete`'s own "a malformed/absent report leaves `complete` incomplete" guarantee (the 002 stop-on-nonzero lineage) — so SC-006/SC-009's "both phases leave a commit" can never read as satisfied on a silent no-op.
- **The seam's reinstall-survival test is specified concretely** (R1-S08): the SC-008 regression (`extensions/git/test/run.sh` §3) dispatches a fixture `/speckit-complete` + `/speckit-testing`, asserts a `complete(<id>)` and a `testing(<id>)` commit exist, then **re-asserts after a git-ext reinstall and a foreign-extension reinstall** — at the same fixture-level detail as the I-17/SC-010 regression (§2.3); SC-006 and FR-013 both ride on it.

---

## Concern 2 — The I-17 workforce-freshness fix (a distinct, gate-integrity concern the council reviews as such)

### 2.1 The defect (FR-014)

The workforce gate binds `tasks.md @ <sha>` + `agents/assignment.md @ <sha>` at approval (`on-gate-approve.sh`). `verify-gate.sh workforce` — fired by `before_implement` and **per wave** by `implement-parallel` — treats `tasks.md` as fresh iff its recorded SHA equals the current committed SHA (`sha.sh`) **and** the working tree is clean. But `implement-parallel` marks tasks `[X]` in `tasks.md` and commits per wave, so the **first wave's `[X]`-mark moves `tasks.md`'s last-touching SHA (or dirties the tree)** → stale → **wave 2+ hard-blocked**. It bites every feature; it surfaced now because M4 is the **first feature to run its own implement under the live workforce machinery without the 003 grandfather** (I-16 was 003-only). M4 is **not** a meta-feature w.r.t. this machinery (003 built it) — so M4's own gate binds normally, and the honest fix is **fix-first, not grandfather**.

### 2.2 The fix — mechanical checkbox-delta classification (POSITION on D68 lean C / FR-017)

**Position:** `verify-gate.sh` gains, **for the workforce gate's `tasks.md` only**, a **read-only checkbox-delta classification** branch. On a freshness failure (SHA mismatch **or** dirty tree), it computes the full delta from the **recorded-SHA `tasks.md`** to the **current working-tree `tasks.md`** (`git diff <recorded_sha> -- <tasks.md>` plus the uncommitted diff) and:

- **PASSES** iff **every** changed line is a pure **checkbox-state flip** — the line is identical except its GFM task marker advanced from unchecked to checked (`- [ ]` → `- [x]`/`- [X]`). This is *machinery marking progress*; the **approved content is unchanged**.
- **BLOCKS** (stale) on **any** other change — a task added/removed, a description/dependency/ID edited, any non-checkbox text — a human/content edit to an approved artifact, **exactly what S05/FR-009 exist to catch**.

**Why classify the diff, not the committer** (refinement of D68's lean, on record): "refresh on machinery-**authored** wave commits" trusts *who* committed — but `commit.sh` is used by every phase, so a human could smuggle a content edit into a wave commit and have authorship bless it. Classifying the **diff** as checkbox-only is **strictly stronger**: it admits *only* progress-marking and blocks *all* content change, regardless of committer. That is precisely the S05/FR-009 invariant, made mechanical.

**Invariants preserved (the gate-integrity claims the council should test):**
- **Read-only** — `verify-gate.sh` still changes **no git state** and **never writes `gates.yml`** (no re-bind; the recorded SHA stays at approval-time, and the cumulative checkbox delta keeps classifying clean as more boxes flip). This preserves the script's core "no git state is ever changed" property, cleaner than a re-bind path.
- **Zero-AI, mechanical** — a `git diff` + a per-line regex; no model call (FR-007).
- **Fail-closed** — if the diff can't be computed/parsed, or the recorded SHA is unreachable, **BLOCK** (unchanged R1-S10 ethos). Ambiguity never resolves to pass.
- **Scoped** — the classification applies **only** to `workforce`/`tasks.md`. `agents/assignment.md` is untouched by implement (its strict check is unchanged); the **council** gate / `plan.md` keeps the strict check (never checkbox-progressed).
- **Direction-asymmetric** (R1-S14/S15/S18): admissible is **only** an *unchecked→checked* advance (`- [ ]` → `- [x]`/`- [X]`). A **reverse** flip (`[x]`→`[ ]`, e.g. a human un-marking a done task) is **not** admissible — it BLOCKs like any content edit; recovery is a **full re-gate** (the I-16 escape stays ruled out, R1-S14). This direction invariant is **load-bearing**: it is exactly why the mechanism is a direction-aware `git diff`, **not** a canonicalized-checkbox hash — normalizing both marks to one placeholder would make the check direction-blind and silently PASS a reverse flip (R1-S18, peer-proven). **Any future simplification MUST preserve the direction asymmetry.** State the rule direction-explicitly wherever the compressed text is trusted alone (R1-S15).
- **Auditable** (R1-S09): when the **checkbox-delta branch** (not the pre-existing exact-match fast path) produces the PASS, `verify-gate.sh` emits a durable audit line, so SC-010's "zero hand assistance" leaves independently-checkable evidence after the dogfood run — a successful wave 2+ alone cannot distinguish the fix firing from a human working around the gate.

### 2.3 Owned-source + survival-tested + **pre-wave, mechanically enforced** (FR-015/016, SC-010; round-1 R1-S01/S04/S11/S12/S13/S20/S21)

**The one blocking finding (R1-S01 — five-lens + graph-receipted): "wave 1 (or pre-wave)" was unenforced prose a misordered wave-DAG could violate, reproducing the exact wave-2 hard-block the fix removes.** Resolved by the D-row invariant **_machinery that gates the waves is never itself a wave_** (docs/90): the fix runs **PRE-WAVE, outside the `tasks.md` wave loop entirely**, and the ordering is **mechanical, not prose**.

- **One pre-wave git-ext change carries BOTH concerns' edits** (R1-S13/S20 — reconciling the earlier staged-vs-bundled ambiguity to **bundled**): Concern 2's `verify-gate.sh` checkbox-delta fix **and** Concern 1's seam edits (`commit.sh`'s `testing` enum entry + the `after_testing`/`after_complete` hooks) land in a **single** git-ext source change → **one** `install.sh` reinstall → **one** survival-regression pass. They share git-ext's one installer; bundling costs nothing and prevents a double reinstall.
- **`implement-parallel`'s pre-flight enforces it** (R1-S01/S12): before entering wave 1, the pre-flight **refuses to proceed** until that git-ext change + reinstall + survival-regression report are done — the machinery is provisioned *ahead of* the wave loop, never scheduled *inside* it, so it cannot be misordered (R1-S21 is **moot by construction** — no wave-DAG scheduling miss is possible, so no recovery path is needed).
- **The pre-wave window is safe and non-circular** (R1-S11): `verify-gate.sh`'s **first** firing — the `before_implement` check ahead of wave 1 — inspects a **pristine, just-bound `tasks.md`** and passes under the pre-fix script regardless (no box is marked yet). The staleness defect is triggered **only by wave 1's own commit**; so all of wave 1 was never the hazard — wave 1's own `[X]`-mark is — and provisioning the fix before that first commit closes it. SC-010 proves it on M4's own waves 2+.
- **Owned-source + survival-tested** (D57/S2, FR-013/015, S17 class): the change lives in `extensions/git/extension/`; `extensions/git/test/run.sh` gains a case binding a fixture `tasks.md`, flipping a checkbox (→ **pass**), editing a task line (→ **block**), **and the unpaired insertion/deletion (task added/removed) shape §2.2 names as a BLOCK case** (R1-S04) — each re-checked **after a git-ext reinstall and a foreign-extension reinstall** (SC-008).

**I-16 does not ride along.** The spec left an I-16 bootstrap-escape optional ("a plan call"). **Position: not needed for M4** — I-16 is the *meta-feature* circularity (a feature building the binding machinery can't bind its own gate). M4 does not build that machinery (003 did, live), so M4's `after_workforce_approve` binds `tasks.md`/`assignment.md` normally. No bootstrap escape is in scope; adding one would be unused code.

---

## Project Structure

### Documentation (this feature)
```
specs/004-testing-completion/
├── plan.md              # this file
├── research.md          # Phase 0 — the positions + alternatives (both concerns)
├── data-model.md        # Phase 1 — completion-report, testing-doc, checkbox-delta, tester assembly
├── contracts/commands.md# Phase 1 — /speckit-complete, /speckit-testing, verify-gate classification, hooks
├── quickstart.md        # Phase 1 — SC-001..010 validation scenarios
├── graphify-context.md  # before_plan grounding (fresh taxonomy-v1 graph)
├── graph-baseline.json  # committed council baseline (D59 pattern)
└── profile.yaml         # council_tier: standard; both gates human (D33/D61/D68)
```

### Source Code (repository root)
```
extensions/testing/                         # NEW — the 4th pipeline extension
├── install.sh · uninstall.sh · README.md · test/run.sh
└── extension/{extension.yml, testing-config.yml, commands/, templates/, skills/}

extensions/git/extension/                    # OWNED-SOURCE EDITS (D57/S2, reinstall-survival)
├── scripts/commit.sh                        #   + `testing` in the phase enum (seam)
├── scripts/verify-gate.sh                   #   + checkbox-delta classification (I-17)
├── extension.yml                            #   + after_testing, after_complete hooks
└── (install.sh redeploys; test/run.sh += 2 regressions)

docs/contracts/                              # NEW SpecSeyal schemas (the finalization deliverable)
├── completion-report.md                     #   normative core + optional appendix + frontmatter status
├── testing-doc.md                           #   coverage-map + executed:none + gap rules
└── artifact-layout.md                       #   §6 ownership: + completion-report/testing.md writers (edit)
```

**Structure Decision:** the testing extension is a new sibling under `extensions/`; the I-17 fix + testing seam are **owned-source edits within the existing git extension** (never installed-copy edits, D57/S2). The two finalized formats are **SpecSeyal schemas** in `docs/contracts/` (pipeline-wide, not feature-local).

**Collision watch (R1-S22):** the shared/mutable files this feature edits must be **serialized** — no two tasks touching the same one in the same parallel wave: `docs/contracts/artifact-layout.md` (the §6 ownership rows — **explicitly in the set**, since the plan commits an edit to it), git-ext's `commit.sh` + `verify-gate.sh` + `extension.yml` + `test/run.sh` (all in the single pre-wave change, §2.3), and `.specify/extensions.yml` (the installed hook registry both installs touch). `artifact-layout.md` joins the git-ext pair the `graphify-context.md` collision-watch already flags.

**Contract-file count (D46 rule 3) — POSITION:** **two separate schema files** (`completion-report.md`, `testing-doc.md`), matching the one-schema-per-file convention of the seven existing `docs/contracts/` siblings and giving each artifact its own named contract for the §3 resumability mapping. The cross-reference (testing reads the completion report) is handled by a pointer, not co-location. **Ratified by the council** (R1-S16): a combined file would be the first exception to the 1:1 schema-per-file convention across the seven siblings, and the pointer-based cross-reference (D46 rule 3) already gives cheap coupling without co-location.

## Complexity Tracking

*No Constitution violations — this section is intentionally empty.*
