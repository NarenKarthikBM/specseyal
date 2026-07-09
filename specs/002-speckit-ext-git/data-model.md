# Data Model — speckit-ext-git (Phase 1)

The extension holds **no data of its own** (D32) — its "entities" are git objects and fields inside artifacts other phases own. This file fixes their shapes so the hooks and the conformance checks agree.

## Entities

### FeatureBranch
- **Identity**: `name` = the spec ID, matching `^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$` (FR-002), identical to the `specs/NNN-slug/` dir.
- **Lifecycle**: born at `after_specify` from `feature.json`'s spec ID (FR-001/D-R1) → accumulates phase/wave commits → integrated + deleted at `/speckit-git-cleanup` (FR-011).
- **State**: the git ref itself — the only phase state outside `specs/` (D32). No record of it is written anywhere else.

### PhaseCommit
- A commit at a phase boundary that changed an artifact (FR-003). **Message grammar (FR-006):** `^<phase>\(<spec-id>\): <summary>$`, where `<phase> ∈ {spec, plan, council, gate, tasks, categorize, analyze, agents, impl, complete}`.
- **Empty boundary → no commit** (FR-004): `commit.sh` is a no-op when the working tree is clean for the feature's paths.

### WaveCommit
- A per-wave commit inside `implement` (FR-005). **Grammar:** `^impl\(<spec-id>\) wave <K>/<N>: <summary>$`. Made by `implement-parallel` calling the commit primitive (D-R7).

### GateSHABinding
- The `(artifact, commit-SHA)` pair recorded in a **git-ext-owned `specs/NNN/gates.yml`** (owner ruling, R1-S09/S20 — supersedes the earlier "inside the gate section" design, which co-wrote another command's artifact); the gate section (`## Human Gate` / `## Workforce Gate`, §8) carries a **one-line reference** to `gates.yml`.
  - **Council gate** binds `plan.md @ <sha>`; **workforce gate** binds `tasks.md @ <sha>` + `assignment.md @ <sha>`.
- **Freshness rule (FR-009)**: a binding is *fresh* iff `<sha>` equals the artifact's current commit SHA **and the working tree for that artifact is clean** (a dirty approved artifact = stale — R1-S05). `verify-gate` **fails closed** (blocks) on an unparseable binding or gate-format-version drift (R1-S10). A stale binding does not authorize the gated phase (hard-block).
- `<sha>` is a git SHA from `speckit.git.sha <artifact>`.

### WaveWorktree *(spike only — FR-015)*
- An isolated `git worktree` per implement wave, merged per wave. **Exists only inside the timeboxed spike**; no hook or command references it. Deliverable: a finding in `implement.log.md`, not a persisted entity.

## Config (`extension/git-config.yml`)

| Key | Meaning | Default |
|---|---|---|
| `base_branch` | the branch features are cut from and merged into | `main` |
| `merge.policy` | integration strategy | `ff`-permitted; merge-commit only when the base diverged (**D52** — the anchor is the tag, not the merge) |
| `anchor` | completion anchor | annotated tag `complete/<spec-id>`, **mandatory** at cleanup (D52, R1-S27) |
| `branch.pattern` | branch-name = spec ID | `^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$`, **or `YYYYMMDD-HHMMSS-slug` under `feature_numbering: timestamp`** (R1-S25) |
| `commit.grammar` | phase/wave message shapes | as PhaseCommit/WaveCommit above |
| `phases` | which stock phases get `after_*` commit hooks | `[specify, clarify, plan, tasks, implement]` |
| `gates` | gate → `(artifacts, verify-before-phase)` map | council→(`plan.md`, before `tasks`); workforce→(`tasks.md`,`assignment.md`, before `implement`) |

The **completion anchor is the `complete/<spec-id>` tag** (D52, superseding D51's `--no-ff`): it exists unconditionally as a tag regardless of merge topology, enumerable via `git for-each-ref refs/tags/complete/*`, so `merge.policy` is now free to fast-forward.

## Invariants (checked by quickstart / conformance)

1. Exactly one FeatureBranch per feature, name = spec ID (FR-002).
2. Every changed-artifact phase boundary → exactly one PhaseCommit; every wave → exactly one WaveCommit (FR-003/005).
3. No empty commits (FR-004).
4. Every gate section carries a GateSHABinding; a stale binding blocks its phase (FR-008/009).
5. After cleanup: every phase/wave commit is reachable from the base tip (none squashed) and the branch ref is gone (FR-011/SC-005).
6. `traces.jsonl` contains **no** git-ext record (FR-007/SC-007).
