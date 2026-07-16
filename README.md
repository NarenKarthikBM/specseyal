# SpecSeyal

**SpecSeyal** (செயல் — *seyal*, "action"): spec → action.

SpecSeyal is a governed spec-driven development (SDD) orchestrator. It takes
[GitHub Spec Kit](https://github.com/github/spec-kit)'s stock spec → plan →
tasks → implement loop and extends it into a full pipeline: a plan must
survive an adversarial council defense before any code exists, tasks are
categorized and dispatched to specialized parallel agents rather than a
single generic implementer, and every run ends in a completion report and a
testing doc rather than just a diff. Structural grounding throughout the
pipeline — what a feature actually touches, what's safe to run in parallel,
what a new module should imitate — comes from
[graphify](https://pypi.org/project/graphifyy/), a real dependency graph of
the codebase, rather than from an LLM's guess. Everything here runs CLI-first
inside Claude Code today; an Agent SDK-native platform layer (a web GUI +
central manager) is planned on top of the same artifacts.

## The pipeline

```
specify → clarify → plan → council → tasks → analyze → categorize → agents → parallel-implement → complete → testing
```

Each phase reads artifacts in and writes exactly one artifact out
(`spec.md`, `plan.md`, council decision records, `tasks.md`, a task/agent
roster, a completion report, a testing doc) — the same artifacts a future
GUI orchestrator will read and write. Two checkpoints in that sequence are
gates: **council** (after `plan`, before tasks are written) and **workforce**
(after `agents`, before implementation spends tokens) — each configurable
per feature as `human` or `auto` via a `profile.yaml`.

## Quickstart

**Prerequisites**

- [Claude Code](https://claude.com/claude-code), signed in on a **Claude
  subscription** (Pro/Max), not API billing.
- `ANTHROPIC_API_KEY` **unset** in your shell — SpecSeyal is subscription-only
  end to end (see [Billing](#license--billing) below). Check `/status` inside
  Claude Code if you're unsure.

**Install**

```bash
# 1. Initialize GitHub Spec Kit in your repo — installs .specify/ and the
#    stock /speckit-* commands as .claude/skills/.
specify init --here --integration claude

# 2. Layer each SpecSeyal extension on top, one install.sh per extension:
bash extensions/graphify/install.sh .
bash extensions/council/install.sh .
bash extensions/git/install.sh .
bash extensions/workforce/install.sh .
bash extensions/testing/install.sh .
bash extensions/deck-render/install.sh .
```

Every installer is idempotent — re-running it updates the extension in place
rather than duplicating it — and every extension ships an `uninstall.sh`
alongside its `install.sh`.

**First commands**

```
/graphify           # build the dependency graph of your repo
/speckit-specify     # write the feature spec — the pipeline starts here
```

From there the pipeline runs the phase sequence above; each `/speckit-*`
command is documented in the extension that provides it (see
[Repo layout](#repo-layout)).

## Repo layout

```
extensions/   pipeline extensions (graphify, council, git, workforce, testing, deck-render)
platform/     manager + GUI + orchestrator (empty until the platform milestone)
docs/         architecture, implementation plan, decision log, contracts
specs/        per-feature SDD artifacts: specs/NNN-feature/...
```

Start with the docs, in this order:

- [`docs/00-VISION-AND-ARCHITECTURE.md`](docs/00-VISION-AND-ARCHITECTURE.md)
  — the north star: what this is, the core ideology, the full extended
  workflow, the component map. Read first.
- [`docs/05-IMPLEMENTATION-PLAN.md`](docs/05-IMPLEMENTATION-PLAN.md) — the
  grounded build sequence, milestone by milestone, with each milestone's
  close-out recorded as it lands.
- [`docs/90-DECISIONS-AND-IDEAS.md`](docs/90-DECISIONS-AND-IDEAS.md) — the
  decision log (every non-trivial call, numbered and dated) and the idea
  parking lot.

Each extension under `extensions/` carries its own `README.md` with the
commands it registers and how to install/uninstall it standalone.

### graphify's home

`extensions/graphify/` is SpecSeyal's in-repo home for the graphify
integration: it installs three companion skills that consume the graph
(graph-verified parallel task markers, graph-aware parallel implementation)
into `.claude/skills/`. The graph-building engine itself is not vendored —
it's the upstream [`graphifyy`](https://pypi.org/project/graphifyy/) pip
package plus the `/graphify` command that drives it, kept as a clean
external dependency so the engine can evolve (or be archived and swapped)
independently of the extension that wires its output into the pipeline.

## License & billing

SpecSeyal is [MIT licensed](LICENSE).

Billing is **subscription-only, end to end**: every session in this pipeline
runs through an interactive Claude Code subscription. `ANTHROPIC_API_KEY` is
never set or relied upon by this project — keep it unset on any machine
running SpecSeyal, so billing never silently routes to API usage instead of
your plan.
