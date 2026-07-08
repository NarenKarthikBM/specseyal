# Decision Record — 000-sample

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).
> Fixture: commit SHAs below are placeholders (`0000000`) — the fixture predates the git extension (M2).

## Metadata

| Field | Value |
|---|---|
| feature | `000-sample` |
| spec-id | `000-sample` |
| profile | `gates.council=human, gates.workforce=human` |
| rounds-run | 1 |
| schema-version | `1.0` |

---

## Round 1 — 2026-07-08T14:02:11Z

**Verdict:** 0 blocking · 2 strong · 2 consider
**Deck reviewed:** `council/defense-deck/technical.md` @ `0000000`
**Plan reviewed:** `plan.md` @ `0000000`

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | strong | Risk register omits the "fixture encodes a misreading" failure mode | accepted | — | `plan.md §4` @ `0000000` |
| R1-S02 | strong | Fixture exercises `decision-record.md` R3 nowhere | accepted | — | `council/decision-record.md` rows R1-S03, R1-S04 @ `0000000` |
| R1-S03 | consider | Rename `000-sample` → `000-fixture` | rejected | The directory name is fixed by the M0 kickoff prompt (`docs/95` Part 2, step 3), which the council has no standing to overrule. The "copyable example" misreading is addressed instead by `README.md`, which opens with "This is not a feature." Reopen as a D-row if the misreading occurs in practice. | — |
| R1-S04 | consider | Ship a machine-readable conformance checker with the fixture | deferred | Sound, and out of M0's scope — M0 ships contracts, not tooling. A checker written now would encode the contracts a second time before a single real feature has tested them (the exact objection the plan raises against generating the fixture). Filed as **I-11** in `docs/90`; earliest sensible home is M1, where the first real feature gives the checker something other than the fixture to run against. | — |

### Chairman delta check

*Only present when Round N raised `blocking` items.* — omitted (no blocking items).

---

## Human Gate — 2026-07-08T15:40:02Z

| Field | Value |
|---|---|
| reviewer | Babu |
| decision | `approved` |
| reviewed | `defense-deck/overview.md`, `round-1/suggestions.md`, this record |

**Notes:** Fixture. The gate section is authored as part of the fixture and records no real review;
`000-sample` never runs. A real feature's gate section is appended by a human, or by triage under
`gates.council.mode: auto` with `reviewer: auto`.

**Overrides:** none.

---

## Carried Constraints

> Accepted suggestions that constrain task generation. `/speckit-tasks` reads this section
> and nothing else from this file.

- `R1-S01` — the plan's risk register must name the misreading failure mode. Any task that edits
  `plan.md §4` must preserve that row.
- `R1-S02` — the fixture must contain at least one `rejected` and one `deferred` disposition.
