# Agent Assignment — {{FEATURE}}

> Format: `artifact-layout.md` §8 (D49, resolving I-12) + `data-model.md` §5. Written by
> `/speckit-agent-assign` — `assemble.py` (zero-AI, deterministic; `agent-library-schema.md` §3) plus a
> Sonnet `skill-builder` session per ∅-match gap (D2/D40.2) — then signed by `/speckit-workforce-approve`
> (S13). The signed `## Workforce Gate` decision is what unlocks `/speckit-implement-parallel`; the
> roster below it is a proposal until then.
>
> **Inputs:** `categorization.md` ({{TASK_COUNT}} tasks) ⇐ `tasks.md @ {{TASKS_SHA}}` (S14 freshness
> binding — a stale SHA hard-warns and routes back to re-categorize rather than assembling against it).
> **Library snapshot (S18):** content-hash `{{LIBRARY_SNAPSHOT_HASH}}` — the base+skill set on disk when
> this run started, stamped so SC-005 ("gap-free ⇒ byte-identical roster") is checkable in one line.
>
> **Write boundary within this one file (principle 1):** `assemble.py` writes everything from here down
> through the `### Roster approved` table — base/skill selection, the `library`/`built` marks (FR-022),
> the elevated-grant union (FR-013, total-ordered per S01), and the empty-lane / dropped-skill notes
> (FR-016 / FR-011). It never writes the gate timestamp or the `reviewer` / `decision` / `reviewed` /
> `Notes:` / `Overrides:` fields below — those five are **`/speckit-workforce-approve`'s alone** (S13),
> and hold the literal `[PENDING — …]` marker until a human signs (or, under `gates.workforce.mode: auto`
> within `full_auto` only, the assigner resolves them itself in the same write — FR-020/W4; the pending
> state shown here is the `human`-mode default).

<!--
  TEMPLATE SOURCE NOTE. Strip this comment when rendering; it documents the substitution mechanics
  for whoever implements `assemble.py`, not the artifact's own content.

  Two placeholder grammars, kept visually distinct so the write boundary above stays legible even in a
  partially-filled file:
    {{UPPER_SNAKE}}   assemble.py substitutes mechanically, every run — never left in a written file.
    [PENDING — ...]   assemble.py writes this bracketed text LITERALLY — it has nothing to substitute
                      here, since it doesn't know the human's decision. It is the only marker
                      `/speckit-workforce-approve` may find-and-replace, and the only content in this
                      file that command is ever allowed to touch.
-->

## Workforce Gate — [PENDING — timestamp, set by `/speckit-workforce-approve`]

| Field | Value |
|---|---|
| reviewer | [PENDING — set by `/speckit-workforce-approve`] |
| decision | [PENDING — one of `approved` \| `approved-with-notes` \| `rejected`] |
| reviewed | [PENDING — set by `/speckit-workforce-approve`] |

### Roster approved

> One row per assembled agent — a base plus its ≤3 injected skills (W1); every task appears in exactly
> one row's `Task(s)` cell. Each `Skills` entry is marked **`library`** (present in the library at this
> run's start) or **`built`** (authored by the skill builder during *this* run) — FR-022; a **gap-free**
> roster (SC-005) carries zero `built` marks. **`Elevated grants` is mandatory on every row and is never
> omitted** — write `none` when the union is empty (W2/FR-018); the core toolset (`Read, Write, Edit,
> Bash, Glob, Grep`) is assumed and never listed (D44). A task matching no `(type, specialization)` lane
> assembles onto `agt_generic` and its row carries an **empty-lane** annotation (FR-016) — never a silent
> fallback. Whenever the 3-skill cap trims a candidate, the drop is recorded below the table, never
> silently discarded (FR-011/SC-004).

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
{{ROSTER_ROWS}}

{{EMPTY_LANE_NOTES}}

{{DROPPED_SKILL_NOTES}}

**Notes:** [PENDING — the reviewer's notes, or `none.` if there are none]

**Overrides:** [PENDING — any roster value the reviewer overrode at the gate, naming the D-row if one was opened, or `none.` if there are none]
