# Spike — per-session token capture for council traces (T005 / S1 / R1)

> **Timeboxed** (≤1 investigation session). **Outcome: SUCCESS** — `capture_method: "transcript"` is feasible
> for interactive council runs, so SC-002 can be an *exact* interactive measurement, not best-effort. Per the
> carried constraint (R1-S01), a failure here would have meant `capture_method: unavailable` + a D-row; that
> branch was **not** taken.

## Question

Can an interactive Claude Code session capture **per-session token usage** for the council's trace records
(`trace-schema.md` 1.2, D47) — i.e. attribute tokens to each deck-prep / member / chairman subagent — or is
exact capture only possible once the Agent SDK drives sessions (M6)?

## Method

Inspected, read-only, two sources available at runtime:
1. the Claude Code **transcript JSONL** at `~/.claude/projects/<project>/<session>.jsonl`;
2. the **Agent-tool completion return** for dispatched subagents.

## Findings

1. **The transcript records per-message usage with exactly the fields the trace needs.** Each assistant
   message carries a `usage` object with `input_tokens`, `output_tokens`, `cache_read_input_tokens`,
   `cache_creation_input_tokens` (+ `server_tool_use`, `web_search_requests`, `web_fetch_requests`). These map
   1:1 onto `trace-schema` `tokens.{input, output, cache_read, cache_creation}`.
2. **Per-subagent attribution is possible.** Records carry `isSidechain` (true for subagent/sidechain
   messages), plus `sessionId`, `uuid`, `parentUuid` — enough to isolate a given subagent's message subtree and
   sum its usage into one session-level total.
3. **The Agent return also yields an aggregate per subagent.** Each dispatched agent's completion return
   includes `subagent_tokens` (observed across Wave 1–2: ~39k–60k per agent) + `tool_uses` + `duration_ms`.
   This is a convenient **total** for cross-checking, though it lacks the 4-way breakdown.

## Conclusion → policy for the trace-writer (T006)

- **`capture_method: "transcript"`** — the interactive path. The trace-writer parses the session transcript,
  attributes each council subagent's messages (via `isSidechain` + the session/uuid subtree), and sums the four
  `usage` fields into that session's `tokens`. The Agent-return `subagent_tokens` is a total cross-check.
- **`capture_method: "sdk"`** — the M6 path, when the Agent SDK exposes usage on the response directly.
- **`capture_method: "unavailable"`** (`tokens: null`) — the honest fallback **only** if attribution fails
  (e.g. transcript absent or format drift). Never emit a guessed number (the `cost_usd: null` ethos, D35/D47).

**R1 resolves on the good side:** the M1 exit's SC-002 does not have to wait for the SDK — a live council run
(M2) can report real `council_spend` with `capture_method: transcript`.

## Caveats (honest)

- Attribution is a small parsing job (match the subagent's message subtree); **verify at M2's first live run**
  before trusting the numbers.
- The transcript **format is version-specific** — validated against the Claude Code build in use here. If the
  shape drifts, the writer MUST degrade to `unavailable`, never emit wrong tokens.
- `subagent_tokens` alone is an aggregate; the transcript is the authoritative source for the 4-field record.
