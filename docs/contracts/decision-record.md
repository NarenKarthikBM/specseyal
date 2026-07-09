# Contract — `council/decision-record.md`

> **Status:** 1.1 (M0, amended 2026-07-10 by **D55** — `## Human Gate` gains the FR-008 `gates.yml` pointer). Normative.
> **Implements:** docs/10 §5 (convergence rule), D13, D13.5, D14, **D55** (well-known-path gate-binding pointer).
> **Consumed by:** the human gate, `/speckit-tasks`, and the central manager (M5).

The decision record is the council's audit trail. Its single reason to exist: **a suggestion may be rejected, but it may not be silently dropped.** Every suggestion the council raises leaves a row here with a disposition, and every non-acceptance carries written reasoning (docs/10 §5.5).

---

## 1. Rules

| # | Rule |
|---|---|
| R1 | **Append-only.** A new round appends a section. No prior section is ever edited or deleted. |
| R2 | Every suggestion in `round-N/suggestions.md` appears exactly once, with exactly one disposition. |
| R3 | `disposition ∈ {rejected, deferred}` ⟹ non-empty `rationale`. This is D13.5, and it is the contract's whole point. |
| R4 | `class: blocking` + `disposition: accepted` ⟹ a non-empty `plan-delta` naming the commit that applied it. |
| R5 | `class: blocking` + `disposition: rejected` ⟹ the human gate section must acknowledge it explicitly. The chairman classifies; only a human overrides a `blocking`. |
| R6 | A `## Human Gate` section may appear more than once (a rejection sends the plan back for one more round — docs/10 §5). The last one is authoritative. |
| R7 | The file exists as soon as round 1 is triaged, even if every suggestion was accepted. |

Suggestion IDs are `R<round>-S<nn>`, assigned by the chairman in `suggestions.md` and never renumbered.

## 2. Format

````markdown
# Decision Record — 000-sample

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).

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

**Verdict:** 0 blocking · 2 strong · 3 consider
**Deck reviewed:** `council/defense-deck/technical.md` @ `abc1234`
**Plan reviewed:** `plan.md` @ `abc1234`

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | strong | Split the migration from the schema change | accepted | — | `plan.md §4` @ `def5678` |
| R1-S02 | strong | Cache the user lookup | rejected | Premature: no measurement, and the lookup is behind an existing memoized accessor. Revisit if the perf budget in §7 is missed. | — |
| R1-S03 | consider | Name the table `saved_search` (singular) | deferred | Repo convention is plural; a rename is a separate cross-cutting change. Filed as I-nn. | — |

### Chairman delta check

*Only present when Round N raised `blocking` items.* — omitted (no blocking items).

---

## Human Gate — 2026-07-08T15:40:02Z

| Field | Value |
|---|---|
| reviewer | Babu |
| decision | `approved` |
| reviewed | `defense-deck/overview.md`, `round-1/suggestions.md`, this record |

**Notes:** R1-S02's rejection is sound; the perf budget makes it falsifiable.

**Overrides:** none.

**Binding:** plan↔SHA binding recorded at `specs/000-sample/gates.yml` (git-ext-owned; FR-008/D55).

---

## Carried Constraints

> Accepted suggestions that constrain task generation. `/speckit-tasks` reads this section
> and nothing else from this file.

- `R1-S01` — the migration is its own task; it may not be bundled with the schema edit.
````

## 3. Field values

| Field | Domain |
|---|---|
| `class` | `blocking` \| `strong` \| `consider` — set by the chairman (D13), overridable only at the human gate |
| `disposition` | `accepted` \| `rejected` \| `deferred` |
| `plan delta` | `<file> §<section> @ <commit-sha>`, or `—` |
| `decision` (gate) | `approved` \| `approved-with-notes` \| `rejected` |
| `Binding` (gate) | a one-line pointer to the git-extension-owned `specs/<spec-id>/gates.yml` — the plan↔SHA gate binding (FR-008/D55). **Present when the git extension is installed** (it records the binding via its `after_council_approve` hook, D55); **omitted** in a council-only repo with no `gates.yml`. This section never carries the SHA itself: the git ext owns that record, and principle I keeps the council artifact single-writer (D55). The pointer is written by the section's own author — `/speckit-council-approve` (human) or `/speckit-council-triage` (auto) — never by the git ext. |

`deferred` means *acknowledged, not now, and recorded somewhere it will resurface* — the rationale must name where (an `I-` row in docs/90, a follow-up spec). A `deferred` with nowhere to resurface is a `rejected` wearing a nicer word.

## 4. Reopened plans (D14)

When a severe `/speckit-analyze` finding reopens a council-defended plan, append:

```markdown
## Reopen — 2026-07-09T09:12:00Z

| Field | Value |
|---|---|
| trigger | `/speckit-analyze` finding `A-03` (severity: severe) |
| tier | `delta` |
| tier proposed by | triage |
| tier confirmed by | human gate |
| scope | `plan.md §5` diff only |
```

`tier` is `delta` \| `full`. Default `delta`; `full` iff the patch changes the plan's chosen approach or architecture. The triage step proposes; the human gate may override in either direction (docs/10 §5, D14). A `delta` reopen then appends a normal `## Round N` section whose suggestions were raised against the diff alone.

## 5. Sections

| Section | Cardinality | Required |
|---|---|---|
| `# Decision Record — <spec-id>` | 1 | yes |
| `## Metadata` | 1 | yes |
| `## Round N` | ≥1, ascending, contiguous | yes |
| `### Chairman delta check` | 0..1 per round | iff that round raised `blocking` items |
| `## Reopen` | 0..n | iff D14 triggered |
| `## Human Gate` | ≥1 (R6) | yes, unless `gates.council.mode: auto` |
| `## Carried Constraints` | 1, last | yes (may be empty) |

Validation is these seven rows plus R1–R7. A record that satisfies them is complete regardless of prose quality; a record that violates R3 is invalid no matter how well written.

## 6. Non-goals (v1)

- No machine-readable sidecar (YAML/JSON). The record is read by humans at the gate and by an LLM at `/speckit-tasks`; both read markdown. A sidecar becomes worthwhile only when the central manager needs to query across features (M5) — and then it is *derived* from this file, never authoritative.
- No suggestion-level threading or reply chains. One round, one table.
- No cross-feature suggestion IDs. `R1-S01` is scoped to its feature.
