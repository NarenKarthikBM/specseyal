# Implementation Plan: Unified Graph Context Management (graphify-context)

**Branch**: `005-graphify-context` | **Date**: 2026-07-13 | **Spec**: [spec.md](./spec.md) (APPROVED, D74 binding)

**Input**: Feature specification from `specs/005-graphify-context/spec.md`

**Grounding**: [graphify-context.md](./graphify-context.md), generated from the fresh D59 step-0 baseline ([graph-baseline.json](./graph-baseline.json), **1611 nodes / 2674 edges / 141 communities**; the before-picture measured in [graph-baseline-measure.md](./graph-baseline-measure.md)). **Read the graphify-context.md caveat before trusting any degree number here** — this feature's own change targets (`.sh`/`.yml` files, the upstream `graphifyy` `.py`) are exactly what the graph cannot yet see (S22/I-13), so every code-plumbing blast-radius claim below is **engineer assertion re-derived by reading source, not graph fact**. The concept/rationale layer (the spec, D-rows, contracts) grounds well; the plumbing layer does not. This is disclosed *doubly* (D74): the council that reviews this plan is itself a graph consumer.

## Summary

`005` makes the shared graph-context layer **cheaper and higher-signal** without touching upstream `graphifyy` (D75 — it stays an upstream pip dependency, archivable per D29). All work is a **specseyal-owned augmentation at the extension seam** (D57/I-14, reinstall-survival-tested), landing in `extensions/graphify/` and `extensions/council/`. It ships as **four independently-shippable, independently-reviewable concerns** (D74-2 severability) with an explicit detach order:

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

**Performance Goals**: an incremental refresh after a bounded change set costs **materially less than the ~753k-token / ~11-min / 5-session full ritual** measured at step-0 (partial change → partial cost, FR-007/SC-004); the freshness check is sub-second and mechanical (FR-005).

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

### Arm 1 — Coverage of the pipeline's own artifact types (FR-001–004)

**Home:** `extensions/graphify/` (a new mechanical post-extraction augmentation pass, e.g. `augment.sh` + a small Python helper calling no upstream-modifying code).

**Shape:** after the upstream extraction produces the graph, the pass walks the repo's `.sh`/`.yml`/`.md` files and **emits nodes + exactly three cross-file edge kinds** (clarify-bounded, not broad-semantic):
1. **hook registration** — an `extension.yml` `hooks.*` entry → the command/skill node it names;
2. **install copy** — an `install.sh` `cp`/`rm -rf`+copy of a source tree → the installed target;
3. **script→script** — a `.sh` sourcing/exec'ing another (`. ./x.sh`, `x.sh`, `"$DIR/x.sh"`).
It merges these into `graph.json` (or the extraction JSON pre-build) so `explain`/`path` resolve them. Where a relationship can't be modeled, it emits the **labeled-assertion fallback**, never a silent gap (FR-004, S22).

**Contract surface:** `explain "verify-gate.sh"` gains the `implement-parallel`/`before_implement` caller edges; `path "verify-gate.sh" "implement-parallel"` returns a path (the SC-001 exit test — today it's "No path found", verified live).

**Fixture:** a committed golden — a fixture repo slice with a known `.sh`/`.yml` topology → the pass emits the expected nodes+edges byte-deterministically.

**S22:** the pass's own `.sh`/`.py` are graph-invisible until the pass runs on the repo itself; the plan claims its blast radius by source-reading, labeled assertion.

### Arm 2 — Freshness as a property, not a ritual (FR-005–008)

**Home:** `extensions/graphify/` (a `freshness.sh` staleness check + an incremental-refresh wrapper around the upstream `build_merge`).

**Shape:**
- **Staleness check (FR-005/006):** mechanically compares the graph's manifest/hashes against the current working tree; a stale product **hard-warns and routes to regeneration** (the D58/S14 categorization-SHA pattern — **not** a new hard-block gate, per clarify). No state file (D32) — freshness is derived.
- **Incremental refresh (FR-007/008):** wraps the upstream merge and carries **the stale-survivor guard proven by hand at step-0** as a committed check — after a merge, assert no node attributed to a changed file survives absent from the fresh extraction (step-0 caught **0**; M3 caught **86**). On survivors > 0, prune-or-rebuild rather than ship a contaminated graph (D59 "fresh, non-stale baseline"). Equivalence to a full regen for the changed scope is the SC-004 exit test.

**Contract surface:** `freshness.sh` exit code + report (fresh | stale→regenerate); the refresh emits the survivor count (the step-0 measurement, now mechanical).

**Fixture:** a committed pair — (a) a graph + a mutated worktree → check reports stale; (b) a base graph + a changed-file extraction → refresh yields a graph equivalent to a full regen, **0 survivors**.

**S22:** wraps upstream `build_merge`/`detect_incremental` (out-of-repo, graph-invisible, D75) — the wrapper's own reach is asserted by source-reading.

### Arm 3 — Tiered context products, one graph several diets (FR-009/010)

**Home:** the `speckit-graphify-context` skill (`extensions/graphify/skills/…`, source-owned).

**Shape — packaging DECIDED (D74-2 asked the plan to set it):** **separate token-bounded products from one generator.** The single skill run produces:
- `graphify-context.md` — the **blast-radius / shared-mutable / `[P]`** diet for plan/tasks/implement (**unchanged shape → FR-013 non-regression for those three consumers**);
- a **receipts** diet (concept/rationale slice) for the council member + deck-prep;
- a **type-signal** diet (per-file `type` signals + path-convention fallback) for the categorizer.

**Why separate products, not one sectioned file:** it makes **FR-010 structural, not aspirational** — a consumer that opens only its product literally cannot pay for another's tokens; a sectioned file leaves "read only your section" as unenforced prose (the D53 prose-vs-mechanism lesson). One generator keeps them coherent (one graph, one pass).

**Contract surface:** the three product paths + their token bounds; each carries only its slice.

**Fixture:** a committed golden per product (three of the six consumer fixtures land here).

**S22:** grounded — the skill and its consumers are `.md`/document nodes the graph sees.

### Arm 4 — Query-cost discipline: the enforced ceiling (FR-011/012)

**Home:** `extensions/council/` (the member prompt + the orchestrator's member-dispatch).

**Shape:** a **hard, enforced cap** on a member's graph-query **count** (a declared `N`, resolved from `council-config.yml`, tier-aware; `--budget` already caps per-call *output*, this caps call *count*). The count and whether the ceiling was hit are **recorded in the member's trace** (FR-012) **and disclosed in the member's own opinion** (D74-3 — extending the existing `reduced grounding note (FR-019)` the member-prompt already references, degree-16 confirmed live), so the chairman can **weight a ceiling-limited opinion** rather than trust it as fully grounded (SC-008).

**Contract surface:** `council-config.yml` `member.query_ceiling`; the trace `graph_queries` field + `ceiling_hit` flag; the opinion's reduced-grounding disclosure line.

**Fixture:** a member fixture whose reviewing loop is driven to the ceiling → the opinion carries the disclosure and the trace records the hit (the fourth consumer fixture; the remaining two — implement-parallel + tasks-graph consuming arm-3's `graphify-context.md` unchanged — are arm-3-adjacent).

**Baseline this round:** the `005` council round itself records **per-member query counts** — arm 4's **uncapped baseline**, the last round that will ever run without a ceiling (owner directive; the natural before-picture, mirroring step-0).

## Detach order (D74-2) — detachability follows fallback, not importance

**Core (never detach): arms 2 + 3 + 4.** **Detach-first: arm 1.**

**Rationale, stated verbatim as the ruling requires:** *Arm 1 detaches first NOT because it is least important — its coverage is the headline I-13 fix — but because it is the **only arm with a working fallback**. Absent arm 1, blast-radius and `[P]` on `.sh`/`.yml` degrade to the **labeled-assertion / file-disjointness** path the pipeline already uses honestly today (taxonomy §1; every feature 002–004 shipped on it). Arms 2, 3, and 4 have **no fallback**: without arm 2 the ~753k-token ritual and silent staleness persist; without arm 3 every consumer keeps over-reading one diet; without arm 4 the 25–38-call cache-churn loop stays unbounded. **Detachability follows fallback, not importance** — so if the council or implement finds the four-arm payload heavy, arm 1 (which fails *gracefully* to today's honest behavior) is the clean cut, and it re-attaches as a follow-up feature without unwinding the rest.* No arm descopes silently — any detach is a triage disposition or a gate note (D74-2).

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

- **R1 — Arm 1 is the graph's blind spot fixing itself.** The pass adds `.sh`/`.yml` edges, but its *own* correctness can't be graph-verified (I-13, live: `verify-gate.sh` degree-5-intra-file, no `→implement-parallel` path). Mitigation: deterministic golden fixtures + source-read review; the council checks receipts by reading source, not the graph (S22, disclosed doubly).
- **R2 — Separate-products packaging (arm 3) risks drift between the three diets.** Mitigation: one generator, one graph pass; a shared-provenance header; goldens per product. (Chose structural FR-010 over a sectioned file precisely to avoid "read only your section" prose.)
- **R3 — The query ceiling (arm 4) could starve a member mid-review.** Mitigation: the ceiling is tier-aware and generous relative to the *median* member (the 25–38 range is the uncapped tail); a ceiling-hit is disclosed + weightable, not a silent truncation (SC-008). This round's per-member counts calibrate `N`.
- **R4 — Upstream `graphifyy` drift.** A future `graphifyy` release could change `build_merge`'s contract under arm 2's wrapper. Mitigation: the wrapper pins to the CLI/API surface it uses and the survival fixtures catch a break; `graphifyy` is a versioned dependency (D75).
- **R5 — Self-reference at the council.** The council reviewing this plan queries a graph that cannot see the fix (S22 doubly). Mitigation: `graphify-context.md` is Exhibit-A honest; reduced grounding is disclosed per FR-019/D10; and this round's own query counts become arm-4's baseline.

## Complexity Tracking

*Constitution Check passed with no violations — no rows.*
