---
name: t026-dedup-shared-tag
description: T026 committed fixture -- structurally valid and additive-only; used
  to assert the validator-side half of SC-007/S24's dedup property: ONE skill
  whose tags cover a novel tag shared by two different tasks validates against
  EACH task's own tag set independently. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_test_dedup_shared_tag
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [shared-novel-tag, dedup-fixture-context]

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

- **Do nothing beyond what is stated in this fixture.** This module simulates
  one skill-builder dispatch closing a tag shared by two gapped tasks at once,
  per /speckit-agent-assign's connected-components dedup (T025).
