---
name: fx-sonnet
description: T021 frozen test fixture base specialist (extensions/workforce/test/test_assemble.sh).
  Ordinary Sonnet lane for (scaffold|service|endpoint|test|docs) x qa-automation. Not a real
  seed base -- do not load outside extensions/workforce/test/fixtures/assemble/.
tools: Read, Write, Edit, Bash, Glob, Grep     # the immutable core — see agent-library-schema.md §4.1
model: sonnet

specseyal:
  schema_version: "2.0"
  kind: base
  id: agt_fx_sonnet
  version: 1.0.0

  taxonomy:
    type: [scaffold, service, endpoint, test, docs]
    specialization: qa-automation

  provenance:
    created: 2026-07-11
    created_by: human

  central:
    synced: false
    remote_id: null
    body_sha256: null
---

Frozen T021 assembly golden-test fixture. Ordinary Sonnet base used by
`categorization.fixture.md` (SC-005/S01 double-run determinism, SC-004 cap-trim,
SC-003/S09 grant union) and `gap/categorization.fixture.md` (S15 gap-rerun
stability). Not a real specialist; carries no lane-specific discipline beyond
this notice.
