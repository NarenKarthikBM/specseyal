---
description: "Print the HEAD SHA that last touched an artifact path (read-only)"
---

# Git Sha

Print the SHA of the HEAD commit that last touched a given artifact path. Read-only; this is the value source a gate section (`## Human Gate` / `## Workforce Gate`) records against (FR-008).

## Behavior

- **In**: a repo-relative artifact path (e.g. `specs/NNN/plan.md`).
- **Does**: prints the SHA of the HEAD commit that last touched that path. Read-only.
- **Out**: a git SHA on stdout. No side effect, no trace.

## Execution

Run `scripts/sha.sh <artifact-path>` (this command file is its provenance source). No model is invoked.
