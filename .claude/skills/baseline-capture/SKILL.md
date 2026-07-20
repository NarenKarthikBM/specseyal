---
name: baseline-capture
description: Establishing a pre-change baseline across more than one extension's own test harness, so a
  later "the guard now fails" claim can be checked against a recorded prior state instead of assumed.
  Applies whenever a task must run several extensions' `test/run.sh` before any source edit lands.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_baseline_capture
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [baseline, harness, pre-change-verification, regression, cross-extension, test-harness, multi-extension]

  grants: []

  provenance:
    created: 2026-07-20
    created_by: skill-builder
    source_feature: 008-pre-public-maintenance
    promoted_at: null
    stale_risk: false

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: e18b68abddb1e6d3a4000cce9734ff099aaab7c7a9efeecbbbff2be776fd158f
---

This task establishes a pre-change baseline across more than one extension's own test harness, before
any source file changes land. In addition to your base instructions:

1. **Run every named extension's own `test/run.sh` separately**, one invocation per extension, never a
   single combined script that runs them all at once — a failure must stay traceable to the specific
   extension whose harness produced it.
2. **Record the exact pass/fail count each harness reports**, verbatim, per extension — not a rounded or
   summarized "looks green" note. If a harness's own output prints no explicit count, record its raw exit
   code and full output as the substitute baseline, and say plainly that you did so.
3. **Capture the baseline before touching any source file the change will edit.** A baseline taken after
   an edit has already landed cannot serve the purpose it exists for.
4. **Persist the baseline somewhere a later step can read it** — the task's own artifact, report, or log,
   not only your own working context — so a future "the guard now fails" claim can be checked against a
   durable record rather than a memory of having run it.
5. **Treat every named extension's harness as required, even ones you expect to pass cleanly.** Skipping
   a harness because its result seems predictable leaves that one extension's prior state unrecorded and
   the whole baseline incomplete.
6. **When a later failure is reported against one of these harnesses, compare it to this baseline
   first.** If the same failure was already present in the baseline, state plainly that it is
   pre-existing — never present a pre-existing failure as evidence of a newly introduced regression.
