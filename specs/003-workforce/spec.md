# Feature Specification: The Workforce Pair — Task Categorization & Agent Assembly

**Feature Branch**: `003-workforce`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "M3 — the workforce pair: task categorization + agent assembly (speckit-ext-categorize + speckit-ext-agents: categorizer, skill builder, assembler), delivered as one feature. Owner rulings encoded."

> **Reading note.** This feature is the M3 "workforce pair" (docs/00 §3, docs/05 M3): two pipeline extensions delivered as **one feature** — **`speckit-ext-categorize`** (the categorizer) and **`speckit-ext-agents`** (the skill builder + the assembler/assigner). Its "users" are the engineer driving the SDD pipeline and the human who signs the workforce gate. The requirements describe **observable behavior and the artifacts produced** (`categorization.md`, new `SKILL.md` modules, `agents/assignment.md` with its `## Workforce Gate` roster); the *how* — session prompts, the ranking code, hook wiring — is deferred to `/speckit-plan`. Decisions already ratified in `docs/90` (D9, D16–D18, D24, D37, D40–D44, D48, D49, D56) and the M0 contracts (`taxonomy-v0.md` **BLESSED**, `agent-library-schema.md`, `skill-module.md`, `artifact-layout.md` §8, `trace-schema.md`) appear under **Constraints & Assumptions** as givens citing their D-row, not open choices — this is a dogfood build of a *designed* component (D40 blessed), not greenfield. Unlike `002`, this extension **does AI work at runtime**: the categorizer and skill builder are model sessions (Sonnet, D18), so subscription/model policy (D28/D18) governs both its build *and* its runtime.
>
> The categorizer and the assembler **PROPOSE**; the human **signs** at the workforce gate (D9). Nothing here decides autonomously unless a feature's `profile.yaml` sets `gates.workforce.mode: auto` (legal only under `full_auto`, `profile-schema.md`).

## Clarifications

### Session 2026-07-10

- Q: How is the determinism guarantee (FR-015 / SC-005) scoped, given the skill builder is an LLM that authors new skills (not byte-reproducible) and mutates the library mid-run? → A: **Assembly-only, against a fixed library snapshot.** Determinism is a property of the assignment *algorithm* — the same `categorization.md` + the same library yields the same roster. A run that invokes the skill builder (∅-match, FR-006) is **explicitly excluded** from the byte-identical claim: LLM authorship is not byte-reproducible and the run grows the library; determinism for such a run means that re-running against the *resulting* library reproduces the roster. SC-005 is therefore measured on **gap-free** runs. (Consistent with D24: the flywheel persists generated skills, which then become part of the fixed library deterministic assembly consumes.)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Every task is classified by the blessed taxonomy (Priority: P1)

After `/speckit-tasks` (and `/speckit-analyze`) produce the final `tasks.md`, the engineer runs the categorizer. It reads `tasks.md` + `plan.md` and writes `categorization.md`: every task tagged with exactly one `type`, exactly one `specialization`, the boolean `preserves_behavior`, and any number of free `tags`, per the blessed taxonomy v0. If more than 20% of the feature's tasks fall to `general`, the run FAILS loudly and writes nothing — the categorization is under-evidenced and the pipeline stops here until a conforming run is produced.

**Why this priority**: Categorization is the assembler's only input; without it, no roster can be assembled. It is the foundational half of the pair.

**Independent Test**: Run the categorizer against a real `tasks.md` → a `categorization.md` in which every task carries all four taxonomy fields, `general ≤ 20%`, and every value is a member of the closed enums.

**Acceptance Scenarios**:

1. **Given** a `tasks.md` with N tasks and a `plan.md` naming the stack, **When** the categorizer runs, **Then** `categorization.md` tags all N tasks with one `type`, one `specialization`, a `preserves_behavior` boolean, and tags — and nothing in `tasks.md` is mutated.
2. **Given** a feature whose tasks resist classification such that `count(general) > 0.20 × N`, **When** the categorizer runs, **Then** it FAILS, writes no `categorization.md`, and reports the cap breach — the phase does not complete.
3. **Given** a task whose files all already exist in the graph and add no public surface, **When** it is categorized, **Then** `preserves_behavior: true` (derived mechanically, not guessed).

---

### User Story 2 - Each task assembles into a specialized agent, and the human signs the roster (Priority: P1)

The engineer runs the assembler. It reads `categorization.md` + the library and proposes, per task, one assembled agent = a base specialist (chosen by `(type, specialization)`) + up to 3 injected skills (chosen and ranked by tags, additive-only). It writes `agents/assignment.md` carrying a `## Workforce Gate` roster: one row per assembled agent showing its model, its skills (`id@version`), and — mandatory — its elevated-grant set. The human reads the roster and approves, approves-with-notes, or rejects. Approval is what unlocks implementation.

**Why this priority**: The roster plus its human sign-off *is* the workforce gate (D9) — the economic guard before implementation spends tokens, and the moment network access is approved (D41).

**Independent Test**: Run the assembler on a `categorization.md` → an `assignment.md` whose `## Workforce Gate` roster lists every task under exactly one assembled agent with model / skills / elevated-grants columns; a human `approved` section unlocks `/speckit-implement-parallel`.

**Acceptance Scenarios**:

1. **Given** a categorized task `(type, specialization, tags)`, **When** the assembler runs, **Then** it selects exactly one base lane, injects ≤ 3 tag-ranked skills, and the row's elevated-grant set equals the union of those skills' declared grants.
2. **Given** a task carrying the `prompt` tag, **When** it is assembled, **Then** it lands on an implementation specialist under the D18 Sonnet floor — never a docs-exempt non-Sonnet specialist.
3. **Given** more than 3 candidate skills for a task, **When** it is assembled, **Then** exactly 3 are injected (top tag-rank) and the dropped candidates are logged, never silently discarded.
4. **Given** an assembled roster, **When** the human appends an `approved` `## Workforce Gate` section, **Then** `/speckit-implement-parallel` is unlocked; a `rejected` section sends the roster back for reassignment.
5. **Given** the same `categorization.md` and the same library, **When** the assembler runs twice, **Then** it proposes the identical roster (determinism).

---

### User Story 3 - A coverage gap grows the library, not a bespoke agent (Priority: P2)

When a task's tags match no existing skill, the skill builder authors ONE new `SKILL.md` module (additive-only) and persists it into the library with provenance metadata (`origin: generated`, the source feature recorded). It is now a candidate for future tasks. Promotion to the trusted set is a separate, manual step in v1.

**Why this priority**: This is the flywheel (D24) — the library's only self-evolving component. It matters, but the pair is already viable (US1 + US2) against a static seed library; the builder handles the long tail.

**Independent Test**: Give a task a genuinely novel tag with no covering skill → a new `.claude/skills/<name>/SKILL.md` appears, valid per `skill-module.md`, `origin: generated`, `source_feature` set — and injecting it never makes an agent less safe than its base.

**Acceptance Scenarios**:

1. **Given** a task with tags and an empty skill-candidate set, **When** the assembler runs, **Then** the skill builder authors one conforming `SKILL.md` (additive-only body, declared grants, `skl_` id, semver) rather than a bespoke agent.
2. **Given** a newly generated skill, **When** it is persisted, **Then** its provenance records `origin: generated` and the source feature, and promotion to `origin: promoted` requires a separate manual action (no auto-promotion on stats in v1).

---

### User Story 4 - Implementation consumes the roster, and every dispatch is auditable (Priority: P2)

`/speckit-implement-parallel` reads the approved `assignment.md` and dispatches each task's assembled agent. Every dispatch leaves a trace carrying the assembly: the injected skills (`id@version`) and the elevated grants that were active — the same set the human approved at the gate.

**Why this priority**: It closes the loop (the M3 exit criterion), makes the flywheel computable (skill stats derive from these traces), and makes the grant approval auditable end-to-end (D41/D43).

**Independent Test**: With an approved `assignment.md`, run implementation → each per-task trace record carries `skills: [{id, version}]` and `elevated_grants: [...]` matching the approved roster row.

**Acceptance Scenarios**:

1. **Given** an approved roster, **When** implementation dispatches a task's agent, **Then** the dispatch's trace record names the injected skills by `id@version` and the elevated grants active, with `agent_id` = the assembled base.
2. **Given** a task assembled with zero injected skills, **When** it is dispatched, **Then** its trace carries `skills: []` and `elevated_grants: []`.

---

### Edge Cases

- **Over-cap `general`** → categorization FAILS, writes nothing, stops the pipeline (a failure, not a warning — D42).
- **No base lane matches `(type, specialization)`** (including every `general`-specialized task, whose escape-hatch guarantees no lane) → assemble onto the generic base and REPORT the empty lane on the roster (a gate-visible fact, not a silent fallback); the tags still select or build skills on top.
- **More than 3 candidate skills** → inject the top 3 by tag-rank; log the dropped ones.
- **`preserves_behavior: true`** → auto-inject `refactor-discipline`, counting against the cap of 3 (taxonomy §2.3).
- **`prompt`-tagged task** → held to the D18 Sonnet floor by a code guard in the assigner (D48).
- **Contradictory skills injected together** (e.g. move-fast + be-careful) → not machine-detectable (skill-module S4); the cap bounds the blast radius and the human catches it at the gate.
- **Empty / absent library** → every task is a gap; the builder authors skills (bounded by the count of distinct tag-clusters), and the roster shows generic bases where no lane exists.
- **A task whose `mutates=` hits the shared/mutable set** → may be assigned an agent, never inlined as orchestrator glue (assignment guard, taxonomy §2.2), and vice versa.

## Requirements *(mandatory)*

### Functional Requirements

**Categorizer (`speckit-ext-categorize`)**

- **FR-001**: The categorizer MUST run as a separate session (session-boundary rule) that reads `tasks.md` + `plan.md` and writes `categorization.md` and no other artifact (D37).
- **FR-002**: It MUST tag every task with exactly one `type` (of the 8), exactly one `specialization` (of the 11), a boolean `preserves_behavior`, and zero or more free `tags`, every enum value being a member of the blessed taxonomy v0.
- **FR-003**: It MUST derive `type` and `preserves_behavior` from graphify's emitted signals (the mechanical axis) and `specialization` from `plan.md`'s declared stack + the spec's domain (the interpretive axis).
- **FR-004**: It MUST FAIL — writing no `categorization.md` and not completing the phase — when `count(general) > 0.20 × count(tasks)` (the cap is a floor on evidence, D42).
- **FR-005**: The categorizer PROPOSES; it MUST NOT itself sign off the categorization — acceptance is the human's at the workforce gate (D9).

**Skill builder (`speckit-ext-agents`)**

- **FR-006**: When a task's tags yield an empty skill-candidate set, the builder MUST author exactly one new `SKILL.md` module (not a bespoke agent — D40.2) conforming to `skill-module.md`.
- **FR-007**: A generated module MUST be additive-only (no negation/override of base behavior; obligations added, never relaxed — S1–S3) and MUST declare its tool grants explicitly (`grants`, D41).
- **FR-008**: The builder MUST persist a generated module into the library with provenance (`origin: generated`, `provenance.source_feature` = this feature) so it becomes a candidate for future tasks (the flywheel, D24).
- **FR-009**: Promotion of a generated module to the trusted set (`origin: promoted`) MUST be a separate manual action in v1 — never automatic on accumulated stats.

**Assembler / assigner (`speckit-ext-agents`)**

- **FR-010**: The assembler MUST run as a separate session that reads `categorization.md` + the library (`.claude/agents/`, `.claude/skills/`) and writes `agents/assignment.md` and no other artifact.
- **FR-011**: Per task, it MUST select exactly one base specialist by `(type, specialization)` and inject at most 3 skill modules selected/ranked by tags — additive-only (A-1, D40). What the cap trims MUST be logged, never silently dropped.
- **FR-012**: `preserves_behavior: true` MUST auto-inject the `refactor-discipline` skill, counting against the cap of 3 (taxonomy §2.3).
- **FR-013**: The assembled agent's elevated-grant set MUST equal the union of its injected skills' declared grants — nothing else grants anything (D41).
- **FR-014**: A `prompt`-tagged task MUST be assembled onto an implementation specialist under the D18 Sonnet floor, enforced as a **code-level guard** in the assigner — never onto a docs-exempt non-Sonnet specialist (D48).
- **FR-015**: **Assembly** MUST be deterministic against a **fixed library snapshot**: the same `categorization.md` + the same library yields the identical roster every run. Determinism is a property of the assignment *algorithm*, not of the skill builder — a run that invokes the builder (∅-match, FR-006) authors new skills (LLM, not byte-reproducible) and grows the library; once those skills exist, re-runs are deterministic (see Clarifications 2026-07-10).
- **FR-016**: When no base lane matches `(type, specialization)`, the assembler MUST fall back to the generic base AND report the empty lane on the roster (never a silent fallback).

**Workforce gate & roster (`agents/assignment.md`)**

- **FR-017**: `agents/assignment.md` MUST carry a `## Workforce Gate` section in the `artifact-layout.md` §8 format (D49/I-12): one row per assembled agent with Task(s), Assembled agent (base), Model, Skills (`id@version`), and a MANDATORY Elevated grants column.
- **FR-018**: The Elevated grants column MUST never be omitted — approving the roster is approving network/tool access (D41); the core toolset is assumed and not listed (D44).
- **FR-019**: The Model column MUST make the D18/D48 Sonnet floor auditable for every implementation row.
- **FR-020**: The gate section MUST record the human's decision (`approved` | `approved-with-notes` | `rejected`); `approved`/`approved-with-notes` unlocks `/speckit-implement-parallel`, a `rejected` returns the roster for reassignment (artifact-layout §8 W3). Under `gates.workforce.mode: auto` (only within `full_auto`) the assigner writes the section itself.

**Loop closure (traces)**

- **FR-021**: Every implementation dispatch of an assembled agent MUST leave a trace record carrying `skills: [{id, version}]` (the injected skills, `[]` if none) and `elevated_grants: [...]` (the gate-approved set active), with `agent_id` = the assembled base (D43).

### Key Entities

- **Categorization (`categorization.md`)** — the categorizer's sole output: the task list, each task carrying `(type, specialization, preserves_behavior, tags)`. The categorize extension owns it and writes nothing else (D37).
- **Base specialist** (`.claude/agents/<name>.md`) — a curated-static lane definition selected by `(type, specialization)`; carries a model, no tags; does not evolve (D44).
- **Skill module** (`.claude/skills/<name>/SKILL.md`) — the library's unit of storage; additive-only; carries tags, declared grants, provenance, stats; the only evolving entry (D40, D44).
- **Assembled agent** — not a stored file: `base + ≤3 skills`, elevated grants = the union of the skills' grants; composed at assignment time (D40).
- **Roster / `## Workforce Gate`** (in `agents/assignment.md`) — the proposed assembly for every task plus the human's decision; shows model, skills, elevated grants (D49, artifact-layout §8).
- **Seed library** — the initial set of base specialists + skills. **Deferred to the plan** (the plan proposes it, the council reviews it).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every task in a categorized feature carries exactly one `type`, one `specialization`, a `preserves_behavior` boolean, and its tags — 100% coverage — with all enum values inside the closed taxonomy, or the run fails.
- **SC-002**: The `general` cap holds: a feature is categorized only if `count(general) ≤ 0.20 × count(tasks)`; an over-cap attempt produces no `categorization.md`.
- **SC-003**: Every categorized task appears in exactly one roster row naming a base, its injected skills, its model, and its elevated-grant set — no row omits the grants column.
- **SC-004**: No assembled agent exceeds `base + 3` skills; whenever the cap trims, the dropped skills are recorded.
- **SC-005**: Assembly is reproducible on **gap-free** runs — two runs over the same `categorization.md` + the same fixed library (no ∅-match skill-building) produce byte-identical rosters. Runs that invoke the skill builder are excluded from the byte-identical claim (LLM authorship); their determinism is that re-running against the *resulting* library reproduces the roster (Clarifications 2026-07-10).
- **SC-006**: No `prompt`-tagged task is ever assembled below the Sonnet floor (the D48 guard holds on 100% of such tasks).
- **SC-007**: A task with a tag no skill covers yields exactly one new persisted `SKILL.md` with `origin: generated` and its source feature recorded.
- **SC-008**: Every implementation dispatch of an assembled agent leaves a trace carrying the injected skills (`id@version`) and elevated grants that match its approved roster row.
- **SC-009** (**M3 exit**): a real feature runs `categorize → assign → workforce-gate (human approves) → implement-parallel` end-to-end, with the roster consumed by implementation.

## Constraints & Assumptions

Every entry is a ratified given — a `docs/90` D-row or an M0 contract — per the D46 spec-hygiene rule, not an open choice.

- **Taxonomy v0 is a closed, blessed enum** (D42, `taxonomy-v0.md`): 8 types × 11 specializations, `general` capped, `preserves_behavior` a modifier. The categorizer targets it; adding a value is a D-row, not an edit.
- **The library's unit of storage is the skill; an agent is an assembly** (D40, A-1): `base + ≤3 skills`, additive-only. Bases are curated-static; skills alone evolve (D44).
- **Tool grants are per-skill and gate-visible** (D41): the assembled agent's elevated grants = the union of its skills' declarations; the roster displays them (D44 core-vs-elevated terms).
- **The D48 guard is in scope for this feature**: `prompt`-tagged tasks hold the Sonnet floor, enforced in the assigner as code (D48 booked this guard to M3).
- **`categorization.md` and `agents/assignment.md` are single-writer artifacts** owned by the categorize and agents extensions respectively (D37, `artifact-layout.md` §6); the categorizer never mutates `tasks.md`.
- **The workforce-gate record format is `artifact-layout.md` §8** (D49, resolving I-12): `## Workforce Gate` with the roster table and mandatory Elevated grants column.
- **Traces carry the assembly** (D43, `trace-schema.md` 1.1/1.2): `skills: [{id, version}]` + `elevated_grants: [...]`, `agent_id` = the base. Skill stats derive from these records (the flywheel).
- **Model policy** (D18): the categorizer and skill builder are mechanical/generative roles → Sonnet; implementation base specialists hold the Sonnet floor (`agent-library-schema.md` §4).
- **The flywheel persists generated skills; promotion is manual in v1** (D24): the single self-evolving component of year one (D44).
- **Autonomy** (D9, `profile-schema.md`): the workforce gate is the second gate-capable checkpoint; the categorizer and assembler PROPOSE, the human signs — unless `gates.workforce.mode: auto` under `full_auto`.
- **This feature's `profile.yaml` sets `council_tier: standard`** (D56): its plan's council review runs the cost-controlled tier, measured against the 5.25M `full` baseline.
- **Subscription-only** (D28): the categorizer and skill builder run on the Claude subscription; no `ANTHROPIC_API_KEY`.
- **Pipeline position** (owner ruling; docs/00 §3): `tasks → analyze → categorize → agent-assign → workforce-gate → implement`. **Reconciliation flagged:** the owner's order runs `analyze` *before* `categorize` (dogfood practice — `analyze` may patch `tasks.md` before it is categorized), whereas `artifact-layout.md` §2 currently lists `categorize` before `analyze`; the §2 row order is to be reconciled during this feature (a contract touch, not a new decision).

**OPEN — deferred to the plan; the council weighs it at plan review (deliberately *not* a `/speckit-clarify` target):**

- **Does the skill-builder role itself declare `web_search` — the system's first elevated grant (D41)?** The builder authors skills that may themselves declare `web_search`; to author them well it may need to consult current library/dependency docs. Granting the builder network access would be the first real network reach in the system and deserves council scrutiny. The spec poses it; the plan proposes an answer; the council decides at plan review.

**Deferred to the plan (not fixed in this spec):**

- The **seed library** — the seed base specialists and seed skills. The plan proposes the set; the council reviews it (docs/05 M3's "5–6 specialists" is indicative only).
