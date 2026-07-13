# Fixture: arm3-products

**Task:** T018 [US3] — per-product goldens for the three arm-3 context products, plus the
FR-013 unchanged-shape tripwire.

**Asserts, in two parts printed as one combined `stdout` (`expected.txt` = part 1 + part 2):**

1. **Header golden (mechanical, via `provenance.sh`).** Runs
   `"$REPO/extensions/graphify/extension/scripts/provenance.sh" header input/graph.json repo
   2026-01-01T00:00:00Z` and prints its stdout verbatim — the shared-provenance header block
   defined in `extensions/graphify/skills/speckit-graphify-context/SKILL.md` ("Shared-
   provenance header"), computed from this fixture's own small, committed `input/graph.json`
   (7 nodes / 5 edges / a synthetic 40-hex `built_at_commit`). Because `generated-at` is
   passed as a fixed literal rather than read from the wall clock (the contract's own
   golden-fixture guidance), the entire 9-line block — including the content-derived
   `node-count`, `edge-count`, `generation-id` (sha256 of the canonicalized graph minus
   `built_at_commit`), and `source-fingerprint` (the graph's own `built_at_commit`, prefixed)
   — is byte-stable and asserted byte-for-byte. `provenance.sh` is an orchestrator-owned
   shared helper authored in a **later wave**; until then this call finds no such file, part 1
   contributes nothing to `cmd.sh`'s stdout, and the fixture is **red for that reason**
   (intended TDD red — `cmd.sh`'s own exit code reflects the failure, and the harness's FAIL
   message points at the captured stderr, which names the missing file explicitly).

2. **Shape conformance (FR-013 tripwire + the two new diets).** Independent of part 1 — needs
   no script-under-test — so it runs, and passes, even while part 1 is red. Checked against
   this fixture's own three committed exemplar files (`expected-context.md`,
   `expected-receipts.md`, `expected-typesignal.md`), a hand-authored stand-in for what one
   `speckit-graphify-context` generator run (T020) over `input/graph.json` produces, all
   three carrying the same shared-provenance header for realism (that mutual-coherence
   property is what the separate `arm3-coherence` fixture, T019, actually asserts — this
   fixture proves per-product shape only):
   - `expected-context.md` (`graphify-context.md` stand-in) retains its **current, unchanged**
     section headings — `## Graph scope`, `## Relevant existing modules`, `## Blast radius
     (per anchor)`, `## Shared / mutable files (collision watch)`, `## Patterns to follow` —
     the FR-013 non-regression tripwire for the plan/tasks-graph/implement-parallel consumers.
   - `expected-receipts.md` (the new receipts diet) carries a concept/rationale section.
   - `expected-typesignal.md` (the new type-signal diet) carries per-file `file_type` lines,
     plus a labeled path-convention-fallback line for a file absent from the graph (taxonomy
     §1 / FR-004 honesty phrasing: "convention-derived / engineer assertion, not graph fact").

   Each check prints its own deterministic `PASS`/`FAIL` line (so a future regression names
   *which* heading or diet broke, not just "shape check failed"), followed by a summary line.

**Why a fixture-local graph instead of the repo's own `graph-baseline.json`:** the committed
baseline is the real, ~1611-node corpus graph — far too large to hand-verify or keep a
byte-stable, reviewable golden against. This fixture's `input/graph.json` is a small,
schema-conformant, fully self-contained graph (the same seven top-level keys: `directed`,
`multigraph`, `graph`, `nodes`, `links`, `hyperedges`, `built_at_commit`; node fields include
`label`, `file_type`, `source_file`, …) so the header arithmetic is hand-checkable and the
fixture never depends on ambient repo state. Per the shared-provenance-header contract, the
emitted `graph-path:` field is the **canonical convention string for the given scope**
(`graphify-out/graph.json` for `repo`), not an echo of the `input/graph.json` argument —
`provenance.sh` is designed to accept any readable graph file while still stamping the
real-world-shaped path a genuine repo run would carry.

**Provenance:** authored 2026-07-14, task T018 (005-graphify-context), skill
`skl_golden_fixture_discipline@1.0.0`. Depends on T004 (shared-provenance header contract,
done). Depended on by T020 (the generator, which must reproduce `expected-context.md`'s
section shape and both new diets' grammar) and by `provenance.sh`'s own authoring (which must
satisfy this fixture's header golden).
