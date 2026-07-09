# Research — speckit-ext-git (Phase 0)

Design decisions resolved before Phase 1. Each: **Decision · Rationale · Alternatives rejected.** All are mechanical-git choices (no model), grounded in the spec's four ratified positions (D51) and the M0/M1 contracts.

## D-R1 · Branch birth = the `after_specify` commit hook

**Decision**: The feature branch is created by the **first commit hook** (`after_specify`), which reads the spec ID from `.specify/feature.json` and does `git checkout -b <spec-id>` (carrying the uncommitted `spec.md`), then commits it — so `spec.md` is the branch's first commit and the base branch never held it.
**Rationale**: By `after_specify` the spec ID already exists (create-new-feature.sh assigned it), so the branch name is **read, not recomputed** — FR-002 is guaranteed and there is no slug to keep in sync. Satisfies artifact-layout §2's "co-incident with `specify`, before `spec.md` is committed" (D51).
**Alternatives rejected**: a `before_specify` hook (fires before the ID exists → must duplicate `create-new-feature.sh`'s NNN+slug logic and risks a dir/branch mismatch, since the specify skill computes its own dir name independently).

## D-R2 · Commit surface = `after_*` hooks + one shared primitive

**Decision**: Register `after_specify/clarify/plan/tasks/implement` commit hooks for the stock phases; expose `speckit.git.commit "<phase>" "<summary>"` as the single commit primitive that the non-stock boundaries (council, triage, gates, and per-wave in implement) call directly.
**Rationale**: Stock phases have hook points; extension-command phases and per-wave do not. One primitive keeps the commit-message grammar (FR-006) and the "no-op if clean" rule (FR-004) in exactly one place.
**Alternatives rejected**: editing the stock spec-kit skills to embed commits (a re-init would clobber them — breaks the graphify/council compatibility guarantee); a bespoke per-wave hook (spec-kit has no per-wave hook vocabulary).

## D-R3 · Gate↔SHA binding = git-ext-owned `gates.yml` (revised at triage, R1-S09/S20)

**Decision**: The binding lives in a **git-ext-owned `specs/NNN/gates.yml`**, written by the git ext via a reinstall-surviving `after_council_approve` hook; the gate section carries a one-line reference. `verify-gate` reads `gates.yml`, compares **working-tree-aware + fail-closed** (R1-S05/S10), and hard-blocks on stale (FR-009).
**Rationale**: The git ext owning its own artifact keeps principle I clean **and** dissolves the supply/record seam — the original "git ext supplies, gate command records" split still required editing the gate command, which its installer overwrites on reinstall (R1-S04). One owner, one artifact.
**Alternatives rejected**: git ext co-writes the gate section (co-write, ownership muddle); the earlier supply/record split (still coupled the git ext to an installer-overwritten command).

## D-R4 · Completion anchor = `complete/<spec-id>` tag; merge `ff`-permitted (amended D52)

**Decision**: `/speckit-git-cleanup` integrates with **fast-forward permitted** (merge-commit only when the base diverged; never squash/rebase-collapse), creates a **mandatory annotated tag `complete/<spec-id>`** as the completion anchor, then deletes the branch; a conflict aborts and is surfaced.
**Rationale (D52, superseding D51's merge clause, R1-S27)**: the anchor is the **tag** — immutable, the D19/M5 binding target, enumerable via `git for-each-ref refs/tags/complete/*` **independent of merge topology**. It exists unconditionally as a tag, so `--no-ff` is no longer needed and solo/linear features stay ff-clean. "Preserve the phase trail" (D25) still holds (no squash).
**Alternatives rejected**: `--no-ff` mandatory (D51's clause — superseded by the tag); squash/rebase (destroys the trail — D25). *M1's ff-merge grandfather is now moot (kept as history).*

## D-R5 · Re-approval after a stale-approval hard-block routes by gate type

**Decision**: A hard-blocked stale approval is cleared by re-running the **gate of that artifact's type** — council-approved artifacts via D14's reopen tiers (`delta` default, `full` if the approach changed) through the manual reopen interface (`001`-FR-017); workforce-gate artifacts by re-running the workforce gate.
**Rationale**: The git ext only detects+blocks; clearing the block is a human gate action, and each gate already has its re-entry path (D51). No new re-approval mechanism is invented.
**Alternatives rejected**: a git-ext "force-approve" override (defeats the binding — rejected at clarify).

## D-R6 · No state file; the worktree idea is a firewalled spike

**Decision**: Branch state = the git ref; gate-SHA state = fields in the gate artifacts; nothing else persists (D32). The I-4 worktree-per-wave idea ships as a **timeboxed Phase-4 spike** whose only output is a recorded finding in `implement.log.md` + an I-row.
**Rationale**: D32 forbids a state file. D25 explicitly scopes worktrees as a spike, not committed behavior; firewalling it keeps FR-001…FR-014 independent of its outcome.
**Alternatives rejected**: a `.git-ext-state.json` (forbidden by D32); shipping worktrees as v1 behavior (contradicts D25).

## D-R7 · Per-wave commits reuse `implement-parallel`'s existing behavior

**Decision**: `implement-parallel` calls `speckit.git.commit "impl" "wave K/N …"` after each wave (FR-005); the `after_implement` hook backstops the phase boundary.
**Rationale**: `implement-parallel` **already** commits per wave by hand (the M1 trail: `impl(001) wave K/8`). The extension just formalizes the message grammar and makes the call the single commit path. If a per-wave call is missed, the `after_implement` hook still checkpoints the phase — coarser, never lost.
**Alternatives rejected**: a separate per-wave hook (no such hook vocabulary); leaving per-wave commits fully manual (defeats the automation goal).
