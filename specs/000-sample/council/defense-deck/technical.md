# Defense Deck (technical) — 000-sample

> Fixture. Produced by Session A (deck-prep). Read by council members.
> Contents per `docs/10` §3. Overwritten in place on revision (`artifact-layout.md` §4).

## Problem restatement

`docs/contracts/` describes artifacts nothing has produced. Contracts unexercised are hypotheses.

## Chosen approach

Hand-author one valid instance of every artifact, in phase order.

## Rejected alternatives, with reasons

| Alternative | Rejected because |
|---|---|
| Generate the tree from a script | A second encoding of the contracts; the two drift |
| Defer to M1's first real feature | Contract bugs and council bugs would land together, undiagnosable |

## Dependency / graph impact

Zero edges. `specs/000-sample/` is a leaf.

## Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| Fixture drifts from contracts | medium | Same-commit rule |
| Fixture mistaken for a real feature | low | Reserved ordinal + README |

## Cost / complexity estimate

Zero sessions. Zero implementation tokens.

## Testability claim

A conformance checker passes this directory or fails it. Nothing in between.
