# Phase 0 Research — speckit-ext-council

Design decisions resolved before Phase 1. Format: **Decision / Rationale / Alternatives**. There is no external technology to research (the extension is Claude Code skills + the graphify pattern); the "unknowns" are design choices the spec deferred to the plan.

## R-D1 — Member differentiation ("varied prompts", D18)

**Decision**: 5 **general-purpose** members share one base reviewer prompt, differentiated by a soft **lens nudge** each: A correctness/logic · B risk & failure modes · C simplicity & rejected alternatives · D testability · E dependencies & sequencing.

**Rationale**: Satisfies D18 ("varied prompts") and docs/10's "faithful llm-council v1" simultaneously — the lenses induce opinion diversity without making members formal role critics. The base prompt lives in `member-prompt.md` with a `{{lens}}` slot, so v1→v2 (role critics) is a template swap, not an architecture change (FR-003). Each member records its assigned lens in its opinion metadata (S4), so the first live run yields evidence of which lens surfaced which suggestion — direct input to the v2 role-critic design.

**Alternatives**: (a) identical prompts, rely on sampling diversity — weaker signal, wastes the chance to spread coverage; (b) formal v2 role critics now — pre-empts a v2 decision and overfits before cost data exists.

## R-D2 — Subagent choreography

**Decision**: `/speckit-council` runs in the main thread as orchestrator and dispatches **leaf subagents** (deck-prep, 5 members ×2 stages, chairman), holding stage barriers — the `speckit-implement-parallel` wave pattern. Members return **compact statuses**; only the chairman's `suggestions.md` returns as content.

**Rationale**: Proven pattern in the graphify exemplar; keeps every stage's output an inspectable artifact (resumability); honors context hygiene (no opinion bodies in the main thread).

**Alternatives**: a single nested "council session" subagent — Claude Code doesn't reliably nest subagents, and it hides the barriers from the artifact tree. (That form is the M6 SDK realization; the invariant is identical.)

## R-D3 — Trace assembly under parallelism

**Decision**: each subagent returns a **structured trace fragment**; the orchestrator appends fragments to `traces.jsonl` **serially, after each barrier**.

**Rationale**: 5 parallel members appending to one JSONL file would interleave and corrupt lines. Serial orchestrator assembly is race-free and keeps `traces.jsonl` valid (one JSON object per line).

**Alternatives**: per-subagent direct append (corruption risk); per-session temp files + later concat (more files, same result as serial assembly).

## R-D4 — Per-session token capture *(OPEN — Risk R1)*

**Decision**: read token usage from the Agent-tool return metadata when available; otherwise emit structurally-valid traces with best-effort tokens and defer the exact measurement to the SDK-driven platform (M6).

**Rationale**: SC-002 (the M1 exit) needs real per-session tokens. Interactive Claude Code may not expose per-subagent usage programmatically. This is the plan's chief open risk and is **flagged for the council** — it decides whether M2's exit measurement is exact or best-effort.

**Alternatives**: parse `/cost` (user-facing, not programmatic); estimate from duration (fabricated precision — rejected on the same grounds as `cost_usd=null`).

## R-D5 — Deck rendering

**Decision**: two markdown templates — `deck-technical.md` (problem, chosen approach + rejected alternatives, dependency/graph impact, risk register, cost/complexity, testability) and `deck-overview.md` (one page: what/why, what could go wrong, cost, "done").

**Rationale**: D15 fixes markdown for v1 — diffable, session-friendly, git-versioned in place (D38). Presentational rendering is a later GUI concern.

**Alternatives**: HTML/pptx (D15 rejected — deferred to the platform).

## R-D6 — Reduced-grounding flag (FR-019)

**Decision**: when `graph.json` is absent, members note it in their opinions; the chairman writes an explicit **`> ⚠ Reduced grounding: no graph`** banner at the top of `suggestions.md`; triage copies it into the decision-record round header. Visible at the gate (SC-008).

**Rationale**: A degraded review must never read as fully grounded (D46). The flag rides the existing artifacts — no new file.

## R-D7 — Reopen interface (FR-017, D46)

**Decision**: `/speckit-council --reopen <delta|full>`. `delta` builds the context package from `(plan diff, triggering finding)` and runs the round against only that; `full` reruns the whole round. Both write a `## Reopen` section (tier, proposer, scope) to the decision record.

**Rationale**: v1 ships the *mechanism*, manually invoked; the automated `/speckit-analyze` trigger (D11) is deferred to analyze integration. Keeps the reopen path exercised and contract-complete (`decision-record.md` §4) without the analyze dependency.
