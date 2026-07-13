# Implementation Plan: Unified Graph Context Management (graphify-context)

**Branch**: `005-graphify-context` | **Date**: 2026-07-13 | **Spec**: [spec.md](./spec.md) (APPROVED, D74 binding)

**Input**: Feature specification from `specs/005-graphify-context/spec.md`

**Grounding**: [graphify-context.md](./graphify-context.md), generated from the fresh D59 step-0 baseline ([graph-baseline.json](./graph-baseline.json), **1611 nodes / 2674 edges / 141 communities**; the before-picture measured in [graph-baseline-measure.md](./graph-baseline-measure.md)). **Read the graphify-context.md caveat before trusting any degree number here** — this feature's own change targets (`.sh`/`.yml` files, the upstream `graphifyy` `.py`) are exactly what the graph cannot yet see (S22/I-13), so every code-plumbing blast-radius claim below is **engineer assertion re-derived by reading source, not graph fact**. The concept/rationale layer (the spec, D-rows, contracts) grounds well; the plumbing layer does not. This is disclosed *doubly* (D74): the council that reviews this plan is itself a graph consumer.

## Summary

`005` makes the shared graph-context layer **cheaper and higher-signal** without touching upstream `graphifyy` (D75 — it stays an upstream pip dependency, archivable per D29). All work is a **specseyal-owned augmentation at the extension seam** (D57/I-14, reinstall-survival-tested), landing in `extensions/graphify/` and `extensions/council/`. It ships as **four independently-shippable, independently-reviewable concerns** (D74-2 severability) with an explicit detach order — a **1-vs-3 asymmetry (S15)**: only arm 1 has a fallback and is cleanly detachable; arms 2–4 are core (no fallback), so they ship together or the feature's value doesn't land (see *Detach order*):

- **Arm 1 — Coverage** (`.sh`/`.yml`/`.md` nodes + 3 edge kinds): a mechanical post-extraction pass that augments the graph after the upstream extraction. *Detach-first candidate — it is the only arm with a working fallback.*
- **Arm 2 — Freshness as a property**: a mechanical staleness check (hard-warn + regenerate) + an incremental-refresh wrapper carrying the stale-survivor guard proven by hand at step-0.
- **Arm 3 — Tiered products**: one generator emitting ≥3 token-bounded per-consumer diets.
- **Arm 4 — Query ceiling**: a hard, enforced, observable cap on a council member's graph-query count, with ceiling-hit disclosed in the member's own opinion.

## Technical Context

**Language/Version**: POSIX `sh` (the augmentation pass, freshness check, incremental wrapper — the `commit.sh`/`verify-gate.sh` idiom); Python 3 only where it must call the installed `graphifyy` API (`build_merge`/`detect_incremental` via `graphify-out/.graphify_python`, never editing the package); Markdown (the tiered products, the member-prompt).

**Primary Dependencies**: the **upstream `graphifyy` pip package** (unmodified — D75) via its CLI (`graphify explain`/`path`/`query`) and its Python entry points; the live `git`, `council`, `workforce`, `testing` extensions (the six consumers must keep working).

**Storage**: the graph (`graphify-out/graph.json`, gitignored working copy D45; committed per-feature `graph-baseline.json` snapshot D59); the tiered context products (disposable grounding files, regenerable — **not** phase artifacts-of-record); traces (`traces.jsonl`, append-only, D35).

**Testing**: the extension test harnesses (`extensions/graphify/test/`, `extensions/council/test/`, model = `extensions/git/test/run.sh`) — reinstall-survival + the **six named consumer regression fixtures** (FR-013/SC-009); the augmentation pass is deterministic so its fixtures are byte-checkable.

**Target Platform**: developer machines running the SDD pipeline in Claude Code (subscription auth, D28).

**Project Type**: pipeline extensions (CLI layer) — augmentation of an existing extension, not a new one.

**Performance Goals**: an incremental refresh after a bounded change set costs **materially less than the ~753k-token / ~11-min / 5-session full ritual** measured at step-0 (partial change → partial cost, FR-007/SC-004). **Numeric threshold for SC-004 (S07), derived from the step-0 measurement:** for a bounded change touching **≤ ~10% of tracked files**, the common incremental path (cheap `refresh.sh`, no full regen) MUST cost **≤ 25% of the full-ritual token budget — i.e. ≲ ~190k tokens and a single session** (vs ~753k / 5 sessions). A refresh exceeding this is a regression to investigate, not silently absorb — the SC now has a number it can go red against. The freshness check itself is sub-second and mechanical (FR-005).

**Constraints**: mechanical/no-LLM augmentation (constitution V — no `ANTHROPIC_API_KEY`); source-owned edits that survive reinstall (D57); `graphifyy` untouched (D75); non-breaking on all six live consumers (FR-013); markdown stays the artifact of record (D15).

**Scale/Scope**: size **M** (D73 α-polish); the current graph is 1611 nodes / 2674 edges; the pipeline's own corpus is overwhelmingly `.sh`/`.yml`/`.md`/`.py` — the exact types arm 1 targets.

## Constitution Check

*GATE: evaluated before Phase 0 and re-checked after design. Result: **PASS**, no violations, no Complexity Tracking rows.*

- **I. Artifacts Are the Contract** — **PASS.** Arm 3 emits ≥3 context products, but the graphify-context generator is a **`before_*` hook, not a pipeline phase**, and its outputs are **disposable grounding derivatives** (regenerable from the graph; the file header literally says "Disposable"), **not** artifacts-of-record. Principle I's "exactly one artifact out" governs *phases* (spec→plan→…), which are untouched. Arm 1/2 write the **gitignored working graph** (D45), not a phase artifact. *(This is the exact subtlety a receipts-checking council will probe — addressed head-on, not left implicit.)*
- **II. Context Hygiene** — **PASS, advanced.** Arm 3 (tiered diets) and arm 4 (query ceiling) *reduce* over-serving — each consumer gets only its slice, and a member's context intake is bounded. This is principle II cashed out, not strained.
- **III. Resumability (NON-NEGOTIABLE)** — **PASS.** The arm-2 freshness check is **artifact-inferred** (computed from the graph manifest + working tree), **no state file** (D32). Staleness is a derived property, re-checkable anywhere.
- **IV. Observability** — **PASS.** Arm 4 records per-member query counts + ceiling-hits in `traces.jsonl` (FR-012). The arm-1/2 augmentation is mechanical (no model call), so — like `commit.sh` — it writes no trace; nothing opts a *session* out of tracing.
- **V. Subscription-Only Billing (NON-NEGOTIABLE)** — **PASS.** The augmentation is deterministic parsing (no LLM); `graphifyy`'s own semantic extraction, when a regen is needed, runs on subscription subagents exactly as today (D28). No key.
- **Model Policy (D18)** — **PASS.** No new model role. Arm 1/2 = mechanical scripts; arm 3 = the existing generator; arm 4 = a member-prompt + orchestrator change (members stay Sonnet, chairman Opus).
- **Autonomy & Gates (D9)** — **PASS.** `005` does not touch the gate structure. `profile.yaml`: `council_tier: standard`, both gates `human`, `full_auto: false`.

## The Four Severable Arms (each an independently-reviewable concern)

> Per D74-2 the council reviews these as **four distinct concerns**. Each names its home, its shape, its contract surface, its fixture, and its S22 honesty. Any one can detach into a follow-up without unwinding the others.
>
> **Two orderings, kept distinct (S14).** *Build/execution* order within a refresh cycle is **arm 1 → arm 2 → arm 3** (augment the graph → check/refresh freshness → generate the tiered products): arm-3's generator reads the *current, augmented, fresh* graph, so it presumes arms 1–2 already ran this cycle, and consumer-fixture 4 needs arm-3's product to exist to be exercisable. This is **not** the *detach* order below (severability, not sequence) — build order and detach order are separate questions, conflated at your peril.

### Arm 1 — Coverage of the pipeline's own artifact types (FR-001–004)

**Home:** `extensions/graphify/` (a new mechanical post-extraction augmentation pass, e.g. `augment.sh` + a small Python helper calling no upstream-modifying code).

**Shape:** after the upstream extraction produces the graph, the pass walks the repo's `.sh`/`.yml`/`.md` files and **emits nodes + exactly three cross-file edge kinds** (clarify-bounded, not broad-semantic):
1. **hook registration** — an `extension.yml` `hooks.*` entry → the command/skill node it names;
2. **install copy** — an `install.sh` `cp`/`rm -rf`+copy of a source tree → the installed target;
3. **script→script** — a `.sh` sourcing/exec'ing another (`. ./x.sh`, `x.sh`, `"$DIR/x.sh"`).
It merges these into `graph.json` (or the extraction JSON pre-build) so `explain`/`path` resolve them. Where a relationship can't be modeled, it emits the **labeled-assertion fallback**, never a silent gap (FR-004, S22).

**Modeled-but-wrong is a regression, not an acceptable cost (S10).** The pass is pattern-based, so a *commented-out* `source`, a *conditional* `cp`, or an indirect `"$VAR/script.sh"` call MUST NOT be minted as a confident edge presented as fact — that is strictly worse than today's honest file-disjointness fallback. Any construct the pass cannot resolve to a definite edge falls to the labeled assertion, never a guessed edge; the golden (below) exercises exactly these messy real-`.sh` shapes, not only a clean topology.

**`.md` coverage is bounded and stated honestly (S08 → D76).** The three edge kinds do **not** model a *"skill/script reads a scaffolding template"* relationship, and the canonical `plan-template.md`/`spec-template.md` have no node today — so **template-heavy plumbing stays blast-radius-invisible after arm 1 ships**, and FR-003/SC-001's "majority of tasks" reach **explicitly excludes** template-heavy features (owner ruling **D76**: exclude-and-book; clarify's *"three kinds, bounded"* stands unamended). A fourth *template-read* edge kind is **booked as an evidence-backed follow-up (I-24, the D66 seeding-bar)** — admitted only when recurring feature-gap evidence justifies it, not added mid-flight on momentum.

**Contract surface:** `explain "verify-gate.sh"` gains the `implement-parallel`/`before_implement` caller edges; `path "verify-gate.sh" "implement-parallel"` returns a path (the SC-001 exit test — today it's "No path found", verified live). **Ambiguous-match hardening (S04 — the round's strongest find, 5/5 members + live-reproduced this round):** `graphify explain` today resolves a short name to the top-scoring node **silently** even on a near-tie, while `graphify path` already warns — so a deck-cited filename can resolve to the *wrong* node with no signal. Because arm 1 grows the same-named-node surface (more `.sh`/`.yml`/`.md` nodes) and arm 4 makes each member query *precious*, this feature (a) hardens `explain` to emit `path`'s ambiguous-match warning, and (b) adopts a **qualified-path/label citation convention** for deck-prep and the member prompt so receipts name an unambiguous anchor. Attaches at the extension seam (the graphify CLI wrapper + the council templates); `graphifyy` untouched (D75).

**Fixture (three committed goldens, both branches exercised — S03/S10/S11):**
1. **Success branch:** a fixture repo slice with a known `.sh`/`.yml` topology → the pass emits the expected nodes+edges.
2. **Fallback branch (S03 — the SC-002 honesty guarantee):** a slice carrying a relationship kind *outside* the three modeled edge kinds → the pass emits the **labeled-assertion fallback** (silence is the failure mode; SC-002's "zero unlabeled fallback claims" is only proven if the fallback branch is exercised, not just the success branch).
3. **Messy-pattern branch (S10):** commented-out `source`, conditional `cp`, `"$VAR/script.sh"` indirection → the pass mints **no wrong edge**; unresolvable constructs fall to labeled assertion.

**Byte-determinism is pinned, not assumed (S11):** the golden asserts stable node/edge ordering, canonical JSON key order, and **no filesystem-iteration-order dependence** — "no LLM" (Testing) is necessary but not sufficient for byte-for-byte golden diffing, and FS-iteration order is a classic flaky-golden source (the `003`-S01 sorted-set lesson, pre-empted here).

**S22:** the pass's own `.sh`/`.py` are graph-invisible until the pass runs on the repo itself; the plan claims its blast radius by source-reading, labeled assertion.

### Arm 2 — Freshness as a property, not a ritual (FR-005–008)

**Home:** `extensions/graphify/` (a `freshness.sh` staleness check + an incremental-refresh wrapper around the upstream `build_merge`).

**Shape:**
- **Staleness check (FR-005/006):** mechanically compares the graph's manifest/hashes against the current working tree; a stale product **hard-warns and routes to regeneration** (the D58/S14 categorization-SHA pattern — **not** a new hard-block gate, per clarify). No state file (D32) — freshness is derived, and the check is **recomputed at every consumption point, never cached or reused across hook calls within a session (S20):** a consumer trusting a report computed earlier in the same session would recreate, one layer up, the exact stale-artifact-trusted-without-recheck failure this arm exists to close. The derived-property framing (D32) makes this natural; the invocation contract states it so it cannot silently regress.
- **Stale/recovery control flow — DECIDED (S02, the revision's load-bearing ruling):** "routes to regeneration" is **not** a synonym for the ~753k-token full ritual. The concrete branch table:
  - **common path (stale but incrementally-refreshable):** run the cheap `refresh.sh` incremental **always** — this is the path SC-004's "materially lower cost" binds to;
  - **survivors > 0 after refresh:** **prune** the stale survivors + **targeted re-extract of the affected scope only** (never a whole-corpus rebuild for a bounded change);
  - **full-corpus regen** fires **only** on an extractor-**version change** (arm-2 wrapper pin mismatch, R4) or an **explicit operator demand** — never as the default stale response.
- **Incremental refresh (FR-007/008):** wraps the upstream merge and carries **the stale-survivor guard proven by hand at step-0** as a committed check — after a merge, assert no node attributed to a changed file survives absent from the fresh extraction (step-0 caught **0**; M3 caught **86**). On survivors > 0, prune-or-rebuild per the branch table above rather than ship a contaminated graph (D59 "fresh, non-stale baseline"). Equivalence to a full regen for the changed scope is the SC-004 exit test.
- **Composition with arm 1 (S06 — the cross-arm invariant):** an incremental refresh **MUST re-invoke arm-1's `augment.sh` on the changed scope**. Otherwise every incremental refresh silently regresses arm-1's `.sh`/`.yml` coverage on exactly the changed files and falsifies SC-004's "equivalent to a full regen" — a gap no *per-arm* fixture can catch, since each tests its arm in isolation. Stated as an invariant, backed by the composition fixture below.
- **Check-then-use race (S19 — argued, not merely asserted):** a `freshness.sh` pass for one wave-task's `before_implement` hook could in principle be invalidated by a sibling wave-task's concurrent edit before the first reads `graphify-context.md`. This **cannot occur** under existing pipeline discipline: the shared/mutable collision rule **serializes** any tasks touching shared files into different waves (never co-scheduled), and the graph / `graphify-context.md` are shared products — so no two concurrently-running wave tasks both mutate the graph's inputs. If that argument fails to close during implement, an explicit concurrent-refresh fixture is the fallback (the round rated this its most speculative item; the argument is the primary mitigation).

**Contract surface:** `freshness.sh` exit code + report (fresh | stale→**cheap-refresh** | stale→**prune+targeted-re-extract** | stale→**full-regen**, per the S02 branch table); the refresh emits the survivor count (the step-0 measurement, now mechanical).

**Fixture (five committed cases — both branches of each guard, S01/S06/S18):**
- **(a) stale-positive:** a graph + a mutated worktree → check reports **stale**.
- **(b) stale-negative / no false alarm (S18):** a graph + an **unmutated** worktree → check reports **fresh**, no crying-wolf warning (the inverse branch of (a); a check that can only ever fire proves nothing about its quiet path).
- **(c) equivalence, 0 survivors:** a base graph + a changed-file extraction → refresh yields a graph equivalent to a full regen, **0 survivors**.
- **(d) negative-path survivor guard (S01 — precondition for arm-2 sign-off, NOT a disclosed-and-shipped gap):** a fixture that **manufactures > 0 stale survivors** (the M3 86-node incident in miniature) → asserts the guard **detects** them **and** actually performs the prune-or-rebuild recovery. Without this case the guard is exercised only on passing input — the exact "guard tested only on the branch that passes" shape the round's blocking core (S01–S03) is about.
- **(e) cross-arm composition (S06):** a changed `.sh` file + incremental refresh → the refreshed graph carries arm-1's augment edges for the changed file (coverage not silently regressed).

**S22:** wraps upstream `build_merge`/`detect_incremental` (out-of-repo, graph-invisible, D75) — the wrapper's own reach is asserted by source-reading.

### Arm 3 — Tiered context products, one graph several diets (FR-009/010)

**Home:** the `speckit-graphify-context` skill (`extensions/graphify/skills/…`, source-owned).

**Shape — packaging DECIDED (D74-2 asked the plan to set it):** **separate token-bounded products from one generator.** The single skill run produces:
- `graphify-context.md` — the **blast-radius / shared-mutable / `[P]`** diet for plan/tasks/implement (**unchanged shape → FR-013 non-regression for those three consumers**);
- a **receipts** diet (concept/rationale slice) for the council member + deck-prep;
- a **type-signal** diet (per-file `type` signals + path-convention fallback) for the categorizer.

**Why separate products, not one sectioned file:** it makes **FR-010 structural, not aspirational** — a consumer that opens only its product literally cannot pay for another's tokens; a sectioned file leaves "read only your section" as unenforced prose (the D53 prose-vs-mechanism lesson). One generator keeps them coherent (one graph, one pass).

**Contract surface:** the three product paths + their token bounds; each carries only its slice.

**Fixture:** a committed golden per product (three of the six consumer fixtures land here), **plus a cross-product coherence fixture (S13):** one generator run → all three diets carry the **same graph hash / generation-id** in a shared-provenance header, asserted by test. This makes R2's "shared-provenance header" a *checked* invariant rather than process discipline — the same prose-vs-mechanism bar the plan set when it rejected the single-sectioned-file alternative (D53); a per-product golden alone proves each diet correct *in isolation*, not *mutually coherent*.

**S22:** grounded — the skill and its consumers are `.md`/document nodes the graph sees.

### Arm 4 — Query-cost discipline: the enforced ceiling (FR-011/012)

**Home:** `extensions/council/` (the member prompt + the orchestrator's member-dispatch).

**Shape:** a **hard, enforced cap** on a member's graph-query **count** (a declared `N`, resolved from `council-config.yml`, **tier-aware**; `--budget` already caps per-call *output*, this caps call *count*).

**Tier-aware `N` — calibrated only from same-tier data (S05 → D77):** the ceiling resolves **per tier**, never from a mismatched ecosystem:
- **standard tier: `N = 15`** (D77), calibrated from *this* round's uncapped standard-tier baseline (per-member max **9**; 15 ≈ 1.7× the observed max — clears the range with headroom, tight enough to catch a genuine runaway);
- **full tier: `N` UNSET — full tier runs UNCAPPED** until its own baseline is measured. Trigger to set it: the **first full-tier round** (an M5-class L/architecture feature, per D61's tier guidance). The historical `002` eager counts (25–38) are **not** a full-tier calibration source either — they predate lazy loading + the D62 deck, a different ecosystem. **No ceiling is derived from the wrong tier's behavior** — precisely the calibration trap the council caught in this very round.

The count + whether the ceiling was hit are **recorded in the member's trace** (FR-012) **and disclosed in the member's own opinion** (D74-3). **The trace `ceiling_hit` flag is the load-bearing "never silent" guarantee, not the member's free-texted sentence (S09 → D53):** a member scrambling at its ceiling is prompt-following at its *least* reliable, so the **orchestrator mechanically appends the reduced-grounding disclosure line the instant it enforces the cap** — the member's own prose is courtesy, the mechanical flag + mechanical append are the guarantee. The chairman weights a ceiling-limited opinion rather than trust it as fully grounded (SC-008).

**Contract surface:** `council-config.yml` `member.query_ceiling`; the trace `graph_queries` field + `ceiling_hit` flag; the opinion's reduced-grounding disclosure line.

**Fixture (both branches — S18):** a member fixture whose reviewing loop is driven to the ceiling → the opinion carries the disclosure and the trace records the hit (the fourth consumer fixture); **plus the non-disclosure-default inverse (S18):** an ordinary non-ceiling round carries **no** disclosure line and `ceiling_hit: false` — the SC-008 quiet-path branch, so the disclosure cannot fire spuriously (crying-wolf coverage is coverage). The remaining two consumer fixtures — implement-parallel + tasks-graph consuming arm-3's `graphify-context.md` unchanged — are arm-3-adjacent.

**Baseline MEASURED this round (arm 4's uncapped before-picture, mirroring step-0):** the `005` standard-tier council recorded **per-member graph-query counts of A=8, B=7, C=9, D=2, E=6 — total 32, mean 6.4, range [2, 9]** (transcript ground-truth). This is the **last standard-tier round that will ever run without a ceiling**, and it directly sets `N = 15` above. The counts run **~4–5× below `002`'s 25–38 per-member loop** — standard-tier lazy context + the D62 deck already structurally suppress the loop, which is *why* `N` must be tier-scoped.

**SC-006's named measurement trigger (S07):** the incremental-vs-uncapped cost comparison SC-006 promises is booked against the **first post-arm-4 council round (`006`'s)**, measured versus this round's uncapped baseline — a concrete, owned trigger, so SC-006 cannot stay permanently deferred with no way to go red.

**Mid-implementation self-reopen guard (S17, narrowed per peer):** while `005` is mid-implementation — after arm 4 is spec'd but before its prompt/orchestrator change is wired — a `/speckit-council --reopen delta` on `005` would dispatch the **pre-ceiling** member prompt. The reopen path notes the pre-ceiling prompt status until arm 4 wires (one line). *(A future feature's round predating `005`'s completion is unavoidable and out of scope; this round is arm-4's baseline by design — only the mid-implementation `005` self-reopen case is actionable.)*

## Detach order (D74-2) — detachability follows fallback, not importance

**The severability picture is a 1-vs-3 asymmetry, and leads with it (S15):** only **arm 1** has a working fallback and is genuinely detachable; **arms 2 + 3 + 4 are core — "never detach", because none has a fallback.** "Four independently-shippable concerns" (D74-2's spec-mandated framing, kept) therefore means *one cleanly-detachable arm + three that ship together or the feature's value doesn't land*.

**Core (never detach): arms 2 + 3 + 4.** **Detach-first: arm 1.**

**Rationale, stated verbatim as the ruling requires:** *Arm 1 detaches first NOT because it is least important — its coverage is the headline I-13 fix — but because it is the **only arm with a working fallback**. Absent arm 1, blast-radius and `[P]` on `.sh`/`.yml` degrade to the **labeled-assertion / file-disjointness** path the pipeline already uses honestly today (taxonomy §1; every feature 002–004 shipped on it). Arms 2, 3, and 4 have **no fallback**: without arm 2 the ~753k-token ritual and silent staleness persist; without arm 3 every consumer keeps over-reading one diet; without arm 4 the 25–38-call cache-churn loop stays unbounded. **Detachability follows fallback, not importance** — so if the council or implement finds the four-arm payload heavy, arm 1 (which fails *gracefully* to today's honest behavior) is the clean cut, and it re-attaches as a follow-up feature without unwinding the rest.* No arm descopes silently — any detach is a triage disposition or a gate note (D74-2).

**Severability is a checked claim, not rationale-only (S12).** A **detached-configuration fixture** asserts arms **2 + 3 + 4 pass green with arm 1 absent** (the fallback story realized as a test). Without it, all the named fixtures assume every shipped arm present, leaving severability as prose — and since detach is a *live* triage option, the plan's own prose-vs-mechanism standard (the reason it chose structural FR-010 over a sectioned file, D53) applies to its own severability claim.

## Non-regression with teeth — the six named consumer fixtures (FR-013/SC-009)

One committed, named regression fixture per live consumer — non-regression is a green test, not prose (the S04 lesson):

| # | Consumer | Fixture asserts |
|---|---|---|
| 1 | `/speckit-plan` | reads `graphify-context.md` (arm-3 blast-radius diet) unchanged in shape |
| 2 | `/speckit-tasks-graph` | consumes the same diet; `[P]`/wave derivation unbroken |
| 3 | `/speckit-implement-parallel` | consumes the same diet; per-task blast-radius unbroken |
| 4 | council member | reads its receipts diet; query ceiling + disclosure fire (arm-4) |
| 5 | categorizer | reads the type-signal diet; `type` derivation + path-convention fallback intact |
| 6 | deck-prep | reads the receipts diet (the D62 enrichment source) unbroken |

## Project Structure

### Documentation (this feature)
```text
specs/005-graphify-context/
├── plan.md · research.md · data-model.md · quickstart.md · contracts/commands.md   # plan phase
├── spec.md (approved) · graphify-context.md · graph-baseline.json · graph-baseline-measure.md
└── profile.yaml (standard / both-human)
```

### Source (repository root) — all specseyal-owned, `graphifyy` untouched (D75)
```text
extensions/graphify/
├── extension/scripts/augment.sh        # arm 1 — post-extraction .sh/.yml/.md nodes + 3 edge kinds
├── extension/scripts/freshness.sh      # arm 2 — staleness check (hard-warn + regenerate)
├── extension/scripts/refresh.sh        # arm 2 — incremental wrapper + stale-survivor guard
├── skills/speckit-graphify-context/    # arm 3 — one generator → 3 separate products
└── test/                               # arm-1/2/3 goldens + consumer fixtures 1,2,3,5,6

extensions/council/
├── extension/templates/member-prompt.md   # arm 4 — query ceiling + ceiling-hit disclosure
├── extension/council-config.yml            # arm 4 — member.query_ceiling
└── test/                                    # consumer fixture 4 (ceiling + disclosure)
```

**Structure Decision:** augmentation-only at the extension seam (D75). Arms 1–3 live in `extensions/graphify/` source; arm 4 in `extensions/council/` source. Every edit is reinstall-survival-tested (D57 — the installer `rm -rf`+`cp`s these trees, so a source-only edit is the sole survivable form). `graphifyy` is never edited — arms 1/2 call its API and augment around it. Cross-extension coupling (arm 4 ↔ the graphify products) attaches at a hook/config point, never a foreign source edit (I-14).

## Risks (for the council)

- **R1 — Arm 1 is the graph's blind spot fixing itself.** The pass adds `.sh`/`.yml` edges, but its *own* correctness can't be graph-verified (I-13, live: `verify-gate.sh` degree-5-intra-file, no `→implement-parallel` path). Mitigation: deterministic golden fixtures + source-read review; the council checks receipts by reading source, not the graph (S22, disclosed doubly). **Also mitigated — the `explain` ambiguous-match footgun (S04):** hardening `explain` to warn on near-ties + the qualified-path citation convention (Arm 1 contract surface) stops a receipt resolving to the wrong node, which arm 1's larger same-name surface would otherwise worsen.
- **R2 — Separate-products packaging (arm 3) risks drift between the three diets.** Mitigation: one generator, one graph pass; a shared-provenance header; goldens per product. (Chose structural FR-010 over a sectioned file precisely to avoid "read only your section" prose.)
- **R3 — The query ceiling (arm 4) could starve a member mid-review.** Mitigation: the ceiling is tier-aware and generous relative to the *median* member (the 25–38 range is the uncapped tail); a ceiling-hit is disclosed + weightable, not a silent truncation (SC-008). This round's per-member counts calibrate `N`.
- **R4 — Upstream `graphifyy` drift.** A future `graphifyy` release could change `build_merge`'s contract under arm 2's wrapper. Mitigation (**upgraded to preventive, not reactive — S16**): a **real version pin** — the installed `graphifyy` version is **recorded in a manifest and checked** (the arm-2 wrapper asserts the pinned version before calling `build_merge`/`detect_incremental`; a mismatch triggers the **full-regen** branch of the S02 table, not a silent wrong-contract call). The survival fixtures still catch a break, but the pin **prevents** the Med–High-impact wrong-contract call rather than only detecting it afterward; `graphifyy` stays a versioned dependency (D75).
- **R5 — Self-reference at the council.** The council reviewing this plan queries a graph that cannot see the fix (S22 doubly). Mitigation: `graphify-context.md` is Exhibit-A honest; reduced grounding is disclosed per FR-019/D10; and this round's own query counts become arm-4's baseline.

## Complexity Tracking

*Constitution Check passed with no violations — no rows.*
