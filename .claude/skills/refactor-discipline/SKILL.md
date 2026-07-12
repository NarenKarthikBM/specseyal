---
name: refactor-discipline
description: Behavior-preserving edits to existing code. Injected automatically when a task's
  preserves_behavior is true. Bounds the blast radius; adds no public surface.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_refactor_discipline
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [refactor, blast-radius, behavior-preserving]

  grants: []

  provenance:
    created: 2026-07-09
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
    body_sha256: 36328b2da4ded8b3d78efb4fc524cbb886fe7f801a5f1b5c50f4c4518be7791c
---

This task preserves behavior. Every file you touch already exists; you add no public surface.

In addition to your base instructions:

- **Add no new public surface.** No new exported symbol, route, table, CLI flag, or config key.
  If the task seems to need one, it is not a behavior-preserving task — stop and say so.
- **Stay inside the blast radius.** Your graphify blast radius names the files that depend on
  what you are changing. Every one of them must still compile and pass its tests. Do not widen
  the change to make your edit easier.
- **Preserve observable behavior exactly** — return values, error types, side effects, ordering,
  and timing characteristics that anything downstream could depend on.
- **Change no test to make your change pass.** A test that fails after a behavior-preserving
  edit has found a behavior you did not preserve. Fix the code, not the test.
- **Land it in one commit** whose message states what was preserved, not merely what moved.
