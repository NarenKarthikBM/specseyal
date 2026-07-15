# Categorization — 006-deck-render

> **Source binding (S14):** derived from `tasks.md @ 7134c87` (37 tasks). `tasks.md` had no uncommitted
> local changes at read time (`git status --short` empty).

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `scaffold` | `devtools-cli` | false | false | extension, scaffold, monorepo, tree, readme |
| T002 | `scaffold` | `devtools-cli` | false | false | yaml, manifest, extension, hooks |
| T003 | `scaffold` | `devtools-cli` | false | false | bash, install, idempotent, flock, atomic-write, shell |
| T004 | `scaffold` | `devtools-cli` | false | false | bash, uninstall, idempotent, deregister, shell |
| T005 | `scaffold` | `devtools-cli` | false | false | command, cli, markdown, deck-render |
| T006 | `scaffold` | `devtools-cli` | false | false | skill, wrapper, shell-out, cli |
| T007 | `scaffold` | `devtools-cli` | true | false | gitignore, config |
| T008 | `scaffold` | `devtools-cli` | false | false | contract, schema, yaml, enum, profile |
| T009 | `scaffold` | `devtools-cli` | false | false | contract, schema, artifact-layout, docs |
| T010 | `scaffold` | `devtools-cli` | false | false | yaml, config, fixture, profile |
| T011 | `scaffold` | `devtools-cli` | false | false | contract, schema, exit-codes, reconciliation, docs |
| T012 | `scaffold` | `devtools-cli` | true | false | decision-log, docs, idempotent |
| T013 | `service` | `devtools-cli` | false | false | python, markdown, parser, stdlib, block-model |
| T014 | `service` | `devtools-cli` | false | false | python, yaml, enum, validation, ssot |
| T015 | `service` | `devtools-cli` | false | false | python, pptx, transform, atomic-write, stamp, sha256, determinism |
| T016 | `test` | `qa-automation` | false | false | python, ooxml, zipfile, xml, test-infra, fixture |
| T017 | `test` | `qa-automation` | false | false | bash, shell, posix, test-harness, fixtures |
| T018 | `test` | `qa-automation` | false | false | fixture, golden, markdown, non-regression |
| T019 | `test` | `qa-automation` | true | false | test, fidelity, ooxml, bash |
| T020 | `test` | `qa-automation` | true | false | test, sha256, stamp, bash |
| T021 | `test` | `qa-automation` | true | false | test, overflow, continuation, fixture, bash |
| T022 | `test` | `qa-automation` | false | false | fixture, yaml, enum, profile |
| T023 | `test` | `qa-automation` | true | false | test, bash, default-path, profile |
| T024 | `test` | `qa-automation` | true | false | test, bash, validation, enum |
| T025 | `test` | `qa-automation` | true | false | test, bash, override, profile |
| T026 | `test` | `qa-automation` | true | false | test, bash, ssot, drift, enum |
| T027 | `test` | `qa-automation` | false | false | fixture, broken, non-regression |
| T028 | `test` | `qa-automation` | true | false | test, bash, importerror, degrade, pythonpath |
| T029 | `test` | `qa-automation` | true | false | test, bash, partial-failure, exit-code, isolation |
| T030 | `test` | `qa-automation` | true | false | test, bash, atomic, mid-write, os-replace |
| T031 | `test` | `qa-automation` | true | false | test, bash, staleness, sha256, stale |
| T032 | `test` | `qa-automation` | true | false | test, bash, boundary, grep, git-ls-files |
| T033 | `test` | `qa-automation` | true | false | test, bash, cost, traces, zero-token |
| T034 | `test` | `qa-automation` | true | false | test, bash, reinstall, install, idempotent, survival |
| T035 | `test` | `qa-automation` | true | false | test, bash, co-install, extensions-yml, merge |
| T036 | `test` | `qa-automation` | false | false | quickstart, dogfood, e2e |
| T037 | `test` | `qa-automation` | true | false | quickstart, e2e, integration-gate, sc-mapping, validation, dogfood |

## Cap Check

`general 0 / total 37 (≤ max(1, ⌊0.20 × 37⌋) = 7)`

## Notes for the human reviewer

**Type distribution** (8-value enum): `scaffold` 12 · `service` 3 · `test` 22 · (`data-model` 0, `endpoint` 0,
`ui` 0, `docs` 0, `infra` 0). All in-enum.

- **T001–T012 (Phase 1, "Setup" heading) are all `scaffold`.** Per taxonomy §2's own derivation rule,
  "Phase heading is `Setup`" is a standalone, sufficient signal for `scaffold` — checked first, before
  the `docs` rule (7th) would otherwise have caught the `*.md`-outside-`specs/` files (T005, T008, T009,
  T011 partially, T012). This mirrors `003-workforce`'s own precedent categorization, where all three of
  its Setup-phase tasks were `scaffold` regardless of file content, while non-Setup `*.md` tasks (its
  T006/T007/T010/T022/T023/T030/T031) correctly fell to `docs`. `006` has no non-Setup, non-`test` task at
  all, so `docs` never fires here — a real, if unusual, consequence of this feature having zero
  agent/prompt-authoring surface and folding every remaining contract-doc edit into the Setup wave.
- **T013–T015 are `service`**, not `data-model`, despite `deps=-` on T013/T014: neither script's `files=`
  sits under a schema/model/types/migrations path (they're under `extension/scripts/`), so the
  `data-model` rule's primary path criterion never matches — same reasoning `003-workforce` applied to its
  own `extension/scripts/*.py` foundational modules (all typed `service`, zero `data-model` tasks there
  either).
- **T016–T037 are uniformly `test`**, including T036 (a dogfood render execution, no file under `tests/`)
  and T037 (a quickstart walkthrough, `mutates=-`). Both match the `003-workforce` precedent exactly: its
  own SC-009 dogfood/quickstart task (T032) was categorized `test`/`qa-automation` despite an identical
  file-path mismatch (`specs/003-workforce/quickstart.md`, not under `tests/`) — "Any verification
  artifact" is the deliverable, and the path check is the typical, not the sole, signal.

**Specialization distribution** (11-value enum): `devtools-cli` 15 · `qa-automation` 22 · `general` 0. All
in-enum. No `ai-agents` task exists in this feature — a deliberate consequence of the plan's own framing
("model-free ⇒ trace-free ⇒ free… No session is dispatched at all," Constitution Check Principle II). T005
(command file) and T006 (`SKILL.md` wrapper) were the closest candidates for `ai-agents`, but the task
text itself disclaims model involvement ("invokes no model," FR-011/R9) and neither file is dispatched as
*another session's* system prompt (the pattern that earned `003`'s categorizer-prompt/skill-builder-prompt/
deck-prep-template tasks their `ai-agents` lane and `prompt` tag) — both are read by the *same* orchestrating
session as command/skill instructions, not dispatched to a new one. They stay `devtools-cli`. No
`frontend-web`/`mobile`/`backend-service`/`data-persistence`/`infra-platform`/`security`/`performance` task
exists either — expected for a self-contained, model-free, stdlib-only CLI extension with no server,
database, cloud, or auth surface.

**`runtime_consumed`: all 37 `false`.** No task in this feature authors a file that becomes a dispatched
session's system prompt or an agent-rendered template — the feature's entire premise is that it dispatches
*no* session at all. T005/T006 were checked most carefully against this modifier (see above) and both
resolve `false`: nothing here is "a prompt fragment an agent renders" or "a system prompt some later
session dispatches" in the sense the modifier targets. No task carries the `prompt` tag, correctly, since
none is that kind of asset.

**`preserves_behavior`:** 12 `true` / 25 `false`. The `true` set splits into two shapes: (a) pure additive,
non-contract edits to a pre-existing file with no new schema/table/flag/key (T007 `.gitignore`, T012 the
decision-log append), and (b) the sixteen `test/run.sh` *section* tasks (T019–T021, T023–T026, T028–T035,
T037) — each mutates an already-scaffolded file (`run.sh`, created new by T017) and adds only internal test
assertions, never a new exported symbol/route/table/CLI-flag/config-key of the extension itself. The
`false` set is every task whose `mutates=` carries `(new)` (T001–T006, T013–T018, T022, T027, T036) plus
three existing-file edits that *do* add new documented contract surface: **T008** (adds the `deck_render`
config key to the profile schema), **T009** (adds a new `renders/` path + writer-ownership table row to
`artifact-layout.md`), **T010** (adds the literal new `deck_render: none` key to the sample fixture), and
**T011** (adds the two previously-unmapped `both` exit-code table outcomes and rewrites the write-semantics
contract) — all four are genuinely new specified behavior, not internal refinement, so `refactor-discipline`
correctly does not auto-inject on them.
