# Phase 1 Contracts — Command Surface (003-workforce)

The two extensions expose two commands. Both obey the session-boundary rule (§2), single-writer ownership (§6/D37), and append one `traces.jsonl` record per model session (IV). Scripts are zero-AI (no trace).

---

## `/speckit-categorize` (extension: `categorize`)

| | |
|---|---|
| **Phase** | `categorize` (runs **after** `analyze` — D58) |
| **Session** | one Sonnet `categorizer` session + a zero-AI validator |
| **Context in** | `tasks.md` (post-analyze, with graphify signals), `plan.md` |
| **Artifact out** | `categorization.md` — **and nothing else** (D37; never mutates `tasks.md`) |
| **Trace** | one `categorizer` record (role=categorizer, model=sonnet) |

**Behavior**
1. Dispatch the `categorizer` Sonnet session → tags every task `(type, specialization, preserves_behavior, tags)` per taxonomy v0; `type`/`preserves_behavior` mechanical from graphify signals, `specialization` interpretive from plan+domain.
2. Run `validate-categorization.py`:
   - **coverage** — every task carries all four fields; every enum value in the closed set (SC-001), else FAIL.
   - **cap** — `count(general) > 0.20 × count(tasks)` ⇒ **exit non-zero, write no `categorization.md`, phase does not complete** (FR-004/SC-002).
3. On pass, write `categorization.md`; on fail, report the breach and stop the pipeline at categorize (Resumability III).

**Postconditions.** `categorization.md` exists ∧ validates ⇒ phase complete. `after_categorize` hook → `git.commit categorize(003-workforce): …` (research R7).

**Errors.** Over-cap → no artifact (FR-004). Un-enumerable value → FAIL (never invent a taxonomy value — that is a D-row, taxonomy §8).

---

## `/speckit-agent-assign` (extension: `agents`)

| | |
|---|---|
| **Phase** | `agent-assign` (after `categorize`) |
| **Session** | zero-AI `assemble.py`; **+** one-or-more Sonnet `skill-builder` sessions **only on ∅-match** (R2) |
| **Context in** | `categorization.md`, `.claude/agents/`, `.claude/skills/` |
| **Artifact out** | `agents/assignment.md` (roster + `## Workforce Gate`) — **and nothing else** in the feature tree; generated `SKILL.md` persists to the repo-root library (D24, outside the feature tree) |
| **Trace** | one `agent-creator` record per skill-builder session (none on a gap-free run — R2) |

**Behavior (deterministic core + gap handoff)**
1. `assemble.py` runs `agent-library-schema.md` §3 over `categorization.md` × library → per task: base by `(type, specialization)` (∅ ⇒ `agt_generic` + empty-lane note, FR-016); candidate skills by tag-intersection; force-inject `refactor-discipline` if `preserves_behavior`; rank (Jaccard→success_rate→version→id); inject **first 3**, **log dropped** (FR-011/SC-004); grants = union (FR-013); **D48 guard** — `prompt`-tagged ⇒ assert Sonnet base else error (FR-014/SC-006); mark each skill `library`/`built` (FR-022). Emits the roster + a ∅-match gap list.
2. **If gaps:** for each, dispatch a Sonnet `skill-builder` → author one additive-only `SKILL.md` → `validate-skill.py` (S1–S3, `skl_` id, semver, grants⊄core) → persist to `.claude/skills/` with `origin: generated`, `source_feature: 003-workforce` (FR-006/007/008); promotion stays manual (FR-009).
3. **Re-run `assemble.py`** (now gap-free over the grown library) → final roster; built skills carry the `built` mark.
4. Write `agents/assignment.md`: the roster table + `## Workforce Gate` (reviewer/decision/reviewed; Model + Elevated-grants mandatory — §8). Under `gates.workforce.mode: human` (this feature) the section is **pending human**; under `auto` (full_auto only) the assigner writes the decision (FR-020/W4).

**Determinism (FR-015/SC-005).** Two runs over the same `categorization.md` + the same library ⇒ byte-identical `agents/assignment.md` **when gap-free** (zero `built` marks). A gap run is excluded from byte-identity (LLM authorship); re-running against the *resulting* library reproduces it.

**Postconditions.** Roster present ⇒ assign complete; `## Workforce Gate` `approved`/`approved-with-notes` ⇒ `/speckit-implement-parallel` unlocked (via the git `before_implement` `verify-gate` workforce hook, R8). `after_agent-assign` hook → `git.commit agents(003-workforce): …`.

**Errors.** `prompt` task → non-Sonnet base = hard error (FR-014). Generated skill failing S1–S3 = rejected, not persisted (FR-007). >3 candidates = exactly 3 injected + remainder logged (SC-004).

---

## Config surfaces

- `categorize-config.yml` — `general_cap: 0.20`, `taxonomy: docs/contracts/taxonomy-v0.md`, `model: sonnet`.
- `agents-config.yml` — `assembly_cap: 3`, `model: sonnet`, `seed_library:` manifest (7 bases + 5 skills), `skill_builder.web_search: false` (R6; the council's decision lands here).

## Hooks registered (own `extension.yml`, D57 S1)

| Extension | Hook | Command | Purpose |
|---|---|---|---|
| categorize | `after_categorize` | `speckit.git.commit` | phase-tagged commit (R7) |
| agents | `after_agent-assign` | `speckit.git.commit` | phase-tagged commit (R7) |

The `before_implement` workforce `verify-gate` hook already exists (git ext); the pair consumes it (R8), registering nothing new for gate freshness.
