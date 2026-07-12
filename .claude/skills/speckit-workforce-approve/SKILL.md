---
name: "speckit-workforce-approve"
description: "Record the workforce human gate's decision into agents/assignment.md's ## Workforce Gate section and unlock /speckit-implement-parallel. Presents the ### Roster approved table (base, model, skills, elevated grants per assembled agent) against tasks.md, then resolves the section's six [PENDING …] fields (timestamp, reviewer, decision, reviewed, notes, overrides). Runs no session — a human decides, not an agent — so it writes no traces.jsonl record."
argument-hint: "approved | approved-with-notes | rejected [notes]"
compatibility: "Requires a specs/NNN-feature/agents/assignment.md with a ## Workforce Gate section (written by /speckit-agent-assign, which itself requires /speckit-categorize to have run first). Run /speckit-categorize then /speckit-agent-assign before this command."
metadata:
  author: narenkarthikbm
  source: "workforce:commands/speckit.workforce-approve.md"
user-invocable: true
disable-model-invocation: true
---

## User Input

```text
$ARGUMENTS
```

The first whitespace-delimited token of `$ARGUMENTS` MUST be one of `approved`, `approved-with-notes`, `rejected` (case-insensitive; canonicalize to lowercase for recording). Everything after it, trimmed of surrounding quotes/whitespace, is free-text `notes` (optional). Empty `$ARGUMENTS` is an error — see Pre-Execution step 6 / Record the Decision step 1.

## What this is

This command is **the workforce human gate** (D9; the `workforce-gate` row of `artifact-layout.md` §2), mirroring `/speckit-council-approve` exactly (S13). It is the third and last of the workforce extension's three commands, and — like the council gate — the only one not backed by an LLM session: `/speckit-categorize` dispatches a `categorizer` session, `/speckit-agent-assign` runs `assemble.py` deterministically (plus a `skill-builder` session only on a ∅-match gap), but **this command runs no session at all — a human reads the assembled roster and decides.** It only reads `agents/assignment.md`, takes (or, in auto mode, verifies) a decision, and resolves that one section's six fields. There is no model call anywhere in this flow, so the subscription-auth constraint (D28) is trivially satisfied — there is nothing to authenticate.

Because a real human decision is the entire point of this command, `disable-model-invocation` is `true` above — unlike its sibling command skills. An agent must never invoke this skill on its own initiative to wave a roster through the gate; it only runs when a human explicitly types `/speckit-workforce-approve …`.

**The write boundary (principle 1, within one file).** `agents/assignment.md` has two writers for two disjoint regions of the *same* file: `assemble.py` (T014) writes everything from the file header down through the `### Roster approved` table — base/skill selection, the `library`/`built` marks, the elevated-grant union, the empty-lane and dropped-skill notes. This command writes only the `## Workforce Gate` table's three fields (`reviewer`/`decision`/`reviewed`), the section's own timestamp, and the trailing `**Notes:**`/`**Overrides:**` lines — **never** the `### Roster approved` table sandwiched between them. Neither writer ever touches the other's region; `assignment.template.md`'s own template-source comment names the `[PENDING …]` markers as "the only content in this file that command is ever allowed to touch."

**Bootstrap note (S28).** `003-workforce` is the feature that builds this very command (and the git-ext `on-gate-approve` generalization it fires into). Its own workforce gate therefore cannot be signed through machinery that did not yet exist when assembly ran for `003` itself — exactly as `002-speckit-ext-git`'s council gate was left unbound at the time (R1-S28, like M1's fast-forward). That gate, if `003` needs one, is hand-written and grandfathered; the binding this feature designs does not retroactively apply to the feature that designs it. This is a one-time historical fact about `003`, not a runtime branch this command implements — every other feature exercises this command normally.

## Pre-Execution

1. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root and parse `FEATURE_DIR` (absolute path) — the same feature-resolution mechanism (`.specify/feature.json` under the hood) the council gate uses.
2. **Require an assembled roster.** `FEATURE_DIR/agents/assignment.md` must exist — i.e. `/speckit-agent-assign` has run. If missing: ERROR — "Run /speckit-categorize then /speckit-agent-assign before /speckit-workforce-approve" — and stop.
3. **Require the gate section and the roster beneath it.** The file must contain a `## Workforce Gate` heading with a `### Roster approved` subsection (and its table) nested inside it. If either is absent, the file is non-conformant upstream (an `/speckit-agent-assign`-side contract violation, `artifact-layout.md` §8) — ERROR naming the specific missing piece rather than guessing.
4. **Read the current section's marker state.** Take the *last* `## Workforce Gate` heading in the file (normally the only one). Note whether its six fields (timestamp, reviewer, decision, reviewed, notes, overrides) still carry `[PENDING …]` markers or are already fully resolved — this drives both the write step below and the auto-mode branch.
5. **Read the autonomy profile.** Read `FEATURE_DIR/profile.yaml`. If the file is absent, present but unparseable, or `gates.workforce.mode` is unset: the mode is `human` (`profile-schema.md` P1 — a missing or broken profile is the safest posture, never the fastest one; never default to `auto`). Otherwise read `gates.workforce.mode` literally (`human` or `auto`).
6. **Check the grant tripwire (D67), then branch on mode.** Scan the roster for its `**Grant tripwire (D67)**` notice — equivalently, any `Elevated grants` cell that is not `none`. **If the tripwire is ENGAGED (any elevated grant), the effective mode is forced to `human` regardless of `gates.workforce.mode`** — D67 verdict 12: approving a grant-bearing roster is approving network/tool access (A-2/D41), the one thing `auto` must never wave through unseen, so a human signs it. (A correctly-behaving `/speckit-agent-assign` will already have left the gate `[PENDING …]` for exactly this reason rather than auto-writing it.) Then branch: tripwire ENGAGED, **or** `gates.workforce.mode: human` → continue to "Present to the Human" below. `auto` **and** tripwire clear → skip straight to "Autonomy" below; do not parse `$ARGUMENTS` in that branch (there is no human decision to collect — whatever was passed is ignored).

## Autonomy — `gates.workforce.mode: auto` (FR-020/W4)

> **Reached only when the grant tripwire is CLEAR (D67 verdict 12).** Pre-Execution step 6 forces `human` mode whenever the roster carries any elevated grant, so this branch runs only for a grant-free auto roster. The standalone-P4 reading below is now **ratified** (D67, resolving I-19) — with that one carve-out: elevated grants always demand a human, no matter the profile.

**`gates.workforce.mode: auto` is valid on its own — it does not require `full_auto: true`.** `profile-schema.md` P4 is explicit: "`gates.workforce.mode: auto` alone is valid with `full_auto: false`. The workforce gate is an economic guard (don't spend tokens on a bad roster); the council gate is a correctness guard. Only the correctness guard is protected." This differs from the council gate's own handshake (P2: `gates.council.mode: auto` *does* require `full_auto: true`) — do not carry that requirement over by analogy. `full_auto: true` additionally forces *both* gates to `auto` together (P3), so a full-auto profile is one case that reaches this branch, but not the only one. Either way, this command reads `gates.workforce.mode` directly and does not re-validate any handshake itself — that is `profile.yaml`'s own conformance, owned upstream, the same non-revalidation stance `/speckit-council-approve` takes for its own (stricter) handshake.

**The load-bearing contract point: under `auto`, this command is not the writer.** Per `profile-schema.md` §4 ("workforce | mode: auto | Assignment writes the gate section itself") and `artifact-layout.md` §8 W4 ("under `auto` the assigner writes the roster and no [human-sourced] gate section is required"), the `## Workforce Gate` section for an auto-mode feature is written by **`/speckit-agent-assign`** itself — as the last step of assembly (mirroring triage's auto-write for the council gate) — not by an invocation of this command.

So, when Pre-Execution finds `gates.workforce.mode: auto`:

- **If the current `## Workforce Gate` section already carries a resolved decision with `reviewer: auto`** (no `[PENDING …]` markers left) — this command is a no-op. Report the existing decision and confirm `/speckit-implement-parallel` is unlocked (when `decision` is `approved`/`approved-with-notes`). Do not touch the section.
- **If `[PENDING …]` markers are still present** — do not resolve them to fill the gap. This means `/speckit-agent-assign` has not (yet) completed its auto-write — an out-of-order invocation, or assembly still mid-run. ERROR: "`gates.workforce.mode` is `auto` — the gate section is written by `/speckit-agent-assign`, not by `/speckit-workforce-approve`. Re-run `/speckit-agent-assign`; do not invoke this command directly under auto mode." Stop.

Either way, this command itself never writes to `agents/assignment.md` under `auto` mode, and — per Observability below — it writes no trace in that case either: the auto gate-write (and the accompanying `after_workforce_approve` fire) happens as a side effect inside `/speckit-agent-assign`'s own run. The `workforce-gate` phase remains sessionless even when automated; there is simply no separate dispatch for this command to make.

## Present to the Human (human mode only)

Show the reviewer exactly the artifacts the contract names (`artifact-layout.md` §2's `workforce-gate` row, context-in: `tasks.md`, `agents/assignment.md`):

1. **`agents/assignment.md`'s `### Roster approved` table**, in full — one row per assembled agent: `Task(s)`, base, `Model`, `Skills (id@ver)`, `Elevated grants` (W1). This table is what's being approved; reading it against `tasks.md`'s task list is what "approving the roster" means.
2. **Any empty-lane note** (FR-016 — a task matched no `(type, specialization)` lane and fell back to `agt_generic`) and **any dropped-skill note** (FR-011/SC-004 — a candidate trimmed by the 3-skill cap) printed below the table.
3. **The file header's `tasks.md` SHA and library-snapshot hash** (S14/S18) — lets the reviewer confirm the roster was assembled against the `tasks.md` currently on disk, not a stale one.

**Check for elevated grants (FR-018/W2).** Scan every row's `Elevated grants` column for anything other than `none`. The column is never omitted precisely so this check is possible — call out each one explicitly before asking for a decision: approving the roster *is* approving that network/tool access (e.g. `web_search` on a skill-builder-authored skill, D41/D60). The core toolset (`Read, Write, Edit, Bash, Glob, Grep`) is assumed and not listed (D44), so anything shown here is *additional*. This is exactly the **D67 grant tripwire** (verdict 12): if any grant is present, this human review is mandatory even under `gates.workforce.mode: auto` — which is why you are here rather than the auto branch.

**Check for an empty-lane fallback (FR-016).** A task assembled onto `agt_generic` because it matched no lane is a signal worth surfacing, not a silent default — flag it the same way.

Whatever the human decides about either flag must be discoverable afterward: name it in `Notes:`, or in `Overrides:` if they are approving *despite* the concern — silently letting a mandatory-disclosure field pass unmentioned is exactly what W2/FR-016 exist to prevent.

## Record the Decision

1. **Parse `$ARGUMENTS`** (human mode only — mode was already confirmed `human` in Pre-Execution): first token → `decision` ∈ {`approved`, `approved-with-notes`, `rejected`} (case-insensitive, canonicalized to lowercase); the remainder, trimmed → `notes`.
   - Empty `$ARGUMENTS`, or a first token that isn't one of the three values → ERROR and ask for one explicitly (echo the `argument-hint`). **Never default a missing or unrecognized decision to `approved`** — silently approving on unparsed input would turn the gate into a formality, which is precisely the failure mode this command exists to prevent.
   - `decision == approved-with-notes` with empty `notes` → ask the human to supply the notes before recording; the decision's own name promises them. Do not invent notes on their behalf, and do not silently downgrade to plain `approved`.
   - `decision == rejected` with empty `notes` → strongly prompt for a reason (reassignment needs something to act on), but proceed if the human declines to give one; record `**Notes:** none.`
2. **Resolve `reviewer`.** Run `git config user.name`. If empty/unset, fall back to `$USER` / `whoami`. If still empty, use the literal `unknown` and append a clause to `notes` flagging that no reviewer identity could be resolved.
3. **Resolve the six decision fields of the current `## Workforce Gate` section.** Its layout (per `assignment.template.md`) is *not* one contiguous block: the timestamp + `reviewer`/`decision`/`reviewed` table sit at the **top** of the section, then `### Roster approved` and its table (plus empty-lane/dropped-skill notes) sit in the **middle** — untouched, `assemble.py`'s alone — then `**Notes:**`/`**Overrides:**` sit at the very **bottom**, after the roster.

   **If the top and bottom fields still carry `[PENDING …]` markers** (the common case, straight off `/speckit-agent-assign`): resolve each **in place**, producing exactly this shape at the top —

   ```markdown
   ## Workforce Gate — <ISO-8601 UTC timestamp>

   | Field | Value |
   |---|---|
   | reviewer | <name> |
   | decision | `<approved|approved-with-notes|rejected>` |
   | reviewed | `tasks.md`, `assignment.md` (roster) |
   ```

   — and this shape at the bottom, immediately after the (untouched) roster table and its notes:

   ```markdown
   **Notes:** <notes, or "none.">

   **Overrides:** <one line per elevated-grant or empty-lane item the human approved despite, or acted on — or "none.">
   ```

   (`reviewed`'s value is the literal one `artifact-layout.md` §8's own worked example uses — paths relative to `FEATURE_DIR`, not dynamically computed.) Every byte of `### Roster approved` — rows, marks, empty-lane notes, dropped-skill notes — stays exactly as `assemble.py` wrote it.

   **If the section is already fully resolved** (no `[PENDING …]` markers left — a second invocation with no intervening `/speckit-agent-assign` reassignment, e.g. the human correcting an earlier call): never edit the resolved fields in place. **Append a new `## Workforce Gate — <timestamp>` block** (the same shape as above, freshly composed, including its own `### Roster approved` table copied verbatim from the current roster) after the existing one, at the end of the file. This mirrors `decision-record.md` R6's "a correction is a new section, never an edit" rule — exactly what W3 means by "the section may recur… the last one is authoritative." The newly appended block is authoritative; the prior one is left untouched as history.
4. If `agents/assignment.md` has no `## Workforce Gate` heading at all, Pre-Execution step 3 should already have stopped — treat reaching this point as an internal-consistency failure and re-run Pre-Execution rather than guessing where to write.

## Fire the Gate-Write Hook, and Effect (FR-020/S02/S13)

After the write above succeeds:

- **`approved` or `approved-with-notes`** → fire **`after_workforce_approve`** now. Per `workforce/extension.yml`'s own comment, this command is the sole emitter of that event ("`/speckit-workforce-approve` EMITS this event"); the *handler* lives entirely in the git extension's own source (D57 S2, since git owns `gates.yml`) — registered as the `speckit.git.record-gate` hook (`gate: workforce`) in `extensions/git/extension/extension.yml`, resolving to the generalized `on-gate-approve.sh workforce` action (the `on-council-approve.sh` → `on-gate-approve.sh {council|workforce}` generalization, S02). Concretely: **run it** — `sh .specify/extensions/git/scripts/on-gate-approve.sh workforce` — and honor its exit code. This is what `git/extension.yml`'s hooks-header comment means by "no HookExecutor… the invoking phase-skill runs the hook and honors its exit code": this command *is* that phase-skill, so making the call is its job, not something that happens automatically elsewhere. The action composes `gates.sh write workforce`, binding `tasks.md @ <sha>` + `assignment.md @ <sha>` into git-ext-owned `gates.yml` — which is what lets the `before_implement` `verify-gate` (`gate: workforce`, already registered) pass, unlocking `/speckit-implement-parallel`.
  - **Detect the git extension the same way the council gate does**: a registered `after_workforce_approve` hook in `.specify/extensions.yml`, equivalently `git` appearing in its `installed:` list. If the git extension is not installed, there is no `gates.yml` to bind — skip the fire step and say so plainly; the `## Workforce Gate` section itself is still fully recorded, and this phase's artifact-out does not depend on git-ext being present.
  - If the git extension **is** installed but `on-gate-approve.sh` (or the `after_workforce_approve` registration) is not yet present, that is a genuine upstream gap in git-ext's own generalization — report it plainly rather than silently skipping or failing obscurely.
  - This command never writes `gates.yml` itself (sole-owner ruling, R1-S09/S20) — it only triggers the action that does, exactly as `/speckit-council-approve` triggers `after_council_approve` for the council gate.
- **`rejected`** → **do not** fire `after_workforce_approve`. The event denotes an approval *existing*, not merely this command having run — `on-council-approve.sh`'s own header states the equivalent framing for its gate: "Fires once a council approval exists… the event firing at all already means an approval exists." No binding is written; a stale prior `workforce:` block in `gates.yml` (from an earlier cycle) is left untouched, and since `assignment.md` just changed, `verify-gate.sh`'s SHA check would catch it as stale regardless. Nothing is unlocked. The roster returns for reassignment (W3): `/speckit-agent-assign` re-runs — most likely after the concern named in `Notes:` is addressed — producing a fresh `agents/assignment.md` with a new `[PENDING …]` gate, and this command runs again once that lands.
- Per W3/R6, a later invocation of this command appends another block rather than editing a resolved one (see "Record the Decision" step 3); whichever is last in the file is authoritative.

## Observability — no trace (the one exception to principle 4)

**This command writes nothing to `traces.jsonl`, in every mode.** This is deliberate and contract-specified, not an oversight:

- `artifact-layout.md` §2: "Three rows run **no session** and so leave no trace: `branch` …, `council-gate` and `workforce-gate` (a human). The gates still write artifacts — their decision sections — which is what keeps §3 [resumability] working."
- `trace-schema.md` §7 rule 9: "`branch`, `council-gate` and `workforce-gate` run no session — a git ref and a human, respectively — and correctly have none."
- `commands.md`'s own row for this command: **Session** — none, mechanical; **Trace** — none, "the gate runs no session" (artifact-layout §2 / trace-schema R9, the D47 pattern the council gate follows).

No LLM session runs here — a human reads the roster and decides, and this skill just records it (or, under `auto`, merely verifies what `/speckit-agent-assign` already wrote) — so there is no `role`, `model`, `tokens`, or `duration_ms` to report, and fabricating a trace record with placeholder values would be worse than omitting one. The audit trail for this phase lives entirely in the `## Workforce Gate` section itself, plus — on approval — the `gates.yml` binding the fired hook writes. Both are artifacts, not transcript, which is what keeps this phase's completion inferable from the artifact tree alone with no trace needed (`artifact-layout.md` §3, resumability rule). Running the hook action in the previous section is a plain mechanical shell step, same as every other git-ext primitive (`commit.sh`, `verify-gate.sh`); it is not a model session and does not change this.

## Completion Report

Report, concisely:
- Feature and the roster reviewed (row count; any elevated-grant or empty-lane flags surfaced).
- Mode (`human` / `auto`) — and in `auto` mode, whether this run found an existing auto gate (no-op) or had to stop (out-of-order invocation).
- Reviewer and decision recorded (or, in the auto no-op case, the existing recorded decision) — and whether it was an in-place resolution or an appended correction block.
- Fire outcome: `after_workforce_approve` fired (git-ext bound `gates.yml`) / skipped — git extension not installed / not fired — decision was `rejected`.
- Effect: `/speckit-implement-parallel` unlocked, or the roster returns for reassignment via `/speckit-agent-assign`.
- An explicit line: no `traces.jsonl` record was written (no session ran).

## Done When

- [ ] Preconditions verified: `agents/assignment.md` exists with a `## Workforce Gate` section and its nested `### Roster approved` table — or the command stopped with a specific missing-artifact message.
- [ ] `profile.yaml` gate mode resolved, defaulting safely to `human` on absence or parse failure; `auto` accepted whether or not `full_auto` is set (P4, ratified by D67); **the D67 grant tripwire checked first** — any elevated grant in the roster forces `human` regardless of profile.
- [ ] Human mode: roster table + empty-lane/dropped-skill notes presented; any non-`none` `Elevated grants` row and any empty-lane fallback flagged before a decision was asked for.
- [ ] Auto mode: no section fabricated by this command; an existing `reviewer: auto` section was detected and reported, or the command stopped cleanly on an out-of-order invocation.
- [ ] Only the six decision fields (timestamp, reviewer, decision, reviewed, Notes, Overrides) were written or appended — the `### Roster approved` table was never touched.
- [ ] `after_workforce_approve` fired on `approved`/`approved-with-notes` (or its absence explained, if git-ext isn't installed) — and explicitly **not** fired on `rejected`.
- [ ] Effect reported correctly: `approved` / `approved-with-notes` → implement unlocked; `rejected` → returned for reassignment via `/speckit-agent-assign`.
- [ ] No `traces.jsonl` record written, in any mode.
- [ ] Completion reported to the human.
