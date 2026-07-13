---
name: "speckit-testing"
description: "Dispatches exactly one Sonnet tester subagent — a separate session (context hygiene, artifact-layout.md §2) — whose context-in is completion-report.md + spec.md ONLY (FR-006/SC-003); it MAY additionally, lazily read implement.log.md on doubt as a cross-check (R1-S05, the D10 pattern). The tester writes testing.md, the sole artifact out, mapping every Success Criterion and Functional Requirement in spec.md to a verification approach grounded in the report's ### Integration status, marking each row's evidence source (report-claimed/log-verified) and any uncovered item an explicit GAP, never a fabricated covered — executed: none always, doc-only, no test runs (FR-009/010). It returns status-only to main (SC-003) — no completion-report or spec body is re-imported; main never opens either file itself, before or after dispatch. Main appends exactly one trace record (role: tester, model claude-sonnet-5, agent_id null, skills [], elevated_grants []) plus a context_in field naming the files the tester actually read (R1-S06), sourced from the tester's own status line. Runs strictly after /speckit-complete and honors the after_testing hook (git-ext's own, owned-source) when registered — an errored or empty invocation halts the phase (R1-S07). A malformed or absent testing.md leaves the testing phase incomplete (resumability rule)."
argument-hint: "None expected — /speckit-testing takes no flags; it always operates on the current feature's completion-report.md + spec.md (resolved via .specify/feature.json)"
compatibility: "Requires spec-kit .specify/ structure with a completion-report.md (from /speckit-complete, contract-validated against docs/contracts/completion-report.md) and spec.md, plus the testing extension's tester-prompt.md template + testing-config.yml — read from the installed path (.specify/extensions/testing/) when present, else from extensions/testing/extension/ source (true in this repo today, since the testing extension hasn't been installed on itself yet). Honors a registered after_testing hook (git-ext's own, extensions/git/extension/extension.yml) when present; not required for this skill to run."
metadata:
  author: narenkarthikbm
  source: "extensions/testing/extension/skills/speckit-testing/SKILL.md — speckit-ext-testing (specs/004-testing-completion), T013"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

This command takes no flags (unlike `/speckit-council`'s `--reopen`). If `$ARGUMENTS` is non-empty, note it in your completion report but let it change nothing below — `contracts/commands.md` defines no argument for `/speckit-testing` for it to mean.

## What this is

You are the **orchestrator**. `/speckit-testing` runs in the main thread and never assesses coverage itself — it dispatches **one** subagent (the `tester`; the "separate session" `artifact-layout.md` §2 assigns this phase) and acts on that session's own return. Unlike `/speckit-categorize`, there is no external validator script gating this phase at runtime: `extensions/testing/test/run.sh`'s SC/FR coverage validator is a separate, code-level, CI/dev-time check that runs against `spec.md` and fixed golden fixtures (T016) — it does not take an arbitrary path argument the way `validate-categorization.py` does, so it is not something this command invokes per-run. That is the same distinction `/speckit-complete`'s own SKILL draws for its sibling artifact: the writer's own self-check, not an independent runtime gate, is what a conforming `testing.md` rests on here. The tester **proposes** a coverage assessment; nothing in this command's own procedure certifies it beyond confirming the file exists — real certification is `test/run.sh`'s CI pass and, ultimately, the human who reads `testing.md` before signing off on the feature (`docs/contracts/testing-doc.md`'s own "Consumed by").

This phase runs **strictly after** `/speckit-complete` (`artifact-layout.md` §2): `testing.md`'s entire coverage map is grounded in `completion-report.md`'s own `### Integration status` claims (FR-008), so an absent or invalid completion report blocks this phase by construction — there is nothing to ground a verification approach in otherwise.

**The tester is a fixed role, not an assembled agent.** Unlike `/speckit-implement-parallel`'s per-task dispatches, there is no workforce roster to look up here and no `agents/assignment.md` row to read: the tester always runs as `agent_id: null`, `skills: []`, `elevated_grants: []` — the same shape every non-`implementer` role in this pipeline carries (`trace-schema.md` §7 rules 4–6). It runs on the base Sonnet toolset alone (`Read`/`Bash` to reach its inputs, `Write` for `testing.md`) — no elevated grant is ever needed or requested.

**The hard rule this command exists to enforce on you (FR-006/SC-003).** However tempting it is to open `completion-report.md` or `spec.md` yourself — to sanity-check the tester's claim, or because you already hold the completion report's content in this same conversation from having just run `/speckit-complete` moments ago — you do not, under any outcome, before or after dispatch. The tester has its own `Read`/`Bash` tool access and reads its own inputs; your job is to render its prompt, dispatch it, and act on its one-line return. The context-hygiene claim (SC-003) is true only because main never touches the bodies, not because of anything asserted in prose alone — reading either file yourself, even "just to double-check," is the exact violation the `context_in` trace field (R1-S06, Step 3) exists to make auditable after the fact. `testing.md` itself is the one artifact this phase produces and is not covered by this rule — you may confirm its bare existence (Step 2), but never its content.

## Pre-Execution

1. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root; parse `REPO_ROOT` and `FEATURE_DIR` (absolute paths — use them absolute in every subsequent command). The spec ID is `basename(FEATURE_DIR)`.

2. **Require `completion-report.md` + `spec.md` — existence only.** Both `$FEATURE_DIR/completion-report.md` and `$FEATURE_DIR/spec.md` must exist: a plain `[ -f ... ]` check, never a content read (content is the tester's job alone, Step 1). If either is missing: ERROR — "no completion-report.md — run /speckit-complete first" (or the `spec.md` equivalent, though its absence this late in the pipeline would itself be a far deeper problem) — and stop. Write nothing, dispatch nothing. This is the concrete form of the `spec.md` Edge Case: "`completion-report.md` missing or invalid → the testing phase cannot run... the pipeline stops at `complete` until a conforming report exists (no fabricated input)."

3. **Resolve the testing extension's paths** (installed vs. source — the same fallback rule `/speckit-categorize` applies to `categorizer-prompt.md`): prefer `$REPO_ROOT/.specify/extensions/testing/`; fall back to `$REPO_ROOT/extensions/testing/extension/` only if the installed tree isn't present. Resolve two paths and hold onto them by name for the steps below:
   - `$TESTER_PROMPT` → `.../templates/tester-prompt.md` — the Sonnet tester's separate-session prompt (authored elsewhere, T014; treat its content as authoritative over anything paraphrased below — this skill only fixes the *dispatch*, never the tester's internal verification-approach logic).
   - `$TESTING_CONFIG` → `.../testing-config.yml`.

   If `$TESTER_PROMPT` does not exist under either path, STOP — "no tester-prompt.md found (installed or source) — the testing extension is incompletely built" — and report it. Never fabricate a prompt inline in its place; that would silently invent the very content this skill is scoped not to author.

4. **Read `$TESTING_CONFIG`'s `tester.model:` key** (`sonnet`, D18 — mechanical/generative roles run Sonnet, never Opus/Haiku). This is a fixed, non-tunable value for this extension, but read it from config rather than hardcode it, matching this repo's own convention (`/speckit-categorize`'s own words: "derive it from the config, don't hardcode it"). It resolves to the exact model id `claude-sonnet-5` for the trace (Step 3) — never the alias.

5. **Idempotency.** `/speckit-testing`, like its sibling `/speckit-complete`, has no "already done" short-circuit: every invocation dispatches a fresh tester, and a successful write overwrites whatever `testing.md` was there before. A prior valid `testing.md` already existing is not an error — note it plainly if you have reason to believe nothing has changed since `completion-report.md` was last written. This matters concretely only in the failure path (see "Failure and resumability" below): a prior *valid* file must never be clobbered by *this* run's bad draft.

6. **Note the hook, don't invoke it yet.** `after_testing` is declared in git-ext's own `extension.yml` (owned-source, D57 §9, `plan.md` §1.4) and, once registered, appears as a row under `$REPO_ROOT/.specify/extensions.yml`'s `hooks.after_testing` (`{extension: git, command: speckit.git.commit, optional: false, phase: testing, priority: 5}`). It fires **after** a successful write (Step 4), never here.

## Step 1 — Dispatch the tester (paths, not content — the session-boundary rule, FR-006/SC-003)

Read `$TESTER_PROMPT` once and substitute its slot(s) — at minimum `{{feature}}` → the spec ID (mirroring `categorizer-prompt.md`'s own single-substitution-point convention; `tester-prompt.md`'s own "Slot reference," if it defines more, is authoritative over this description). **Do not read `completion-report.md`, `spec.md`, or any other project file into your own context, before or after dispatch, under any outcome** — the tester has its own `Read`/`Bash` tool access and reads its two inputs itself. This is the literal mechanism behind FR-006/SC-003: the session-boundary claim is true only because main never touches the bodies, not because of anything stated in prose alone.

Dispatch **one `Sonnet` subagent** via the `Agent` tool, the rendered text as the literal `prompt` argument. `subagent_type: general-purpose` is sufficient — a generic file-reading, file-writing task, not a specialized persona (the same reasoning `/speckit-categorize` and `/speckit-council` apply to their own member/categorizer dispatches). No `isolation` is needed: this session reads two files (optionally a third, per R1-S05) and writes exactly one, with no collision risk.

Barrier: wait for the return. Its entire reply should be one line, in this shape:
```
Wrote testing.md — <N> row(s) (<C> covered, <G> GAP), executed: none, self-check: clean, context_in: completion-report.md, spec.md[, implement.log.md].
```
or, on a self-detected problem:
```
Self-check FAILED — <one-line reason>. testing.md not written (or left as found).
```
If the session returns more than this — coverage-map rows, quoted prose from `completion-report.md`/`spec.md`, editorializing about a gap — that is a broken contract on its part, the same shape `categorizer-prompt.md` names for its own session ("never paste the table... that reply line is the whole of what leaves this session"). Do not repeat, quote, or forward the excess anywhere — not into your own completion report, not into the trace. Note the violation in one line and continue to Step 2 regardless, basing what you report there on the file's on-disk existence and the status line's own structured claims, never on the excess prose.

If the subagent dispatch itself fails to return at all (crash, timeout, tool error): do not retry silently and do not fabricate a status line. Skip directly to Step 3 with `outcome: "failed"`, `artifact: null`, best-effort timestamps, `tokens: null` / `capture_method: "unavailable"`, and `context_in: []` (nothing was confirmed read); report it; stop — do not run Step 2 or Step 4.

## Step 2 — Confirm the artifact landed (existence only — never content)

Check `[ -f "$FEATURE_DIR/testing.md" ]`. This is the **only** check main performs against the file itself — main never opens it, greps its frontmatter, or counts its rows; doing so would re-import exactly the body SC-003 exists to keep out. As noted in "What this is," there is no independent runtime validator to fall back on here; be honest that this step confirms presence, not conformance.

- **File present, and the status line claimed a clean self-check** → `outcome: "success"`; proceed to Step 3.
- **File present, but the status line itself reported `Self-check FAILED`** → the tester recognized a problem before finishing. Treat as failure — never silently promote this to success just because a file happens to exist on disk.
- **File absent** (the dispatch returned something, but no `testing.md` landed) → treat as failure.

Either failure branch: `outcome: "failed"`, `artifact: null`; proceed to Step 3, then to "Failure and resumability" below — never to Step 4.

## Step 3 — Trace (exactly one record, `role: "tester"` — R1-S06)

Append exactly **one** record to `$FEATURE_DIR/traces.jsonl`, after Step 2 resolves (its `artifact`/`outcome`/`context_in` fields depend on which branch was taken). Mint `trace_id` fresh (`trc_` + a ULID/timestamp-random token, never reused).

| Field | Value |
|---|---|
| `schema_version` | `"1.0"` |
| `trace_id` | fresh, unique |
| `parent_trace_id` | `null` — `/speckit-testing`'s own invocation is not itself a traced role (the same reasoning `/speckit-categorize`'s and `/speckit-complete`'s own fragments use: dispatched/authored directly by the interactive main thread, so there is no in-file `trace_id` for it to reference) |
| `feature` | the spec ID |
| `phase` | `"testing"` |
| `role` | `"tester"` (`trace-schema.md` §2: `tester \| testing \| sonnet`) |
| `agent_id` | `null` — the tester is a **fixed role**, never a workforce-assembled agent; there is no roster row to look up (non-null iff `role == "implementer"`, `trace-schema.md` §7 rule 4 — this is not that role) |
| `skills` | `[]` (rule 5: non-empty only for `implementer`) |
| `elevated_grants` | `[]` (rule 6, same reasoning — the tester runs the base Sonnet toolset only) |
| `model` | `"claude-sonnet-5"` — the exact id resolved from `$TESTING_CONFIG`'s `tester.model: sonnet` (Pre-Execution step 4), never the alias `sonnet` (D18; `trace-schema.md` §1: "aliases move, a trace is a historical claim") |
| `effort` | `"medium"` — mirrors the established Sonnet-mechanical-role precedent (`categorizer`/`implementer` both record `medium`) unless this dispatch actually ran at a different effort |
| `started_at` / `ended_at` / `duration_ms` | this dispatch's actual wall-clock span (the `Agent`-tool call's own start/return) |
| `tokens` / `capture_method` | attempt `transcript`-based attribution from the dispatched session's transcript (D47); fall back honestly to `capture_method: "unavailable"` + `tokens: null` when attribution isn't available — never a guessed number |
| `outcome` | `"success"` iff Step 2 resolved to success; `"failed"` on every other branch (a self-reported self-check failure, a missing file, or a dispatch that never returned) |
| `artifact` | `"specs/<feature>/testing.md"` on `success`; `null` on `failed` |
| `context_in` | an array of repo-relative paths naming the files the tester **actually read** this session — always `["specs/<feature>/completion-report.md", "specs/<feature>/spec.md"]`, **plus** `"specs/<feature>/implement.log.md"` iff the tester's own status line reported exercising the R1-S05 lazy cross-check; `[]` on a dispatch that never returned (Step 1). Copied **verbatim** from the tester's status line — main never independently re-derives this list, since verifying it directly would require opening the files itself, the exact thing this field exists to avoid needing. |
| `cost_usd` | `null` (D28 — subscription-only, no per-call price) |

**On `context_in` (R1-S06).** This field is **new to this record** (`plan.md` §1.3; `decision-record.md`: "the `tester` trace gains a `context_in` field... so an SC-003 violation is detectable after the fact"), in the D43 assembly-provenance spirit applied to context rather than tooling. `docs/contracts/trace-schema.md` (v1.2, as it stands) does not yet list `context_in` in its own §1 field table or §7 validation rules — this is the R1-S06-ratified, tester-role-scoped addition that `docs/contracts/testing-doc.md` §7 and `contracts/commands.md`'s own Trace row already cite by that name. Treat it as this record's own obligation regardless; a future `trace-schema.md` revision should fold it into the general schema rather than leave it a one-role exception documented only here and in this feature's own contracts. The table above is exposition order; the literal JSON key order is `templates/trace-fragment.md`'s (T015) to fix — this skill's own recommendation, consistent with the D43 clustering, is to place `context_in` immediately after `elevated_grants` (both describe this dispatch's scope) and before `model`.

This is the contract's entire trace obligation for this phase ("Trace: exactly one record," `contracts/commands.md`) — do not add a second `orchestrator` fragment for `/speckit-testing` itself, the same convention `/speckit-categorize` and `/speckit-complete` hold for their own top-level invocations.

## Step 4 — Honor `after_testing` if registered (R1-S07)

Check `$REPO_ROOT/.specify/extensions.yml` for a `hooks.after_testing` entry — parse if present, skip silently if the file is absent or unparsable, drop any entry with `enabled: false` (the tolerant-parse rule every speckit command here uses). This step only runs after Step 2 resolved `outcome: "success"` — never on a failed or absent `testing.md` (mirroring `/speckit-complete`'s own "never fire the hook against a malformed/absent report").

- **A row is registered** (expected shape once git-ext carries it: `{extension: git, command: speckit.git.commit, optional: false, phase: testing, priority: 5}` — git-ext's **own**, owned-source hook, `plan.md` §1.4) — invoke it: locate the git extension's commit primitive at `$REPO_ROOT/.specify/extensions/git/scripts/commit.sh` and run
  ```
  "$REPO_ROOT/.specify/extensions/git/scripts/commit.sh" testing "<one-line summary, e.g. '27 row(s), 1 GAP, executed: none'>"
  ```
  waiting for it to finish before ending this command. Rely on `commit.sh`'s own contract (staging scope, no-op-if-clean, the FR-006 `testing(<id>): <summary>` phase-tag grammar) rather than reimplementing it.

  **An errored or empty invocation halts the phase (R1-S07, `plan.md` §1.4).** If `commit.sh` exits non-zero, or is registered but not actually present at that path despite the row (a partially-installed/removed git extension), do **not** report the `testing` phase as complete — report the hook failure plainly and stop. Do not fall back to a raw `git add`/`git commit` (that would bypass the primitive's staging-scope and no-op guarantees), and do not paper over the failure by treating `testing.md`'s own successful write as sufficient on its own — SC-006/SC-009 both need the commit to have actually landed, symmetric with `complete`'s own "a malformed/absent report leaves `complete` incomplete" guarantee.
- **No row is registered** (true before git-ext is edited/reinstalled with this hook, or if git-ext isn't installed at all) — this is **not** an error. The `testing` phase is still complete: `testing.md` exists (Step 2), which is the postcondition (`artifact-layout.md` §3) — the hook is a *consequence* of completion, not a *precondition* of it. Note plainly in your completion report that no commit fired automatically and why.

## Failure and resumability (`spec.md` Edge Cases, `artifact-layout.md` §3)

A malformed or absent `testing.md` leaves the `testing` phase **incomplete** — full stop. Concretely:

- If Step 2 resolves to failure (the tester's status line reported a self-check failure, the dispatch never returned, or no file landed at all), do not report the `testing` phase as complete under any framing. If a prior valid `testing.md` already existed on disk before this run started (Pre-Execution step 5), restore it with `git checkout -- "$FEATURE_DIR/testing.md"` (run from `$REPO_ROOT`) so this run's bad draft never survives over a previously-committed good one; if no prior valid file existed, leave whatever the tester's own session produced (or nothing, if it wrote nothing) — never fabricate a conforming-looking file yourself to paper over the gap. Report the specific failure and stop; a later invocation of `/speckit-testing` re-dispatches a fresh tester from scratch — resumability means the next run just repeats the walk, not that this run needs a special recovery path.
- Do **not** run Step 4 (the `after_testing` hook) against a failed or absent `testing.md` — the hook is downstream of a *successful* write, exactly as `/speckit-complete` never fires `after_complete` on a malformed report.
- **This is a structural rule, not a content one.** A `testing.md` that honestly surfaces several spec items as `GAP` still makes the `testing` phase *complete* in the resumability sense, provided the file itself validates against `docs/contracts/testing-doc.md` — the phase's postcondition is "the artifact exists and validates," not "the news is good." Per Step 2, the only failure this command can itself *detect* is an absent file or the tester's own self-reported self-check failure; anything subtler (a fabricated `covered`, a miscounted row) is `test/run.sh`'s and the human reader's job, not this command's — never imply this step verified more than that.
- Never treat `testing.md`'s mere existence as sufficient to call the phase complete if the tester's own status line said otherwise (Step 2) — a file on disk is not the same claim as a file the tester itself vouches for.

## Completion Report

```
## Testing Complete — <feature>
Doc: specs/<feature>/testing.md  (written | self-check failed, not written — prior restored | not written, none existed)
Tester: 1 Sonnet session — <its status line, or "no return" on dispatch failure>
Coverage: <N> row(s) — <C> covered, <G> GAP  (per the tester's own self-report; not independently re-derived)
Context-in: completion-report.md, spec.md[, implement.log.md]  (session-boundary held — no body re-imported into main)
Trace: 1 tester record appended (outcome: success|failed), context_in recorded
Commit: after_testing → <sha>  |  no-op (clean tree)  |  hook not registered (note why)  |  HALTED — hook errored (R1-S07)  |  skipped (doc not written)
Next: hand off testing.md for human sign-off  |  fix the underlying issue and re-run /speckit-testing
```

## Guardrails

- Subscription auth only (D28) — never reference or set `ANTHROPIC_API_KEY`; the dispatched tester runs on the same Claude subscription as this session.
- Main never reads `completion-report.md` or `spec.md` itself, before or after dispatch, under any outcome — paths, not content (FR-006/SC-003). The tester's own `Read`/`Bash` access is what actually reads them.
- Exactly one artifact out, ever: `testing.md`. Never a second file, never a state file (`artifact-layout.md` §3: "there is no state file, and adding one is forbidden").
- Exactly one tester dispatch per run. A failure means stop and report — never silently retry with a nudged prompt; a human decides the next step.
- Never fabricate, embellish, or "helpfully" summarize the tester's own status line — if it returns more than one line, note the violation, never repeat, quote, or forward the excess.
- `context_in` is always sourced verbatim from the tester's own self-report — never independently re-derived by opening the files main was told not to touch.
- Never substitute a raw `git add`/`git commit` for the `after_testing` hook's `commit.sh` primitive.
- An errored or empty `after_testing` invocation halts the phase (R1-S07) — never report `testing` as complete on a failed hook fire.
- Never leave the tree worse than found: on a self-check failure, restore or protect a prior valid `testing.md` rather than leaving something that looks plausible but doesn't conform.

## Done When

- [ ] Feature resolved; `completion-report.md` + `spec.md` existence confirmed (never their content read by main)
- [ ] `$TESTER_PROMPT` resolved (installed or source) and rendered with its slot(s); exactly one Sonnet tester subagent dispatched via the `Agent` tool
- [ ] The tester's one-line status return handled; any excess content noted as a contract violation, never repeated or forwarded
- [ ] `testing.md`'s existence confirmed (never its content read) — no runtime validator invoked (that is `test/run.sh`'s separate CI job)
- [ ] Exactly one `role: "tester"` trace record appended: `agent_id: null`, `skills: []`, `elevated_grants: []`, `model: "claude-sonnet-5"`, and a `context_in` array sourced verbatim from the tester's own report (R1-S06)
- [ ] `after_testing` hook honored when registered (halts the phase on an errored/empty invocation per R1-S07), or its absence noted plainly when not
- [ ] On any failure: nothing claims completeness that isn't true; a prior valid `testing.md` is protected, never silently clobbered by a bad draft
- [ ] Completion reported in the format above
