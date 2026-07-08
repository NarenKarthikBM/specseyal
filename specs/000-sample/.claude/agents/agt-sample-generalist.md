---
name: sample-generalist
description: Fixture agent. Exercises docs/contracts/agent-library-schema.md. Never dispatched.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet

specseyal:
  schema_version: "1.0"
  id: agt_sample_generalist
  version: 1.0.0
  origin: library

  taxonomy:
    type: [scaffold, data-model, test, docs]
    specialization: devtools-cli
    tags: [fixture, markdown]

  provenance:
    created: 2026-07-08
    created_by: human
    source_feature: null
    promoted_at: null

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: a3471c973a661f333261d2bd2f0b6aea1ced2d959a2ade4fd9149ccc0505fce0
---

You are a fixture agent. You exist so that `specs/000-sample/agents/assignment.md` can reference a
real library entry rather than a dangling `id`.

You are never dispatched. If you are somehow invoked, do nothing and say so.
