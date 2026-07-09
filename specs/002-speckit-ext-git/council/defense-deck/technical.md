# Defense Deck — Technical

**Feature**: `002-speckit-ext-git`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

M0 and M1 ran the per-feature git lifecycle entirely by hand: an engineer manually created the feature branch, remembered to commit at each phase boundary, and manually merged at completion. That manual discipline is fragile and is exactly what a governed pipeline should not depend on. `speckit-ext-git` automates it — mechanically, with zero AI — so that an engineer can drive `/speckit-specify → plan → tasks → implement → completion` without ever typing a `git` command, and the resulting branch/commit graph is the durable, resumable checkpoint trail the rest of the pipeline (and the eventual M5 manager) can rely on.

Four things are broken without it, in priority order (per `spec.md`'s user stories): (1) the feature branch and phase-boundary commits don't happen automatically (US1, P1 — the M2 exit condition); (2) `implement`'s long, parallel, interruption-prone run has no sub-phase checkpoint, so an interruption can force re-running a whole multi-wave implementation (US2, P1); (3) a gate approval (council on `plan.md`, workforce on the roster) isn't bound to the exact commit it approved, so a post-approval edit can silently ride on a stale sign-off (US3, P2); (4) completion has no trail-preserving, branch-retiring integration step (US4, P2). A fifth, explicitly non-committed story (US5, P3) asks whether per-wave git worktrees would improve implementation isolation — a timeboxed spike, not shipped behavior.

---

## 2. Chosen Approach & Rejected Alternatives

**Chosen approach**

Package `extensions/git/` exactly like `extensions/graphify/` — a **hook-registering** installer (council's installer, by contrast, is command-only and registers no hooks). The extension is almost entirely hooks on the pipeline's **stock** phase boundaries (`after_specify`, `after_clarify`, `after_plan`, `before_tasks`, `after_tasks`, `before_implement`, `after_implement`), plus **three shared primitives** — `speckit.git.commit`, `speckit.git.sha`, `speckit.git.verify-gate` — that serve the boundaries with no stock hook point (council/triage/gate commits, and per-wave commits inside `implement`).

The design's spine (D32): **the branch and the commit graph *are* the state** — no state file, ever. Concretely:

- **Branch birth is folded into the `after_specify` commit hook**, not a `before_specify` hook. By `after_specify`, the spec ID already exists in `feature.json`, so the branch name is *read*, not re-derived — this guarantees FR-002 (branch name == spec ID) with zero duplication of `create-new-feature.sh`'s NNN+slug logic. `git checkout -b <id>` carries the still-uncommitted `spec.md` onto the new branch, so the base branch never receives a per-feature spec commit (SC-002).
- **Gate↔SHA binding splits supply from record** to keep Constitution principle I (artifacts are the contract) clean: the git ext *supplies* the SHA via a `current-sha` helper; the gate command that already owns its gate section (`council-approve`, the workforce-gate writer) *records* `<artifact> @ <sha>` into that section. The git ext never becomes a second writer of another phase's artifact. A `before_*` hook on the gated phase then calls `verify-gate`, and a stale verdict **hard-blocks** (FR-009) — re-approval routes through D14's reopen tiers for a council gate, or a plain re-run for a workforce gate.
- **Completion cleanup is one human-invoked command**, `/speckit-git-cleanup` — never automatic, because retiring a branch is consequential. It performs an **unconditional `--no-ff` merge** (the merge commit is the feature's completion anchor — the D19/M5 binding target and the node that makes `git log --first-parent` enumerate one entry per feature) and then deletes the feature branch ref. A textual conflict aborts and surfaces for manual resolution; mechanical git never guesses. M1's fast-forward completion predates this policy and is grandfathered, never rewritten.
- **The command→primitive seam (§F) is the one place the git ext couples to another extension's command**: `implement-parallel` calls `speckit.git.commit` per wave (FR-005), and the council/triage/approve commands call it at their boundaries, because those boundaries have no stock hook point. This is the design's single most load-bearing integration seam (flagged as Risk R1 below).
- **A firewalled Phase-4 spike** gives each parallel implement wave its own `git worktree`, merges per wave, and records an adopt-later/abandon outcome in `implement.log.md` regardless of result. No FR-001…FR-014 behavior depends on it; deleting it leaves the v1 loop intact.

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| `before_specify` branch creation (stock spec-kit's own model) | Fires before the spec ID exists, forcing the hook to re-derive the NNN+slug logic itself and risking a mismatch with the directory the specify skill computes. Folding birth into `after_specify` reads the ID instead of recomputing it — zero duplication, FR-002 guaranteed. |
| A state file / DB tracking branches and gate SHAs | Rejected outright by D32 (principle III), not merely disfavored: the branch is a ref and the SHAs live inside the gate artifacts by design. A state file is forbidden. |
| The git ext writes the SHA into the gate section itself | A second writer mutating the gate command's own artifact muddies Constitution principle I. The git ext supplies the SHA; the gate command that owns the section records it. |
| Squash- or rebase-collapse merge at cleanup | Rejected by D25/D51: collapsing history destroys exactly the phase trail the whole feature build produced. |
| Fast-forward-when-linear as the cleanup default | Rejected at spec review (D51): the merge commit must exist **unconditionally** as the completion anchor; a fast-forward leaves no anchor node. (Fast-forward survives only as M1's grandfathered pre-policy act.) |
| Automatic cleanup at the `complete` phase | Rejected at clarify: retiring a branch is consequential enough that it must stay an explicit, engineer-invoked step. |
| Editing the stock spec-kit skills directly to insert commits | Rejected: hooks plus a commit primitive keep a Spec Kit re-init non-clobbering — the same compatibility guarantee graphify and council already rely on. |

---

## 3. Dependency / Graph Impact

Grounded in `graphify-context.md` (repo graph, 1013 nodes / 917 edges, generated 2026-07-09; deterministic AST extraction, no LLM).

**The extension is almost entirely new code.** `extensions/git/` does not exist in the graph. What the graph grounds instead is the *pattern* this build must mirror and the *one* file it must touch:

- **Pattern to mirror**: `extensions/council/install.sh` (community 101) is the install exemplar — copy `extension/` → `.specify/extensions/<name>/`, copy `skills/*` → `.claude/skills/`, the same `bold/ok/warn/die` helper UI. `extensions/graphify/install.sh` supplies the piece council's installer lacks: the `extensions.yml` hook-merge step, since council registers no hooks and this extension does. `002` = council's packaging + graphify's hook-merge.
- **Coordination point (no code dependency)**: `.specify/scripts/bash/create-new-feature.sh` computes the NNN+slug and writes `feature.json`; it is branch-agnostic and creates no git branch itself. The `after_specify` hook must read the spec ID it just wrote, never recompute it (FR-001/FR-002).
- **Contracts consumed, not code**: `artifact-layout.md` §2 (branch co-incident with `specify`, amended under D51) and §8 (`## Workforce Gate` SHA fields), and `decision-record.md` (council-gate `@ <sha>` citations, R4). The SHA bindings extend these existing sections; nothing new is invented.

**Blast radius**: `install.sh`'s helper functions are cosmetic (copy the shape). `.specify/extensions.yml` is the one file with real blast radius — it is depended on by *every* `/speckit-*` phase command for its `before_*`/`after_*` hooks, so a malformed edit there breaks all phases, not just git's.

**Shared / mutable files (collision watch)** — both flagged explicitly by graphify-context, and both load-bearing for this plan:

- `.specify/extensions.yml` — the single shared/mutable file. It already holds graphify's three `before_*` hooks; this extension's installer **merges in, append-only, never overwrites**. Per graphify-context.md, this merge must be serialized (orchestrator glue), never handed to a parallel subagent.
- `.specify/feature.json` — gitignored/transient (D45). The branch hook reads the spec ID from it but must never make a downstream phase depend on the branch name (FR-013) — this is what keeps branch state and feature tracking decoupled.

All other files this feature introduces are new and disjoint from existing code, and are freely parallelizable in implementation.

---

## 4. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| **R1** | No stock hook point exists for extension-command boundaries (council/triage/gates) or per-wave commits inside `implement`, so those checkpoints depend on the calling command itself invoking the git-ext primitive — a command→primitive coupling. A command that forgets the call leaves that boundary silently uncommitted. | Med | Med — a missed call degrades checkpoint granularity (a wave or gate boundary goes uncommitted); it does not lose work, because the coarser phase hook (`after_implement`/`after_tasks`) still backstops it. | v1 makes the primitives the single commit path and documents the call site inside each calling command; the phase-boundary hooks backstop any missed per-wave/gate call. **Explicitly flagged for the council** as the design's load-bearing seam. |
| **R2** | Gate-verify only fires at the *entry* of a gated phase (`before_tasks` for the council gate, `before_implement` for the workforce gate). An artifact edited after the gated phase has already started running is not re-checked mid-flight. | Med | Med — a narrow but real staleness window inside an already-running phase; outside that window the hard-block (FR-009) is fully effective. | v1 explicitly scopes freshness to gate entry, not continuous re-verification; documented as a known, accepted bound rather than solved. **Flagged.** |
| **R3** | Branch-at-`after_specify` re-entrancy: if `specify` is re-run, or the branch already exists, the hook must not fork a second branch or otherwise diverge. | Low | Med if it occurred (a diverged/duplicate branch would corrupt the one piece of state living outside `specs/`) — but the mitigation makes this effectively unreachable. | `branch.sh` is create-if-absent-then-checkout (FR-012); re-running `specify` switches to the existing branch instead of creating a new one. |
| **R4** | The `extensions.yml` merge corrupts the shared hook registry, which every `/speckit-*` phase command reads — a bad merge breaks *all* phases, not just git's. | Low | High — this is the one file in the whole design whose blast radius extends beyond this feature (graphify-context.md's own blast-radius note). | Append-only merge with a parse-check; `uninstall.sh` reverts exactly the entries this extension added; the merge mirrors graphify's already-proven installer pattern. |
| **R5** | The worktree-per-wave spike (US5/FR-015) bleeds into v1 if a wave's worktree merge is ever treated as load-bearing rather than experimental. | Low | Low — firewalled by construction; nothing in the committed loop references it. | Firewalled by FR-015: the spike writes only to `implement.log.md`, and no hook or FR-001…FR-014 behavior references its outcome. |

---

## 5. Cost / Complexity Estimate

**Runtime cost is zero by design** — no model calls, no tokens, no `traces.jsonl` records (SC-007, FR-007). This is the plan's explicit non-goal-as-goal: `git_ext_spend = 0`.

**Build-side cost, per D18's role→model map:**

- **Council round** (this defense): 1 Sonnet deck-prep session (this one) + 5 Sonnet council-member sessions (independent opinions, then anonymized peer review) + 1 Opus-xhigh chairman synthesis session.
- **Triage**: applying accepted suggestions back into `plan.md` runs on the Opus main thread (judgment role, D18) — session count folds into the main thread, not a separate dispatch.
- **Implementation**: session/wave count is not yet fixed — `tasks.md` doesn't exist until after this council round clears triage — but the plan's own complexity framing bounds the shape of that work: **integration, not algorithm**. The hard parts are the branch-birth timing (§C above), the command→primitive seam (§F/R1), and the gate-freshness contract (§D/R2) — all mechanical git wired into an already-existing hook system, no novel data structures. The plan estimates roughly five short POSIX `sh` scripts (`branch.sh`, `commit.sh`, `sha.sh`, `verify-gate.sh`, `cleanup.sh`) plus one skill (`/speckit-git-cleanup`) plus four command provenance stubs plus the hook/config wiring — implementation sessions will run Sonnet per D18, most likely fewer waves than `001`'s 8-wave build given the narrower, purely-mechanical scope.

**What drives complexity up**: the command→primitive coupling (R1) requiring every non-hooked boundary's calling command to remember the call; composing cleanly with two already-installed extensions (graphify's `before_*` hooks, council's commands) at shared boundaries; and the `extensions.yml` merge being the one edit with system-wide blast radius. **What keeps it down**: no new runtime dependency beyond git itself (≥2.20), no database, no state file, no AI at runtime, and a Constitution Check that passes with an empty Complexity Tracking table.

---

## 6. Testability Claim

Every FR/SC is designed to be falsifiable without a model call — pure git-state and artifact inspection. Per `plan.md`'s Testing field (full detail deferred to `quickstart.md`, not itself a source of this deck):

| SC | Claim | Verification method |
|---|---|---|
| SC-001 | Full pipeline run completes on an auto-created branch with phase-tagged commits; no manual `git` needed. | End-to-end pipeline run on a real feature. |
| SC-002 | Branch name == spec ID for 100% of features; base branch carries zero per-feature artifacts pre-integration. | Rides the same end-to-end pipeline run as SC-001 — spec.md's US1 Independent Test checks `spec.md` lands on the feature branch and not the base branch in that same run. |
| SC-003 | Every completed phase boundary that changed an artifact has exactly one phase-tagged commit; every completed wave has its own. | `git log` history walk against the phase/wave sequence. |
| SC-004 | 100% of gate approvals record the approved SHA; a post-approval edit is detected and blocks the dependent phase until re-approval. | An injected post-approval edit, proving the stale-approval hard-block fires. |
| SC-005 | 100% of phase-tagged commits remain individually reachable from the base-branch tip after completion (zero squashed); branch ref removed. | Completion-integration reachability check (`git log --first-parent` walk + ref-existence check). |
| SC-006 | An interrupted implementation resumes at the first uncommitted wave with nothing duplicated or lost. | Not separately named in `plan.md`'s Testing field; verified structurally by the same wave-commit mechanism SC-003 walks, exercised via spec.md's US2 Independent Test (interrupt after wave 2, confirm resume starts at wave 3). |
| SC-007 | Zero AI/token cost and zero `traces.jsonl` records of the extension's own. | A `traces.jsonl` scan across a full run, confirming no git-extension session record exists. |
| SC-008 | The worktree spike produces a recorded outcome + recommendation within its timebox, regardless of result; removing it leaves SC-001…SC-007 unaffected. | The spike's recorded entry in `implement.log.md`. |

Two claims (SC-002, SC-006) are not independently named with their own test in `plan.md`'s Testing line — they ride existing tests (the SC-001 pipeline run and the SC-003 history walk, respectively) rather than getting a dedicated verification step of their own. This deck surfaces that mapping rather than implying six named tests where the plan states four.
