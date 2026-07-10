# Categorization — 003-workforce

> **By-hand bootstrap (grandfathered, S28).** `003` *builds* the categorizer (`/speckit-categorize`)
> and its `validate-categorization.py`, so those tools do not yet exist to categorize `003` itself —
> this file is written by hand against **taxonomy v0 (BLESSED)**, exactly as `001`/`002` hand-categorized
> before M3 shipped the tool. The last manual pass; the feature builds its replacement.
>
> **Source binding (S14):** derived from `tasks.md @ d37a846` (32 tasks). If `tasks.md` moves, re-categorize.

## Categorization table

| task_id | type | specialization | preserves_behavior | tags |
|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | extension, scaffold, monorepo, tree |
| T002 | `scaffold` | `devtools-cli` | false | yaml, manifest, hooks, extension, commands |
| T003 | `scaffold` | `devtools-cli` | false | yaml, config, caps |
| T004 | `service` | `devtools-cli` | false | python, yaml, parser, frontmatter |
| T005 | `test` | `devtools-cli` | false | python, unit, pytest |
| T006 | `docs` | `ai-agents` | false | agent, library, sonnet, frontmatter |
| T007 | `docs` | `ai-agents` | false | skill, library, additive, frontmatter |
| T008 | `scaffold` | `devtools-cli` | false | bash, install, idempotent, flock, hooks, deregister |
| T009 | `scaffold` | `devtools-cli` | false | bash, uninstall, deregister |
| T010 | `docs` | `ai-agents` | false | **prompt**, categorizer, taxonomy, sonnet |
| T011 | `service` | `devtools-cli` | false | python, validation, enum, cap |
| T012 | `endpoint` | `ai-agents` | false | command, categorizer, orchestration, dispatch, sonnet |
| T013 | `test` | `qa-automation` | false | test, fixtures, bash, cap |
| T014 | `service` | `devtools-cli` | false | python, matching, jaccard, determinism, assembly |
| T015 | `docs` | `ai-agents` | false | template, roster, workforce-gate, markdown |
| T016 | `endpoint` | `ai-agents` | false | command, assembler, orchestration, dispatch, sonnet |
| T017 | `endpoint` | `devtools-cli` | false | command, gate, approve, hooks |
| T018 | `service` | `security` | false | bash, gate, binding, git, shell |
| T019 | `scaffold` | `devtools-cli` | false | yaml, hooks, gate, git, manifest |
| T020 | `test` | `qa-automation` | false | test, reinstall, survival, install, bash, gate |
| T021 | `test` | `qa-automation` | false | test, golden, determinism, fixtures, bash |
| T022 | `docs` | `ai-agents` | false | **prompt**, skill-builder, **web-search**, sonnet, stale-risk |
| T023 | `docs` | `ai-agents` | false | template, skill-module, markdown, frontmatter |
| T024 | `service` | `security` | false | python, validation, additive-only, grants, security |
| T025 | `service` | `ai-agents` | false | orchestration, skill-builder, dispatch, flywheel, **web-search** |
| T026 | `test` | `qa-automation` | false | test, fixtures, additive-only, dedup, bash |
| T027 | `service` | `ai-agents` | false | traces, dispatch, orchestration, grants, web-search |
| T028 | `test` | `qa-automation` | false | test, trace, roster, diff, bash |
| T029 | `test` | `qa-automation` | false | test, harness, ci, bash, install |
| T030 | `docs` | `ai-agents` | false | **prompt**, deck-prep, council, sonnet, transcript-mining |
| T031 | `docs` | `devtools-cli` | false | docs, readme, markdown |
| T032 | `test` | `qa-automation` | false | test, dogfood, e2e, quickstart |

## Cap Check

`general 0 / total 32 (≤ 0.20 × 32 = 6)` → **PASS** (0 ≤ 6). No task fell to the escape hatch; every lane is evidence-backed.

**Type distribution** (8-value enum): `scaffold` 6 · `service` 7 · `endpoint` 3 · `docs` 8 · `test` 8 · (`data-model` 0, `ui` 0, `infra` 0). All in-enum.

**Specialization distribution** (11-value enum): `devtools-cli` 12 · `ai-agents` 11 · `qa-automation` 7 · `security` 2 · `general` 0. All in-enum. (No `frontend-web`/`mobile`/`backend-service`/`data-persistence`/`infra-platform`/`performance` — a pipeline-extension build, as expected.)

**`preserves_behavior`:** all 32 `false` — `003` is a greenfield build (every task creates new files or adds public surface: the git-ext generalization T018/T019, the command edits T025/T027, and the deck-prep enrichment T030 all *add* surface). **No `refactor-discipline` auto-injection on any `003` task** — correct: this is a build, not a refactor.

## D48 guard — checked

The `prompt`-tagged tasks are **T010** (categorizer-prompt), **T022** (skill-builder-prompt), **T030** (deck-prep template). Each is mechanically `type: docs` (`*.md` outside `specs/`) but is **implementation prompt-authoring** (`ai-agents`), so the D48 guard applies: each MUST assemble onto an implementation specialist under the **D18 Sonnet floor**, never a docs-exempt non-Sonnet base. All three route to **`agt_ai_agents`** (the only seed base accepting `docs`, and `model: sonnet`) — **D48 satisfied by construction**. There is **no** non-Sonnet base in the seed library, so the guard's error branch is unexercised here (it is exercised by the SC-006 synthetic-fixture test, T021/S03).
