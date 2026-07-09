---
description: "Verify a recorded gate SHA against current HEAD; hard-block on stale"
---

# Git Verify Gate

Parse the recorded `<artifact> @ <sha>` pairs from a gate section and compare each against the artifact's current SHA. Runs from `before_tasks` (`council` gate) and `before_implement` (`workforce` gate); a non-zero exit hard-blocks the phase (FR-009).

## Behavior

- **In**: `gate ∈ {council, workforce}`.
- **Does**: parses the recorded `<artifact> @ <sha>` from the gate section (`decision-record.md` `## Human Gate` / `assignment.md` `## Workforce Gate`), compares each to `sha <artifact>`. Working-tree-aware, fail-closed.
- **Out**: exit 0 if every recorded SHA matches current (fresh); non-zero + a human-readable mismatch on stderr if any is stale (FR-009). Read-only, no trace.

## Execution

Run `scripts/verify-gate.sh <gate>` (this command file is its provenance source). No model is invoked.
