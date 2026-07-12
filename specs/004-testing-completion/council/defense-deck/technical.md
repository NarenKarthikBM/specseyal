# Defense Deck — Technical

**Feature**: `004-testing-completion`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

> **D62 (`003-workforce` round-1, 2026-07-10).** The first `standard`-tier ceremony measured a per-member `plan.md` read-rate of **4/5** (spec 1/5, graph 3/5): most of that round's 25 suggestions — including **both blocking defects** (S01, S02) — trace to three `plan.md` sections this template rendered too thinly, or not at all, to be trusted on their own: `## Architecture & data flow` (6 of 25 suggestions), `## Plan-time verifications & per-SC test coverage` (7 of 25 — the round's single highest-demand section), `## Project Structure` (3 of 25). §3 (new below) and the strengthened §4/§7 exist to close that gap by default, so a lazy-context member can reach an opinion from this deck alone. **After-metric:** the per-member `plan.md` read-rate at the *next* council run — target: a majority of the bench (≤2/5) no longer needs to open `plan.md`.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

**Concern 1 — the testing extension.** 001, 002, and 003 each ended with an ad-hoc completion write-up and no systematic answer to "what was actually verified?" M4 is the last extension before Checkpoint α (the whole pipeline running CLI-only), and it finalizes the pipeline's tail: after `/speckit-implement-parallel` finishes, the `complete` phase must read `tasks.md` + `implement.log.md` and write `completion-report.md` in a **finalized, contract-validated format** — machine-readable status plus a fixed core section set — because M5 needs to bind this report as a D19 phase-event payload with zero rework (US1, P1). That report then feeds a new `testing` phase: a doc-only agent that reads the report + `spec.md` and maps **every** Success Criterion and Functional Requirement to a verification approach, flagging anything the report doesn't evidence as a gap rather than fabricating coverage — it asserts what should be tested and how, but executes nothing (US2, P1; a testing-agent that runs tests is v2, out of scope).

**Concern 2 — the I-17 workforce-freshness fix (distinct, gate-integrity).** M4 is also the pipeline's **first fully-unassisted run** under 003's live workforce-gate machinery, with no grandfather exemption. That exposed a general defect: the workforce gate binds `tasks.md` at approval, but `implement-parallel`'s own normal operation — marking tasks `[X]` and committing per wave — moves `tasks.md`'s SHA and dirties the tree, so the existing freshness check hard-blocks **every** feature's wave 2+ by design, not by accident. This is not a testing-extension feature; it is a security/gate-integrity defect ruled in-scope by D68 as a **distinct second concern** whose design MUST be council-reviewed on gate-integrity terms (FR-017), bundled into M4 only because M4 is the first feature that would otherwise be blocked by it live.

---

## 2. Chosen Approach & Rejected Alternatives

### Concern 1 — the testing extension

**Chosen approach.** A 4th pipeline extension, `extensions/testing/`, packaged like graphify/council/workforce, providing two thin commands and owning two prompt/trace templates — but **not** the phase-commit hooks (those live in git-ext, per the seam decision below). `/speckit-complete` runs in **main**: the Opus orchestrator reads `tasks.md` + `implement.log.md` (already in its context — no dispatch) and writes `completion-report.md`, adding **no new model role** (FR-001). `/speckit-testing` runs in main but **dispatches one Sonnet `tester` subagent** — a genuinely separate session whose context-in is `completion-report.md` + `spec.md` only; it writes `testing.md` and returns status-only (SC-003). Both new artifacts validate against new normative `docs/contracts/` schemas — the format-finalization deliverable.

Two sub-positions the plan defends on their own terms (D68's deferred leans):

- **Completion authorship → a thin `/speckit-complete` command**, not orchestrator-inline prose with no command. **Alternative rejected:** orchestrator-inline authorship with no command — leaves M5's `after_complete` D19 push (FR-005) and FR-012's `complete`-tagged commit with **no hook boundary to hang on**, reproducing exactly the gap `002` deferred to M4.
- **The testing seam → the 002 pattern**, entirely in git-ext's **own source**: add `testing` to `commit.sh`'s phase enum (`complete` is already there) and register two new hooks, `after_testing` and `after_complete`, in git-ext's `extension.yml`, each firing `speckit.git.commit <phase> "<summary>"`. Ownership stays clean — the testing extension owns the commands; git-ext hooks its own commit primitive onto their boundaries in its own source, never patching the testing extension's installed copy (D57 §9).

### Concern 2 — the I-17 workforce-freshness fix

**Chosen approach.** `verify-gate.sh` gains a **read-only, mechanical checkbox-delta classification branch**, scoped to the workforce gate's `tasks.md` only. On a freshness failure (SHA mismatch or dirty tree), it computes the full delta from the recorded-SHA `tasks.md` to the current working-tree `tasks.md` and **passes iff every changed line is a pure GFM checkbox flip** (`- [ ]` → `- [x]`/`- [X]`, otherwise byte-identical); it **blocks** on any other change, or on an unparseable/unreachable diff (fail-closed).

- **Alternative rejected — trust the committer** (D68's own original non-binding lean: "refresh on machinery-authored wave commits"). Rejected on the record: `commit.sh` is used by every phase, so an authorship-based check is spoofable — a human could smuggle a content edit into a wave commit and have authorship bless it. Classifying the **diff**, not the committer, is strictly stronger: it admits only progress-marking and blocks all content change regardless of who committed it — precisely the S05/FR-009 invariant, made mechanical.
- **Alternative rejected — grandfather I-17 again**, as 003 was grandfathered (I-16). Rejected: M4 is **not** a meta-feature with respect to this machinery (003 built it, live) — grandfathering again would undercut M4's own SC-010 exit test and leave the general defect (which "bites every feature") unfixed.
- **Related scope call — no I-16 bootstrap-escape.** The spec left an I-16 bootstrap-escape optional ("a plan call"). The plan's position: not needed for M4, since M4 doesn't build the binding machinery itself; adding an escape now would be speculative, unused code.

### Open branch point for the council — contract-file count

The plan takes a **position**, not a closed decision: **two** separate `docs/contracts/` schema files (`completion-report.md`, `testing-doc.md`), matching the one-schema-per-file convention of the seven existing `docs/contracts/` siblings, with the cross-reference (testing reads the completion report) handled by a pointer, not co-location (D46 rule 3 — a plan-level format choice). The plan states explicitly: **"Council may prefer one combined file."**

---

## 3. Architecture & Data Flow *(D62 — new section; round-1 evidence: S01/S02/S04/S13/S14/S15, both blocking defects)*

Two independent flows. Every write below is annotated with **who performs it** — a live model session vs. a deterministic script — because that distinction is what the Constitution Check's Principle II/IV rows and the FR-007 "zero-AI" claims rest on.

**Concern 1 pipeline — `complete` → `testing`, then the seam:**

```
tasks.md (all [X]) + implement.log.md ──▶ [/speckit-complete, MAIN, Opus orchestrator]
    reads:  tasks.md, implement.log.md (already in main's context — no dispatch)
    writes: completion-report.md  (frontmatter status ∈ {success,partial,failed} + fixed core
            sections + optional dogfood appendix)
    guarantee: resumability — malformed/absent report leaves `complete` INCOMPLETE, pipeline
               halts (US1 scenario 1/2); the file body IS the future D19 artifact.body verbatim,
               idempotent on sha256 — no reshaping when M5 builds the push
        │
        ▼  [after_complete hook, git-ext OWN SOURCE — mechanical, zero-AI, no trace]
        commit.sh complete "<summary>"  ──▶  complete(<id>) phase-tagged commit

completion-report.md + spec.md ──▶ [/speckit-testing, MAIN dispatches ONE Sonnet `tester` SUBAGENT]
    context-in (subagent ONLY): completion-report.md + spec.md — nothing else (session-boundary
               rule / context hygiene)
    writes: testing.md  (frontmatter executed:none + ## Coverage map: every spec SC AND FR →
            a verification approach, grounded in the report's Integration-status; unevidenced
            items flagged GAP, never fabricated "covered" + ## Verified-by-reading vs. v2-would-
            execute)
    returns: STATUS-ONLY to main (SC-003) — no report/spec body re-imported
    trace: exactly one record — role:tester, Sonnet, agent_id:null, skills:[], elevated_grants:[]
    guarantee: doc-only — executes no test; implement-time tests already run are cited as
               EXISTING evidence, never re-run (FR-009)
        │
        ▼  [after_testing hook, git-ext OWN SOURCE, NEW hook + NEW enum entry — mechanical, zero-AI]
        commit.sh testing "<summary>"  ──▶  testing(<id>) phase-tagged commit
```

**Concern 2 — the I-17 fix, a modification to an existing, already-live mechanism (not a new phase):**

```
[EXISTING, unchanged] after_workforce_approve (git-ext) binds tasks.md@<sha> +
    assignment.md@<sha> into git-ext-owned gates.yml, at gate-approval time only.

[EXISTING, unchanged] verify-gate.sh workforce fires at before_implement (once) AND
    per-wave by implement-parallel (repeatedly): fresh iff recorded-SHA == current SHA
    AND working tree clean; else hard-block, fail-closed.

    THE DEFECT: implement-parallel's own normal operation ([X]-marks tasks.md, commits
    per wave) moves tasks.md's SHA / dirties the tree — wave 1's own progress-marking
    stales the binding it just satisfied, hard-blocking wave 2+ by design.

[NEW] on a tasks.md freshness failure ONLY, verify-gate.sh (extensions/git/extension/
    scripts/verify-gate.sh, owned-source) gains a read-only classification branch:
    reads:   git diff <recorded_sha> -- tasks.md  (committed delta) + the uncommitted
             working-tree diff
    decides: PASS (exit 0) iff EVERY changed line is a pure checkbox flip
             ([ ]→[x]/[X], otherwise byte-identical); BLOCK (non-zero) on ANY other
             change, or an unparseable/unreachable diff (fail-closed — ambiguity never
             resolves to pass)
    performed by: mechanical — a git diff + a per-line regex inside the existing
             mark_stale() accumulator; zero model call (FR-007)
    writes:  NOTHING — read-only; gates.yml is never re-written, no re-bind, no git-state
             change (preserves verify-gate.sh's core "changes no git state" property)
    scope:   tasks.md / workforce gate ONLY — assignment.md and the council gate/plan.md
             keep the unmodified strict check
        │
        ▼  SEQUENCING GUARANTEE (FR-016/SC-010): this fix — source edit + git-ext
           reinstall + the survival regression — MUST land in wave 1 (or pre-wave) of
           M4's OWN implement, so M4's own waves 2+ run under the CORRECTED installed
           machinery — proving the fix on the dogfood run itself.
```

---

## 4. Project Structure & Dependency / Graph Impact *(Project Structure fold-in — D62; round-1 evidence: S06/S10/S25)*

**Project Structure** (from `plan.md`)

```
specs/004-testing-completion/           # this feature's own artifacts (unchanged shape)

extensions/testing/                     # NEW — the 4th pipeline extension
├── install.sh · uninstall.sh · README.md · test/run.sh
└── extension/{extension.yml, testing-config.yml, commands/, templates/, skills/}

extensions/git/extension/               # OWNED-SOURCE EDITS (D57/S2, reinstall-survival)
├── scripts/commit.sh                   #   + `testing` in the phase enum          (Concern 1)
├── scripts/verify-gate.sh              #   + checkbox-delta classification         (Concern 2)
├── extension.yml                       #   + after_testing, after_complete hooks   (Concern 1)
└── (install.sh redeploys; test/run.sh += 2 regressions, one per concern)

docs/contracts/                         # NEW SpecSeyal schemas (pipeline-wide, not feature-local)
├── completion-report.md                #   normative core + optional appendix + frontmatter status
├── testing-doc.md                      #   coverage-map + executed:none + gap rules
└── artifact-layout.md                  #   §6 ownership: + completion-report/testing.md writers (edit)
```

**Structure Decision** (`plan.md`): the testing extension is a new sibling under `extensions/`; the I-17 fix and the testing seam are **owned-source edits within the existing, already-shipped git extension** — never installed-copy edits (D57/S2). The two finalized formats are **SpecSeyal schemas** in `docs/contracts/` — pipeline-wide, not feature-local, because M5 and every future feature's `complete`/`testing` phase will validate against them.

**Dependency / Graph Impact** (from `graphify-context.md`, independently verified)

Grounded in the fresh taxonomy-v1 baseline committed for this council round: `specs/004-testing-completion/graph-baseline.json` — **1,343 nodes / 2,177 edges**, repo scope (D59 pattern; matches the live `graphify-out/graph.json` at prep time).

**Honest grounding caveat (I-13) — read this before trusting any degree number below.** Both concerns edit **shell scripts** and a YAML manifest. graphify's AST layer captures each `.sh` file's internal `defines` but almost no cross-file edges (shell has no import graph), so `graphify explain` returns **low-degree leaf nodes** — `verify-gate.sh` degree **4**, `commit.sh` degree **3** — and a direct `path "verify-gate.sh" → "implement-parallel"` query finds **NO edge**, even though `implement-parallel` calls `verify-gate.sh` every wave. That call relationship is real; the graph is simply blind to it (shell has no import edges to trace). **These low degrees understate real blast radius — they are not evidence these files are low-impact.** Per `graphify-context.md`'s own instruction, code-layer grounding for the two `.sh`/`.yml` edit targets leans on direct source reads, not graph edges. Where the graph *does* ground well is the richer concept/rationale layer (436 concept + 213 rationale nodes) — confirming, for example, the direct link `Finalized completion-report contract --references--> 003 Completion Report`.

**Blast radius per anchor** (`graphify-context.md`):
- `verify-gate.sh` — defines `die()`, `usage()`, `mark_stale()` (the stale-report accumulator — the natural hook point the new classification branch attaches to); composes `gates.sh read <gate>` + `sha.sh <artifact>`, never reimplements either; consumed (graph-invisible) by `before_implement` + per-wave `implement-parallel`.
- `commit.sh` — the phase enum `case "$phase"` (L89-92) is the single edit point for `testing`; follow the pattern in the existing `after_*` hooks in `extension.yml`.
- `on-gate-approve.sh` / `gates.sh` — the binding-writer path a "refresh on wave commit" design would have touched (rejected, §2 above); `gates.yml` stays git-ext's sole-owned record, untouched by this fix (read-only).

**Shared / mutable files — collision watch** (`graphify-context.md`; serialize, never parallelize, across these):
- **`commit.sh` AND `verify-gate.sh`** — **two owned-source edits to the same extension** (the testing seam + the I-17 fix), redeployed together by git-ext's **one** `install.sh`. This is the deck's single most load-bearing cross-concern coupling: Concern 1's edit (`commit.sh`) and Concern 2's edit (`verify-gate.sh`) share a redeploy path even though they are separately-reviewable design decisions. The I-17 fix must land wave-1/pre-wave (FR-016/SC-010); the testing-seam hooks fire later, at the `complete`/`testing` boundaries, after implement finishes — a natural but not accidental ordering.
- **`extension.yml`** — two new hook entries (`after_testing`, `after_complete`) land in one manifest.
- **`extensions/git/test/run.sh`** — both the testing-seam survival test and the I-17 survival-regression append here.
- **`.specify/extensions.yml`** — the installed hook registry every extension's `install.sh` merges into (the classic 002/003 shared/mutable file); the new testing-extension install **and** the git-ext reinstall both touch it in the same build.

---

## 5. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| **R1** (Concern 1) | `testing.md`'s "100% of SC+FR mapped" claim (SC-004) is authored by a Sonnet subagent reading the completion report; `plan.md` states no code-level cross-check that every current `spec.md` SC/FR ID actually lands in the coverage map — only that unevidenced items must be flagged GAP rather than fabricated. | Med — a spec this size (17 FRs + 10 SCs) is exactly where an LLM could plausibly under- or mis-map an item. | Med — a silently-dropped SC/FR is precisely what SC-004 exists to prevent, and the enforcement here is prose/prompt-level, not mechanical. | The doc-only boundary already forces explicit gap-flagging over fabrication (FR-008/010); contract validation checks the coverage map's structural presence. **Flagged for the council's testability lens** — no script asserts 100% completeness against the live spec. |
| **R2** (Concern 1) | The `tester` subagent's context-hygiene contract — context-in limited to `completion-report.md` + `spec.md`, return status-only (SC-003) — is enforced by the dispatch prompt, not a code-level context filter. | Low–Med. | Med — a violation reintroduces exactly the class of context-hygiene break the separate-session architecture exists to prevent. | The one-trace-record structure makes a violation auditable after the fact; the same enforcement class was explicitly flagged "for the council to pressure-test" in 003's round-1 (its R1), and recurs here in a new role. |
| **R3** (Concern 2) | The checkbox-delta regression `plan.md` describes exercises exactly two named fixture mutations — flip a checkbox (→ pass) and edit a task line (→ block). Edge shapes beyond these two (e.g., a diff mixing a pure-checkbox line with a content-edited line in the same commit, or a rewritten/squashed history that makes the recorded SHA unreachable) are not individually named as tested fixtures in `plan.md`. | Low — git history rewriting mid-implement is unusual, and the "every changed line must be a pure flip" quantifier (not "any changed line") already handles the mixed-line case correctly by construction. | Med if it occurred — the fail-closed default means any such edge case would **block**, not silently pass, so the failure mode is "reproduce the original I-17 symptom," not a security hole. | Fail-closed by design (unclassifiable/unreachable ⇒ block, "ambiguity never resolves to pass"); the fix is sequenced wave-1/pre-wave so it is exercised live before M4 depends on it (FR-016/SC-010). Worth the council's correctness lens naming any additional fixture shapes it wants proven. |
| **R4** (cross-concern) | `commit.sh` and `verify-gate.sh` are both owned-source edits to the **same** already-shipped extension, landing in the **same** feature build and redeployed by **one** `install.sh` (`graphify-context.md` collision watch). | Med — two concerns editing the same file surface in one build is a natural staging hazard even when each edit is individually simple. | Med — a collision or wrong-order landing could leave wave 2+ still blocked, defeating SC-010's own exit test. | Explicitly flagged as a collision-watch pair in `graphify-context.md`; the I-17 fix's wave-1/pre-wave sequencing (FR-016/SC-010) gives it priority over the testing-seam hooks, which fire only later at the `complete`/`testing` boundaries. |
| **R5** (Concern 1, informational) | The two-vs-one `docs/contracts/` file count is an explicit plan-level **position**, not a closed decision — the plan itself invites the council to prefer one combined file (D46 rule 3). | Low. | Low — either shape satisfies the resumability rule; this is a convention choice, not a correctness risk. | Presented in §2 above as an open branch point rather than settled; the council's call is dispositive either way. |

---

## 6. Cost / Complexity Estimate

**This council round** (`council_tier: standard`, D61 default, `profile.yaml` confirmed): 1 deck-prep Sonnet session (this one) + 5 stage-1 Sonnet member opinions + 1 consolidated Sonnet peer-critique session + 1 Opus-xhigh chairman synthesis = **8 sessions** — the same D56 `standard`-tier shape 003 measured at 2,830,593 billable tokens (−46.1% vs. the `full`-tier baseline, per the decision log). **This round is also the D62 deck-enrichment after-metric measurement itself** — the target set at D62 is a majority of the bench (≤2/5 members) no longer needing to open `plan.md`, now that §3/§4/§7 exist by default.

**Build-side** (`plan.md` Scale/Scope, stated directly — `tasks.md` doesn't exist until after this round clears triage): **one net-new AI role** (the Sonnet `tester`, SC-007); **~1 new extension** (`extensions/testing/`) **+ 4 git-ext owned-source edits** (`commit.sh` enum, `extension.yml` × 2 hooks, `verify-gate.sh`'s new branch) **+ 2 new pipeline-wide contracts**. All build-side implementation sessions run Sonnet per D18.

**Runtime cost, once built** — the two concerns have different cost shapes. The testing extension is **not** zero-cost at runtime, going forward: every future feature that reaches `complete`/`testing` spends exactly **one Sonnet `tester` session** (always — no conditionality, unlike 003's gap-only skill-builder); `complete` itself adds no new session (main-thread orchestrator, no dispatch). The I-17 fix is purely a **one-time build-side** cost — `verify-gate.sh`'s new branch is mechanical (a `git diff` + regex) and runs at zero marginal AI cost on every future gate check, forever, once shipped.

**Grant posture** (D67 tripwire): `plan.md`'s own pre-assessment finds the M4 roster **grant-free** — the doc-only `tester` reads two files and writes one on the core toolset (no `web_search`, no network); the git-ext edits run on the base shell toolset. The tripwire is clear, so `gates.workforce.mode: auto` would be *permissible*, but the profile deliberately keeps **both gates `human`** (D68) specifically to exercise the first machine-written, machine-bound workforce gate.

**What drives complexity up**, per `plan.md`: (1) **two separately-reviewable concerns bundled into one plan/build** — a deliberate D68 ruling, not an accident, but it doubles the review surface this deck exists to keep manageable; (2) **four owned-source edits to one already-shipped, live extension** in a single feature, each requiring reinstall-survival coverage; (3) the I-17 fix carries a **self-referential sequencing constraint** — it must be built, installed, and proven correct in wave 1 (or pre-wave) of the very implement run that ships it, so that M4's own waves 2+ can complete unassisted; (4) **two new pipeline-wide contracts** in `docs/contracts/`, which every future feature's `complete`/`testing` phase must now satisfy, not just this one.

---

## 7. Testability Claim & Plan-Time Verifications *(strengthened — D62; round-1 evidence: S03/S05/S09/S12/S22/S23/S24, the round's single highest-demand section)*

**Tally:** of the spec's 10 Success Criteria, **4 have a plan-cited committed/automated test** — golden-fixture contract validation or a fixture-backed regression (**SC-001, SC-002, SC-008, SC-010**); the remaining **6 (SC-003, SC-004, SC-005, SC-006, SC-007, SC-009) are manual or dogfood-run verification only** — `plan.md` does not claim automated/code-level coverage for these six, though two of them (SC-004, SC-005) have partial structural backing from the contract validator.

**Guard/branch falsifiability.** The plan's one genuine guard/conditional is the I-17 checkbox-delta classification (`PASS` iff every changed line is a pure checkbox flip; `BLOCK` otherwise). Its regression test, as `plan.md` §2.3 describes it, explicitly exercises **both branches** with named fixture mutations — flip a checkbox (→ **pass**) and edit a task line (→ **block**) — then re-checks both outcomes survive a git-ext reinstall and a foreign-extension reinstall. This is exactly the two-sided coverage that round-1 (003) found missing for a different guard (a Sonnet-floor assertion with no fixture able to trip its failure branch), independently, from two members and two lenses — worth crediting explicitly rather than re-discovering. **One open branch worth the council's confirmation:** FR-004/SC-005's "the contract passes with or without the appendix" claim is *also* effectively a two-branch conditional (with-appendix / without-appendix), but `plan.md`'s Testing field states only "contract-validation of **a** golden `completion-report.md`" (singular) — it does not explicitly confirm the golden-fixture set includes **both** an appendix-bearing and an appendix-free sample. Worth a direct ask to the plan owner rather than an assumption either way.

**FR/SC → verification method (full mapping):**

| SC | Claim | Enforcement mechanism | Committed test? |
|---|---|---|---|
| SC-001 | `completion-report.md` validates: valid `status` + 100% of required core sections. | `extensions/testing/test/run.sh` — golden-fixture contract validation against `docs/contracts/completion-report.md`. | **Yes** |
| SC-002 | `testing.md` validates against its contract. | `extensions/testing/test/run.sh` — golden-fixture contract validation against `docs/contracts/testing-doc.md`. | **Yes** |
| SC-003 | `testing` runs as a separate session, returns status-only (no report/spec body re-imported). | The dispatch-prompt session boundary (FR-006/FR-011) + the one-trace-record structure. | No — behavioral/session-boundary property, prompt-enforced. |
| SC-004 | 100% of spec SCs + FRs mapped to a verification approach; unevidenced items flagged GAP; `executed: none` recorded. | Contract validation checks structural presence (frontmatter, coverage-map section) — FR-008/009/010; completeness against the live spec's actual ID set is not code-cross-checked per `plan.md`. | Partial — structure yes, completeness no (see R1 above). |
| SC-005 | Core validates with or without the optional dogfood appendix. | The same contract validator as SC-001 (FR-004 states the rule); `plan.md` doesn't explicitly confirm both fixture variants are in the golden set (see the open branch above). | Partial / unconfirmed. |
| SC-006 | Both `complete` and `testing` leave a phase-tagged commit. | The `after_complete`/`after_testing` hooks firing `commit.sh` (FR-012) — proven live via `git log` at the dogfood run; not a standalone regression beyond the SC-008 seam test. | No — verified at runtime. |
| SC-007 | Exactly one net-new AI role; no `ANTHROPIC_API_KEY` anywhere. | Constitution Check + the grant-tripwire pre-assessment (design-level); roster/env inspection at run time. | No — design-asserted + manual inspection. |
| SC-008 | The `testing`-phase git seam survives a git-ext reinstall and a foreign-extension reinstall. | `extensions/git/test/run.sh` §3-model reinstall-survival regression (FR-013). | **Yes** |
| SC-009 (M4 exit) | Both a validated `completion-report.md` and a validated `testing.md`, each phase-tagged-committed. | The composition of SC-001 + SC-002 + SC-006, proven on M4's own dogfood run. | No — integration-level, proven live. |
| SC-010 (I-17) | Wave 2+ passes the freshness check under live machinery, zero hand assistance. | `extensions/git/test/run.sh` checkbox-delta regression (bind → flip → pass; edit → block; re-check after reinstalls — FR-015/016) **plus** the live proof required on M4's own implement wave 2+. | **Yes** (regression) + a required live dogfood proof. |
