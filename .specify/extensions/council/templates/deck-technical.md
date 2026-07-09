# Defense Deck — Technical

**Feature**: `[NNN-feature-name]`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

*Guidance: restate the problem in 1–2 short paragraphs, pulled from `spec.md` (the "why", the User Scenarios, the priority-1 story). No solutioning here — this section grounds the reviewer in what's being solved before they see the answer.*

[PLACEHOLDER — problem restatement from spec.md]

---

## 2. Chosen Approach & Rejected Alternatives

*Guidance: state the approach `plan.md` actually chose, then list every alternative it seriously considered and rejected, each with the concrete reason it lost — not a strawman. This is the crux the council scrutinizes hardest: a plan with no rejected alternatives reads as unexamined, and members will treat a thin list here as a suggestion magnet.*

**Chosen approach**

[PLACEHOLDER — chosen approach, from plan.md's Summary / Technical Context]

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| [PLACEHOLDER — alternative 1] | [PLACEHOLDER — why, from plan.md] |
| [PLACEHOLDER — alternative 2] | [PLACEHOLDER — why, from plan.md] |

---

## 3. Dependency / Graph Impact

*Guidance: pull blast radius, shared/mutable files, and relevant existing modules from `graphify-context.md`. If deck-prep ran without a `graph.json`, say so plainly here rather than omitting the section — the reduced-grounding condition still gets flagged downstream in `suggestions.md` (FR-019), but a silent gap here reads as an unexamined claim, not a graceful degradation.*

[PLACEHOLDER — dependency/graph impact from graphify-context.md, or an explicit "no graph available" note]

---

## 4. Risk Register

*Guidance: enumerate the real risks `plan.md` surfaces (including anything from its Complexity Tracking table), one row each. Every risk needs a mitigation — a row with no mitigation is what the `risk` lens (S4) is built to catch.*

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [PLACEHOLDER — risk 1] | [low / med / high] | [low / med / high] | [PLACEHOLDER — mitigation] |
| [PLACEHOLDER — risk 2] | [low / med / high] | [low / med / high] | [PLACEHOLDER — mitigation] |

---

## 5. Cost / Complexity Estimate

*Guidance: state the session count this plan implies (deck-prep, council members, chairman, triage, and any implementation sessions) and the model mix per the D18 role→model map (e.g., "N Sonnet sessions + 1 Opus xhigh"). Note anything in `plan.md` that drives complexity up (new dependencies, cross-cutting changes) — this is what the `cost`/`simplicity` lenses check against the chosen approach in §2.*

[PLACEHOLDER — session count + model mix, from plan.md]

---

## 6. Testability Claim

*Guidance: for each FR/SC this plan touches, name how it will be verified (contract test, conformance check, manual gate, etc.) — pull this from `plan.md`'s testing approach, not just a restatement of `spec.md`'s Success Criteria. A claim with no verification method is what the `testability` lens (S4) is built to flag.*

[PLACEHOLDER — testability claim, mapping FRs/SCs to verification methods]
