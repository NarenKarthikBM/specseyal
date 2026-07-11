---
description: "Dispatch one Sonnet categorizer session over tasks.md + plan.md; code-validate against taxonomy v0 and the general-cap; write categorization.md only on a pass"
---

# Categorize

Tag every task in `tasks.md` with `(type, specialization, preserves_behavior, tags)` per taxonomy v0 (`docs/contracts/taxonomy-v0.md`). Runs **after** `analyze` (D58), so `tasks.md` is assumed stable by the time this runs. `tasks.md` is never mutated (D37) — `categorization.md` is the only artifact out, and it is written **only** when the validator passes (S22).

## Behavior

- Dispatches **one Sonnet `categorizer` subagent**: tags every task — `type`/`preserves_behavior` mechanical from graphify signals, `specialization` interpretive from `plan.md` + domain — and records the source `tasks.md` SHA it derived from (S14).
- Runs `validate-categorization.py` (zero-AI, imports the shared `frontmatter.py`, S21): 100% coverage + closed-enum membership (SC-001); `count(general) > 0.20 × count(tasks)` ⇒ exit non-zero (FR-004/SC-002).
- On pass, keeps/writes `categorization.md` and honors the `after_categorize` hook → a phase-tagged commit. On fail: no artifact, the breach is reported verbatim, and the phase does not complete.
- Appends exactly one `categorizer` trace record (role=categorizer, model=sonnet) either way.

## Execution

Run the `/speckit-categorize` skill (this command file is its provenance source). The Sonnet dispatch is LLM-driven orchestration; `validate-categorization.py` is the one standalone script it runs.
