# Contract — `traces.jsonl` (observability)

> **Status:** 1.0 (M0). Normative.
> **Implements:** principle 4 (observability), D6 (cost is a metric, not a principle), D18, D19 (sync model), D28 (subscription-only), D35.
> **Location:** `specs/NNN-feature/traces.jsonl` — one append-only file per feature.
> **Consumed by:** agent-library `stats` (M3), the M1 exit criterion, the central manager (M5).

Every session in every phase appends exactly one record when it ends. No exceptions, no opt-out (`profile-schema.md` §6). The file is JSON Lines: one object per line, append-only, never rewritten.

---

## 1. Record

```json
{
  "schema_version": "1.0",
  "trace_id": "trc_01J8Z3K9QW7X",
  "parent_trace_id": "trc_01J8Z3K0AAA1",
  "feature": "000-sample",
  "phase": "council",
  "role": "chairman",
  "agent_id": null,
  "model": "claude-opus-4-8",
  "effort": "xhigh",
  "started_at": "2026-07-08T14:00:03.120Z",
  "ended_at": "2026-07-08T14:02:11.902Z",
  "duration_ms": 128782,
  "tokens": { "input": 41203, "output": 3877, "cache_read": 118400, "cache_creation": 12010 },
  "outcome": "success",
  "artifact": "specs/000-sample/council/round-1/suggestions.md",
  "cost_usd": null
}
```

| Field | Type | Notes |
|---|---|---|
| `schema_version` | string | `"1.0"`. |
| `trace_id` | string | Unique per session. Sortable prefix (`trc_` + ULID) so `sort` on the raw file is chronological. |
| `parent_trace_id` | string \| null | The session that spawned this one. `null` for the main thread. Builds the session tree. |
| `feature` | string | Spec ID. Redundant with the path — carried so records survive being concatenated across features. |
| `phase` | enum | One of the phases in `artifact-layout.md` §2. |
| `role` | enum | §2. |
| `agent_id` | string \| null | The `specseyal.id` of the library entry that ran (`agent-library-schema.md`). Non-null iff `role == implementer`. |
| `model` | string | **Exact model ID**, e.g. `claude-opus-4-8`, `claude-sonnet-5`. Never an alias like `sonnet`. Aliases move; a trace is a historical claim. |
| `effort` | enum \| null | `low` \| `medium` \| `high` \| `xhigh` \| `max` \| null. D18 names it (`Opus, xhigh`), so it is recorded. |
| `started_at`, `ended_at` | ISO-8601 UTC, ms precision | |
| `duration_ms` | int | `ended_at − started_at`. Denormalized; it is what every query wants. |
| `tokens` | object | Four non-negative ints: `input`, `output`, `cache_read`, `cache_creation`. All four required. |
| `outcome` | enum | `success` \| `partial` \| `failed` \| `aborted`. Matches implement-parallel's wave-review vocabulary. |
| `artifact` | string \| null | Repo-relative path of the **one** artifact this session produced (principle 1). `null` for sessions that produce none (a council member's opinion is chairman-only, not an artifact-out). |
| `cost_usd` | number \| null | §4. |

## 2. `role` enum

Each role's model is fixed by D18. The trace records what actually ran, so drift from policy is detectable rather than assumed away.

| `role` | Phase | D18 model |
|---|---|---|
| `orchestrator` | main thread, all phases | opus (xhigh) |
| `deck-prep` | deck-prep | sonnet |
| `council-member` | council | sonnet |
| `chairman` | council | opus |
| `triage` | triage | opus |
| `categorizer` | categorize | sonnet |
| `agent-creator` | agent-assign | sonnet |
| `analyzer` | analyze | opus |
| `implementer` | implement | sonnet |
| `wave-reviewer` | implement | opus |
| `tester` | testing | sonnet |

A record whose `(role, model)` contradicts this table is **valid but flagged**. The table is policy; the trace is evidence. Never make the writer enforce the policy — that would silently rewrite the evidence, and the whole point of the trace is to let observability data eventually overturn D18 (Q6).

## 3. No message bodies

A trace record carries **no prompts, no transcripts, no artifact bodies, no tool inputs or outputs**. Only the fields in §1.

Two reasons, and both are load-bearing. Context hygiene (principle 1): a trace that carries bodies re-imports the context the session boundary exists to keep out. Multi-tenancy (D7, D20): traces sync to a central manager shared by work teams and OSS users; a trace file must be safe to ship without redaction review.

Transcripts remain where Claude Code puts them. The trace holds a pointer's worth of identity — `trace_id` — and nothing more.

## 4. `cost_usd` is null, and tokens are the unit of account (D28)

Everything through M7 runs on subscription auth: M0–M5 in interactive sessions, M6+ on the plan's Agent SDK credit. **There is no per-call price.** `cost_usd` is therefore `null` in every record this project will write for the foreseeable future, and the field exists only so that a future API-billed deployment has somewhere to put a number.

Do not synthesize `cost_usd` from public API rates. A number that looks like money but was never charged is worse than no number: it will be summed, charted, and eventually believed.

**Tokens are the currency.** D6 puts cost inside observability as a tracked metric rather than a governing principle; §5 is how it gets tracked.

## 5. Rollups

Defined here so every consumer computes them identically.

```
tokens_billable(r)      = r.tokens.input + r.tokens.output + r.tokens.cache_creation
                          # cache_read excluded: it is the saving, not the spend

phase_spend(f, p)       = Σ tokens_billable(r) for r in f.traces where r.phase == p
feature_spend(f)        = Σ tokens_billable(r) for r in f.traces
council_spend(f)        = phase_spend(f, "council") + phase_spend(f, "deck-prep")
agent_success(a)        = count(r.outcome == "success") / count(r) where r.agent_id == a
```

`council_spend` includes deck prep because the deck exists only to be reviewed. **This is the M1 exit criterion** — "council token spend per feature is measured" (docs/05) — and M1's risk note ("if heavy, trim member count before trimming member tooling") is answerable only against this exact number, computed this exact way.

`agent_success` is the flywheel's promotion input (`agent-library-schema.md` §5).

## 6. D19-readiness: the phase event envelope

M5 pushes phase events to the central manager over MCP. D19 fixes the payloads: **phase completion carries the full artifact + status + trace; mid-phase carries status only, no artifact bodies.** Both envelopes are defined now, so M5 is plumbing rather than design.

```json
{
  "event": "phase.completed",
  "schema_version": "1.0",
  "feature": "000-sample",
  "phase": "council",
  "status": "success",
  "artifact": {
    "path": "specs/000-sample/council/round-1/suggestions.md",
    "sha256": "…",
    "body": "# Suggestions — Round 1\n…"
  },
  "traces": [ { "…": "every trace record with this feature+phase" } ]
}
```

```json
{
  "event": "phase.heartbeat",
  "schema_version": "1.0",
  "feature": "000-sample",
  "phase": "council",
  "status": "running",
  "at": "2026-07-08T14:01:00Z"
}
```

A heartbeat carries **no `artifact` key at all** — not an empty one. D19 chose heartbeats precisely to keep artifact bodies off the wire between boundaries; an `artifact: null` key invites a future patch to fill it in.

`phase.completed` is emitted after the artifact is written and validated, and after the phase's trace records are appended. It is therefore replayable: the manager's state is a fold over these events, and re-sending one is idempotent on `(feature, phase, artifact.sha256)`.

## 7. Validation

The file conforms iff:

1. Every line is a complete JSON object; no line is ever modified after being written.
2. Every record has all §1 fields; unknown fields are rejected.
3. `duration_ms == ended_at − started_at`, within 1 ms.
4. `agent_id != null` ⟺ `role == "implementer"`.
5. `trace_id` is unique within the file; every non-null `parent_trace_id` refers to a `trace_id` in this file or a parent feature's.
6. No value in any record contains a newline (JSONL invariant) — which §3 already guarantees, since only bodies would.
7. Every completed phase in `artifact-layout.md` §2 that runs a session has ≥1 record. `branch`, `council-gate` and `workforce-gate` run no session — a git ref and a human, respectively — and correctly have none.

## 8. Non-goals (v1)

- **No spans, no distributed tracing.** One record per session; `parent_trace_id` gives a tree. Sub-session timing is not observed.
- **No sampling.** Every session, always. The volume is one line per session.
- **No log levels or free-text messages.** A trace is structured evidence, not a log.
