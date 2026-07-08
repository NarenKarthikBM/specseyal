# speckit-graphifyy

**Ground [GitHub spec-kit](https://github.com/github/spec-kit)'s spec-driven-development loop in a real dependency graph of your codebase.**

Spec-kit plans, splits tasks, and implements from the *spec*. On its own it guesses what your
code looks like — which files a feature touches, what's safe to parallelize, what a new module
should imitate. `speckit-graphifyy` feeds it the answer instead of a guess, by querying a
[graphify](https://pypi.org/project/graphifyy/) knowledge graph of your repo.

```
                    ┌─────────────────────────────────────────────┐
   /graphify  ──▶   │  graphify-out/graph.json  (real import/call  │
                    │  edges, blast radius, shared/mutable files)  │
                    └───────────────────┬─────────────────────────┘
                                        │  queried by
        ┌───────────────────────────────┼───────────────────────────────┐
        ▼                                ▼                               ▼
  /speckit-plan                /speckit-tasks-graph          /speckit-implement-parallel
  (before_plan hook            stock tasks.md  +             executes the Execution Waves
   offers grounding)           graph-verified [P]  +          as parallel subagents, each
                               ## Execution Waves DAG          pre-loaded with its blast radius
```

It's an **add-on layer**, not a fork: it drops a spec-kit *extension* and three *companion skills*
next to the stock ones. A `specify init` re-run never clobbers them.

---

## What it installs

| Into your repo | What it is |
| --- | --- |
| `.specify/extensions/graphify/` | A spec-kit extension. Registers `before_plan` / `before_tasks` / `before_implement` hooks (all **optional** — they *suggest*, never auto-run) and holds the graph-path + token-budget config. |
| `.claude/skills/speckit-graphify-context/` | Writes a token-bounded `graphify-context.md` for the active feature: relevant modules, per-file blast radius, shared/mutable collision files, patterns to follow. |
| `.claude/skills/speckit-tasks-graph/` | Drop-in alternative to `/speckit-tasks`: same `tasks.md`, plus `[P]` markers **verified against real edges** and a machine-readable `## Execution Waves` DAG. |
| `.claude/skills/speckit-implement-parallel/` | Drop-in alternative to `/speckit-implement`: runs the waves as parallel subagents (dev-orchestrator model), reviewing each wave before unlocking the next. |

The stock `speckit-*` skills and `.specify/scripts/*` are **left untouched**.

---

## Prerequisites

1. **[Claude Code](https://claude.com/claude-code)** — the skills are Claude Code skills.
2. **spec-kit**, initialized in your repo: install the [`specify` CLI](https://github.com/github/spec-kit)
   and run `specify init` so a `.specify/` directory exists.
3. **graphify** — the graph builder:
   ```bash
   pip install graphifyy          # provides the `graphify` CLI
   ```
   plus the **`/graphify` skill** for Claude Code (that's what builds the graph with rich
   extraction). The companion skills query the `graphify` CLI directly (`graphify explain/query/path`).

---

## Install

```bash
git clone https://github.com/narenkarthikbm/speckit-graphifyy
cd speckit-graphifyy
./install.sh /path/to/your/project      # defaults to the current directory
```

The installer copies the extension + skills and idempotently registers the hooks in
`.specify/extensions.yml`. Re-run it any time to update; run `./uninstall.sh /path/to/your/project`
to remove the layer cleanly.

> **YAML registration** needs a Python with PyYAML. The installer searches the interpreters most
> likely to have it (graphify's, spec-kit's, system `python3`) and falls back to
> `uv run --with pyyaml`. If none is available it prints the exact block to paste — nothing breaks.

---

## The loop

Once installed, run a feature end to end:

```text
1.  /graphify                 # build graphify-out/graph.json for the repo
                              #   (re-run /graphify --update after big merges)

2.  /speckit-constitution     # stock spec-kit — project principles (once)
    /speckit-specify          # stock — write the feature spec
    /speckit-clarify          # stock — de-risk ambiguity

3.  /speckit-plan             # stock — the before_plan hook offers to generate
                              #   graphify-context.md first, so the plan reflects real structure

4.  /speckit-tasks-graph      # ← graph-aware: stock tasks.md + verified [P] + ## Execution Waves

5.  /speckit-implement-parallel   # ← graph-aware: runs the waves as parallel subagents
```

Steps 4 and 5 are the graph-aware replacements; everything else is stock spec-kit. You can still
use `/speckit-tasks` and `/speckit-implement` if you want the serial path.

---

## Configuration

`.specify/extensions/graphify/graphify-config.yml`:

```yaml
graph:
  repo: graphify-out/graph.json        # this repo's graph
  merged: ../graphify-out/graph.json   # optional: a merged stack graph for cross-repo features
output:
  file: graphify-context.md            # written into specs/<feature>/
query:
  budget: 1200                         # token cap per graphify query — keeps the context file lean
```

`merged` is a convenience for monorepos/sibling-repo features (e.g. a frontend feature that touches
the backend). Single-repo projects can ignore or delete it.

---

## How it stays compatible

The graph-aware commands are **siblings**, not edits to `speckit-tasks` / `speckit-implement`:

- `tasks.md` keeps the exact stock format (so `/speckit-analyze` still works); the DAG is *appended*.
- Re-running `specify init` or upgrading spec-kit can't clobber the integration — it lives in
  separate skill folders and an extension directory spec-kit doesn't own.
- If the graph is missing, the graph-aware commands degrade gracefully (heuristic `[P]`, and they
  tell you to run `/graphify`) rather than fabricating dependencies.

More detail in [`docs/how-it-works.md`](docs/how-it-works.md) and a full walkthrough in
[`docs/workflow.md`](docs/workflow.md). Stuck? [`docs/troubleshooting.md`](docs/troubleshooting.md).

---

## License

MIT — see [`LICENSE`](LICENSE).
