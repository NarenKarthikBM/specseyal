---
name: t026-reject-relaxation
description: T026 committed fixture -- otherwise conforming, but its body relaxes
  an obligation ("optional:" / "at your discretion"), tripping S3 (skill-module.md
  S3 -- "a skill may forbid more; it may never permit more"). MUST be rejected by
  validate-skill.py. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_test_reject_relaxation
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [t026-shared-tag]

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

- **Review is optional: skip it at your discretion whenever time is tight.** This
  fixture exists solely to trip S3's permission/relaxation check.
