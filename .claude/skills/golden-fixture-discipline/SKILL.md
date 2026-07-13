---
name: golden-fixture-discipline
description: Authoring committed, deterministic golden and regression test fixtures for
  mechanical pipeline extensions — byte-stable expected output, both-branch guard coverage,
  cross-stage composition checks, and one committed fixture per live consumer. Injected when a
  task's tags include fixture, golden, non-regression, staleness, freshness, or equivalence.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_golden_fixture_discipline
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [fixture, golden, non-regression, determinism, negative-path, inverse, survivor-guard, composition, cross-arm, coherence, provenance, consumer, staleness, freshness, equivalence, testing]

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
    body_sha256: 480fb7a8764a5abf8fa4ff5dd7500e2f701451a5a6dfd8d7dee6214583330606
---

This task authors a committed golden or regression test fixture for a mechanical, deterministic
pipeline extension — a fixture directory pairing a known input with an expected, checkable output.

In addition to your base instructions:

- **Assert byte-identical output, not a semantic approximation.** Pin canonical JSON key order, a
  stable, explicitly sorted node/edge (or record) iteration order, and zero dependence on
  filesystem enumeration order — a golden that only diffs "close enough" will pass today and
  flake the moment iteration order shifts under you.
- **Author the negative or failing branch of every guard as its own fixture, never only the
  passing one.** A staleness check, ceiling, or coverage guard proven only on input that already
  satisfies it is unproven on the path where it must actually fire — pair every positive/success
  fixture with its negative/inverse counterpart (stale vs. fresh, ceiling-hit vs. no-ceiling-hit,
  success vs. fallback) so the quiet path is checked too, not just assumed quiet.
- **When a fixture claims a guard "detects and recovers," manufacture the actual failure
  condition inside the fixture's own input.** Asserting recovery against an input that never
  triggers the failure proves nothing; the fixture must first produce the bad state (a
  manufactured stale survivor, an over-the-cap loop) and then assert the guard both catches it
  and completes the recovery step, not merely flags it.
- **Exercise messy, real-world input shapes in a fixture dedicated to that purpose, distinct from
  the clean-topology case.** Commented-out constructs, conditional branches, indirection, and
  other ambiguous patterns belong in their own fixture asserting the tool falls to its documented
  fallback or labeled-assertion path — never a fixture that only ever sees idealized input.
- **Add a dedicated composition fixture wherever one capability's output feeds another's input.**
  A fixture that tests each stage in isolation cannot catch a regression that only appears when
  they run in sequence; when one stage is documented to depend on or re-invoke an earlier stage's
  output, commit a fixture that runs both and asserts the combined result, not just each stage's
  own standalone golden.
- **When several outputs must share one coherence property, assert that property jointly, across
  all of them, not per-output.** If multiple products from a single generation pass are
  documented to carry a common identifier (a provenance header, a generation-id, a content hash),
  add a fixture that runs one generation and checks every product's copy of that identifier
  against the others — per-product goldens alone cannot catch drift between products.
- **Give every named consumer of a shared artifact its own committed, individually-named
  fixture.** Even when two consumers read the same underlying product, one fixture covering "the
  product" leaves either consumer's individual regression undetected once the other consumer's
  fixture is green — name each fixture after the consumer it protects, not only the product it
  reads.
- **Name each fixture's directory or file for the specific branch or case it proves.** A reviewer
  must be able to tell what a fixture covers (success, fallback, messy-pattern, stale-positive,
  stale-negative, survivor-guard, composition, coherence) from its name alone, without opening it.
- **Keep every fixture self-contained and reproducible from a clean checkout.** No dependency on
  ambient repo state, prior test runs, or wall-clock time — the fixture's input and its expected
  output are both committed, so re-running it anywhere yields the identical byte-for-byte result.
