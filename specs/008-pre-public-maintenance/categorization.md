# Categorization — 008-pre-public-maintenance

> **Source binding (S14):** derived from `tasks.md @ b13ee42` (18 tasks).

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `qa-automation` | true | false | baseline, harness, pre-change-verification, regression, cross-extension |
| T002 | `test` | `qa-automation` | true | false | bash, shell, fr-015, allowlist, scope-guard, git-diff |
| T003 | `scaffold` | `devtools-cli` | false | false | bash, shell, install, installer, security, argument-validation, argument-injection, trap, exit-handler |
| T004 | `scaffold` | `devtools-cli` | true | false | bash, shell, install, sparse-checkout, git-clone, codeload, tarball, fallback, delegation |
| T005 | `scaffold` | `devtools-cli` | false | false | bash, shell, self-test, smoke-test, install, cli-flag |
| T006 | `docs` | `devtools-cli` | true | false | docs, readme, quickstart, install-instructions, security-posture |
| T007 | `test` | `qa-automation` | false | false | fixture, golden, both-branch, non-regression, conformance, injected-violation, contract |
| T008 | `endpoint` | `devtools-cli` | false | false | python, cli, conformance, validation, stdlib, subprocess, delegation, contract, shell-out |
| T009 | `endpoint` | `devtools-cli` | true | false | python, cli, conformance, validation, contract, artifact-layout, decision-record, completion-report, testing-doc, trace-schema, agent-library-schema |
| T010 | `endpoint` | `devtools-cli` | true | false | python, self-test, contract-drift, cli, validation |
| T011 | `test` | `qa-automation` | true | false | bash, shell, fixture, golden, determinism, static-analysis, no-import-guard, test-harness, non-regression |
| T012 | `scaffold` | `devtools-cli` | true | false | bash, shell, install, installer-hygiene, manifest, yaml, hooks, divergence-guard, git, idempotent, reinstall |
| T013 | `docs` | `ai-agents` | true | true | skill, prompt, provenance, council, git-rev, metadata, additive |
| T014 | `endpoint` | `devtools-cli` | true | false | python, yaml, parsing, comment-stripping, dequote, regression, non-regression, cli |
| T015 | `docs` | `ai-agents` | true | true | skill, prompt, trace-schema, gitignore, guard, orchestration, dispatch |
| T016 | `test` | `qa-automation` | true | false | quickstart, e2e, integration-gate, sc-mapping, validation, dogfood, manual-execution |
| T017 | `docs` | `general` | true | false | decision-log, docs-90, close-out, i-row, sign-off, fr-015 |
| T018 | `test` | `qa-automation` | true | false | verification, allowlist-guard, full-suite, regression, final-check, fr-015, bash, shell |

## Cap Check

`general 1 / total 18 (≤ max(1, ⌊0.20 × 18⌋) = 3)`

## Notes

- **No `graphify-type-signal.md` exists** for this feature (checked; not present in `specs/008-pre-public-maintenance/`). `type` was derived entirely from `tasks.md`'s own `files=`/`deps=`/`mutates=`/phase annotations and path convention, with no corroborating graph-grounded signal available — stated plainly per the instructions' honesty rule.

- **T002 / T007 / T011 (`test`, all touching `extensions/workforce/test/run.sh` or a fixture tree)**: the `test` derivation rule cites two conditions — path-under-`tests/` and "lands in an earlier wave than the task it covers." T007 satisfies both cleanly (Wave 3 fixtures precede the Wave 4 checker they validate). T002 (the FR-015 scope guard) and T011 (wiring fixture invocation + static/determinism guards) both satisfy the path/deliverable condition unambiguously — each is a verification artifact added to a `test/run.sh` harness — but the wave-ordering clause reads awkwardly for a scope guard that precedes essentially everything (T002) and for guard-wiring that necessarily follows what it verifies (T011, Wave 9, after T007–T010 in Waves 3–6). Classified both `test` on the strength of the path match and the "any verification artifact" deliverable definition, since no other type in the closed enum plausibly fits either task.

- **T012 vs. T014 (compound multi-file tasks)**: both touch a mix of files matching different type rules — an installer/manifest-style file matching `scaffold`'s explicit "extension.yml" / "installer script" examples, alongside a `test/run.sh` guard or fixture addition. T012's `.specify/extensions.yml` mirror resync and `install.sh` fix are each an explicit, primary, numbered sub-step in the task's own text, so `scaffold` dominates by both file-count and table order. T014's `.specify/extensions.yml` touch appears only in the task annotation line and the cross-task dependency note ("both edit graphify installed surfaces and contend on the `.specify/` installed mirror") — not as a primary described action within T014's own steps — so it was not weighted as decisive. T014's primary described work is the `augment_merge.py` parsing fix; inspection of the file confirms it is structurally a CLI script (`main(argv)`, `if __name__ == "__main__"`, `--emit`/`--merge` modes — the same shape as `check-conformance.py`), so `endpoint` was chosen ahead of `test` by table order. A different, also-defensible reading could classify T014 as `scaffold` (to match T012) or `service` (parsing/business logic) instead — flagging this pair as a genuine judgment call.

- **T013 / T015 (`SKILL.md` edits, `runtime_consumed: true`)**: `runtime_consumed` was set to `true` by extending the stated path examples (`*-prompt.md`, `deck-*.md`, a `templates/`/`prompts/` directory) to `SKILL.md` files — reasoning that a `SKILL.md` is loaded into an agent's context and followed as instructions at runtime (the same mechanism this categorizer session itself was dispatched under), matching the general principle ("loaded or rendered by an agent at runtime … rather than only read by a human") even though `SKILL.md` is not one of the literal named examples. Flagging this as an interpretive extension of the rule, not a literal-example match — worth confirming at the next taxonomy review.

- **T016 / T018 (`files=(none)`)**: typed `test` from the deliverable definition ("Any verification artifact" — a quickstart integration-gate execution and a final full-suite/allowlist re-verification, respectively) rather than from any `files=`/path signal, since neither task has one. This is the only place in this run where `type` was derived from description alone.

- **`preserves_behavior` on files=(none) tasks (T001, T016, T018)**: marked `true` vacuously — no `files=` path fails the "already exists" check and no new public surface is added, because none exists to check. Noted so the vacuous basis is visible rather than implied as a substantive judgment.
