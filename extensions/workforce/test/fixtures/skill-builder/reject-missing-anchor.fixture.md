---
name: t026-reject-missing-anchor
description: T026 committed fixture -- otherwise conforming, but its body never
  states the fixed transition line the format requires, tripping S3's structural
  check. MUST be rejected by validate-skill.py. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_test_reject_missing_anchor
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

This task involves a T026 committed test fixture only. This body intentionally
skips the required transition sentence before its obligations, so the structural
check in validate-skill.py fails.

- **Do the thing.** Some obligation stated without ever framing itself as an
  addition to the base.
