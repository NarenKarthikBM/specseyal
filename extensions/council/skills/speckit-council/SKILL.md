---
name: "speckit-council"
description: "Convene the plan-defense council on the current feature's plan.md: deck prep, five Sonnet members across independent opinions plus anonymized peer review, and an Opus chairman synthesis, producing a classified round-N/suggestions.md for /speckit-council-triage. Ceremony scales by council_tier (D56): full = 5 per-member peer reviews (12 sessions); standard = one consolidated peer critique + lazy context (8 sessions). Supports --reopen delta|full to revisit an already-defended plan."
argument-hint: "Optional: --reopen delta \"<triggering finding>\"  |  --reopen full"
compatibility: "Requires spec-kit .specify/ structure with a completed plan.md, and the council extension installed at .specify/extensions/council/. Grounds member review in graphify-out/graph.json when present; degrades to a flagged deck-only review when absent (FR-019)."
metadata:
  author: narenkarthikbm
  source: "extensions/council/skills/speckit-council — speckit-ext-council (docs/10-COUNCIL-EXTENSION-SPEC.md)"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). The only recognized flag is `--reopen <delta|full>`. For `delta`, everything after the tier word is the **triggering finding**, taken verbatim (e.g. `--reopen delta "the migration and schema edit are still bundled after the last revision"`). `full` takes no further argument. Anything else in `$ARGUMENTS` with no `--reopen` present is out of contract scope for this command — ignore it rather than inventing behavior `commands.md` doesn't define.

## What this is

You are the **orchestrator**. `/speckit-council` runs in the main thread and never reviews the plan itself — it dispatches subagents (the "separate sessions" of the session-boundary rule) and holds four barriers: **deck-prep → stage 1 (5× independent opinions, parallel) → stage 2 (anonymized peer review) → stage 3 (1× chairman synthesis)**. This is the `speckit-implement-parallel` wave pattern applied to a review pipeline instead of a task DAG (`plan.md` Chosen Approach C / `research.md` R-D2).

**Ceremony tier (D56).** The peer-review shape and the context members load are set by `council_tier`, resolved in Pre-Execution step 4. Under **`full`** (the default) the barriers are exactly as above — stage 2 is 5 parallel per-member reviews, members read deck+plan+spec eagerly, no output cap: **12 sessions**, the `002` 5.25M baseline. Under **`standard`** stage 2 collapses to **one consolidated peer-critique session**, members load context **lazily** (the technical deck is the sole up-front read; plan/spec/graph are consulted only on demand), and an output cap applies: **8 sessions**. Everything else — anonymity (FR-006), the status-only-returns invariant (S2/SC-005), the Opus chairman, resumability, and per-session traces — is **identical across tiers**. Only three things branch on the tier: stage 1's dispatch appendix, stage 2's session count, and the chairman's input list. Where a stage below reads "5 peer sessions" or "read eagerly," that is the `full` path; each `standard` delta is called out inline as it arises.

**The invariant that makes this safe (S2, SC-005):** every subagent's entire return value is one status line. All review content is file-mediated — members write to `opinions/`, the chairman alone reads them, and you read **only** the final `round-N/suggestions.md`. You never open, `grep`, or otherwise inspect anything under `opinions/`, at any point, for any reason — existence checks are `test -f` / `ls`, never a content read. If a dispatched subagent ever returns more than its one-line status, that is a broken contract on its part: do not repeat, quote, or forward the excess anywhere (not into `traces.jsonl`, not into your completion report) — note the violation by role/letter only and continue.

## Pre-Execution

1. **Extension hooks.** Check `.specify/extensions.yml` for `hooks.before_council` entries, using the same rules every speckit command uses: parse if present, skip silently if absent/unparsable; drop entries with `enabled: false`; a hook with no `condition` is executable, one with a `condition` is left to the HookExecutor; dots become hyphens when building the slash command (`speckit.foo` → `/speckit-foo`); mandatory hooks (`optional: false`) are announced and actually invoked, waiting for completion, before continuing; optional hooks are announced only. **In practice this is a no-op today** — the council extension declares `hooks: none` (`extension.yml`; `plan.md` Chosen Approach A) and nothing else in this repo hooks into `before_council` — the check stays so a future extension can hook `/speckit-council` without an edit here.

2. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root; parse `REPO_ROOT`, `BRANCH`, `FEATURE_DIR` (absolute paths — use them absolute in every subsequent command in this session, per your own tool discipline). The feature/spec ID is `basename(FEATURE_DIR)`.

3. **Precondition: `plan.md` must exist.** If `$FEATURE_DIR/plan.md` is missing, this is the contract's **no-plan** exit state: report the error and stop. Write nothing — no `council/` directory, no trace line, no partial state.

4. **Read the council config.** `$REPO_ROOT/.specify/extensions/council/council-config.yml` → `member_count` (v1: 5), `member_lenses` (a list with exactly `member_count` entries), `models.{chairman,member,deck_prep}` (opus/sonnet/sonnet, D18), `max_rounds` (1 — informational here; the round *cap* is `/speckit-council-triage`'s concern via the delta-check escalation, not something this command enforces by refusing to run). Zip `member_lenses[0..member_count-1]` positionally to letters `A, B, C, …` in order — with the v1 defaults that's `A=correctness, B=risk, C=simplicity, D=testability, E=sequencing` (`research.md` R-D1), but derive it from the config, don't hardcode it, since trimming `member_count` is the documented M1 cost lever.

   **Resolve the ceremony tier (D56, `profile-schema.md` §7).** Read `$FEATURE_DIR/profile.yaml`'s `council_tier` if the file is present and the key parses; else fall back to `council-config.yml`'s top-level `council_tier`; if neither is set, the tier is **`full`** (T1 — absent ⇒ the fullest review; never silently pick the cheaper tier). Load that tier's parameters from `council-config.yml`'s `tiers.<tier>` block: **`peer_review`** (`per_member` | `consolidated`), **`context`** (`eager` | `lazy`), and **`member_output_cap`** (`none` or an integer). These three values are the *only* thing that branches stages 1–3; nothing else in this command reads the tier. Note the resolved tier + its three params for your completion report, and cross-check the model map is unchanged (a tier never alters D18 — Sonnet members, Opus chairman, both tiers).

5. **Note graph availability.** `test -f "$REPO_ROOT/graphify-out/graph.json"`. This does not gate anything (FR-019 — degrade, don't block) and you don't need to relay it to subagents — `member-prompt.md` and `deck-technical.md` both already instruct their own sessions to check for the graph themselves. You only need this fact for your own completion report's "Grounding" line as a sanity cross-check against the chairman's authoritative reduced-grounding banner in `suggestions.md`.

6. **Resolve the round number (resumability, Constitution III).** List `$FEATURE_DIR/council/round-*/`, numerically sorted.
   - No rounds exist → this run is **round 1**.
   - The highest existing `round-N` has `suggestions.md` → it is *complete*; never reopen it — this run is round **N+1** (contract idempotency: "re-run… starts round-(N+1); never overwrites a prior round").
   - The highest existing `round-N` has **no** `suggestions.md` → it is an interrupted run; **resume round N in place**: skip deck-prep if `defense-deck/{technical,overview}.md` already exist from this attempt, skip stage 1 for any letter that already has `opinions/<letter>.md`, skip stage 2 for any letter that already has `opinions/peer/<letter>.md`, then continue at whichever stage is first incomplete. Never re-run a stage whose artifact is already on disk.

7. **If `--reopen` was passed**, read **§ Reopen** now before dispatching anything — it changes what context stage 1 gets and whether deck-prep runs at all, but not the round-number resolution above.

## Dispatch mechanics (applies to every stage below)

- **Paths, not content.** Beyond the two prompt templates (next bullet) and, only for `--reopen delta`, the plan-diff text, you do not read `plan.md`, `spec.md`, the deck, or any opinion into your own context. Subagents have their own `Read`/`Bash` access and read their inputs themselves from the paths you give them.
- **Prompt templates are rendered by you, once, before dispatch.** `member-prompt.md` and `chairman-prompt.md` are prompt templates, not output shapes — read `$REPO_ROOT/.specify/extensions/council/templates/member-prompt.md` once and, per letter, substitute `{{member_letter}}` and `{{lens}}` textually to get that letter's base prompt (one render per letter, reused for both stage 1 and stage 2 — only the stage-specific appendix you append differs between the two dispatches). Read `.../templates/chairman-prompt.md` once for stage 3 and render its §2 fenced block with `{{mode}} = "synthesis"` and the slots from its own §3 table. The rendered text becomes the literal `prompt` argument to the `Agent` tool call, with your stage-specific appendix (concrete paths, which stage) appended at the end.
- **`deck-technical.md`, `deck-overview.md`, `suggestions.md` are output shapes, not prompts** — point deck-prep and the chairman at their installed template paths and let them read the guidance/placeholders themselves; you don't pre-render these.
- **True parallelism = one message, multiple `Agent` tool calls.** Stage 1's five members — and, under tier `full`, stage 2's five per-member reviewers — must each be dispatched as five `Agent` tool-use blocks in the *same turn*, never one at a time. Under tier `standard`, stage 2 is a **single** `Agent` call (the consolidated reviewer), so the one-turn-five-calls rule applies only to stage 1 there. `subagent_type: general-purpose` is sufficient for every council role (deck-prep, member, chairman): generic file-writing, tool-using tasks, not specialized personas. No `isolation` is needed anywhere in this flow — every subagent writes its own disjoint file (`opinions/<letter>.md`, `opinions/peer/<letter>.md`, `opinions/peer/consolidated.md`, or the one deck/suggestions path); there is no shared-file collision to isolate against.
- **A barrier means what it says.** Do not start stage 2 until all five stage-1 returns are in hand; do not dispatch the chairman until the stage-2 returns are in hand — **all five** under tier `full`, the **single** consolidated return under `standard`. If one member fails or times out, proceed with the other four, record `outcome: "failed"` in that letter's trace fragment, and let the chairman's own missing-file handling (`chairman-prompt.md` § Inputs) absorb the gap — never block the whole round on one member. (A `standard`-tier consolidated-peer failure leaves the chairman reading the five stage-1 opinions alone — a degraded but valid round; note it rather than blocking.)

## Stage 0 — Deck prep

Dispatch **one `Sonnet` subagent**. Prompt = point it at `.../templates/deck-technical.md` and `deck-overview.md` (the shapes to fill) and at `$FEATURE_DIR/plan.md`, `spec.md`, `graphify-context.md` (its sources). Tell it to write `council/defense-deck/technical.md` and `council/defense-deck/overview.md` (paths relative to `$FEATURE_DIR`), overwriting in place if they already exist (D38 — the deck is not round-scoped; git on the feature branch holds prior versions). Its return is one status line confirming the two files were written — nothing else.

**Skip this stage entirely for `--reopen delta`** (§ Reopen) — the delta tier's context is the diff + finding, not a re-rendered deck, and `defense-deck/` is left untouched. Run it normally for a fresh/resumed round and for `--reopen full`.

Barrier: wait for the return, then append its trace fragment (§ Traces) before dispatching stage 1.

## Stage 1 — Independent opinions

Dispatch **`member_count` (5) `Sonnet` subagents in one turn**. Each gets its rendered `member-prompt.md` base (letter + lens already substituted) plus an appendix stating: this is **Stage 1**; the concrete paths for `defense-deck/technical.md`, `plan.md`, `spec.md`; and the write target `council/round-N/opinions/<letter>.md`. (For `--reopen delta`, the appendix instead names the plan-diff text and the triggering finding as the *entire* review context — § Reopen.) Each member's return is one status line — `Wrote opinions/<letter>.md — <n> suggestions.` — and nothing else ever crosses back to you.

**Tier deltas to the Stage-1 appendix (D56).** The base `member-prompt.md` is unchanged; the tier only tunes the appendix you append:

- **`context: lazy`** (tier `standard`) — add, verbatim in intent: *"Lazy context: your primary and only required read is the technical deck (`defense-deck/technical.md`). Do NOT read `plan.md` or `spec.md` wholesale, and do not sweep the graph — consult them ON DEMAND only to verify a specific deck claim you actually doubt. Their paths are `<plan.md>`, `<spec.md>`; open them only if a check requires it."* Under **`context: eager`** (tier `full`) the appendix is exactly the base paragraph above — deck+plan+spec read up front.
- **`member_output_cap: <n>`** (tier `standard`, e.g. 6) — add: *"Write at most `<n>` suggestions; if you have more, keep the highest-signal ones and drop the rest rather than padding."* Under `none` (tier `full`) no cap line is added.
- **Read-rate telemetry** (tier `standard` only) — extend the required return line to carry a metadata-only suffix naming which sources the member actually opened: `Wrote opinions/<letter>.md — <n> suggestions. consulted: deck[,plan][,spec][,graph]`. This is process metadata, **not** review content — the status-only invariant (S2) still holds; it simply lets you compute the per-member `plan.md` read-rate (the D56 lazy-loading effectiveness metric) for your completion report without ever opening an opinion. Under tier `full` the return line is the plain form above.

Barrier: wait for all five, then append the five trace fragments (§ Traces), serially, before dispatching stage 2.

## Stage 2 — Peer review

Stage 2's shape is set by the tier's **`peer_review`** value (Pre-Execution step 4). Both paths barrier before stage 3, both return status-only, and both write under `opinions/peer/`; only the session count and file layout differ. You never open any peer file — you name paths and check existence with `test -f`, exactly as in stage 1.

**`per_member` (tier `full`).** Re-dispatch **5 new `Sonnet` subagent sessions in one turn** — fresh sessions with no memory of stage 1, not continuations; the *same* letter→lens assignment carries over so `opinions/peer/A.md` pairs with `opinions/A.md`. Each gets the same rendered `member-prompt.md` base plus an appendix stating: this is **Stage 2 (per-member)**; its own letter's opinion is excluded; read the other four at `council/round-N/opinions/<other-letter>.md` (you name the paths — you do not open them yourself); write to `council/round-N/opinions/peer/<letter>.md`. Return is one status line, same discipline as stage 1.

Barrier: wait for all five, then append the five trace fragments (§ Traces), serially, before dispatching stage 3.

**`consolidated` (tier `standard`).** Dispatch **one `Sonnet` subagent** — a single neutral peer reviewer, not a lettered member: it carries no `{{lens}}` and reviews all five opinions at once, so render `member-prompt.md` with `{{member_letter}}` = `consolidated` and `{{lens}}` = `consolidated` (or point it at the deck-less consolidated task directly). Its appendix states: this is **Stage 2 (consolidated peer critique)**; read all five stage-1 opinions at `council/round-N/opinions/<A..E>.md` (you name the paths; you never open them yourself); critique and rank them *as a set* — which findings are strongest and which weakest and why, which specific suggestions across the five to endorse or challenge (by letter), and any genuinely-new point all five missed; obey the same `member_output_cap` (≤ 15 consolidated points); write a single consolidated critique to `council/round-N/opinions/peer/consolidated.md`. Return is one status line — `Wrote opinions/peer/consolidated.md — <n> points.` — same status-only discipline (no critique content ever crosses back). This one file is where the chairman reads the peer round under `standard`; collapsing five sessions to one is the tier's largest lever (the `002` finding: each avoided member session also avoids its 25–38 graphify tool-call turns and their cache churn).

Barrier: wait for the single return, then append its one trace fragment (§ Traces) before dispatching stage 3.

## Stage 3 — Chairman synthesis

Dispatch **one `Opus` subagent**, mode `synthesis` — never `delta-check`; that mode belongs exclusively to `/speckit-council-triage`'s post-revision check, and this skill never invokes it, reopen included. Prompt = the rendered `chairman-prompt.md` §2 block with `{{feature}}`, `{{round}}`, `{{opinions_dir}} = council/round-N/opinions`, `{{peer_dir}} = council/round-N/opinions/peer`, `{{plan_path}} = plan.md` substituted. The chairman reads every stage-1 opinion (`opinions/<A..E>.md`) **and every stage-2 peer file present** under `opinions/peer/` — **ten files under tier `full`** (5 opinions + 5 per-member peer), **six under `standard`** (5 opinions + one `consolidated.md`) — it is the *only* session ever permitted to open them, and it discovers the peer files by listing `opinions/peer/` rather than assuming a fixed count. It writes `council/round-N/suggestions.md`: classified rows, stable `R<round>-S<nn>` IDs, the reduced-grounding banner iff any opinion flagged it, and a Chairman's note. Its return is status + verdict counts **only** — no suggestion text, no opinion excerpts.

Barrier: wait for the return, then append its trace fragment (§ Traces).

## Query-ceiling enforcement (arm 4 — D77, S09, `005-graphify-context`)

A council member's graph-query loop is bounded by a **hard, tier-aware ceiling** — `tiers.<tier>.query_ceiling` in `council-config.yml` (Pre-Execution step 4): `standard: 15` (D77, calibrated from this round's uncapped per-member max of 9); `full:` unset/uncapped until its own baseline is measured. This applies to **every `council-member` dispatch** — stage 1, and stage 2's per-member (`full`) or consolidated (`standard`) reviewer.

**The member reports its count; the orchestrator enforces the consequence — mechanically (S09/D53).** The member prompt (`member-prompt.md`, wired by `005`'s T027) instructs the member to stop after its `N`th graph query and to append its graph-query **count** to its status-line return (`graph_queries: <count>`, the same metadata-only channel as the `standard`-tier `consulted:` suffix — still status-only, S2). A member scrambling at its ceiling is prompt-following at its *least* reliable, so the load-bearing guarantee is **not** the member's own prose — it is mechanical, on you, the orchestrator, at each member barrier:

1. Run `.specify/extensions/council/scripts/ceiling-check.sh <tier> <count>` (source: `extensions/council/extension/scripts/ceiling-check.sh`). It reads `query_ceiling` for the tier and prints `ceiling_hit: true|false` and, **iff** hit, the exact reduced-grounding disclosure line on a second line.
2. On `ceiling_hit: true`, **mechanically append that disclosure line to the member's own opinion file** — a *blind append* (`ceiling-check.sh <tier> <count> | tail -n +2 >> "$FEATURE_DIR/council/round-N/opinions/<letter>.md"`), never reading the opinion's content. An append is a write, not a read, so the S2/SC-005 context-hygiene invariant (you never open `opinions/`) still holds by construction. The member's own prose, if it disclosed anything, is courtesy; this mechanical append is what guarantees the chairman weights a ceiling-limited opinion rather than trusting it as fully grounded (SC-008).
3. Record `graph_queries: <count>` and `ceiling_hit: <bool>` in that member's trace fragment (§ Traces) — the "never silent" flag (SC-006/SC-008): a ceiling-limited opinion is auditable *after* the round from the trace itself, not only mid-round.

Under `full` (uncapped), `ceiling-check.sh` returns `ceiling_hit: false` for any count, no disclosure fires, and the fragment still records the observed `graph_queries` — the count that will calibrate `full`'s own eventual ceiling (the SC-006 measurement trigger, booked against the first post-arm-4 `full`-tier round). If a member's return omits `graph_queries` (e.g. a pre-T027 member prompt, or a failed member), record `ceiling_hit: false` with the count you can determine, or omit both fields for that fragment if none is knowable — never fabricate a count (the exact-or-null ethos, D47).

## Context hygiene — the one rule that cannot bend (S2, SC-005)

Across every stage above, you never read `opinions/` or `opinions/peer/` — not to confirm a member finished (use `test -f`), not to sanity-check quality, not for any reason. The only council artifact whose *content* you ever read is `round-N/suggestions.md`, once, after the stage-3 barrier — that is what your completion report is built from. This is what makes SC-005's grep-based conformance check sufficient: there is no opinion content in your transcript to leak, by construction, not by discipline alone.

## Traces — serial append, never parallel (R-D3, `trace-fragment.md` §5)

`/speckit-council`'s own invocation is not itself a traced role — the council roles this command traces are exactly `deck-prep`, `council-member`, and `chairman` (never an `orchestrator` fragment for itself). Every fragment you collect therefore carries **`parent_trace_id: null`** — the same reasoning that gives `/speckit-council-triage`'s own fragment `parent_trace_id: null`: it, too, is dispatched directly by the interactive main thread rather than by another traced session, so there is no in-file trace_id for it to reference.

After **each** barrier (deck-prep's one return; stage 1's five returns; stage 2's returns — **five under tier `full`, one under `standard`**; chairman's one return), append that barrier's fragment(s) to `$FEATURE_DIR/traces.jsonl` **one line at a time, immediately, before dispatching the next stage** — never batch across barriers, never write two lines concurrently. Five members finishing stage 1 together are still five separate, sequential appends, in letter order. The `standard`-tier consolidated peer session traces as **`council-member`** (Sonnet, `phase: "council"`), exactly like a per-member peer session — same role, same fields; there is one fragment instead of five.

Per fragment, fixed council values (`trace-fragment.md` §2): `agent_id: null`, `skills: []`, `elevated_grants: []`, `cost_usd: null`, `schema_version: "1.0"`. Per-role values (§3, D18 via `council-config.yml`):

| Role | `phase` | `model` | `effort` | `artifact` |
|---|---|---|---|---|
| `deck-prep` | `"deck-prep"` | `"claude-sonnet-5"` | `"medium"` | the deck path |
| `council-member` | `"council"` | `"claude-sonnet-5"` | `"medium"` | `null` (an opinion is chairman-only, never an artifact-out) |
| `chairman` | `"council"` | `"claude-opus-4-8"` | `"xhigh"` | the `suggestions.md` path |

**Arm-4 fields on `council-member` fragments (D77, `005`; `trace-schema.md` §1/§7 rule 12, role-scoped).** Every `council-member` fragment (stage 1, and stage 2's per-member/consolidated reviewer) additionally carries `graph_queries: <int>` and `ceiling_hit: <bool>` — the two present or absent **together**, and **only** on `council-member` records (never on `deck-prep`/`chairman`). They are the Query-ceiling-enforcement outputs above: `graph_queries` is the count the member reported; `ceiling_hit` is `ceiling-check.sh`'s verdict for the tier. See `trace-fragment.md` §3.1.

`tokens`/`capture_method` follow `trace-fragment.md` §4's policy exactly: attempt `transcript`-based attribution from the session transcript (the T005 spike validated this path — `capture_method: "transcript"`); fall back honestly to `capture_method: "unavailable"` + `tokens: null` when attribution isn't available — never a guessed number (D47). Mint a fresh, unique `trace_id` per fragment (e.g. `trc_` + a ULID/timestamp-random token) — never reused across sessions.

## Reopen — `--reopen delta|full` (FR-017, D46, `research.md` R-D7)

Both tiers still run the round-resolution in Pre-Execution step 6 and still produce a normal `round-N/suggestions.md` via a **synthesis**-mode chairman — a reopen is a round with a different-shaped context package, not a different pipeline.

> **Mid-implementation self-reopen guard (S17, `005-graphify-context` arm 4).** While `005` itself is mid-implementation — after arm 4 is spec'd but before its member-prompt change (T027) wires the query-cap instruction into `member-prompt.md` — a `/speckit-council --reopen delta` on `005` would dispatch the **pre-ceiling** member prompt (no `graph_queries` report, no cap). That is expected and harmless (the Query-ceiling-enforcement section above records `ceiling_hit: false` and omits the count it cannot know); this note simply flags the pre-ceiling prompt status until T027 lands. Once T027 is in, the member prompt reports the count and every reopen is fully ceiling-aware. Do not confuse this with `/speckit-council-triage`'s own "chairman-only delta check" (FR-010) — that is a same-round, append-to-the-existing-`suggestions.md` re-adjudication triage runs after one blocking-triggered revision; it is a different mechanism entirely and this skill never touches it.

**`full`** — no special handling: run Stage 0–3 exactly as a fresh round would (deck-prep regenerates `defense-deck/` in place; members get the full deck + plan + spec). The only difference from an ordinary re-run is cosmetic — note "reopen (full)" in the completion report.

**`delta`** — the cheap tier, and FR-017's default:

1. **The triggering finding is required, verbatim, from `$ARGUMENTS`.** If `--reopen delta` was passed with no finding text, stop and ask for it — it is factual input only the caller has; do not invent or infer one.
2. **Compute the plan diff yourself.** This is plain `plan.md` content, not `opinions/` — reading it is normal and expected. Find the most recent `## Round N` section in `$FEATURE_DIR/council/decision-record.md` and its `Plan reviewed: plan.md @ <sha>` line; that `<sha>` is the diff base. Run `git diff <sha>..HEAD -- "$FEATURE_DIR/plan.md"`. If `decision-record.md` doesn't exist yet, there is nothing to reopen — that's a contract error: tell the user and suggest `--reopen full` or a plain `/speckit-council` instead.
3. **Skip Stage 0 (deck-prep) entirely.** `defense-deck/` is not touched.
4. **Stage 1's appendix changes**: instead of deck/plan/spec paths, each member's dispatch gives the diff text and the finding text as the *entire* review context, and says so explicitly — "this is a delta reopen: you have no deck and no full plan; review only the diff and the finding below." Stage 2 and Stage 3 are otherwise unchanged (peer review reads this same round's stage-1 opinions; the chairman still runs `synthesis` mode over whatever the members produced).
5. **You do not write `## Reopen` to `decision-record.md`** — that section is `/speckit-council-triage`'s to write when it processes this round, not this skill's. Your job ends at `suggestions.md`; make your completion report state the tier, the diff base sha, and the finding text plainly enough that whoever runs triage next has what they need.

## Exit states

| State | Trigger | Result |
|---|---|---|
| `success` | stage 3 barrier cleared | `round-N/suggestions.md` written; completion report returned |
| `no-plan` | `$FEATURE_DIR/plan.md` missing | error reported; nothing written (Pre-Execution step 3) |
| `no-graph` | `graphify-out/graph.json` absent | still `success` — the round completes deck-only, with the reduced-grounding banner surfaced in `suggestions.md` (FR-019) |

## Completion Report

```
## Council Round Complete — <feature> (round <N>[, reopen: delta|full])
Tier: full | standard   (D56)
Suggestions: council/round-<N>/suggestions.md
Verdict: <b> blocking · <s> strong · <c> consider
Sessions: 1 deck-prep + <5|0> stage-1 + <5|1|0> stage-2 + 1 chairman = <total> (traces appended)
Read-rate: <k>/5 stage-1 members consulted plan.md [· spec <k>/5 · graph <k>/5]   (standard tier only; from the consulted: return metadata)
Grounding: full | reduced (no graphify-out/graph.json)
Reopen: — | delta (base <sha>, finding: "<text>") | full
Next: /speckit-council-triage
```

Stage-2 session count: `5` under tier `full` (per-member), `1` under `standard` (consolidated), `0` for `--reopen`-only edge states that skip it. Omit the `Read-rate` line entirely under tier `full` (eager context — every member reads `plan.md` by construction, so the metric is trivially 5/5 and carries no signal). Return this — never opinion content, never suggestion text beyond the verdict counts already shown; the next command reads `suggestions.md` directly for the detail.

## Guardrails

- Subscription auth only (D28) — never reference or set `ANTHROPIC_API_KEY`; every dispatched subagent runs on the same Claude subscription as this session.
- Never dispatch the chairman in `delta-check` mode from this skill — that belongs to `/speckit-council-triage` alone.
- Never overwrite an existing round's `opinions/`, `opinions/peer/`, or `suggestions.md` — a completed round is immutable; only `defense-deck/` is ever overwritten in place, and never for `--reopen delta`.
- Never write to `decision-record.md` — that is triage's artifact, not this skill's.
- Stage 1 is always one message with 5 `Agent` calls (never five separate messages); stage 2 is likewise 5 calls under tier `full`, or a single `Agent` call under `standard` (the consolidated reviewer).
- **Tier resolves to `full` when unresolved (D56, T1).** An absent/unparseable `council_tier` in both `profile.yaml` and `council-config.yml` means the *fullest* review — never silently drop to `standard`. A tier never changes the D18 model map or the gate mode; it only changes stage-2 session count, stage-1 context, and the output cap.
- If `plan.md` is missing, stop before creating anything.

## Done When

- [ ] Ceremony tier resolved (D56): `profile.yaml` `council_tier` → `council-config.yml` default → `full`; its `peer_review`/`context`/`member_output_cap` params loaded
- [ ] Round number resolved by the resumability rule (fresh, resumed, or reopened) — no prior round ever overwritten
- [ ] Deck prep done (skipped only for `--reopen delta`)
- [ ] All applicable stage-1 and stage-2 sessions returned status-only, and their trace fragments were appended serially after their barrier (stage 2 = 5 per-member under `full`, 1 consolidated under `standard`)
- [ ] Chairman ran in `synthesis` mode and `round-N/suggestions.md` exists, classified and ID'd, with the reduced-grounding banner iff triggered
- [ ] No `opinions/` content ever entered this session's own context
- [ ] Completion report returned in the format above
