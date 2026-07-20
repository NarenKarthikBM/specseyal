---
name: "speckit-implement-parallel"
description: "Graph-aware, parallel sibling of speckit-implement. Executes tasks.md as dependency-ordered waves, dispatching one subagent per task within a wave (dev-orchestrator model), each pre-loaded with a graphify blast-radius. Reviews each wave before the next, marks tasks [X], and logs waves. Each dispatch reads its task's row from the approved workforce roster (agents/assignment.md) and its trace carries the assembly it ran as — agent_id, skills, elevated_grants (FR-021/SC-008, D43)."
argument-hint: "Optional implementation guidance or task/story filter"
compatibility: "Requires spec-kit .specify/ structure with tasks.md. Best with an ## Execution Waves section from /speckit-tasks-graph and a graphify-out/graph.json. Requires an approved agents/assignment.md workforce roster — the before_implement gate already enforces this; this skill additionally reads the roster's content, not just its gate binding."
metadata:
  author: narenkarthikbm
  source: "sibling of speckit-implement (templates/commands/implement.md) + dev-orchestrator + graphify"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## What this is

A drop-in alternative to `/speckit-implement`. The stock command executes tasks serially in one agent. This one runs the **dev-orchestrator wave model**: it reconstructs the task DAG, then for each wave dispatches **one subagent per task in the same turn** (true parallelism), reviews the wave, integrates, and only then unlocks the next wave. Each subagent gets a self-contained prompt that already includes the graphify blast-radius for its files, so it never re-explores the repo.

You are the **orchestrator**. You do not implement tasks yourself except trivial glue/integration.

## Pre-Execution

1. Honor `before_implement` extension hooks from `.specify/extensions.yml` (same rules as speckit-implement).
2. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks`; parse `FEATURE_DIR` + `AVAILABLE_DOCS` (absolute paths).
3. **Checklist gate** (if `FEATURE_DIR/checklists/` exists): same as speckit-implement — tabulate completion, and if any checklist is incomplete, STOP and ask whether to proceed before continuing.
4. Load context once, as orchestrator: `tasks.md` (+ its `## Execution Waves`), `plan.md`, and IF EXISTS `data-model.md`, `contracts/`, `research.md`, `quickstart.md`, `.specify/memory/constitution.md`.
5. Ensure grounding: read `FEATURE_DIR/graphify-context.md`; if missing, run `/speckit-graphify-context` first.
6. **Load the approved roster.** Read `FEATURE_DIR/agents/assignment.md`'s `### Roster approved` table once, into a task-id → row lookup (a row's `Task(s)` cell can list several ids sharing one assembled agent — index every id in it to that same row). This is what every wave's dispatch and trace consult for the rest of this run; you do not re-read the table mid-run (the gate re-verify in "Execute waves" step 1 re-confirms the *binding* hasn't drifted, it does not re-parse the roster). Per row:
   - **base** — the `Assembled agent (base)` cell, e.g. `` `agt_ai_agents` `` — strip the backticks and any trailing annotation (e.g. `⚠ empty lane`; the empty-lane fact itself is roster bookkeeping, not part of the trace).
   - **skills** — the `Skills (id@ver)` cell: `[]` when the cell is `none` (or an equivalent hand-authored phrasing, e.g. this feature's own grandfathered bootstrap roster's `*(none — base suffices)*`); otherwise one entry per `` `skl_id@version` `` token (each followed by a `(library)`/`(built)` provenance mark — roster bookkeeping only, drop it; it has no place in the trace's `{id, version}` shape). If a cell's version isn't already full semver (a hand-authored shorthand, e.g. that same grandfathered roster's `@1.0`), resolve the exact version from the injected skill's own installed `.claude/skills/<name>/SKILL.md` frontmatter (`specseyal.version`) instead of guessing or truncating — the file, not the cell text, is authoritative.
   - **elevated grants** — the `Elevated grants` cell: `[]` when it reads `none`; otherwise one string per backticked grant token, comma-separated.

   **Cross-extension seam (D57 §9, resolving I-14).** This is a read of the workforce-owned **artifact** only — never a dependency on `extensions/workforce/`'s source. `/speckit-implement-parallel` is graphify-owned; coupling to another extension's behavior belongs at a hook when one exists (S1), and falls back to an edit living in the *owning* extension's own source when it can't (S2) — exactly the shape the `002` per-wave-commit edit took when it had to move out of graphify's *installed* tree and into graphify's own source (R1-S17). Reading `agents/assignment.md` is neither: it is data, not code, so it needs no hook and no foreign-source edit — only this file, in graphify's own source, so graphify's own `install.sh` carries it on every reinstall. See "Execute waves" steps 2 and 5 for where this lookup is used.

   If `agents/assignment.md` is missing, or its `## Workforce Gate` `decision` is still a `[PENDING …]` marker or `rejected`, the run is unapproved; step 1's `before_implement` gate hook should already have stopped you before this point. If you somehow reached here regardless, STOP rather than dispatch against an unsigned roster.
7. Project setup verification (ignore files etc.): same as speckit-implement step 4 — do this once, up front, in the orchestrator.

## Build the execution graph

- If `tasks.md` has an `## Execution Waves` section (from `/speckit-tasks-graph`), use it verbatim as the DAG.
- Otherwise derive it: phase order (Setup → Foundational → Stories → Polish) as hard barriers; `[P]` + distinct file paths → same wave; stated deps / TDD / model → service → endpoint → sequence; shared/mutable files (from `graphify-context.md`) → serialized into their own wave. Write the derived waves back into `tasks.md` so the run is reproducible.
- Apply any `$ARGUMENTS` filter (e.g. a single story) by pruning the DAG to those tasks + their prerequisites.

## Execute waves (the loop)

For each wave in order:

1. **Re-verify the gate.** Before dispatching this wave's tasks, re-verify the workforce gate is still fresh: run `speckit.git.verify-gate workforce` (`/speckit-git-verify-gate workforce`). If it exits non-zero, hard-block — do not dispatch the wave. The approved `tasks.md`/`assignment.md` changed since the gate was last verified and must be re-approved before this wave can proceed. This complements the one-time `before_implement` entry check, which cannot see drift introduced later in a long, multi-wave `implement` phase. (This re-verifies the git-recorded *binding* only; it does not re-read the roster table — the lookup you built in Pre-Execution step 6 stays what this wave dispatches against.)
2. **Dispatch.** For every task in the wave, look up its row in the roster loaded in Pre-Execution step 6 — this is what makes the dispatch a task's **assembled agent** rather than a bare subagent — and spawn a subagent **in the same turn** (parallel) using the Agent tool, with the prompt template below, its Context section naming that row's base and injected skills. Serial waves dispatch their single task (or run trivial ones inline). A task with no matching roster row is a contract violation of the same shape as a stale gate: STOP — never dispatch it under a fabricated or blank assembly.
3. **Hold the barrier.** Do not start the next wave until every subagent in this one returns.
4. **Review each result** (dev-orchestrator gate): output exists; matches the task + plan + constitution; imports resolve. Success → commit the wave's outputs **before** marking anything `[X]`, via `speckit.git.commit impl "wave K/N: <summary>"` (`/speckit-git-commit`); the commit must precede the `[X]` mark (or be atomic with it), so an interrupt between the two always leaves a recoverable "committed-but-unmarked" state, never a lossy "marked-but-uncommitted" one — only then mark the task `[X]` in `tasks.md`. Partial → patch inline or re-dispatch with a corrected prompt. Failure → diagnose; for a serial/blocking task STOP; for one parallel task continue the others and report it.
5. **Trace.** One `implementer` record per task dispatched this wave, appended to `FEATURE_DIR/traces.jsonl` immediately as each task's review (step 4, above) lands — serially, one append at a time, never batched or concurrent (the same JSONL-append discipline `/speckit-council` and `/speckit-agent-assign` hold for their own dispatches). Every dispatched task gets exactly one record regardless of its outcome — success, partial, and failed reviews all still leave a trace, since a session ran in every case. A task implemented inline under the Guardrails' `< 3 tasks` exception gets one too — there is no Agent-tool return to time, so use your own start/finish for that span. Field values are fixed by § Trace fields, below.
6. **Integrate** any shared-file edits the wave implies (e.g. register new routes/models/serializers in the shared manifest) — this is legitimate orchestrator glue and must happen in the orchestrator, never in two parallel subagents.
7. **Log** one line to `FEATURE_DIR/implement.log.md`:
   `<ISO> | wave <N> | tasks: <ids> | agents: <n> | outcome: success|partial|failed`
   Create the file if absent; never edit prior lines.

### Subagent task prompt template

```
## Task: <TaskID> — <description>

### Context (you have no other project context)
- Stack & conventions: <from plan.md: language, framework, libraries, style>
- Constitution constraints: <relevant rules from constitution.md, if any>
- Assembled identity (from the approved roster, `agents/assignment.md`): base `<the row's Assembled agent (base) id, e.g. agt_ai_agents>`[, injected skills: `<the row's skl_id@version list, omitted entirely when it is []>`]

### Your job
<single, crisp deliverable for this one task>

### Graphify blast radius (authoritative — do NOT re-explore the repo)
- Files to edit/create: <files= from the wave annotation>
- This code depends on: <from graphify-context.md>
- Depended on by (do not break these): <from graphify-context.md>
- Follow the existing pattern in: <exemplar file>

### Inputs
<exact files to read: relevant plan/data-model/contract slices, prior-wave outputs by path>

### Outputs
<exact file path(s) to write>

### Constraints
- Edit ONLY your files= set. Do NOT touch shared/mutable files (<list>) — the orchestrator owns those.
- <TDD: if this is an impl task, its tests already exist at <path> and must pass.>

### Done when
<objective criterion: file exists / function implemented / tests green>
```

### Trace fields (`traces.jsonl`, `role: "implementer"`) — FR-021/SC-008, D43

Per `trace-schema.md` §1, every field is present on every record; these are the ones this section fixes. Everything not listed here (`started_at`/`ended_at`/`duration_ms`, `tokens`/`capture_method`, `outcome`, `artifact`) is populated the ordinary way — this table only fixes the values the workforce roster determines. (`artifact` carries one additional rule of its own, below the table, for the gitignored/untracked case — everything else in that list is untouched by this section.)

| Field | Value |
|---|---|
| `schema_version` | `"1.0"` |
| `trace_id` | fresh, unique, one per task dispatched |
| `parent_trace_id` | `null` — `/speckit-implement-parallel`'s own invocation is not itself a traced role (the same reasoning `/speckit-council`'s top-level fragments use: a human-invoked top-level command has no in-file `trace_id` for its dispatches to reference) |
| `feature` | the spec id (`basename(FEATURE_DIR)`) |
| `phase` | `"implement"` |
| `role` | `"implementer"` |
| `agent_id` | **the roster row's base** (Pre-Execution step 6), e.g. `agt_ai_agents` — never `null` (`trace-schema.md` §7 rule 4: non-null iff `role == "implementer"`, and every record here is one) |
| `skills` | **the roster row's injected set**, `[{ "id": "skl_…", "version": "x.y.z" }, …]`, order as the row lists them — `[]` when the row's Skills cell is `none` (never `null` — `trace-schema.md` §1: "Empty array `[]` when none were injected — never `null`"). The count never exceeds 3 (`trace-schema.md` §7 rule 5's cap), because `assemble.py` already enforced it when it wrote the row — this section only carries the row forward, it never re-derives or re-trims it. |
| `elevated_grants` | **the roster row's grant union**, as an array of strings, e.g. `["web_search"]` — `[]` when the row's Elevated grants cell is `none`. This is the exact set a human approved at the workforce gate (D41/D44) — copy it verbatim, never widen or narrow it from what the row shows. (Same mechanism `/speckit-agent-assign` already applies to its own builder-dispatch trace, which records `elevated_grants: ["web_search"]` exactly when that dispatch's declared grant was actually exercised — `speckit-agent-assign/SKILL.md` § Gap handoff step (c), D60/D43. There the source is a live builder return; here it is a roster row — same rule, different source.) |
| `model` | `"claude-sonnet-5"` — the exact id (D18's Sonnet floor for implementation; every seed base declares `model: sonnet`), never the alias `sonnet` |
| `effort` | `"medium"` unless the dispatch actually ran at a different effort — the Sonnet-mechanical-role precedent `/speckit-categorize` and `/speckit-agent-assign` both record for their own Sonnet dispatches, and `trace-schema.md` §2's own reminder that "the trace is evidence" of what ran, not policy echoed back |

**Zero-injection case, explicit.** A row carrying neither skills nor grants — the modal case against a small seed library (e.g. a bare `agt_devtools_cli` row, no skills) — still gets a complete record: `agent_id` is the bare base, `skills: []`, `elevated_grants: []`. `[]` is the fact being recorded on both fields, independently of each other — a row can carry skills with `elevated_grants: []` (every seed skill in this feature's own library declares `grants: []` except the skill-builder's own module) just as easily as the reverse.

**Gitignored/untracked artifact, explicit** (H4.1–H4.3, generalizing `006`'s one-off SC-005 correction into a root-cause guard). Probe **after** the wave's outputs have been committed — step 4 commits before step 5 traces, so by the time a record is written a genuine output is already tracked, and a path *still* untracked at that moment is one that will never be tracked. Probing earlier would null out every legitimately-new file, which is the opposite of the intent. Then probe whether the path that would otherwise go in `artifact` is tracked: `git ls-files --error-unmatch <path>` — exit `0` means tracked, and the record names that real, repo-resident path as usual. A non-zero exit means untracked (whether merely new, or additionally confirmed as matching a `.gitignore` rule via `git check-ignore -q <path>`) — that path will never exist in the repo's history, so the record must not name it. When that untracked/gitignored path is the task's **sole** output, write `artifact: null` for that record instead of the path. A task that also produced at least one tracked file still records that tracked path — the null-out fires only when no tracked output is left to point at. This is a **value** change to `artifact` on the affected record only: `trace-schema.md` §1 already types `artifact` as `string | null` (a session that "produces none" already writes `null` there — this rule only adds a second case that reaches the same, already-legal value), so nothing is added to or removed from the schema (Constitution IV). It is unrelated to the `[]`-never-`null` convention `skills`/`elevated_grants` hold above: those two fields are always arrays and are never `null`; `artifact` is a `string | null` field that is `null` exactly when a session produces no artifact — this rule just adds "its sole output is gitignored/untracked" as one more way that condition can hold.

## Guardrails (kept from spec-kit)

- Phase barriers are hard: never dispatch story tasks before Foundational is fully `[X]`.
- TDD: a test task always lands in an earlier wave than the code it covers.
- Mark every completed task `[X]` in `tasks.md` in real time, per wave.
- Same-/shared-file tasks are never co-scheduled; "when uncertain, sequence."
- If the feature is < 3 tasks with no real parallelism, skip orchestration and just implement inline.
- For very wide cross-story waves where collisions are likely, consider giving each story its own git worktree (`Agent` `isolation: "worktree"`) and merging — overkill for small features.

## Post-Execution

- Honor `after_implement` extension hooks.
- Completion validation: all required tasks `[X]`; implementation matches spec/plan; tests pass.

## Completion Report (dev-orchestrator format)

```
## Implementation Complete — <feature>
### Waves run: <N>  (widest parallel wave: <k> agents)
### Completed: <task ids → one-line outcome>
### Partial/Degraded: <task → what's left>
### Failed: <task → reason → next step>
### Integration status: <imports resolve? tests? shared-file merges clean?>
### Traces: <n> implementer records appended (traces.jsonl) — agent_id/skills/elevated_grants per approved roster row
### Next steps: <...>
```

## Done When

- [ ] All in-scope tasks executed via waves and marked `[X]`
- [ ] Each wave reviewed before the next; shared files integrated by the orchestrator
- [ ] The approved roster (`agents/assignment.md`) was loaded once (Pre-Execution step 6) and every dispatch was looked up in it — no task dispatched under a fabricated or blank assembly
- [ ] Exactly one `implementer` trace appended per task dispatched (inline-implemented tasks included), `agent_id`/`skills`/`elevated_grants` sourced from that task's roster row, `[]` used (never `null`) wherever a row carries none (FR-021/SC-008)
- [ ] `implement.log.md` has one line per wave
- [ ] `before_implement` / `after_implement` hooks honored
- [ ] Completion reported in the format above
