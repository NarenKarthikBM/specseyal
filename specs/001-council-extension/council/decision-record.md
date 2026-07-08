# Decision Record — 001-council-extension

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).
>
> **Bootstrap note.** The council extension does not yet exist, so for this feature's own plan the
> **human is the council** (D9 — the gate is always the backstop). There is therefore no
> `defense-deck/`, no `round-N/opinions/`, and no chairman `suggestions.md`: the four suggestions
> below are the human council's, raised directly against `plan.md`. The extension's first *machine*
> council run is M2's plan (the M1 exit test). This file is the `decision-record.md` contract's first
> real instance — produced, fittingly, by its own bootstrap gate.

## Metadata

| Field | Value |
|---|---|
| feature | `001-council-extension` |
| spec-id | `001-council-extension` |
| profile | `gates.council=human, gates.workforce=human` |
| rounds-run | 1 |
| schema-version | `1.0` |

---

## Round 1 — 2026-07-09 (bootstrap human council)

**Verdict:** 0 blocking · 2 strong · 2 consider
**Deck reviewed:** — (bootstrap: no deck; the human read `plan.md` + the Phase-0/1 artifacts directly)
**Plan reviewed:** `plan.md` @ `c916485`

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | strong | Trace `tokens` = exact-or-null + a `capture_method` enum; amend SC-002 to record the method; add a timeboxed transcript-capture spike (spike failure = `unavailable`, not a blocker) | accepted | — | `trace-schema.md`→1.2 (D47) · `spec.md` §SC-002 · spike booked into `tasks.md` |
| R1-S02 | strong | Explicit invariant — subagent returns are status-only, all content file-mediated; extend SC-005 to the orchestrator transcript | accepted | — | `plan.md` §Chosen Approach C (Invariant) · `spec.md` §SC-005 |
| R1-S03 | consider | Keep the bench at 5 + faithful two-stage peer review for the first live run; defer tuning until the first SC-002 measurement | accepted | — | `plan.md` §Risk register (R2) |
| R1-S04 | consider | Lenses approved as proposed; record each member's lens in opinion metadata for future v2 evidence | accepted | — | `data-model.md` §Opinion · `research.md` §R-D1 |

### Chairman delta check

*Only present when a round raised `blocking` items.* — omitted (0 blocking).

---

## Human Gate — 2026-07-09

| Field | Value |
|---|---|
| reviewer | Babu |
| decision | `approved` |
| reviewed | `plan.md`, `research.md`, `data-model.md`, `contracts/commands.md`, `quickstart.md` |

**Notes:** Bootstrap gate — the human acted as the council for the council's own plan (D9). Approved with **no blocking items**; all four suggestions accepted and applied in the same commit as this record. The extension's first machine-run council review is M2's plan — simultaneously SC-002's first measurement and the M1 exit test.

**Overrides:** none.

---

## Carried Constraints

> Accepted suggestions that constrain task generation. `/speckit-tasks` reads this section
> and nothing else from this file.

- `R1-S01` — `tasks.md` MUST include the trace-writer emitting `capture_method`, plus a **timeboxed transcript-based token-capture spike**; spike failure records `capture_method: unavailable`, never blocks.
- `R1-S02` — the orchestrator/member design MUST enforce **status-only returns** (all opinion content file-mediated); a task verifies SC-005's two-part check.
- `R1-S03` — `member_count: 5` + faithful two-stage peer review are **fixed for the first live run** (config); no tuning task exists until SC-002 does.
- `R1-S04` — member opinions **record their lens** in metadata.

---

## Workforce Gate — 2026-07-09  ⚠ bootstrap placement (contract gap, I-12)

> **Flagged gap (I-12).** No contract defines a workforce-gate record *format*. `artifact-layout.md` §2 puts
> the workforce-gate record in `agents/assignment.md` — but that is M3's agent-assignment artifact, and M3 has
> not shipped (categorization for `001` was a manual pass, so there is no roster artifact). Per the gate's own
> directive, this approval is recorded here instead. Doing so **exceeds the `decision-record.md` contract's
> section set** (which ends at `## Carried Constraints`, cardinality "1, last") — recorded that way *deliberately*,
> to surface the gap rather than paper over it. Resolve at M3 / the v0→v1 contracts review.

| Field | Value |
|---|---|
| reviewer | Babu |
| decision | `approved` |
| roster | Sonnet implementation agents (D18); **max 3 parallel** |
| elevated grants | **none** (core toolset only; no `web_search`) |
| reviewed | `tasks.md` (20 tasks / 8 waves), `categorization.md` (0 `general`, cap 4 → pass) |

**Notes:** Bootstrap workforce gate — no `agents/assignment.md` roster exists (M3 not shipped); the human approved the tasks + waves + the manual categorization directly. Directives: **Call 1** upheld (`endpoint × ai-agents`, `orchestration` tag on the 3 command skills); **Call 2** accepted for v0 (D48 guard on `prompt`-tagged tasks; type resolution deferred to §8); shared-file registration stays orchestrator glue (taxonomy §2.1), never a parallel subagent.

**Overrides:** none.
