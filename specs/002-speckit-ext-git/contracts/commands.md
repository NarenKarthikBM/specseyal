# Contract — speckit-ext-git commands & hooks (Phase 1)

The extension surface: **hooks** (fired automatically by the phase commands) + **primitives** (called by hooks and by extension commands) + **one human command**. Every one is mechanical git; none calls a model or writes a `traces.jsonl` record (FR-007).

## Hooks (registered in `.specify/extensions.yml`, `optional: true`)

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
- **Does** (FR-011, D51): `git merge --no-ff` the feature branch into `base_branch` (unconditional; the merge commit is the completion anchor) → on success, `git branch -d <feature>`. **On conflict: abort (`git merge --abort`) and surface** for manual resolution — never auto-resolve, never delete an unmerged branch.
- **Out**: a base-branch merge commit; the feature branch ref deleted; every phase/wave commit still reachable (SC-005). No trace (mechanical git).
- **Idempotent**: re-running after a completed cleanup is a no-op (branch already gone).

## Gate-command integration points (the R1 seam)

Not new commands — existing commands gain one call each:
- **`/speckit-council-approve`** records `plan.md @ $(speckit.git.sha plan.md)` in the `## Human Gate` section it already writes.
- **The M3 workforce-gate writer** records `tasks.md @ …` + `assignment.md @ …` in `## Workforce Gate` (§8).
- **`/speckit-implement-parallel`** calls `speckit.git.commit impl "wave K/N …"` after each wave (FR-005/D-R7).

## Non-goals (v1)

No remote/push/PR/fetch; no auto-cleanup; no continuous (post-entry) gate re-verification (R2); no worktrees in the committed path (spike only, FR-015).
