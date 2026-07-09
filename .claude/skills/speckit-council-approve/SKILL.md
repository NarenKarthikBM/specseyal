---
name: "speckit-council-approve"
description: "Record the council human gate's decision on decision-record.md and unlock /speckit-tasks. Presents defense-deck/overview.md, round-N/suggestions.md, and the triage disposition table, then appends a ## Human Gate section (reviewer, decision, reviewed artifacts, notes, overrides). Runs no session — a human decides, not an agent — so it writes no traces.jsonl record."
argument-hint: "approved | approved-with-notes | rejected [notes]"
compatibility: "Requires a triaged specs/NNN-feature/council/decision-record.md (a ## Round N table), plus council/defense-deck/overview.md and council/round-N/suggestions.md. Run /speckit-council then /speckit-council-triage first."
metadata:
  author: narenkarthikbm
  source: "council:commands/speckit.council.approve.md"
user-invocable: true
disable-model-invocation: true
---

## User Input

```text
$ARGUMENTS
```

The first whitespace-delimited token of `$ARGUMENTS` MUST be one of `approved`, `approved-with-notes`, `rejected` (case-insensitive; canonicalize to lowercase for recording). Everything after it, trimmed of surrounding quotes/whitespace, is free-text `notes` (optional). Empty `$ARGUMENTS` is an error — see Pre-Execution step 5 / Record the Decision step 1.

## What this is

This command is **the human gate** (FR-011; `docs/10-COUNCIL-EXTENSION-SPEC.md` §2/§5; the `council-gate` row of `artifact-layout.md` §2). It is the only one of the council extension's three commands not backed by an LLM session: `/speckit-council` dispatches deck-prep + member + chairman subagents, `/speckit-council-triage` runs in the main thread, but **this command runs no session at all — a human reads and decides.** It only reads existing artifacts, takes (or, in human mode, collects) a decision, and appends one section to `decision-record.md`. There is no model call anywhere in this flow, so the subscription-auth constraint (D28) is trivially satisfied — there is nothing to authenticate.

Because a real human decision is the entire point of this command, `disable-model-invocation` is `true` above — unlike its sibling command skills. An agent must never invoke this skill on its own initiative to wave a plan through the gate; it only runs when a human explicitly types `/speckit-council-approve …`.

## Pre-Execution

1. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root and parse `FEATURE_DIR` (absolute path). This is the same feature-resolution mechanism (`.specify/feature.json` under the hood) the contract names for the council commands (`commands.md` preconditions: "Feature resolved via `.specify/feature.json`").
2. **Require a triaged decision record.** `FEATURE_DIR/council/decision-record.md` must exist and contain at least one `## Round N` section — i.e. `/speckit-council-triage` has run. If it is missing, or has zero `## Round N` sections: ERROR — "Run /speckit-council then /speckit-council-triage before /speckit-council-approve" — and stop.
3. **Find the round under review.** `N` = the highest-numbered `## Round N` heading present in `decision-record.md`. Round sections are "ascending, contiguous" (`decision-record.md` §1), so the highest heading is always the latest.
4. **Require the deck and suggestions for that round.** `FEATURE_DIR/council/defense-deck/overview.md` and `FEATURE_DIR/council/round-N/suggestions.md` must both exist (commands.md preconditions). Missing either means an upstream phase is incomplete — ERROR naming the specific missing file rather than guessing or proceeding.
5. **Read the autonomy profile.** Read `FEATURE_DIR/profile.yaml`. If the file is absent, present but unparseable, or `gates.council.mode` is unset: the mode is `human` (`profile-schema.md` P1 — *a missing or broken profile is the safest posture, never the fastest one; never default to `auto`*). Otherwise read `gates.council.mode` literally (`human` or `auto`).
6. **Branch on mode.** `human` → continue to "Present to the Human" below. `auto` → skip straight to "Autonomy" below; do not parse `$ARGUMENTS` in that branch (there is no human decision to collect — whatever was passed is ignored).

## Autonomy — `gates.council.mode: auto` (FR-018, `profile-schema.md` §4)

`auto` is only a valid value when the feature's `profile.yaml` also has `full_auto: true` (P2/P3, the two-key handshake). This command does not re-validate that handshake — that is `profile.yaml`'s own conformance, owned upstream — it only reads the mode.

**The load-bearing contract point: under `auto`, this command is not the writer.** Per `commands.md` ("Under `gates.council.mode: auto` (only within `full_auto`), triage writes this section with `reviewer: auto`"), `plan.md`'s Chosen Approach B, and `profile-schema.md` §4 ("Triage writes the gate section itself with `reviewer: auto`, `decision: approved`"), the `## Human Gate` section for an auto-mode feature is written by **`/speckit-council-triage`** — as the last step of triage for a round with zero blocking (or blocking resolved by the one-revision delta check) — not by an invocation of this command. `auto` skips the *human*, never the council, the deck, or the record (`profile-schema.md` §4): the gate artifact still gets written, just not by a person and not via this skill.

So, when Pre-Execution finds `gates.council.mode: auto`:

- **If round N's `decision-record.md` already has a `## Human Gate` section with `reviewer: auto`** — this command is a no-op. Report the existing decision (it will read `decision: approved`) and confirm `/speckit-tasks` is unlocked. Do not append a second section.
- **If no such section exists yet** — do not fabricate one to fill the gap. This means triage has not (yet) completed its auto-write for round N — an out-of-order invocation, or triage still mid-run. ERROR: "`gates.council.mode` is `auto` — the gate section is written by `/speckit-council-triage`, not by `/speckit-council-approve`. Re-run `/speckit-council-triage` for round N; do not invoke this command directly under auto mode." Stop.

Either way, this command itself never writes to `decision-record.md` under `auto` mode, and — per Observability below — it writes no trace in that case either: the auto gate-write happens as a side effect inside `/speckit-council-triage`'s own session, which already emits its own `phase: triage` trace record. The `council-gate` phase remains sessionless even when automated; there is simply no separate dispatch for this command to make.

## Present to the Human (human mode only)

Show the reviewer exactly the artifacts the contract names (`commands.md` "Reads (by the human)"; `artifact-layout.md`'s `council-gate` row, context-in):

1. **`council/defense-deck/overview.md`**, in full — it is deliberately one page, written for a non-technical reader, and is meant to carry an approve/reject decision on its own, without the companion `technical.md` (SC-007).
2. **`council/round-N/suggestions.md`'s verdict line and table** — what the council raised, classified `blocking` / `strong` / `consider`, per suggestion ID.
3. **`decision-record.md`'s Metadata block plus the latest `## Round N` table** (and its `### Chairman delta check` subsection, if present) — what triage actually *did* with each suggestion: disposition (`accepted` / `rejected` / `deferred`) and, for any non-accepted one, the rationale (`decision-record.md` R3). This is what lets the human judge triage's handling, not just the raw suggestions. The whole file is small and append-only, so offer to show it in full if the reviewer wants the prior-round history too.

Never surface `round-N/opinions/` — it is chairman-only for the life of the feature (`artifact-layout.md` §4; SC-005). This command, not being the chairman, must not read it either.

**Check for an unresolved `blocking` item (`decision-record.md` R5).** Scan the `## Round N` table (and the delta check, if present) for any row with `Class: blocking` whose `Disposition` is not `accepted`. If one exists, call it out to the reviewer explicitly before asking for a decision — the chairman classified it `blocking` and triage did not resolve it; only the human gate may now override that classification. Whatever the human decides about it must be named in the `Overrides:` field written below — silently letting an unresolved `blocking` item pass unmentioned is exactly what R5 exists to prevent.

## Record the Decision

1. **Parse `$ARGUMENTS`** (human mode only — mode was already confirmed `human` in Pre-Execution): first token → `decision` ∈ {`approved`, `approved-with-notes`, `rejected`} (case-insensitive, canonicalized to lowercase); the remainder, trimmed → `notes`.
   - Empty `$ARGUMENTS`, or a first token that isn't one of the three values → ERROR and ask for one explicitly (echo the `argument-hint`). **Never default a missing or unrecognized decision to `approved`** — silently approving on unparsed input would turn the gate into a formality, which is precisely the failure mode this command exists to prevent.
   - `decision == approved-with-notes` with empty `notes` → ask the human to supply the notes before recording; the decision's own name promises them. Do not invent notes on their behalf, and do not silently downgrade to plain `approved`.
   - `decision == rejected` with empty `notes` → strongly prompt for a reason (the plan author needs something to act on in the next revision round), but proceed if the human declines to give one; record `**Notes:** none.`
2. **Resolve `reviewer`.** Run `git config user.name`. If empty/unset, fall back to `$USER` / `whoami`. If still empty, use the literal `unknown` and append a clause to `notes` flagging that no reviewer identity could be resolved.
3. **Compose the section**, in the exact shape of `decision-record.md` §2:

   ```markdown
   ## Human Gate — <ISO-8601 UTC timestamp>

   | Field | Value |
   |---|---|
   | reviewer | <name> |
   | decision | `<approved|approved-with-notes|rejected>` |
   | reviewed | `defense-deck/overview.md`, `round-N/suggestions.md`, this record |

   **Notes:** <notes, or "none.">

   **Overrides:** <one line per unresolved-blocking item from "Present to the Human", stating the human's ruling on each — or "none.">
   ```

   (Paths in `reviewed` are relative to `council/`, matching the contract's own worked example.)
4. **Insert it in the right place.** `decision-record.md` §5's section table fixes `## Carried Constraints` at cardinality "1, last" — it must stay the final section in the file. Insert the new `## Human Gate` block **immediately before** `## Carried Constraints`, with a `---` divider on each side matching the file's existing convention between sections — never appended after it, and never editing anything above it. R1 is append-only: no prior section is ever edited or deleted, and that includes never "correcting" an earlier `## Human Gate` section in place — a correction is a new section, and R6 makes the last one in the file authoritative.
5. If `decision-record.md` has no `## Carried Constraints` section at all, the file is non-conformant upstream — ERROR rather than guess where to insert. That is a triage-side contract violation, not something this command should paper over.

## Effect (FR-011)

- **`approved` or `approved-with-notes`** → `/speckit-tasks` is unlocked: `artifact-layout.md` §7 rule 3 treats `tasks.md` without an approved gate section as a contract violation, and that condition is now satisfied. This command does not itself invoke `/speckit-tasks` — it only makes the precondition true.
- **`rejected`** → nothing is unlocked. The plan returns for one more revision round (`docs/10-COUNCIL-EXTENSION-SPEC.md` §2: "reject with notes → one more revision round"): the plan author revises `plan.md` against the notes just recorded, then the cycle repeats — a fresh `/speckit-council` round (which writes `round-(N+1)/`, never overwriting round N, per `commands.md`'s idempotency rule), then `/speckit-council-triage` again, then this command again. This command's responsibility ends at recording the rejection; it does not trigger the next round itself.
- Per R6, a later invocation of this command (same round or a subsequent one) appends another `## Human Gate` section rather than editing this one; whichever is last in the file is authoritative.

## Observability — no trace (the one exception to principle 4)

**This command writes nothing to `traces.jsonl`, in every mode.** This is deliberate and contract-specified, not an oversight:

- `artifact-layout.md` §2: "Three rows run **no session** and so leave no trace: `branch` …, `council-gate` and `workforce-gate` (a human). The gates still write artifacts — their decision sections — which is what keeps §3 [resumability] working."
- `trace-schema.md` §7 rule 9: "`branch`, `council-gate` and `workforce-gate` run no session — a git ref and a human, respectively — and correctly have none."
- `commands.md` cross-command invariant 3: "`/speckit-council` and `/speckit-council-triage` emit traces; `/speckit-council-approve` does not (no session)."

No LLM session runs here — a human reads and decides, and this skill just records it — so there is no `role`, `model`, `tokens`, or `duration_ms` to report, and fabricating a trace record with placeholder values would be worse than omitting one (the same `cost_usd: null` ethos, `trace-schema.md` §4). The audit trail for this phase lives entirely in the `## Human Gate` section itself — that section *is* this phase's artifact-out, and it is what keeps the phase's completion inferable from the artifact tree alone with no trace needed (`artifact-layout.md` §3, resumability rule).

## Completion Report

Report, concisely:
- Feature and the round N reviewed.
- Mode (`human` / `auto`) — and in `auto` mode, whether this run found an existing auto gate (no-op) or had to stop (out-of-order invocation).
- Reviewer and decision recorded (or, in the auto no-op case, the existing recorded decision).
- Any unresolved-`blocking` item and how it was acknowledged in `Overrides`.
- Effect: `/speckit-tasks` unlocked, or the plan returns for one more revision round.
- An explicit line: no `traces.jsonl` record was written (no session ran).

## Done When

- [ ] Preconditions verified: triaged `decision-record.md`, `defense-deck/overview.md`, `round-N/suggestions.md` all present — or the command stopped with a specific missing-artifact message.
- [ ] `profile.yaml` gate mode resolved, defaulting safely to `human` on absence or parse failure.
- [ ] Human mode: overview + suggestions verdict + Round-N disposition table presented; any unresolved `blocking` item flagged before a decision was asked for.
- [ ] Auto mode: no section fabricated by this command; an existing `reviewer: auto` section was detected and reported, or the command stopped cleanly on an out-of-order invocation.
- [ ] A contract-conforming `## Human Gate` section (reviewer, decision, reviewed, notes, overrides) appended immediately before `## Carried Constraints`, never editing a prior section.
- [ ] Effect reported correctly: `approved` / `approved-with-notes` → tasks unlocked; `rejected` → returned for one more revision round.
- [ ] No `traces.jsonl` record written, in any mode.
- [ ] Completion reported to the human.
