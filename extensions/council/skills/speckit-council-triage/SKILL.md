---
name: "speckit-council-triage"
description: "Apply the council's accepted suggestions to plan.md and write the append-only decision record: every suggestion gets exactly one disposition with reasoning (D13.5), a blocking suggestion forces one revision plus a chairman-only delta check (FR-010), and the human gate is either left pending or auto-written under full_auto (FR-018)."
argument-hint: "Optional human triage guidance/leanings (e.g. 'reject R1-S02') — never a substitute for reading suggestions.md, and never a waiver of the rationale requirement"
compatibility: "Requires spec-kit .specify/ structure with plan.md, and specs/NNN-feature/council/round-N/suggestions.md written by /speckit-council. The council extension must be installed (.specify/extensions/council/)."
metadata:
  author: narenkarthikbm
  source: "extensions/council/skills/speckit-council-triage/SKILL.md — speckit-ext-council (specs/001-council-extension), T014"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

Treat non-empty `$ARGUMENTS` as optional, informal triage guidance from the human (a leaning on a specific ID, a note about repo context a member couldn't see, an explicit override instruction for a `blocking` row — see "Disposition" below). It may inform your judgment. It is never a substitute for reading `suggestions.md` yourself, and it never waives the rationale requirement (D13.5) — even a human-directed disposition needs its own written reason in the record.

## What this is

`/speckit-council-triage` is the **triage** phase (`artifact-layout.md` §2 phase table). It runs as a single **main-thread Opus session** — a judgment role, not a mechanical pass-through (D18: "Judgment roles (council chairman, analyze/triage): Opus"). It is the one session downstream of the council permitted to act on `suggestions.md`, and it is bound by the same compression boundary the chairman protects: **read `round-N/suggestions.md` and nothing else under `council/round-N/`** — never `opinions/`, never `opinions/peer/`, this round or any prior round, not even to "just double-check one thing" (`spec.md` FR-007, SC-005). You do not re-review the plan from scratch; you dispose of what the council already raised, apply what you accept, and write the permanent record.

You produce two real, git-tracked artifacts: a **revised `plan.md`** (accepted suggestions applied) and an **appended `council/decision-record.md`** (every suggestion's disposition, with non-empty reasoning for every non-acceptance — the one rule `decision-record.md` exists to enforce). Depending on convergence and the autonomy profile, you may also dispatch one subagent (the chairman, delta-check mode) and, under `full_auto`, write the human-gate section yourself.

## Pre-Execution — resolve the feature and the round

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root; parse `FEATURE_DIR` (absolute). This is a stock spec-kit script — it knows nothing about `council/`, which is why steps 2–4 are custom to this extension (same split `speckit-council-approve` uses).
2. **Precondition**: `$FEATURE_DIR/plan.md` must exist. If not, STOP: "no plan.md — run /speckit-plan first."
3. **Precondition**: `$FEATURE_DIR/council/` must exist with at least one `round-N/suggestions.md`. If `council/` is absent entirely, STOP: "no council round — run /speckit-council first." Never fabricate a round or proceed on an assumption.
4. **Find the target round** — the highest `N` for which `$FEATURE_DIR/council/round-N/suggestions.md` exists.
5. **Idempotency (Constitution III / resumability)** — if `$FEATURE_DIR/council/decision-record.md` already has a complete `## Round N` section for that exact `N` (every ID in `suggestions.md` dispositioned) **and** convergence already resolved (zero blocking, or a `### Chairman delta check` already ran), triage for this round is done. Report that and stop — do not re-triage, re-apply, or re-commit. (R1 makes prior sections immutable; re-running is a no-op, never a corruption.)
6. **Resume check** — if the round looks partially triaged (e.g. `plan.md` already carries the edits but `decision-record.md` has no `## Round N` yet — a prior run committed step 1 below and was interrupted before step 4), search `git log --oneline -- "$FEATURE_DIR/plan.md"` for a `council(...): triage round-N` commit and reuse its SHA rather than re-applying suggestions. Never double-apply an edit.
7. **Read `round-N/suggestions.md` — and nothing else under `council/`.** Parse the reduced-grounding banner if present (`> ⚠ Reduced grounding: no graph` — carry it forward, FR-019), the verdict line (`<a> blocking · <b> strong · <c> consider`), every row (`ID`, `Class`, `Suggestion`, `Sources`, `Target`), and the Chairman's note. Cross-check the verdict line against the actual table row counts — a mismatch is a defect in the artifact, not yours to silently paper over; proceed on the **table** (ground truth) and flag the mismatch in your Completion Report.

**Absolute rule, restated because it is the whole point of this boundary**: do not `Read`, `Glob`, `Grep`, or shell into `round-N/opinions/` or `round-N/opinions/peer/` — this round's or any prior round's. `suggestions.md` is the compression boundary precisely so that instinct is never necessary (SC-005), and the invariant extends to your own transcript, not just your visible output.

## 1. Disposition every suggestion, then apply the accepted ones

### Disposition (judgment, not a formality)

For each row, decide exactly one of `accepted` / `rejected` / `deferred`. Weigh the suggestion's `Class`, its `Sources` (how many independent members/peers raised it), whether it cites a graph-grounded finding, and any `$ARGUMENTS` guidance — then decide and write down why.

- **`accepted`** — applied to `plan.md` below. The Rationale cell may be `—` (R3 only mandates reasoning for non-acceptance), a short justification is welcome.
- **`rejected`** — Rationale MUST be non-empty and substantive (R3/D13.5): the actual reasoning a reader months later would find sufficient, not "not needed" (see the contract's own worked example: *"Premature: no measurement, and the lookup is behind an existing memoized accessor. Revisit if the perf budget in §7 is missed."*).
- **`deferred`** — Rationale MUST be non-empty **and name where it resurfaces**: a follow-up spec, a task filed in `tasks.md`, or an `I-` row in `docs/90-DECISIONS-AND-IDEAS.md`. If the natural resurfacing point is an idea for later, **file the `I-` row in `docs/90-DECISIONS-AND-IDEAS.md` yourself, in this same session** (this is CLAUDE.md's own log discipline and `decision-record.md` §3's requirement meeting in the middle) — a `deferred` with nowhere to resurface is a `rejected` wearing a nicer word, and is invalid. Don't write one you haven't actually given a home.

**`blocking` rows are constrained** (`decision-record.md` R5: "the chairman classifies; only a human overrides a blocking"). At triage time no human has seen this round yet — triage runs *before* the gate in the phase order (`artifact-layout.md` §2). So:
- **Default and expected: `accepted`.** This is what drives convergence (FR-010) — a `blocking` finding is a real defect, contract violation, or safety risk; applying the fix is the safe default, and is what "exactly one revision cycle" (D13) assumes happens.
- Record `rejected` or `deferred` for a `blocking` row **only** when `$ARGUMENTS` carries an explicit human instruction to do so this run. State that plainly in the rationale (e.g. "Overridden per operator instruction: …"), and flag it prominently in your Completion Report — R5 requires the eventual `## Human Gate` section to acknowledge it explicitly, so make that impossible to miss.
- Absent explicit human direction, never unilaterally reject or defer a `blocking` row on your own initiative, even if you disagree with the chairman's classification. Apply it; the human can revert at the gate (`FR-011`: a `rejected` gate decision returns the plan for one more round).

### Apply — plan.md edits, then one commit

1. Before editing anything: `PRE_SHA=$(git rev-parse --short HEAD)` — the plan state the council actually reviewed (used as "Plan reviewed" below).
2. For every `accepted` row, edit `plan.md` at its `Target` (`suggestions.md`'s `Target` field is always `plan.md §<N>`, or `plan.md (whole)` for a cross-cutting one — never another file; the council reviews the plan only, D3). Make a real content change that realizes the suggestion — not a TODO or a comment (that is what `deferred` is for). Stay scoped to what each suggestion actually asked for.
3. If **at least one** row was accepted, stage and commit **`plan.md` only**:
   ```
   git add "<FEATURE_DIR>/plan.md"
   git commit -m "council(<spec-id>): triage round-<N> — apply accepted suggestions <ID, ID, ...>

   <1-2 sentence summary of what changed and why>"
   ```
   Follow this repo's phase-tagged commit convention (D25) — `git log --oneline` shows the established `<phase>(<spec-id-or-NNN>): <summary>` shape (e.g. `council(001): apply bootstrap-gate suggestions S1-S4…`, `plan(001-council-extension): …`) and its `Co-Authored-By` trailer; match it. **This commit is itself "the one revision" FR-010 requires** when the round has `blocking` rows — there is no separate revision step later.
4. `POST_SHA=$(git rev-parse --short HEAD)`. Every accepted row's **Plan delta** cell (written in §3 below) is `<file> §<section> @ <POST_SHA>`. R4 formally requires a named commit only for accepted `blocking` rows, but since "accepted" means "applied," every accepted row gets one for free — matching the contract's own worked example, where an accepted `strong` row also names a commit.
5. If **zero** rows were accepted: skip the commit (`PRE_SHA == POST_SHA`); every row's Plan delta is `—`.

*(Why two commits, not one bundled with the decision record below: `decision-record.md`'s own Round-N row must cite the SHA of **this** commit. A commit cannot correctly cite its own eventual hash inside its own tracked content — so the plan revision and the decision-record write are necessarily two separate commits, in that order.)*

## 2. Convergence (FR-010, D13) — the delta check

`council-config.yml`'s `max_rounds: 1` is the same v1 rule spelled out here: **exactly one revision, at most one chairman delta-check, never a second full council round.**

Read the blocking count off the table using this round's dispositions (normally all `accepted`, per §1).

**Zero `blocking` rows survive** → no delta check. §3's `### Chairman delta check` subsection is written verbatim as:
```
### Chairman delta check

*Only present when Round N raised `blocking` items.* — omitted (0 blocking).
```
(the exact phrasing already established by `decision-record.md`'s own contract example and the `001-council-extension` bootstrap record — reuse it, don't rephrase it.)

**≥1 `blocking` row** → after §1's plan.md commit, dispatch **one subagent: the chairman, in delta-check mode**:

1. Read `.specify/extensions/council/templates/chairman-prompt.md` (installed path; fall back to `extensions/council/extension/templates/chairman-prompt.md` only if the extension isn't installed in this repo yet). Render its §2 prompt with `{{mode}}=delta-check` and: `{{feature}}` = spec ID, `{{round}}` = N, `{{plan_path}}` = `<FEATURE_DIR>/plan.md` (the just-committed revision), `{{suggestions_path}}` = `<FEATURE_DIR>/council/round-N/suggestions.md`, `{{prior_blocking_ids}}` = the comma-separated blocking IDs from §Pre-Execution's table, `{{timestamp}}` = now (ISO-8601 UTC).
2. Dispatch via the Agent tool at the `opus` model alias, highest available reasoning effort (D18: chairman is Opus, xhigh — never Sonnet; record the resolved exact id `claude-opus-4-8` in the trace regardless of what alias the dispatch call itself took, per D18's current mapping). Its context is deliberately narrow — only the revised plan and the prior blocking IDs, never `opinions/` — that narrowness is what makes a delta check cheap instead of a second round (`chairman-prompt.md` §1).
3. The chairman appends `### Chairman delta check — <timestamp>` directly to `round-N/suggestions.md` itself and returns **status only**: a one-line delta verdict plus its trace fragment — never opinion prose (S2). Append that trace fragment to `traces.jsonl` now, serially — `role: chairman`, `phase: council`, `parent_trace_id` = your own `trace_id`, `artifact: council/round-N/suggestions.md` — the same orchestrator-serialized-append rule `/speckit-council` follows (`trace-fragment.md` §5), except here *you* are the dispatcher.
4. Re-read `round-N/suggestions.md`'s newly appended block (this file stays readable at any time — it is never `opinions/`) and lift it **near-verbatim** into `decision-record.md`'s own `### Chairman delta check` subsection (`chairman-prompt.md` §4 — this block is the one piece of content designed to travel between the two files).
5. **Outcome**: every prior blocking ID **RESOLVED** → ready for the gate. Any ID **STILL BLOCKING** → the v1 round limit is reached (one revision + one delta check, never a second full round). Escalate: say so unmissably in the Round-N verdict you write next and in your Completion Report, naming the IDs. This holds **even under `gates.council.mode: auto`** — see §4.
6. `round-N/suggestions.md`'s diff (the appended block) is committed together with `decision-record.md` in §3 below — it is the same triage action, not a separate one.

## 3. Write `council/decision-record.md`

Conform to `docs/contracts/decision-record.md` exactly (R1–R7, its §5 section table). Build the content now; the commit happens at the end of §4, after any auto-gate write, so `## Carried Constraints` only ever gets rebuilt once per run.

**If the file doesn't exist**, create it (R7 — it exists as soon as round 1 is triaged):
```markdown
# Decision Record — <spec-id>

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).

## Metadata

| Field | Value |
|---|---|
| feature | `<spec-id>` |
| spec-id | `<spec-id>` |
| profile | `gates.council=<mode>, gates.workforce=<mode>` |
| rounds-run | <N> |
| schema-version | `1.0` |

---
```
`## Metadata` is cardinality-1 (§5) — the one section you *update in place* each run (bump `rounds-run`). R1's "no prior section is ever edited" governs the round/gate/reopen sections that follow, not this header.

Then, **appended in this order** (never touch anything already committed above this point):

1. **`## Reopen`** — only if this round is a reopen round and no `## Reopen` section for it exists yet. See §5.
2. **`## Round N — <ISO-8601 UTC timestamp>`**:
   ```markdown
   ## Round N — <timestamp>

   **Verdict:** <a> blocking · <b> strong · <c> consider
   **Deck reviewed:** `council/defense-deck/technical.md` @ `<sha>`
   **Plan reviewed:** `plan.md` @ `<PRE_SHA>`

   | ID | Class | Suggestion | Disposition | Rationale | Plan delta |
   |---|---|---|---|---|---|
   ```
   `<sha>` for "Deck reviewed" = `git log -1 --format=%h -- "<FEATURE_DIR>/council/defense-deck/technical.md"`. If the reduced-grounding banner was present in `suggestions.md`, carry it forward as the line directly under the `## Round N` heading (FR-019 — the flag must stay visible all the way to the gate). One table row per suggestion ID, **in `suggestions.md`'s own order** (already blocking-first, per `chairman-prompt.md` §2 rule 3). Copy `ID`/`Class`/`Suggestion` verbatim from `suggestions.md`; fill `Disposition`/`Rationale`/`Plan delta` from §1.
3. **`### Chairman delta check`** — §2's block (the omitted-phrasing, or the lifted delta-check content).
4. **`## Carried Constraints`** (must end up last, cardinality 1 — §5) — **rebuild it from scratch** every run: scan *every* `## Round N` table in the file (all rounds, not just this one) for `accepted` rows and render one bullet per accepted suggestion, in the file's existing style (`- \`R<n>-S<nn>\` — <what it constrains, addressed to /speckit-tasks>`). Replace any prior `## Carried Constraints` block wholesale. This is the one section that is a maintained rollup rather than an append-log entry — its own docstring says so ("`/speckit-tasks` reads this section and nothing else from this file"), which is only true if it stays current.

Do **not** commit yet — §4 may still insert a `## Human Gate` section before `## Carried Constraints`.

## 4. Autonomy gate check (FR-018, `profile-schema.md` §4), then commit

Read `<FEATURE_DIR>/profile.yaml`. If absent, unparseable, or `gates.council.mode` unset: mode is `human` (`profile-schema.md` P1 — a missing/broken profile is always the safest posture). Otherwise read `gates.council.mode` literally.

- **`human`** (default) → do nothing further here. The gate stays pending for a human running `/speckit-council-approve`.
- **`auto`** (valid only under `full_auto: true`, P2/P3 — this skill trusts that handshake, it does not re-validate it) **and** §2 converged cleanly (zero blocking, or the delta check resolved every prior blocking ID) → **you** write the gate section, matching `/speckit-council-approve`'s own template exactly (both codepaths must produce a conformant, mutually consistent `## Human Gate` section, R6):
  ```markdown
  ## Human Gate — <ISO-8601 UTC timestamp>

  | Field | Value |
  |---|---|
  | reviewer | auto |
  | decision | `approved` |
  | reviewed | `defense-deck/overview.md`, `round-N/suggestions.md`, this record |

  **Notes:** Auto-approved under `gates.council.mode: auto` (`full_auto: true`) — zero unresolved blocking suggestions.

  **Overrides:** none.

  **Binding:** plan↔SHA binding recorded at `specs/<spec-id>/gates.yml` (git-ext-owned; FR-008/D55).
  ```
  Insert it **immediately before** `## Carried Constraints` (with the file's existing `---` divider convention on each side), never after it — `## Carried Constraints` must remain the last section. This unlocks `/speckit-tasks` (`artifact-layout.md` §7 rule 3).

  The `**Binding:**` line is FR-008's one-line pointer to the git-extension-owned `specs/<spec-id>/gates.yml` (D55, `decision-record.md` §3) — **identical to the one `/speckit-council-approve` writes** in the `human` path, which R6 requires (both codepaths must produce a mutually consistent `## Human Gate` section). It is a well-known-path pointer, not a value you compute: the git ext records the actual plan↔SHA binding via its own hook and never writes here (D55 inverted the ownership). Substitute the concrete spec ID; **never write the SHA itself.** **Include the line only when the git extension is installed** (a registered `after_council_approve` hook in `.specify/extensions.yml`); in a council-only repo with no `gates.yml`, omit it — exactly as `/speckit-council-approve` does, so the two paths stay consistent in that case too.
- **`auto`, but a `blocking` ID is still STILL BLOCKING after the delta check** → **do not auto-approve.** `profile-schema.md` §4: "auto skips the human, never the council" — a residual, chairman-confirmed blocking defect is exactly the correctness guard `auto` may not waive. Leave `## Human Gate` unwritten. Note in your Completion Report that `/speckit-council-approve` will itself refuse to act while `gates.council.mode` reads `auto` with no gate section present (it errors rather than fabricating one) — the concrete unblock path is a human deliberately editing `profile.yaml` to `gates.council.mode: human` (a conscious, out-of-band decision to intervene, not a silent codepath) and then running `/speckit-council-approve` normally.

**Now commit.** Stage everything this run touched under `council/` plus `decision-record.md`:
```
git add "<FEATURE_DIR>/council/decision-record.md" "<FEATURE_DIR>/council/round-N/suggestions.md"
git commit -m "council(<spec-id>): triage round-<N> — decision record (<a> blocking · <b> strong · <c> consider)"
```
(Omit `round-N/suggestions.md` from the `add` if §2 never ran — nothing changed in that file.) This is the second, separate commit referenced in §1's aside — it cannot self-name its own SHA, so nothing in its own content needs to.

## 5. Reopen handling (FR-017, D14)

`/speckit-council-triage` takes no `--reopen` flag of its own — that argument belongs to `/speckit-council` (`commands.md`). Your job is to **behave correctly when the round you're triaging came from a reopen**, not to trigger one.

- **Normal case**: `/speckit-council --reopen <tier>` already appended a `## Reopen` section (trigger, tier, scope) to `decision-record.md` *before* stages 1–3 ran for that round (`commands.md`: "writes `## Reopen` … to the decision record"). If one exists for round N, just triage normally — it is already in the right append position, ahead of your `## Round N`.
- **Defensive fallback**: if context makes it unambiguous this round is a reopen (e.g. `suggestions.md` frames itself as a diff-only review against a named triggering finding) but no `## Reopen` section exists for it yet, append one yourself in §3, ahead of `## Round N`:
  ```markdown
  ## Reopen — <ISO-8601 UTC timestamp>

  | Field | Value |
  |---|---|
  | trigger | <what/who caused the reopen, as best you can name it> |
  | tier | `delta` |
  | tier proposed by | triage |
  | tier confirmed by | pending human gate |
  | scope | <the plan diff / finding this round actually reviewed> |
  ```
  Default `tier` to `delta` (D14's default) unless the evidence shows the patch changed the plan's chosen approach or architecture, in which case propose `full`. You only **propose** — the human gate confirms or overrides in either direction (D14); write `tier confirmed by: triage (auto mode)` only if §4 auto-approves this same run, otherwise leave it `pending human gate`.
- Everything else about a reopen round — disposition, convergence, the decision-record write — is identical to a normal round. A reopen changes what the council looked at, not how triage processes what it produced.

## 6. Trace

Append **your own** trace fragment to `<FEATURE_DIR>/traces.jsonl` — one record: `schema_version: "1.0"`, a fresh `trc_`-prefixed unique `trace_id`, `parent_trace_id: null` (you are a top-level main-thread session, not a dispatched subagent — `trace-fragment.md` §3, same as the `role: triage` record in `specs/000-sample/traces.jsonl`), `feature`, `phase: "triage"`, `role: "triage"`, `agent_id: null`, `skills: []`, `elevated_grants: []`, `model: "claude-opus-4-8"` (exact id, never the alias `opus`), `effort: "xhigh"`, `started_at`/`ended_at`/`duration_ms`, `tokens` + `capture_method` per the resolved spike policy (`token-capture-spike.md`: parse your own session transcript, sum the four `usage` fields; fall back to `capture_method: "unavailable"` / `tokens: null` only if attribution genuinely fails — never guess, D47), `outcome: "success"` (unless the run itself genuinely errored, in which case `partial`/`failed` and say why), `artifact: "<FEATURE_DIR>/council/decision-record.md"`, `cost_usd: null`.

This is your **one** required fragment (FR-015). If §2 dispatched the chairman, its fragment was already appended serially back in §2.3 — do not append it again here.

## Completion Report

Report, concisely:
- Feature/spec-id and round N triaged.
- Dispositions: counts of accepted / rejected / deferred, and the full ID list for rejected + deferred (they're the ones with a story worth surfacing).
- Blocking outcome: 0 blocking (no delta check) | delta check ran, all resolved | delta check ran, `<n>` still blocking — **escalated**, naming the IDs and (if `auto` mode) the profile-edit unblock path from §4.
- Commit SHA(s): the `plan.md` revision (if any) and the `decision-record.md` write.
- Gate status: pending human (`/speckit-council-approve`) | auto-approved this run | escalated, human required despite `auto`.
- Any anomalies noted (verdict/table mismatch in Pre-Execution step 7; a `blocking` row overridden away from `accepted` in §1).
- Next step, stated explicitly as a command to run.

## Done When

- [ ] Read `round-N/suggestions.md` only — no read of `opinions/` or `opinions/peer/`, this round or any prior round
- [ ] Every suggestion ID in `suggestions.md` has exactly one disposition in `decision-record.md`, with non-empty rationale for every `rejected`/`deferred` (D13.5, naming a resurfacing point for `deferred`) and a named commit for every `accepted` row
- [ ] If ≥1 `blocking` survived: exactly one revision commit + one chairman delta-check dispatch, recorded in `### Chairman delta check`; never a second full council round
- [ ] `decision-record.md` conforms to its contract (§5 section table, R1–R7); `## Carried Constraints` rebuilt fresh and last
- [ ] Reopen round handled: existing `## Reopen` respected, or one appended defensively with `tier proposed by: triage`
- [ ] Autonomy gate honored (FR-018): left pending under `human`, auto-written only on clean convergence under `auto`, never auto-approved through a residual blocking
- [ ] Your own `triage` trace fragment appended (plus the chairman's, if §2 dispatched it)
- [ ] Completion Report delivered with a concrete next step
