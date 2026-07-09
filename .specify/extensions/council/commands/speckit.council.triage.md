---
description: "Apply accepted council suggestions to the plan and write the append-only decision record"
---

# Council Triage

Walk the chairman's `suggestions.md`, apply accepted suggestions to `plan.md` on the feature branch, and record every suggestion's disposition (accepted / rejected / deferred, with reasoning) in `council/decision-record.md`. On any `blocking` item, runs one revision plus a chairman-only delta check before the human gate.

## Behavior

- Reads `round-N/suggestions.md` **only** (never `opinions/` — the context-hygiene boundary).
- Writes `decision-record.md` conforming to its contract (dispositions, reasoning per D13.5, `### Chairman delta check`, `## Carried Constraints` kept last).
- Convergence (D13): zero blocking → gate; ≥1 blocking → one revision + delta check → gate; a residual blocking escalates to the human.
- Handles `## Reopen` (D14) and the `gates.council.mode: auto` gate write.

## Execution

Run the `/speckit-council-triage` skill (this command file is its provenance source).
