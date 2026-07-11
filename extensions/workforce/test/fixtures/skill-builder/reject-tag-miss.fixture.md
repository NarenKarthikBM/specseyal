---
name: t026-tag-miss-control
description: T026 committed fixture -- structurally valid and additive-only in
  every respect; used to assert S04 (taxonomy.tags MUST intersect the triggering
  task's tags) by invoking validate-skill.py with a DISJOINT task-tag argument.
  Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_test_tag_miss_control
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [covers-something-else, another-real-tag]

  grants: []

  provenance:
    created: 2026-07-12
    created_by: skill-builder
    source_feature: 003-workforce
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

This task involves a T026 committed test fixture only.

In addition to your base instructions:

- **Do nothing beyond what is stated in this fixture.** This module is
  structurally conforming in every respect; only the CLI-supplied task-tag
  argument varies between the PASS control and the S04 rejection in
  test_skill_builder.sh.
