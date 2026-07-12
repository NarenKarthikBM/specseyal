---
name: "speckit-categorize"
description: "Dispatch one Sonnet categorizer session over tasks.md + plan.md to tag every task (type, specialization, preserves_behavior, tags) per taxonomy v0 — type/preserves_behavior mechanical from graphify signals, specialization interpretive from plan+domain. Code-validates coverage, closed-enum membership, and the 20% general-cap via validate-categorization.py; categorization.md is written only on a passing validation (D37/S22) — an over-cap run or an un-enumerable value FAILs loudly with no artifact and the categorize phase does not complete (FR-004/SC-001/SC-002). Runs after /speckit-analyze (D58); never mutates tasks.md; appends one categorizer trace record and honors the after_categorize commit hook on pass."
argument-hint: "None expected — /speckit-categorize takes no flags; it always operates on the current feature's tasks.md + plan.md (resolved via .specify/feature.json)"
compatibility: "Requires spec-kit .specify/ structure with tasks.md (ideally post-/speckit-analyze, D58) and plan.md, plus the workforce extension's categorizer-prompt.md + validate-categorization.py — read from the installed path (.specify/extensions/workforce/) when present, else from extensions/workforce/extension/ source (true in this repo today, since workforce hasn't been installed on itself yet)."
metadata:
  author: narenkarthikbm
  source: "extensions/workforce/skills/speckit-categorize/SKILL.md — speckit-ext-workforce (specs/003-workforce), T012"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

This command takes no flags (unlike `/speckit-council`'s `--reopen`). If `$ARGUMENTS` is non-empty, note it in your completion report but let it change nothing below — `contracts/commands.md` defines no argument for `/speckit-categorize` for it to mean.

## What this is

You are the **orchestrator**. `/speckit-categorize` runs in the main thread and never categorizes anything itself — it dispatches **one** subagent (the `categorizer`; the "separate session" `artifact-layout.md` §2 assigns this phase) and then runs a deterministic script that is the **sole authority** on whether the run passes. The categorizer **proposes**; it never certifies its own output (FR-005) — and note precisely what "certifies" means here: `validate-categorization.py` is a mechanical correctness gate (coverage + closed enums + the cap), not the human acceptance FR-005 is actually about — that acceptance happens later, at the workforce gate, downstream of `/speckit-agent-assign`. Nothing this command writes is "approved" in that sense; it is only "structurally valid."

This phase runs **after** `/speckit-analyze` (D58): `analyze` may still patch `tasks.md` (D11 remediation), so classifying first would tag tasks that can still change — classification follows stabilization.

The invariant that makes this safe (D37, S22): **`categorization.md` is written only when `validate-categorization.py` exits 0.** An over-cap run or a run carrying any un-enumerable `type`/`specialization` value is a hard FAIL — no artifact, the categorize phase does not complete (FR-004/SC-001/SC-002) — never a softened or partial write. `tasks.md` is read-only for the life of this command, under every outcome: it already has two writers (spec-kit itself and graphify's wave appender, `categorizer-prompt.md`'s own words), and a third would make it the pipeline's shared-mutable file — exactly the hazard graphify exists to detect.

## Pre-Execution

1. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root; parse `REPO_ROOT`, `BRANCH`, `FEATURE_DIR` (absolute paths — use them absolute in every subsequent command). The spec ID is `basename(FEATURE_DIR)`.

2. **Preconditions.** `$FEATURE_DIR/tasks.md` and `$FEATURE_DIR/plan.md` must both exist. If either is missing, report which one and STOP — "no tasks.md — run /speckit-tasks first" / "no plan.md — run /speckit-plan first." Write nothing, dispatch nothing.

   `/speckit-analyze` leaves no dedicated artifact of its own (`artifact-layout.md` §2: its Artifact out is "`tasks.md` patch **or** reopened `plan.md`," main-thread, no separate file) — there is no marker this command can check to *confirm* analyze actually ran. Treat the D58 ordering as a documented convention, not a hard gate: proceed on `tasks.md` as it stands, and if you have concrete reason to believe `/speckit-analyze` hasn't run yet on this feature, say so plainly in your completion report rather than silently guessing either way.

3. **Resolve the workforce extension's paths** (installed vs. source — the same fallback rule `/speckit-council-triage` applies to `chairman-prompt.md`): prefer `$REPO_ROOT/.specify/extensions/workforce/`; fall back to `$REPO_ROOT/extensions/workforce/extension/` only if the installed tree isn't present. Resolve three paths and hold onto them by name for the steps below:
   - `$CATEGORIZER_PROMPT` → `.../templates/categorizer-prompt.md`
   - `$VALIDATOR_SCRIPT` → `.../scripts/validate-categorization.py` (imports its sibling `frontmatter.py`, S21 — resolve the *directory*, don't copy the validator alone; both must land in the same place Python looks, which is simply "next to the script")
   - `$WORKFORCE_CONFIG` → `.../workforce-config.yml`

4. **Read `$WORKFORCE_CONFIG`'s `model:` key** (`sonnet`, D18 — mechanical roles run Sonnet). This is a fixed, non-tunable value for this extension (unlike council's `member_count`/tier knobs), but read it from config rather than hardcode it, matching this repo's own convention ("derive it from the config, don't hardcode it" — `/speckit-council`'s own words). Note: the config also declares `general_cap: 0.20`, but that value is **documentation only** here — `$VALIDATOR_SCRIPT` enforces the cap as a hardcoded exact `1/5` integer ratio in code, never as a passed parameter; this command has no CLI flag to configure the cap through even if it wanted to.

5. **Idempotency / pre-existing state.** Check whether `$FEATURE_DIR/categorization.md` already exists **and is tracked by git** — `git ls-files --error-unmatch "$FEATURE_DIR/categorization.md"` run from `$REPO_ROOT`, exit 0 meaning a prior run already committed a valid categorization (most likely via the `after_categorize` hook, or the S28 hand-written bootstrap case). Record this as `HAD_PRIOR_VALID` (true/false) — Step 3 uses it to recover from a FAIL without ever destroying a previously-valid file. This command does not otherwise refuse to re-run: invoking `/speckit-categorize` again always dispatches a fresh categorizer session against the *current* `tasks.md`/`plan.md` and re-derives the categorization from scratch — there is no "round" concept here, unlike council. `data-model.md` §1 names the command itself (not the categorizer session) as `categorization.md`'s owner, and an owner is entitled to regenerate its own artifact.

   If `git status --short -- "$FEATURE_DIR/categorization.md"` (also from `$REPO_ROOT`) shows uncommitted local changes at this point, note it in your completion report: the fresh dispatch in Step 1 overwrites the file regardless of what this run's outcome turns out to be, so any not-yet-committed hand-edits are about to be lost either way.

6. **Note the hook, don't invoke it yet.** `after_categorize` is declared in `workforce/extension.yml` (S25) and, once the workforce extension is installed, appears as a real row under `$REPO_ROOT/.specify/extensions.yml`'s `hooks.after_categorize` (`{extension: workforce, command: speckit.git.commit, optional: false, phase: categorize, priority: 5}`). It fires **after** a successful write (Step 5), never here — this step is only reconnaissance so Step 5 isn't discovering the registry cold.

## Step 1 — Dispatch the categorizer

Read `$CATEGORIZER_PROMPT` once and substitute its one slot, `{{feature}}` → the spec ID, verbatim (its own "Slot reference" table confirms this is the *only* substitution point). Unlike council's `member-prompt.md`, no dispatch appendix is needed on top: the rendered template is already the complete, literal prompt — its own "Output format" section hardcodes the write path (`specs/{{feature}}/categorization.md`) and its own "Return value" section hardcodes the one-line status shape, so there is nothing left for you to add.

**Paths, not content.** Do not read `tasks.md`, `plan.md`, or `spec.md` into your own context, before or after dispatch — the categorizer has its own `Read`/`Bash` access and reads its inputs itself (`categorizer-prompt.md` § Inputs). Your own context stays limited to the rendered prompt text and the two status lines Steps 1 and 2 produce; you have no reason to open `categorization.md`'s content either — the session's return line and the validator's stdout already carry everything your completion report needs.

Dispatch **one `Sonnet` subagent** via the `Agent` tool, the rendered text as the literal `prompt` argument. `subagent_type: general-purpose` is sufficient — a generic file-writing, tool-using task, not a specialized persona, the same reasoning `/speckit-council` applies to its own member/deck-prep/chairman dispatches. No `isolation` is needed: this session writes exactly one file with no collision risk.

Barrier: wait for the return. Its entire reply should be one line:
```
Wrote categorization.md — <M> tasks, general <N>/<M> (cap <⌊0.20×M⌋>), source tasks.md@<short-sha>.
```
If the session returns more than this — table content, individual task classifications, editorializing about the cap — that is a broken contract on its part (`categorizer-prompt.md` § Return value: "Never paste the table... that reply line is the whole of what leaves this session"). Do not repeat, quote, or forward the excess anywhere; note the violation in one line in your completion report and continue to Step 2 regardless — the *file on disk*, not the subagent's reply, is what Step 2 actually checks.

If the subagent dispatch itself fails to return at all (crash, timeout, tool error): do not retry silently and do not fabricate a status line. Skip directly to Step 4 with `outcome: "failed"`, `artifact: null`, best-effort timestamps, `tokens: null` / `capture_method: "unavailable"`; report it; stop. There is no file to validate in Step 2.

## Step 2 — Validate (the zero-AI gate, S22)

Run `$VALIDATOR_SCRIPT` against the literal path the session just wrote:
```
python3 "$VALIDATOR_SCRIPT" "$FEATURE_DIR/categorization.md"
```
(`python3`; fall back to `python` only if `python3` isn't on `PATH`.) This is the **gate-only**, single-argument invocation form — the categorizer already wrote the real, final path per its own template, so there is no separate draft file to promote into place; the validator's own two-argument "write-on-pass" form exists for callers that use a draft path, which this command does not. Branch on the **exit code**, not on stdout/stderr prose:

- **`0`** — PASS. stdout carries one confirmation line (`... OK -- <N> task(s), general <n>/<n> (cap <c>).`). The file on disk **is** the valid `categorization.md` already — nothing further to write. Go to Step 3 (keep).
- **`1`** — FAIL. stderr carries an itemized breach report (coverage/enum/duplicate/tag violations and/or the general-cap arithmetic) — capture it verbatim for your completion report; never summarize away the specifics. An honest over-cap report is real signal about the plan, not a mistake to soften (`categorizer-prompt.md`'s own principle, applied to how you report it too). Go to Step 3 (revert).
- **`2`** — usage error (wrong argument count). This is a bug in *this command's own invocation*, not a categorization verdict (`validate-categorization.py`'s own docstring: "not a categorization verdict either way — the caller invoked this script incorrectly"). Do not treat it as an FR-004/SC-002 FAIL; report the internal error, leave whatever `categorization.md` state already existed exactly as found (this exit code means the script never opened the file), and stop.

## Step 3 — Write gate: keep on pass, revert on fail (D37, S22, FR-004/SC-002)

- **PASS (exit 0):** keep the file exactly as the categorizer wrote it. This is the moment the contract's postcondition is satisfied — "`categorization.md` exists ∧ validates ⇒ phase complete."
- **FAIL (exit 1):** the categorizer's write must not survive — the phase's postcondition is "no artifact" (FR-004) — and because the template writes directly to the real final path (Step 1), *this command* is responsible for restoring that state; the validator only guarantees it never itself creates or modifies anything, it says nothing about content someone else already put there before it ran:
  - `HAD_PRIOR_VALID` (Pre-Execution step 5) is **true** — a previously-valid, committed categorization existed before this run: restore it with `git checkout -- "$FEATURE_DIR/categorization.md"` (run from `$REPO_ROOT`), discarding only this run's bad rewrite. Never leave the tree in a worse state than before the command ran.
  - `HAD_PRIOR_VALID` is **false** — first-ever (or never-committed) attempt: remove the file (`rm "$FEATURE_DIR/categorization.md"`) so the tree genuinely has no `categorization.md`, matching what an over-cap run is expected to leave (`quickstart.md` S2: "no `categorization.md` written").
  - Either way: do **not** proceed to Step 5 — there is nothing valid to commit — and do not re-dispatch automatically. Report the breach and stop; a human fixes `tasks.md`/`plan.md` (or accepts the finding and narrows scope) and re-runs `/speckit-categorize`.

## Step 4 — Trace (one record, always — trace-schema.md §1: "no exceptions, no opt-out")

Append exactly **one** record to `$FEATURE_DIR/traces.jsonl`, after Step 2/3 resolve — its `artifact` field depends on which branch you took, so it cannot be written any earlier. Mint the `trace_id` fresh (`trc_` + a ULID/timestamp-random token, never reused).

| Field | Value |
|---|---|
| `schema_version` | `"1.0"` |
| `trace_id` | fresh, unique |
| `parent_trace_id` | `null` — `/speckit-categorize`'s own invocation is not itself a traced role (the same reasoning `/speckit-council`'s and `/speckit-council-triage`'s own fragments use: dispatched directly by the interactive main thread, so there is no in-file `trace_id` to reference) |
| `feature` | the spec ID |
| `phase` | `"categorize"` |
| `role` | `"categorizer"` |
| `agent_id` | `null` (non-null iff `role == "implementer"`, `trace-schema.md` §1) |
| `skills` | `[]` (categorize never injects skill modules) |
| `elevated_grants` | `[]` (the categorizer runs the base Sonnet toolset only — `web_search` is the skill-builder's grant alone, D60, a later phase) |
| `model` | the exact resolved id, `"claude-sonnet-5"` — never the alias `sonnet` (`$WORKFORCE_CONFIG`'s `model: sonnet` resolves to this; trace-schema.md §1: "never an alias — aliases move, a trace is a historical claim") |
| `effort` | `"medium"` — mirrors the established Sonnet-mechanical-role precedent (council's `deck-prep`/`council-member` fragments and trace-schema.md's own `implementer` example all record `medium`; D18 names no distinct effort for `categorizer` beyond "Sonnet, mechanical role") |
| `started_at` / `ended_at` / `duration_ms` | the dispatch's actual wall-clock span |
| `tokens` / `capture_method` | attempt `transcript`-based attribution from the dispatched session's transcript (D47); fall back honestly to `capture_method: "unavailable"` + `tokens: null` when attribution isn't available — never a guessed number |
| `outcome` | `"success"` iff the validator exited `0`; `"failed"` on every other branch (Step 2's `1`/`2`, and Step 1's dispatch-failure edge case) — a blunt binary, not a graded verdict; the next field is where pass/fail detail actually lives |
| `artifact` | `"specs/<feature>/categorization.md"` on `success`; `null` on `failed` (Step 3 just removed or reverted it — a path to a file no longer there is worse than no path, mirroring "a council member's opinion is chairman-only, not an artifact-out") |
| `cost_usd` | `null` (D28 — subscription-only, no per-call price) |

This is the contract's entire trace obligation for this phase ("Trace: one `categorizer` record") — do not add a second `orchestrator` fragment for `/speckit-categorize` itself; council and triage both follow the same convention for their own top-level invocations.

## Step 5 — `after_categorize` hook (reached from a Step 3 PASS only)

Re-check `$REPO_ROOT/.specify/extensions.yml` for a `hooks.after_categorize` entry — parse if present, skip silently if the file is absent or unparsable, drop any entry with `enabled: false` (the same tolerant-parse rule every speckit command in this repo uses).

- **A row is registered** (today: `{extension: workforce, command: speckit.git.commit, optional: false, phase: categorize, priority: 5}`, once the workforce extension is installed) — `optional: false` marks it mandatory/auto-invoked, never merely announced. Actually invoke it: locate the git extension's commit primitive at `$REPO_ROOT/.specify/extensions/git/scripts/commit.sh` and run
  ```
  "$REPO_ROOT/.specify/extensions/git/scripts/commit.sh" categorize "tag <M> tasks (taxonomy v0), general <N>/<M>"
  ```
  waiting for it to complete before finishing this command. Its self-heal (branch check), staging scope (`specs/<spec-id>/**` only, never `-A`), and no-op-if-clean behavior are `commit.sh`'s own contract (git extension) — rely on that contract rather than re-implementing staging logic yourself. Capture the printed commit SHA (empty stdout = no-op — nothing changed) for your completion report. If `commit.sh` is not actually present at that path despite a registered row (a partially-installed/removed git extension), report the mismatch — do **not** fall back to raw `git add`/`git commit` yourself; that would bypass the branch self-heal and staging-scope guarantees the primitive exists to provide.
- **No row is registered** (true today in *this* repo — workforce isn't installed yet, so `.specify/extensions.yml` has no `after_categorize` key at all) — this is not an error. `categorization.md` was still written and the phase is still complete: the hook is a *postcondition effect*, not a *precondition* of completion (`commands.md`'s own ordering lists the hook as a consequence of "Postconditions," not a gate on them). Note in your completion report that `categorization.md` was not committed automatically, and that installing the workforce extension (or committing by hand) makes this automatic on a future run.

## Exit states

| State | Trigger | Result |
|---|---|---|
| `success` | validator exit `0` | `categorization.md` written/kept; `after_categorize` hook honored if registered; one `categorizer` trace appended; completion report returned |
| `no-tasks` | `$FEATURE_DIR/tasks.md` missing | error reported; nothing written, no trace (no session was ever dispatched) |
| `no-plan` | `$FEATURE_DIR/plan.md` missing | error reported; nothing written, no trace |
| `cap-or-enum-fail` | validator exit `1` (general cap over 20%, and/or a coverage/closed-enum/tag breach) | no `categorization.md` (reverted to the prior valid state, or removed — Step 3); breach reported verbatim; one `categorizer` trace appended with `outcome: "failed"`, `artifact: null`; phase does not complete (FR-004/SC-001/SC-002) |
| `dispatch-fail` | the categorizer subagent never returned | on-disk state untouched by this run; one best-effort `categorizer` trace appended (`outcome: "failed"`); phase does not complete |
| `usage-error` | validator exit `2` | internal command bug, not a categorization verdict; reported and stopped; on-disk state left exactly as found |

## Completion Report

```
## Categorize Complete — <feature>
Result: PASS | FAIL (<cap breach | enum/coverage breach | dispatch failure | usage error>)
Session: 1 categorizer (Sonnet) — <its status line, or "no return" on dispatch-fail>
Validator: validate-categorization.py exit <0|1|2> — <N> task(s), general <n>/<n> (cap <c>)
Categorization: specs/<feature>/categorization.md  (kept | reverted to prior | removed | never existed)
Source binding: tasks.md@<short-sha>  (S14)
Trace: 1 categorizer record appended (outcome: success|failed)
Commit: after_categorize → <sha> | no-op (clean tree) | hook not registered (workforce not installed — commit by hand) | skipped (validation failed)
Next: /speckit-agent-assign   |   fix tasks.md/plan.md and re-run /speckit-categorize
```

## Guardrails

- Subscription auth only (D28) — never reference or set `ANTHROPIC_API_KEY`; the dispatched subagent runs on the same Claude subscription as this session.
- `tasks.md` is never edited by this command or by the categorizer session, under any outcome (D37) — not even to annotate a defect the categorizer noticed; that observation goes in `categorization.md`'s own prose instead.
- `categorization.md` is written/kept **only** on validator exit `0` — never on a hunch that "it's probably fine," never partially, never with the cap check skipped (S22).
- Never invent a `type`/`specialization` value to paper over an enum mismatch — that is the validator's FAIL to report, and a genuine taxonomy gap is a `docs/90` D-row (taxonomy §8), never a workaround made here.
- Exactly one categorizer dispatch per run. A FAIL means stop and report — never silently retry with a nudged prompt; a human decides the next step.
- Never substitute raw `git add`/`git commit` for the `after_categorize` hook's `commit.sh` primitive.

## Done When

- [ ] Feature resolved; `tasks.md` and `plan.md` preconditions checked
- [ ] Categorizer dispatched once (Sonnet, paths-not-content) and its one-line return handled, or a dispatch failure handled per Step 1's edge case
- [ ] `validate-categorization.py` run against the written path and its **exit code** — not just stdout/stderr prose — drove the branch taken
- [ ] On pass: `categorization.md` left exactly as written; on fail: reverted to the prior valid state or removed, never left half-valid
- [ ] Exactly one `categorizer` trace record appended, with `artifact` matching what is actually on disk
- [ ] `after_categorize` hook honored when registered (mandatory, invoked and awaited) or its absence noted plainly when not
- [ ] Completion report returned in the format above
