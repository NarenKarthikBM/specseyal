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
1. Approve the council gate. **Expect**: `## Human Gate` records `plan.md @ <S1>` where `<S1> == speckit.git.sha specs/NNN/plan.md`.
2. Edit `plan.md`; commit (`<S2>`). Run `/speckit-tasks`. **Expect**: the `before_tasks` hook (`verify-gate council`) exits non-zero → `tasks` is **hard-blocked** with a "stale approval: plan.md S1≠S2" message; it stays blocked until the council gate is re-run (D14 reopen).

## Scenario 3 — completion cleanup preserves the trail (SC-005)
1. Note the feature's phase/wave commit count: `git log --oneline main..HEAD | wc -l` = `C`.
2. Run `/speckit-git-cleanup`. **Expect**: a `--no-ff` merge commit on `main`; all `C` phase/wave commits still reachable (`git log main | grep -c '(NNN'` unchanged); the feature branch ref gone (`git branch --list NNN-slug` empty); `git log --first-parent main` shows the feature as **one** node (the anchor).
3. Force a conflict (edit the same line on `main` first) and retry. **Expect**: `merge --abort` and a surfaced conflict — branch **not** deleted, no silent resolution.

## Scenario 4 — zero AI cost (SC-007)
- After a full run: `grep -c '"role":"git' specs/NNN/traces.jsonl` → **0**. The extension left no trace record; `cost = 0` tokens.

## Scenario 5 — worktree spike outcome (SC-008)
- Confirm `implement.log.md` contains a spike entry (what was tried, isolation result, adopt-later/abandon) and that no `extensions/git/**` file references `worktree` outside the spike task — removing the spike leaves Scenarios 1–4 green.

## M2 conformance note (rule-5, D50)
`002` is **not** a meta-feature — it does not describe the council's `opinions/` path, so no rule-5-exempt marker is present (verified: `grep -rl 'opinions/' specs/002-speckit-ext-git/` returns nothing). Standard conformance (artifact-layout §7) applies unchanged.
