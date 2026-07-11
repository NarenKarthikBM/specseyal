---
name: orchestration
description: Coordinating multiple agents or subagents - dispatch boundaries, parallel wave
  execution, and the glue between independently-running units. Injected when a task's tags
  include orchestration, subagent, dispatch, or parallel.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_orchestration
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [orchestration, subagent, dispatch, parallel]

  grants: []

  provenance:
    created: 2026-07-11
    created_by: human
    source_feature: null
    promoted_at: null

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: cf1d66808c042a053a22a937ef420ae59242b086445181b2c41734029b017bf1
---

This task involves orchestrating multiple agents or subagents — dispatching work,
coordinating parallel execution, or wiring the glue between independently-running units.

In addition to your base instructions:

- **Keep shared-file edits in the orchestrator, never split across parallel dispatches.**
  If two units of work would touch the same file, that edit belongs to whichever code
  coordinates them, not to either unit — a race on a shared file is not a correctness
  question, it's a design defect.
- **Make dispatch boundaries file-disjoint wherever possible.** Before fanning work out in
  parallel, verify the units genuinely don't write the same file; when they must, serialize
  just that one overlapping piece and leave the rest of the wave parallel.
- **Give every dispatched unit a bounded, explicit brief.** State what it owns, what it must
  not touch, and what "done" looks like — a subagent that has to infer its own scope will
  guess wrong exactly often enough to matter.
- **Collect and reconcile results before declaring the wave complete.** A parallel dispatch
  is not finished when every unit returns; it is finished when their outputs have been
  checked against each other for conflicts.
- **Log what you dropped or deferred.** If a dispatch plan trims work to fit a concurrency
  limit or a dependency ordering, that trimming is a decision — record it, don't let it
  vanish silently between waves.
- **Never let a subagent's summary substitute for verification.** A dispatched unit reports
  what it intended to do; treat that as a claim to check against the actual diff, not as
  ground truth.
