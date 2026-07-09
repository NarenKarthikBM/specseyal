# Suggestions — Round [N]

<!--
Reduced-grounding banner — a CONDITIONAL slot, not a standing fixture.
Include the line below, verbatim, as the very next line after the title —
before the metadata block, before anything else — ONLY when this round ran
with no graphify graph.json available to deck-prep and the members
(FR-019, FR-005, SC-008). If the round had graph access, delete this whole
comment AND the banner line beneath it. Never leave the banner commented-out
-but-present, and never let a deck-only, degraded review read as fully grounded.
-->
> ⚠ Reduced grounding: no graph

**Feature**: `[NNN-feature-name]`
**Prepared by**: Session B — chairman (Opus, xhigh, D18)
**Reads**: `round-[N]/opinions/*.md`, `round-[N]/opinions/peer/*.md` (chairman-only inputs; never quoted verbatim below)

> Format: markdown v1 (D15). This is the **compression boundary** (`data-model.md`) — the ONLY file under `council/` the main thread reads (FR-007, principle 1), and the sole input to `/speckit-council-triage`. Round-scoped: written once as `round-N/suggestions.md` and **never overwritten** — contrast `defense-deck/`, which *is* overwritten in place on revision (D38). A later round gets its own `round-N+1/suggestions.md`; this file stays exactly as first written.

*This is the chairman's stage-3 synthesis of stage 1 (`opinions/<letter>.md`, independent) and stage 2 (`opinions/peer/<letter>.md`, anonymized peer review): consolidate, classify, ID, stop. Do not quote or forward opinion prose verbatim — `opinions/` stays chairman-only and unread by the main thread for the life of the feature (FR-006, FR-007, SC-005). This file is the entire reason that boundary holds.*

---

**Verdict:** <a> blocking · <b> strong · <c> consider

*Guidance: `<a>` / `<b>` / `<c>` are literal counts of the table's rows, by class — not a subjective summary. This line drives convergence (FR-010): `<a> = 0` routes straight to the human gate; `<a> ≥ 1` forces exactly one revision cycle plus a chairman-only delta check before the gate (SC-004). It must always agree with the table below — a mismatch is a conformance failure, not a style choice.*

---

## Suggestions

*Guidance: one row per suggestion the chairman actually consolidated — not one row per opinion file; several members raising the same point collapses to one row with multiple `Sources`. The row below is one worked example; a real round adds as many rows, in the same shape, as it produced (there is no fixed count, and none is required beyond zero).*

| ID | Class | Suggestion | Sources | Target |
|----|-------|-----------|---------|--------|
| R1-S01 | blocking | Split the migration from the schema change | A, E | plan.md §4 |

*Field domains:*

| Field | Domain |
|---|---|
| `ID` | `R<round>-S<nn>` — assigned here in write order, **never renumbered** afterward even if triage later rejects the suggestion (FR-008; `decision-record.md`) |
| `Class` | `blocking` \| `strong` \| `consider` (D13) — the chairman's call; only the human gate may override a `blocking` (`decision-record.md` R5) |
| `Suggestion` | the consolidated suggestion, phrased as one instruction to the plan — not a restatement of the problem |
| `Sources` | the anonymized letter(s) (stage 1 and/or stage 2) that raised or backed it, e.g. `A, E` — never a real member name; the letter→member map is never persisted (FR-006) |
| `Target` | the plan section it bears on, as `plan.md §<N>`. If a suggestion doesn't map to one section cleanly, name the nearest and say why in the suggestion text itself |

---

## Chairman's note

*Guidance: 1–3 sentences, no more. Two jobs: (1) always — state the overall verdict: what the round converged on, and where members agreed or split, naming the round's real find if it has one; (2) only when this file follows a revision — i.e. it reports a chairman-only delta check (FR-010, D13), whose result is also recorded in `decision-record.md`'s `### Chairman delta check` — add whether the revision actually resolved the prior blocking item(s). Every claim here must trace to a row in the table above; this note synthesizes, it never introduces a new suggestion.*

[PLACEHOLDER — 1–3 sentence chairman's note: overall verdict, and, after a revision, the delta-check result]
