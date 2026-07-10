# Phase 0 Research — 003-workforce

Resolves the design choices the spec deferred to the plan. Format: Decision · Rationale · Alternatives rejected.

## R1 — The assembler is a deterministic script, not an LLM session

**Decision.** `extensions/agents/extension/scripts/assemble.py` implements `agent-library-schema.md` §3 verbatim (base lookup by `(type, specialization)`; candidate skills by tag intersection; rank by Jaccard → `success_rate` → `version` → `id`; inject `first 3 of (forced ++ ranked)`; grant union; D48 guard; FR-022 `library|built` marks). It runs with **no model** and is the sole authority for matching. The `agent-creator` session only *dispatches* skill-building and *writes* the artifact.

**Rationale.** SC-005 requires byte-identical rosters on gap-free runs. Only code can guarantee that; an LLM ranking is not reproducible. This is the load-bearing decision of the whole feature — it is why one artifact (`categorization.md`) can be a non-reproducible LLM product while the roster built from it is byte-reproducible.

**Alternatives rejected.** (a) *LLM does the matching* — fails SC-005 outright. (b) *Pure Bash + `yq`/`awk`* — the §3-step-4 total-order tie-break (`id` ascending, "no ties") is fragile in shell sort pipelines; a locale- or flag-dependent sort silently breaks determinism. Python's stable, explicit `sorted(key=...)` is exact and unit-testable.

## R2 — Frontmatter parsing: a minimal stdlib parser, not a PyYAML dependency

**Decision.** Parse the `specseyal:` frontmatter block with a small, targeted parser over the known shape (the fixed keys of `agent-library-schema.md` §1.1 / `skill-module.md` §1), in the Python stdlib only. No third-party YAML dependency added.

**Rationale.** Subscription-only build hygiene favors zero new install-time deps beyond what graphify already vendors. The frontmatter shape is a **closed, contract-defined** structure (not arbitrary YAML), so a full parser is unnecessary. `body_sha256` uses the `agent-library-schema.md` §2 reference definition (`sed '1,/^---$/d; 1,/^---$/d' | shasum -a 256`).

**Alternatives rejected.** (a) *PyYAML* — a real dependency for a closed shape; rejected on hygiene. (b) *Hand-rolled full YAML* — over-engineering; the contract shape is fixed.

## R3 — Categorizer: a Sonnet session + a code cap-validator

**Decision.** `/speckit-categorize` dispatches one Sonnet `categorizer` session that reads `tasks.md` + `plan.md` and emits the categorization; then `validate-categorization.py` (code) checks coverage (all four fields, closed-enum membership) and the `general ≤ 20%` cap, failing the phase (no write) on breach.

**Rationale.** `specialization` is interpretive (plan stack + spec domain — taxonomy §1), so the categorizer needs inference (Sonnet, D18). But the cap (FR-004) must not be the LLM policing itself — it is a hard evidentiary floor, so it is **code** (D58-5a). `type` + `preserves_behavior` follow the mechanical derivation rules over the graphify signals already in `tasks.md`.

**Alternatives rejected.** (a) *Fully scripted categorizer* — `specialization` cannot be derived from graphify signals (the asymmetry that justifies two axes, taxonomy §1). (b) *LLM self-enforces the cap* — a lazy/over-`general` run could self-certify; the cap must be mechanical.

## R4 — Skill builder: dispatched on ∅-match, authored by a Sonnet subagent, validated by code

**Decision.** When `assemble.py` reports a ∅-match (candidate set empty, `tags ≠ ∅`), the assign command dispatches a Sonnet `skill-builder` subagent that authors ONE `SKILL.md` (additive-only body, `skl_` id, semver, declared grants, `origin: generated`, `provenance.source_feature`), which `validate-skill.py` checks (S1–S3) before it is persisted to `.claude/skills/`; then `assemble.py` re-runs (gap-free) for the final roster.

**Rationale.** D40.2 (author a skill, not a bespoke agent) + D24 (flywheel persistence) + FR-006/007/008. Validation-before-persist guarantees additive-only (S3: "a skill may forbid more; never permit more") so an injected skill can never make an agent less safe than its base.

**Alternatives rejected.** (a) *Author a whole bespoke agent* — the pre-D40 design; grows 88 near-empty lanes instead of composable parts. (b) *Persist without validation* — a non-conforming skill could break assembly determinism or leak a grant.

## R5 — Seed library scope: 7 bases + 5 skills

**Decision.** 7 base specialists (6 evidence-backed lanes + `agt_generic` fallback) and 5 seed skills (incl. the existing `refactor-discipline`). Full set and rationale in [plan.md § Seed Library](./plan.md).

**Rationale.** Fitted to the only real evidence that exists — the 001 and 002 categorizations — plus the taxonomy worked-example cluster. Under-seeding (fewer lanes) forces more `agt_generic` fallbacks that under-serve real tasks; over-seeding invents lanes with no evidence (OQ6 overfit risk). Absent lanes fall to `agt_generic` + a reported empty lane — honest, and it earns each lane its first evidence.

**Alternatives rejected.** (a) *Only `refactor-discipline`* (docs/05's minimum) — leaves every 001/002-style task on `agt_generic`, defeating the base-specialist point. (b) *All 11 specializations seeded* — 5 lanes with zero evidence; contradicts "an unexercised enum value is a guess" (taxonomy §5).

## R6 — `web_search` for the skill-builder role: Option A (no grant) in v1

**Decision.** The builder role does **not** declare `web_search` in v1. Full both-options costing in [plan.md § The web_search grant question](./plan.md). The council decides at plan review.

**Rationale.** The system's first elevated grant should be skill-declared and gate-visible (D41), not a role-level default on a session that runs before the gate (A-2/D44). Trivially reversible.

**Alternatives rejected.** *Option B (builder declares `web_search`)* — introduces the one network reach not visible on any workforce-gate roster; kept as a fallback **with** a mandatory builder-run trace flag + roster note if the council prefers it.

## R7 — Phase-commit coupling: categorize/agents register `git.commit` hook points (D57 S1)

**Decision.** The `categorize` and `agents` extensions each declare, in their **own** `extension.yml`, an `after_<phase>` hook pointing at `speckit.git.commit` (`after_categorize` → `commit categorize(<id>): …`; `after_agent-assign` → `commit agents(<id>): …`). No edit to the git extension's source.

**Rationale.** Every phase needs a phase-tagged commit (D25), but the git ext currently has no `after_categorize`/`after_agent-assign` hooks. D57 S1 prefers a hook point over a source edit; an extension registering a hook that targets another extension's command is clean composition through the shared registry (`.specify/extensions.yml`), the merge-not-overwrite file. Reinstall-survival tested (D57 S3).

**Alternatives rejected.** (a) *Edit the git ext to add the two hooks* (D57 S2) — a source edit into a foreign extension when a hook point suffices; S1 is preferred. (b) *No commit hook* — leaves categorize/agent-assign phases uncommitted, breaking the phase-tagged trail (D25).

## R8 — Workforce-gate freshness binding reuses the git ext's `gates.yml` (D55/FR-008)

**Decision.** The workforce gate binds `tasks.md` + `assignment.md` via the existing `before_implement` `verify-gate` hook (already registered, `gate: workforce`); the assign phase writes nothing into `gates.yml` (git-ext-owned, D55). The `## Workforce Gate` section carries the well-known-path reference by convention (D55).

**Rationale.** The git ext already ships the workforce-gate `verify-gate` hook (`extensions.yml` `before_implement`, `gate: workforce`) — the pair consumes it, no new binding machinery. Keeps principle-I clean (no second writer of `gates.yml`).

**Alternatives rejected.** *A new binding record owned by the agents ext* — duplicates D55's design and adds a second writer.
