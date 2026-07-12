# Categorization — 004-testing-completion

> **Source binding (S14):** derived from `tasks.md @ 9601bcd` (19 tasks).

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | bash, install, uninstall, extension-scaffold, packaging, idempotent |
| T002 | `scaffold` | `devtools-cli` | false | false | yaml, config, manifest, extension, commands, model-config |
| T003 | `endpoint` | `security` | false | false | bash, git, gate, fail-closed, checkbox-delta, freshness, audit-log |
| T004 | `endpoint` | `devtools-cli` | false | false | bash, git, commit, enum, phase-tag, seam |
| T005 | `scaffold` | `devtools-cli` | false | false | yaml, hooks, extension-manifest, git, seam |
| T006 | `test` | `qa-automation` | false | false | bash, test, regression, checkbox-delta, reinstall-survival, fixtures |
| T007 | `test` | `qa-automation` | false | false | bash, test, regression, reinstall-survival, commit-seam, fixtures |
| T008 | `test` | `qa-automation` | false | false | bash, install, reinstall, git, pre-flight, survival-regression |
| T009 | `docs` | `devtools-cli` | false | false | contract, frontmatter, status-enum, completion-report, d19-event, appendix |
| T010 | `endpoint` | `devtools-cli` | false | false | command, skill, re-read-from-disk, phase-boundary, single-artifact |
| T011 | `docs` | `devtools-cli` | false | true | template, completion-report, skeleton, appendix |
| T012 | `docs` | `ai-agents` | false | false | contract, coverage-map, sc-fr-mapping, executed-none, gap-honesty |
| T013 | `endpoint` | `ai-agents` | false | false | command, skill, dispatch, sonnet, tester, trace |
| T014 | `docs` | `ai-agents` | false | true | prompt, sonnet, tester, verification-approach, lazy-grounding, doc-only |
| T015 | `docs` | `ai-agents` | false | true | template, testing-skeleton, trace-record, frontmatter |
| T016 | `test` | `qa-automation` | false | false | bash, validator, coverage, golden-fixture, contract-validation, round-trip |
| T017 | `docs` | `devtools-cli` | false | false | contract, ownership, artifact-layout, governance |
| T018 | `test` | `qa-automation` | false | false | install, reinstall, extension, round-trip, contract-validation |
| T019 | `test` | `qa-automation` | true | false | quickstart, e2e, validation, dogfood, sc-mapping |

## Cap Check

`general 0 / total 19 (≤ max(1, ⌊0.20 × 19⌋) = 3)`

### Distribution

**type:** `scaffold` 3 (T001,T002,T005) · `endpoint` 4 (T003,T004,T010,T013) · `docs` 6 (T009,T011,T012,T014,T015,T017) · `test` 6 (T006,T007,T008,T016,T018,T019) · `data-model` 0 · `service` 0 · `ui` 0 · `infra` 0.

**specialization:** `devtools-cli` 8 · `qa-automation` 6 · `ai-agents` 4 · `security` 1 (T003) · `general` 0.

### Notes for the reviewer

- **T003/T004 (`endpoint`, not `service`).** `verify-gate.sh` and `commit.sh` are each an existing `speckit.git.*` CLI-command primitive (the extension's directly hook-fired surface), so edits to them stay `endpoint` regardless of the edit's internal scope — consistent with how `002-speckit-ext-git` typed these same two files when it authored them. `T005` (`extension.yml`) is `scaffold` per the taxonomy's own explicit `extension.yml` example, independent of its non-`Setup` phase heading.
- **T008/T018 (`test`, not `scaffold`/`infra`).** Both are "reinstall, then run the harness and confirm green" checkpoints; the file targets (`.specify/extensions/**`, `.specify/extensions.yml`) are deployed/registry state rather than authored tooling config, and the task's dominant act is verification — mirrors `003-workforce`'s own "install + confirm harness green" tasks, which resolved to `test`.
- **`ai-agents` vs `devtools-cli` split across the two phases.** `/speckit-complete` (T010) runs in main with no new model role and its contract/template (T009/T011) cluster with it as `devtools-cli`; `/speckit-testing` (T013) dispatches a separate Sonnet `tester` session, so it and its contract/prompt/templates (T012/T014/T015) cluster as `ai-agents`. T017 (a two-row edit to the cross-cutting `artifact-layout.md` ownership table, touching both artifacts) stays `devtools-cli` — neither phase dominates a shared registry file.
- **`runtime_consumed: true`** fires on exactly the three `extensions/testing/extension/templates/*.md` assets (T011, T014, T015) — the completion-report skeleton, the tester's dispatched system prompt, and the testing.md skeleton + trace fragment. T009/T012/T017 stay `false` as the taxonomy's own explicit "a contract... a human reads it" example. Only T014 carries the free `prompt` tag (the literal dispatched-session asset); T011/T015 are output skeletons an authoring session renders into, not a system prompt a session is dispatched with.
- **T019 is the sole `preserves_behavior: true`.** It is annotated `mutates=-` (read-only quickstart validation) — every other existing-file edit in this feature (T003–T008, T017, T018) adds new behavior, a new enum value, a new hook/config entry, new test coverage, or newly-live capability, so all resolve `false`.
