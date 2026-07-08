# `000-sample` — conformance fixture

**This is not a feature.** It is the executable statement of `docs/contracts/`: one directory
exercising every artifact the pipeline can produce, each empty-but-valid against its contract.

Nothing here is ever implemented. `NNN=000` is reserved for this fixture.

## What it exercises

| Contract | Exercised by |
|---|---|
| `artifact-layout.md` | the whole tree, and its `§2` phase order |
| `profile-schema.md` | `profile.yaml` (both gates `human`, `full_auto: false`) |
| `decision-record.md` | `council/decision-record.md` — accepted, rejected (with reasoning, R3) and deferred rows |
| `trace-schema.md` | `traces.jsonl` — one record per session-running phase |
| `taxonomy-v0.md` | `categorization.md` — 2 types × 1 specialization × `preserves_behavior`, plus the `general` cap check |
| `agent-library-schema.md` | `.claude/agents/agt-sample-generalist.md` — a **base specialist** (see below) |
| `skill-module.md` | `.claude/skills/refactor-discipline/SKILL.md` — the seed skill module |

## Two deliberate oddities

**`.claude/agents/` and `.claude/skills/` nested inside the fixture.** The library is repo-level
(`.claude/` at the repo root — D17), not per-feature. A seed library is M3's job, and M0 ships no
implementation. But `agents/assignment.md` has to resolve a real lane, and a dangling `id` would make
the fixture unverifiable. So one base specialist and one skill module live here, at the paths they
would occupy in a real repo, where Claude Code will not load them. Delete both when M3 seeds the real
library.

Under D40 an agent is **assembled, not stored**: base specialist (selected by `(type, specialization)`)
+ up to 3 tag-selected skill modules + the union of their tool grants. `assignment.md` shows the
assembly trace. The fixture injects **zero** skills — and says so, rather than inventing a task that
would have needed one.

**`graphify-context.md` is present but disposable.** `artifact-layout.md` §3 exempts it from the
resumability rule; it is committed here only so the tree is complete.

## Using it

Any conformance checker written later must pass this directory. When a contract changes, this
fixture changes in the same commit — that is what keeps `docs/contracts/` honest.
