---
description: "Run deck prep + one council round on the current plan; return a classified suggestions summary to the main thread"
---

# Council Review

Convene the plan-defense council on the active feature's `plan.md`. Prepares a defense deck (technical + a one-page overview), then runs a three-stage llm-council review — independent opinions → anonymized peer review → chairman synthesis — producing `council/round-N/suggestions.md`. Only the chairman's suggestions cross back to the main thread (context hygiene); member opinions stay chairman-only.

## Behavior

- Reads `plan.md`, `spec.md`, `graphify-context.md`, and (if present) `graphify-out/graph.json`; reads `council-config.yml` for member count, lenses, and the D18 model map.
- Dispatches subagents: 1 deck-prep (Sonnet) → 5 members × 2 stages (Sonnet, parallel) → 1 chairman (Opus). Each session appends a trace to `traces.jsonl`.
- Degrades gracefully with a reduced-grounding flag when no graph exists (FR-019).
- `--reopen <delta|full>` re-runs the council on a reopened plan (D14).

## Execution

Run the `/speckit-council` skill (this command file is its provenance source). The work is LLM-driven subagent orchestration; there is no standalone script.
