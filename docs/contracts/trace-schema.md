# Contract — `traces.jsonl` (observability)

> **Status:** 1.4 (M0, amended 2026-07-09 by **D43**, **D47**; M4, 2026-07-13 by **D72** — the `tester` role's `context_in` field; M-α, 2026-07-14 by **D77** — the `council-member` role's `graph_queries` + `ceiling_hit` fields). Normative.
> **Implements:** principle 4 (observability), D6 (cost is a metric, not a principle), D18, D19 (sync model), D28 (subscription-only), D35, **D40** (assembly), **D41** (tool grants), **D43** (skill/grant attribution), **D47** (token capture method), **D72** (the `tester` role's `context_in` field, executing `004`-council **R1-S06**), **D77** (the `council-member` role's `graph_queries` + `ceiling_hit` fields, executing `005`-council **R1-S05** — arm 4's query ceiling).
> **Location:** `specs/NNN-feature/traces.jsonl` — one append-only file per feature.
> **Consumed by:** agent-library skill `stats` (M3 flywheel), the M1 exit criterion, the central manager (M5).

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
  "skills": [],
  "elevated_grants": [],
  "model": "claude-opus-4-8",
  "effort": "xhigh",
  "started_at": "2026-07-08T14:00:03.120Z",
  "ended_at": "2026-07-08T14:02:11.902Z",
  "duration_ms": 128782,
  "tokens": { "input": 41203, "output": 3877, "cache_read": 118400, "cache_creation": 12010 },
  "capture_method": "transcript",
  "outcome": "success",
  "artifact": "specs/000-sample/council/round-1/suggestions.md",
  "cost_usd": null
}
```

An `implementer` record, showing a populated assembly (D40/D43) — a `service` base with two injected skills, one of which declared a `web_search` grant:

```json
{
  "schema_version": "1.0",
  "trace_id": "trc_01J8Z4M2RS9P",
  "parent_trace_id": "trc_01J8Z4K0IMPL",
  "feature": "021-rate-limits",
  "phase": "implement",
  "role": "implementer",
  "agent_id": "agt_backend_service",
  "skills": [
    { "id": "skl_rate_limiting", "version": "1.2.0" },
    { "id": "skl_refactor_discipline", "version": "1.0.0" }
  ],
  "elevated_grants": ["web_search"],
  "model": "claude-sonnet-5",
  "effort": "medium",
  "started_at": "2026-07-09T10:15:00.000Z",
  "ended_at": "2026-07-09T10:19:40.000Z",
  "duration_ms": 280000,
  "tokens": { "input": 12000, "output": 3100, "cache_read": 8000, "cache_creation": 0 },
  "capture_method": "sdk",
  "outcome": "success",
  "artifact": "src/services/rate_limit.ts",
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
| `agent_id` | string \| null | The `specseyal.id` of the **base specialist** the assembly dispatched (`agent-library-schema.md` §1.1). Non-null iff `role == implementer`. Before D40 this named "the library entry that ran"; under D40 the thing that runs is an assembly, and this is its base. |
| `skills` | array | The skill modules injected into this assembly (D40, D43). Each element is `{ "id": "skl_…", "version": "x.y.z" }`. **Empty array `[]` when none were injected** — never `null`. Non-implementer roles always carry `[]`. Order is the assignment step's injection order; consumers must not depend on it. |
| `elevated_grants` | array | The union of elevated tool grants active for this dispatch (D41, D43) — the exact set the workforce gate displayed and a human approved. Strings, e.g. `["web_search"]`. `[]` when the assembly ran on the base's core toolset alone. The base's immutable core (`Read, Write, Edit, Bash, Glob, Grep`) is **never** listed — only elevation is auditable. |
| `model` | string | **Exact model ID**, e.g. `claude-opus-4-8`, `claude-sonnet-5`. Never an alias like `sonnet`. Aliases move; a trace is a historical claim. |
| `effort` | enum \| null | `low` \| `medium` \| `high` \| `xhigh` \| `max` \| null. D18 names it (`Opus, xhigh`), so it is recorded. |
| `started_at`, `ended_at` | ISO-8601 UTC, ms precision | |
| `duration_ms` | int | `ended_at − started_at`. Denormalized; it is what every query wants. |
| `tokens` | object \| null | Four non-negative ints: `input`, `output`, `cache_read`, `cache_creation`. All four required **when `capture_method ≠ unavailable`**; the whole object is **`null`** when `capture_method == unavailable` (D47 — exact-or-null, never estimated). |
| `capture_method` | enum | `sdk` \| `transcript` \| `unavailable` (D47). How `tokens` were obtained: `sdk` = Agent SDK / API usage metadata (exact; the M6 path); `transcript` = parsed from the Claude Code transcript JSONL (exact; the interactive path); `unavailable` = not capturable, `tokens` is `null`. Never a fabricated estimate — the `cost_usd`-null ethos (§4) applied to tokens. |
| `outcome` | enum | `success` \| `partial` \| `failed` \| `aborted`. Matches implement-parallel's wave-review vocabulary. |
| `artifact` | string \| null | Repo-relative path of the **one** artifact this session produced (principle 1). `null` for sessions that produce none (a council member's opinion is chairman-only, not an artifact-out). |
| `context_in` | array | **`role: tester` records only** (D72, executing `004`-council **R1-S06**). The repo-relative paths of the files the `tester` session read as its context-in — always `completion-report.md` + `spec.md`, plus `implement.log.md` when the R1-S05 lazy cross-check fired. Strings; order is the read order, consumers must not depend on it. Its purpose is auditability: it puts the tester's declared reads on the record so an SC-003 context-hygiene violation (a tester that read more than it should) is inspectable rather than invisible. **Absent** on every non-`tester` record (not `null`, not `[]` — the key is simply not present); one of the role-scoped §1 fields governed by role rather than being universal (§7 rule 2/11), alongside `graph_queries`/`ceiling_hit` below. |
| `graph_queries` | int | **`role: council-member` records only** (D77, executing `005`-council **R1-S05** — arm 4's query-cost discipline). Non-negative count of the graph queries that member ran during its round, measured against `council-config.yml`'s tier-aware `member.query_ceiling`. **Absent** on every non-`council-member` record (not `null`, not `0` — the key is simply not present); one of the role-scoped §1 fields, alongside `context_in` and `ceiling_hit` (§7 rule 2/12). |
| `ceiling_hit` | bool | **`role: council-member` records only** (D77, executing `005`-council **R1-S05**), always present together with `graph_queries`. Whether that member's query loop hit `council-config.yml`'s enforced `query_ceiling`. Ceiling-hit is never silent (D74): a capped member's opinion carries the reduced-grounding disclosure (FR-019 lineage) in its own output, and this field is the same fact on the trace, so the chairman's weighting of a ceiling-limited opinion is auditable after the round rather than only visible mid-round. **Absent** on every non-`council-member` record (not `null`, not `false` — the key is simply not present); role-scoped alongside `graph_queries` and `context_in` (§7 rule 2/12). |
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

A trace record carries **no prompts, no transcripts, no artifact bodies, no tool inputs or outputs**. Only the fields in §1. `skills` and `elevated_grants` (D43) are *identity and capability metadata* — an id, a version, a tool name — not bodies; they carry no skill prompt text. The no-bodies rule is intact.

Two reasons, and both are load-bearing. Context hygiene (principle 1): a trace that carries bodies re-imports the context the session boundary exists to keep out. Multi-tenancy (D7, D20): traces sync to a central manager shared by work teams and OSS users; a trace file must be safe to ship without redaction review.

Transcripts remain where Claude Code puts them. The trace holds a pointer's worth of identity — `trace_id` — and nothing more.

## 4. `cost_usd` is null, and tokens are the unit of account (D28)

Everything through M7 runs on subscription auth: M0–M5 in interactive sessions, M6+ on the plan's Agent SDK credit. **There is no per-call price.** `cost_usd` is therefore `null` in every record this project will write for the foreseeable future, and the field exists only so that a future API-billed deployment has somewhere to put a number.

Do not synthesize `cost_usd` from public API rates. A number that looks like money but was never charged is worse than no number: it will be summed, charted, and eventually believed.

**Tokens are the currency.** D6 puts cost inside observability as a tracked metric rather than a governing principle; §5 is how it gets tracked.

## 5. Rollups

Defined here so every consumer computes them identically.

```
tokens_billable(r)      = 0 if r.tokens == null else (r.tokens.input + r.tokens.output + r.tokens.cache_creation)
                          # cache_read excluded: it is the saving, not the spend.
                          # tokens == null ⟺ capture_method == unavailable (D47): the record contributes 0,
                          # and every consumer MUST report the COUNT of such records alongside the sum —
                          # a spend computed over partly-unavailable traces is a lower bound, and saying so
                          # is the difference between an honest datapoint and a misleading one.

phase_spend(f, p)       = Σ tokens_billable(r) for r in f.traces where r.phase == p
feature_spend(f)        = Σ tokens_billable(r) for r in f.traces
council_spend(f)        = phase_spend(f, "council") + phase_spend(f, "deck-prep")

# Flywheel attribution (D43). A skill is credited for a dispatch iff it was injected into
# that dispatch's assembly — read straight off r.skills. Segmented per VERSION (D17/D24):
# skl_x@1.0 and skl_x@1.1 are different rows, because a prompt edit is a behavior change.
skill_success(k, v)     = count(r.outcome == "success" for r in ALL.traces
                                where {id:k, version:v} ∈ r.skills)
                          / count(r for r in ALL.traces where {id:k, version:v} ∈ r.skills)
```

`council_spend` includes deck prep because the deck exists only to be reviewed. **This is the M1 exit criterion** — "council token spend per feature is measured" (docs/05) — and M1's risk note ("if heavy, trim member count before trimming member tooling") is answerable only against this exact number, computed this exact way. Per D47 it is reported **with the count of `capture_method: unavailable` records**: interactive runs may not capture every session exactly, and an honest exit datapoint states its own completeness rather than presenting a lower bound as the whole.

`skill_success` is the flywheel's promotion input (`agent-library-schema.md` §5). It keys on the **skill**, not the dispatched agent, because under D40 the agent is an assembly and crediting `agent_id` (the base) would smear every skill's performance across every other skill it was ever co-injected with. It segments on `version` because promotion rewards a *specific prompt* (D17/D24); a skill that regressed at 1.1 must not coast on 1.0's record. A dispatch with `skills: []` credits no skill — correctly, since a bare base is not a flywheel candidate.

> **Note on isolation.** `skill_success` measures a skill only in *combination* with whatever else shared its assembly (up to the cap of 3) — traces cannot isolate one skill's marginal contribution. That is honest, and it is enough for a promotion bar; a true ablation would need controlled dispatches, which are out of scope. Recorded so no one reads `skill_success` as a clean per-skill causal number.

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
2. Every record has all §1 fields — **except the role-scoped fields**, each present iff its own role condition holds: `context_in` iff `role == "tester"` (rule 11); `graph_queries` and `ceiling_hit` iff `role == "council-member"` (rule 12). Any field not in §1 is still rejected — all three role-scoped fields are themselves in §1, so none is an "unknown field"; the pre-1.3 tension R1-S06 created (and its arm-4, 1.4-era counterpart) is resolved the same way, by admitting each to the schema rather than carving an exception into the unknown-field rule.
3. `duration_ms == ended_at − started_at`, within 1 ms.
4. `agent_id != null` ⟺ `role == "implementer"`.
5. `skills` is always present and always an array; each element is `{id, version}` with `id` matching `^skl_[a-z0-9]+(_[a-z0-9]+)*$` and `version` valid semver. `skills != []` ⟹ `role == "implementer"` (only an assembly injects skills). `|skills| ≤ 3` (the assembly cap, `agent-library-schema.md` §3).
6. `elevated_grants` is always present and always an array of strings; none of them is a member of the base core `{Read, Write, Edit, Bash, Glob, Grep}` (only elevation is recorded, D41/D43). `elevated_grants != []` ⟹ `role == "implementer"`.
7. `trace_id` is unique within the file; every non-null `parent_trace_id` refers to a `trace_id` in this file or a parent feature's.
8. No value in any record contains a newline (JSONL invariant) — which §3 already guarantees, since only bodies would.
9. Every completed phase in `artifact-layout.md` §2 that runs a session has ≥1 record. `branch`, `council-gate` and `workforce-gate` run no session — a git ref and a human, respectively — and correctly have none.
10. `capture_method ∈ {sdk, transcript, unavailable}` (D47). `tokens == null ⟺ capture_method == unavailable`; when `tokens != null`, all four sub-fields are present non-negative ints.
11. `context_in` is present iff `role == "tester"` (D72, executing `004`-council **R1-S06**): an array of repo-relative path strings naming the files that `tester` session read as its context-in. **Absent** (the key omitted entirely) on every non-`tester` record — not `null`, not `[]`. This is one of the role-gated fields in §1 (alongside `graph_queries`/`ceiling_hit`, rule 12); it exists so an SC-003 context-hygiene violation is auditable from the trace itself (the tester's declared reads, on the record) rather than being invisible.
12. `graph_queries` and `ceiling_hit` are present iff `role == "council-member"` (D77, executing `005`-council **R1-S05**, `005-graphify-context` arm 4): `graph_queries` a non-negative int counting the graph queries that member ran; `ceiling_hit` a bool recording whether that count hit `council-config.yml`'s enforced `query_ceiling`. Both **absent** (the key omitted entirely) on every non-`council-member` record — not `null`, not `0`/`false` — and present or absent **together**: a `council-member` record never carries one without the other. This is the arm-4 counterpart of rule 11 — a second role-gated pair in §1, alongside `context_in`, existing so a role's declared behavior (a tester's reads; a council-member's query count and whether it was capped) is auditable from the trace itself rather than invisible.

## 8. Non-goals (v1)

- **No spans, no distributed tracing.** One record per session; `parent_trace_id` gives a tree. Sub-session timing is not observed.
- **No sampling.** Every session, always. The volume is one line per session.
- **No log levels or free-text messages.** A trace is structured evidence, not a log.
