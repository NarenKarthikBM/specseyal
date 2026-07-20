# Feature Specification — violation-assembly-cap-exceeded

> Fixture (T007, `specs/008-pre-public-maintenance/fixtures/`). Not a real feature — it exists
> only to exercise `check-conformance.py`'s both-branch contract coverage
> (`contracts/conformance-checker-command.md`). Ships no code.

## Summary

A minimal, deterministic feature dir used only to give the conformance checker something to
validate. Its correctness claim is *conformance*: every artifact validates against the contract
that names it (the same posture `specs/000-sample/testing.md` states for that fixture).

## Functional Requirements

- **FR-001**: The fixture directory MUST contain one artifact per completed phase in
  `artifact-layout.md` §2.
- **FR-002**: Every trace record in `traces.jsonl` MUST validate against `trace-schema.md` §1/§7.

## Success Criteria

- **SC-001**: `check-conformance.py <this-dir>` exits `0` once T008 lands.
- **SC-002**: Every artifact present in this tree validates against its named `docs/contracts/`
  schema.
