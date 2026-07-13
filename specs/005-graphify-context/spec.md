# Feature Specification: Unified Graph Context Management (graphify-context)

**Feature Branch**: `005-graphify-context`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "005-graphify-context — unified graph context management for cost and quality. The first α-polish feature (D73), run through the full pipeline at standard tier. graphify's graph layer is now consumed by LIVE extensions (plan/tasks-graph/implement-parallel read graphify-context.md; the council member queries the live graph as its receipts tool per D10; the categorizer derives `type` from graph signals; deck-prep mines it per D62). Four telemetry-grounded positions at spec altitude: (1) coverage of the pipeline's own artifact types (.sh/.yml/.md), retiring the I-13 fallback where feasible; (2) incremental graph maintenance vs full regen — freshness as a property, not a ritual; (3) tiered context products per consumer — one graph, several diets; (4) query-cost discipline — what bounds a member's 38-call loop. Every position cites its telemetry."

> **✅ APPROVED with adjudications — 2026-07-13 (D74).** Spec review ratified the **four positions + their clarify rulings as taken** — plumbing-edge coverage (three edge kinds, bounded), both freshness arms (staleness check + incremental-extractor fix), tiered diets (packaging at plan altitude), and a hard query ceiling; the **self-reference honesty clause** (the council checks receipts against a graph that cannot yet see the very files fixing its own blindness) **stands as written**. Four adjudications: **(1) Severability, not a split** — the plan presents the four arms as independently shippable concerns with an explicit descope order + rationale, so splitting is cheap and never silent (see *Severability* under Constraints; D74). **(2) Ceiling-hit is never silent** — an exhausted query ceiling is disclosed in the consumer's own output (a member's opinion carries the reduced-grounding disclosure, D10 / FR-019 lineage) and in its trace (FR-012; SC-008). **(3) Non-regression with teeth** — each of the six live consumers gets a named, committed regression fixture (FR-013; SC-009; the S04 lesson). See `docs/90` **D74**.

> **Reading note.** This is **`005-graphify-context`**, the first of the three **α-polish features** (D73) that run between Checkpoint α (M4, reached 2026-07-13) and the platform (M5). Checkpoint α is *already reached*; this is **leverage on the working CLI pipeline, not new pipeline function** (D73) — size **M**. It is dogfooded through the full pipeline at **`standard`** council tier (D61), which means the thing under review (the graph-context layer) is **consumed by the very council that reviews its plan** — see *Blast-radius honesty* below.
>
> **Altitude.** The spec fixes **WHAT** the graph-context layer must deliver and **WHY**, in observable terms (which claims are graph-grounded vs labeled assertion; whether freshness is checkable; which consumer reads which slice; whether a member's query loop is bounded and visible). The **HOW** — the extractor internals that would model `.sh`/`.yml`/`.md`, the incremental-refresh mechanism, the exact shape of each tiered product, the query-bound mechanism — is deferred to `/speckit-plan`. Positions below are taken with informed guesses and documented; the four genuinely-open boundaries were sharpened in the 2026-07-13 `/speckit-clarify` session (see `## Clarifications`), with the tiered-product *packaging* deferred to the plan.
>
> **Consumers are LIVE.** graphify is no longer a standalone grapher — its graph and its `graphify-context.md` are read today by **six live consumers**: `/speckit-plan`, `/speckit-tasks-graph`, and `/speckit-implement-parallel` (the three `before_*` graphify hooks in `.specify/extensions.yml`); the **council member**, which queries the live graph as its receipts tool (D10); the **categorizer**, which derives `type` from graph signals (taxonomy §1); and **deck-prep**, which mines it (D62). The blast radius of any change here spans live extensions, so this improvement MUST be non-breaking on the running pipeline.
>
> **Blast-radius honesty applies DOUBLY (S22 / I-13 / D10).** This feature's own files *are* graphify's extractor, the `speckit-graphify-context` skill, and the consumer extensions — overwhelmingly `.sh` / `.yml` / `.md` / `.py`, **the exact file types the graph cannot yet see** (I-13). So a plan grounding `005`'s own blast-radius hits I-13 for its own change targets: it MUST label those claims **assertion, not graph fact**, and it MUST carry the reduced-grounding disclosure the council reads (FR-019, D46-4) — which matters *doubly* because the council reviewing this plan is **itself one of the graph's consumers**, checking receipts against a graph that does not yet model the change under review.
>
> Decisions already ratified in `docs/90` and the M0 contracts appear under **Constraints & Assumptions** as givens citing their D-row (D46 spec-hygiene rule), not open choices.

## Clarifications

### Session 2026-07-13

- Q: Position 1 (retire I-13 "where feasible") — how far must the graph model the pipeline's own artifact types before the labeled fallback takes over? → A: **Plumbing edges.** Emit `.sh`/`.yml`/`.md` nodes + exactly **three** cross-file edge kinds — hook registration (`extension.yml` → command), install copy (`install.sh` cp), script→script call; the labeled-assertion fallback stays (labeled) for everything else. Broad semantic inference of *all* cross-file relations is out of scope. *(Applied to FR-002, FR-004, US1, Out of Scope.)*
- Q: Position 2 ("freshness as a property, not a ritual") — context layer only, or also fix graphify's incremental extractor? → A: **Both.** In scope: the mechanical staleness **check** + regenerate-don't-rewrite discipline (context layer) **AND** the trustworthy-incremental extractor **fix** (prune `build_merge`'s stale survivors #1361/#1344; correct `detect_incremental` so a partial change stays partial). Wholesale re-architecture of the extraction pipeline stays out of scope. *(Applied to FR-005, FR-007, FR-008, US2, Out of Scope.)*
- Q: Position 4 ("what bounds a member's 38-call loop") — hard enforced ceiling, or demand-reduction only? → A: **Hard ceiling, observable.** FR-011 imposes a **hard, enforced** cap/budget on graph-query **count** (not only per-call output, which `--budget` already caps), and the count + whether the bound was hit is trace-visible (FR-012). Demand-reduction via the receipts tier (US3) is complementary, not a substitute. *(Applied to FR-011, SC-006, US4.)*
- Q: When the freshness check (FR-005) finds a stale context product, what happens at the consuming phase? → A: **Hard-warn + regenerate** — the check loudly surfaces staleness and routes to regeneration (the D58/S14 categorization-SHA hard-warn pattern), **not** a new hard-block gate. *(Applied to FR-005, SC-003, Edge Cases.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A pipeline-plumbing feature grounds its blast-radius and `[P]` in the graph, not in a disjointness guess (Priority: P1)

An engineer plans a feature that edits shell scripts and a YAML manifest — the shape of nearly every SpecSeyal feature so far (`002`/`003`/`004`). Today the graph is blind to those files, so `graphify explain`/`path` return "No node matching" for `.sh`/`.yml` and treat `.md` prompt/template files as opaque (002 R1-S22 → I-13); `[P]` parallel markers fall back to **file-disjointness** for the whole DAG, and every blast-radius claim is labeled "engineer assertion, not graph fact." With this feature, the graph **models the pipeline's own artifact types and the edges that carry plumbing blast-radius** — hook registrations, install copies, script-to-script calls — so the plan's collision/parallelism decisions rest on real edges. Where the extractor still cannot model a relationship, the labeled-assertion fallback remains, used **as the exception and labeled as such**, never as the silent default.

**Why this priority**: This is the headline **quality** position. The graph-blindness has degraded grounding on every dogfood plumbing feature: at `004`, `verify-gate.sh` resolved to degree 4 and `commit.sh` to degree 3, and `path "verify-gate.sh" → "implement-parallel"` returned **no edge** even though `implement-parallel` calls `verify-gate` **every wave** — a real blast radius the graph could not see. S22 labeling was a patch; closing the coverage where feasible is the fix.

**Independent Test**: Take a feature whose files are `.sh`/`.yml`/`.md` (this feature itself qualifies). After the graph is built, `explain` resolves those files to real nodes, and the specific edges that were invisible at `004` — `verify-gate.sh` ↔ `implement-parallel` (the every-wave call), a hook registration in `extension.yml`, an `install.sh` copy — resolve to real graph edges; `[P]` for the majority of the feature's tasks is graph-derived, not disjointness-fallback.

**Acceptance Scenarios**:

1. **Given** a repo whose graph has been built, **When** a consumer runs `explain "verify-gate.sh"` or `path "verify-gate.sh" "implement-parallel"`, **Then** it returns real nodes/edges (not "No node matching" / "No path found") for the call relationship that exists.
2. **Given** a pipeline-plumbing feature's tasks, **When** its `[P]` markers and per-file blast-radius are derived, **Then** they are graph-derived for the majority of tasks, and any that still rest on the fallback are **labeled** "convention-derived / engineer assertion, not graph fact" (S22 honesty; taxonomy §1).
3. **Given** a file or edge kind the extractor still cannot model, **When** the context product describes it, **Then** the gap is stated plainly (labeled fallback), never presented as graph-grounded — coverage is honest, not claimed complete.

---

### User Story 2 - Graph freshness is a checkable property, not a full-rebuild ritual (Priority: P1)

An engineer starting a feature needs a graph that reflects the current repo. Today that means the **D59 ritual**: regenerate a fresh baseline in a separate session at ~1M subagent tokens (M3 ~1.19M / 8 agents; M4 ~994k / 6 agents), because the incremental `--update` path cannot be trusted — at M3 `detect_incremental` saw the whole corpus as changed (zero legitimate carryover) so incremental degenerated to full-regen, and `build_merge` left **86 stale duplicate nodes** via source_file path-matching drift, forcing a clean rebuild. Worse, once generated, `graphify-context.md` is trusted through plan → tasks → implement while the graph and the plan both move under it, and **nothing checks whether it is still current**. With this feature, freshness becomes a **verifiable property**: a mechanical check reports whether a context product is stale relative to the working tree it grounds, a stale product is **regenerated, not hand-edited** ("regenerate, don't rewrite"), and an incremental refresh keeps the graph current after a bounded change without the full-corpus regeneration.

**Why this priority**: This is the headline **cost + quality** position. The staleness has been flagged **twice** on live features and nearly caused a real defect: at `002` the council (opinion E) found `graphify-context.md` predated the `contracts/` it should have grounded by six minutes (mtimes 16:54 vs 17:00), carried a wrong shared/mutable list, and "nothing regenerates it" — the false manifest would have let `/speckit-tasks` **omit a real seam edit** (became T019 / R1-S03); at `003` analyze it carried stale "two extensions" / "degree 15" claims and had to be "regenerated, not rewritten." A ritual that costs ~1M tokens per feature and a context file that silently goes stale are both symptoms of freshness being treated as an event instead of a property.

**Independent Test**: (a) Point the staleness check at a `graphify-context.md` that predates changes to the plan it grounds → it reports stale (the `002` mtime case is caught, not silently consumed). (b) Change a bounded subset of files and run the incremental refresh → the resulting graph is equivalent to a full regen for that scope (all new nodes present, all superseded nodes pruned — **zero stale survivors**) at materially lower cost than the full-corpus ritual.

**Acceptance Scenarios**:

1. **Given** a `graphify-context.md` and a working tree that has changed since it was generated, **When** the freshness check runs, **Then** it reports the product stale **before** any consumer trusts it — freshness is a checked property, not an assumption.
2. **Given** a stale context product, **When** the pipeline refreshes it, **Then** it is **regenerated** from the graph, never hand-edited into partial correctness (the "regenerate, don't rewrite" ethos; avoids the `002`/`003` stale-claim drift).
3. **Given** only part of the repo has changed, **When** the incremental refresh runs, **Then** the result matches a full regen for the changed scope (new nodes added, **all** superseded nodes pruned — no 86-stale-node drift) and costs materially less than the ~1M-token full-corpus regeneration.
4. **Given** an incremental refresh completes, **When** its output is compared to a from-scratch full regen of the same repo state, **Then** they are equivalent (no missed new nodes, no stale survivors) — the incremental path is trustworthy enough to replace the ritual for the common case.

---

### User Story 3 - Each consumer reads the slice it needs — one graph, several diets (Priority: P2)

The graph serves consumers with genuinely different needs, but today it serves them **one fixed-shape `graphify-context.md`**. The council member and deck-prep want the **concept/rationale "receipts" layer** (requirements, decisions, contracts — the nodes a member queries to check a claim); the categorizer wants **per-file `type` signals** (to derive `type` per taxonomy §1, with the path-convention fallback where a file is uncovered); plan/tasks/implement want **blast-radius + shared/mutable + `[P]`**. With this feature, the single graph produces **distinct, token-bounded context products** — one graph, several diets — so no consumer is served, or pays for, another's slice.

**Why this priority**: **Quality + cost**, with direct telemetry: D62 showed that enriching the deck with the graph/spec sections members actually pulled cut per-member graph queries **3/5 → 1/5** and stage-1 spend **−25.1%** (988,961 vs 1,319,818 tok). That was one consumer (deck-prep) getting a better-targeted slice by hand; making tiered products first-class generalizes the win across consumers. P2 (not P1) because it compounds US1/US2 rather than standing alone — a better-targeted product is most valuable once the graph it slices is both broader (US1) and fresh (US2).

**Independent Test**: For a given feature, the three consumer classes each read a product carrying their slice — plan/tasks/implement get blast-radius; council/deck-prep get concept/rationale receipts; the categorizer gets per-file `type` signals — and the council member's secondary-source pulls drop relative to the one-diet baseline (extending D62's graph 3/5 → 1/5).

**Acceptance Scenarios**:

1. **Given** the same underlying graph, **When** the three consumer classes request context, **Then** each receives a product carrying only its slice (blast-radius; concept/rationale receipts; per-file `type` signals) — not a single fixed file every consumer over-reads.
2. **Given** the council member reviews a plan, **When** it consumes its receipts-tier product, **Then** its on-demand graph pulls drop relative to the one-diet baseline (the D62 direction), because the receipts it needs are already in its diet.
3. **Given** any tiered product, **When** it is produced, **Then** it stays token-bounded (context hygiene, principle 2) — a targeted diet, not the whole graph.

---

### User Story 4 - A council member's graph-query loop is bounded and visible (Priority: P2)

When a council member reviews a plan, it queries the live graph on demand to check the deck's receipts (D10). Today that loop is **unbounded**: at the first live council (`002`) each member ran **25–38 graphify tool-call turns**, and because every turn churns `cache_creation`, the transcript spend ran **~3.4×** the Agent-return aggregate — one round cost **5.25M billable tokens**. `--budget` caps each call's **output**, but nothing caps the **number of calls**. With this feature, a member's query loop is bounded by a **hard, enforced ceiling** (a cap or budget on query count), and the number of queries a member ran — and whether it hit the bound — is **visible in the round telemetry**.

**Why this priority**: **Cost** — attacking the multiplier at its source. D56's lazy-context tier (−46% total) and D62's enriched deck (−25% demand) both reduced spend around the edges, but neither bounded the per-member query loop that *drives* the 3.4× cache-creation multiplier; a bound on call count is the lever aimed straight at it. P2 because it is a guardrail on an already-tiered ceremony (D56), not a precondition for US1/US2.

**Independent Test**: At a `standard`-tier council round, each member's graph-query count is bounded by the enforced ceiling and is recoverable from telemetry; with the bound in force, the round's cache-creation-driven spend is lower than an equivalent unbounded loop at the same tier.

**Acceptance Scenarios**:

1. **Given** a council member reviewing a plan, **When** it queries the graph on demand, **Then** its query loop is bounded by the enforced ceiling (a cap or budget on **query count**, not only per-call output) — the 25–38-call unbounded loop cannot recur.
2. **Given** a completed council round, **When** its telemetry is read, **Then** the number of graph queries each member ran (and whether it hit the bound) is recoverable (extending the D56 read-rate / D62 secondary-source-pull telemetry).
3. **Given** the bound is in force, **When** round spend is compared to an unbounded loop at the same tier, **Then** the cache-creation-driven multiplier is reduced — the bound changes cost, not who signs (`gates.council.mode`) and not the tier (D56).

---

### Edge Cases

- **A file/edge kind the extractor still cannot model.** Coverage is "where feasible" — some relationships will remain graph-invisible. The context product MUST label these as fallback (assertion, not graph fact), never omit or over-claim them (US1 AS3).
- **The graph itself is missing or unbuilt.** The context skill already STOPs and tells the user to run `/graphify` rather than fabricate context (current SKILL.md step 2) — this behavior MUST be preserved (no fabricated context ever).
- **An incremental refresh disagrees with a full regen.** If the trustworthy-incremental invariant cannot be met for a change set, the system MUST fall back to a full regeneration rather than ship an inequivalent (stale-survivor) graph — freshness honesty over cost (the `002`/`003` "stale receipts masquerade as ground truth" ethos, D59).
- **A tiered product is requested for a consumer whose slice is empty** (e.g., a feature with no concept/rationale relevance). The product is explicitly empty ("none found"), never fabricated — mirrors the current shared/mutable "none found" rule.
- **This feature's own plan grounding.** `005`'s change targets are the uncovered `.sh`/`.yml`/`.md`/`.py` themselves; the plan MUST disclose reduced grounding and label its own blast-radius as assertion (Blast-radius honesty, doubly).
- **A consumer reads a stale product before the freshness check runs.** The check MUST be positioned so a consumer cannot silently trust a stale product (the `002` failure mode) — staleness is caught before consumption, not after.

## Requirements *(mandatory)*

### Functional Requirements

**Group A — Coverage of the pipeline's own artifact types (Position 1; retire the I-13 fallback where feasible)**

- **FR-001**: The graph MUST emit nodes for the artifact types the pipeline's own features are built from — shell scripts (`.sh`), YAML manifests (`.yml`), and Markdown prompt/template/skill files (`.md`) — so a feature touching those files resolves them as graph nodes. *(Today `explain`/`path` return "No node matching" for `.sh`/`.yml` and treat `.md` templates as opaque — 002 R1-S22 / I-13.)*
- **FR-002**: The graph MUST emit the cross-file edges that carry blast radius for pipeline-plumbing work — **specifically these three edge kinds** (Clarification 2026-07-13): a **hook registration** (an `extension.yml` entry → the command/skill it names), an **install copy** (`install.sh` copying a source tree into `.specify/`), and a **script-to-script invocation** (one `.sh` calling/sourcing another). Broader semantic inference of *all* cross-file relations is out of scope; the labeled fallback (FR-004) covers what these three do not. *(Today the AST layer captures only intra-file `defines`; "shell has no import graph," so `path verify-gate.sh → implement-parallel` finds no edge though implement-parallel calls verify-gate every wave — 004 telemetry.)*
- **FR-003**: For a feature whose files are now graph-covered, `[P]` parallel markers and per-file blast-radius MUST be derivable from **graph edges** rather than the file-disjointness fallback for the majority of its tasks.
- **FR-004**: The labeled-assertion fallback (I-13) MUST remain available and MUST be used — **and labeled** as "convention-derived / engineer assertion, not graph fact" — **only** for file/edge kinds the extractor still cannot model. Coverage MUST be honest: a fallback claim is never presented as graph-grounded, and the graph is never claimed to cover what it does not (taxonomy §1 honesty rule).

**Group B — Freshness as a property, not a ritual (Position 2; the "regenerate, don't rewrite" thread)**

- **FR-005**: The system MUST provide a **mechanical staleness check** reporting whether a given context product (and the graph it derives from) is current with respect to the working tree it grounds — so freshness is a verifiable property, not an assumption. When it finds a stale product it **hard-warns and routes to regeneration** — the D58/S14 categorization-SHA pattern — **not** a new hard-block gate (Clarification 2026-07-13). *(Today the product's own header says "stale after large merges" but nothing checks it; it silently grounded a plan it predated — 002 council E.md.)*
- **FR-006**: When a context product is stale, the pipeline MUST **regenerate** it from the graph, never hand-edit it into partial correctness — the "regenerate, don't rewrite" ethos — so a corrected product cannot carry a stale claim (the near-miss seam omission at `002`/R1-S03; the stale "two extensions"/"degree 15" at `003` analyze).
- **FR-007**: The system MUST provide an **incremental graph refresh** whose result is **equivalent to a full regeneration for the changed scope** — every new node/edge added, **every superseded node pruned (zero stale survivors)** — so keeping the graph current after a bounded change does not require the full-corpus, ~1M-token regeneration ritual (D59). The two named extractor drifts are **in scope to fix** (Clarification 2026-07-13): prune `build_merge`'s stale survivors (#1361/#1344) and correct `detect_incremental` so a partial change stays a partial refresh instead of degenerating to full-regen. *(Today `--update` degenerated to full-regen at M3 and left 86 stale duplicate nodes via build_merge path-matching drift.)*
- **FR-008**: If the trustworthy-incremental invariant (FR-007) cannot be met for a given change set, the system MUST **fall back to a full regeneration** rather than ship an inequivalent graph — freshness honesty over cost (D59: "stale receipts masquerade as ground truth").

**Group C — Tiered context products, one graph several diets (Position 3)**

- **FR-009**: The single graph MUST be able to produce **distinct context products for distinct consumers** rather than one fixed-shape file — at minimum: (a) a **blast-radius / shared-mutable / `[P]`** product for plan/tasks/implement (today's `graphify-context.md`); (b) a **concept/rationale "receipts"** product for the council member and deck-prep (D62); (c) a **per-file `type`-signal** product for the categorizer (taxonomy §1, path-convention fallback where uncovered).
- **FR-010**: Each context product MUST be **token-bounded** and carry only the slice its consumer needs (context hygiene — principles 1/2), so no consumer is served, or pays for, another's diet.

**Group D — Query-cost discipline (Position 4)**

- **FR-011**: A council member's on-demand graph-query loop MUST be bounded by a **hard, enforced discipline** — a cap or budget on the **number of queries** (not only per-call output, which `--budget` already caps) — so the per-member 25–38-call loop that drove the 3.4× cache-creation multiplier (002 = 5.25M tok/round) cannot recur unbounded. The bound is a **real ceiling, enforced**, not merely a target (Clarification 2026-07-13); demand-reduction via the receipts tier (FR-009) is **complementary, not a substitute**.
- **FR-012**: The query bound MUST be **observable, and its exhaustion MUST never be silent** (D74). The number of graph queries a member ran, and whether it hit the bound, MUST be recoverable from the round telemetry (extending the D56 per-member read-rate and D62 secondary-source-pull telemetry); **and when a consumer exhausts its ceiling, that degradation MUST be disclosed in the consumer's own output** — a council member's opinion carries the reduced-grounding disclosure (the D10 / FR-019 reduced-grounding lineage), so the chairman can **weight a ceiling-limited opinion** rather than trust it as fully grounded.

**Group E — Non-regression across live consumers (cross-cutting)**

- **FR-013**: The six live consumers of the graph and `graphify-context.md` — `/speckit-plan`, `/speckit-tasks-graph`, `/speckit-implement-parallel`, the council member (D10), the categorizer (taxonomy §1), and deck-prep (D62) — MUST continue to function: either the current context product remains available unchanged, or each consumer is updated in lockstep. This cost/quality improvement MUST be **non-breaking** on the running pipeline, and non-regression MUST have **teeth**: **each of the six consumers gets a NAMED, committed regression fixture** (D74 — the S04 lesson: a named guarantee without a committed test is prose).
- **FR-014**: The change MUST honor the cross-extension seam convention (D57 / I-14): any coupling to a consumer extension attaches at a **hook point** or lives in the **owning extension's source** and is reinstall-survival-tested — never a source edit to another extension's installer-overwritten file.

### Key Entities

- **The knowledge graph** (`graphify-out/graph.json`) — nodes/edges over the repo (today typed code + document + concept + rationale). The live working copy is gitignored (D45); a per-feature baseline snapshot is committed (`graph-baseline.json`, D59). This feature widens what it *covers* (Group A) and how it is *maintained* (Group B) — not the D45/D59 commit conventions.
- **Context product(s)** — the consumer-facing slice(s) derived from the graph. Today a single `graphify-context.md`; this feature makes it **tiered** (Group C) — one graph, several diets.
- **Freshness state** — whether a context product / graph is current with respect to the working tree it grounds. New: a **mechanical check** (FR-005) makes this observable rather than assumed.
- **Query bound** — the hard, enforced ceiling (cap or budget) bounding a consumer's graph-query loop, chiefly the council member's (FR-011), and its telemetry (FR-012).
- **Consumers** — the six live extensions/roles above (FR-013). Their continued function is the non-regression contract.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(coverage)*: For a pipeline-plumbing feature (files are `.sh`/`.yml`/`.md`), `[P]` markers and per-file blast-radius are **graph-derived for the majority of its tasks** — not file-disjointness fallback; specifically, the edges invisible at `004` (`verify-gate.sh` ↔ `implement-parallel` via the every-wave call; a hook registration; an install copy) resolve to real graph edges.
- **SC-002** *(honesty)*: **Zero** unlabeled fallback claims — every blast-radius/`[P]` claim still resting on the fallback is labeled "assertion, not graph fact" (S22), and the graph is nowhere claimed to cover what it does not.
- **SC-003** *(freshness check)*: A context product that predates the plan it grounds (the `002` mtime case) is **flagged stale by the mechanical check and routed to regeneration before a consumer trusts it** — hard-warn, not silently consumed and not a new hard-block (the D58/S14 pattern).
- **SC-004** *(incremental equivalence + cost)*: After a bounded change set, an incremental refresh yields a graph **equivalent to a full regen** (all new nodes present, **zero stale survivors**) at **materially lower cost** than the ~1M-token full-corpus regeneration — partial change → partial cost.
- **SC-005** *(tiered diets)*: Each of the three consumer classes reads a product carrying its slice, and the council member's on-demand graph pulls **drop relative to the one-diet baseline** (extending D62's 3/5 → 1/5 direction).
- **SC-006** *(query-cost)*: At `005`'s own `standard`-tier council round, each member's graph-query count is **bounded by the enforced ceiling (FR-011) and visible in telemetry**, and the round's cache-creation-driven spend is **lower than an equivalent unbounded loop at the same tier** — tier and signer unchanged.
- **SC-007** *(non-regression / dogfood)*: The pipeline runs `005` end-to-end (spec → … → implement → complete → testing) with **all six live consumers functioning and no regression** — the feature dogfoods the very layer it improves (D73).
- **SC-008** *(ceiling disclosure — D74)*: When a council member exhausts its query ceiling, its opinion **carries an explicit reduced-grounding disclosure** (D10 / FR-019 lineage) **and** its trace records the ceiling-hit (FR-012) — a ceiling-limited opinion is never presented to the chairman as fully grounded.
- **SC-009** *(non-regression teeth — D74)*: Each of the six live consumers (plan / tasks-graph / implement-parallel / council-member / categorizer / deck-prep) has a **committed, named regression fixture** that passes on `005`'s pipeline pass — non-regression is a green test per consumer, not a prose assurance (the S04 lesson).

## Constraints & Assumptions

*Every entry cites a D-row (D46 spec-hygiene rule); a claim that cannot is a plan-level design choice, not a spec given.*

- **α-polish framing (D73).** `005` is leverage on the working CLI pipeline, not new pipeline function; size **M**; first of the `005`→`006`→`007` trio, each run through the full pipeline at `standard` tier. Checkpoint α is already reached (M4).
- **Severability, not a split (D74).** The four positions are ratified *as taken*, but the plan MUST present them as **four independently shippable concerns** (the `004` two-concern precedent scaled to four) with an **explicit descope order + rationale**, council-reviewable — so if the council or implement finds the payload heavy, one arm **detaches into a follow-up feature without unwinding the rest**. Splitting is made *cheap*, never done *speculatively*; **no arm descopes silently** — any descope is a triage disposition or a gate note.
- **Autonomy posture (D9 / D33 / D56 / D61 / D73).** `profile.yaml`: `council_tier: standard`, both gates `human`, `full_auto: false`. The `standard` ceremony (8 sessions, lazy context, consolidated peer) is the measured default since D61; `human` gates are the D33 safest posture. *(profile.yaml is authored at `/speckit-plan`, per the `004` precedent — these are its ratified values.)*
- **Consumers are live (D10 / D62 / taxonomy §1 / extensions.yml).** The graph and `graphify-context.md` are read by six live consumers; blast radius spans live extensions; non-breaking is required (FR-013).
- **Blast-radius honesty, DOUBLY (S22 / I-13 / D10 / D46-4).** `005`'s change targets are the uncovered `.sh`/`.yml`/`.md`/`.py`; the plan MUST label its own blast-radius as assertion, not graph fact, and carry the reduced-grounding disclosure (FR-019) the council reads — the council being itself a consumer of the graph under review.
- **Graph home & seam discipline (D26 / D31 / D57 / I-14).** graphify lives in `extensions/graphify/`; the `speckit-graphify-context` skill installs to `.claude/skills/` from `extensions/graphify/skills/` source and is wired as the `before_plan`/`before_tasks`/`before_implement` hooks. Cross-extension coupling attaches at a hook point or in the owning extension's source, reinstall-survival-tested (FR-014).
- **Working-graph conventions unchanged (D45 / D59).** A cheaper incremental path does NOT repeal D45's "never commit the working graph"; the live `graphify-out/` stays gitignored and only the per-feature `graph-baseline.json` snapshot is committed (D59). Freshness-as-a-property is about *maintaining* the working graph and *checking* the products, not about committing the graph.
- **Model & billing (D18 / D28 / D59).** Build agents are Sonnet; the main thread is Opus (xhigh). Semantic extraction is a subagent pipeline (D59) run on subscription (D28) — `ANTHROPIC_API_KEY` stays unset.
- **Tier mechanics untouched (D56).** Query-cost discipline (Group D) bounds a member's query *loop*; it does not change the council tier, the member count, the model map, or who signs (`gates.council.mode` / `full_auto`).
- **Artifacts of record unaffected (D15 / principle 1).** This feature changes what the graph *sees* and how context is *served and bounded* — not what the pipeline's artifacts of record are.

## Out of Scope

- **Universal file-type coverage.** Coverage targets the pipeline's own artifact types (`.sh`/`.yml`/`.md`) and the edge kinds that carry plumbing blast-radius (FR-002) — not language-server-grade extraction of every file type. The labeled fallback (I-13) stays for what remains unmodeled (FR-004).
- **Wholesale re-architecture of the semantic-extraction pipeline.** The two named incremental drifts (`build_merge` stale survivors, `detect_incremental` degeneration) **are in scope to fix** (FR-007/008, Clarification 2026-07-13); the ~1M-token full regen stays available as the from-scratch path. What stays out is *replacing extraction wholesale* — the win is not *needing* the full regen for a partial change, not rebuilding the extractor.
- **Graph-scored model assignment** (Q6) — deferred to observability data (D18), unrelated to this feature.
- **Council tier / member-count changes** (D56) and **deck rendering** (`006`, D73) — out of `005`.

## Dependencies

- **A built graph** (`/graphify`) for the repo — the context skill already refuses to fabricate context when the graph is absent (current SKILL.md step 2); that behavior is preserved.
- **The live git, workforce, and testing extensions** — `005` runs the full pipeline (branch → plan → council → tasks → analyze → categorize → agents → implement → complete → testing), so the M2–M4 machinery must be installed and green (it is, on `main`).
- **The D62-enriched deck-prep template and the D56 tier mechanics** — the query-cost and tiered-product positions extend, and must remain compatible with, the council ceremony as shipped.
