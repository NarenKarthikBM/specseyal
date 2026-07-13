---
name: quickstart-integration-gate
description: Executing an end-to-end quickstart, acceptance walkthrough, or similar runnable
  checklist as a feature's integration gate — systematically binding every Success Criterion and
  Functional Requirement to a concrete, executed check and asserting full coverage, not a sampled
  spot-check. Injected when a task's tags include quickstart, e2e, integration-gate, sc-mapping,
  validation, or dogfood.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_quickstart_integration_gate
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [quickstart, e2e, integration-gate, sc-mapping, validation, dogfood, acceptance-test, coverage-mapping, requirements-traceability, gap-disclosure, non-regression, testing]

  grants: []

  provenance:
    created: 2026-07-14
    created_by: skill-builder
    source_feature: 005-graphify-context
    promoted_at: null
    stale_risk: false

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: dd38c65d1fb855f32983b7dbfddbd6bd55d7633b36f6658591dd1c8a8ae695c7
---

This task runs an end-to-end quickstart, acceptance walkthrough, or comparable runnable checklist
as a feature's integration gate — the final mechanical proof that every claimed Success Criterion
and Functional Requirement actually holds, not a sampled spot-check of a few scenarios.

In addition to your base instructions:

1. **Enumerate every Success Criterion and Functional Requirement named in the feature's spec
   before running anything**, and bind each one to a specific, named step or scenario in the
   checklist you execute. Any SC or FR you cannot bind to a concrete step is an explicit GAP,
   recorded by its own name — never folded silently into a general "looks fine" pass.
2. **Actually execute every bound step and observe its real output.** A step whose outcome you
   infer from reading the checklist's prose, without running it, may never be marked pass —
   confidence in a predicted result is not evidence of an executed one.
3. **Trace the mapping in both directions.** After binding every SC/FR to a step, also confirm
   every numbered step in the checklist maps back to at least one named SC, FR, or arm. A step
   that validates nothing named in the spec gets flagged as an orphan check, not left in the
   ledger unlabeled.
4. **Run every step assigned to a given Success Criterion, not only the first one that passes.**
   When one SC is proven by more than one scenario — a positive-path step plus a named negative,
   inverse, or no-false-alarm counterpart — execute all of them before marking that SC covered.
5. **Record a step you cannot actually run as explicitly blocked, a third state distinct from both
   pass and fail**, whenever a prerequisite is missing, the environment is unavailable, or a
   dependency is blocked. A blocked step never counts toward coverage.
6. **Cross-check every named consumer or downstream integration point called out in the spec or
   plan against the checklist's own consumer-facing steps.** A consumer with no corresponding
   executed step is a gap in the gate itself, named explicitly, never quietly folded into "out of
   scope."
7. **Treat reinstall, redeploy, or re-provisioning survival — whenever the spec claims it — as its
   own distinct executed scenario.** Re-run the same steps against the reinstalled or redeployed
   artifact and diff the result for parity; a pre-reinstall pass alone never stands in for this.
8. **Produce one coverage ledger — every SC/FR as its own row, each marked pass, fail, GAP, or
   blocked, naming the step(s) that proved it — as this gate's artifact of record.** A narrative
   summary is an addition to the ledger, never a substitute for it.
9. **Treat any single GAP or blocked row as withholding the gate's overall pass.** Never average
   partial coverage into an aggregate "mostly passing" verdict; one unresolved row means the
   integration gate has not closed.
