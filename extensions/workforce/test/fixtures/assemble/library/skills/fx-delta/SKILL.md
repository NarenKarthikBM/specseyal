---
name: fx-delta
description: T021 frozen test fixture skill (extensions/workforce/test/test_assemble.sh,
  SC-004). One of four skills sharing the `cap-test` tag, so a task tagged only `cap-test`
  has exactly 4 tag-matching candidates -- more than the assembly cap of 3. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_fx_delta
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [cap-test, delta]

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
    body_sha256: null
---

Frozen T021 test fixture. All four `cap-test` skills tie on Jaccard,
`success_rate` (null), and `version` (1.0.0), so the ranking's final,
deterministic tie-break is `skill.id` ascending -- `skl_fx_delta` sorts
first among the four (`delta` < `epsilon` < `gamma` < `zeta`). Not a real
skill.
