# Implement Log — speckit-ext-git (Phase 4, `/speckit-implement-parallel`)

One line per wave. Bootstrap discipline (workforce-gate note 3): the orchestrator performs
commit-before-`[X]` (atomic per S06) and by-hand wave-boundary gate-freshness at every wave,
until `002`'s own waves land those mechanisms (T010/S06, S23). Width-4 (note 2). Never edits prior lines.

Gate-freshness baseline: council `plan.md@bec819e` · workforce `tasks.md@30167a9` + `assignment.md@1ffaf6c`
(`[X]`-marks + this log's appends are expected progress, not staleness).

| ISO | wave | tasks | agents | outcome | gate-freshness |
|---|---|---|---|---|---|
| 2026-07-09T16:00Z | 1/14 | T001 | 0 (orchestrator glue) | success | ✅ baseline set |
| 2026-07-09T16:08Z | 2/14 | T002, T003, T004 | 3 (Sonnet) | success | ✅ plan/assignment intact |
| 2026-07-09T16:20Z | 3/14 | T005 | 0 (orchestrator — subagent stalled on infra watchdog @600s; authored by hand) | success | ✅ intact |
| 2026-07-09T16:32Z | 4/14 | T006 | 0 (orchestrator glue — shared .specify/extensions.yml) | success | ✅ intact; merge tested in scratch (6/6 assertions, S07 order, idempotent) |
| 2026-07-09T16:40Z | 5/14 | T007 | 0 (orchestrator glue — shared .specify/extensions.yml) | success | ✅ intact; install→uninstall round-trip BYTE-IDENTICAL to pre-install (FR-014); deregister-first (S26a) verified — Foundational phase done |
| 2026-07-09T17:05Z | 6/14 | T008, T011, T015, T016 | 4 (Sonnet, width-4) | success | ✅ intact; 3 scripts sh/dash/bash -n clean; T015 clause in both tracked skills; branch flock+mkdir-fallback (macOS no flock), cleanup ff/tag/abort sandbox-tested |
| 2026-07-09T17:30Z | 7/14 | T009, T012, T017 | 3 (Sonnet) | success | ✅ intact; commit.sh self-heal+scoped-staging (11 scenarios), gates.sh version-tagged fail-closed I/O, cleanup skill (council frontmatter, dmi:false) |
| 2026-07-09T18:00Z | 8/14 | T013, T014 | 2 (Sonnet) | success | ✅ intact; US3 integration smoke PASSED (SC-004): fresh→dirty-uncommitted-stale(S05)→SHA-mismatch-stale→missing-gates-fail-closed(S10); T014 verified decision-record.md checksum unchanged (principle I). US3 complete |
| 2026-07-09T18:15Z | 9/14 | T010 | 1 (Sonnet) | success | ✅ intact; implement-parallel now carries per-wave verify-gate (S23) + commit-before-[X] (S06), surgical. US2 complete. (Orchestrator still does both BY HAND this run — note 3.) |
| 2026-07-09T18:20Z | 10/14 | T018, T019 | 0 (orchestrator — spike experiment + disposable-doc regen) | success | ✅ intact; spike concluded ABANDON (below); graphify-context manifest corrected |
| 2026-07-10T00:10Z | 11/14 | T020 | 0 (orchestrator — shares graphify-context.md with T019, serial) | success | ✅ intact; before_specify assertions fixed (speckit-specify NOTE + graphify-context:13) → after_specify (D-R1) |
| 2026-07-10T00:30Z | 12/14 | T021 | 0 (orchestrator glue — test/run.sh on the shared list) | success | ✅ intact; harness 11/11 PASS. **S17 test earned its keep**: caught T010's per-wave edit was only in the INSTALLED copy → wiped by a graphify reinstall (graphify SHIPS speckit-implement-parallel). Fixed by moving the edit into graphify's SOURCE; regression now confirms it survives. T015 targets are stock (safe). |
| 2026-07-10T00:45Z | 13/14 | T022 | 0 (orchestrator glue — extends test/run.sh) | success | ✅ intact; before_specify drift lint added (section 4). Full harness 15/15 PASS; negative control confirms it catches reintroduced drift. Homed in test/run.sh until the D50 checker ships (D50/S29). |
| 2026-07-10T01:00Z | 14/14 | T023 | 0 (orchestrator — quickstart validation run) | success | ✅ intact; quickstart SC existence-proofs 15/15 PASS (summary below). ALL 23 TASKS [X]. |

## Quickstart SC validation — outcome (T023 · R1-S18/S29 · existence proofs, not "100%")

Ran the `quickstart.md` scenarios against the built extension in throwaway repos (this repo untouched). **15/15 checks PASS:**
- **SC-001/002/003** (Scenario 1): `commit.sh` self-heals the branch → branch name = spec ID, checked out; `spec.md` on the feature branch and **`git show main:…spec.md` fails** (base-clean); phase-tagged grammar `spec(<id>): …`/`plan(<id>): …`/`impl(<id>) wave K/N: …`; no empty commit on a clean tree (FR-004).
- **SC-004** (Scenario 2): fresh binding verifies (exit 0); an **uncommitted** edit → stale hard-block (S05 working-tree-aware); a **committed** edit → stale hard-block (SHA mismatch). Both cases caught.
- **SC-005** (Scenario 3): `cleanup.sh` → `complete/<spec-id>` tag exists; **every** phase/wave commit reachable from base tip via per-SHA `git merge-base --is-ancestor` (not a count); feature branch ref removed.
- **SC-006** (Scenario 3b): the per-wave commit lands in HEAD **before** `[X]` — an interrupt leaves a recoverable "committed-but-unmarked" state.
- **SC-007** (Scenario 4): **by construction** — no `extensions/git/**` code path invokes a model/API or writes `traces.jsonl` (verified precisely, stripping doc-comments and the `.claude/` path — not a vacuous grep).
- **SC-008** (Scenario 5): no v1 payload references `worktree` — deleting the spike leaves US1–US4 intact (firewall held).

*(One self-caught false positive along the way: the first SC-007 grep matched the scripts' own "no model / no traces.jsonl" doc-comments and the `.claude/skills` path; corrected to a comment-stripped, path-excluded invocation check — the property holds.)*

## Wave-worktree spike — outcome (T018 · FR-015 · D54 · timebox ≤2h: ran ~18:20–18:25Z, well within cap)

> The **wave-worktree spike** (distinct from `speckit-implement-parallel`'s pre-existing per-**story** `Agent isolation: worktree` guardrail — R1-S24). Hypothesis (I-4): giving each parallel implement **wave** its own `git worktree`, merging per wave, improves isolation between concurrent subagents vs the shared-tree default.

**What was tried.** A minimal empirical harness in a scratch repo: (A) two "wave tasks" in separate worktrees each committing a **disjoint** new file, merged per wave; (B) two worktree tasks both editing a **shared** file (`registry.yml`), merged per wave. Plus the lived evidence of this build's own 9 waves.

**What happened.**
- **(A) disjoint files:** worktrees merged clean — but so does the shared tree. **No isolation benefit**, since `[P]` already restricts a wave to disjoint-file sets.
- **(B) shared file:** worktree-per-wave produced a **merge conflict** on `registry.yml`. Worktrees **reintroduce** the exact shared-file collision that the DAG's "serialize shared/mutable writers as orchestrator glue" rule (taxonomy §2.1, gate-note 2) prevents *by construction*. Worktrees isolate at the **wrong layer** (per-wave filesystem) when the real isolation belongs at the **DAG layer** (don't co-schedule shared-file writers).
- **Cost:** each wave would add `git worktree add ×N` + per-wave merges + `worktree remove` + branch cleanup — real setup/disk/merge overhead.
- **This build is the existence proof:** waves 2/6/7/8 ran 2–4 concurrent Sonnet subagents in the **shared** tree with **zero** collisions, because `[P]` was disjoint-new-files only and the 3 shared/mutable files (`.specify/extensions.yml`, `test/run.sh`, `graphify-context.md`) were handled as orchestrator glue. No worktree was ever needed.

**Recommendation: ABANDON for v1 (do not adopt).** Worktree-per-wave adds cost for zero benefit on the disjoint case and is *actively worse* on the shared case (it manufactures conflicts the current design avoids). The correct isolation layer is the DAG (already in place). A null result is a **success** (D25/D54): the firewall held — no FR-001…FR-014 behavior, hook, or command references `worktree`; deleting T018 leaves US1–US4 green (SC-008). Resolves **I-4** (the original worktrees-per-wave idea) → abandon.
