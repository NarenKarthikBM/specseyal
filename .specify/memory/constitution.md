# SpecSeyal Constitution

> The non-negotiable principles governing every feature built through this pipeline.
> Derived from `docs/00-VISION-AND-ARCHITECTURE.md` §2 and the decision log `docs/90`.
> This file is the operative gate that `/speckit-plan` and `/speckit-analyze` check each feature against.
> Amending it is a decision (a D-row in docs/90) plus a version bump here.

## Core Principles

### I. Artifacts Are the Contract
Every pipeline phase reads artifacts in and writes **exactly one** artifact out (principle 1, D4). The CLI layer and the platform layer share this single interface — files in the repo. A phase that writes two artifacts, or mutates another phase's artifact, violates this. `tasks.md` has two writers only because graphify appends a disjoint `## Execution Waves` section (artifact-layout §6); that is the sole exception, and it is why categorization got its own artifact (D37).

### II. Context Hygiene
The main thread stays a lean orchestration spine (principle 2). Heavy work — council review, categorization, agent assembly — runs in **separate sessions** that receive only their declared context-in and return one compact artifact. The main thread never inherits an offloaded session's context. The council's `opinions/` never cross to the main thread; `suggestions.md` is the sole compression boundary (docs/10 §6).

### III. Resumability (NON-NEGOTIABLE)
Phase state is **inferred from artifacts**. There is no state file, and adding one is forbidden (D32). A phase is complete iff its artifact-out exists **and** validates against its contract. Gate decisions are artifacts — a section appended to a record — never events in a database or a transcript. Kill the process anywhere; the artifact tree alone says where to restart.

### IV. Observability
Every session in every phase appends **exactly one** trace record to `traces.jsonl` (principle 4, D35). No opt-out — a feature cannot disable tracing. Traces carry **no message bodies** (identity and metrics only), so they are safe to sync to a multi-tenant manager without redaction review. Tokens are the unit of account; `cost_usd` is `null` under subscription billing (D6, D28).

### V. Subscription-Only Billing (NON-NEGOTIABLE)
All work runs on Claude subscription auth. `ANTHROPIC_API_KEY` is **never** set or relied upon (D28). M0–M5 run in interactive sessions; M6+ programmatic sessions use the plan's Agent SDK monthly credit. A build machine with the key set routes billing to the API silently — so it stays unset.

## Additional Constraints

### Model Policy (D18)
Two-plane: **Opus (xhigh)** on the main thread and for judgment roles (council chairman, analyze/triage); **Sonnet** for implementation agents and mechanical/generative roles (deck prep, categorizer, skill builder, council members). Haiku unused in v1. Only base specialists declare a model; a `(role, model)` contradiction in a trace is *flagged*, never silently rewritten (the trace is evidence, not an enforcer).

### Autonomy & Gates (D9)
Exactly two gate-capable checkpoints: the **council gate** (post-plan) and the **workforce gate** (post-tasks + agent assignment). The council gate is default-on in every profile; skipping it requires an explicit `full_auto: true` handshake (profile-schema §2). Autonomy is about **who signs**, never about **what runs** — an `auto` gate still convenes the council and writes every artifact.

## Governance

This constitution supersedes convenience. Every `/speckit-plan` runs a **Constitution Check** gate against these principles before Phase 0 and re-checks after design; an unjustified violation is an ERROR. A justified violation is recorded in the plan's **Complexity Tracking** with the simpler alternative that was rejected and why.

**Log discipline (non-negotiable):** any decision made in a session gets a D-row in `docs/90` in that same session; ideas get I-rows immediately. Amendments to this constitution are themselves decisions — a D-row, plus a version bump below.

**Version**: 1.0.0 | **Ratified**: 2026-07-09 | **Last Amended**: 2026-07-09
