---
name: fx-novel
description: T021 frozen test fixture skill (extensions/workforce/test/test_assemble.sh,
  S15). Present ONLY in the "closed" gap-rerun snapshot -- simulates the skill builder
  authoring and persisting a new SKILL.md to close T002's gap (D2/D40.2). Matches T002's
  `novel-tag` tag. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_fx_novel
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [novel-tag]

  grants: []

  provenance:
    created: 2026-07-11
    created_by: skill-builder
    source_feature: assemble-fixture
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

Frozen T021 test fixture. Absent from `gap/skills-open/`; present here to
simulate the skill builder closing T002's ∅-match gap between the two
`assemble.py` runs. The gap-closed test invocation passes
`--built-skill skl_fx_novel` so this run's roster marks it **`built`** rather
than `library` (FR-022). Not a real skill.
