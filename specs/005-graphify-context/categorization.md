# Categorization — 005-graphify-context

> **Source binding (S14):** derived from `tasks.md @ 4f6f740` (36 tasks).

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | bash, posix, test-harness, fixture |
| T002 | `scaffold` | `devtools-cli` | false | false | bash, posix, test-harness, fixture |
| T003 | `scaffold` | `devtools-cli` | false | false | bash, posix, shell-idiom, scripts |
| T004 | `docs` | `ai-agents` | false | true | prompt, markdown, graph, provenance, contract, skill |
| T005 | `test` | `qa-automation` | false | false | fixture, golden, bash, yaml, arm1 |
| T006 | `test` | `qa-automation` | false | false | fixture, golden, fallback, bash, yaml, arm1 |
| T007 | `test` | `qa-automation` | false | false | fixture, golden, messy-pattern, bash, arm1 |
| T008 | `endpoint` | `devtools-cli` | false | false | bash, python, graph, deterministic, coverage, edges |
| T009 | `endpoint` | `devtools-cli` | false | false | bash, cli, graph, ambiguous-match, guard |
| T010 | `docs` | `ai-agents` | false | true | prompt, deck, citation, council, markdown |
| T011 | `test` | `qa-automation` | false | false | fixture, freshness, golden, staleness |
| T012 | `test` | `qa-automation` | false | false | fixture, equivalence, refresh, golden |
| T013 | `test` | `qa-automation` | false | false | fixture, survivor-guard, negative-path, golden |
| T014 | `test` | `qa-automation` | false | false | fixture, composition, cross-arm, golden |
| T015 | `endpoint` | `devtools-cli` | false | false | bash, freshness, graph, staleness, provenance |
| T016 | `endpoint` | `devtools-cli` | false | false | bash, refresh, incremental, survivor-guard, graph |
| T017 | `scaffold` | `devtools-cli` | false | false | version-pin, manifest, preventive-check, graphifyy |
| T018 | `test` | `qa-automation` | false | false | fixture, golden, tiered-products, arm3 |
| T019 | `test` | `qa-automation` | false | false | fixture, coherence, provenance, golden, arm3 |
| T020 | `docs` | `ai-agents` | false | true | prompt, graph, tiered-products, skill, provenance |
| T021 | `docs` | `ai-agents` | false | true | prompt, deck, deck-prep, receipts, markdown |
| T022 | `docs` | `ai-agents` | false | true | prompt, categorizer, type-signal, markdown |
| T023 | `docs` | `ai-agents` | false | false | trace, schema, contract, council-member, query-ceiling |
| T024 | `test` | `qa-automation` | false | false | fixture, ceiling, council, trace, disclosure |
| T025 | `test` | `qa-automation` | false | false | fixture, no-ceiling, council, trace, disclosure, inverse |
| T026 | `scaffold` | `ai-agents` | false | false | yaml, config, council, query-ceiling, tier-aware |
| T027 | `docs` | `ai-agents` | false | true | prompt, council, query-ceiling, disclosure, markdown |
| T028 | `docs` | `ai-agents` | false | false | orchestration, dispatch, ceiling-enforcement, council, trace, markdown |
| T029 | `test` | `qa-automation` | false | false | fixture, consumer, non-regression, plan, golden |
| T030 | `test` | `qa-automation` | false | false | fixture, consumer, non-regression, tasks-graph, golden |
| T031 | `test` | `qa-automation` | false | false | fixture, consumer, non-regression, implement-parallel, golden |
| T032 | `test` | `qa-automation` | false | false | fixture, consumer, non-regression, categorizer, golden |
| T033 | `test` | `qa-automation` | false | false | fixture, consumer, non-regression, deck-prep, golden |
| T034 | `test` | `qa-automation` | false | false | fixture, severability, detach, golden, non-regression |
| T035 | `test` | `devtools-cli` | false | false | bash, reinstall, install, idempotent, harness, survival |
| T036 | `test` | `qa-automation` | true | false | quickstart, e2e, validation, dogfood, sc-mapping, integration-gate |

## Cap Check

`general 0 / total 36 (≤ max(1, ⌊0.20 × 36⌋) = 7)`

### Distributions

- **type** (8-value enum): `scaffold` 5 (T001,T002,T003,T017,T026) · `docs` 8 (T004,T010,T020,T021,T022,T023,T027,T028) · `endpoint` 4 (T008,T009,T015,T016) · `test` 19 (T005–T007,T011–T014,T018,T019,T024,T025,T029–T036) · `data-model` 0 · `service` 0 · `ui` 0 · `infra` 0.
- **specialization** (11-value enum): `devtools-cli` 9 (T001,T002,T003,T008,T009,T015,T016,T017,T035) · `ai-agents` 9 (T004,T010,T020,T021,T022,T023,T026,T027,T028) · `qa-automation` 18 (all fixture/golden/consumer/quickstart tasks) · `general` 0.
- **`preserves_behavior`**: false ×35, true ×1 (T036 only — `mutates=-`, a read-only quickstart execution; every other task either creates a new file or adds a new field/instruction/product/config-key/stage to an existing one).
- **`runtime_consumed`**: true ×6 (T004, T010, T020, T021, T022, T027 — the shared-provenance/generator SKILL.md and the deck/member/categorizer prompt templates), false ×30. All six carry the `prompt` tag as the Step-3 hint; `runtime_consumed` is the load-bearing gate per D65.

### Notes for the reviewer

- **`endpoint`, not `service`, for the four mechanical scripts (T008 `augment.sh`, T009 `explain-guard.sh`, T015 `freshness.sh`, T016 `refresh.sh`).** Each is a named, directly-invoked CLI primitive with its own exit-code contract in `contracts/commands.md` (the `commit.sh`/`verify-gate.sh` idiom plan.md itself cites) — this mirrors how `004-testing-completion` typed `verify-gate.sh`/`commit.sh` `endpoint` rather than `service` for exactly this reason (a hook-fired command surface, regardless of how much logic lives inside). `deps=` on these four tasks names test tasks rather than a `service` task, so the derivation table's dependency clause doesn't literally fire — the path/contract signal (named CLI command, `contracts/commands.md` entry) is what settles it, consistent with the `002`/`004` precedent.
- **`devtools-cli` vs `qa-automation` split inside "testing" work.** T001/T002 (scaffolding the `test/run.sh` harness itself) and T035 (adding the harness's reinstall-survival stage) are `devtools-cli` — building/extending the harness is CLI/build tooling. Every task whose deliverable is fixture *content* (goldens, consumer fixtures, ceiling fixtures) is `qa-automation` — harness-and-fixture expertise, not harness-*construction* expertise. T036 (the full `quickstart.md` validation run) is `qa-automation`, matching how `002`, `003`, and `004` each typed their own final quickstart-validation task.
- **`ai-agents` cluster tracks the D65 `runtime_consumed` cluster closely but not exactly.** T023 (trace-schema fields for `council-member`) and T026 (`council-config.yml` `query_ceiling`) and T028 (orchestrator enforcement logic) are `ai-agents` by domain content (LLM query-ceiling/observability) but `runtime_consumed: false` — a schema, a YAML config, and the orchestrator's own control-flow are not themselves dispatched as another session's system prompt, unlike T004/T010/T020/T021/T022/T027.
- **`scaffold` for T026 (`council-config.yml`)** follows `001-council-extension`'s own precedent for the identical file (config/manifest edits match the `extension.yml`-style "build/tooling config" clause regardless of phase), even though its content (`member.query_ceiling`) is `ai-agents`-flavored — `type` stays mechanical/path-driven, `specialization` is the interpretive axis.
- **No `general` was needed.** The plan's four-arm structure (arm 1/2 mechanical scripts, arm 3 generator + prompt lockstep, arm 4 council config/prompt/orchestrator, plus the fixture layer common to all) gave every task a dominating lane on the first pass; none was written `general` to fill room, and none was forced off `general` to dodge the cap.
