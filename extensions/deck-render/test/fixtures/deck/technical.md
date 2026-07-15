# Defense Deck — Technical

**Feature**: `005-graphify-context`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

The graph-context layer graphify produces is no longer a standalone convenience — it is read today by **six live consumers**: `/speckit-plan`, `/speckit-tasks-graph`, `/speckit-implement-parallel` (the three `before_*` hooks), the council member (its receipts tool, D10), the categorizer (`type` derivation, taxonomy §1), and deck-prep (D62). Four telemetry-grounded problems have accumulated under that load:

1. **Coverage (US1, P1).** The graph is blind to the pipeline's own artifact types — `.sh`/`.yml`, and `.md` templates are opaque. At `004`, `verify-gate.sh` resolved to degree 4 and `commit.sh` to degree 3, and `path "verify-gate.sh" → "implement-parallel"` returned **no edge** even though `implement-parallel` calls `verify-gate.sh` every wave. `[P]` and blast-radius fall back to file-disjointness for nearly every plumbing feature (002/003/004 all shipped on the fallback).
2. **Freshness (US2, P1).** Keeping the graph current costs a ~753k-token/~11-min/5-session full-regen ritual (D59 step-0), because the incremental `--update` path can't be trusted: at M3 `detect_incremental` saw the whole corpus as changed and `build_merge` left **86 stale duplicate nodes**. Worse, nothing checks whether a generated `graphify-context.md` is still current — at `002` it silently predated the `contracts/` it should have grounded by six minutes and nearly caused `/speckit-tasks` to omit a real seam edit (R1-S03).
3. **One-size-fits-all product (US3, P2).** Every consumer reads the same fixed-shape `graphify-context.md`, even though their needs differ — plan/tasks/implement want blast-radius, the council member and deck-prep want concept/rationale receipts, the categorizer wants per-file `type` signals. D62 already showed a hand-tuned, better-targeted slice cut per-member graph queries 3/5→1/5 and stage-1 spend −25.1%.
4. **Unbounded query cost (US4, P2).** A council member's on-demand graph-query loop is unbounded: at `002` each member ran 25–38 tool-call turns, and because every turn churns `cache_creation`, transcript spend ran ~3.4× the Agent-return aggregate — 5.25M billable tokens for one round.

This feature (`005`, the first of the `005`→`006`→`007` α-polish trio, D73, size M) is leverage on the working pipeline, not new function — it makes the shared graph-context layer cheaper and higher-signal for all six consumers without adding new pipeline behavior.

---

## 2. Chosen Approach & Rejected Alternatives

**Chosen approach**

`005` fixes all four problems as **specseyal-owned augmentation at the extension seam** (D57/I-14, reinstall-survival-tested), landing entirely in `extensions/graphify/` and `extensions/council/`, **without touching upstream `graphifyy`** (D75 — it stays an upstream pip dependency, archivable per D29). It ships as **four independently-shippable, independently-reviewable arms** (D74-2 severability), each mapping to one of the four problems above: **Coverage** (arm 1), **Freshness as a property** (arm 2), **Tiered products** (arm 3), **Query ceiling** (arm 4). The Constitution Check passed with **no violations and no Complexity Tracking rows** — notably, no arm introduces a new model role (D18 unchanged: arm 1/2 are mechanical scripts, arm 3 is the existing generator, arm 4 is a member-prompt + orchestrator change).

An explicit **detach order** governs severability: **core, never-detach = arms 2 + 3 + 4; detach-first = arm 1.** The plan states the rationale verbatim, as the D74-2 ruling requires: *"Arm 1 detaches first NOT because it is least important — its coverage is the headline I-13 fix — but because it is the only arm with a working fallback. Absent arm 1, blast-radius and `[P]` on `.sh`/`.yml` degrade to the labeled-assertion / file-disjointness path the pipeline already uses honestly today... Arms 2, 3, and 4 have no fallback: without arm 2 the ~753k-token ritual and silent staleness persist; without arm 3 every consumer keeps over-reading one diet; without arm 4 the 25–38-call cache-churn loop stays unbounded. Detachability follows fallback, not importance."* No arm descopes silently — any detach is a triage disposition or a gate note.

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| **Fork `graphifyy`** (edit the upstream extractor directly to add coverage/freshness fixes) | D75/D29: `graphifyy` stays an upstream pip dependency, archivable, untouched. All four arms instead call its CLI/API and augment *around* it at the extension seam (D57/I-14) — arms 1/2 wrap `build_merge`/`detect_incremental`, never edit them. A fork would break reinstall-survival and couple `005` to upstream release cadence. |
| **Broad-semantic extraction** (infer *all* cross-file relations, not just plumbing edges) | Explicitly scoped down in clarification: coverage is bounded to **exactly three** edge kinds — hook registration, install copy, script→script invocation — the ones that carry plumbing blast-radius. "Broader semantic inference of all cross-file relations is out of scope" (FR-002); the labeled-assertion fallback (FR-004) covers what these three do not. Named explicitly in spec Out of Scope as *not* "language-server-grade extraction of every file type." |
| **One sectioned context file** (single `graphify-context.md` with per-consumer sections, instead of separate products) | Rejected because it makes the no-cross-payment guarantee (FR-010) **aspirational, not structural** — "a sectioned file leaves 'read only your section' as unenforced prose" (the D53 prose-vs-mechanism lesson). The chosen shape — one generator emitting three separate, token-bounded products — makes it **structural**: a consumer that opens only its product literally cannot pay for another's tokens (R2 in §5 covers the resulting drift risk this alternative would have avoided differently, at the cost of the enforcement guarantee). |
| **Demand-reduction-only query bound** (rely on the receipts tier, US3, to reduce a member's *need* to query, with no hard cap on call count) | Clarification 2026-07-13 ruled this insufficient on its own: FR-011 requires a **hard, enforced** ceiling on query *count* — `--budget` already caps per-call *output*, but nothing capped call *count*, which is what actually drives the 3.4× cache-creation multiplier. Demand-reduction via tiered receipts (arm 3) is kept as **complementary**, not a substitute — a member that needs fewer queries also needs a backstop for when it still runs long. |

---

## 3. Architecture & Data Flow

Every arm below is annotated with **which component performs its write** — this is a load-bearing distinction (D53): a **mechanical script** runs deterministically with no model call and (per the Constitution Check) writes no trace, the same class of component as `commit.sh`/`verify-gate.sh`; a **live model session** is a dispatched or inline Claude session whose output is not byte-reproducible from inputs alone. Conflating the two is exactly the kind of unenforced-prose gap D53 names.

**Baseline (unchanged).** The upstream `graphifyy` CLI/API (`build_merge`, `detect_incremental`, AST `extract`) produces the base graph exactly as it does today (D75) — this stage is out of augmentation scope for every arm; arms 1/2 call it, none edit it.

**Arm 1 — Coverage** (`extensions/graphify/extension/scripts/augment.sh` + a small Python helper)
- **Performed by:** a **mechanical script** — a post-extraction pass, no model call, no trace (like `commit.sh`).
- **Reads:** the graph immediately after upstream extraction completes; the repo's `.sh`/`.yml`/`.md` files.
- **Writes:** nodes for those artifact types, plus exactly **three** cross-file edge kinds — (1) hook registration: an `extension.yml` `hooks.*` entry → the command/skill it names; (2) install copy: an `install.sh` `cp`/`rm -rf`+copy of a source tree → its installed target; (3) script→script: one `.sh` sourcing/exec'ing another. Merges into `graph.json` (or the pre-build extraction JSON) so `explain`/`path` resolve them.
- **Guarantee claimed:** byte-deterministic on a known topology (fixture-checkable); where a relationship can't be modeled, it emits the **labeled-assertion fallback**, never a silent gap (FR-004, S22) — coverage is honest, not claimed complete.
- **Contract surface:** `explain "verify-gate.sh"` gains the `implement-parallel`/`before_implement` caller edges; `path "verify-gate.sh" "implement-parallel"` returns a path — the SC-001 exit test (today: "No path found", verified live, see §4).
- **S22 caveat:** the pass's own `.sh`/`.py` are themselves graph-invisible until it has run on the repo — its blast radius is asserted by source-reading, not graph fact.

**Arm 2 — Freshness as a property** (`extensions/graphify/extension/scripts/freshness.sh` + `refresh.sh`)
- **Performed by:** two **mechanical scripts** — no model call, no trace, same class as arm 1.
- **Staleness check (`freshness.sh`) — reads:** the graph's manifest/hashes against the current working tree. **Writes:** a fresh/stale report; no state file (freshness is a derived property, D32). On stale, it **hard-warns and routes to regeneration** — the D58/S14 categorization-SHA pattern, explicitly **not** a new hard-block gate (Clarification 2026-07-13).
- **Incremental refresh (`refresh.sh`) — reads:** the current graph + the changed-file set; wraps the upstream `build_merge`. **Writes:** the merged graph, carrying the **stale-survivor guard** proven by hand at step-0 — after a merge, assert no node attributed to a changed file survives absent from the fresh extraction (step-0 measured **0** survivors; M3's ungated merge had left **86**). On survivors > 0: prune-or-rebuild rather than ship a contaminated graph.
- **Guarantee claimed:** equivalence to a full regen for the changed scope (every new node/edge added, every superseded node pruned) at materially lower cost than the full-corpus ritual — the SC-004 exit test. If the invariant can't be met for a change set, the system falls back to a full regeneration rather than ship an inequivalent graph (FR-008, freshness honesty over cost).
- **Contract surface:** `freshness.sh` exit code + report; the refresh emits the survivor count (the step-0 measurement, now mechanical and repeatable).
- **S22 caveat:** wraps `build_merge`/`detect_incremental`, which are out-of-repo and graph-invisible (D75) — the wrapper's own reach is asserted by source-reading, not graph fact.

**Arm 3 — Tiered context products** (the `speckit-graphify-context` skill, `extensions/graphify/skills/…`)
- **Performed by:** the **existing generator**, unchanged in kind — this is a skill, not a headless script, so its write is performed inline by whichever **live model session** invokes the `before_plan`/`before_tasks`/`before_implement` hook (or the graph-aware speckit variant), reading the skill's instructions and running graph queries. D18 Model Policy is explicit that this introduces **no new model role**: arm 3 changes what the generator emits, not who/what performs the write.
- **Reads:** the current (augmented, fresh) graph.
- **Writes:** **three separate, token-bounded products from one generator run** — (a) `graphify-context.md`, the blast-radius/shared-mutable/`[P]` diet for plan/tasks/implement, **unchanged shape** (FR-013 non-regression); (b) a **receipts** diet (concept/rationale slice) for the council member + deck-prep; (c) a **type-signal** diet (per-file `type` signals + path-convention fallback) for the categorizer.
- **Guarantee claimed:** each product is token-bounded and carries only its consumer's slice — **structurally**, not by convention (the rejected "one sectioned file" alternative in §2 is exactly what this guards against; the D53 lesson). One generator, one graph pass, keeps the three products coherent (mitigates the drift risk at R2, §5).
- **Contract surface:** the three product paths + their token bounds.
- **S22 status:** **grounded**, not asserted — the skill and its consumers are `.md`/document nodes the graph already sees.

**Arm 4 — Query-cost discipline** (`extensions/council/extension/templates/member-prompt.md` + the orchestrator's member-dispatch)
- **Performed by:** a **prompt/orchestrator change**, split across two write paths at runtime. The **enforcement** — the hard cap itself, resolved from `council-config.yml`'s `member.query_ceiling` (tier-aware) — sits in the orchestrator/dispatch layer, i.e. it is **config-driven and mechanical**, not a model decision. The **disclosure content** — the reduced-grounding note appended to a ceiling-limited opinion — is authored by the **live model session** (the council member itself, Sonnet), extending the `reduced grounding note (FR-019)` the member-prompt already references (degree-16 node, confirmed live in the graph — see §4). The **trace fields** (`graph_queries` count, `ceiling_hit` flag, FR-012) are recorded per-round telemetry, consistent with this pipeline's existing append-only trace convention (D35) — a mechanical record of what the member did, not a claim the member makes about itself.
- **Reads:** `council-config.yml` `member.query_ceiling`; the member's live graph-query call count during its review.
- **Writes:** the member's own opinion (carries the disclosure line when the ceiling is hit — D74-3, SC-008); the round's trace record (`graph_queries`, `ceiling_hit`).
- **Guarantee claimed:** ceiling-hit is **never silent** — it is disclosed in the consumer's own output *and* recorded in its trace, so the chairman can weight a ceiling-limited opinion rather than trust it as fully grounded (SC-008). This never changes the tier, the member count, the model map, or who signs (D56 untouched).
- **Baseline note:** `005`'s own council round records **per-member query counts uncapped** — this is arm 4's own calibration baseline, and (by owner directive) the last round that will ever run without a ceiling.

---

## 4. Project Structure & Dependency / Graph Impact

**Project Structure** (from `plan.md`)

```text
specs/005-graphify-context/                         # documentation (this feature)
├── plan.md · research.md · data-model.md · quickstart.md · contracts/commands.md   # plan phase
├── spec.md (approved) · graphify-context.md · graph-baseline.json · graph-baseline-measure.md
└── profile.yaml (standard / both-human)

extensions/graphify/                                # source, all specseyal-owned, graphifyy untouched (D75)
├── extension/scripts/augment.sh        # arm 1 — post-extraction .sh/.yml/.md nodes + 3 edge kinds
├── extension/scripts/freshness.sh      # arm 2 — staleness check (hard-warn + regenerate)
├── extension/scripts/refresh.sh        # arm 2 — incremental wrapper + stale-survivor guard
├── skills/speckit-graphify-context/    # arm 3 — one generator → 3 separate products
└── test/                               # arm-1/2/3 goldens + consumer fixtures 1, 2, 3, 5, 6

extensions/council/
├── extension/templates/member-prompt.md   # arm 4 — query ceiling + ceiling-hit disclosure
├── extension/council-config.yml            # arm 4 — member.query_ceiling
└── test/                                    # consumer fixture 4 (ceiling + disclosure)
```

**Structure Decision:** augmentation-only at the extension seam (D75). Arms 1–3 live in `extensions/graphify/` source; arm 4 in `extensions/council/` source. Every edit is reinstall-survival-tested (D57 — the installer `rm -rf`+`cp`s these trees, so a source-only edit is the sole survivable form). `graphifyy` is never edited. Cross-extension coupling (arm 4 ↔ the graphify products) attaches at a hook/config point, never a foreign source edit (I-14).

**Shared/mutable collision list** (from `graphify-context.md` — serialize any tasks touching these; never co-schedule two in one parallel wave):
- `.specify/extensions.yml` — the hook registry; every extension's installer merges into it. **Highest collision point** — but this is flagged **assertion**, not a graph edge (see blind spot below); the M2 live collision bug is the supporting record (R1-S17).
- `extensions/graphify/skills/speckit-graphify-context/SKILL.md` + its installed copy under `.claude/skills/` — arm 3's central edit (D57 source-edit rule).
- `extensions/council/extension/templates/member-prompt.md` + installed `.specify/extensions/council/` copy — arm 4's edit (same D57 rule).

**Dependency / Graph Impact** (from `graphify-context.md`, independently verified — every number below is the tool's own output)

- Baseline graph: **1611 nodes, 2674 edges** (the fresh D59 step-0 baseline, `graph-baseline.json`).
- `.claude/skills/speckit-graphify-context/SKILL.md` (arm-3 home) — **degree 2**: referenced by tasks-graph + implement-parallel. Graph-grounded.
- `extensions/council/extension/templates/member-prompt.md` (arm-4 home) — **degree 16**: already references `member_lenses`, `plan.md`, and the reduced-grounding note (FR-019) — the D74-3 disclosure hook arm 4 extends. Graph-grounded.
- Concept/rationale layer: **277 rationale nodes + 541 concept nodes** (the spec, D-rows, contracts) — grounds well.

**The blind spot, stated plainly — this feature is Exhibit A for reduced grounding.** Verified live against the baseline graph:
- `explain "verify-gate.sh"` → **degree 5, every edge intra-file** (`contains` + `defines` die/mark_stale/usage/count_lines). **Zero cross-file edges.**
- `path "verify-gate.sh" "implement-parallel"` → **"No path found"** — even though `implement-parallel` calls `verify-gate.sh` **every wave**. This is arm 1's exact target relationship, and the graph is blind to it *today*, as of this baseline.
- The upstream `graphifyy` extractor (`build_merge`/`detect_incremental`/AST `extract`) — arm 2's subject — is a **pip package outside the repo**, so it has **no nodes at all** (D75).

**Every blast-radius claim in this deck (and in `plan.md`) on a `.sh`/`.yml`/upstream-`.py` file is engineer assertion re-derived by reading source — NOT graph fact.** This includes: the `.specify/extensions.yml` "highest collision point" claim above, every arm-1/arm-2 "reads/writes" description in §3 (the augmentation pass and the freshness/refresh scripts are themselves `.sh`/`.py`, i.e. exactly the coverage gap they are built to close), and R1/R4 in the risk register below. The concept/rationale layer grounds well; the code-plumbing layer — this feature's own change surface — does not. This is disclosed *doubly*: the council reviewing this plan is itself a graph consumer reading a graph that cannot yet see the files under review.

---

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **R1 — Arm 1 is the graph's blind spot fixing itself.** The augmentation pass adds `.sh`/`.yml` edges, but its own correctness can't be graph-verified (I-13; live: `verify-gate.sh` degree-5-intra-file, no `→implement-parallel` path, see §4). | High (standing condition — always true for this arm, not a maybe) | Medium (doesn't block correctness of what ships; means confidence rests on fixtures + human review, not self-verification) | Deterministic golden fixtures + source-read review; the council checks receipts by reading source, not the graph (S22, disclosed doubly). |
| **R2 — Separate-products packaging (arm 3) risks drift between the three diets.** | Medium | Medium (would erode the tiering value proposition if diets desync) | One generator, one graph pass; a shared-provenance header; goldens per product. (Chose structural FR-010 over a sectioned file precisely to avoid "read only your section" prose — §2.) |
| **R3 — The query ceiling (arm 4) could starve a member mid-review.** | Low (ceiling is calibrated against this round's own uncapped baseline, explicitly generous relative to the median member) | Medium (a starved member's opinion is reduced-grounding — but disclosed + weightable, not silent, SC-008) | The ceiling is tier-aware and generous relative to the *median* member (the 25–38 range is the uncapped tail); a ceiling-hit is disclosed + weightable, not a silent truncation. This round's per-member counts calibrate `N`. |
| **R4 — Upstream `graphifyy` drift.** A future release could change `build_merge`'s contract under arm 2's wrapper. | Low | Medium–High (a silent contract break could corrupt the freshness guarantee) | The wrapper pins to the CLI/API surface it uses; survival fixtures catch a break; `graphifyy` is a versioned dependency (D75). |
| **R5 — Self-reference at the council.** The council reviewing this plan queries a graph that cannot see the fix under review (S22 doubly). | High (certain for this round — not probabilistic) | Low–Medium (mitigated by disclosure; doesn't block the review, tempers confidence in code-plumbing claims specifically) | `graphify-context.md` is Exhibit-A honest (§4); reduced grounding is disclosed per FR-019/D10; this round's own query counts become arm 4's baseline. |

**Complexity Tracking:** the Constitution Check passed with **no violations and no Complexity Tracking rows** — no risk beyond R1–R5 is flagged by the gate itself.

---

## 6. Cost / Complexity Estimate

**This council round (standard tier, D61):** **8 sessions** — 1 deck-prep (Sonnet, mechanical role, this session), 5 council members (Sonnet, mechanical role per D18), 1 consolidated peer critique (Sonnet — `standard` tier replaces `full` tier's 5 per-member peer reviews with one consolidated pass + lazy context), 1 chairman synthesis (Opus, xhigh — judgment role). This matches the `full` tier's 12-session ceremony minus the per-member peer-review fan-out.

**Downstream of this round:** council-triage — 1 session (Opus, judgment role per D18: analyze/triage), **+1 conditional** chairman-only delta check if a blocking suggestion forces a plan revision (FR-010 of the council-triage contract).

**Implementation (later, `/speckit-tasks` → `/speckit-implement-parallel`, not yet session-counted — tasks.md doesn't exist yet):** bounded to the **four severable arms** — mechanical scripts (arm 1's `augment.sh`, arm 2's `freshness.sh`/`refresh.sh`), one existing generator extended (arm 3), and one prompt/orchestrator change (arm 4). Per D18, implementation agents are Sonnet; **no arm introduces a new model role** (Constitution Check, Model Policy: PASS). Complexity is cross-cutting in *surface* — two extensions touched (`extensions/graphify/`, `extensions/council/`), six live consumers requiring non-regression fixtures (§7) — but bounded in *kind*: no new dependency (`graphifyy` stays untouched, D75), no new state file (freshness is derived, D32), no new gate structure (D9 untouched). Scale/Scope is explicitly sized **M** (D73 α-polish — leverage on the working pipeline, not new pipeline function).

---

## 7. Testability Claim & Plan-Time Verifications

`plan.md` carries no `## Plan-time verifications` table for this feature; the picture below is assembled from each arm's own **Fixture** line (§3), the **six named consumer fixtures** (FR-013/SC-009), and `spec.md`'s **SC-001…SC-009**.

### 7a. Per-arm fixtures

| Arm | Fixture | Committed? | S22 status |
|---|---|---|---|
| 1 — Coverage | A fixture repo slice with a known `.sh`/`.yml` topology → the pass emits the expected nodes+edges **byte-deterministically**. | Yes | Assertion (the pass's own `.sh`/`.py` are graph-invisible until it runs on the repo). |
| 2 — Freshness | A committed **pair**: (a) a graph + a mutated worktree → check reports stale; (b) a base graph + a changed-file extraction → refresh yields a graph equivalent to a full regen, **0 survivors**. | Yes | Assertion (wraps out-of-repo `build_merge`/`detect_incremental`, D75). |
| 3 — Tiered products | A committed golden **per product** — three of the six consumer fixtures land here. | Yes | Grounded (skill + consumers are `.md` nodes the graph sees). |
| 4 — Query ceiling | A member fixture whose reviewing loop is driven to the ceiling → the opinion carries the disclosure and the trace records the hit (the fourth consumer fixture). | Yes | N/A (council-layer, not code-plumbing). |

### 7b. The six named consumer fixtures (FR-013/SC-009 — non-regression with teeth)

| # | Consumer | Fixture asserts |
|---|---|---|
| 1 | `/speckit-plan` | Reads `graphify-context.md` (arm-3 blast-radius diet) unchanged in shape. |
| 2 | `/speckit-tasks-graph` | Consumes the same diet; `[P]`/wave derivation unbroken. *(Plan labels this "arm-3-adjacent" — it asserts downstream consumption behavior, not arm 3's product generation itself.)* |
| 3 | `/speckit-implement-parallel` | Consumes the same diet; per-task blast-radius unbroken. *(Also "arm-3-adjacent" per the plan's own framing.)* |
| 4 | Council member | Reads its receipts diet; query ceiling + disclosure fire (arm 4's own fixture). |
| 5 | Categorizer | Reads the type-signal diet; `type` derivation + path-convention fallback intact. |
| 6 | Deck-prep | Reads the receipts diet (the D62 enrichment source) unbroken. |

### 7c. Per-SC verification

| SC | Claim | Verification | Committed / Manual |
|---|---|---|---|
| SC-001 (coverage) | `[P]`/blast-radius graph-derived for majority of a plumbing feature's tasks; the `004`-invisible edges resolve. | Arm-1 golden fixture (7a) + live `explain`/`path` contract-surface check (§3). | **Committed** |
| SC-002 (honesty) | Zero unlabeled fallback claims — every un-modeled relationship is labeled, not silently omitted. | FR-004's fail-closed labeling behavior. | **Manual / gap** — see 7e; the arm-1 Fixture line as stated covers the *successfully-modeled* branch (known topology → correct nodes+edges) but does not separately name a case exercising the *fallback-labeling* branch (an edge kind that cannot be modeled). |
| SC-003 (freshness check) | A stale product (the `002` mtime case) is flagged before a consumer trusts it. | Arm-2 fixture (a): graph + mutated worktree → reports stale. | **Committed** |
| SC-004 (incremental equivalence + cost) | Refresh = full-regen equivalent, zero stale survivors, *and* materially lower cost. | Arm-2 fixture (b) covers **equivalence / 0-survivors**. | **Split** — equivalence is committed; the "materially lower cost" sub-claim has no stated cost-threshold assertion in the fixture — **manual/measurement-only**. |
| SC-005 (tiered diets + pull-drop) | Each consumer class reads its own slice; council member's on-demand pulls drop vs. one-diet baseline (extending D62 3/5→1/5). | Arm-3 goldens (7a) cover "reads own slice." | **Split** — slice-delivery is committed; the query-*pull-drop* comparison is a before/after telemetry read, not fixture-assertable — **manual/measurement-only**, same class as SC-006. |
| SC-006 (query-cost) | Member query count bounded + visible; round spend lower than an equivalent unbounded loop. | `005`'s own council round records **uncapped** per-member counts — this *is* the baseline measurement. | **Manual / measurement-only** — explicitly a one-time baseline this round (the ceiling doesn't exist yet to be tested against), not a repeatable green test. |
| SC-007 (non-regression / dogfood) | Full pipeline run (spec→…→testing) with all six consumers functioning, no regression. | Constituent claims are covered by the six named fixtures (7b). | **Split** — the six fixtures are committed; the end-to-end "the pipeline actually completed" claim is an observed dogfood pass, not itself a single committed test. |
| SC-008 (ceiling disclosure) | A ceiling-exhausted member's opinion carries the disclosure; trace records the hit. | Arm-4 fixture / consumer fixture 4 (7a/7b) — drives the loop to the ceiling. | **Committed** (see 7e for the branch caveat). |
| SC-009 (non-regression teeth) | Each of the six live consumers has a named, committed regression fixture. | *Is* the six-fixture table itself (7b). | **Committed** (× 6, by definition). |

### 7d. Tally

**4 of 9 SCs (SC-001, SC-003, SC-008, SC-009) have a clean committed/golden fixture backing their full claim. 3 of 9 (SC-004, SC-005, SC-007) are split — the structural/mechanical half is committed, but a cost, telemetry-comparison, or end-to-end-completion half is manual/measurement-only. 2 of 9 (SC-002, SC-006) have no committed fixture for their core claim** — SC-002's fallback-labeling branch is not separately named in the arm-1 fixture, and SC-006 is explicitly a one-time uncapped baseline measurement, not a repeatable green test (the ceiling it would test against doesn't exist until arm 4 ships).

### 7e. Branch/guard falsifiability — does the fixture set exercise BOTH branches?

- **Arm 2's stale-survivor guard (SC-004): NO, only the pass branch is fixture-backed.** The stated fixture (b) is "a base graph + a changed-file extraction → refresh yields a graph equivalent to a full regen, **0 survivors**." Nothing in the plan names a fixture that deliberately produces **survivors > 0** to prove the prune-or-rebuild guard actually engages and recovers correctly — the guard's only demonstrated behavior is passing cleanly. A guard that has only ever been exercised on the passing input proves nothing about its failure-handling branch.
- **Arm 2's staleness check (SC-003): only the stale branch is named.** Fixture (a) drives "graph + mutated worktree → reports stale." No fixture is named for the complementary case — an unmutated worktree → reports **fresh**, no warning — so a false-positive-stale failure mode is not demonstrably ruled out by a committed test either.
- **Arm 1's fallback-labeling branch (SC-002): not separately named**, as covered in 7c — the golden fixture demonstrates correct modeling of a known topology, not the labeled-fallback path for an unmodelable one.
- **Arm 4's ceiling-hit disclosure (SC-008): only the hit branch is named.** The consumer fixture drives a member's loop *to* the ceiling. No fixture is separately named for the complementary "ceiling not hit → no disclosure line appears" case — though this is a softer gap than the arm-2 stale-survivor guard, since ordinary (non-triggering) council rounds implicitly exercise the non-disclosure default throughout the rest of the fixture set.
