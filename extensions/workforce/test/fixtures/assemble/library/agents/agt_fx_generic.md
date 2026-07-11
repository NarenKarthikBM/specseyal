---
name: fx-generic
description: T021 frozen test fixture generic fallback base specialist
  (extensions/workforce/test/test_assemble.sh). The FR-016 fallback lane for
  (scaffold|data-model|service|endpoint|ui|test|infra) x general. Not a real seed base --
  do not load outside extensions/workforce/test/fixtures/assemble/.
tools: Read, Write, Edit, Bash, Glob, Grep     # the immutable core — see agent-library-schema.md §4.1
model: sonnet

specseyal:
  schema_version: "2.0"
  kind: base
  id: agt_fx_generic
  version: 1.0.0

  taxonomy:
    type: [scaffold, data-model, service, endpoint, ui, test, infra]
    specialization: general

  provenance:
    created: 2026-07-11
    created_by: human

  central:
    synced: false
    remote_id: null
    body_sha256: null
---

Frozen T021 assembly golden-test fixture: the required FR-016 empty-lane
fallback (`Library.generic_base()` raises if no base declares
`specseyal.taxonomy.specialization: general`). Present so the frozen library
snapshot satisfies that invariant even though none of the committed
categorization fixtures currently hit an empty lane. Not a real specialist.
