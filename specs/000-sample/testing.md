# Testing Doc — 000-sample

> Fixture. Produced by the testing agent (M4, doc-only — the agent writes the doc; running the tests
> is I-3, post-v1).

## What "tested" means for this feature

`000-sample` ships no code, so there is nothing to unit-test. Its correctness claim is *conformance*:
every artifact validates against the contract that names it.

## Test plan

| # | Assertion | Contract | Status |
|---|---|---|---|
| 1 | Directory name matches `^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$` | `artifact-layout.md` §7.1 | manual ✓ |
| 2 | Every artifact in `artifact-layout.md` §1 is present | §7.2 | manual ✓ |
| 3 | No artifact exists whose upstream phase is incomplete | §7.3 | manual ✓ |
| 4 | `traces.jsonl` has ≥1 record per session-running phase | §7.4 | manual ✓ |
| 5 | No file outside `council/` mentions the chairman-only opinions subtree | §7.5 | manual ✓ |
| 6 | `profile.yaml` satisfies P1–P4 | `profile-schema.md` §2 | manual ✓ |
| 7 | Every suggestion has exactly one disposition | `decision-record.md` R2 | manual ✓ |
| 8 | Every `rejected`/`deferred` carries a rationale | R3 | manual ✓ |
| 9 | Every trace record has all §1 fields; `agent_id ≠ null ⟺ role = implementer` | `trace-schema.md` §7 | manual ✓ |
| 10 | `body_sha256` matches the prompt body, for the base **and** the skill | `agent-library-schema.md` §6.7 | manual ✓ |
| 11 | Every taxonomy key is drawn from the closed enums (8 types, 11 specializations) | `taxonomy-v0.md` §2, §4 | manual ✓ |
| 12 | `count(general) ≤ 0.20 × count(tasks)` | `taxonomy-v0.md` §4 | manual ✓ |
| 13 | The base declares no `tags`; the skill declares no `type`, `specialization`, or `model` | `agent-library-schema.md` §6.5, `skill-module.md` §6.5 | manual ✓ |
| 14 | Every assembled agent's grant set is displayed on the roster | `skill-module.md` §4, D41 | manual ✓ |
| 15 | The skill body adds obligations only — no override of the base (S1–S3) | `skill-module.md` §3 | manual ✓ |

## Why every status says "manual"

There is no checker. `R1-S04` proposed one and it was **deferred** (`council/decision-record.md`),
filed as **I-11**. Until it exists, these fifteen assertions are verified by reading — which is exactly
the weakness `R1-S01` recorded in the plan's risk register: a reader who misread a contract will
verify the fixture against the misreading.

Assertion 15 is the clearest case. S1–S3 are stated as machine-checkable in `skill-module.md` §3, and
nothing checks them. S4 (contradictory skill pairs) is not checkable at all, by that contract's own
admission.

## Recommended follow-up

I-11's checker should be written by someone who has *not* read this fixture, working from
`docs/contracts/` alone. Otherwise it inherits the fixture's misreadings and certifies them.
