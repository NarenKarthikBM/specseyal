# Trace fragment — testing sessions

**Scope:** how `/speckit-testing` produces the one trace fragment `trace-schema.md` requires per
session (principle 4), for its single dispatched `tester` role. This file fixes the tester-specific
values, documents the `context_in` addition (R1-S06), and describes the emission mechanics; it
never redefines the base schema itself.

> **Authoritative schema:** `docs/contracts/trace-schema.md` — **1.2** (§1 record, §2 role enum, §7 validation).
> **Also implements:** `specs/004-testing-completion/data-model.md` ("TesterAssembly" entity) · D18 (model policy: `tester` = Sonnet) · `specs/004-testing-completion/council/decision-record.md` R1-S06 (the `context_in` addition) · `docs/contracts/testing-doc.md` §7 (`context_in` is the auditable record for the SC-003 session-boundary claim) · `specs/004-testing-completion/contracts/commands.md` (the `/speckit-testing` row: status-only return, SC-003, "exactly one record").
> **Does not apply to:** `/speckit-complete` — see §5; the `complete` phase runs in **main** and its one trace record is `role: orchestrator`, not a dispatched-role fragment this template governs.

---

## 1. Who emits one

`/speckit-testing` dispatches exactly **one** session — a Sonnet `tester` subagent, the separate
session `contracts/commands.md` names for context hygiene — and that session emits **exactly one**
trace fragment for the whole `testing` phase (FR-011: "append exactly one trace record";
`contracts/commands.md`'s `/speckit-testing` row: "exactly one record"). Unlike `council`'s
multi-role fan-out (deck-prep, 10 members, chairman across 13 sessions), the `testing` phase has
exactly one role, `tester` (`trace-schema.md` §2's `role` enum row; `data-model.md`'s
"TesterAssembly" entity) — there is no second fragment to reconcile.

## 2. Fragment shape — fixed tester values

Every field in `trace-schema.md` §1 is present on a tester fragment. These are **fixed**, always:

| Field | Value | Why (schema rule) |
|---|---|---|
| `role` | `"tester"` | The phase's one role (`trace-schema.md` §2; `data-model.md` TesterAssembly). |
| `phase` | `"testing"` | `artifact-layout.md` §2's `testing` phase row. |
| `model` | `"claude-sonnet-5"` | D18: `tester` is a mechanical/generative role — Sonnet, never an alias (`trace-schema.md` §1: "Aliases move; a trace is a historical claim"). |
| `effort` | `"medium"` | The Sonnet default this project records for every other mechanical/generative role — `deck-prep`, `council-member`, `categorizer`, `implementer` (`specs/004-testing-completion/traces.jsonl`); D18 names no different effort for `tester`. |
| `agent_id` | `null` | Non-null **iff** `role == "implementer"` (§1 field table; §7 rule 4) — `tester` is not an assembly base. |
| `skills` | `[]` | `skills != []` ⟹ `role == "implementer"` (§7 rule 5) — the tester runs no injected skill. |
| `elevated_grants` | `[]` | `elevated_grants != []` ⟹ `role == "implementer"` (§7 rule 6) — core toolset only (`data-model.md` TesterAssembly: "D67 tripwire clear"). |
| `cost_usd` | `null` | D28 — subscription-only billing; no per-call price to record (§4). |
| `schema_version` | `"1.0"` | The record's own version field — unaffected by `trace-schema.md`'s own document status (currently 1.2). |
| `artifact` | `"specs/<id>/testing.md"` | The one artifact this session produces (principle 1; `data-model.md` TesterAssembly). |

`parent_trace_id` is the dispatching `/speckit-testing` main-thread session's own `trace_id`,
stamped onto the collected fragment by the orchestrator before it appends — the same pattern
`extensions/council/extension/templates/trace-fragment.md` §5 documents for council fragments
(never left as the fragment's own guess). `started_at`, `ended_at`, `duration_ms`, `tokens`,
`capture_method`, and `outcome` are populated per the actual session, under the same
`capture_method` policy (`transcript` \| `sdk` \| `unavailable`, D47) every other role's fragment in
this repo already follows — see that same council template's §4 for the full mechanics; not
re-derived here.

## 3. Canonical example

```json
{
  "schema_version": "1.0",
  "trace_id": "<runtime: trc_ + ULID>",
  "parent_trace_id": "<runtime: the dispatching /speckit-testing session's own trace_id>",
  "feature": "<id>",
  "phase": "testing",
  "role": "tester",
  "agent_id": null,
  "skills": [],
  "elevated_grants": [],
  "model": "claude-sonnet-5",
  "effort": "medium",
  "started_at": "<runtime: ISO-8601 UTC, ms precision>",
  "ended_at": "<runtime: ISO-8601 UTC, ms precision>",
  "duration_ms": "<runtime: ended_at - started_at, ms>",
  "tokens": "<runtime: 4-field object {input, output, cache_read, cache_creation} -- or JSON null iff capture_method == \"unavailable\" (trace-schema.md §7 rule 10)>",
  "capture_method": "<runtime: \"transcript\" | \"sdk\" | \"unavailable\" (D47)>",
  "outcome": "<runtime: \"success\" | \"partial\" | \"failed\" | \"aborted\">",
  "artifact": "specs/<id>/testing.md",
  "cost_usd": null,
  "context_in": [
    "specs/<id>/completion-report.md",
    "specs/<id>/spec.md"
  ]
}
```

Resolve every `<...>` placeholder before appending: `<id>` to the real spec ID (consistently,
across `feature`, `artifact`, and `context_in`); the runtime-filled fields (`trace_id`,
`parent_trace_id`, `started_at`/`ended_at`/`duration_ms`, `tokens`/`capture_method`, `outcome`) to
the values the actual session produced. Every fixed field in §2 is copied verbatim, never
substituted. `skills`/`elevated_grants` stay the literal empty array `[]` — never `null`
(`trace-schema.md` §7 rules 5/6).

## 4. `context_in` — the R1-S06 addition beyond `trace-schema.md` §1

`context_in` is **not** one of `trace-schema.md` §1's base fields — it does not appear in that
file's field table, and that document's own status line (currently **1.2**) has not been bumped to
fold it in. It is the **R1-S06** addition: the council round-1 suggestion "add a context-in field to
the tester trace so an SC-003 violation is auditable"
(`specs/004-testing-completion/council/round-1/suggestions.md`), **accepted** and ratified in
`specs/004-testing-completion/council/decision-record.md` — "the `tester` trace MUST carry a
`context_in` field (files read)" — and characterized in `plan.md` §1.3 as applying "the D43
assembly-provenance spirit" to the tester. `docs/contracts/testing-doc.md` §7 already cites it by
this name — "the auditable record is the tester's trace `context_in` field (`trace-schema.md`,
R1-S06)" — so this template is where that citation is made concrete for the `tester` role, until
(if ever) a future revision of `trace-schema.md` folds it into the base schema project-wide.
`trace-schema.md` §7 rule 2 reads, literally and as written today, "unknown fields are rejected";
`context_in` is a deliberate, council-ratified exception to that rule for this one role's fragment —
flagged here plainly rather than left for a future reader to discover as a silent contradiction.

**Shape:** an array of repo-relative path strings (the same path convention `trace-schema.md` §1
uses for `artifact`), never an array of objects. Exactly the files `contracts/commands.md`'s
`/speckit-testing` row fixes as the tester's context-in boundary:

- `specs/<id>/completion-report.md` and `specs/<id>/spec.md` — **always** present, in every tester
  fragment (the session's mandatory context-in, SC-003).
- `specs/<id>/implement.log.md` — present **only** when the tester actually exercised the R1-S05
  lazy-read cross-check (the D10 on-demand-grounding pattern, applied to a doubt-triggered log read
  rather than a graphify query) for at least one coverage-map row marked `log-verified`. Absent
  otherwise — never added speculatively.

A conforming `context_in` is therefore always exactly the 2-entry array above, or that same 2-entry
array with the log path appended as a 3rd — never any other file, and never empty (an empty
`context_in` would itself misstate the tester's own mandatory context-in, the fact it exists to make
auditable). Order is not a guaranteed/binding property — no consumer should depend on it, the same
disclaimer `trace-schema.md` §1 makes for `skills`' injection order.

## 5. `/speckit-complete` emits no fragment under this template

`artifact-layout.md` §2 names `complete` as a **main**-session phase (`contracts/commands.md`'s
`/speckit-complete` row: "no new model role… the phase's trace is the main-thread orchestrator's own
record"). Its one trace record is filed at `role: orchestrator` — there is no `role: complete` in
`trace-schema.md` §2's enum, and none is needed — so this template, which fixes the
`tester`-specific values above, does not govern it. (Mirrors
`extensions/council/extension/templates/trace-fragment.md` §6, which excludes
`/speckit-council-approve` from that file's scope for the analogous reason: a different phase whose
one session's trace this template's fixed values do not apply to.)
