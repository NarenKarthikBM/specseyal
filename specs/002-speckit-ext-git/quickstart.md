# Quickstart — speckit-ext-git validation

Runnable checks that prove each SC. All are mechanical (no model). Run from repo root after `bash extensions/git/install.sh .`.

## Prerequisites
- A repo with `.specify/` initialized (spec-kit) and the git extension installed (hooks merged into `.specify/extensions.yml`).
- A clean base branch (`main`) to cut a test feature from.

## Setup
```
bash extensions/git/install.sh .
grep -A2 'after_specify\|before_tasks' .specify/extensions.yml   # hooks registered
```

## Scenario 1 — auto branch + phase commits (SC-001, SC-002, SC-003)
1. Run `/speckit-specify` for a throwaway feature. **Expect**: a branch named `NNN-slug` (= spec ID) exists and is checked out; `spec.md` is committed **on it**; `git log main..HEAD` shows a `spec(NNN-slug): …` commit; `git show main:specs/NNN-slug/spec.md` **fails** (base never held it → SC-002).
2. Run `/speckit-plan`, `/speckit-tasks`. **Expect**: one `plan(NNN): …` and one `tasks(NNN): …` commit at each boundary (SC-003); no manual `git` was run (SC-001).
3. Run an implementation of ≥3 waves. **Expect**: an `impl(NNN) wave K/N: …` commit per wave (SC-003).

## Scenario 2 — gate↔SHA binding + stale hard-block (SC-004)
1. Approve the council gate. **Expect**: `gates.yml` records `plan.md @ <S1>` (== `speckit.git.sha specs/NNN/plan.md`); `## Human Gate` carries a one-line `gates.yml` reference (R1-S09).
2. Edit `plan.md` — test **both** a committed edit and an **uncommitted** one — then run `/speckit-tasks`:
   ```
   printf '\n<!-- injected edit -->\n' >> specs/NNN-slug/plan.md   # uncommitted → dirty tree
   /speckit-tasks
   ```
   **Expect** (both cases): `before_tasks` → `verify-gate council` exits non-zero → `tasks` **hard-blocked** ("stale approval: plan.md"); the **uncommitted** case is caught too (working-tree-aware, R1-S05). Stays blocked until the council gate is re-run (D14 reopen).

## Scenario 3 — completion cleanup: trail preserved + tag anchor (SC-005)
1. Record each phase/wave commit SHA on the branch: `git rev-list main..HEAD`.
2. Run `/speckit-git-cleanup`. **Expect**: integration into `main` (**ff if linear**, merge-commit if diverged, D52); a **mandatory annotated tag** present — `git for-each-ref refs/tags/complete/NNN-slug` non-empty (the anchor); **each recorded SHA still reachable** — `git merge-base --is-ancestor <sha> main` returns 0 for every one (per-SHA, not a count); the feature branch ref gone.
3. Force a conflict (edit the same line on `main` first) and retry. **Expect**: `merge --abort` and a surfaced conflict — branch **not** deleted, no silent resolution.

## Scenario 3b — interrupt/resume at wave granularity (SC-006, the missing P1 coverage — R1-S18)
1. Start an implementation of ≥3 waves; kill the process after wave 2 commits.
2. Resume. **Expect**: git HEAD and `tasks.md` `[X]` markers **agree** (the commit precedes the `[X]`, R1-S06); resumption starts at wave 3; no wave-1/2 work duplicated or lost.

## Scenario 4 — zero AI cost, by construction (SC-007)
- The extension runs as synchronous git hooks — **there is no session to trace**, so `cost = 0` tokens *by construction* (a `grep '"role":"git"' traces.jsonl → 0` would pass **vacuously** and proves nothing — R1-S18). The real check: no `extensions/git/**` path invokes a model or the Agent tool.

## Scenario 5 — worktree spike outcome (SC-008)
- Confirm `implement.log.md` contains a spike entry (what was tried, isolation result, adopt-later/abandon) and that no `extensions/git/**` file references `worktree` outside the spike task — removing the spike leaves Scenarios 1–4 green.

## M2 conformance note (rule-5, D50)
`002` is **not** a meta-feature — it does not describe the council's `opinions/` path, so no rule-5-exempt marker is present (verified: `grep -rl 'opinions/' specs/002-speckit-ext-git/` returns nothing). Standard conformance (artifact-layout §7) applies unchanged.
