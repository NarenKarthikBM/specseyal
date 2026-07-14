# Defense Deck — Technical

**Feature**: `[NNN-feature-name]`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`, `graphify-receipts.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

> **Citation convention (S04).** Any repo file, script, or symbol this deck names — architecture walkthrough, dependency/graph-impact section, risk register, anywhere — MUST be a qualified path or fully-qualified label (e.g. `.specify/extensions/git/scripts/verify-gate.sh`, never a bare `verify-gate.sh`). `graphify explain`/`graphify path` resolve a short name to its single top-scoring node with **no signal on a near-tie**, so a bare filename is an ambiguous anchor the instant two nodes share it — a surface arm 1's own `.sh`/`.yml`/`.md` coverage pass only grows. A member re-querying this deck's own citation must land on the node the deck meant.

> **D62 (`003-workforce` round-1, 2026-07-10).** The first `standard`-tier ceremony measured a per-member `plan.md` read-rate of **4/5** (spec 1/5, graph 3/5): most of that round's 25 suggestions — including **both blocking defects** (S01, S02) — trace to three `plan.md` sections this template rendered too thinly, or not at all, to be trusted on their own: `## Architecture & data flow` (6 of 25 suggestions), `## Plan-time verifications & per-SC test coverage` (7 of 25 — the round's single highest-demand section), `## Project Structure` (3 of 25). §3 (new below) and the strengthened §4/§7 exist to close that gap by default, so a lazy-context member can reach an opinion from this deck alone. **After-metric:** the per-member `plan.md` read-rate at the *next* council run — target: a majority of the bench (≤2/5) no longer needs to open `plan.md`.

> **Concept/rationale enrichment — the receipts diet (D62).** The same graphify generator run that writes `graphify-context.md` also emits `graphify-receipts.md` (arm 3; deck-prep is consumer 6 of `plan.md`'s six named non-regression fixtures) — the concept/rationale/contracts diet for deck-prep and the council member. Mine its `## Concept / rationale receipts` (graph-grounded concept/rationale nodes — e.g. requirements, D-rows — each carrying its own citation) and `## Contracts cited` (the `contracts/` files this feature references, one gloss each) wherever this deck states a rationale or names a contract, rather than restating `spec.md`/`plan.md` prose unverified. This diet **is** the D62 enrichment source for that grounding specifically — it complements `graphify-context.md`'s blast-radius/shared-file grounding in §4 below, it does not replace it. If `graphify-receipts.md` is absent from this feature's directory, say so plainly rather than silently omitting the grounding it would have supplied — the same honest-fallback convention §4 already applies to a missing `graph.json`.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

*Guidance: restate the problem in 1–2 short paragraphs, pulled from `spec.md` (the "why", the User Scenarios, the priority-1 story). No solutioning here — this section grounds the reviewer in what's being solved before they see the answer.*

[PLACEHOLDER — problem restatement from spec.md]

---

## 2. Chosen Approach & Rejected Alternatives

*Guidance: state the approach `plan.md` actually chose, then list every alternative it seriously considered and rejected, each with the concrete reason it lost — not a strawman. This is the crux the council scrutinizes hardest: a plan with no rejected alternatives reads as unexamined, and members will treat a thin list here as a suggestion magnet. Keep "chosen approach" to a short rationale — the full step-by-step mechanism, with its per-step guarantees, belongs in §3 (Architecture & Data Flow) below; don't duplicate a full pipeline diagram in both places.*

**Chosen approach**

[PLACEHOLDER — chosen approach, from plan.md's Summary / Technical Context]

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| [PLACEHOLDER — alternative 1] | [PLACEHOLDER — why, from plan.md] |
| [PLACEHOLDER — alternative 2] | [PLACEHOLDER — why, from plan.md] |

---

## 3. Architecture & Data Flow *(D62 — new section; round-1 evidence: S01/S02/S04/S13/S14/S15, both blocking defects)*

*Guidance: pull `plan.md`'s own `## Architecture & data flow` section (or equivalently named) and reproduce its step-by-step pipeline — every distinct step, in order, with what each step reads/writes, which guarantees it claims (determinism, ordering, freshness, stability across partial re-runs), and, critically, **which component performs each write** — a deterministic script vs. a live model session is a load-bearing distinction (D53), not a paraphrasing detail. Round-1's deck compressed this into a 4-line, un-annotated ASCII diagram folded inside §2; that compression is exactly what let both of that round's blocking defects — a set serialized in non-deterministic order, and a gate-write path nothing actually wired — reach the council unnoticed by deck-prep itself. Reproduce faithfully but concisely: this section earns its length by replacing what members were otherwise fetching from `plan.md` directly; it is not license to copy the whole file.*

[PLACEHOLDER — full step-by-step architecture & data flow, from plan.md's own Architecture & data flow section: the pipeline diagram with per-step read/write/guarantee annotations, plus any explicit reinforcement notes it states (e.g. freshness checks, determinism guarantees, re-run stability claims)]

---

## 4. Project Structure & Dependency / Graph Impact *(Project Structure fold-in — D62; round-1 evidence: S06/S10/S25)*

*Guidance: two related but distinct sources feed this section — don't conflate them. First, pull `plan.md`'s own `## Project Structure` section: the file/directory tree, the "Structure Decision" narrative (why this shape — package or extension boundaries, one component vs. several), and any shared/mutable-file collision policy it states (install order, locking, serialize-vs-parallelize rules). Second, pull blast radius, shared/mutable files, and relevant existing modules from `graphify-context.md`. **Any specific graph metric this section states — a node's degree, an edge count, "the most-referenced file" — must be read directly from `graphify-context.md` / the graph tool output, never restated from `plan.md`'s own prose unverified.** Round-1's deck asserted a shared config file was "degree 15... the single highest-collision file" with no independent check; three separate members re-ran the graph query and got degree 1 — the number was wrong, but the real risk it was reaching for (a lock-free merge into a shared file, with no defined install order between two new extensions touching it in the same round) was real, and is exactly the kind of claim this section exists to get right the first time. If deck-prep ran without a `graph.json`, say so plainly here rather than omitting the section — the reduced-grounding condition still gets flagged downstream in `suggestions.md` (FR-019), but a silent gap here reads as an unexamined claim, not a graceful degradation.*

**Project Structure** (from `plan.md`)

[PLACEHOLDER — file/directory tree shape + the Structure Decision narrative from plan.md's Project Structure section: component/extension boundaries, install order, shared-file collision policy]

**Dependency / Graph Impact** (from `graphify-context.md`, independently verified)

[PLACEHOLDER — dependency/graph impact from graphify-context.md, or an explicit "no graph available" note; any metric cited here is the tool's own output, not a restatement of plan.md's prose]

---

## 5. Risk Register

*Guidance: enumerate the real risks `plan.md` surfaces (including anything from its Complexity Tracking table), one row each. Every risk needs a mitigation — a row with no mitigation is what the `risk` lens (S4) is built to catch.*

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [PLACEHOLDER — risk 1] | [low / med / high] | [low / med / high] | [PLACEHOLDER — mitigation] |
| [PLACEHOLDER — risk 2] | [low / med / high] | [low / med / high] | [PLACEHOLDER — mitigation] |

---

## 6. Cost / Complexity Estimate

*Guidance: state the session count this plan implies (deck-prep, council members, chairman, triage, and any implementation sessions) and the model mix per the D18 role→model map (e.g., "N Sonnet sessions + 1 Opus xhigh"). Note anything in `plan.md` that drives complexity up (new dependencies, cross-cutting changes) — this is what the `cost`/`simplicity` lenses check against the chosen approach in §2.*

[PLACEHOLDER — session count + model mix, from plan.md]

---

## 7. Testability Claim & Plan-Time Verifications *(strengthened — D62; round-1 evidence: S03/S05/S09/S12/S22/S23/S24, the round's single highest-demand section)*

*Guidance: pull `plan.md`'s own `## Plan-time verifications & per-SC test coverage` section (or equivalently named) wholesale — reproduce its full per-SC/FR table (claim, enforcement mechanism, committed-test yes/no), not a paraphrase of `spec.md`'s Success Criteria. This was round-1's single highest-demand section (7 of 25 suggestions) even though its table was already rendered near-verbatim — the gap was two things the table alone didn't make visible at a glance, so surface them explicitly: (1) a one-line tally — "N of M SCs have a committed/golden test; the rest are manual-only" — so the code-verified/manual split isn't something a reader has to count row-by-row themselves; (2) for every fixture-backed test that asserts a guard or a conditional (an `if`/`else`, a floor, a cap), confirm the fixture set can actually exercise **both** branches — a fixture set that can only ever pass an assertion proves nothing about its failure branch. This exact gap (a Sonnet-floor guard with no non-Sonnet fixture anywhere in the library that could trip it) was independently found by two members from two different lenses in round-1. A claim with no verification method, or a guard that cannot fail under the described fixtures, is what the `testability` lens (S4) is built to flag.*

[PLACEHOLDER — full per-SC/FR verification table, from plan.md's Plan-time verifications section, + the committed-vs-manual tally line + a note on guard/branch falsifiability for each fixture-backed assertion]
