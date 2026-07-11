---
name: t026-reject-model-key
description: T026 committed fixture -- otherwise conforming, but carries a
  top-level `model:` key, tripping S2 (a skill is never a dispatch target and
  declares no model -- skill-module.md S1/S6 rule 1). MUST be rejected by
  validate-skill.py. Not a real skill.
model: sonnet

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_test_reject_model_key
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

- **Do nothing beyond what is stated in this fixture.** This module exists solely
  to exercise the S2 top-level model-key check in the committed test harness.
