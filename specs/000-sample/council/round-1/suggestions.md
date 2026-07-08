# Suggestions — Round 1

> Fixture. Stage 3: chairman synthesis. **The only file in `council/` the main thread reads**
> (`docs/10` §6, `artifact-layout.md` §4). Suggestion IDs assigned here, never renumbered.

## Verdict

**0 blocking · 2 strong · 2 consider.** No revision cycle is forced (`docs/10` §5.2 — straight to
the human gate). Members converged; the peer round produced one withdrawal and no new disputes.

## Suggestions

| ID | Class | Suggestion |
|---|---|---|
| `R1-S01` | strong | The risk register omits the fixture's real failure mode: hand-authoring can encode a *misreading* of a contract, and a checker written from the same misreading would pass it. State it. |
| `R1-S02` | strong | The fixture exercises `decision-record.md` R3 (rejection requires reasoning) nowhere — the record will contain only accepted rows. Ensure at least one rejection and one deferral. |
| `R1-S03` | consider | Rename `000-sample` → `000-fixture`. "Sample" reads as "example feature you may copy." |
| `R1-S04` | consider | Ship a machine-readable conformance checker alongside the fixture, so drift is caught by CI rather than by review. |

## Chairman note

`R1-S02` is the round's find. It was reached by reading the contract the artifact is meant to
exercise, not by reading the plan — which is the behaviour D10's graphify tooling exists to
encourage, generalized from code to contracts.

`R1-S03` is classed `consider` rather than `strong` because the name is fixed by the M0 kickoff
prompt (`docs/95`), which the council does not have standing to overrule.
