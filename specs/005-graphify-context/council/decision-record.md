# Decision Record — 005-graphify-context

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).

## Metadata

| Field | Value |
|---|---|
| feature | `005-graphify-context` |
| spec-id | `005-graphify-context` |
| profile | `gates.council=human, gates.workforce=human` |
| rounds-run | 1 |
| schema-version | `1.0` |

---

## Round 1 — 2026-07-13T18:12:00Z

**Verdict:** 3 blocking · 11 strong · 6 consider
**Deck reviewed:** `council/defense-deck/technical.md` @ `4a77732`
**Plan reviewed:** `plan.md` @ `8ef9aa1`

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | blocking | Negative-path fixture manufacturing >0 stale survivors, asserting the guard detects AND prune-or-rebuilds; a precondition for arm-2 sign-off. | accepted | Blocking core: a guard for the M3 86-node incident, exercised only on passing input. Applied as Arm 2 Fixture case (d). Delta-check: RESOLVED. | `plan.md §Arm 2 (Fixture)` @ `031bf13` |
| R1-S02 | blocking | Specify arm-2's stale/recovery control flow pre-tasks: what "routes to regeneration" invokes; prune-vs-rebuild on survivors>0. | accepted | The branch SC-004's cost claim binds to was unspecified+untested. Applied as the Arm 2 Shape branch table: common path = cheap `refresh.sh` always; survivors>0 → prune + targeted re-extract of affected scope; full regen only on extractor-version-change or explicit demand. Delta-check: RESOLVED. | `plan.md §Arm 2 (Shape)` @ `031bf13` |
| R1-S03 | blocking | Fixture feeding an unmodeled relationship kind, asserting the labeled-assertion fallback APPEARS (silence is the failure mode). | accepted | SC-002's honesty guarantee was exercised only on the success branch. Applied as Arm 1 Fixture branch (2). Delta-check: RESOLVED. | `plan.md §Arm 1 (Fixture)` @ `031bf13` |
| R1-S04 | strong | Harden `explain` with `path`'s ambiguous-match warning + adopt a qualified-path citation convention for deck-prep/members. | accepted | Round's strongest find (5/5 members + live-reproduced this round); wrong resolutions burn the arm-4 ceiling budget. Applied to Arm 1 contract surface + Risks R1. | `plan.md §Arm 1 (contract) / §Risks R1` @ `031bf13` |
| R1-S05 | strong | Calibrate the ceiling `N` tier-aware; don't derive a full-tier `N` from this lazy round. | accepted | Owner ruling **D77**: standard-tier `N=15` (~1.7× this round's max of 9); full-tier `N` UNSET / uncapped until its own baseline (trigger: first full-tier M5-class round); `002`'s 25–38 not a full-tier source. Applied to Arm 4 Shape. | `plan.md §Arm 4 (Shape)` @ `031bf13` |
| R1-S06 | strong | State whether incremental refresh re-invokes arm-1's augment on the changed scope; add a cross-arm composition fixture. | accepted | Silent coverage regression would falsify SC-004; no per-arm fixture catches it. Applied as an Arm 2 invariant + Fixture case (e). | `plan.md §Arm 2 (Shape/Fixture)` @ `031bf13` |
| R1-S07 | strong | Give SC-004 a numeric threshold; commit SC-006 to a concrete named follow-up trigger. | accepted | An SC with no number can't go red. Applied: Performance Goals numeric threshold (≤25% / ≲190k tok / 1 session for a ≤~10%-file change); SC-006 trigger = first post-arm-4 (`006`) round vs this baseline. | `plan.md §Performance Goals / §Arm 4` @ `031bf13` |
| R1-S08 | strong | Add a template-read edge kind OR state FR-003/SC-001 "majority" excludes template-heavy plumbing. | accepted | Owner ruling **D76** (exclude-and-book): plan states the exclusion; the template-read edge kind is booked as **I-24** (D66 seeding-bar) — admitted only on recurring feature-gap evidence; clarify's "three kinds, bounded" stands unamended. Applied to Arm 1 Shape. | `plan.md §Arm 1 (Shape)` @ `031bf13` |
| R1-S09 | strong | Make the trace `ceiling_hit` flag (not member prose) the load-bearing "never silent" guarantee; mechanical append on enforcement. | accepted | A member at its ceiling is prompt-following at its least reliable (D53). Applied: the orchestrator mechanically appends the disclosure line the instant it enforces the cap. | `plan.md §Arm 4 (Shape)` @ `031bf13` |
| R1-S10 | strong | Exercise messy real `.sh` patterns (commented-out `source`, conditional `cp`, `$VAR` indirection) — must not mint wrong edges. | accepted | Modeled-but-wrong is a regression from honest disjointness. Applied as an Arm 1 Shape rule + Fixture messy-pattern branch (3). | `plan.md §Arm 1 (Shape/Fixture)` @ `031bf13` |
| R1-S11 | strong | Pin the serialization discipline behind "byte-deterministic" (stable ordering, canonical keys, no FS-iteration dependence). | accepted | "No LLM" is necessary but not sufficient for golden diffing (the `003`-S01 sorted-set lesson). Applied to Arm 1 Fixture. | `plan.md §Arm 1 (Fixture)` @ `031bf13` |
| R1-S12 | strong | Detached-configuration fixture: arms 2+3+4 pass green with arm 1 absent. | accepted | Severability was rationale-only; the plan's own prose-vs-mechanism standard (D53) applies to its own claim. Applied to Detach order. | `plan.md §Detach order` @ `031bf13` |
| R1-S13 | strong | Cross-product coherence fixture: all three diets carry the same graph hash from one generator run. | accepted | Per-product goldens prove each diet correct in isolation, not mutually coherent (D53). Applied to Arm 3 Fixture. | `plan.md §Arm 3 (Fixture)` @ `031bf13` |
| R1-S14 | strong | State the intra-cycle execution order across arms 1→2→3. | accepted | Build order and severability were being conflated. Applied to the Four Severable Arms intro: build order (augment→freshness→generate) distinct from detach order. | `plan.md §Four Severable Arms` @ `031bf13` |
| R1-S15 | consider | Lead the severability framing with the 1-vs-3 asymmetry. | accepted | Sharpens the framing; the spec-inherited "four independently-shippable" phrasing (D74-2) is kept, reframed. Applied to Summary + Detach order. | `plan.md §Summary / §Detach order` @ `031bf13` |
| R1-S16 | consider | Confirm a real `graphifyy` version pin (manifest + check) — preventive, not reactive. | accepted | R4's stated mitigation was code-usage discipline (reactive) for a Med–High-impact risk. Applied: manifest pin + wrapper version-check → full-regen branch on mismatch. | `plan.md §Risks (R4)` @ `031bf13` |
| R1-S17 | consider | Guard the mid-implementation `005` self-reopen (pre-ceiling prompt until arm 4 wires). | accepted | Narrowed per peer to the only actionable case (a future feature's round predating `005` is unavoidable and out of scope). Applied to Arm 4 Baseline (one line). | `plan.md §Arm 4 (Baseline)` @ `031bf13` |
| R1-S18 | consider | Both inverse fixtures: false-positive-stale (unmutated worktree reports fresh) + non-disclosure-default (ordinary round carries no disclosure line). | accepted | Crying-wolf coverage is coverage. Applied: Arm 2 Fixture case (b) for false-positive-stale; Arm 4 Fixture non-disclosure-default branch (`ceiling_hit: false`, no disclosure line) for SC-008. | `plan.md §Arm 2 (Fixture) / §Arm 4 (Fixture)` @ `031bf13` |
| R1-S19 | consider | Argue why the freshness check-then-use race can't occur under wave-glue serialization; fixture only if the argument fails. | accepted | Round's most speculative item (self-rated, no citation) — argue-first per disposition. Applied to Arm 2 Shape: the shared/mutable collision rule serializes graph-mutating tasks across waves; concurrent-refresh fixture is the fallback if the argument fails to close at implement. | `plan.md §Arm 2 (Shape)` @ `031bf13` |
| R1-S20 | consider | State that `freshness.sh`'s report is recomputed at every consumption point, never cached across hook calls within a session. | accepted | A consumer trusting an earlier-computed report recreates the stale-artifact failure one layer up. Applied to Arm 2 Shape: recompute-at-every-consumption invocation contract (derived property, D32). | `plan.md §Arm 2 (Shape)` @ `031bf13` |

### Chairman delta check — 2026-07-13T18:09:18Z

- R1-S01 — RESOLVED — Arm 2's fixture now carries case **(d)**: a negative-path fixture that manufactures > 0 stale survivors (the M3 86-node incident in miniature) and asserts the guard both **detects** them and actually performs the **prune-or-rebuild** recovery, made an explicit precondition for arm-2 sign-off rather than a disclosed-and-shipped gap.
- R1-S02 — RESOLVED — Arm 2's Shape now specifies a concrete stale/recovery branch table: the common stale path runs the cheap `refresh.sh` incremental **always** (the path SC-004's "materially lower cost" binds to), survivors > 0 routes to **prune + targeted re-extract of the affected scope only**, and the ~753k-token full-corpus regen fires **only** on an extractor-version change or explicit operator demand — the branch is no longer unspecified.
- R1-S03 — RESOLVED — Arm 1's fixture now has branch **(2)**: a fallback-branch fixture feeding the augmentation pass a relationship kind *outside* the three modeled edge kinds and asserting the **labeled-assertion fallback appears** (silence named as the failure mode), so SC-002's "zero unlabeled fallback claims" honesty guarantee is exercised, not just the success branch.

**Delta verdict:** all clear, ready for the gate

---

## Human Gate — 2026-07-13T18:20:45Z

| Field | Value |
|---|---|
| reviewer | Naren Karthik B M |
| decision | `approved` |
| reviewed | `defense-deck/overview.md`, `round-1/suggestions.md`, this record |

**Notes:** none.

**Overrides:** none.

**Binding:** plan↔SHA binding recorded at `specs/005-graphify-context/gates.yml` (git-ext-owned; FR-008/D55).

---

## Carried Constraints

> Accepted suggestions that constrain task generation. `/speckit-tasks` reads this section
> and nothing else from this file.

- `R1-S01` — arm-2's stale-survivor guard needs a **negative-path fixture** (manufactures >0 survivors, asserts detect + prune-or-rebuild) as a sign-off precondition — not merely the 0-survivor pass.
- `R1-S02` — arm-2's stale/recovery path is a **branch table**: common → cheap `refresh.sh` always; survivors>0 → prune + targeted re-extract of affected scope; full regen only on extractor-version-change/demand. Task the branches distinctly.
- `R1-S03` — arm-1 needs a **fallback-branch fixture** (unmodeled edge kind → labeled assertion appears); the success-branch golden alone does not discharge SC-002.
- `R1-S04` — task the `graphify explain` ambiguous-match warning **and** the qualified-path citation convention for deck-prep + member-prompt (extension-seam edits; `graphifyy` untouched).
- `R1-S05` — arm-4 ceiling is tier-scoped: **standard `N=15`**; **full-tier UNSET / uncapped** until its own baseline. Do not task a full-tier ceiling value.
- `R1-S06` — arm-2 incremental refresh **re-invokes arm-1 augment on the changed scope**; needs a **cross-arm composition fixture** (a per-arm fixture won't catch the regression).
- `R1-S07` — SC-004 has a **numeric threshold** (≤25% / ≲190k tok / 1 session for ≤~10%-file changes); SC-006's measurement is a **named follow-up** (first post-arm-4 `006` round).
- `R1-S08` — arm-1 `.md` coverage **excludes template-heavy plumbing** (stated, not silently); template-read edge kind is deferred to **I-24**, not this feature. Three edge kinds only.
- `R1-S09` — arm-4 "never silent" is carried by the **mechanical `ceiling_hit` flag + orchestrator-appended disclosure line**, not member prose. Task the mechanical append.
- `R1-S10` — arm-1 golden exercises **messy real `.sh` patterns**; unresolvable constructs fall to labeled assertion, never a guessed edge.
- `R1-S11` — arm-1 golden pins **byte-determinism** (stable ordering, canonical keys, no FS-iteration dependence).
- `R1-S12` — a **detached-configuration fixture** (arms 2+3+4 green with arm 1 absent) is required for the severability claim.
- `R1-S13` — arm-3 needs a **cross-product coherence fixture** (all three diets share one graph hash / generation-id).
- `R1-S14` — **build order is arm 1→2→3** (augment→freshness→generate), distinct from detach order; task ordering follows build order.
- `R1-S15` — severability is framed as a **1-vs-3 asymmetry** (arm 1 detachable; arms 2–4 core). Narrative only; no task impact beyond the plan text.
- `R1-S16` — arm-2 carries a **real `graphifyy` version pin** (manifest + wrapper check → full-regen on mismatch).
- `R1-S17` — the `--reopen` path notes **pre-ceiling prompt status** until arm 4 wires (mid-implementation `005` self-reopen guard; one line).
- `R1-S18` — freshness needs a **false-positive-stale** fixture (unmutated → fresh) **and** arm-4 needs a **non-disclosure-default** fixture (ordinary round → no disclosure line, `ceiling_hit: false`).
- `R1-S19` — arm-2 **argues** the check-then-use race is precluded by wave-glue serialization of shared files; a concurrent-refresh fixture is the fallback only if that argument fails to close.
- `R1-S20` — `freshness.sh`'s report is **recomputed at every consumption point**, never cached across hook calls within a session.
