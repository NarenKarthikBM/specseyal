# Decision Record — 002-speckit-ext-git

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).

## Metadata

| Field | Value |
|---|---|
| feature | `002-speckit-ext-git` |
| spec-id | `002-speckit-ext-git` |
| profile | `gates.council=human, gates.workforce=human` (no `profile.yaml` — default, D33) |
| rounds-run | 1 |
| schema-version | `1.0` |

---

## Round 1 — 2026-07-09T13:05:45Z

**Verdict:** 6 blocking · 12 strong · 11 consider
**Deck reviewed:** `council/defense-deck/technical.md` @ `8de488a`
**Plan reviewed:** `plan.md` @ `4b63083`

> Owner preamble (this gate): (i) gate↔SHA binding home = git-ext-owned `specs/NNN/gates.yml`; (ii) **D52** authorized — supersedes D51's `--no-ff` clause only: `ff`-permitted, completion anchor = mandatory `complete/<spec-id>` tag. Plan revision committed @ `bec819e`; spec delta @ `0dbb715`.

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | blocking | Hard-block hooks are `optional:true` (only announced, never auto-invoked) → warn-and-override the spec rejected | accepted | The round's convergent headline (5 sources); a real FR-009 defect | `plan.md §B` @ `bec819e` |
| R1-S02 | blocking | No stop-on-nonzero clause in `speckit-tasks`/`speckit-implement` pre-checks | accepted | Independent of S01; kept a distinct task so neither is dropped as "already covered" | `plan.md §B/§Dep` @ `bec819e` |
| R1-S03 | blocking | False "only `extensions.yml` touched" manifest → `/speckit-tasks` could omit the seam | accepted | Verifiably false; enumerated all 5 existing-file edits as tasks | `plan.md §Dependency` @ `bec819e` |
| R1-S04 | blocking | R1-seam edits live in council/graphify skills their installers overwrite on reinstall | accepted | Reinstall-surviving `after_council_approve` hook; no source-tree edits | `plan.md §D` @ `bec819e` |
| R1-S05 | blocking | Gate-verify compared committed-HEAD only → uncommitted hand-edit false-passes | accepted | `verify-gate` now working-tree-aware; the exact threat FR-009 exists to catch | `plan.md §B` + `spec.md FR-009` @ `bec819e`/`0dbb715` |
| R1-S06 | blocking | `implement-parallel` marks `[X]` before the per-wave commit → interrupt breaks resumability | accepted | Commit-before-`[X]`; principle III / SC-006 | `plan.md §B/§Dep` @ `bec819e` |
| R1-S07 | strong | Impossible ordering claim (git `after_*` can't run after graphify `before_*`); `priority` dead code | accepted | §F rewritten; installer inserts verify-gate ahead of graphify; priority implement-or-delete | `plan.md §F` @ `bec819e` |
| R1-S08 | strong | No code-level hook enforcement (`HookExecutor` unimplemented) — enforcement is prose-only | accepted (scoped) | Named honestly as prose-level v1; mechanical enforcement deferred to M6 (**D53**); drift lint compensates | `plan.md §Testability` + `D53` @ `bec819e` |
| R1-S09 | strong | `## Human Gate` has no `@ <sha>` field; reusing R4's is a different command/time | accepted | Binding homed in git-ext-owned `gates.yml` (owner ruling), gate section references it | `spec.md FR-008` + `plan.md §D` @ `0dbb715`/`bec819e` |
| R1-S10 | strong | `verify-gate` behavior on unparseable gate data unspecified (fail-open risk) | accepted | Fail-closed + format-version guard as FR-009 acceptance criteria | `spec.md FR-009` @ `0dbb715` |
| R1-S11 | strong | `commit.sh` staging scope ambiguous — a repo-wide `git add -A` could sweep secrets in | accepted | Scoped to `specs/NNN/**` + declared task outputs; repo-wide add banned | `plan.md §B` @ `bec819e` |
| R1-S12 | strong | `after_specify` is the only brancher — if it fails, commits land silently on base | accepted | Idempotent ensure-branch folded into `commit.sh` (one self-healing entry point) | `plan.md §B` @ `bec819e` |
| R1-S13 | strong | Concurrent `/speckit-specify` races the unlocked NNN scan; create-if-absent → silent shared branch | accepted (full) | `flock` on NNN allocation AND loud fail on NNN-exists-different-slug (owner: full) | `plan.md §Risk R3` @ `bec819e` |
| R1-S14 | strong | Missing `after_analyze` hook (analyze exists, can revise `tasks.md`) | accepted | Added; documented why categorize/agent-assign/complete omitted (no skill until M3/M4) | `plan.md §B` @ `bec819e` |
| R1-S15 | strong | Installer hook-merge is the largest/most-failure-prone file, hidden in "~5 short scripts" | accepted | Budgeted as its own task (7 entries, 3 shapes, 5 keys + 2 append targets) | `plan.md §Cost` @ `bec819e` |
| R1-S16 | strong | Two stale `before_specify` assertions contradict the ratified `after_specify` design | accepted | Correcting both (`speckit-specify` NOTE + `graphify-context.md`:13) is its own task | `plan.md §Structure` @ `bec819e` |
| R1-S17 | strong | No scripted test harness for a "deterministic, zero-AI" extension | accepted | `extensions/git/test/run.sh`: `branch.sh` units + reinstall-survival regression (keeps S04 fixed) | `plan.md §Testability` @ `bec819e` |
| R1-S18 | strong | Quickstart doesn't prove its SCs (missing SC-006; vacuous SC-007; wrong SC-005/008 methods) | accepted | SC-006 interrupt/resume added; SC-005 per-SHA `merge-base`; SC-007 by-construction; SC-008 remove+rerun | `quickstart.md` + `spec.md SC` @ `bec819e`/`0dbb715` |
| R1-S19 | consider | Add a Rejected-Alternatives line: `before_specify` deliberately unused (not missed) | accepted | Doc-line added. **The floated `before_specify` *switch* is rejected** — D51 closed it same-day; it resurrects the NNN+slug duplication the plan correctly rejected | `plan.md §Rejected` @ `bec819e` |
| R1-S20 | consider | Decouple gate-SHA from a foreign artifact (git-ext-owned bindings, or a principle-I exception) | accepted | Resolved by owner preamble (i): git-ext-owned `gates.yml` dissolves the D-R3 supply/record seam | `spec.md FR-008` + `plan.md §D` @ `0dbb715`/`bec819e` |
| R1-S21 | consider | Descope gate-SHA to record-and-disclose only; defer the enforced hard-block | **rejected** | Reproduces the warn-and-override the spec rejected **by name** at the 2026-07-09 spec adjudication; the hard-block is ratified spec. The FR-011 delta is owner-authorized; **no equivalent authorization exists or is sought** for descoping FR-009. Two peers rebutted it as needing a spec-delta re-litigating that clarification, not a plan simplification. | — |
| R1-S22 | consider | Label installer/`extensions.yml` blast-radius claims as engineer assertion (graph has no `.sh`/`.yml` nodes) | accepted | Labeled in §Dependency; filed **I-13** (graphify coverage for non-code artifacts) | `plan.md §Dependency` + `I-13` @ `bec819e` |
| R1-S23 | consider | Re-verify gate freshness at each wave boundary for `implement` (R2's widest blind spot) | accepted | Added to §B per-wave; R2 downgraded | `plan.md §B/§Risk R2` @ `bec819e` |
| R1-S24 | consider | Distinct name for the spike vs the pre-existing per-story `Agent isolation: worktree` | accepted | Renamed **wave-worktree spike** (FR-015, §G) so `implement.log.md` attribution stays clean | `spec.md FR-015` + `plan.md §G` @ `0dbb715`/`bec819e` |
| R1-S25 | consider | FR-002 branch regex needs a carve-out for `feature_numbering: timestamp` mode | accepted | Added `YYYYMMDD-HHMMSS-slug` carve-out to FR-002 + data-model | `spec.md FR-002` @ `0dbb715` |
| R1-S26 | consider | (a) uninstall deregisters hooks before payload removal; (b) merge-`flock` | accepted (a) | (a) accepted — else `extensions.yml` references deleted commands / dangling hard-block hook. **(b) rejected** — merge-`flock` duplicative of orchestrator-serialized discipline; note S13's *allocation* flock is a different lock and stands | `plan.md §Risk R4` @ `bec819e` |
| R1-S27 | consider | `complete/<spec-id>` tag as the M5 anchor instead of hard-locking `no-ff` | accepted (as replacement) | Owner preamble (ii): the mandatory tag **replaces** `--no-ff` (D51→**D52**), `ff` permitted; adopted beyond member C's "optional" framing — mandatory | `spec.md FR-011` + `D52` @ `0dbb715` |
| R1-S28 | consider | Grandfather `002`'s own `## Human Gate` unbound; disambiguate D51's "at ID assignment" wording | accepted | Triage note added: `002`'s own gate is pre-mechanism (like M1's ff); `after_specify` fires at *end* of specify | `spec.md` (triage note) @ `0dbb715` |
| R1-S29 | consider | Soften SC-002/004 "100%" to existence-proofs; copy-pasteable command; grep the `optional:` value; wire drift lint into the D50 checker | accepted | SCs softened; Scenario 2 command added; drift lint wired to D50 (compensates S08) | `spec.md SC` + `plan.md §Testability` @ `0dbb715`/`bec819e` |

### Chairman delta check — 2026-07-09T13:02:22Z

Re-adjudication of the six prior `blocking` rows (R1-S01…R1-S06) against the triage-revised `plan.md` (commit `bec819e`) — re-adjudication only, no re-review: opinions were not reopened and no new findings were raised.

- R1-S01 — RESOLVED — §B registers every hard-block/branch/commit hook `optional: false` with the dispatch layer auto-invoking it, retiring the announce-only `optional: true`.
- R1-S02 — RESOLVED — the explicit "if the invoked hook exits non-zero, STOP" clause is added to `speckit-tasks`/`speckit-implement` pre-checks as its own task, distinct from S01's flag flip.
- R1-S03 — RESOLVED — the false "only `extensions.yml` touched" manifest is retracted and all required existing-file edits are enumerated as tasks, so `/speckit-tasks` cannot omit the seam.
- R1-S04 — RESOLVED — the SHA-record moves to a reinstall-surviving `after_council_approve` hook; the sole remaining coupled edit (`implement-parallel` per-wave) is in Risk R1 and covered by the reinstall-survival regression.
- R1-S05 — RESOLVED — `verify-gate` is working-tree-aware (a dirty approved `plan.md` reads stale) and fail-closed, so an uncommitted hand-edit hard-blocks.
- R1-S06 — RESOLVED — the per-wave commit lands BEFORE the `[X]` mark, closing the interrupt window (principle III / SC-006).

**Delta verdict:** all clear, ready for the gate. All six prior blocking items resolved by the single authorized revision (FR-010); no new findings raised, so the plan proceeds to the human gate with no residual blocking risk.

---

## Human Gate — 2026-07-09T13:15:41Z

| Field | Value |
|---|---|
| reviewer | Naren Karthik B M |
| decision | `approved` |
| reviewed | `defense-deck/overview.md`, `round-1/suggestions.md`, this record |

**Notes:** none.

**Overrides:** none.

---

## Carried Constraints

> Accepted suggestions that constrain task generation. `/speckit-tasks` reads this section and nothing else from this file.

- `R1-S01` — hard-block / branch-commit hooks MUST be registered `optional: false` with auto-invoke (its own task, distinct from S02).
- `R1-S02` — `speckit-tasks`/`speckit-implement` pre-checks MUST abort on a non-zero hook exit (its own task).
- `R1-S03` — the **five** existing-file edits are each their own task: `extensions.yml` merge; `after_council_approve` hook (council); per-wave commit (`implement-parallel`); stop-on-nonzero (`speckit-tasks` + `speckit-implement`); regenerate `graphify-context.md`.
- `R1-S04`/`S09`/`S20` — gate↔SHA binding is a **git-ext-owned `gates.yml`**, written via a reinstall-surviving `after_council_approve` hook; no other extension's source is edited.
- `R1-S05`/`S10` — `verify-gate` MUST be working-tree-aware and fail closed (FR-009 acceptance criteria).
- `R1-S06` — the per-wave commit MUST precede the `[X]` mark (or be atomic with it).
- `R1-S07` — installer MUST insert `verify-gate` ahead of graphify on `before_tasks`/`before_implement`; `priority` is implemented or deleted.
- `R1-S11` — `commit.sh` staging is scoped to `specs/NNN/**` + declared outputs; never repo-wide.
- `R1-S12` — `commit.sh` self-heals (ensure-branch folded in).
- `R1-S13` — NNN allocation MUST `flock` and loud-fail on NNN-exists-different-slug; add a concurrency test.
- `R1-S14` — add an `after_analyze` commit hook.
- `R1-S15` — the `extensions.yml` hook-merge is its own budgeted task.
- `R1-S16` — correcting the two stale `before_specify` assertions is its own task.
- `R1-S17` — ship `extensions/git/test/run.sh` (branch.sh units + reinstall-survival regression).
- `R1-S23` — re-verify gate freshness at each wave boundary in `implement`.
- `R1-S24` — the spike is the **wave-worktree spike**; distinct name in `implement.log.md`.
- `R1-S25` — branch regex supports `feature_numbering: timestamp`.
- `R1-S26a` — `uninstall.sh` deregisters hooks before payload removal (or fails hard).
- `R1-S27` — cleanup creates the mandatory annotated tag `complete/<spec-id>` (D52); `ff` permitted.
- `R1-S18`/`S29` — quickstart proves its SCs (SC-006 interrupt/resume; per-SHA `merge-base`; by-construction SC-007; remove+rerun SC-008); SCs are existence-proofs; wire the `before_specify` drift lint into the D50 conformance checker.
- `R1-S08` — enforcement is prose-level in v1; mechanical `HookExecutor` deferred to M6 (D53) — tasks MUST NOT claim mechanical hook enforcement.
