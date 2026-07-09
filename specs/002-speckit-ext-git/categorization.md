# Categorization — speckit-ext-git (taxonomy v0)

> **Manual pass (M3 phase run by hand).** The categorize extension ships in M3; until then this artifact is written by hand — exactly as `001` hand-wrote its own (artifact-layout §8 bootstrap note). Categorized against **`docs/contracts/taxonomy-v0.md` (v0 — BLESSED, normative)**: every task carries exactly one `type` (of 8), one `specialization` (of 10 + `general`), the boolean `preserves_behavior`, and free `tags`. The pair `(type, specialization)` selects the base specialist; `tags` select injected skills.
>
> **Input**: `tasks.md` (23 tasks) + `plan.md` (declared stack). **Owner**: categorize phase — this file only (D37). **Reads/writes no other artifact.**

## Method caveat — `type` is NOT graph-derived here (I-13 / R1-S22)

Taxonomy §1 rests on an asymmetry: **`type` is mechanically derivable from graphify's `files=`/`deps=`/`mutates=`/phase/TDD signals; `specialization` is interpretive.** That asymmetry **does not hold for this feature**: `graphify explain`/`path` return **"No node matching"** for `.sh`/`.yml` (I-13, filed R1-S22), so the graph emits **no signals** for 21 of 23 tasks. Here **both axes are engineer judgment** — `type` re-derived by reading `plan.md`/`tasks.md` (the primitive's command surface, the file's role), not by a graphify read. This is booked as evidence for the taxonomy §8 v0→v1 review: v0's "cheap mechanical `type`" claim degrades to judgment on a pipeline-plumbing feature whose files the graph doesn't cover.

## Task categorization

| Task | Deliverable | `type` | `specialization` | `preserves_behavior` | `tags` |
|---|---|---|---|---|---|
| T001 | `extensions/git/` skeleton | `scaffold` | `devtools-cli` | false | `shell`, `extension-scaffold`, `packaging` |
| T002 | `git-config.yml` | `scaffold` | `devtools-cli` | false | `yaml`, `config`, `git` |
| T003 | provenance command stubs (`.md`) | `docs` | `devtools-cli` | false | `provenance`, `command-stub` |
| T004 | READMEs | `docs` | `devtools-cli` | false | `readme`, `packaging` |
| T005 | `extension.yml` hook manifest | `scaffold` | `devtools-cli` | false | `yaml`, `hooks`, `manifest` |
| T006 | `install.sh` (hook-merge, R1-S15) | `infra` | `devtools-cli` | false | `installer`, `yaml-merge`, `hooks`, `idempotent` |
| T007 | `uninstall.sh` (R1-S26a) | `infra` | `devtools-cli` | false | `uninstaller`, `deregister`, `hooks` |
| T008 | `branch.sh` (ensure-branch, flock) | `service` | `devtools-cli` | false | `git`, `branch`, `flock`, `idempotent` |
| T009 | `commit.sh` (`speckit.git.commit`) | `endpoint` | `devtools-cli` | false | `git`, `commit`, `staging-scope` |
| T010 | edit `speckit-implement-parallel` (per-wave commit) | `endpoint` | `ai-agents` | false | `git`, `orchestration`, `wave-commit`, `resumability` |
| T011 | `sha.sh` (`speckit.git.sha`) | `endpoint` | `devtools-cli` | false | `git`, `sha`, `read-only` |
| T012 | `gates.sh` (`gates.yml` bindings I/O) | `service` | `security` | false | `authorization`, `bindings`, `yaml`, `integrity` |
| T013 | `verify-gate.sh` (`speckit.git.verify-gate`) | `endpoint` | `security` | false | `authorization`, `fail-closed`, `working-tree`, `hard-block` |
| T014 | `on-council-approve.sh` (SHA-record hook) | `service` | `security` | false | `authorization`, `hook`, `signer-agnostic`, `reinstall-survive` |
| T015 | edit `speckit-tasks`+`speckit-implement` (stop-on-nonzero) | `endpoint` | `devtools-cli` | false | `hooks`, `enforcement`, `stop-on-nonzero` |
| T016 | `cleanup.sh` (`speckit.git.cleanup`) | `endpoint` | `devtools-cli` | false | `git`, `merge`, `tag`, `conflict-abort` |
| T017 | `speckit-git-cleanup` skill | `endpoint` | `devtools-cli` | false | `skill`, `human-command`, `git` |
| T018 | wave-worktree spike (finding) | `infra` | `ai-agents` | false | `spike`, `worktree`, `isolation`, `parallel`, `firewalled` |
| T019 | regenerate `graphify-context.md` (manifest fix) | `docs` | `devtools-cli` | *true (inert — docs)* | `graphify`, `manifest`, `blast-radius` |
| T020 | correct stale `before_specify` assertions | `docs` | `devtools-cli` | *true (inert — docs)* | `drift-fix`, `documentation` |
| T021 | `test/run.sh` (units + reinstall-survival) | `test` | `qa-automation` | false | `harness`, `regression`, `reinstall-survival`, `concurrency` |
| T022 | `before_specify` drift lint | `test` | `qa-automation` | false | `lint`, `conformance`, `drift` |
| T023 | quickstart SC validation run | `test` | `qa-automation` | false | `validation`, `existence-proof`, `e2e` |

## `general` cap check (D42/D44 — hard gate)

- `count(general)` = **0** of 23 tasks = **0%** ≤ 20% (`0.20 × 23 = 4.6` → ≤ 4 permitted). **PASS.** Every task resolved to a named lane; no lazy `general` fallback. The evidence floor holds — the plan is specific enough that each task has a dominating expertise.

## `preserves_behavior` note

**Zero `preserves_behavior: true` implementation tasks.** The two implementation-type edits to existing files — T010 (adds per-wave commit behavior) and T015 (adds stop-on-nonzero enforcement) — both **add new observable behavior**, so both derive `false`. T019/T020 mutate existing files with no new surface (mechanically `true`), but they are `docs` type, where the modifier is **inert** — a `docs` task is not an implementation task and injects no `refactor-discipline` skill (§2.3/§3). Net: the `refactor-discipline` auto-injection **never fires** for this feature — consistent with taxonomy §5's standing note that `preserves_behavior: true` is unexercised by real output so far (booked, §8 item 4).

## D48 prompt-tag guard — **NOT triggered (no prompt assets)**

Per instruction, checked whether any task authors a **prompt asset** (the D48 class: an LLM-rendered prompt/deck template mechanically typed `docs` that could route to a non-Sonnet docs specialist and escape the D18 implementation floor).

**Finding: no prompt assets appear in this feature, so the D48 guard is moot here.** `speckit-ext-git` is a **zero-AI mechanical-git extension (FR-007)** — its runtime makes no model calls and renders no template to any LLM. What it authors:

- shell scripts (mechanical git) — implementation, not prompts;
- YAML config/manifest (`git-config.yml`, `extension.yml`) — `scaffold`;
- `.md` **command-provenance stubs** (T003) and READMEs (T004) — `docs`, but **command/provenance metadata, not runtime-rendered LLM prompts**;
- one **command skill** (`speckit-git-cleanup`, T017) — typed `endpoint` (a CLI command surface), authored on the implementation floor already; it wraps mechanical git, orchestrates no model.

None is a runtime-rendered prompt/deck template, so **no task carries the `prompt` tag** and the D48 Sonnet-floor guard does not engage. *(Contrast `001-council-extension`, which authored member/chairman prompt templates + deck templates → `docs × ai-agents` + `prompt` tag → D48 fired there, Call 2. The guard exists precisely for that asset class, which this feature does not contain.)* The guard is recorded here as **checked and inapplicable**, not silently skipped.

## Distribution & readout

| Axis | Distribution |
|---|---|
| **type** | `endpoint` ×7 · `docs` ×4 · `scaffold` ×3 · `service` ×3 · `infra` ×3 · `test` ×3 · `data-model` ×0 · `ui` ×0 |
| **specialization** | `devtools-cli` ×15 · `security` ×3 · `qa-automation` ×3 · `ai-agents` ×2 · `general` ×0 |

**Reading**: a `devtools-cli`-dominant feature (a Spec Kit extension), with a coherent **`security` cluster** — the gate↔SHA integrity trio (T012/T013/T014, US3's "approval provably about unchanged content"), a two-task **`ai-agents`** touch (the `implement-parallel` per-wave edit + the concurrent-subagent-isolation spike), and a **`qa-automation`** test cluster (harness + lint + validation). No `data-model`/`ui` — the extension "holds no data of its own" (D32) and has no user-facing views. All seven implementation types present are on the **D18 Sonnet floor** (agent-library-schema §4); the four `docs` tasks are genuine documentation (any D18-permitted model).

## Booked for the taxonomy §8 v0→v1 review

1. **`type` un-derivable from the graph (I-13/R1-S22)** — v0's "mechanical, cheap `type`" claim degraded to judgment on this `.sh`/`.yml` feature. First non-`ai-agents`, non-web dogfood datapoint; the taxonomy was fitted to graphify's TS example (§5) — this stresses it against shell/YAML plumbing.
2. **Spike resists clean typing** — T018 (`infra × ai-agents`) is a P3 firewalled *experiment* whose deliverable is a finding, not a built unit; the deliverable-centric type model has no clean slot for "bounded experiment." Candidate v1 consideration.
3. **`preserves_behavior: true` still unexercised** (§8 item 4) — 002's edits all add behavior; the `refactor-discipline` path remains untested against real output.
4. **`security` as specialization for shell-implemented integrity** — T012/T013/T014 are `security` by *dominating expertise* (authorization/fail-closed/no-bypass), though implemented in POSIX `sh`; confirms §4's "expertise that dominates, not the language" reading.
