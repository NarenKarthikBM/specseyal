---
name: fx-nonsonnet
description: SYNTHETIC T021 test fixture base specialist that deliberately violates the
  D18 Sonnet floor (extensions/workforce/test/test_assemble.sh, SC-006/S03). Exists ONLY
  to trip the D48 guard's `else -- hard-error` branch against a `prompt`-tagged task.
  NEVER a real library entry -- do not load outside
  extensions/workforce/test/fixtures/assemble/.
tools: Read, Write, Edit, Bash, Glob, Grep     # the immutable core — see agent-library-schema.md §4.1
model: haiku

specseyal:
  schema_version: "2.0"
  kind: base
  id: agt_fx_nonsonnet
  version: 1.0.0

  taxonomy:
    type: [docs]
    specialization: security

  provenance:
    created: 2026-07-11
    created_by: human

  central:
    synced: false
    remote_id: null
    body_sha256: null
---

Frozen T021 test fixture. `type: [docs]` alone does not violate the D18 model
policy (agent-library-schema.md §4 only forces `model: sonnet` on bases
accepting one of the 7 IMPLEMENTATION types -- `docs` is not among them), so
this base's `model: haiku` is otherwise unremarkable. That is exactly why it
is the right synthetic fixture for SC-006/S03: a `prompt`-tagged task is
mechanically `type: docs` yet is real implementation prompt-authoring
(taxonomy-v0.md §3, D48), so assembling it onto THIS base must be caught by
the D48 guard's hard-error branch, not by the general model-policy validator.
