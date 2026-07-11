---
name: t026-additive-pass
description: T026 committed fixture -- a fully conforming, additive-only generated
  skill used to assert validate-skill.py's PASS path (exit 0). Not a real skill;
  exercised only by extensions/workforce/test/test_skill_builder.sh.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_test_additive_pass
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [t026-shared-tag, additive-pass-only-tag]

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
  to exercise validate-skill.py's PASS path in the committed test harness.
- **Never delete or overwrite a file outside this fixture's own scope.** A
  conservative, additive-only obligation, chosen so this fixture is itself a
  legitimate (if trivial) additive skill body -- not merely a syntactic shell.
