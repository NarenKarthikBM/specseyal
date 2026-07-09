# Implementation Plan: speckit-ext-git — Per-Feature Git Lifecycle

**Branch**: `002-speckit-ext-git` | **Date**: 2026-07-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-speckit-ext-git/spec.md`

## Summary

Build `speckit-ext-git`: a Spec Kit extension that automates the per-feature git lifecycle M0/M1 ran by hand — **branch birth, phase-tagged commits, gate↔SHA binding, and completion cleanup** — as **mechanical git with zero AI**. It is packaged like `extensions/graphify/` (a **hook-registering** installer) and is almost entirely **hooks**: `after_*` phase hooks make the phase-tagged commit; the first one (`after_specify`) also **creates the feature branch** named from the spec ID; `before_*` hooks **verify gate freshness** (SHA match) and hard-block a stale approval; a **commit primitive** serves the non-stock boundaries (council/triage/gates, and per-wave in implement); and **one human command**, `/speckit-git-cleanup`, does the explicit `--no-ff` trail-preserving merge and retires the branch. The extension authors **no `specs/` artifact** and emits **no trace** — it commits artifacts other phases wrote and supplies SHA values the gate commands record.

The design's spine is **the branch and the commit graph *are* the state** (D32): no state file, ever. Branch = a git ref; gate-SHA bindings = fields inside the gate sections the pipeline already writes; the phase trail = the resumability checkpoints. Everything else follows from the spec's four ratified positions (D51) and the M0/M1 contracts.

## Technical Context

**Language/Version**: POSIX `sh` hook/command scripts + markdown skill/command definitions. No compiled code, **no model calls** (same class as `extensions/graphify/`, minus the AI). Git ≥ 2.20 is the only runtime dependency.
**Primary Dependencies**: `git` (local only — no remote/PR/push in v1); Spec Kit ≥ 0.12 `.specify/` hook system (`extensions.yml` `before_*`/`after_*`); `.specify/feature.json` (the spec-ID resolver, D45); composes with the installed graphify (`before_*`) and council (command) extensions.
**Storage**: git refs + commits, and SHA fields **inside** existing gate sections (`decision-record.md` `## Human Gate`; `assignment.md` `## Workforce Gate`, §8). No database, **no state file** (D32).
**Testing**: an end-to-end pipeline run on a real feature (SC-001); a `git log` history walk vs the phase/wave sequence (SC-003); an injected post-approval edit proving the stale-approval hard-block (SC-004); a completion-integration reachability check (SC-005); a `traces.jsonl` scan proving zero git-ext records (SC-007); the worktree spike's recorded outcome (SC-008).
**Target Platform**: Claude Code CLI now; the same hooks fire unchanged under the Agent SDK orchestrator (M6, D4).
**Project Type**: Spec Kit pipeline extension (hook layer) — sibling of `extensions/graphify/`, but hook-registering (graphify's installer variant) rather than command-only (council's).
**Performance Goals**: not latency-bound; git ops are sub-second. The governing non-goal is **cost**: `git_ext_spend = 0` — no model, no tokens, no trace (FR-007/SC-007).
**Constraints**: mechanical git only, no AI (D25); no state file (D32); branch/feature tracking decoupled (D45); local-git only (D25 scope); the build follows subscription auth (D28) + D18 model policy; all SHA bindings extend existing contract fields (D4).
**Scale/Scope**: one feature lifecycle ≈ one branch + ~8–12 phase/wave commits + 2 gate stamps + 1 cleanup merge.

## Constitution Check

*GATE: must pass before Phase 0; re-checked after design. Ref `.specify/memory/constitution.md`.*

| Principle | How this plan satisfies it | Verdict |
|---|---|---|
| **I. Artifacts are the contract** | The extension **authors no `specs/` artifact**. It *commits* artifacts other phases wrote, and *supplies* SHA values that the **gate command** (not the git ext) records into its own gate section — so no writer's artifact is mutated by a second writer. Ownership (artifact-layout §6) is unchanged. | ✅ PASS |
| **II. Context hygiene** | The extension runs **no session** — every operation is a synchronous shell hook in the phase already running. Nothing is offloaded; nothing returns opinion/context bodies. | ✅ PASS |
| **III. Resumability (NON-NEGOTIABLE)** | This extension *is* the resumability mechanism made mechanical: the phase-tagged commit is the checkpoint, the branch is the sole out-of-`specs/` state (a ref), and gate-SHA freshness **extends** "validity, not mere presence" (§3 consequence 2) — a gate section validates only if its recorded SHA matches. **No state file** (D32) — `gates.yml` (the binding home, R1-S09/S20) is a *bindings record*, not phase state; the gate section's existence still marks the phase done. | ✅ PASS |
| **IV. Observability** | The extension appends **no** `traces.jsonl` record — it is mechanical git, not an AI session, exactly like the `branch`/gate rows that "run no session and so leave no trace" (artifact-layout §2). It does not disable any *other* session's tracing. | ✅ PASS |
| **V. Subscription-only billing (NON-NEGOTIABLE)** | Zero model calls → billing is moot at runtime; the build runs on subscription auth, `ANTHROPIC_API_KEY` unset. | ✅ PASS |
| **Model policy (D18)** | Runtime has no model. The **build** uses Sonnet implementers + the Opus main thread. | ✅ PASS |
| **Autonomy & gates (D9)** | Gate-SHA binding is signer-agnostic (FR-010): an `auto`-written gate section still records the approved SHA; the freshness check runs the same. Autonomy changes *who signs*, not *what is bound*. | ✅ PASS |

**Result: PASS, no violations.** Complexity Tracking is empty. *(The one place a violation could hide — the git ext writing into a gate section it doesn't own — is designed out: the gate command records the SHA using a git-ext helper; the git ext writes no artifact. This is Chosen Approach §D and Risk R1.)*

## Chosen Approach

### A. Packaging — graphify's installer, hook-registering (mirror + merge)

`extensions/git/` with an idempotent `install.sh` that copies `extension/` → `.specify/extensions/git/`, the cleanup skill → `.claude/skills/`, **and merges its hook entries into `.specify/extensions.yml`** (the graphify variant — council's installer skipped this because council registers no hooks; this one does). `uninstall.sh` removes only what it added, including its hook entries. The `extensions.yml` merge is **append, never overwrite** — it already holds graphify's three `before_*` hooks (see `graphify-context.md`: this is the one shared/mutable file).

### B. The hook architecture (the heart) — revised at triage

Hooks carrying **hard-block or branch/commit semantics are registered `optional: false`** and the dispatch layer **auto-invokes** them — *not* `optional: true` (which the stock dispatcher only *announces*, the round's headline defect, **R1-S01**). The stock `speckit-tasks`/`speckit-implement` pre-checks gain an explicit **"if the invoked hook exits non-zero, STOP"** clause (**R1-S02** — an independent second fix: flipping the flag makes the hook *run* but still not *block*). The extension is these hooks plus a shared **commit / sha / verify-gate primitive** for boundaries with no stock hook.

| Pipeline point | Git-ext mechanism (`optional: false` unless noted) | Action |
|---|---|---|
| after `specify` | `after_specify` | **Branch birth (FR-001):** `commit.sh` **self-heals** — ensures the feature branch first (create-if-absent from `feature.json`'s spec ID, carrying the uncommitted `spec.md`), then commits `spec(<id>): …`. Folding ensure-branch into the one commit entry point kills the silent base-branch failure mode (**R1-S12**). |
| after `clarify` | `after_clarify` | commit `spec(<id>): clarify` |
| after `plan` | `after_plan` | commit `plan(<id>): …` |
| **after `analyze`** | **`after_analyze`** (**R1-S14**) | commit `analyze(<id>): …` (`speckit-analyze` exists, has working hooks, can revise `tasks.md`) |
| council / triage | commit primitive, called by those commands | `council(<id>): …` |
| council approve | **`after_council_approve` hook** (reinstall-surviving, **R1-S04/S09**) | git ext writes `plan.md @ <sha>` into **`gates.yml`**; `## Human Gate` carries a one-line reference |
| before `tasks` | `before_tasks` | **gate-verify (FR-009):** council binding fresh? Compare is **working-tree-aware** (dirty approved `plan.md` = stale, **R1-S05**) and **fails closed** on unparseable/format-drift (**R1-S10**); mismatch ⇒ hard-block until reopen (D14). |
| after `tasks` | `after_tasks` | commit `tasks(<id>): …` |
| workforce gate | git ext writes to `gates.yml` | binds `tasks.md @ <sha>` + `assignment.md @ <sha>` (§8 ref) |
| before `implement` | `before_implement` | gate-verify workforce binding (same wt-aware / fail-closed rules) ⇒ hard-block on stale |
| per wave (`implement`) | commit primitive, called by `implement-parallel` | `impl(<id>) wave K/N: …` (FR-005), **committed BEFORE the `[X]` mark** (**R1-S06** — else an interrupt can't tell "done, commit missing" from "partial, discard"; breaks principle III / SC-006); **re-verify gate freshness each wave** for `implement` (**R1-S23**). |
| after `implement` | `after_implement` | backstop the phase boundary |
| completion | **`/speckit-git-cleanup`** (human) | integrate (**`ff`-permitted**; merge-commit only if base diverged) + create the mandatory **`complete/<spec-id>` annotated tag** (the anchor) + delete branch (**R1-S27**, D52) |

**Shared primitives** (extension commands the hooks + pipeline call): `speckit.git.commit "<phase>" "<summary>"` — phase-tagged commit (FR-006), no-op if clean (FR-004), **staging scoped to `specs/NNN-feature/**` + the task's declared outputs only — never a repo-wide `git add -A`** (**R1-S11**: an unattended repo-wide add would sweep a stray `.env`/credential into permanent history); `speckit.git.sha <artifact>` — current SHA (read-only); `speckit.git.verify-gate <gate>` — recorded-vs-current compare, **working-tree-aware, fail-closed** (R1-S05/S10).

### C. Branch birth folded into the first commit (FR-001, §2 D51)

The branch is **not** a `before_specify` hook. `before_specify` fires *before* `specify` assigns the spec ID, so a branch created there would have to **duplicate** `create-new-feature.sh`'s NNN+slug logic and risk a slug mismatch with the dir. Instead, the **`after_specify` commit hook creates the branch** — by then the spec ID exists in `feature.json`, so the branch name is read, not recomputed (FR-002 guaranteed). `git checkout -b <id>` carries the still-uncommitted `spec.md` onto the new branch; the base branch never receives a `spec.md` commit → it stays clean (SC-002). This is exactly "co-incident with `specify`, before `spec.md` is committed" (artifact-layout §2, D51).

### D. Gate↔SHA binding — git-ext-owned `gates.yml` (FR-008/009; revised at triage)

The binding lives in a **git-ext-owned artifact `specs/NNN/gates.yml`** (owner ruling; **R1-S09/S20**), written by the git ext itself as a side effect of a call the gate already makes — so no gate command's artifact is co-written by a second writer (principle I stays clean; this **dissolves the D-R3 supply/record seam** that manufactured half of R1). Wiring is a **reinstall-surviving `after_council_approve` hook** (**R1-S04**), never an edit to `speckit-council-approve`'s installer-overwritten source; the `## Human Gate` section carries a one-line `gates.yml` reference. Before a gated phase, `verify-gate` reads `gates.yml` and compares recorded-vs-current **working-tree-aware** and **fail-closed** (R1-S05/S10); a stale verdict **hard-blocks** (FR-009). Re-approval routes by gate type (D51): council → D14 reopen tiers (`001`-FR-017); workforce → re-run. *The one genuinely coupled edit with no hook slot — `implement-parallel`'s per-wave commit — is named in the Risk register (R1) and covered by the reinstall-survival regression (R1-S17).*

### E. Completion cleanup — explicit; `complete/<spec-id>` tag anchor, `ff`-permitted (FR-011, **D52**)

`/speckit-git-cleanup` is **human-invoked** (never automatic — retiring a branch is consequential). It (a) integrates into the base — **fast-forward permitted**, a merge-commit only when the base diverged; (b) creates the **mandatory annotated tag `complete/<spec-id>`** at the integration commit — the immutable **completion anchor** (the D19/M5 binding target, enumerable via `git for-each-ref refs/tags/complete/*`, **independent of merge topology**); then (c) deletes the feature branch ref. A textual conflict **aborts and is surfaced** for manual resolution. *The tag replaces D51's `--no-ff` requirement (D52, R1-S27): the anchor exists unconditionally as a tag, so merge topology is free and solo/linear features stay ff-clean. M1's ff-merge grandfather is now moot (kept as history).*

### F. Composition & the per-wave seam (FR-013; revised at triage — R1-S07)

The earlier "git commit hook runs after graphify's context hook at a shared boundary" was **impossible** (every git commit hook is `after_*`; graphify is exclusively `before_*`) — **R1-S07**. The only real shared keys are `before_tasks` / `before_implement`, where git's `verify-gate` meets graphify's context-gen; there the **installer inserts `verify-gate` ahead of graphify** (so the hard-block runs before graphify's heavy context regeneration). The `priority` field is **dead code** in the stock dispatcher (a static `5`, never read) — v1 **either implements priority ordering or deletes it; no zombie schema**. `feature.json` stays the feature resolver (the git ext reads the spec ID, never couples a downstream phase to the branch name). The **one** boundary with no hook slot — `implement-parallel`'s per-wave commit — is the design's genuine seam (R1), reinstall-survival-tested (R1-S17).

### G. The wave-worktree spike (FR-015, firewalled)

A **timeboxed Phase-4 task, named the *wave-worktree spike*** — distinct from `speckit-implement-parallel`'s pre-existing per-*story* `Agent isolation: worktree` guardrail (R1-S24), so `implement.log.md`'s recorded outcome is not misattributed. Give each parallel implement *wave* its own `git worktree`, merge per wave, measure whether isolation beats the shared-tree default. Outcome (adopt-later / abandon) recorded in `implement.log.md` + an I-row regardless. **No v1 hook or command depends on it**; deleting it and re-running Scenarios 1–4 green proves the firewall (SC-008).

## Rejected Alternatives

- **`before_specify` branch creation** (stock spec-kit's model). Rejected: it fires before the spec ID exists, forcing the hook to re-derive NNN+slug and risking a mismatch with the dir. Folding branch birth into `after_specify` reads the ID from `feature.json` — zero duplication (§C). *(R1-S19: this slot is **deliberately left unused, not missed** — its own contract already tolerates the cited mismatch; D51 closed the question same-day. Two stale `before_specify` assertions still in the codebase are corrected as a task, R1-S16.)*
- **A state file / DB for phase state.** Rejected by D32 (principle III): the branch is a ref; phase state is inferred from artifacts. (`gates.yml` is a **bindings record**, not phase state — the gate section's existence still marks the phase done.)
- **The git ext co-writes the SHA into the gate section.** Rejected (principle I: a second writer mutating the gate command's artifact). Resolved at triage by a **git-ext-owned `gates.yml`** (R1-S09/S20) — the git ext owns its own artifact.
- **Squash / rebase-collapse merge at cleanup.** Rejected by D25: destroys the phase trail. (Still rejected — D52 permits `ff`/merge-commit, never squash.)
- **`--no-ff` as the mandatory anchor** (D51's original clause). **Superseded at triage (D52, R1-S27):** the anchor is a `complete/<spec-id>` **tag**, independent of merge topology, so `ff` is now permitted.
- **Descope the gate hard-block to record-and-disclose** (R1-S21). Rejected: reproduces the warn-and-override the spec rejected **by name** on 2026-07-09; adopting it needs a spec-delta re-litigating that clarification and would leave FR-009/SC-004 with nothing to hard-block-test. No such authorization exists (contrast the FR-011 delta, which the owner *did* authorize).
- **Automatic cleanup at `complete`.** Rejected at clarify: branch retirement is consequential; explicit human command.
- **Editing stock / other-extension skills' *source* to insert commits or SHA-records.** Rejected (R1-S04): their installers `rm -rf`+`cp -R` on reinstall → edits wiped, and source edits are ownership violations. Use **hooks** (`after_analyze`, `after_council_approve`); the one unavoidable coupled edit (`implement-parallel` per-wave) is reinstall-survival-tested (R1-S17).

## Project Structure

```text
extensions/git/
├── install.sh                     # idempotent; graphify variant (merges hooks into extensions.yml)
├── uninstall.sh                   # removes payload, skill, AND its hook entries
├── README.md
├── extension/
│   ├── extension.yml              # id: git; provides commit/sha/verify-gate + cleanup; registers before_*/after_* hooks
│   ├── README.md
│   ├── git-config.yml             # base_branch, commit-message grammar, merge policy (--no-ff), branch-name pattern
│   ├── commands/                  # provenance stubs (dots→hyphens on install)
│   │   ├── speckit.git.commit.md
│   │   ├── speckit.git.sha.md
│   │   ├── speckit.git.verify-gate.md
│   │   └── speckit.git.cleanup.md
│   └── scripts/                   # the actual mechanical git (POSIX sh)
│       ├── branch.sh              # ensure-branch-from-spec-id (idempotent)
│       ├── commit.sh              # phase-tagged commit; no-op if clean (FR-004/006)
│       ├── sha.sh                 # current SHA of an artifact
│       ├── verify-gate.sh         # recorded-vs-current SHA compare (FR-009)
│       └── cleanup.sh             # --no-ff merge + branch delete + conflict abort (FR-011)
└── skills/
    └── speckit-git-cleanup/SKILL.md   # the one human command (installed to .claude/skills/)

# install.sh copies extensions/git/skills/* → .claude/skills/ and merges hooks → .specify/extensions.yml
```

**Structure Decision**: sibling-of-graphify, hook-registering. The mechanical git lives in `scripts/*.sh` (testable in isolation); the one human-facing skill (`/speckit-git-cleanup`) is installed to `.claude/skills/` so a Spec Kit re-init never clobbers it. **Revised at triage:** add `scripts/gates.sh` (write/read `specs/NNN/gates.yml`, R1-S09/S20) and **`test/run.sh`** (unit tests + the reinstall-survival regression, R1-S17); the branch regex supports `feature_numbering: timestamp` mode (R1-S25); and **correcting the two stale `before_specify` assertions** (`speckit-specify/SKILL.md` closing NOTE + `graphify-context.md`:13, R1-S16) is its own task — both currently point a future implementer at the rejected design.

## Dependency / graph impact

*(Corrected at triage — **R1-S03**: the earlier "only `.specify/extensions.yml` touched, no source mutated" manifest was **false** and would have let `/speckit-tasks` omit the R1-seam work entirely.)*

New code under `extensions/git/`, **plus edits to existing files that MUST each be their own task** (enumerated so none is dropped):

1. `.specify/extensions.yml` — hook-merge (append-only; the single shared/mutable file per `graphify-context.md`).
2. `speckit-council-approve` — add the `gates.yml` SHA-record call (R1-S09) via an **`after_council_approve` hook** so the wiring is **reinstall-surviving** (**R1-S04**: council's installer `rm -rf`+`cp -R`s its skills, so editing the installed copy is silently wiped and editing council's *source tree* is an ownership violation — a hook is neither).
3. `speckit-implement-parallel` — the per-wave commit call **with commit-before-`[X]`** ordering (R1-S06). No per-wave hook vocabulary exists, so this is the one genuinely coupled edit — named as a risk (R1-S04) and covered by the reinstall-survival regression test (R1-S17).
4. `speckit-tasks` + `speckit-implement` — the stop-on-non-zero pre-check clause (R1-S02).
5. Regenerate `graphify-context.md`'s shared/mutable list to match.

The installer/`extensions.yml` blast-radius claims are **engineer assertion re-derived by reading files, not graph fact** — `graphify explain`/`path` return "No node matching" for `.sh`/`.yml` (**R1-S22**, filed **I-13**). Blast radius beyond the five above: none.

## Risk register (post-triage)

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| **R1** | **The command→primitive seam**, narrowed at triage: the council-approve SHA-record moved to a reinstall-surviving `after_council_approve` hook and the binding to `gates.yml` (R1-S04/S09/S20), so **only** `implement-parallel`'s per-wave commit remains a coupled edit (no per-wave hook vocabulary). | Low (was Med) | That one edit is reinstall-survival-**tested** (R1-S17); `after_implement` backstops the phase even if a per-wave call is missed (coarser checkpoint, never lost work). |
| **R2** | **Gate-verify mid-phase blind spot** — entry-only freshness leaves the longest, most-interruption-prone phase (`implement`) unchecked across its waves. | Low (was Med) | **Addressed (R1-S23):** re-verify gate freshness at **each wave boundary** in `implement`. |
| **R3** | **Concurrent `/speckit-specify` race** on the unlocked NNN scan; `branch.sh` create-if-absent would turn a loud collision into a *silent shared-branch merge*. | Med (sharpened) | **R1-S13:** `flock` on NNN allocation **and** loud fail on NNN-exists-with-different-slug (the case a same-slug guard misses); add a concurrency test. |
| **R4** | **`extensions.yml` merge / uninstall corrupts the shared registry** → breaks *all* phases; a dangling `optional:false` hook would hard-block every phase. | Low | Append-only merge + parse-check; **`uninstall.sh` deregisters hooks *before* payload removal or fails hard** (R1-S26a); the merge is its own budgeted task (R1-S15). *(A merge-`flock` was rejected as duplicative — R1-S26b; S13's allocation lock is a different lock and stands.)* |
| **R5** | **Enforcement is prose-level, not mechanical** (R1-S08): even corrected `optional:false`+stop-on-nonzero hooks are enforced by an LLM following prose (no `HookExecutor` implemented in-repo). | **Med — accepted** | Named honestly in the Testability claim; the falsifiable-without-a-model claim is downgraded; a mechanical `HookExecutor` is **deferred to M6 (D53)**; the D50 drift lint (R1-S29) partially compensates. |
| **R6** | **Wave-worktree spike bleeds into v1.** | Low | Firewalled by FR-015; writes only to `implement.log.md`; distinct name from the pre-existing per-story `Agent isolation: worktree` (R1-S24); removal re-runs Scenarios 1–4 green (SC-008). |

## Cost / complexity estimate

**Runtime cost: zero** — no model, no tokens, no session to trace (SC-007). Complexity is **integration, not algorithm**. The largest, most failure-prone piece is **the installer's `extensions.yml` hook-merge, budgeted as its own task (R1-S15)** — not "a short sh script": graphify needed a 193-line embedded-Python YAML merge with a 5-way interpreter fallback to merge **3 uniform** entries; git-ext merges **7 entries across 3 shapes into 5 new keys + 2 append targets**. Beyond it: ~5 short `sh` scripts (`branch/commit/sha/verify-gate/cleanup`), `gates.yml` I/O, one human skill, and a CI test harness (R1-S17).

## Testability claim (revised at triage)

**Honest scope (R1-S08):** the extension is deterministic git, but its *enforcement* is **prose-level in v1** — the stock dispatcher has no implemented `HookExecutor`, so a corrected `optional:false`+stop-on-nonzero hook is enforced by an LLM following skill prose, not by code. The "falsifiable without a model" claim is downgraded accordingly; mechanical enforcement is deferred to M6 (**D53**), and the D50 **drift lint** (R1-S29) catches the `before_specify`-style drift class mechanically meanwhile.

What **is** mechanically testable ships as a **scripted, CI-able harness `extensions/git/test/run.sh` (R1-S17)**: unit tests for `branch.sh` create-if-absent (scratch repo + fabricated `feature.json`, no model) and a **reinstall-survival regression** (reinstall council+graphify, assert the R1-seam call sites survived — the S04 class a manual quickstart never catches). `quickstart.md` is corrected to actually prove its SCs (R1-S18): the missing **SC-006 interrupt/resume** scenario added; SC-005 via per-SHA `merge-base --is-ancestor` + the `complete/<spec-id>` tag; SC-007 by-construction, not a vacuous grep; SC-008 removes the spike and re-runs. SCs are **existence proofs**, not "100%" (R1-S29). See [quickstart.md](./quickstart.md).

## Phase outputs

- **Phase 0** — [research.md](./research.md): resolved design decisions (branch-birth timing, the command→primitive seam, gate-SHA ownership, `--no-ff` anchor, worktree spike framing).
- **Phase 1** — [data-model.md](./data-model.md) (branch/commit/gate-binding entities + the commit-message grammar), [contracts/commands.md](./contracts/commands.md) (the hooks + 4 command I/O contracts), [quickstart.md](./quickstart.md) (end-to-end validation).

## Complexity Tracking

*No Constitution violations — section intentionally empty.*

## Triage revisions — Round 1 (2026-07-09)

The council's round-1 suggestions (disposed in `council/decision-record.md`) applied here — **28 accepted, 1 rejected (S21)**. By area:

- **Spec deltas (owner-authorized, applied to `spec.md` first)**: FR-011 → mandatory `complete/<spec-id>` **tag** anchor, `ff`-permitted (**D52**, S27); FR-008 → `gates.yml` binding home (S09/S20); FR-009 → working-tree-aware + fail-closed (S05/S10); FR-002 → timestamp-mode carve-out (S25); FR-015 → "wave-worktree spike" (S24); SC-002/004 softened to existence-proofs, SC-005/007/008 verification corrected (S18/S29); triage note grandfathers `002`'s own gate + disambiguates D51 timing (S28).
- **§B hook table**: `optional:false` + auto-invoke (S01); stop-on-nonzero (S02); self-healing `commit.sh` ensure-branch (S12); `after_analyze` (S14); commit-before-`[X]` + per-wave freshness (S06/S23); staging scope pinned (S11).
- **§D**: `gates.yml` via a reinstall-surviving `after_council_approve` hook (S04/S09/S20).  **§E**: tag anchor, ff-permitted (S27/D52).  **§F**: impossible-ordering fixed, verify-gate ahead of graphify, `priority` implement-or-delete (S07).
- **Dependency/graph impact**: false manifest corrected — 4 skill-edit tasks enumerated (S03); graph claims labeled assertion + **I-13** (S22).
- **Risk register**: R1 narrowed; R2 addressed (S23); R3 NNN flock + loud-fail (S13); R4 uninstall-order (S26a; merge-flock rejected S26b); R5 prose-enforcement accepted → M6 (S08/**D53**).
- **Cost** (S15), **Testability** (S08/S17/S18/S29), **Structure** (S16 stale-assertion task; `gates.sh`; `test/run.sh`), **Rejected Alternatives** (S19 doc-line; S21 descope **rejected**).

**Rejected — S21** (descope the FR-009 hard-block to record-and-disclose): reproduces the warn-and-override the spec rejected *by name* 2026-07-09; unlike the FR-011 delta, no owner authorization exists. **Partial** — S19 (doc-line accepted; `before_specify` switch rejected), S26 (uninstall-order (a) accepted; merge-flock (b) rejected).

All 6 blocking (S01–S06) are applied above; the **chairman delta-check** (`decision-record.md` → `### Chairman delta check`) re-adjudicates them against this revised plan.
