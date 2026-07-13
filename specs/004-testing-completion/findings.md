# M4 Findings — 004-testing-completion

> M4 is **the first fully-unassisted pipeline run** — its product is findings about the live stations (every upstream station is now real machinery, not a grandfathered hand-pass). This file accumulates them; at `complete` they fold into `completion-report.md`'s `### Findings adjudicated` appendix. Each finding is `OPEN` until the owner adjudicates it (→ a `docs/90` D-row).

---

## F1 — The D66 flywheel's first live firing: the gap driver is SEED BREADTH, not a mis-tuned threshold

**Station:** `agent-assign` (assemble). **Status:** ✅ **RESOLVED → D71** (owner ruling (b)+(c)-residual). **Booked levers:** D66 (seed breadth · gap-batching granularity).

> **Resolution (D71).** Two general authoring skills hand-seeded into the live library **and** the workforce seed set (own-source) — `skl_docs_contract_authoring` + `skl_dispatched_prompt_authoring`, `origin: seed`, `grants: []`, two-feature-evidence-pointed, **not provisional**. Re-run assemble: **6 gaps closed** (cluster 1 + cluster 3), **2 residual accepted** (`T010`, `T019` — single-feature demand, capable bases author unaided). `LIBRARY_SNAPSHOT_HASH e9670c55→1b18ccab`; SC-005 determinism holds; **zero builder dispatches** (D66's seeding clause, not flywheel failure). Observability sub-finding booked **I-21** (D47 transcript attribution, third occurrence).

### What happened

`assemble.py` matched 19 tasks → **10 roster rows**, and D66's flywheel **fired for the first time ever**: **8/19 tasks (42%) ∅-matched** the skill library, batched into **4 shared-tag clusters** — `[T009,T011,T012,T015,T017]` · `[T010]` · `[T014]` · `[T019]`. `GRANT_TRIPWIRE: none`. The full agent-assign contract would now dispatch 4 web-search Sonnet skill-builders to author 4 new skills into the **shared** `.claude/skills/` library. This is the moment D66 booked: *"neither lever has a steady-state datapoint yet (003's own build was hand-rostered gap-free); revisit when the flywheel first fires for real."*

### Diagnosis (airtight — replicated `assemble.py`'s gap set exactly)

**Root cause = seed breadth. The gap criterion is NOT a threshold that can be "too loose."**

1. **The gap test is zero-overlap, the strictest possible.** `assemble.py:736`: `skill_gap = len(candidates) == 0 and len(task.tags) > 0`, where `_find_candidates` = `{ s : s.tags ∩ t.tags ≠ ∅ }` (line 679). Jaccard (`_rank_key`) only **ranks** the overlapping candidates; it is **never** the gap gate. A task gaps *only* when it shares **literally zero tags** with **every** skill. There is no loose threshold to tighten.

2. **All 8 gaps have ∅ intersection with the entire 18-tag library vocabulary.** The library's tags are wholly *code-plumbing*: `{bash, shell, posix, install, uninstall, idempotent, reinstall, yaml, config, manifest, hooks, orchestration, subagent, dispatch, parallel, refactor, blast-radius, behavior-preserving}`. The gapped tasks are wholly *spec-kit authoring*: `contract, frontmatter, template, completion-report, coverage-map, sc-fr-mapping, prompt, tester, verification-approach, quickstart, e2e, artifact-layout, d19-event, …` — a **disjoint tag space** the seed library never touched.

3. **The 11 matches confirm the same narrowness.** They rode plumbing tags only — `bash`→shell-scripting (5 tasks matched on `bash` *alone*), `install/reinstall`→installer-hygiene, `yaml/config/manifest/hooks`→yaml-hooks, `dispatch`→orchestration, and `preserves_behavior:true`→refactor-discipline (auto-inject, T019).

### Corroboration — this is the **second** datapoint, not an outlier

| Feature | Work character | ∅-match rate |
|---|---|---|
| `003-workforce` (session log row 169) | extension plumbing + python + prompts | **14/32 = 44%** (hand-rostered gap-free; flywheel *would* have built) |
| `004-testing-completion` (this run) | doc/contract/prompt authoring | **8/19 = 42%** (flywheel fired for real) |

Two structurally different features, ~43% ∅-match each. The seed library (5 skills, grown from 001/002/003's plumbing) has **zero coverage of the pipeline's authoring dimension** — contracts, dispatched prompts, command skills, templates, quickstarts — which M4 is the first feature to exercise heavily. The "seed breadth" lever D66 named is now empirically the dominant one; "gap-batching granularity" and any threshold notion are **not** implicated.

### The three MACHINE-PASS measurements (for the gate)

| Measurement | Value | Note |
|---|---|---|
| **general-rate** | **0/19 (0%)** | far under the floor'd cap `max(1,⌊0.2·19⌋)=3` (validator PASS) |
| **runtime_consumed hits** | **3** | T011, T014, T015 — the dispatched/rendered `templates/*.md` assets (D65 §2.4 modifier); holds the Sonnet floor |
| **gap-cluster count** | **4** | 8 ∅-match tasks; D66's first live firing |

### The decision this tees up (owner's call)

The gaps are real (genuine zero-overlap), and every gapped task already sits on a **capable base** — the missing skills are *additive guidance*, not missing capability, so a roster with these gaps open is a valid interim state. Options, roughly:

- **(a) Fire the flywheel as designed** — 4 skill-builders → 4 new skills in the shared library. Risk: reactive per-gap authoring on the first firing may over-fit M4's idiosyncratic tags (`d19-event`, `executed-none`, `artifact-layout`, …) that no future feature reuses.
- **(b) Broaden the seed deliberately** — hand-curate 1–2 genuinely-reusable authoring skills (e.g. a `docs-contract-authoring` and/or a `dispatched-prompt-authoring` module — tags `contract/schema/frontmatter`, `prompt/system-prompt/dispatch`) that future pipeline features will reuse, rather than 4 M4-shaped ones. Matches D66's "evidence-based curation, not speculative seeding" ethos now that there's evidence.
- **(c) Accept the gaps for M4** — gate the roster as-is; the capable bases author the docs/contracts/prompts without injected skill-guidance (as `003` did with its 14 gaps). Zero shared-library mutation; revisit seed breadth as a standing item.
- **(d) Tune batching only** — not indicated: the batching is downstream of the (correct) zero-overlap gate and doesn't change *whether* tasks gap.

**Recommendation:** (b) or (c) over (a) for the *first* firing — the value is in the **finding** (seed breadth is the lever, now twice-confirmed), and reactive per-gap authoring is exactly the speculative-curation risk D66 warned against. Whichever is chosen becomes a `docs/90` D-row resolving **I-20**.

---

## F2 — The workforce-gate binding requires commit-BEFORE-bind (the gate decision lives inside the bound file)

**Station:** `workforce-gate` (`/speckit-workforce-approve` + `on-gate-approve.sh`). **Status:** handled correctly this run (two gate commits); flagged for the M6 HookExecutor → **I-22**.

The **council** gate binds `plan.md`, whose decision section lives in a *separate* file (`decision-record.md`) — so approval + binding commit as one (as `de0e62d` did). The **workforce** gate binds `agents/assignment.md`, whose `## Workforce Gate` decision section lives **inside that same bound file**. `on-gate-approve.sh workforce` records `assignment.md @ sha.sh(assignment.md)` = the last *committed* sha. **Empirically confirmed this run:** with the gate resolution edited-but-uncommitted, `sha.sh(assignment.md) = 092b17e` (pre-resolution) — firing the hook then would have bound `092b17e`, which goes stale the instant the gate commit re-touches `assignment.md`, hard-blocking wave 1. Correct sequence (used): **resolve → commit gate (`5a7f705`) → fire `on-gate-approve` (binds `5a7f705`) → commit `gates.yml` (`a1a1366`) → `verify-gate workforce` = 0**. The `/speckit-workforce-approve` skill's prose ("write fields → fire hook") under-specifies this ordering; a naive write→fire→commit-together binds a stale sha. **Load-bearing for the M6 HookExecutor**, which must fire `after_workforce_approve` *after* the gate-resolution commit — not as one write→fire→commit step. Not a defect (the machinery is correct when sequenced right); a documentation/automation gap the first live machine binding (D68) surfaced.

---

## F3 — install.sh's PyYAML-less manual-fallback block is stale for the new testing seam (latent, mirrors the I-16/S02 hazard)

**Station:** `implement` pre-flight T005 (git-ext `extension.yml`) + the frozen `extensions/git/install.sh`. **Status:** OPEN → owner call (book I-row). **Severity:** minor/latent — does not bite this run.

T005 (correctly, per its file scope = `extension.yml` only) added the `after_complete`/`after_testing` hook declarations to the git-ext **manifest**, which the installer's **auto-merge path** reads dynamically — so on any host with PyYAML or `uv` (i.e. this host, and effectively all real ones) the two hooks register correctly (T008 confirmed: appended to the installed registry, append-only, idempotent). **But** `install.sh`'s `print_manual_block` — the hand-paste text emitted only when a host has *neither* a PyYAML interpreter *nor* `uv` — hardcodes its hook list and was **not** updated (it lists `after_specify…after_workforce_approve` but not `after_complete`/`after_testing`). A human pasting that block on a fallback-only host would silently omit the testing/complete commit seam. This is the **exact shape of the I-16/S02 hazard** 003 already hit and fixed for `after_workforce_approve` (run.sh §4 even carries a static grep asserting the manual block declares it). There is **no** equivalent static check for `after_complete`/`after_testing`, so nothing guards this drift.

**Why it didn't surface as a wave failure:** the T007 seam regression and the T008 reinstall both exercise the *auto-merge* path (uv present), which is manifest-driven and correct; the manual block is unreachable on any host the tests run on.

**Recommendation (owner):** cheapest correct fix is a one-line-per-hook addition to `print_manual_block` **plus** a run.sh §4-style static grep (`install.sh manual fallback declares after_complete/after_testing`) so the manifest and the hand-paste block can't silently diverge — the same belt-and-suspenders 003 applied. Out of scope for M4's approved task set (T005 was scoped to `extension.yml`); flagged here rather than fixed. → a `docs/90` I-row (installer manual-fallback completeness as a standing invariant).

---

## F4 — the SC/FR coverage validator must exclude cross-feature `NNN-FR-` references (a real grep hazard the T016 validator must dodge)

**Station:** `implement` Wave 3 T012 (testing-doc contract authoring) surfaced it; **owner of the fix:** Wave 4 T016 (the coverage validator). **Status:** handled — baked into the T016 dispatch prompt this run; booked here as the durable rationale. **Severity:** correctness (a naive validator would false-positive).

`spec.md` cites `001-FR-019` twice — line 83 (Edge Cases) and **line 106 (inside `### Functional Requirements`, in FR-010's own body)** — a **cross-feature reference to feature 001's FR-019**, not one of `004`'s own requirements (004's real range is **FR-001…FR-017**, 17 FRs; SCs are **SC-001…SC-010**, 10). A naive `grep -oE 'FR-[0-9]+' spec.md` returns **18** distinct FRs including a spurious `FR-019`, and R1-S03's rule ("every `SC-\d+`/`FR-\d+` in spec.md must have a `testing.md` coverage-map row, fail on any gap") would then demand a coverage row for a non-existent 004 requirement — a false failure, or worse a fabricated row.

**Why section-scoping alone is insufficient:** the `001-FR-019` on line 106 sits *inside* the `### Functional Requirements` section (lines 90–120), so bounding the grep to that section does NOT exclude it. The robust rule (empirically confirmed this run: `[0-9]{3}-FR-[0-9]+` matches only `FR-019`): **exclude any `SC-`/`FR-` token immediately preceded by a `\d{3}-` prefix** (a cross-feature citation), then take the distinct set → exactly the 10 SC + 17 FR of 004. No `SC-` cross-feature citation exists in spec.md (only the FR one), but the validator should apply the same exclusion symmetrically for durability.

**Disposition:** the T016 validator prompt (Wave 4) carries this exclusion rule explicitly, and T016's own tests should include a guard that the validator counts exactly 10 SC + 17 FR (not 18) against this spec. A good standing generalization for the pipeline: SC/FR coverage validators across features must treat `NNN-`-prefixed ids as foreign. → a `docs/90` I-row (cross-feature-reference exclusion as a coverage-validator invariant). **Resolved this run:** T016's `extract_ids()` uses `([0-9]{3}-)?(SC|FR)-[0-9]+` and drops prefixed tokens; harness asserts naive=28 vs fixed=27, plus an isolated exclusion unit test — 43/0 green.

---

## F5 — R1-S06's tester-trace `context_in` field is not sanctioned by `trace-schema.md` (a cross-contract tension two agents independently caught)

**Station:** `implement` Wave 4 — surfaced **independently by BOTH T013** (`/speckit-testing` skill) **and T015** (`trace-fragment.md`), which is strong signal it's real, not a one-agent misread. **Status:** OPEN → owner call (book I-row). **Severity:** latent contract inconsistency (no strict trace validator runs in v1, so it doesn't bite this run).

Council suggestion **R1-S06** (accepted, binding) mandates: *"the `tester` trace MUST carry a `context_in` field (files read)."* The testing extension's trace-fragment and the `/speckit-testing` skill both correctly emit it. **But** `docs/contracts/trace-schema.md` is still at status **1.2 (unamended)**: its §1 field table does **not** list `context_in`, and its §7 rule 2 states *"Every record has all §1 fields; **unknown fields are rejected**."* Taken literally, a conforming `role: tester` record carrying `context_in` would be **rejected** by a strict trace-schema validator — R1-S06 and trace-schema.md §7 rule 2 are in direct tension, and no M4 task reconciles them (the testing tasks author the trace *producers*; none amend the *schema*).

**Why it didn't bite:** v1 trace validation is prose-level (there is no strict trace-schema conformance checker running in the pipeline yet — `trace-schema.md` §7 is the spec for a future one). So the field is emitted and read fine today; the inconsistency is latent until someone builds the §7 validator.

**Recommendation (owner):** amend `trace-schema.md` to sanction `context_in` — cleanest as a `role: tester`-scoped optional field in §1 with a one-line §7 carve-out (mirrors how `elevated_grants`/`skills` are role-gated), bumping the schema to 1.3 and citing R1-S06. Alternative (weaker): an explicit "the tester role adds `context_in`; §7 rule 2's unknown-field rejection excepts it" note in §7. Either closes the gap before the M6/M-later strict trace validator ships and starts rejecting valid tester traces. Out of M4's approved task scope (no task touches `trace-schema.md`); flagged, not fixed. → a `docs/90` I-row (fold R1-S06 `context_in` into trace-schema.md).

---

## F6 — the doc-only tester correctly GAPs a requirement satisfied UPSTREAM of implement (gap-honesty working as designed; the first live tester run surfaced it)

**Station:** `testing` (the first live `/speckit-testing` run, M4 close-out). **Status:** ✅ correct-as-designed — no fix; pattern noted for future doc-only testing. **Severity:** none (a validation of the design, not a defect).

The first live `testing.md` mapped 27 ids as a full bijection and flagged **exactly one honest GAP: FR-017** ("the I-17 fix design is plan-level and MUST be council-reviewed as gate-integrity"). FR-017 **is** genuinely satisfied — but at **council round-1** (`de0e62d`; `tasks.md` Dependencies even says so: *"FR-017 … already satisfied — round-1 council reviewed it … no build task"*), which is **upstream of the implement phase**. The tester's bounded context is `completion-report.md` + `spec.md` only (SC-003); the completion report is the *implement* account and legitimately carries no evidence of a *council* review, so the tester — correctly refusing to fabricate a `covered` from evidence it cannot point to (Step 5 gap-honesty, SC-002/004) — marked it `GAP`. **This is the honesty ethos working exactly as intended**, and it is a *correct, complete* run (a GAP is a valid answer; a fabricated `covered` would not be).

**The pattern (for future features):** any requirement satisfied at spec/plan/council/gate — *outside* the implement run — will be GAPed by a completion-report-grounded tester **unless** the completion report's `### Integration status` deliberately surfaces that upstream evidence. Two honest readings, both defensible: (a) leave it a GAP (the tester's grounding is the implement account, and "council-reviewed" isn't an implement fact) — the human reading `testing.md` resolves it against the council record, which the GAP correctly points them to; or (b) have `/speckit-complete` note council/plan-satisfied requirements in Integration status so the tester can ground them as `covered` (report-claimed). M4 took (a) by construction (the report was authored before this was observed). **Not a defect** — booked as the design property the first live tester run confirmed. No `docs/90` row (nothing open to decide); if a future feature wants (b), that is a `/speckit-complete` authoring convention, a fresh decision then.

---

## Adjudication (M4 close-out) — all findings disposed

Per this file's own model (each finding → a `docs/90` D-row/I-row on adjudication, folded into `completion-report.md`'s `### Findings adjudicated`):

| Finding | Disposition |
|---|---|
| **F1** — flywheel first firing = seed-breadth signal | **RESOLVED → D71** (seed 2 authoring skills; 6 gaps closed, 2 residual; zero builder dispatches). Sub-finding → **I-21**. |
| **F2** — workforce-gate commit-before-bind | **Booked → I-22** (M6 HookExecutor). Handled correctly by hand this run. |
| **F3** — install.sh manual-fallback stale for the seam | **Booked → I-23** (git-ext follow-up pile). Latent; auto-merge path unaffected. |
| **F4** — coverage validator must exclude `NNN-` cross-refs | **RESOLVED this run** (T016 `extract_ids()`; naive 28 → 27, isolated exclusion test). |
| **F5** — tester `context_in` not in trace-schema.md | **RESOLVED → D72** (trace-schema → 1.3; committed `0ef22e5` before the tester ran). |
| **F6** — doc-only tester GAPs upstream-satisfied FR-017 | **Correct-as-designed** — gap-honesty working; pattern noted, no fix. |
