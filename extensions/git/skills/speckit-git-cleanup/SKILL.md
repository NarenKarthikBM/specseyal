---
name: "speckit-git-cleanup"
description: "Integrate the completed feature branch into base_branch (fast-forward when possible; git merge --no-ff only if the base diverged, D52), create the mandatory annotated completion tag complete/<spec-id>, and delete the feature branch — by shelling out to extensions/git/extension/scripts/cleanup.sh (installed at .specify/extensions/git/scripts/cleanup.sh). On a merge conflict: abort and surface, never auto-resolve, never delete an unmerged branch. Idempotent. Mechanical git only — invokes no model and writes no traces.jsonl record (FR-007)."
argument-hint: "Optional: <feature-branch-name> — defaults to .specify/feature.json's feature_directory, or the current branch if that file is absent"
compatibility: "Requires the git extension installed at .specify/extensions/git/ (script at .specify/extensions/git/scripts/cleanup.sh, config at .specify/extensions/git/git-config.yml) and a clean working tree once real work is needed. The feature must actually be complete — this deletes the feature branch ref."
metadata:
  author: narenkarthikbm
  source: "extensions/git/skills/speckit-git-cleanup/SKILL.md — speckit-ext-git (specs/002-speckit-ext-git), T017"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

Optional. Trim surrounding whitespace; if what remains is non-empty, it is the `<feature-branch-name>` — pass it as `cleanup.sh`'s one positional argument verbatim (a git branch name cannot itself contain whitespace, so no further parsing is needed). That name is both the feature branch to retire **and** the spec id used in the tag (`complete/<spec-id>`), per `FeatureBranch.name == spec id` (`data-model.md`). If `$ARGUMENTS` is empty, pass no argument — `cleanup.sh` resolves the branch itself from `.specify/feature.json`'s `feature_directory` (basename), falling back to the currently checked-out branch if that file is absent or unparsable.

## What this is

This is the **one human-invoked command** in the git extension (`contracts/commands.md` — `/speckit-git-cleanup`; FR-011, D52). Every other surface this extension provides is a hook-fired primitive (`speckit.git.commit`, `speckit.git.sha`, `speckit.git.verify-gate`); this is the deliberate exception. Retiring a branch is consequential — it deletes a ref — so **nothing in the pipeline invokes this automatically**: a human decides the feature is done and runs `/speckit-git-cleanup` themselves, or asks the agent to run it on their behalf in conversation. That is why `disable-model-invocation` is `false` above, the same as this extension's other command skills — not `true`, which is reserved for a skill like `/speckit-council-approve` where a literal human judgment call is the entire point of the command. Here there's no judgment left for a model to usurp once the human has decided to invoke cleanup: running this skill is executing a deterministic script and reporting exactly what it did.

This skill runs **no model** and writes **no `traces.jsonl` record** (FR-007) — mechanical git only. It is a thin wrapper: resolve the one optional argument, shell out to `cleanup.sh`, relay its result. Every behavior below — integrate, tag, delete, conflict-abort, idempotency — lives in the script (`extensions/git/extension/scripts/cleanup.sh`; its command-file provenance source is `extensions/git/extension/commands/speckit.git.cleanup.md`), not in this SKILL's own prose.

## Pre-Execution

1. **Confirm intent.** This is a completion action, not a checkpoint — only run it once the feature's work is actually done and the branch is ready to retire.
2. **Resolve the argument** per "User Input" above: either a trimmed `$ARGUMENTS` string, or nothing (let the script self-resolve).
3. **Locate the script** at `.specify/extensions/git/scripts/cleanup.sh` (the installed path — the installer copies this extension's `extension/` directory to `.specify/extensions/git/`, so `extension/scripts/cleanup.sh` lands there). If it's missing, stop and report that the git extension isn't installed in this repo — do not fall back to running raw git commands yourself.

## Execution

Run the script:
- `$ARGUMENTS` empty → `.specify/extensions/git/scripts/cleanup.sh` (no arguments; the script resolves the feature branch itself).
- `$ARGUMENTS` non-empty → `.specify/extensions/git/scripts/cleanup.sh "<feature-branch-name>"`.

Relay its stdout, stderr, and exit code — do not reinterpret, retry, or "fix" anything it reports. What it does, in order:

1. **Idempotency check first (read-only, safe regardless of working-tree state):** if the feature branch is already gone and the `complete/<spec-id>` tag already exists, it prints a no-op message and exits 0 — nothing further runs. If the branch is gone but the tag is missing (or vice versa), it reports a specific error rather than guessing; surface that as-is rather than papering over it.
2. **Working-tree guard:** only if real work remains does it require a clean working tree (`git status --porcelain` empty) — refusing with no side effects otherwise. Commit or stash first if this fires.
3. **Integrate** the feature branch into `base_branch` (from `.specify/extensions/git/git-config.yml`): fast-forward when possible; `git merge --no-ff` only when `base_branch` has diverged from the feature branch tip (D52). Never squash, never rebase-collapse — every phase/wave commit stays individually reachable.
4. **Tag** the integration commit with the mandatory annotated tag `complete/<spec-id>` (skipped only if a prior, interrupted run already created it) — the completion anchor, independent of merge topology (D52).
5. **Delete** the feature branch with `git branch -d` (never `-D`): git itself refuses if any commit would become unreachable, which is the no-silent-loss guard, not a bespoke check this skill adds.

## Conflict handling — never auto-resolve

If integration hits a textual merge conflict, `cleanup.sh` itself runs `git merge --abort` and exits non-zero with a clear message — the feature branch is left fully intact (nothing deleted, no tag created, no partial state). Surface that failure to the human exactly as the script reports it. Never attempt to resolve the conflict yourself, never re-run with a force flag, and never delete the feature branch in this state — the script's refusal *is* the safety mechanism, not an error for this skill to route around. The human resolves the conflict manually (on either branch, their call) and then simply re-runs `/speckit-git-cleanup`.

## Idempotent re-run

Re-running this skill after a completed cleanup is always safe: the script detects the branch is already gone and the tag already present, prints a "nothing to do" message, and exits 0 (see Execution step 1). Re-running after an aborted, conflicted attempt is also safe — the feature branch is untouched, so a normal cleanup attempt (or, once the conflict is resolved by hand, another cleanup run) proceeds as if for the first time.

## Observability — no trace

This skill invokes no model and writes no `traces.jsonl` record, in every outcome — success, conflict-abort, or already-clean. `contracts/commands.md` names the whole extension surface this way: "Every one is mechanical git; none calls a model or writes a `traces.jsonl` record" (FR-007). There is no session here to attribute a role, model, tokens, or duration to — just the script's own result.

## Guardrails

- Never auto-resolve a merge conflict, never force-delete (`-D`) the feature branch, never delete an unmerged branch.
- Never squash or rebase-collapse the feature branch before integration — every phase/wave commit must stay individually reachable (D25).
- Never invoke this skill on the pipeline's own initiative — no hook fires it; only an explicit human decision (typing `/speckit-git-cleanup`, or asking the agent to run it) triggers execution.
- Never write to `traces.jsonl` for this phase — it is sessionless by contract (FR-007).
- Never reimplement or bypass `cleanup.sh`'s logic with ad hoc git commands — this skill's only job is to invoke the script and relay its result.

## Completion Report

Report, concisely:
- The feature branch named/resolved, and the `base_branch` it integrated into.
- Outcome: integrated + tagged + deleted | already clean (no-op) | aborted on conflict (branch left intact).
- The integration commit and the `complete/<spec-id>` tag name, if created this run.
- On conflict: the script's own error, and that manual resolution + a re-run is the next step.
- An explicit line: no `traces.jsonl` record was written (no session ran).

## Done When

- [ ] `.specify/extensions/git/scripts/cleanup.sh` located and invoked with either no argument or the trimmed `$ARGUMENTS`.
- [ ] The script's own stdout/stderr/exit code relayed verbatim — no reinterpretation or retry logic added here.
- [ ] On conflict: reported as a surfaced failure, feature branch confirmed left intact, no auto-resolve attempted.
- [ ] On success: integration + mandatory `complete/<spec-id>` tag + branch deletion confirmed from the script's own report.
- [ ] Idempotent re-run (or re-run after a conflict abort) acknowledged as safe when applicable.
- [ ] No `traces.jsonl` record written.
- [ ] Completion reported to the human.
