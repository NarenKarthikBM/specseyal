---
name: "speckit-council"
description: "Convene the plan-defense council on the current feature's plan.md: deck prep, five Sonnet members across independent opinions plus anonymized peer review, and an Opus chairman synthesis, producing a classified round-N/suggestions.md for /speckit-council-triage. Supports --reopen delta|full to revisit an already-defended plan."
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

You are the **orchestrator**. `/speckit-council` runs in the main thread and never reviews the plan itself — it dispatches subagents (the "separate sessions" of the session-boundary rule) and holds four barriers: **deck-prep → stage 1 (5× independent opinions, parallel) → stage 2 (5× anonymized peer review, parallel) → stage 3 (1× chairman synthesis)**. This is the `speckit-implement-parallel` wave pattern applied to a review pipeline instead of a task DAG (`plan.md` Chosen Approach C / `research.md` R-D2).

**The invariant that makes this safe (S2, SC-005):** every subagent's entire return value is one status line. All review content is file-mediated — members write to `opinions/`, the chairman alone reads them, and you read **only** the final `round-N/suggestions.md`. You never open, `grep`, or otherwise inspect anything under `opinions/`, at any point, for any reason — existence checks are `test -f` / `ls`, never a content read. If a dispatched subagent ever returns more than its one-line status, that is a broken contract on its part: do not repeat, quote, or forward the excess anywhere (not into `traces.jsonl`, not into your completion report) — note the violation by role/letter only and continue.

## Pre-Execution

1. **Extension hooks.** Check `.specify/extensions.yml` for `hooks.before_council` entries, using the same rules every speckit command uses: parse if present, skip silently if absent/unparsable; drop entries with `enabled: false`; a hook with no `condition` is executable, one with a `condition` is left to the HookExecutor; dots become hyphens when building the slash command (`speckit.foo` → `/speckit-foo`); mandatory hooks (`optional: false`) are announced and actually invoked, waiting for completion, before continuing; optional hooks are announced only. **In practice this is a no-op today** — the council extension declares `hooks: none` (`extension.yml`; `plan.md` Chosen Approach A) and nothing else in this repo hooks into `before_council` — the check stays so a future extension can hook `/speckit-council` without an edit here.

2. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root; parse `REPO_ROOT`, `BRANCH`, `FEATURE_DIR` (absolute paths — use them absolute in every subsequent command in this session, per your own tool discipline). The feature/spec ID is `basename(FEATURE_DIR)`.

3. **Precondition: `plan.md` must exist.** If `$FEATURE_DIR/plan.md` is missing, this is the contract's **no-plan** exit state: report the error and stop. Write nothing — no `council/` directory, no trace line, no partial state.

4. **Read the council config.** `$REPO_ROOT/.specify/extensions/council/council-config.yml` → `member_count` (v1: 5), `member_lenses` (a list with exactly `member_count` entries), `models.{chairman,member,deck_prep}` (opus/sonnet/sonnet, D18), `max_rounds` (1 — informational here; the round *cap* is `/speckit-council-triage`'s concern via the delta-check escalation, not something this command enforces by refusing to run). Zip `member_lenses[0..member_count-1]` positionally to letters `A, B, C, …` in order — with the v1 defaults that's `A=correctness, B=risk, C=simplicity, D=testability, E=sequencing` (`research.md` R-D1), but derive it from the config, don't hardcode it, since trimming `member_count` is the documented M1 cost lever.

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
- **True parallelism = one message, multiple `Agent` tool calls.** Stage 1's five members and stage 2's five members must each be dispatched as five `Agent` tool-use blocks in the *same turn* — never one at a time. `subagent_type: general-purpose` is sufficient for every council role (deck-prep, member, chairman): generic file-writing, tool-using tasks, not specialized personas. No `isolation` is needed anywhere in this flow — every subagent writes its own disjoint file (`opinions/<letter>.md`, `opinions/peer/<letter>.md`, or the one deck/suggestions path); there is no shared-file collision to isolate against.
- **A barrier means what it says.** Do not start stage 2 until all five stage-1 returns are in hand; do not dispatch the chairman until all five stage-2 returns are in hand. If one member fails or times out, proceed with the other four, record `outcome: "failed"` in that letter's trace fragment, and let the chairman's own missing-file handling (`chairman-prompt.md` § Inputs) absorb the gap — never block the whole round on one member.

## Stage 0 — Deck prep

Dispatch **one `Sonnet` subagent**. Prompt = point it at `.../templates/deck-technical.md` and `deck-overview.md` (the shapes to fill) and at `$FEATURE_DIR/plan.md`, `spec.md`, `graphify-context.md` (its sources). Tell it to write `council/defense-deck/technical.md` and `council/defense-deck/overview.md` (paths relative to `$FEATURE_DIR`), overwriting in place if they already exist (D38 — the deck is not round-scoped; git on the feature branch holds prior versions). Its return is one status line confirming the two files were written — nothing else.

**Skip this stage entirely for `--reopen delta`** (§ Reopen) — the delta tier's context is the diff + finding, not a re-rendered deck, and `defense-deck/` is left untouched. Run it normally for a fresh/resumed round and for `--reopen full`.

Barrier: wait for the return, then append its trace fragment (§ Traces) before dispatching stage 1.

## Stage 1 — Independent opinions

Dispatch **`member_count` (5) `Sonnet` subagents in one turn**. Each gets its rendered `member-prompt.md` base (letter + lens already substituted) plus an appendix stating: this is **Stage 1**; the concrete paths for `defense-deck/technical.md`, `plan.md`, `spec.md`; and the write target `council/round-N/opinions/<letter>.md`. (For `--reopen delta`, the appendix instead names the plan-diff text and the triggering finding as the *entire* review context — § Reopen.) Each member's return is one status line — `Wrote opinions/<letter>.md — <n> suggestions.` — and nothing else ever crosses back to you.

Barrier: wait for all five, then append the five trace fragments (§ Traces), serially, before dispatching stage 2.

## Stage 2 — Anonymized peer review

Re-dispatch **5 new `Sonnet` subagent sessions in one turn** — fresh sessions with no memory of stage 1, not continuations; the *same* letter→lens assignment carries over so `opinions/peer/A.md` pairs with `opinions/A.md`. Each gets the same rendered `member-prompt.md` base plus an appendix stating: this is **Stage 2**; its own letter's opinion is excluded; read the other four at `council/round-N/opinions/<other-letter>.md` (you name the paths — you do not open them yourself); write to `council/round-N/opinions/peer/<letter>.md`. Return is one status line, same discipline as stage 1.

Barrier: wait for all five, then append the five trace fragments (§ Traces), serially, before dispatching stage 3.

## Stage 3 — Chairman synthesis

Dispatch **one `Opus` subagent**, mode `synthesis` — never `delta-check`; that mode belongs exclusively to `/speckit-council-triage`'s post-revision check, and this skill never invokes it, reopen included. Prompt = the rendered `chairman-prompt.md` §2 block with `{{feature}}`, `{{round}}`, `{{opinions_dir}} = council/round-N/opinions`, `{{peer_dir}} = council/round-N/opinions/peer`, `{{plan_path}} = plan.md` substituted. The chairman reads all ten opinion files itself — it is the *only* session ever permitted to — and writes `council/round-N/suggestions.md`: classified rows, stable `R<round>-S<nn>` IDs, the reduced-grounding banner iff any opinion flagged it, and a Chairman's note. Its return is status + verdict counts **only** — no suggestion text, no opinion excerpts.

Barrier: wait for the return, then append its trace fragment (§ Traces).

## Context hygiene — the one rule that cannot bend (S2, SC-005)

Across every stage above, you never read `opinions/` or `opinions/peer/` — not to confirm a member finished (use `test -f`), not to sanity-check quality, not for any reason. The only council artifact whose *content* you ever read is `round-N/suggestions.md`, once, after the stage-3 barrier — that is what your completion report is built from. This is what makes SC-005's grep-based conformance check sufficient: there is no opinion content in your transcript to leak, by construction, not by discipline alone.

## Traces — serial append, never parallel (R-D3, `trace-fragment.md` §5)

`/speckit-council`'s own invocation is not itself a traced role — the council roles this command traces are exactly `deck-prep`, `council-member`, and `chairman` (never an `orchestrator` fragment for itself). Every fragment you collect therefore carries **`parent_trace_id: null`** — the same reasoning that gives `/speckit-council-triage`'s own fragment `parent_trace_id: null`: it, too, is dispatched directly by the interactive main thread rather than by another traced session, so there is no in-file trace_id for it to reference.

After **each** barrier (deck-prep's one return; stage 1's five returns; stage 2's five returns; chairman's one return), append that barrier's fragment(s) to `$FEATURE_DIR/traces.jsonl` **one line at a time, immediately, before dispatching the next stage** — never batch across barriers, never write two lines concurrently. Five members finishing stage 1 together are still five separate, sequential appends, in letter order.

Per fragment, fixed council values (`trace-fragment.md` §2): `agent_id: null`, `skills: []`, `elevated_grants: []`, `cost_usd: null`, `schema_version: "1.0"`. Per-role values (§3, D18 via `council-config.yml`):

| Role | `phase` | `model` | `effort` | `artifact` |
|---|---|---|---|---|
| `deck-prep` | `"deck-prep"` | `"claude-sonnet-5"` | `"medium"` | the deck path |
| `council-member` | `"council"` | `"claude-sonnet-5"` | `"medium"` | `null` (an opinion is chairman-only, never an artifact-out) |
| `chairman` | `"council"` | `"claude-opus-4-8"` | `"xhigh"` | the `suggestions.md` path |

`tokens`/`capture_method` follow `trace-fragment.md` §4's policy exactly: attempt `transcript`-based attribution from the session transcript (the T005 spike validated this path — `capture_method: "transcript"`); fall back honestly to `capture_method: "unavailable"` + `tokens: null` when attribution isn't available — never a guessed number (D47). Mint a fresh, unique `trace_id` per fragment (e.g. `trc_` + a ULID/timestamp-random token) — never reused across sessions.

## Reopen — `--reopen delta|full` (FR-017, D46, `research.md` R-D7)

Both tiers still run the round-resolution in Pre-Execution step 6 and still produce a normal `round-N/suggestions.md` via a **synthesis**-mode chairman — a reopen is a round with a different-shaped context package, not a different pipeline. Do not confuse this with `/speckit-council-triage`'s own "chairman-only delta check" (FR-010) — that is a same-round, append-to-the-existing-`suggestions.md` re-adjudication triage runs after one blocking-triggered revision; it is a different mechanism entirely and this skill never touches it.

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
Suggestions: council/round-<N>/suggestions.md
Verdict: <b> blocking · <s> strong · <c> consider
Sessions: 1 deck-prep + <5|0> stage-1 + <5|0> stage-2 + 1 chairman = <total> (traces appended)
Grounding: full | reduced (no graphify-out/graph.json)
Reopen: — | delta (base <sha>, finding: "<text>") | full
Next: /speckit-council-triage
```

Return this — never opinion content, never suggestion text beyond the verdict counts already shown; the next command reads `suggestions.md` directly for the detail.

## Guardrails

- Subscription auth only (D28) — never reference or set `ANTHROPIC_API_KEY`; every dispatched subagent runs on the same Claude subscription as this session.
- Never dispatch the chairman in `delta-check` mode from this skill — that belongs to `/speckit-council-triage` alone.
- Never overwrite an existing round's `opinions/`, `opinions/peer/`, or `suggestions.md` — a completed round is immutable; only `defense-deck/` is ever overwritten in place, and never for `--reopen delta`.
- Never write to `decision-record.md` — that is triage's artifact, not this skill's.
- Stage 1 and stage 2 are each one message with 5 `Agent` calls, never five separate messages.
- If `plan.md` is missing, stop before creating anything.

## Done When

- [ ] Round number resolved by the resumability rule (fresh, resumed, or reopened) — no prior round ever overwritten
- [ ] Deck prep done (skipped only for `--reopen delta`)
- [ ] All applicable stage-1 and stage-2 member sessions returned status-only, and their trace fragments were appended serially after their barrier
- [ ] Chairman ran in `synthesis` mode and `round-N/suggestions.md` exists, classified and ID'd, with the reduced-grounding banner iff triggered
- [ ] No `opinions/` content ever entered this session's own context
- [ ] Completion report returned in the format above
