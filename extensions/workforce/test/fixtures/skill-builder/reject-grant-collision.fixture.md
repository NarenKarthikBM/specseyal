---
name: t026-reject-grant-collision
description: T026 committed fixture -- otherwise conforming, but its grants list
  re-declares a core-toolset name (`Bash`), tripping D41 (agent-library-schema.md
  S6 rule 9 -- the core toolset is implicit and never a grant). MUST be rejected
  by validate-skill.py. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_test_reject_grant_collision
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [t026-shared-tag]

  grants: [Bash]

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
  to exercise the grant-disjointness check in the committed test harness.
