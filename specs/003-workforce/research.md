# Phase 0 Research — 003-workforce

Resolves the design choices the spec deferred to the plan. Format: Decision · Rationale · Alternatives rejected.

## R1 — The assembler is a deterministic script, not an LLM session

**Decision.** `extensions/workforce/extension/scripts/assemble.py` implements `agent-library-schema.md` §3 verbatim (base lookup by `(type, specialization)`; candidate skills by tag intersection; rank by Jaccard → `success_rate` → `version` → `id`; inject `first 3 of (forced ++ ranked)`; grant union; D48 guard; FR-022 `library|built` marks). It runs with **no model** and is the sole authority for matching; post-council (S08) it **writes the `## Workforce Gate` roster table itself** — a tool-permission fact, not a prose promise — and **total-orders every set-typed intermediate (the grant union above all) before serialization** (S01), so the roster is byte-reproducible. The `agent-creator` (skill-builder) session fires **only on a ∅-match**, to author one `SKILL.md`.

**Rationale.** SC-005 requires byte-identical rosters on gap-free runs. Only code can guarantee that; an LLM ranking is not reproducible, and even Python's own `set` iteration is `PYTHONHASHSEED`-dependent unless total-ordered (S01). This is the load-bearing decision of the whole feature — it is why one artifact (`categorization.md`) can be a non-reproducible LLM product while the roster built from it is byte-reproducible.

**Alternatives rejected.** (a) *LLM does the matching* — fails SC-005 outright. (b) *Pure Bash + `yq`/`awk`* — the §3-step-4 total-order tie-break (`id` ascending, "no ties") is fragile in shell sort pipelines; a locale- or flag-dependent sort silently breaks determinism. Python's stable, explicit `sorted(key=...)` is exact and unit-testable — and the S01 total-order is trivial there, fragile in shell.

## R2 — Frontmatter parsing: one shared, unit-tested stdlib module (S21), not a PyYAML dependency

**Decision.** Parse the `specseyal:` frontmatter block with **one shared `frontmatter.py` module** (S21) — a small, targeted parser over the known closed shape (the fixed keys of `agent-library-schema.md` §1.1 / `skill-module.md` §1), Python stdlib only — **imported by both `assemble.py` and `validate-skill.py`**, never two hand-rolled copies. No third-party YAML dependency added; Python 3 is already established by graphify (no new runtime, S19).

**Rationale.** Subscription-only build hygiene favors zero new install-time deps beyond what graphify already vendors. The frontmatter shape is a **closed, contract-defined** structure (not arbitrary YAML), so a full parser is unnecessary. A *second* hand-rolled parser is the same silent-divergence hazard that motivated rejecting Bash for the matcher (S21) — so the module is unit-tested independently. `body_sha256` uses the `agent-library-schema.md` §2 reference definition (`sed '1,/^---$/d; 1,/^---$/d' | shasum -a 256`).

**Alternatives rejected.** (a) *PyYAML* — a real dependency for a closed shape; rejected on hygiene. (b) *Hand-rolled full YAML* — over-engineering; the contract shape is fixed. (c) *Two separate parsers, one per script* — the divergence hazard S21 exists to close.

## R3 — Categorizer: a Sonnet session + a code cap-validator

**Decision.** `/speckit-categorize` dispatches one Sonnet `categorizer` session that reads `tasks.md` + `plan.md` and emits the categorization; then `validate-categorization.py` (code) checks coverage (all four fields, closed-enum membership) and the `general ≤ 20%` cap, failing the phase (no write) on breach.

**Rationale.** `specialization` is interpretive (plan stack + spec domain — taxonomy §1), so the categorizer needs inference (Sonnet, D18). But the cap (FR-004) must not be the LLM policing itself — it is a hard evidentiary floor, so it is **code** (D58-5a). `type` + `preserves_behavior` follow the mechanical derivation rules over the graphify signals already in `tasks.md`.

**Alternatives rejected.** (a) *Fully scripted categorizer* — `specialization` cannot be derived from graphify signals (the asymmetry that justifies two axes, taxonomy §1). (b) *LLM self-enforces the cap* — a lazy/over-`general` run could self-certify; the cap must be mechanical.

## R4 — Skill builder: dispatched on ∅-match, authored by a Sonnet subagent, validated by code

**Decision.** When `assemble.py` reports a ∅-match (candidate set empty, `tags ≠ ∅`), the `/speckit-agent-assign` command dispatches a Sonnet `skill-builder` subagent — holding the **declared `web_search` grant (D60, see R6)** — that authors ONE `SKILL.md` (additive-only body, `skl_` id, semver, declared grants, `origin: generated`, `provenance.source_feature`), which `validate-skill.py` checks (**S1–S3, plus S04: the generated skill's tags MUST intersect the triggering task's tags**) before it is persisted to `.claude/skills/`; the builder checks the live `.claude/skills/` listing and hard-fails/renames on a name collision, never a silent skip (S07). Then `assemble.py` re-runs (gap-free) for the final roster.

**Rationale.** D40.2 (author a skill, not a bespoke agent) + D24 (flywheel persistence) + FR-006/007/008. Validation-before-persist guarantees additive-only (S3: "a skill may forbid more; never permit more") so an injected skill can never make an agent less safe than its base. The S04 tag-intersection closes a real defect the council found — a structurally-valid skill whose tags miss the triggering task leaves the gap provably open.

**Alternatives rejected.** (a) *Author a whole bespoke agent* — the pre-D40 design; grows 88 near-empty lanes instead of composable parts. (b) *Persist without validation* — a non-conforming skill could break assembly determinism or leak a grant.

## R5 — Seed library scope: 7 bases + 5 skills

**Decision.** 7 base specialists (4 dogfood-backed lanes + 2 worked-example-only lanes + `agt_generic` fallback) and 5 seed skills (incl. the existing `refactor-discipline`). The two worked-example-only bases (`agt_backend_service`, `agt_data_persistence`) carry **`provisional: true`** (S11) so the weaker evidence basis is visible library metadata, not silent. Full set, the type-coverage matrix (S16), and rationale in [plan.md § Seed Library](./plan.md).

**Rationale.** Fitted to the only real evidence that exists — the 001 and 002 categorizations — plus the taxonomy worked-example cluster. Under-seeding (fewer lanes) forces more `agt_generic` fallbacks that under-serve real tasks; over-seeding invents lanes with no evidence (OQ6 overfit risk). Absent lanes fall to `agt_generic` + a reported empty lane — honest, and it earns each lane its first evidence. Marking the two thin lanes `provisional` (S11) keeps the uneven evidence honest without dropping the lanes.

**Alternatives rejected.** (a) *Only `refactor-discipline`* (docs/05's minimum) — leaves every 001/002-style task on `agt_generic`, defeating the base-specialist point. (b) *All 11 specializations seeded* — 5 lanes with zero evidence; contradicts "an unexercised enum value is a guess" (taxonomy §5).

## R6 — `web_search` GRANTED to the skill-builder role (D60, owner ruling at round-1 triage)

**Decision.** The skill-builder role **declares `web_search`** — the system's **first elevated grant** (D41). The builder puts `grants: [web_search]` in its **skill-module frontmatter** (A-2 — a skill-declared grant, not a role-level ambient default); it **surfaces on every roster whose assembly includes the builder path** (003's own workforce gate displays it — the first elevated grant a human approves, `artifact-layout.md` §8 W2); and any builder dispatch that searched records `elevated_grants: ["web_search"]` in its trace (D43). **S17's stale-knowledge flag ships as a complement:** authoring a module for a post-cutoff framework *without* searching stamps `provenance.stale_risk: true`. The grant lands in `workforce-config.yml` as `skill_builder.web_search: true`.

> **Supersession note.** Phase-0 (this row) and the plan both **recommended Option A (no grant)**; the owner **overruled at round-1 triage → D60** and granted it. This row is reconciled to the ruling.

**Rationale (owner, D60).** A builder authoring skills for post-cutoff frameworks *without* search produces **confidently-stale** modules — the exact failure A-2's grant machinery exists to make visible and governable. Granting search + flagging non-search is the honest resolution. The audit chain holds: the grant is **skill-declared → gate-visible → trace-recorded**, so network reach in the system is still 100% accounted for.

**Alternatives rejected.** *Option A (no grant)* — the plan's earlier recommendation; leaves the builder unable to consult current docs, so it authors stale skills silently for frameworks past the model's training cutoff. Retired by D60.

## R7 — Phase-commit coupling: the `workforce` extension registers `git.commit` hook points (D57 S1, S25)

**Decision.** The **single `workforce` extension** (S10) declares, in its **own** `extension.yml`, `after_<phase>` hook points targeting `speckit.git.commit` (`after_categorize` → `commit categorize(<id>): …`; `after_agent-assign` → `commit agents(<id>): …`). These fire-points are **registered in `workforce/extension.yml` and dispatched by the installed registry** (S25 — named explicitly, not assumed to "just work" by analogy; the `after_council_approve` precedent is invoked from the registry, not its command file). No edit to the git extension's source for the phase commits.

**Rationale.** Every phase needs a phase-tagged commit (D25), but the git ext has no `after_categorize`/`after_agent-assign` hooks. D57 S1 prefers a hook point over a source edit; an extension registering a hook that targets another extension's command is clean composition through the shared registry (`.specify/extensions.yml`), the merge-not-overwrite file. Reinstall-survival tested (D57 S3).

**Alternatives rejected.** (a) *Edit the git ext to add the two commit hooks* (D57 S2) — a source edit into a foreign extension when a hook point suffices; S1 is preferred. (b) *No commit hook* — leaves categorize/agent-assign phases uncommitted, breaking the phase-tagged trail (D25). *(Contrast R8: the workforce **gate-write** path is the one place a git-ext source edit is unavoidable and correct — and it lives in git-ext's own source, D57 S2.)*

## R8 — Workforce-gate binding: git-ext generalizes `on-council-approve.sh` → `on-gate-approve.sh` (S02/S13, D55/FR-008)

**Decision.** `/speckit-workforce-approve` (S13 — the new third command) records the human signature in `## Workforce Gate` and fires **`after_workforce_approve`**, which the git extension handles by running its **generalized, gate-agnostic `on-gate-approve.sh workforce`** → `gates.sh write workforce` → binds `tasks.md` + `assignment.md @ <sha>` into git-ext-owned `gates.yml`. The generalization is a rename+parameterize of git-ext's own `on-council-approve.sh` (hardcoded to `gates.sh write council`) **in git-ext's own source** (D57 S2; `gates.yml` stays git-ext-owned per D55/Q1). The already-registered `before_implement` `verify-gate` (`gate: workforce`) then passes, unlocking `/speckit-implement-parallel`. **git-ext must be reinstalled** after this edit; the S07/S17 reinstall-survival regression proves both gate wirings still fire.

**Rationale.** The council found (**S02, blocking**, verified by 3 members reading the *installed* scripts) that git-ext's gate-record hook was **council-only** — nothing recorded the workforce binding, so `verify-gate` failed closed and `before_implement` was unreachable. `gates.sh` **already knows** `write workforce` (`tasks.md`+`assignment.md` — the sibling block, preserved across writes), so the fix is narrow: parameterize `on-gate-approve.sh` by a `{council|workforce}` arg and register `after_workforce_approve`. Keeps principle-I clean — still a single writer of `gates.yml` (git-ext), reached via a hook, not a second writer.

**Alternatives rejected.** (a) *The pre-council design — bind via the existing `verify-gate` hook while the assign phase writes nothing* — this **was** the S02 defect: `verify-gate` **reads** a binding, nothing **wrote** it, so the gate was unreachable. (b) *A new binding record owned by the `workforce` extension* — a second writer of `gates.yml`, duplicating D55/Q1's design.
