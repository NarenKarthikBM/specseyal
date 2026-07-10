# Phase 1 Data Model — 003-workforce

Entities the pair reads and writes. Shapes are **defined by the M0 contracts** — this file states each entity's role, key fields, and validation, and cites the contract rather than re-specifying it.

## 1. Categorization record — one per task (in `categorization.md`)

The categorizer's sole output; `categorize` extension owns the file, writes nothing else (D37).

| Field | Domain | Derivation (taxonomy §1) | Validation |
|---|---|---|---|
| `task_id` | `T\d+` | from `tasks.md` | present, unique, 1:1 with tasks |
| `type` | one of **8** (`taxonomy-v0.md` §2) | mechanical — graphify `files=`/`deps=`/TDD position | closed enum |
| `specialization` | one of **11** incl. `general` (§4) | interpretive — `plan.md` stack + spec domain | closed enum |
| `preserves_behavior` | bool (§2.3) | mechanical — every `files=` exists ∧ no new public surface | bool |
| `tags` | list<kebab> (§6) | free — language/framework/protocol/sub-domain | lowercase kebab, may be `[]` |

**File-level validation (`validate-categorization.py`, code):** 100% task coverage; every enum value in-domain (SC-001); **`count(general) ≤ 0.20 × count(tasks)`** else FAIL, write nothing (FR-004/SC-002). File *format* is plan-level (D46 rule 3): a markdown table + a `## Cap Check` line stating `general N / total M (≤ 0.20M)`.

## 2. Base specialist — `.claude/agents/agt-*.md` (curated-static, D44)

Selected by `(type, specialization)`; **does not evolve**. Full format `agent-library-schema.md` §1.1. Seven seeded (plan.md § Seed Library).

- **Key fields:** `specseyal.kind: base`, `id: agt_…`, `taxonomy.type: [..]`, `taxonomy.specialization: <one>`, `model: sonnet` (enforced §4), core toolset `{Read,Write,Edit,Bash,Glob,Grep}`, **no `tags`**.
- **Validation (`agent-library-schema.md` §6):** `id` matches `^agt_…`, unique; `(type, specialization)` lane unique across bases; model rule holds; body non-empty; `body_sha256` correct.

## 3. Skill module — `.claude/skills/*/SKILL.md` (the evolving unit, D40)

Selected by `tags`; the library's unit of storage. Full format `skill-module.md`. Five seeded + any generated.

- **Key fields:** `specseyal.kind: skill`, `id: skl_…`, `version` semver, `origin ∈ {seed,generated,promoted}`, `taxonomy.tags: [..]` (non-empty, **no type/specialization**), `grants: []`-or-elevated (D41), `provenance.source_feature` (non-null iff generated/promoted), `stats` (derived cache), **no `model`**.
- **Validation (`validate-skill.py` = `skill-module.md` §6 + §3):** id `^skl_…` unique; semver; body satisfies **S1** (no negation), **S2** (no model/dispatch keys), **S3** (additive obligations only); `grants` disjoint from core; `origin`→`source_feature` rule.

## 4. Assembled agent — **not stored**, composed at assignment (D40)

`agent = base(model=sonnet) + ≤3 injected skills + grants(= ⋃ skills.grants)`. Produced by `assemble.py`; never a file. Its identity on a trace is `agent_id = base.id` (D43). The assembly cap is **3** (forced `refactor-discipline` counts, taxonomy §2.3); trimmed candidates are **logged** (FR-011/SC-004).

## 5. Roster row + `## Workforce Gate` — in `agents/assignment.md` (D49, `artifact-layout.md` §8)

One row per assembled agent (W1). Columns — all mandatory:

| Column | Source | Rule |
|---|---|---|
| Task(s) | categorization | each task in exactly one row (W1) |
| Assembled agent (base) | `assemble.py` base lookup | `agt_…`; `agt_generic` + **empty-lane note** when no lane matched (FR-016) |
| Model | base.model | Sonnet floor auditable (FR-019); D48 guard for `prompt` tasks |
| Skills (`id@ver`) | injected set | each marked **`library`** (in lib at run start) or **`built`** (this run) — **FR-022** |
| Elevated grants | `⋃ skills.grants` | **never omitted** (W2/FR-018); `none` when empty; core toolset never listed (D44) |

**Gate record:** `## Workforce Gate` with reviewer · `decision ∈ {approved, approved-with-notes, rejected}` · reviewed. `approved`/`approved-with-notes` unlocks implement; `rejected` returns for reassignment (W3/FR-020). Present iff `gates.workforce.mode: human` (W4); `auto` (only under `full_auto`) the assigner writes it.

**SC-005 gap-free check (D58):** a gap-free run's roster carries **zero `built`-marked skills** — a verifiable artifact property, not an assertion (FR-022).

## 6. Dispatch trace — one per implement dispatch (`trace-schema.md` §1, D43)

Not written by this pair, but its **shape is this pair's loop-closure contract** (FR-021/SC-008): each `implementer` record carries `agent_id = base`, `skills: [{id,version}]` (the injected set, `[]` if none), `elevated_grants: [...]` (the gate-approved union). `|skills| ≤ 3` (rule 5). Skill `stats` derive from these via `skill_success(id,version)` (§5) — the flywheel input.

## Entity flow

```
tasks.md ─(type,preserves_behavior mechanical)─┐
plan.md  ─(specialization interpretive)────────┴▶ categorization.md ─▶ assemble.py ─▶ roster row ─▶ ## Workforce Gate ─▶ implement trace ─▶ skill.stats (flywheel)
                                                                          │ ∅-match
                                                                          └▶ skill-builder ─▶ new SKILL.md ─▶ .claude/skills/ (marked `built`)
```
