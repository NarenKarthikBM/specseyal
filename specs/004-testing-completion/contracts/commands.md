# Command & Interface Contracts — 004-testing-completion

The interfaces this feature exposes: two new phase commands (testing extension), two extended git-ext primitives + two new git-ext hooks (owned-source), and the testing-extension manifest. Mechanical git changes run no session and write no trace (FR-007).

## `/speckit-complete` — the `complete` phase (testing extension)

| Aspect | Contract |
|---|---|
| Session | **main** (artifact-layout §2). The orchestrator (Opus) authors — **no new model role** (FR-001). |
| Context in | `tasks.md`, `implement.log.md`. |
| Artifact out | `completion-report.md` (and no other, principle 1) — validates against `docs/contracts/completion-report.md`. |
| Boundary | exists so `after_complete` (commit) and M5's `after_complete` D19 push have a command to hang on (FR-005/012). |
| Trace | the main-thread orchestrator record (no dispatched session). |
| Failure | a malformed/absent report leaves `complete` **incomplete** — the pipeline stops here (resumability, US1). |

## `/speckit-testing` — the `testing` phase (testing extension)

| Aspect | Contract |
|---|---|
| Session | **main dispatches ONE Sonnet `tester` subagent** — the subagent is the *separate session* (§2, context hygiene). |
| Context in (subagent) | `completion-report.md` + `spec.md` **only** — nothing else (session-boundary rule). |
| Artifact out | `testing.md` (and no other) — validates against `docs/contracts/testing-doc.md`. |
| Return | **status-only** to the main thread (SC-003) — no report/spec body re-imported. |
| Trace | exactly one record: `role: tester`, `model: claude-sonnet-5`, `agent_id: null`, `skills: []`, `elevated_grants: []` (FR-011). |
| Guard | records `executed: none`; executes no test; cites implement-time tests as **existing** evidence (FR-009). |

## `speckit.git.verify-gate workforce` — extended (I-17, owned-source)

| Aspect | Contract |
|---|---|
| Trigger | `before_implement` (gate=workforce) + per-wave by `implement-parallel`. |
| Existing behavior | fresh iff, for each bound artifact, recorded-SHA == current SHA **and** working tree clean; else non-zero (hard-block). Unchanged for `agents/assignment.md` and for the **council** gate/`plan.md`. |
| New behavior (`tasks.md` only) | on a `tasks.md` freshness failure, compute the delta recorded-SHA → working-tree and **exit 0 iff every changed line is a pure checkbox flip** (`- [ ]`→`- [x]`/`- [X]`); **non-zero (block)** on any other change or an unclassifiable/unreachable diff (fail-closed). |
| Invariants | read-only (no `gates.yml` write, no git-state change); zero-AI (git diff + regex, FR-007); silent on the happy path (exit code is the contract). |
| Coverage | reinstall + reinstall-survival regression (`extensions/git/test/run.sh` §3; S17 class; FR-013/015): bind → flip a box (pass) → edit a task line (block) → re-check after git-ext + foreign reinstall (SC-008/SC-010). |

## `speckit.git.commit` — extended (testing seam, owned-source)

| Aspect | Contract |
|---|---|
| Phase enum | add **`testing`** to `spec plan council gate tasks categorize analyze agents impl complete` (`complete` already present). |
| Grammar | `testing(<spec-id>): <summary>` (FR-006 PhaseCommit form). No-op on clean scope; staging scoped to `specs/<id>/**` (unchanged). |

## Git-ext hooks added (owned-source, `extension.yml`)

| Hook | phase | optional | Fires |
|---|---|---|---|
| `after_testing` | `testing` | false | `speckit.git.commit testing "<summary>"` → `testing(<id>)` commit (FR-012, SC-006). |
| `after_complete` | `complete` | false | `speckit.git.commit complete "<summary>"` → `complete(<id>)` commit — the path 002 deferred (FR-012). |

Both are the 002 seam pattern (D57 §9): the testing extension provides the *commands*; the git extension hooks its commit primitive onto their boundaries **in git-ext's own source**, reinstall-survival-tested (FR-013). Enforcement is prose-level in v1 (D53); a mechanical `HookExecutor` is M6.

## Testing extension manifest (`extensions/testing/extension/extension.yml`)

| Aspect | Contract |
|---|---|
| provides.commands | `speckit.complete`, `speckit.testing`. |
| Install | mirror graphify/council/workforce: extension tree → `.specify/extensions/testing/`; skills → `.claude/skills/`; hook rows merged into `.specify/extensions.yml`. |
| Uninstall | deregister-first, byte-identical round-trip (002 FR-014 pattern). |
| Config | `testing-config.yml` — `tester.model: sonnet` (D18), doc-only guard (`executed: none`). |

## Not in scope (M5)

The `after_complete` MCP push event itself (D19 → the central manager) is M5. This feature makes the completion-report body well-formed and replayable (FR-005) and provides the command boundary; it builds no MCP.
