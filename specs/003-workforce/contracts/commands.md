# Phase 1 Contracts — Command Surface (003-workforce)

The one `workforce` extension exposes **three** commands. All obey the session-boundary rule (§2), single-writer ownership (§6/D37), and append one `traces.jsonl` record per model session (IV). The scripts (`assemble.py`, the shared `frontmatter.py`, `validate-categorization.py`, `validate-skill.py`) are zero-AI (no trace).

> **One extension, three commands (S10/S13).** The round-1 council folded the drafted two extensions (`categorize` + `agents`) into a single `extensions/workforce/` tree mirroring `extensions/council/`'s one-directory/multi-command shape (S10). The third command — `/speckit-workforce-approve` — is the S13 home for the gate signature and the gate-write trigger, mirroring `/speckit-council-approve`.

---

## `/speckit-categorize` (extension: `workforce`)

| | |
|---|---|
| **Phase** | `categorize` (runs **after** `analyze` — D58) |
| **Session** | one Sonnet `categorizer` session + a zero-AI validator |
| **Context in** | `tasks.md` (post-analyze, with graphify signals), `plan.md` |
| **Artifact out** | `categorization.md` — **and nothing else** (D37; never mutates `tasks.md`) |
| **Trace** | one `categorizer` record (role=categorizer, model=sonnet) |

**Behavior**
1. Dispatch the `categorizer` Sonnet session → tags every task `(type, specialization, preserves_behavior, tags)` per taxonomy v0; `type`/`preserves_behavior` mechanical from graphify signals, `specialization` interpretive from plan+domain. Records the source `tasks.md` SHA it derived from (S14 freshness binding).
2. Run `validate-categorization.py` (imports the shared `frontmatter.py`, S21):
   - **coverage** — every task carries all four fields; every enum value in the closed set (SC-001, code-validated per S05), else FAIL.
   - **cap** — `count(general) > 0.20 × count(tasks)` ⇒ **exit non-zero, write no `categorization.md`, phase does not complete** (FR-004/SC-002; the test asserts file-absence directly, S22).
3. On pass, write `categorization.md`; on fail, report the breach and stop the pipeline at categorize (Resumability III).

**Postconditions.** `categorization.md` exists ∧ validates ⇒ phase complete. `after_categorize` hook → `git.commit categorize(003-workforce): …` (research R7; registered in `workforce/extension.yml`, S25).

**Errors.** Over-cap → no artifact (FR-004). Un-enumerable value → FAIL (never invent a taxonomy value — that is a D-row, taxonomy §8).

---

## `/speckit-agent-assign` (extension: `workforce`)

| | |
|---|---|
| **Phase** | `agent-assign` (after `categorize`) |
| **Session** | zero-AI `assemble.py`; **+** one-or-more Sonnet `skill-builder` sessions **only on ∅-match** (R4) |
| **Context in** | `categorization.md` (+ its `tasks.md` SHA, checked for staleness — S14), `.claude/agents/`, `.claude/skills/` |
| **Artifact out** | `agents/assignment.md` (roster + `## Workforce Gate`) — **and nothing else** in the feature tree; a generated `SKILL.md` persists to the repo-root library (D24, outside the feature tree and outside any install `rm -rf` payload — S07) |
| **Trace** | one `agent-creator` record per skill-builder session (none on a gap-free run — R2/★★), carrying `elevated_grants: ["web_search"]` when the builder searched (D60/D43) |

**Behavior (deterministic core + gap handoff)**
1. `assemble.py` runs `agent-library-schema.md` §3 over `categorization.md` × library → per task: base by `(type, specialization)` (∅ ⇒ `agt_generic` + empty-lane note, FR-016); candidate skills by tag-intersection; force-inject `refactor-discipline` if `preserves_behavior`; rank (Jaccard→success_rate→version→id); inject **first 3**, **log dropped** (FR-011/SC-004); grants = union, **total-ordered before serialize** (S01/FR-013); **D48 guard** — `prompt`-tagged ⇒ assert Sonnet base else hard-error (FR-014/SC-006); mark each skill `library`/`built` (FR-022). It **writes the `## Workforce Gate` roster table itself** (S08) and **stamps a library-snapshot content-hash** (S18). Emits the roster + a ∅-match gap list. If `tasks.md` has moved past the SHA `categorization.md` recorded, it **hard-warns and routes to re-categorize** rather than assembling against stale classification (S14).
2. **If gaps:** for each, dispatch a Sonnet `skill-builder` — holding its **declared `web_search` grant** (D60) — → author one additive-only `SKILL.md` → `validate-skill.py` (**S1–S3, plus S04: tags MUST intersect the triggering task's tags**; `skl_` id, semver, grants⊄core) → persist to `.claude/skills/` with `origin: generated`, `source_feature: 003-workforce` (FR-006/007/008), stamping `provenance.stale_risk: true` if it authored post-cutoff without searching (S17). The builder checks the live `.claude/skills/` listing and **hard-fails/renames on a name collision**, never a silent skip (S07). Promotion stays manual (FR-009).
3. **Re-run `assemble.py`** (now gap-free over the grown library) → final roster; built skills carry the `built` mark. The re-run is **stable** (S15): only the gap task's row may change; every already-matched task's row is byte-identical (checkable via FR-022 marks + the snapshot hash).
4. Write `agents/assignment.md`: the roster table + `## Workforce Gate` (reviewer/decision/reviewed; Model + Elevated-grants mandatory — §8). Under `gates.workforce.mode: human` (this feature) the section is left **pending the human signature**, recorded by `/speckit-workforce-approve` (S13); under `auto` (full_auto only) the assigner writes the decision (FR-020/W4).

**Determinism (FR-015/SC-005).** Two runs over the same `categorization.md` + the same library ⇒ byte-identical `agents/assignment.md` **when gap-free** (zero `built` marks) — reinforced three ways: total-ordered serialization (S01), the script (not an LLM) writing the artifact (S08), and the stamped library-snapshot hash (S18) that makes the claim checkable in one line. A gap run is excluded from byte-identity (LLM authorship); re-running against the *resulting* library reproduces it.

**Postconditions.** Roster present ⇒ assign complete. The gate signature — recorded by `/speckit-workforce-approve` (below) — is what unlocks implement, not the roster draft (S13). `after_agent-assign` hook → `git.commit agents(003-workforce): …` (registered in `workforce/extension.yml`, S25).

**Errors.** `prompt` task → non-Sonnet base = hard error (FR-014). Generated skill failing S1–S3 or the S04 tag-intersection = rejected, not persisted (FR-007). >3 candidates = exactly 3 injected + remainder logged (SC-004). Skill-name collision on persist = hard-fail/rename, never a silent skip (S07).

---

## `/speckit-workforce-approve` (extension: `workforce`) — NEW (S13)

| | |
|---|---|
| **Phase** | `workforce-gate` (after `agent-assign`) — the human sign-off, mirroring `/speckit-council-approve` |
| **Session** | **none** — mechanical; runs no model (like the council gate, which leaves no trace) |
| **Context in** | `agents/assignment.md` (the roster) + the human's decision |
| **Artifact out** | the `## Workforce Gate` section of `agents/assignment.md` — **and nothing else** (single-writer of that section; the roster table above it is `assemble.py`'s) |
| **Trace** | **none** — the gate runs no session (artifact-layout §2 / trace-schema R9; the D47 pattern the council gate follows) |

**Behavior**
1. Record the human's decision — reviewer · `decision ∈ {approved, approved-with-notes, rejected}` · reviewed — in `## Workforce Gate` (the `artifact-layout.md` §8 / I-12 format, D49).
2. Fire **`after_workforce_approve`**, which the git extension handles by running its generalized **`on-gate-approve.sh workforce`** → `gates.sh write workforce` → bind `tasks.md` + `assignment.md @ <sha>` into git-ext-owned `gates.yml` (S02; `gates.yml` stays git-ext-owned per D55/Q1). `gates.sh` already knows the `workforce` artifact set, so only `on-gate-approve.sh` (formerly `on-council-approve.sh`, council-hardcoded) and the hook registration change — **in git-ext's own source** (D57 S2). git-ext is reinstalled after this edit (R8).
3. `approved`/`approved-with-notes` ⇒ the `before_implement` `verify-gate` (`gate: workforce`, already registered) passes → `/speckit-implement-parallel` unlocked; `rejected` ⇒ the roster returns for reassignment (W3/FR-020), and the last section is authoritative.

**Signer-agnostic (FR-010/W4).** Under `auto` (only within `full_auto`) the assigner writes the `## Workforce Gate` section directly, and the same `after_workforce_approve` gate-write must fire — exactly the signer-agnostic contract `on-council-approve.sh` already documents.

**Bootstrap grandfather (S28).** `003` builds *this very command* and git-ext's `on-gate-approve` generalization, so `003`'s **own** workforce gate cannot be written by the not-yet-installed machinery: it is **hand-written and grandfathered**, exactly as `002`'s council gate was left unbound (R1-S28, like M1's fast-forward). The binding this feature designs does not apply retroactively to the feature that designs it.

---

## Config surface — `workforce-config.yml` (one file, S10)

One config, replacing the drafted `categorize-config.yml` + `agents-config.yml`:

- `general_cap: 0.20` — the FR-004 evidence floor.
- `assembly_cap: 3` — the D40 injection cap (`refactor-discipline` counts).
- `model: sonnet` — the categorizer, skill builder, and every base (D18).
- `taxonomy: docs/contracts/taxonomy-v0.md` — the blessed enum.
- `seed_library:` — the manifest (7 bases + 5 skills; § Seed Library in plan.md).
- `skill_builder.web_search: true` — **D60**, the system's first elevated grant (the drafted `false` is retired by the owner ruling).

## Hooks registered

The phase-commit hooks are registered in **`workforce/extension.yml`** (the extension targeting another extension's command through the shared registry — D57 S1, no git-source edit); the gate-write handler is registered in **`git/extension.yml`** (a git-source change, since git owns `gates.yml` — D57 S2). S25: the `after_*` fire-points are declared in `workforce/extension.yml` and dispatched by the installed registry, not assumed to "just work."

| Hook | Registered in | Command / action | Purpose |
|---|---|---|---|
| `after_categorize` | `workforce/extension.yml` | `speckit.git.commit` | phase-tagged commit `categorize(003-workforce)` (R7, D57 S1) |
| `after_agent-assign` | `workforce/extension.yml` | `speckit.git.commit` | phase-tagged commit `agents(003-workforce)` (R7, D57 S1) |
| `after_workforce_approve` | `git/extension.yml` (**NEW**) | `speckit.git.record-gate` → `on-gate-approve.sh workforce` | bind `tasks.md` + `assignment.md @ sha` into `gates.yml` (S02/R8; git own source, D57 S2) |
| `before_implement` | `git/extension.yml` (**existing**) | `speckit.git.verify-gate` (`gate: workforce`) | gate-freshness hard-block; **consumed**, nothing new registered (R8) |

The `before_implement` workforce `verify-gate` hook already existed in git-ext; before the S02 fix it verified a binding that nothing wrote (the blocking defect). With `after_workforce_approve` now writing the binding, the freshness check is finally reachable.
