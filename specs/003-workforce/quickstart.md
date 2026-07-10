# Quickstart — 003-workforce validation

Runnable scenarios proving the workforce pair works end-to-end. Each maps to a success criterion. The **M3 exit test is SC-009 on `003` itself** (dogfood). References: [contracts/commands.md](./contracts/commands.md), [data-model.md](./data-model.md).

## Prerequisites

```bash
bash extensions/categorize/install.sh .    # → .specify/extensions/categorize/ + .claude/skills/speckit-categorize
bash extensions/agents/install.sh .        # → .specify/extensions/agents/ + seed library into .claude/agents/ (7) + .claude/skills/ (5)
# verify: /speckit-categorize and /speckit-agent-assign resolve; 7 agt-*.md + 5 skl skills present; refactor-discipline relocated from 000-sample
```

## Scenarios

### S1 — Categorize a real feature (US1 · SC-001)
```bash
/speckit-categorize        # after /speckit-tasks + /speckit-analyze on a real feature
```
**Expect:** `categorization.md` tags **every** task with one `type`, one `specialization`, a `preserves_behavior` bool, and tags; all enum values in the closed taxonomy; `tasks.md` byte-unchanged (D37). *(SC-001)*

### S2 — Over-cap fails loudly (US1 · SC-002 · FR-004)
Feed a `tasks.md` engineered so `count(general) > 0.20 × N`.
**Expect:** `validate-categorization.py` exits non-zero; **no `categorization.md` written**; the breach is reported; the phase does not complete. *(SC-002)*

### S3 — `preserves_behavior` is mechanical (US1 · FR-003)
A task whose every `files=` already exists in the graph and adds no public surface.
**Expect:** `preserves_behavior: true` — derived, not guessed.

### S4 — Assemble the roster (US2 · SC-003)
```bash
/speckit-agent-assign
```
**Expect:** `agents/assignment.md` with a `## Workforce Gate` roster — every task in exactly one row naming base · Model · Skills(`id@ver` + `library`/`built`) · **Elevated grants** (never omitted). *(SC-003)*

### S5 — Assembly cap holds, drops logged (US2 · SC-004 · FR-011)
A task with >3 tag-matching skills.
**Expect:** exactly 3 injected (top tag-rank); the dropped candidates **logged**, never silently discarded. *(SC-004)*

### S6 — Determinism on a gap-free run (US2 · SC-005 · FR-015/FR-022)
```bash
/speckit-agent-assign   # run twice over the same categorization.md + library
diff assignment.run1.md assignment.run2.md    # gap-free: roster has zero `built` marks
```
**Expect:** **byte-identical** rosters; the roster carries **zero `built`-marked skills** (the verifiable gap-free property, D58). *(SC-005)*

### S7 — Sonnet floor for `prompt` tasks (US2 · SC-006 · FR-014)
A `prompt`-tagged task (mechanically typed `docs`).
**Expect:** assembled onto a **Sonnet** implementation specialist (`agt_ai_agents`), never a docs-exempt non-Sonnet base; `assemble.py`'s code guard errors otherwise. *(SC-006)*

### S8 — A gap grows the library, not a bespoke agent (US3 · SC-007 · FR-006/008)
A task with a genuinely novel tag no skill covers.
**Expect:** exactly one new `.claude/skills/<name>/SKILL.md`, valid per `skill-module.md`, `origin: generated`, `source_feature: 003-workforce`; that skill marked `built` on this run's roster; promotion to `promoted` stays a separate manual step (FR-009). *(SC-007)*

### S9 — Additive-only is enforced (US3 · FR-007)
Attempt to persist a generated skill whose body negates/overrides the base (S1) or relaxes an obligation (S3).
**Expect:** `validate-skill.py` **rejects** it; not persisted.

### S10 — Loop closure: traces carry the assembly (US4 · SC-008 · FR-021)
```bash
/speckit-implement-parallel     # on the approved roster
```
**Expect:** each per-task dispatch trace carries `skills: [{id,version}]` and `elevated_grants: [...]` matching its approved roster row; `agent_id` = the assembled base; a zero-skill task carries `skills: []`, `elevated_grants: []`. *(SC-008)*

### S11 — Reinstall-survival (D57 S3)
```bash
bash extensions/agents/install.sh . && bash extensions/graphify/install.sh . && bash extensions/agents/install.sh .
# assert: seed library intact, a `built` skill from a prior run NOT clobbered, hooks still registered
```
**Expect:** the seed library and any generated skill survive a foreign-extension reinstall; the `after_categorize`/`after_agent-assign` hook points still fire. *(R5/I-14/D57)*

### S12 — M3 EXIT (SC-009)
Run the full chain on a real feature:
```bash
/speckit-tasks-graph → /speckit-analyze → /speckit-categorize → /speckit-agent-assign → [human signs ## Workforce Gate] → /speckit-implement-parallel
```
**Expect:** `categorize → assign → workforce-gate (human approves) → implement-parallel` end-to-end, the roster consumed by implementation. *(SC-009 — the M3 exit criterion)*

## Deterministic-assembly golden test (in `extensions/agents/test/run.sh`)

A committed `categorization.fixture.md` + a frozen library snapshot → `assemble.py` twice → assert byte-identical roster (SC-005) with a `prompt`-tagged task (SC-006) and a >3-candidate task (SC-004). Zero-AI, so CI-runnable without a model.
