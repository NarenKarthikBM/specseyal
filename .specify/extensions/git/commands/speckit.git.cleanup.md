---
description: "Integrate the completed feature branch, tag complete/<spec-id>, and delete it"
---

# Git Cleanup

Integrate the completed feature branch into `base_branch`, tag the integration commit `complete/<spec-id>`, and delete the feature branch. The human runs this once a feature is done (FR-011, D52).

## Behavior

- **In**: the completed feature branch (checked out or named); base from `git-config.yml`.
- **Does**: integrate into `base_branch` — `ff` permitted, `git merge --no-ff` only when the base diverged → `git tag -a complete/<spec-id>` at the integration commit (the mandatory completion anchor) → `git branch -d <feature>`. On conflict: abort (`git merge --abort`) and surface — never auto-resolve, never delete an unmerged branch.
- **Out**: the integration commit + the `complete/<spec-id>` tag (enumerable via `git for-each-ref refs/tags/complete/*`); the feature branch ref deleted; every phase/wave commit reachable (SC-005 via per-SHA `merge-base --is-ancestor`). No trace.
- **Idempotent**: re-running after a completed cleanup is a no-op (branch gone, tag present).
- **Worktree-aware** (D81/I-30): in a per-feature-worktree layout `base_branch` is checked out in another worktree, so cleanup integrates there (`git -C`, requiring it clean) rather than checking it out in place, and detaches the feature worktree's HEAD so the branch can be deleted — it never removes the worktree directory. The single-worktree path is unchanged.

## Execution

Run the `/speckit-git-cleanup` skill, which shells out to `scripts/cleanup.sh` (this command file is its provenance source). No model is invoked.
