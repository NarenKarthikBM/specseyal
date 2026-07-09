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
| **III. Resumability (NON-NEGOTIABLE)** | This extension *is* the resumability mechanism made mechanical: the phase-tagged commit is the checkpoint, the branch is the sole out-of-`specs/` state (a ref), and gate-SHA freshness **extends** "validity, not mere presence" (§3 consequence 2) — a gate section validates only if its recorded SHA matches. **No state file** (D32). | ✅ PASS |
| **IV. Observability** | The extension appends **no** `traces.jsonl` record — it is mechanical git, not an AI session, exactly like the `branch`/gate rows that "run no session and so leave no trace" (artifact-layout §2). It does not disable any *other* session's tracing. | ✅ PASS |
| **V. Subscription-only billing (NON-NEGOTIABLE)** | Zero model calls → billing is moot at runtime; the build runs on subscription auth, `ANTHROPIC_API_KEY` unset. | ✅ PASS |
| **Model policy (D18)** | Runtime has no model. The **build** uses Sonnet implementers + the Opus main thread. | ✅ PASS |
| **Autonomy & gates (D9)** | Gate-SHA binding is signer-agnostic (FR-010): an `auto`-written gate section still records the approved SHA; the freshness check runs the same. Autonomy changes *who signs*, not *what is bound*. | ✅ PASS |

**Result: PASS, no violations.** Complexity Tracking is empty. *(The one place a violation could hide — the git ext writing into a gate section it doesn't own — is designed out: the gate command records the SHA using a git-ext helper; the git ext writes no artifact. This is Chosen Approach §D and Risk R1.)*

## Chosen Approach

### A. Packaging — graphify's installer, hook-registering (mirror + merge)

`extensions/git/` with an idempotent `install.sh` that copies `extension/` → `.specify/extensions/git/`, the cleanup skill → `.claude/skills/`, **and merges its hook entries into `.specify/extensions.yml`** (the graphify variant — council's installer skipped this because council registers no hooks; this one does). `uninstall.sh` removes only what it added, including its hook entries. The `extensions.yml` merge is **append, never overwrite** — it already holds graphify's three `before_*` hooks (see `graphify-context.md`: this is the one shared/mutable file).

### B. The hook architecture (the heart)

The extension is a set of hooks on the **stock** phase boundaries plus a shared **commit primitive** for the boundaries that have no stock hook (council/triage/gates, per-wave):

| Pipeline point | Git-ext mechanism | Action |
|---|---|---|
| after `specify` | `after_specify` hook | **Branch birth (FR-001):** ensure the feature branch — create from the base branch if absent, named exactly the spec ID read from `feature.json`, carrying the uncommitted `spec.md` onto it — then commit `spec(<id>): …`. So `spec.md` lands on the branch; the base never held it. |
| after `clarify` | `after_clarify` hook | commit the `spec.md` revision (`spec(<id>): clarify`) |
| after `plan` | `after_plan` hook | commit plan artifacts (`plan(<id>): …`) |
| council / triage | commit primitive, called by those commands | `council(<id>): …`; at **council approve**, the gate command records `plan.md @ <sha>` into `## Human Gate` using the git-ext `current-sha` helper (FR-008) |
| before `tasks` | `before_tasks` hook | **gate-verify (FR-009):** the council gate's recorded `plan.md @ <sha>` must equal `plan.md`'s current SHA; mismatch ⇒ **hard-block** `tasks` until re-approval (council → D14 reopen tiers) |
| after `tasks` | `after_tasks` hook | commit `tasks(<id>): …` |
| workforce gate | commit primitive + `current-sha` | stamp `tasks.md @ <sha>` + `assignment.md @ <sha>` into `## Workforce Gate` (§8) |
| before `implement` | `before_implement` hook | **gate-verify:** workforce-gate SHAs fresh? mismatch ⇒ hard-block (workforce → re-run gate) |
| per wave (implement) | commit primitive, called by `implement-parallel` | `impl(<id>) wave K/N: …` (FR-005) |
| after `implement` | `after_implement` hook | final implement-boundary commit |
| completion | **`/speckit-git-cleanup`** (human command) | explicit `--no-ff` merge into base + delete branch (FR-011) |

**Three shared primitives** (extension commands the hooks and the pipeline call): `speckit.git.commit "<phase>" "<summary>"` (phase-tagged commit with the FR-006 grammar, **no-op if nothing changed** — FR-004), `speckit.git.sha <artifact>` (prints the current commit SHA touching that artifact — the value gate commands record), `speckit.git.verify-gate <gate>` (compares recorded vs current SHA; exit non-zero ⇒ stale).

### C. Branch birth folded into the first commit (FR-001, §2 D51)

The branch is **not** a `before_specify` hook. `before_specify` fires *before* `specify` assigns the spec ID, so a branch created there would have to **duplicate** `create-new-feature.sh`'s NNN+slug logic and risk a slug mismatch with the dir. Instead, the **`after_specify` commit hook creates the branch** — by then the spec ID exists in `feature.json`, so the branch name is read, not recomputed (FR-002 guaranteed). `git checkout -b <id>` carries the still-uncommitted `spec.md` onto the new branch; the base branch never receives a `spec.md` commit → it stays clean (SC-002). This is exactly "co-incident with `specify`, before `spec.md` is committed" (artifact-layout §2, D51).

### D. Gate↔SHA binding — the git ext supplies, the gate command records (FR-008/009)

To keep principle I clean, the **gate command owns its gate section**; the git ext only supplies the SHA and the freshness verdict. At approval, `council-approve` / the workforce-gate writer calls `speckit.git.sha plan.md` (etc.) and records `<artifact> @ <sha>` in the section it already writes. Before a gated phase, the git ext's `before_*` hook calls `verify-gate`; a stale verdict **hard-blocks** (FR-009). Re-approval routes by gate type (D51): council → D14 reopen tiers via the manual reopen interface (`001`-FR-017); workforce → re-run the gate. *This requires the council-approve skill (and the M3 workforce-gate writer) to call the `sha` helper — the one place the git ext couples to another extension's command (Risk R1).*

### E. Completion cleanup — explicit, unconditional `--no-ff` (FR-011, D51)

`/speckit-git-cleanup` is **human-invoked** (never automatic — retiring a branch is consequential). It performs an **unconditional `--no-ff` merge** into the base (the merge commit is the feature's **completion anchor**: the D19/M5 phase-event binding target, and the node `git log --first-parent` enumerates per feature), preserving every phase-tagged commit; then deletes the feature branch ref. A textual conflict **aborts and is surfaced** for manual resolution (mechanical git never guesses). M1's `main` ff-merge predates this policy and is **grandfathered — never rewritten**.

### F. Composition & the per-wave seam (FR-013)

Hooks are `optional: true, priority: N` (graphify's schema) so they compose; the git commit hook runs *after* graphify's context hook at a shared boundary. `feature.json` stays the feature resolver — the git ext reads the spec ID from it but never makes a downstream phase depend on the branch name. **Per-wave commits (FR-005) and council/gate commits have no stock hook point**, so they are driven by the *commands themselves* calling `speckit.git.commit` — `implement-parallel` per wave (it already commits per wave by hand — the M1 trail), and the council/triage/approve commands at their boundaries. This command→primitive coupling is the design's main integration seam (R1).

### G. The worktree spike (FR-015, firewalled)

A **timeboxed Phase-4 task**: give each parallel implement wave its own `git worktree`, merge per wave, measure whether isolation beats the shared-tree default. Outcome (adopt-later / abandon) is recorded in `implement.log.md` + an I-row regardless. **No v1 hook or command depends on it**; deleting it leaves FR-001…FR-014 intact.

## Rejected Alternatives

- **`before_specify` branch creation** (stock spec-kit's model). Rejected: it fires before the spec ID exists, forcing the hook to re-derive NNN+slug and risking a mismatch with the dir the specify skill computes. Folding branch birth into the `after_specify` commit hook reads the ID from `feature.json` — zero duplication, FR-002 guaranteed (§C).
- **A state file / DB tracking branches and gate SHAs.** Rejected outright by D32 (principle III): the branch is a ref, the SHAs live in the gate artifacts. A state file is forbidden, not merely discouraged.
- **The git ext writes the SHA into the gate section itself.** Rejected: a second writer mutating the gate command's artifact muddies principle I. The git ext *supplies* the SHA; the gate command *records* it (§D).
- **Squash- or rebase-collapse merge at cleanup.** Rejected by D25/D51: it destroys the phase trail the whole feature built. `--no-ff`, unconditional.
- **Fast-forward-when-linear as the cleanup default.** Rejected at spec review (D51): the merge commit must exist unconditionally as the completion anchor; ff leaves no anchor. (ff remains only as M1's grandfathered pre-policy act.)
- **Automatic cleanup at the `complete` phase.** Rejected at clarify: branch retirement is consequential; it stays an explicit human command.
- **Editing the stock spec-kit skills to insert commits.** Rejected: hooks + a commit primitive keep a Spec Kit re-init non-clobbering (the graphify/council compatibility guarantee).

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

**Structure Decision**: sibling-of-graphify, hook-registering. The mechanical git lives in `scripts/*.sh` (testable in isolation, invoked by hooks and by the commit primitive); the one human-facing skill (`/speckit-git-cleanup`) is installed to `.claude/skills/` so a Spec Kit re-init never clobbers it.

## Dependency / graph impact

All-new code under `extensions/git/`. The **only** existing file touched is `.specify/extensions.yml` (hook-merge, append-only) — the single shared/mutable file (`graphify-context.md`). No source file is mutated. The one behavioral coupling is command→primitive (§F/R1): `implement-parallel` (per-wave) and `council-approve` (SHA record) call git-ext primitives — additive, not a rewrite. Blast radius otherwise: none.

## Risk register

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| **R1** | **No stock hook point for extension-command boundaries** (council/triage/gates) and **per-wave** commits, so they depend on those commands calling the git-ext primitive — a command→primitive coupling. If a command forgets to call it, that boundary is silently uncommitted. | **Med** | v1 makes the primitives the single commit path and documents the call site in each command; the `after_implement`/`after_tasks` hooks backstop the phase boundary even if a per-wave call is missed (no *lost* work, only coarser checkpoints). **Flagged for the council** — this is the design's load-bearing seam. |
| **R2** | **Gate-verify hook points.** `before_tasks` guards the council gate and `before_implement` guards the workforce gate — but an artifact edited *after* the gated phase already ran isn't re-checked. | Med | v1 scopes freshness to the *entry* of the gated phase (the moment the approval is consumed); continuous re-verification is out of v1 scope. Documented as a known bound. **Flagged.** |
| **R3** | **Branch-at-`after_specify` when the base already advanced / re-run.** If `specify` is re-run or the branch exists, the hook must be idempotent and must not fork a second branch. | Low | `branch.sh` is create-if-absent + checkout (FR-012); re-running switches to the existing branch. |
| **R4** | **`extensions.yml` merge corrupts the shared registry** → breaks *all* phases. | Low | Append-only merge with a parse-check; `uninstall.sh` reverts exactly its entries; mirrors graphify's proven merge. |
| **R5** | **Worktree spike bleeds into v1** if a wave's worktree merge is treated as load-bearing. | Low | Firewalled by FR-015; the spike writes only to `implement.log.md`; no hook references it. |

## Cost / complexity estimate

**Runtime cost: zero** — no model, no tokens, no trace (SC-007). The complexity is **integration, not algorithm**: the hard parts are the branch-birth timing (§C), the command→primitive seam (§F/R1), and the gate freshness contract (§D/R2) — all mechanical git wired into the existing hook system. No novel data structures; ~5 short `sh` scripts + one skill.

## Testability claim

Every FR/SC is falsifiable without a model: a full pipeline run on a *later* feature proves SC-001/002/003 (branch auto-created, phase+wave commits present); an injected post-approval edit + a blocked `tasks` proves SC-004; a `git log --first-parent` + reachability count after cleanup proves SC-005; a `traces.jsonl` scan proves SC-007 (zero git-ext records); the spike's `implement.log.md` entry proves SC-008. See [quickstart.md](./quickstart.md).

## Phase outputs

- **Phase 0** — [research.md](./research.md): resolved design decisions (branch-birth timing, the command→primitive seam, gate-SHA ownership, `--no-ff` anchor, worktree spike framing).
- **Phase 1** — [data-model.md](./data-model.md) (branch/commit/gate-binding entities + the commit-message grammar), [contracts/commands.md](./contracts/commands.md) (the hooks + 4 command I/O contracts), [quickstart.md](./quickstart.md) (end-to-end validation).

## Complexity Tracking

*No Constitution violations — section intentionally empty.*
