---
name: fx-epsilon
description: T021 frozen test fixture skill (extensions/workforce/test/test_assemble.sh,
  SC-004). One of four skills sharing the `cap-test` tag, so a task tagged only `cap-test`
  has exactly 4 tag-matching candidates -- more than the assembly cap of 3. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_fx_epsilon
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [cap-test, epsilon]

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

Frozen T021 test fixture. Ranks second of the four `cap-test` skills by the
`skill.id` ascending tie-break (`delta` < `epsilon` < `gamma` < `zeta`). Not
a real skill.
