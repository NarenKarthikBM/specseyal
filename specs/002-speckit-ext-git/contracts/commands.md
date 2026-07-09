# Contract — speckit-ext-git commands & hooks (Phase 1)

The extension surface: **hooks** (fired automatically by the phase commands) + **primitives** (called by hooks and by extension commands) + **one human command**. Every one is mechanical git; none calls a model or writes a `traces.jsonl` record (FR-007).

## Hooks (registered in `.specify/extensions.yml`)

> **Revised at triage (R1-S01/S02):** hard-block / branch-commit hooks are **`optional: false`** so the dispatcher **auto-invokes** them (an `optional: true` hook is only *announced*); and `speckit-tasks`/`speckit-implement` pre-checks **abort on a non-zero hook exit**. `after_analyze` (R1-S14) and `after_council_approve` (R1-S04/S09) are added to the set below.

| Hook | Fires | Action | Exit contract |
|---|---|---|---|
| `after_specify` | end of `/speckit-specify` | `branch.sh` (ensure feature branch from `feature.json` spec ID) → `commit.sh spec "…"` | 0 always; branch created iff absent (idempotent, FR-012) |
| `after_clarify` | end of `/speckit-clarify` | `commit.sh spec "clarify"` | 0; no-op if clean (FR-004) |
| `after_plan` | end of `/speckit-plan` | `commit.sh plan "…"` | 0; no-op if clean |
| `before_tasks` | start of `/speckit-tasks` | `verify-gate.sh council` | **non-zero ⇒ hard-block** (stale council gate, FR-009) |
| `after_tasks` | end of `/speckit-tasks` | `commit.sh tasks "…"` | 0; no-op if clean |
| `before_implement` | start of `/speckit-implement*` | `verify-gate.sh workforce` | **non-zero ⇒ hard-block** (stale workforce gate) |
| `after_implement` | end of `/speckit-implement*` | `commit.sh impl "…"` (backstops the phase boundary) | 0; no-op if clean |

Hooks compose with graphify's `before_*` by `priority`; the git commit hook runs **after** graphify's context hook at a shared boundary (FR-013).

## Primitives (extension commands; called by hooks and by council/triage/implement)

### `speckit.git.commit <phase> <summary>`
- **In**: phase label ∈ config `phases`+`{council,gate,categorize,analyze,agents,complete}`, a summary string. **Wave form**: `commit impl "wave K/N …"`.
- **Does**: stages the feature's changed paths, commits with the FR-006 grammar. **No-op (exit 0, no commit) if the tree is clean** (FR-004).
- **Out**: the new commit SHA on stdout (or empty if no-op). No trace.

### `speckit.git.sha <artifact-path>`
- **In**: a repo-relative artifact path (e.g. `specs/NNN/plan.md`).
- **Does**: prints the SHA of the HEAD commit that last touched that path (the value a gate command records into its section, FR-008). Read-only.
- **Out**: a git SHA on stdout. No side effect, no trace.

### `speckit.git.verify-gate <gate>`
- **In**: `gate ∈ {council, workforce}`.
- **Does**: parses the recorded `<artifact> @ <sha>` from the gate section (`decision-record.md` `## Human Gate` / `assignment.md` `## Workforce Gate`), compares each to `sha <artifact>`.
- **Out**: exit **0** if every recorded SHA matches current (fresh); **non-zero** + a human-readable mismatch on stderr if any is stale (FR-009). Read-only, no trace.

## Human command

### `/speckit-git-cleanup` (skill; `disable-model-invocation` not set — human runs it)
- **In**: the completed feature branch (checked out or named); base from `git-config.yml`.
- **Does** (FR-011, **D52**): integrate into `base_branch` — **`ff` permitted**, `git merge --no-ff` only when the base diverged → **`git tag -a complete/<spec-id>`** at the integration commit (the mandatory completion anchor) → `git branch -d <feature>`. **On conflict: abort (`git merge --abort`) and surface** — never auto-resolve, never delete an unmerged branch.
- **Out**: the integration commit + the `complete/<spec-id>` tag (enumerable via `git for-each-ref refs/tags/complete/*`); the feature branch ref deleted; every phase/wave commit reachable (SC-005 via per-SHA `merge-base --is-ancestor`). No trace (mechanical git).
- **Idempotent**: re-running after a completed cleanup is a no-op (branch gone, tag present).

## Gate-command integration points (the R1 seam — narrowed at triage)

- **Council approve → `after_council_approve` hook** (reinstall-surviving, R1-S04): the git ext writes `plan.md @ <sha>` into **`gates.yml`**; `## Human Gate` carries a one-line reference. **No edit to `speckit-council-approve`'s installer-overwritten source.**
- **Workforce gate (M3)**: the git ext writes `tasks.md @ …` + `assignment.md @ …` into `gates.yml`; `## Workforce Gate` (§8) references it.
- **`/speckit-implement-parallel`**: calls `speckit.git.commit impl "wave K/N …"` after each wave **before marking the task `[X]`** (R1-S06), and re-verifies gate freshness each wave (R1-S23). The one genuinely coupled edit (no per-wave hook slot), reinstall-survival-tested (R1-S17).

## Non-goals (v1)

No remote/push/PR/fetch; no auto-cleanup; no continuous (post-entry) gate re-verification (R2); no worktrees in the committed path (spike only, FR-015).
