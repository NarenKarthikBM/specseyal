# Phase 1 Data Model — speckit-ext-council

The council's "data" is its **artifact tree** and the **internal formats** the M0 contracts don't already fix. Contract-defined artifacts (`decision-record.md`, `traces.jsonl`, `profile.yaml`) are referenced, not redefined.

## Artifact tree (per `artifact-layout.md` §1)

```text
specs/NNN-feature/council/
├── defense-deck/
│   ├── technical.md          # Session A — for members
│   └── overview.md           # Session A — one page, for the human gate
├── round-N/
│   ├── opinions/
│   │   ├── A.md … E.md        # stage 1, independent, anonymized      [chairman-only]
│   │   └── peer/ A.md … E.md  # stage 2, anonymized peer review        [chairman-only]
│   └── suggestions.md        # stage 3, chairman — the ONLY main-thread read
└── decision-record.md        # triage + gate; append-per-round        [decision-record.md]
```

Round-scoped artifacts live under `round-N/` and are never overwritten; `defense-deck/` is overwritten in place on revision (D38, git-versioned).

## Entities

### Deck (`defense-deck/technical.md`, `overview.md`)
| Field (technical) | Notes |
|---|---|
| Problem restatement | from spec.md |
| Chosen approach + **rejected alternatives with reasons** | from plan.md |
| Dependency / graph impact | from graphify-context.md |
| Risk register | from plan.md |
| Cost / complexity estimate | session count + model mix |
| Testability claim | how FRs/SCs are verified |

Overview (one page): what & why · what could go wrong · what it costs · what "done" looks like.

### Opinion (`round-N/opinions/<A–E>.md`, `.../peer/<A–E>.md`)
A member's review. It opens with a metadata line recording the member's **lens** (`correctness` / `risk` / `simplicity` / `testability` / `sequencing`, S4) — kept as future v2 evidence of which lens raised which suggestion; the lens is a review angle, not the member's identity, so it does not de-anonymize (FR-006). Then free-form markdown that MUST end with a **machine-liftable suggestion list** the chairman consolidates:
```markdown
---
lens: correctness
---
<review prose>

## Suggestions
- [correctness] The migration and schema edit are bundled; split them. (confidence: high)
- [risk] No rollback path for the partial-write case. (confidence: med)
```
Anonymized: the file letter is the only identity; the letter→member map is never persisted (FR-006).

### Suggestion (row in `suggestions.md`, and in `decision-record.md`)
| Field | Domain | Set by |
|---|---|---|
| `id` | `R<round>-S<nn>`, never renumbered | chairman |
| `class` | `blocking` \| `strong` \| `consider` | chairman (D13) |
| `text` | the consolidated suggestion | chairman |
| `sources` | which lenses/opinions raised it (anonymized) | chairman |
| `target` | `plan.md §<section>` the suggestion touches | chairman |

### `suggestions.md` (chairman synthesis — the compression boundary)
```markdown
# Suggestions — Round N
> ⚠ Reduced grounding: no graph   ← present ONLY when graph.json was absent (FR-019)

**Verdict:** <a> blocking · <b> strong · <c> consider

| ID | Class | Suggestion | Sources | Target |
|----|-------|-----------|---------|--------|
| R1-S01 | blocking | Split the migration from the schema change | A, E | plan.md §4 |
| R1-S02 | strong   | Cache the user lookup | C | plan.md §6 |

## Chairman's note
<1–3 sentences: overall verdict, and — after a revision — the delta-check result.>
```
This is the **only** council artifact the main thread reads (context hygiene). It is the input to `/speckit-council-triage`.

### Decision record (`decision-record.md`)
Defined by `decision-record.md` (contract). The council extension is its writer: triage appends the round table (every suggestion → disposition + reasoning), the `### Chairman delta check`, any `## Reopen`, and `## Carried Constraints`; `/speckit-council-approve` appends `## Human Gate`.

### Trace fragment (returned by each subagent → assembled into `traces.jsonl`)
Every field of `trace-schema.md` §1. For council roles: `agent_id: null`, `skills: []`, `elevated_grants: []`, `cost_usd: null`. `role ∈ {deck-prep, council-member, chairman, triage}`; `model` the exact ID per D18. The orchestrator stamps `parent_trace_id` (its own trace) and appends serially.

## Lifecycle / state transitions

```
deck-prep done        ⟺ defense-deck/{technical,overview}.md exist
council round N done   ⟺ round-N/suggestions.md exists
triage done            ⟺ decision-record.md has a Round-N table (every suggestion dispositioned)
blocking present       ⟹ one revision + ### Chairman delta check before the gate
gate done              ⟺ decision-record.md has a ## Human Gate (last one authoritative)
tasks unlocked         ⟺ gate decision ∈ {approved, approved-with-notes}
```

State is inferred from these artifacts alone (Constitution III / D32) — there is no state file.

## Validation rules (feed the conformance check / `/speckit-analyze`)

- Every `suggestions.md` row has a unique `R<n>-S<nn>` id and a class ∈ {blocking, strong, consider}.
- Every id in `suggestions.md` appears exactly once in `decision-record.md` with one disposition; `rejected`/`deferred` ⟹ non-empty rationale (D13.5).
- `blocking` + `accepted` ⟹ a `plan-delta` naming the commit (decision-record R4).
- No file under `specs/NNN/` outside `council/` mentions the `opinions/` path (SC-005).
- Reduced-grounding banner in `suggestions.md` ⟺ the round ran without a graph (FR-019).
