# Trace fragment — council sessions

**Scope:** how `/speckit-council` and `/speckit-council-triage` each produce the one trace fragment `trace-schema.md` requires per session (principle 4). This file fixes the council-specific values and the emission mechanics; it never redefines the schema itself.

> **Authoritative schema:** `docs/contracts/trace-schema.md` — **1.2** (§1 record, §2 role enum, §5 rollups, §7 validation).
> **Also implements:** `specs/001-council-extension/data-model.md` ("Trace fragment" entity) · D18 (model policy) · D47 / `extensions/council/docs/token-capture-spike.md` (`capture_method`) · `research.md` R-D3 (serial append) · `spec.md` S2 (status-only returns).
> **Does not apply to:** `/speckit-council-approve` — see §6, it emits no trace at all.

---

## 1. Who emits one

Per round, `/speckit-council` dispatches **12 sessions** — 1 deck-prep, 10 council-member (5 members × 2 stages: independent opinion, then anonymized peer review), 1 chairman — and `/speckit-council-triage` runs as its own single session, for **13 sessions** total across both skills. Every one of them returns exactly **one** trace fragment when it ends: `trace-schema.md` requires this of "every session in every phase… No exceptions." That matches `plan.md`'s own accounting: "Every session (deck-prep, 10 member, chairman, triage) emits one trace record."

## 2. Fragment shape — fixed council values

Every field in `trace-schema.md` §1 is present on a council fragment. These are **fixed**, regardless of role:

| Field | Value | Why (schema rule) |
|---|---|---|
| `agent_id` | `null` | Non-null **iff** `role == "implementer"` (§1 field table; §7 rule 4). No council role is `implementer`. |
| `skills` | `[]` | `skills != []` ⟹ `role == "implementer"` (§7 rule 5) — only an assembly injects skills; no council role is an assembly. |
| `elevated_grants` | `[]` | `elevated_grants != []` ⟹ `role == "implementer"` (§7 rule 6). |
| `cost_usd` | `null` | D28 — subscription-only billing; there is no per-call price to record (§4). |
| `schema_version` | `"1.0"` | The **record's own** version field — not the contract document's status. `trace-schema.md` is at doc-status **1.2**, but the field itself has stayed `"1.0"` since M0 (§1 field table; every record in `specs/000-sample/traces.jsonl` confirms it). Never write `"1.2"` into this field. |

Everything else — `role`, `phase`, `model`, `effort`, timestamps, `tokens`, `capture_method`, `outcome`, `artifact` — is populated per the session that produced the fragment (§3, §4).

### 2.1 Canonical example (`council-member`, the modal case — 10 of every round's 13 sessions)

```json
{
  "schema_version": "1.0",
  "trace_id": "trc_01J9Z1CNCLMEMBA01",
  "parent_trace_id": "trc_01J9Z0CNCLORCH001",
  "feature": "021-rate-limits",
  "phase": "council",
  "role": "council-member",
  "agent_id": null,
  "skills": [],
  "elevated_grants": [],
  "model": "claude-sonnet-5",
  "effort": "medium",
  "started_at": "2026-07-09T10:05:00.000Z",
  "ended_at": "2026-07-09T10:05:58.000Z",
  "duration_ms": 58000,
  "tokens": { "input": 15600, "output": 1800, "cache_read": 4400, "cache_creation": 0 },
  "capture_method": "transcript",
  "outcome": "success",
  "artifact": null,
  "cost_usd": null
}
```

`artifact: null` here is **not** a missing value. A member session does write `round-N/opinions/<letter>.md` (or `.../peer/<letter>.md`), but per `trace-schema.md` §1: *"a council member's opinion is chairman-only, not an artifact-out."* `opinions/` is chairman-only-read (`artifact-layout.md` §4); the trace deliberately hands the main thread no pointer into it.

## 3. How role changes the fragment

| `role` | `phase` | `model` (D18) | `effort` | `artifact` |
|---|---|---|---|---|
| `deck-prep` | `deck-prep` | `claude-sonnet-5` | `medium` | `specs/NNN-feature/council/defense-deck/` — the two-file bundle, one artifact-out (principle 1) |
| `council-member` | `council` | `claude-sonnet-5` | `medium` | `null` — §2.1 |
| `chairman` | `council` | `claude-opus-4-8` | `xhigh` | `specs/NNN-feature/council/round-N/suggestions.md` — the one artifact `/speckit-council` returns (the compression boundary, `data-model.md`) |
| `triage` | `triage` | `claude-opus-4-8` | `xhigh` | `specs/NNN-feature/council/decision-record.md` — the append; the accompanying `plan.md` revision is real but is not the fragment's `artifact` (matches the `role: triage` record in `specs/000-sample/traces.jsonl`) |

`model` is always the **exact** id, never an alias (`sonnet`/`opus`) — `trace-schema.md` §1: "Aliases move; a trace is a historical claim." `effort` is never `null` for a council fragment: D18 names an effort for every role above, so it is always recorded.

The other three roles, same shape, showing the variance above:

```json
[
  {
    "schema_version": "1.0",
    "trace_id": "trc_01J9Z1CNCLDECKP01",
    "parent_trace_id": "trc_01J9Z0CNCLORCH001",
    "feature": "021-rate-limits",
    "phase": "deck-prep",
    "role": "deck-prep",
    "agent_id": null,
    "skills": [],
    "elevated_grants": [],
    "model": "claude-sonnet-5",
    "effort": "medium",
    "started_at": "2026-07-09T10:00:00.000Z",
    "ended_at": "2026-07-09T10:03:30.000Z",
    "duration_ms": 210000,
    "tokens": { "input": 9800, "output": 2200, "cache_read": 0, "cache_creation": 4400 },
    "capture_method": "transcript",
    "outcome": "success",
    "artifact": "specs/021-rate-limits/council/defense-deck/",
    "cost_usd": null
  },
  {
    "schema_version": "1.0",
    "trace_id": "trc_01J9Z1CNCLCHAIR01",
    "parent_trace_id": "trc_01J9Z0CNCLORCH001",
    "feature": "021-rate-limits",
    "phase": "council",
    "role": "chairman",
    "agent_id": null,
    "skills": [],
    "elevated_grants": [],
    "model": "claude-opus-4-8",
    "effort": "xhigh",
    "started_at": "2026-07-09T10:20:00.000Z",
    "ended_at": "2026-07-09T10:22:15.500Z",
    "duration_ms": 135500,
    "tokens": { "input": 41203, "output": 3877, "cache_read": 118400, "cache_creation": 12010 },
    "capture_method": "transcript",
    "outcome": "success",
    "artifact": "specs/021-rate-limits/council/round-1/suggestions.md",
    "cost_usd": null
  },
  {
    "schema_version": "1.0",
    "trace_id": "trc_01J9Z1CNCLTRIAGE1",
    "parent_trace_id": null,
    "feature": "021-rate-limits",
    "phase": "triage",
    "role": "triage",
    "agent_id": null,
    "skills": [],
    "elevated_grants": [],
    "model": "claude-opus-4-8",
    "effort": "xhigh",
    "started_at": "2026-07-09T14:00:00.000Z",
    "ended_at": "2026-07-09T14:05:40.000Z",
    "duration_ms": 340000,
    "tokens": { "input": 7300, "output": 4100, "cache_read": 12010, "cache_creation": 0 },
    "capture_method": "transcript",
    "outcome": "success",
    "artifact": "specs/021-rate-limits/council/decision-record.md",
    "cost_usd": null
  }
]
```

`triage`'s `parent_trace_id` is `null` because `/speckit-council-triage` runs as its own top-level main-thread session (`artifact-layout.md` §2: `triage | main | …`), not as a subagent some other session dispatched — the same pattern the `role: triage` record in `specs/000-sample/traces.jsonl` uses.

## 4. `capture_method` policy (`token-capture-spike.md`, D47)

`capture_method ∈ {transcript, sdk, unavailable}`. `tokens` is the 4-field object **iff** `capture_method != "unavailable"`; it is the literal JSON `null` — the whole object, not zeros — **iff** `capture_method == "unavailable"` (`trace-schema.md` §1, §7 rule 10).

1. **`transcript`** — the policy for every interactive council session today (T005's spike outcome: **SUCCESS**). The trace-writer:
   1. reads the Claude Code session transcript JSONL (`~/.claude/projects/<project>/<session>.jsonl`);
   2. isolates the subagent's own message subtree using `isSidechain: true` together with its `sessionId` / `uuid` / `parentUuid` chain;
   3. sums that subtree's per-message `usage` fields — `input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens` — into `tokens.{input, output, cache_read, cache_creation}` (a 1:1 field mapping, spike finding 1).
   The Agent-tool completion return's `subagent_tokens` aggregate is a **cross-check only** — a convenient total, but it lacks the 4-way breakdown, so it never substitutes for the transcript sum (spike finding 3).
2. **`sdk`** — the M6 path: once the Agent SDK drives council sessions, `tokens` comes directly from the SDK/API response's usage metadata. Not available to any M0–M5 interactive council skill; recorded now so the trace-writer's shape doesn't change when M6 lands. (`trace-schema.md` §1's `implementer` example already shows this shape in practice — same four fields, `capture_method: "sdk"`.)
3. **`unavailable`** (`tokens: null`) — the honest fallback, used **only** when attribution fails: the transcript is absent, or its format has drifted since the spike validated it (the spike's own caveat: the transcript shape is version-specific). **Never emit a guessed or estimated token count in its place** — this is the same exact-or-null ethos as `cost_usd: null` (D35/D47). A fragment with `capture_method: "unavailable"` still has every other field populated normally; only `tokens` is null.

Fallback shape (any of the four roles — shown here for `council-member`):

```json
{
  "schema_version": "1.0",
  "trace_id": "trc_01J9Z1CNCLMEMBB02",
  "parent_trace_id": "trc_01J9Z0CNCLORCH001",
  "feature": "021-rate-limits",
  "phase": "council",
  "role": "council-member",
  "agent_id": null,
  "skills": [],
  "elevated_grants": [],
  "model": "claude-sonnet-5",
  "effort": "medium",
  "started_at": "2026-07-09T10:06:00.000Z",
  "ended_at": "2026-07-09T10:06:47.000Z",
  "duration_ms": 47000,
  "tokens": null,
  "capture_method": "unavailable",
  "outcome": "success",
  "artifact": null,
  "cost_usd": null
}
```

An `unavailable` fragment still rolls up honestly: `tokens_billable` treats it as `0`, and `trace-schema.md` §5 requires every consumer of `council_spend` to also report the **count** of `capture_method: unavailable` records alongside the sum — never presenting a partial sum as the whole (D47).

## 5. Orchestrator-serialized append — never parallel

Two rules, both non-negotiable:

1. **Subagents return status only.** A deck-prep, council-member, or chairman subagent's return value is a path + one-line outcome + its trace fragment — never file content, never an opinion body (`spec.md`'s status-only-returns invariant, S2 / SC-005). The fragment itself is already bodiless by contract (`trace-schema.md` §3, "No message bodies") — it carries identity and timing metadata only.
2. **The orchestrating session appends fragments to `specs/NNN-feature/traces.jsonl` itself, one at a time, immediately after each stage barrier — never as a parallel or concurrent write.** `/speckit-council` holds stage barriers (deck-prep → stage-1 opinions ×5 → stage-2 peer review ×5 → chairman); at each barrier the orchestrator collects that barrier's returned fragment(s) and appends them **serially** before dispatching the next stage. Per `data-model.md`'s "Trace fragment" entity, the orchestrator also **stamps `parent_trace_id`** on each collected fragment with its own `trace_id` before appending. `/speckit-council-triage` runs no subagents — it is a single session, so it appends its own one fragment once, at the end of its own run; trivially serial, since there is nothing to interleave with.

Why this is load-bearing: `traces.jsonl` is JSON Lines — one object per line, and no line is ever rewritten (`trace-schema.md` §7 rules 1 and 8). Five members finishing stage 1 concurrently and each writing directly to that file would interleave partial writes mid-line and corrupt it. Serial, orchestrator-owned assembly is the only path that keeps the file valid — precisely the race `research.md` R-D3 ruled out under its rejected alternative ("per-subagent direct append… corruption risk").

## 6. `/speckit-council-approve` writes no trace

`/speckit-council-approve` is the `council-gate` phase (`artifact-layout.md` §2). It appends a `## Human Gate` section to `decision-record.md` — reviewer, decision, reviewed artifacts, notes, overrides (`decision-record.md` contract §2) — recording a **human's** decision (or, under `full_auto`, a deterministic auto-approval with `reviewer: auto`). No Claude session runs to produce that section.

`artifact-layout.md` §2 names exactly three phases that run no session at all: `branch`, `council-gate`, `workforce-gate`. `council-gate` is what `/speckit-council-approve` implements. It therefore **emits zero trace fragments** — this template does not apply to it, and its skill must not invoke any trace-writer path. (`traces.jsonl` validation rule 9 already expects this: only phases that run a session need ≥1 record.)
