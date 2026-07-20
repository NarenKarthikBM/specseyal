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
# 1. Get the SpecSeyal source onto disk. The installers are a local file copy
#    (no network fetch), so the extensions/ tree must be present. Any of:
git clone https://github.com/<owner>/specseyal.git         # full history, or
git clone --depth 1 https://github.com/<owner>/specseyal.git   # shallow, or
#    no git at all — download and extract the tree:
#    curl -L https://github.com/<owner>/specseyal/archive/refs/heads/main.tar.gz | tar xz
cd specseyal        # (or specseyal-main from the tarball)

# 2. Initialize GitHub Spec Kit in the repo you want the pipeline in — installs
#    .specify/ and the stock /speckit-* commands as .claude/skills/.
specify init --here --integration claude

# 3. Layer each SpecSeyal extension on top, one install.sh per extension. Each
#    installer's last argument is the TARGET repo (the one initialized in step 2):
#    "." installs into the current directory; pass a path to install elsewhere.
bash extensions/graphify/install.sh .
bash extensions/council/install.sh .
bash extensions/git/install.sh .
bash extensions/workforce/install.sh .
bash extensions/testing/install.sh .
bash extensions/deck-render/install.sh .
```

To layer SpecSeyal onto a *different* repo, point the target argument at it —
e.g. `bash /path/to/specseyal/extensions/graphify/install.sh /path/to/your-repo`.

Every installer is idempotent — re-running it updates the extension in place
rather than duplicating it — and every extension ships an `uninstall.sh`
alongside its `install.sh`.

**Clone-free install (single extension)**

Don't want to clone the whole repo just to install one extension?
`bootstrap.sh`, at the SpecSeyal repo root, fetches a single
`extensions/<name>/` subtree from a pinned ref and delegates straight to that
extension's own `install.sh` — no manual `git clone` of SpecSeyal required.
This is additive to the route above, not a replacement: both work, and
re-running either is idempotent.

The documented default is the reviewable two-step form — fetch the script,
then run it, so you can read it before anything executes:

```bash
curl -fsSLO https://raw.githubusercontent.com/NarenKarthikBM/specseyal/<pinned-ref>/bootstrap.sh
sh bootstrap.sh <extension-name> [<target-repo-dir>] [--ref <pinned-ref>]
```

> **⚠ Not available yet — use the local route above until the next release tag lands.**
>
> `bootstrap.sh` is introduced by the release that mints
> `complete/008-pre-public-maintenance`, and **that tag does not exist yet**. Because
> `bootstrap.sh` is absent from every *earlier* tag, there is currently **no `<pinned-ref>`
> for which the `curl` above succeeds** — it will 404 for any ref you substitute. Passing
> `--ref` does not work around this: `--ref` selects which ref the *extension subtree* is
> fetched from (step 2), while the `curl` URL selects which ref `bootstrap.sh` *itself* is
> fetched from (step 1). Step 1 is the one with no valid ref today.
>
> Until that tag lands, use the local `install.sh` route documented above — it works now
> and is unaffected. Once the tag exists, substitute it for `<pinned-ref>` and both forms
> below work as written.

`<extension-name>` is one of: `git | graphify | council | workforce | testing
| deck-render`. `<target-repo-dir>` is optional and defaults to `.` (must
already exist). `--ref` always takes a concrete tag or commit, never a moving
branch.

A convenience one-liner exists but is intentionally secondary — it skips the
inspection step above, so treat it as a shortcut for a ref you already
trust, not the primary path:

```bash
curl -fsSL https://raw.githubusercontent.com/NarenKarthikBM/specseyal/<pinned-ref>/bootstrap.sh | sh -s -- <extension-name> [<target-repo-dir>] [--ref <pinned-ref>]
```

`sh bootstrap.sh --self-test` exercises both of its fetch paths (sparse clone
and tarball fallback) against local, hermetic stand-ins and installs nothing
— a way to sanity-check the script itself before pointing it at a real
target.

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
