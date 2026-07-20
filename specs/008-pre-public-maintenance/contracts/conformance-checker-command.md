# Contract — `check-conformance.py` (US2 · I-11)

The CLI/behavioral contract for the contract conformance checker. Derived from the contracts, **not** the M0 fixture (FR-005).

## Invocation

```sh
python3 extensions/workforce/extension/scripts/check-conformance.py <feature-dir>
# e.g. python3 .../check-conformance.py specs/000-sample
```

- `<feature-dir>` — required; a `specs/NNN-feature/` directory. No third-party deps; Python 3 stdlib only.

## Behavior contract

| # | Guarantee | Maps to |
|---|-----------|---------|
| C1 | Validates `<feature-dir>` against the `docs/contracts/` schema set (layout, record formats, frontmatter) | FR-004 |
| C2 | **Delegates** to `validate-profile.py` / `validate-categorization.py` / `validate-skill.py` for their artifacts — does not re-check their rules | FR-008, SC-005 |
| C3 | **Covers remaining contracts directly**: artifact-layout, decision-record, completion-report, testing-doc, trace-schema, agent-library-schema | FR-004, data-model E3 |
| C4 | **PASSES `specs/000-sample`** — artifact-layout §7's "any conformance checker built later must pass it" made real | FR-006, SC-004, Acceptance §US2-1 |
| C5 | On a violation, **FAILS naming the offending artifact + the rule broken** | FR-004, SC-004, Acceptance §US2-2 |
| C6 | **Deterministic** — same input → identical verdict | FR-007, SC-004, Acceptance §US2-3 |
| C7 | **Single CI-invocable command, zero third-party deps** | FR-007, SC-005, Acceptance §US2-3 |
| C8 | **Honors documented D50 meta-feature carve-outs** — a carve-out is not reported as drift | FR-006, SC-004, Acceptance §US2-4 |
| C9 | Embeds a `_self_test()` (the `validate-profile.py` shape) | Research R2 |

## Exit codes

- `0` — the feature dir conforms (all delegated + direct checks pass; carve-outs honored).
- non-zero — one or more nonconformances; stdout/stderr names each `<artifact> · <rule>`.
- A usage error (missing/nonexistent dir) exits non-zero, reported distinctly from a conformance failure.

## Both-branch fixtures (FR-009 / SC-004)

Committed under `specs/008-pre-public-maintenance/fixtures/`, run from `extensions/workforce/test/run.sh`:

- **conformant/** — a valid feature dir → checker PASSES.
- **violation-missing-section/**, **violation-bad-frontmatter/**, **violation-wrong-path/**, **violation-bad-trace-line/** — each injects one contract breach → checker FAILS naming that cause.
- Plus the standing CI assertion that the checker PASSES `specs/000-sample`.

## Out of scope (this contract)

- Re-validating `profile.yaml`/`categorization.md`/skills internally (delegated — FR-008).
- A hard requirement to pass every historical feature dir (pre-contract + carve-out dirs; research R2). CI pins `specs/000-sample` as the golden.
