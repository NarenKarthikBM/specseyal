---
description: "Phase-tagged commit of the feature's changed paths; no-op if clean"
---

# Git Commit

Stage the feature's changed paths and commit them with the FR-006 phase-tagged grammar. This is the primitive behind every `after_*` hook (`after_specify`, `after_clarify`, `after_plan`, `after_tasks`, `after_implement`) and behind `/speckit-implement-parallel`'s per-wave commits. Mechanical git only — no model call, no trace (FR-007).

## Behavior

- **In**: phase label ∈ config `phases` + `{council, gate, categorize, analyze, agents, complete}`, a summary string. Wave form: `commit impl "wave K/N …"`.
- **Does**: stages the feature's changed paths, commits with the FR-006 grammar. No-op (exit 0, no commit) if the tree is clean (FR-004).
- **Out**: the new commit SHA on stdout (or empty if no-op). No trace.

## Execution

Run `scripts/commit.sh <phase> <summary>` (this command file is its provenance source). No model is invoked.
