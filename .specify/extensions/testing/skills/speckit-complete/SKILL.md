---
name: "speckit-complete"
description: "Close out an implement run: re-read tasks.md + implement.log.md from disk on every invocation (R1-S02, never from assumed/retained context) and author completion-report.md — the complete phase's sole artifact (principle 1), in the finalized format docs/contracts/completion-report.md fixes (frontmatter status ∈ {success, partial, failed} + six ordered core sections; an optional milestone-close appendix outside the validated core). Runs entirely in the main thread — no subagent dispatch, no standalone script, no new model role (FR-001); the phase's trace is one orchestrator-role record, not a dispatched session's. A malformed or absent report leaves complete incomplete (resumability, spec.md US1) and nothing downstream fires. Honors the after_complete hook (git-ext's own, owned-source) when registered."
argument-hint: "None required — /speckit-complete takes no flags; it always operates on the current feature's tasks.md + implement.log.md (resolved via .specify/feature.json). Free text, if given, is noted in the completion report but changes nothing below."
compatibility: "Requires spec-kit .specify/ structure with tasks.md (from /speckit-tasks-graph or /speckit-tasks) and, ordinarily, implement.log.md (from /speckit-implement-parallel or /speckit-implement) — the record of what an implement run did. Validates its own output against docs/contracts/completion-report.md; a registered after_complete hook (git-ext's own, extensions/git/extension/extension.yml) is honored if present but is not required for this skill to run."
metadata:
  author: narenkarthikbm
  source: "extensions/testing/extension/skills/speckit-complete/SKILL.md — speckit-ext-testing (specs/004-testing-completion), T010"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

`/speckit-complete` defines no required flags — `contracts/commands.md`'s row for this command names no argument for `$ARGUMENTS` to mean (the same stance `/speckit-categorize` takes for its own invocation). If non-empty, note it verbatim in your completion report but let it change nothing in the procedure below. In particular: whether this build closes a `docs/05-IMPLEMENTATION-PLAN.md` milestone (and therefore earns the optional appendix — see "Write completion-report.md" step 4) is **your own judgment as the orchestrator**, drawn from your own knowledge of the milestone plan, never something a flag here gates.

## What this is

You are the **orchestrator**, and for the first time in this pipeline, you are also the **entire session**. Every sibling phase-command either dispatches at least one subagent (`/speckit-categorize` → one `categorizer`; `/speckit-council` → deck-prep + members + chairman; `/speckit-implement-parallel` → one subagent per task per wave) or runs no session at all because a human decides (`/speckit-workforce-approve`, `/speckit-council-approve`) or because it's mechanical git with no model call (`speckit.git.commit`, `speckit.git.verify-gate`). `/speckit-complete` is neither: **you** — the main-thread Opus orchestrator — read the two input files and author `completion-report.md` yourself, in this turn, with no `Agent`-tool dispatch anywhere in the procedure. No new model role is introduced (FR-001); the pipeline's roster of traced roles gains nothing here.

This command exists — rather than the orchestrator just narrating the same content as bare inline prose with no named command — for exactly one reason, ratified by the council (`R1-S17`, `decision-record.md`): a hook fires on a command **boundary**, and the `complete` phase had none. M5's future `after_complete` D19 push (FR-005) and git-ext's `after_complete` commit hook (FR-012 — the `complete(<id>)` commit `002` deferred) both need this boundary to hang on. Every other pipeline phase is already a `/speckit-*` command; leaving `complete` as bare orchestrator prose would have made it the sole exception.

**The hard rule this command exists to enforce on you (`R1-S02`).** However confident you feel that you already know what `tasks.md` and `implement.log.md` say — because you just finished running `/speckit-implement-parallel` yourself, in this same conversation, moments ago — you **re-read both files from disk, in full, every single time this command runs.** Never author `completion-report.md` from memory of what you saw earlier in this session. Resumability (Constitution III, `artifact-layout.md` §3) beats context retention: "I already have this in context" is exactly the kind of assumption that silently breaks — across a compaction, a `/clear`, a resumed session opened fresh days later, or simply a long multi-wave implement run whose early waves have scrolled out of what you'd naturally recall. A stale or half-remembered read here produces a report that doesn't match what's actually on disk, and there is no downstream check that would catch that — `completion-report.md`'s contract validates its *shape*, not whether its content matches the source files. Treat the re-read as unconditional, never a step you skip because "this is a fresh run anyway" or "I just wrote `implement.log.md` myself." It costs two file reads; skipping it risks an inaccurate report the rest of the pipeline (and M5's future D19 push) trusts as the historical record of what happened.

## Pre-Execution

1. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root; parse `REPO_ROOT` and `FEATURE_DIR` (absolute paths — use them absolute in every subsequent command). The spec ID is `basename(FEATURE_DIR)`.
2. **Require `tasks.md`.** `$FEATURE_DIR/tasks.md` must exist. If missing: ERROR — "no tasks.md — run /speckit-tasks (or /speckit-tasks-graph) first" — and stop. Write nothing.
3. **Check `implement.log.md`, but don't hard-require it.** `$FEATURE_DIR/implement.log.md` is the normal record `/speckit-implement-parallel` leaves — one line per wave. It can legitimately be absent for a trivial feature that `/speckit-implement-parallel`'s own Guardrails routed around wave orchestration entirely ("< 3 tasks with no real parallelism, skip orchestration and just implement inline") — that path never reaches the log-append step. Branch on what `tasks.md` shows:
   - Some tasks are `[X]` (or all of them) and `implement.log.md` is absent → proceed, but note plainly in the eventual report that there is no wave log because implementation ran inline, not through the wave loop; treat "waves run" as `0 (inline)`.
   - **No** tasks are `[X]` and `implement.log.md` is absent → nothing has been implemented yet. ERROR — "no implement.log.md and no completed tasks — run /speckit-implement-parallel (or /speckit-implement) first" — and stop. Write nothing.
4. **Idempotency note.** A prior valid `completion-report.md` already existing is not an error — this command has no "already done" short-circuit; every invocation re-derives from the current `tasks.md` + `implement.log.md` (Step 1's `R1-S02` re-read applies identically on a second run) and overwrites the prior file. If a prior valid report exists and you have reason to believe nothing has changed since, say so in your report rather than silently re-writing identical content as if it were new.

## Step 1 — Re-read from disk (`R1-S02`, no exceptions)

Read `$FEATURE_DIR/tasks.md` and (if present, per Pre-Execution step 3) `$FEATURE_DIR/implement.log.md` now, in full, regardless of anything you already believe you know about their contents from earlier in this conversation. This is the one behavior this entire command is named to guarantee — see "What this is" above for why. Do not proceed to Step 2 on a remembered summary; the read must actually happen, this turn, every turn.

While you're here, also read `$FEATURE_DIR/agents/assignment.md`'s `### Roster approved` table, if present — it feeds the roster-summary requirement in Step 2. It is not, itself, this command's `R1-S02` obligation (that rule names exactly `tasks.md` + `implement.log.md`), but reading it fresh alongside them is nearly free and keeps the roster line honest against whatever the workforce gate actually approved.

## Step 2 — Derive the run's shape

From the files just read:

- **Task completion.** Count total tasks in `tasks.md`'s task list and how many are checked `[X]`. Note any that are unchecked but were explicitly implemented and reported partial/degraded or failed (`implement-parallel`'s own wave reviews classify these; `implement.log.md`'s per-wave `outcome` field is the primary signal — cross-reference against which task IDs that wave's line names).
- **Waves.** From `implement.log.md`'s lines (`<ISO> | wave <N> | tasks: <ids> | agents: <n> | outcome: success|partial|failed`): the count of waves run, the widest parallel wave (`max(n)` across lines), and each wave's own outcome. `0 (inline)` per Pre-Execution step 3 when the file is absent and implementation ran inline.
- **Roster summary.** From `agents/assignment.md`'s `### Roster approved` table: a one-line-per-distinct-assembly summary — base + injected skills, e.g. "3× `agt_devtools_cli` (no skills), 1× `agt_ai_agents` + `skl_x@1.0`". A row with no injected skills is the modal case against a small library, not an omission — name it plainly (`speckit-implement-parallel/SKILL.md`'s own "zero-injection case, explicit" precedent: a bare base still gets a complete, named mention, never a blank).
- **Integration status.** The end-to-end claims this run can actually back with evidence from `implement.log.md` (and, if you dispatched waves yourself moments ago, your own direct knowledge of that dispatch): do imports resolve, do the tests the plan called for pass, are shared-file integrations (registries, manifests) clean. This is **the most load-bearing section** — `testing.md`'s coverage map (FR-008) grounds its verification approaches in exactly this section's claims, so state it concretely (what was checked, how) rather than a vague "looks fine."
- **Key results.** The headline outcomes worth surfacing without reading the rest of the report.

## Step 3 — Derive `status` truthfully (FR-003, `spec.md` US1 scenario 2)

- `success` — every task is `[X]` and every wave's logged outcome is `success` (or there is no log because a trivial inline implementation completed cleanly, Pre-Execution step 3).
- `partial` — at least one task or wave finished partial/degraded, but nothing is an outright unresolved failure.
- `failed` — at least one required task or wave failed and was not subsequently resolved.

**Never write `success` when the underlying record shows any partial or failed task or wave** — that is precisely the scenario `spec.md` US1 scenario 2 exists to catch, and it is a truthfulness rule on *content*, not a formatting one: a well-formed report that honestly declares `status: failed` still makes the `complete` phase itself *complete* (see "Failure and resumability" below) — only a **structurally** malformed or absent file makes it incomplete. Do not conflate the two.

## Step 4 — Write `completion-report.md` (the sole artifact, principle 1)

Compose the file at `$FEATURE_DIR/completion-report.md`, matching `docs/contracts/completion-report.md` exactly — that contract, not this skill and not any template file, is the normative source; if `extensions/testing/extension/templates/completion-report.template.md` exists, treat it as a convenience scaffold only, never an authority that could disagree with the contract. **Self-check the composed content against §6 (below) before you call `Write`** — this is a check-then-write discipline, not write-then-validate-then-maybe-revert: there is no external validator script gating this phase at runtime (unlike `/speckit-categorize`'s `validate-categorization.py`), so nothing else will catch a mistake for you.

The exact skeleton (`docs/contracts/completion-report.md` §1, verbatim):

```markdown
---
feature: 004-testing-completion    # spec ID, string
phase: complete                    # literal — always "complete"
status: success                    # success | partial | failed (FR-003)
---

## Implementation Complete — <name>

### Completed (N/N)

### Partial/Degraded

### Failed

### Integration status

### Key results

<!-- Everything below this line is the OPTIONAL appendix — outside the
     validated core. Omit entirely on a non-dogfood feature. -->

## Milestone-close context

## Decisions & log
```

Fill it in:

1. **Frontmatter** — `feature` = the spec ID; `phase` = the literal string `complete`; `status` = Step 3's verdict, exact lowercase, no other value.
2. **The six core sections, spelled exactly as above, in this exact top-to-bottom order — no other top-level (`##`) heading anywhere in the core:**
   - `## Implementation Complete — <name>` — `<name>` is the feature or extension name this report describes (need not equal frontmatter `feature` verbatim — precedent: `003`'s report titled this heading `speckit-ext-workforce`, not `003-workforce`); non-empty, never the literal string `<name>`. Body: waves run + widest parallel wave + the roster summary (Step 2).
   - `### Completed (N/N)` — `N/N` = `<completed>/<total>`, two non-negative integers, `completed ≤ total`, **no space around the slash** (e.g. `### Completed (12/19)`) — never a literal placeholder.
   - `### Partial/Degraded` — **exactly this spelling, no spaces around the slash** (not "Partial / Degraded" — `plan.md`'s own illustrative rendering elsewhere in this repo uses spaces; the ratified contract does not, and the contract is authoritative). **Present even when empty** — write "None." or equivalent prose; never omit the heading.
   - `### Failed` — same "present even when empty" rule as above.
   - `### Integration status` — Step 2's integration claims, concretely.
   - `### Key results` — Step 2's headline outcomes.
3. **`status == partial` ⟹ `### Partial/Degraded` is non-empty; `status == failed` ⟹ `### Failed` is non-empty** (the section must carry the detail the status claims exists). The converse does not hold — a `success` report may still narrate a handled partial hiccup in either section without contradicting its own status (`003`'s own precedent).
4. **Optional appendix** — `## Milestone-close context` and/or `## Decisions & log` — add **only** when this feature closes out a `docs/05-IMPLEMENTATION-PLAN.md` milestone (your own judgment as the orchestrator, never flag-gated — see "User Input" above). Their internal structure is free-form (`docs/contracts/completion-report.md` §3); a non-dogfood feature omits both entirely. Presence or absence here never changes what validates.
5. **Self-check against `docs/contracts/completion-report.md` §6**, before you write: frontmatter parses and `status` is an exact-lowercase member of `{success, partial, failed}`; all six headings present, exactly spelled, in exact order; `Partial/Degraded`/`Failed` present regardless of emptiness; the only `##` headings anywhere are the one core heading plus zero/one/both appendix headings; the status/section-emptiness rule in point 3 holds. (Note: `extensions/testing/test/run.sh` independently re-derives and re-checks this same section list after the fact, for CI/dev-time conformance — that is a separate, code-level check built elsewhere; it is not something this skill invokes, and its existence doesn't relax your own obligation to get this right at write-time.)

Write **only** this one file. Never touch `tasks.md` or `implement.log.md` (read-only inputs) or any other artifact. If you genuinely cannot produce a conforming file — the inputs are ambiguous or contradictory in a way you cannot honestly resolve — stop and report the specific blocker rather than writing a guess or a plausible-looking-but-non-conformant file.

## Step 5 — Trace (exactly one record, `role: orchestrator` — not a dispatched session)

`complete` is `main`-session per `artifact-layout.md` §2, and it is **not** one of the three rows (`branch`, `council-gate`, `workforce-gate`) that §2 / `trace-schema.md` §7 rule 9 name as running no session and correctly leaving no trace. So — unlike `/speckit-workforce-approve`, which is a genuine no-trace exception because a human decides — this phase **does** get a trace record: yours. Append exactly one to `$FEATURE_DIR/traces.jsonl` when this turn ends, regardless of outcome ("no exceptions, no opt-out," `trace-schema.md` line 8).

(No prior feature's `traces.jsonl` has ever actually carried a `role: orchestrator` record — `001`/`002`/`003` only ever traced dispatched subagents (`categorizer`, the council roles, `implementer`) plus the human/mechanical no-trace exceptions; every other main-thread-only phase — `specify`, `clarify`, `plan`, `tasks`, `analyze` — is an unmodified stock spec-kit command SpecSeyal hasn't yet taught this obligation to. `/speckit-complete` is new, SpecSeyal-authored code, so it is written to meet `trace-schema.md` §7 rule 9 from its first run, rather than carrying that same gap forward.)

| Field | Value |
|---|---|
| `schema_version` | `"1.0"` |
| `trace_id` | fresh, unique (`trc_` + ULID/timestamp-random, never reused) |
| `parent_trace_id` | `null` — "`null` for the main thread" (`trace-schema.md` §1); nothing was dispatched this turn for it to be a parent *of*, and nothing dispatched *it* |
| `feature` | the spec ID |
| `phase` | `"complete"` |
| `role` | `"orchestrator"` (`trace-schema.md` §2: `orchestrator \| main thread, all phases \| opus (xhigh)`) |
| `agent_id` | `null` (non-null iff `role == "implementer"`, `trace-schema.md` §7 rule 4 — this is not that role) |
| `skills` | `[]` (rule 5: non-empty only for `implementer`) |
| `elevated_grants` | `[]` (rule 6, same reasoning) |
| `model` | `"claude-opus-4-8"` — the exact id, never the alias `opus` (D18's main-thread policy; `trace-schema.md` §1: "aliases move, a trace is a historical claim") |
| `effort` | `"xhigh"` (D18) |
| `started_at` / `ended_at` | this invocation's own span — from the moment you began Step 1's re-read to the moment Step 4's write (and its self-check) finished — never the whole conversation's lifetime. There is no `Agent`-tool return to time here (mirrors `speckit-implement-parallel`'s own rule for an inline-implemented task: "there is no Agent-tool return to time, so use your own start/finish for that span") |
| `duration_ms` | `ended_at − started_at` |
| `tokens` / `capture_method` | attempt transcript-based attribution scoped to this invocation's span (D47) if your environment exposes one; otherwise record honestly — `capture_method: "unavailable"`, `tokens: null` — never a guessed or estimated number. A continuous main-thread conversation spanning many phases makes a clean per-phase slice genuinely harder to isolate than a dispatched subagent's own bounded transcript; that difficulty is a reason to be honest about `unavailable`, never a reason to fabricate a number |
| `outcome` | mirrors the completion report's own `status` **when a valid report resulted** (`success`/`partial`/`failed` pass straight through); `"aborted"` in the edge case this invocation is interrupted before producing any valid report at all — the one value `completion-report.md`'s own `status` field can never carry (`docs/contracts/completion-report.md` §1: an aborted session by definition never reaches the point of writing the file) |
| `artifact` | `"specs/<feature>/completion-report.md"` when a valid, contract-conforming file resulted; `null` otherwise |
| `cost_usd` | `null` (D28 — subscription-only, no per-call price) |

## Step 6 — Honor `after_complete` if registered

Check `$REPO_ROOT/.specify/extensions.yml` for a `hooks.after_complete` entry — parse if present, skip silently if the file is absent or unparsable, drop any entry with `enabled: false` (the tolerant-parse rule every speckit command here uses). This step only runs after Step 4 has produced a file that passed its own self-check — never on a malformed/absent report (see "Failure and resumability" below).

- **A row is registered** (expected shape once git-ext carries it: `{extension: git, command: speckit.git.commit, optional: false, phase: complete, priority: 5}` — that hook is git-ext's **own**, owned-source (`D57` §9); this extension's own `extension.yml` deliberately declares none, by design) — invoke it: locate the git extension's commit primitive at `$REPO_ROOT/.specify/extensions/git/scripts/commit.sh` and run
  ```
  "$REPO_ROOT/.specify/extensions/git/scripts/commit.sh" complete "<one-line summary, e.g. '12/19 tasks, status: success'>"
  ```
  waiting for it to finish before ending this command. Rely on `commit.sh`'s own contract (staging scope, no-op-if-clean, the FR-006 `complete(<id>): <summary>` phase-tag grammar) rather than reimplementing it. If `commit.sh` is not actually present at that path despite a registered row (a partially-installed/removed git extension), report the mismatch plainly — do **not** fall back to a raw `git add`/`git commit`; that would bypass the primitive's staging-scope and no-op guarantees.
- **No row is registered** (true before git-ext is edited/reinstalled with this hook, or if git-ext isn't installed at all) — this is **not** an error. The `complete` phase is still complete: `completion-report.md` exists and validates, which is the postcondition (`artifact-layout.md` §3) — the hook is a *consequence* of completion, not a *precondition* of it. Note plainly in your completion report that no commit fired automatically and why.

## Failure and resumability (`spec.md` US1, `artifact-layout.md` §3)

A malformed or absent `completion-report.md` leaves the `complete` phase **incomplete** — full stop. Concretely:

- If you cannot produce a file that passes Step 4's self-check this turn, do **not** leave a half-written or structurally invalid file in place claiming to be done; report the specific failure and stop. If a prior valid `completion-report.md` existed on disk before this run started, never leave the tree in a worse state than you found it — restore or remove a bad in-progress draft rather than leaving something that looks plausible but doesn't conform. A later invocation of this same command re-reads (Step 1, `R1-S02`) and tries again — resumability means the next run just repeats the walk, not that this run needs a special recovery path.
- Do **not** run Step 6 (the `after_complete` hook) against a malformed or absent report — the hook is downstream of a *valid* file existing, exactly as `/speckit-workforce-approve` never fires `after_workforce_approve` on `rejected`.
- Do not treat `/speckit-testing` as unlocked until a valid `completion-report.md` is on disk — `testing`'s own context-in is this file (`artifact-layout.md` §2), so an incomplete `complete` phase blocks it by construction, not by a separate check this skill needs to enforce.
- **This is a structural rule, not a content one.** A well-formed report whose frontmatter honestly says `status: failed` (because the underlying implement run failed) still makes the `complete` phase *complete* in the resumability sense — the phase's postcondition is "the artifact exists and validates," not "the news is good." Only a file that fails `docs/contracts/completion-report.md` §6's own validation rules (or a file that was never written at all) counts as incomplete.

## Completion Report

Report, concisely, to whoever invoked you:

```
## Complete — <feature>
Report: specs/<feature>/completion-report.md  (written | self-check failed, not written — see below)
Status: success | partial | failed
Shape: <N> waves (widest: <k> agents)  |  inline, no waves
Tasks: <completed>/<total> complete
Roster: <one-line roster summary, Step 2>
Trace: 1 orchestrator record appended (outcome: success|partial|failed|aborted)
Commit: after_complete → <sha>  |  no-op (clean tree)  |  hook not registered (note why)  |  skipped (report not valid)
Next: /speckit-testing   |   fix the underlying implement issue, re-run /speckit-implement-parallel, then /speckit-complete again
```

## Guardrails

- `tasks.md` and `implement.log.md` are **read-only** to this command, under every outcome — never annotate, patch, or "clean up" either one here.
- Re-read both from disk **every** invocation (`R1-S02`) — never skip this because you believe you already hold their content.
- Exactly one artifact out, ever: `completion-report.md`. Never a second file, never a state file (`artifact-layout.md` §3: "there is no state file, and adding one is forbidden").
- Never write `status: success` when any task or wave in the record finished partial or failed.
- Never invent a roster line, a wave count, or an integration claim you cannot back with something Step 1/2 actually read — `### Integration status` in particular is what `testing.md` grounds its coverage map in; a fabricated claim here propagates downstream.
- No `Agent`-tool dispatch anywhere in this procedure (FR-001) — if you find yourself reaching for one, stop; that would introduce exactly the new model role this phase is designed not to need.
- Never substitute a raw `git add`/`git commit` for the `after_complete` hook's `commit.sh` primitive.
- Subscription auth only (D28) — this skill dispatches nothing to authenticate, but never reference or set `ANTHROPIC_API_KEY` anywhere this project touches.

## Done When

- [ ] Feature resolved; `tasks.md` confirmed present; `implement.log.md` checked (present, or its absence explained as an inline-implementation case per Pre-Execution step 3)
- [ ] `tasks.md` + `implement.log.md` re-read from disk **this turn** — never from earlier-session memory (`R1-S02`)
- [ ] `completion-report.md` composed: frontmatter `status` truthful per Step 3; all six core sections present, exactly spelled, in exact order; `Partial/Degraded`/`Failed` present even when empty; appendix added only for a genuine milestone-close build
- [ ] Content self-checked against `docs/contracts/completion-report.md` §6 **before** writing; any issue fixed pre-write, or the run stopped and reported rather than a non-conformant file left on disk
- [ ] No file other than `completion-report.md` written; `tasks.md`/`implement.log.md` untouched
- [ ] No `Agent`-tool dispatch occurred anywhere in this run — no new model role introduced (FR-001)
- [ ] Exactly one `orchestrator` trace record appended to `traces.jsonl` (`agent_id: null`, `skills: []`, `elevated_grants: []`, `parent_trace_id: null`)
- [ ] `after_complete` honored when registered (invoked and awaited), or its absence noted plainly when not — and never fired against a malformed/absent report
- [ ] On any structural failure: nothing claims completeness that isn't true; the phase is left resumable, not silently patched over
- [ ] Completion reported in the format above
