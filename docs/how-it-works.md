# How it works

`speckit-graphifyy` is a thin bridge between two tools that don't know about each other:

- **spec-kit** turns a feature description into a spec → plan → tasks → implementation.
- **graphify** turns your codebase into a queryable knowledge graph (`graphify-out/graph.json`):
  nodes are files/symbols, edges are real `imports` / `calls` / `contains` relationships.

The bridge injects the graph's *facts* into spec-kit's planning at three points.

## The graph is the source of truth

Everything starts with `graphify-out/graph.json`, built by `/graphify`. The companion skills never
read the whole graph; they query it with the `graphify` CLI, capped by a token budget:

- `graphify explain "<file-or-symbol>"` → exact directional edges for one anchor (its blast radius).
- `graphify query "<natural-language>"` → discovery only, to surface anchors you didn't name.
- `graphify path "<A>" "<B>"` → whether/how two anchors connect.

If the graph doesn't exist, the skills **stop and tell you to run `/graphify`** — they never invent edges.

## Piece 1 — the extension (`.specify/extensions/graphify/`)

A standard spec-kit extension. It does two things:

1. **Registers hooks** in `.specify/extensions.yml`: `before_plan`, `before_tasks`, `before_implement`.
   All are `optional: true`, so spec-kit *suggests* "Generate graphify context first?" rather than
   forcing it. This is how grounding reaches the **stock** `/speckit-plan` without modifying it.
2. **Holds config** (`graphify-config.yml`): where the graph lives (repo vs. merged stack graph) and
   the per-query token budget.

## Piece 2 — `speckit-graphify-context`

The shared grounding step. It resolves the active feature dir (via spec-kit's
`check-prerequisites.sh`), reads the spec/plan for concrete nouns (entities, services, routes,
files), maps them to graph node labels, queries the graph, and writes
`specs/<feature>/graphify-context.md` containing:

- **Relevant existing modules** the feature touches.
- **Blast radius per anchor** — what each file depends on and is depended on by.
- **Shared / mutable files** — the collision points (route manifests, barrels, settings, migrations)
  that must be *serialized* during parallel work.
- **Patterns to follow** — the exemplar files new code should imitate.

Both the hooks and the two graph-aware commands below read this one file, so the repo is explored
*once* per feature, not re-derived on every step.

## Piece 3 — `speckit-tasks-graph`

A drop-in alternative to `/speckit-tasks`. It generates the **identical** `tasks.md` (same checklist
format and phase/story organization, so `/speckit-analyze` keeps working), then adds what the stock
command can't:

- **Graph-verified `[P]`**: a task keeps its "parallelizable" marker only if, against every task it
  would share a wave with, their file sets are disjoint, neither sits in the other's blast radius,
  and they share no shared/mutable file. `[P]` becomes a derived fact, not a guess.
- **`## Execution Waves`**: a topologically-ordered, machine-readable DAG (with `files=` / `deps=` /
  `mutates=` annotations per task) that the next step executes directly.

Without a graph it falls back to spec-kit's heuristic and notes the degradation.

## Piece 4 — `speckit-implement-parallel`

A drop-in alternative to `/speckit-implement`. The stock command runs tasks serially in one agent.
This one is the **orchestrator**: it reads the `## Execution Waves` DAG and, for each wave, dispatches
**one subagent per task in the same turn** (true parallelism). Each subagent's prompt already contains
its graphify blast radius, so it never re-explores the repo. The orchestrator holds the barrier until
the wave returns, reviews each result, integrates shared-file edits itself (never in two parallel
agents), marks tasks `[X]`, logs the wave, and only then unlocks the next.

## Why siblings, not edits

The integration is deliberately **additive**. It never patches the stock skills or scripts, so:

- a `specify init` re-run or a spec-kit upgrade can't overwrite it;
- you can adopt it incrementally (use `/speckit-tasks-graph` but stock `/speckit-implement`, or vice versa);
- removing it (`uninstall.sh`) leaves stock spec-kit exactly as it was.
