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
