# Contract — council command surface

The extension's external interface is three Claude Code commands (CLI contracts, per the plan-template's "command schemas for CLI tools"). Each is idempotent and resumable from artifacts (Constitution III).

---

## `/speckit-council [--reopen <delta|full>]`

Runs deck prep + one council round; returns the suggestions summary to the main thread.

| | |
|---|---|
| **Preconditions** | `plan.md` exists (validates). Feature resolved via `.specify/feature.json`. |
| **Reads** | `plan.md`, `spec.md`, `graphify-context.md`, `graphify-out/graph.json` (optional). |
| **Sessions** | deck-prep (Sonnet) · 5 members ×2 stages (Sonnet, ∥) · chairman (Opus). |
| **Writes** | `council/defense-deck/{technical,overview}.md`; `council/round-N/opinions/**`; `council/round-N/suggestions.md`; appends the sessions' traces to `traces.jsonl`. |
| **Returns to main thread** | `suggestions.md` **only** (never `opinions/`). |
| **Postcondition** | `round-N/suggestions.md` exists and validates (unique IDs, classes ∈ {blocking,strong,consider}); reduced-grounding banner present iff no graph (FR-019). |
| **`--reopen delta`** | context = `(plan diff, triggering finding)`; runs stages 1–3 on that; writes `## Reopen` (tier=delta) to the decision record. |
| **`--reopen full`** | full round rerun; writes `## Reopen` (tier=full). |
| **Exit states** | success → suggestions written · no-plan → error, do nothing · no-graph → success + reduced-grounding flag. |
| **Idempotency** | re-run with an existing `round-N/` starts `round-(N+1)/`; never overwrites a prior round. |

## `/speckit-council-triage`

Applies accepted suggestions to the plan; writes the decision record. Runs in the main thread (Opus).

| | |
|---|---|
| **Preconditions** | `round-N/suggestions.md` exists. |
| **Reads** | `suggestions.md` **only** (context-hygiene boundary). |
| **Writes** | revised `plan.md` (on the feature branch); `council/decision-record.md` (append round table); its own trace. |
| **Postcondition** | every suggestion id → exactly one disposition; `rejected`/`deferred` ⟹ non-empty rationale (D13.5); accepted `blocking` ⟹ `plan-delta` names the commit. If any `blocking`: one revision + chairman-only delta check → `### Chairman delta check` recorded. |
| **Convergence** | zero blocking → done (ready for the gate); residual blocking after the delta check → escalate to the gate (round limit, D13). |
| **Exit states** | success → decision record updated, ready for gate · unresolved blocking → flagged for the human. |

## `/speckit-council-approve <approved|approved-with-notes|rejected> [notes]`

Records the human-gate decision; unlocks `/speckit-tasks`. No session (a human acts).

| | |
|---|---|
| **Preconditions** | `decision-record.md` has a triaged round; `overview.md` + `suggestions.md` exist. |
| **Reads (by the human)** | `defense-deck/overview.md`, `suggestions.md`, `decision-record.md`. |
| **Writes** | `## Human Gate` section (reviewer, decision, reviewed artifacts, notes, overrides) appended to `decision-record.md`. No trace (no session runs — `artifact-layout.md` §2). |
| **Postcondition** | decision ∈ {approved, approved-with-notes, rejected}. `approved*` → `/speckit-tasks` unlocked. `rejected` → returns the plan for one more revision round. Under `gates.council.mode: auto` (only within `full_auto`), triage writes this section with `reviewer: auto`. |

---

## Cross-command invariants

1. **Context hygiene (SC-005):** no artifact under `specs/NNN/` outside `council/` ever names the `opinions/` path. The main thread reads only `suggestions.md`.
2. **Resumability (III):** each command's completion is inferable from its artifact-out; re-running a completed command is a no-op or a next-round append, never a corruption.
3. **Observability (IV):** `/speckit-council` and `/speckit-council-triage` emit traces; `/speckit-council-approve` does not (no session). `council_spend` = council + deck-prep phase spend (`trace-schema.md` §5).
4. **Ownership (`artifact-layout.md` §6):** the council extension is the sole writer of everything under `council/`; triage is the sole writer that revises `plan.md` during the council loop.
