# Implementation Plan — 000-sample

> Fixture. Revised once, in Round 1 triage (see `council/decision-record.md`).

## Chosen approach

Hand-author each artifact against its contract, in the phase order of `artifact-layout.md` §2.

## Rejected alternatives

- **Generate the tree from a script.** A generator would encode the contracts a second time, and
  the two encodings would drift. The fixture is the encoding.
- **Skip the fixture; validate contracts against the first real feature (M1).** Then a contract bug
  and a council bug would surface in the same commit, and neither would be diagnosable.

## Dependency / graph impact

None. No file outside `specs/000-sample/` is touched.

## Risk register

| Risk | Mitigation |
|---|---|
| Fixture drifts from the contracts | Contract changes and fixture changes land in the same commit (`README.md`) |
| Fixture mistaken for a real feature | `NNN=000` reserved; `README.md` says so twice |
| **Fixture encodes a *misreading* of a contract, and a checker written from the same misreading passes it** | Inherent to hand-authoring; unfixable here. Mitigated only when M1's first real feature exercises the contracts independently. *(added Round 1, `R1-S01`)* |

## Cost / complexity

Negligible. No sessions are spawned; no tokens are spent implementing it.

## Testability claim

Falsifiable by construction: a conformance checker either passes this directory or it does not.

## Sections

- §1 Chosen approach
- §2 Rejected alternatives
- §3 Dependency / graph impact
- §4 Risk register — *revised in Round 1, per `R1-S01`*
- §5 Cost / complexity
- §6 Testability claim
