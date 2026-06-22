# Workflow — one feature, end to end

A concrete walkthrough of building a feature with the graph-aware loop. Assumes you've already run
`./install.sh` in your repo (see the [README](../README.md)).

## 0. Build the graph (once per repo, refresh as needed)

```text
/graphify
```

This writes `graphify-out/graph.json`. After a large merge or refactor:

```text
/graphify --update
```

For a **cross-repo feature** (e.g. a frontend change that touches a sibling backend), also build a
graph at the stack root so the merged graph exists, and point `graphify-config.yml`'s `graph.merged`
at it.

> No graph yet? The graph-aware commands will stop and ask you to run `/graphify` first. They never
> fabricate dependencies.

## 1. Spec the feature (stock spec-kit)

```text
/speckit-constitution      # once per project: principles the plan/tasks must honor
/speckit-specify           # describe the feature → specs/<feature>/spec.md
/speckit-clarify           # answer targeted questions; encodes answers back into the spec
```

## 2. Plan — grounded

```text
/speckit-plan
```

The `before_plan` hook offers: *"Generate graphify codebase context before planning?"* Accept it (or
run `/speckit-graphify-context` yourself). That writes `specs/<feature>/graphify-context.md`, and the
plan is written against the modules, blast radius, and patterns that **actually exist** — not invented ones.

## 3. Tasks — graph-aware

```text
/speckit-tasks-graph
```

You get a normal `tasks.md` **plus**:

- `[P]` markers that survived verification against real import/call edges, and
- a `## Execution Waves` section: the DAG, with `files=` / `deps=` / `mutates=` per task and a
  shared-file serialization list.

Read the completion report — it tells you the widest parallel wave and which `[P]` markers were
*stripped* (and why). That's usually where naive task generation would have caused a collision.

## 4. Implement — parallel

```text
/speckit-implement-parallel
```

The orchestrator walks the waves:

- **Serial waves** (Setup, Foundational, shared-file integration) run as barriers.
- **Parallel waves** dispatch one subagent per task at once; each gets only its blast radius and its
  `files=` set, and is told not to touch shared/mutable files (the orchestrator owns those).
- Each wave is reviewed and its tasks marked `[X]` before the next unlocks; one line per wave is
  appended to `specs/<feature>/implement.log.md`.

## 5. (Optional) analyze

`/speckit-analyze` still works — `speckit-tasks-graph` preserves the stock `tasks.md` format, so
cross-artifact consistency checks run unchanged.

---

### When to skip the graph-aware path

- **Tiny features** (< 3 tasks, no real parallelism): `/speckit-implement-parallel` will just
  implement inline; using stock `/speckit-implement` is equally fine.
- **No graph and no time to build one**: the stock `/speckit-tasks` + `/speckit-implement` still work;
  you only lose the graph verification.
