# Contract — Task Taxonomy · **v1.0 — BLESSED 2026-07-12**

> **Status:** v1.0 — **BLESSED 2026-07-12.** Reviewed and amended per `docs/reviews/2026-07-12-taxonomy-v1-review.md` (the three-feature dogfood review — 001/002/003 categorized); verdicts logged as **D65** (taxonomy v1, verdicts 1–10), **D66** (gap-batching economics), **D67** (workforce auto-mode + grant tripwire). The v0→v1 trigger (§8) is met and this file is now normative at v1.
> **Renamed from `taxonomy-v0.md` (D65).** The `git mv` to `taxonomy.md` drops the version from the filename — the header carries the version now. References to the old `taxonomy-v0.md` name inside *frozen* history (the `2026-07-09` review memo, the `taxonomy-v0-evidence.md` dossier, completed-feature artifacts under `specs/`, and superseded docs/90 D-rows) are preserved as written — history is not rewritten; live consumers (the `docs/contracts/` set, the workforce extension source, docs/00, docs/05) were swept to `taxonomy.md`.
> **History (v0):** blessed 2026-07-09 per `docs/reviews/2026-07-09-taxonomy-v0-review.md`; satisfied the M0 exit criterion (docs/95 Part 3). The v0 verdicts (8 types, 11 specializations, the `general` cap) were logged as **D42**.
> **Implements:** D16 (hybrid: fixed core + free tags), D36, **D40** (composability), **D41** (tool grants), **D42** (v0 OQ verdicts, 8×11 cardinality, `general` cap), **D65** (v1 blessing: §1 derivability amendment, the `runtime_consumed` modifier §2.4, the floor'd `general` cap §4), **D67** (workforce auto-mode standalone + grant tripwire — see `profile-schema.md` P4).
> **Blocks:** M3 (categorize + skill builder). `agent-library-schema.md` §6 rule 5 treats these as closed enums.
> **Grounded in:** graphify's `speckit-tasks-graph` skill and its `examples/tasks-with-waves.example.md`, both now at `extensions/graphify/`.

Every task carries exactly one `type`, exactly one `specialization`, the boolean modifier `preserves_behavior` (§2.3), the boolean modifier `runtime_consumed` (§2.4), and any number of free `tags`. The pair `(type, specialization)` deterministically selects the **base specialist**; the two boolean modifiers ride orthogonal to type (one injects the `refactor-discipline` skill, the other pins the Sonnet floor); `tags` rank and select the **skill modules** injected on top of the base (D40, `agent-library-schema.md` §3).

---

## 1. Why two axes — the asymmetry that justifies them

`speckit-tasks-graph` annotates every task with exactly this, and nothing more:

```
- T014  files=src/services/svc.ts   deps=T012,T013   mutates=src/services/svc.ts
```

plus its phase (`Setup` / `Foundational` / `User Story N` / `Polish`), its story, its `[P]` marker, and its position in the TDD chain (*tests → models → services → endpoints*).

Read that list carefully and a hard fact falls out:

> **`type` is graph-derived *where the graph covers the files*; `specialization` is not — graphify's task model is stack-agnostic.**

### §1 amendment (v1, D65 verdict 6) — derivability, stated honestly

The v0 draft claimed `type` is *mechanical* full stop. Three dogfood features (001/002/003) proved the honest version: `type` is graph-derived **for the files graphify emits nodes for**, and falls back to a **documented path convention** for the ones it doesn't. graphify emits no nodes for `.sh` / `.yml` (and treats `.md` prompt/template files as opaque), so on the pipeline-plumbing features that dominated v0→v1 the `type` was assigned by **file-path convention + the derivation rules applied by inspection** — e.g. `install.sh` → `scaffold`, `assemble.py` → `service`, `agt_*.md` / `SKILL.md` → `docs` by the `*.md`-outside-`specs/` rule. That is still *the same derivation rules keyed off the same signals*; it is only the **source of the signal** (a path convention, not a graph node) that changes. The categorizer-prompt already instructs this fallback explicitly ("fall back to the task's own description and any file paths it names, apply the same rules by inspection, and say so plainly").

Extending graphify's extractor to emit nodes/edges for `.sh` / `.yml` / `.md` — so those types graph-ground too — is a **graphify enhancement (I-13)**, carried on the graphify backlog, **not a taxonomy patch**: the taxonomy's derivation rules are unchanged; only their input coverage widens. Until then, a `type` derived by path convention on an uncovered file is labeled *convention-derived*, not *graph-grounded* — the same "engineer assertion, not graph fact" honesty the deck-grounding rule (I-13) already enforces.

A `files=src/services/svc.ts` with `deps=` on a data-model task is a **service** task in any language on earth. Nothing in graphify's output says whether it is Python or Go, whether it touches auth, or whether it needs someone who understands query planners. That knowledge lives in `plan.md` (the declared stack) and in the spec's domain.

So the two axes are not a tidy 2×2 imposed on the problem. They are the two *sources of evidence* the categorizer has:

| Axis | Derived from | Character |
|---|---|---|
| `type` | graphify's `files=` / `deps=` / `mutates=` / phase / TDD position **where the graph covers the file**; a documented path convention otherwise (§1 amendment, D65) | mechanical + verifiable on covered files; convention-derived (still cheap, still by rule) on `.sh`/`.yml`/`.md` (I-13) |
| `specialization` | `plan.md`'s stack + path conventions + spec domain | interpretive, needs judgment |

That is also why a Sonnet categorizer suffices (D18): one axis is a lookup, the other is a shallow inference over a document that already states the answer.

## 2. Type — 8 values

| `type` | The task's deliverable | Derivation rule (graphify signals) |
|---|---|---|
| `scaffold` | Project structure, dependencies, tooling config | Phase 1 `Setup`; `files=` in build/tooling config (`package.json`, `tsconfig.json`, `pyproject.toml`) |
| `data-model` | Schema, migrations, types, entities | `files=` under schema/model/types/migrations paths; **first link** of the TDD chain; `deps=-` or deps only on `scaffold` |
| `service` | Domain logic, business operations | `files=` in a service/domain layer; `deps=` on a `data-model` task |
| `endpoint` | External surface: HTTP routes, RPC handlers, CLI commands, MCP tools | `files=` in a route/handler manifest; `deps=` on a `service` task |
| `ui` | User-facing components and views | `files=` under components/views/pages |
| `test` | Any verification artifact | `files=` under `tests/` or matching `*.test.*`/`*_test.*`; lands in an **earlier wave** than the task it covers |
| `docs` | Documentation | `files=` under `docs/`, or `*.md` outside `specs/` |
| `infra` | CI, containers, deployment manifests | `files=` under `.github/`, `Dockerfile`, IaC paths |

**Every rule keys off something graphify actually emits.** That is the acceptance test for a type: if you cannot write its derivation rule against `files=` / `deps=` / `mutates=` / phase / TDD position, it is not a type.

### 2.1 Why there is no `integration` type

The obvious tenth candidate — "wire the new unit into the shared manifest" — is deliberately absent. `speckit-implement-parallel` (step 4) assigns that work to the **orchestrator**, not to a subagent:

> *"Integrate any shared-file edits the wave implies … this is legitimate orchestrator glue and must happen in the orchestrator, never in two parallel subagents."*

Pure shared-manifest wiring is therefore **not a task**, and a type that no task can hold is dead schema. It would also have quietly broken the library: an `integration` specialist would be a specialist for work no subagent is ever dispatched to do.

The near miss is instructive. In graphify's own example, `T011 POST /searches endpoint wiring in src/api/routes.ts` has `files=src/api/routes.ts` and mutates a shared file — yet it *is* a task, because it delivers a handler, not merely a registration. It is `type: endpoint`, scheduled serially. **Type describes the deliverable; scheduling describes the collision risk.** Keeping them apart is what lets `[P]` stay a graph property.

> **Categorizer note (v1, D65 verdict 3) — `endpoint` is the deliverable; body flavor rides in tags.** The `endpoint`↔`service` "body fusion" flagged across 001/002/003 (a slash command or MCP tool whose deliverable is a command surface but whose *body* orchestrates service-like work) is **upheld as-is: type = deliverable.** A `/speckit-*` slash command, an MCP tool handler, a CLI subcommand — its deliverable is an external invocation surface, so it is **`type: endpoint`**, full stop. That its body does orchestration/service work is real signal, but it belongs in the **free tags** (`orchestration`, `dispatch`, …) where it selects skills — not in the type, which would collapse the "what is delivered" axis into "what the body happens to do." This was the actual 001 practice (three `endpoint × ai-agents` command skills, all tagged `orchestration`) and stays the rule; no `endpoint`/`service` split, no new type.

### 2.2 What is *not* taxonomy

`[P]`, wave membership, and `mutates=` are **scheduling**, not classification. They never enter the matching key. They do constrain the roster in one way — a task whose `mutates=` hits the shared/mutable list can only be assigned an agent, never inlined as orchestrator glue, and vice versa — but that is an assignment guard (M3), not a taxonomy key.

### 2.3 The `preserves_behavior` modifier (OQ1 — OVERRULED, D42)

`refactor` was drafted as a ninth type. **It is not a type; it is a modifier**, orthogonal to type. "Refactor the search service" already has a type — `service` — and burying that under `(refactor, backend-service)` destroys the information that it *is* service work.

Every task therefore carries a boolean `preserves_behavior`, whose derivation rule is the one `refactor` used to own, verbatim:

> **`preserves_behavior` is true when every file in `files=` already exists in the graph (`mutates=` has no `(new)`) and the task adds no new public surface.**

Like `type`, it is derivable from what graphify emits — so it belongs to the mechanical axis and costs the categorizer nothing.

**Consequence (D40).** The requirement that motivated `refactor` — that this work needs a *differently disciplined* agent, one careful about blast radius and adding no public surface — is met by composition rather than by a type. `preserves_behavior: true` **auto-injects the `refactor-discipline` skill module** at assembly (`skill-module.md`; `agent-library-schema.md` §3). The discipline arrives as a skill on top of the right base specialist, instead of replacing that base specialist with a generic one.

The auto-injection counts against the assembly cap of 3 injected skills (D40).

`preserves_behavior: true` tasks remain **implementation tasks** (§3): they run the base specialist for their `type`, which is never `docs`.

### 2.4 The `runtime_consumed` modifier (v1, D65 verdict 10 — promoted from the `prompt` tag / D48)

`prompt` was, through v0, a free *tag* that the D48 guard keyed on: a prompt/deck template is mechanically `type: docs` (a `*.md` file outside `specs/`, §2's rule), and §3 lets a `docs`-only specialist take any model D18 permits — so, absent a guard, a prompt-authoring task could route to a non-Sonnet docs specialist and escape the D18 Sonnet floor. D48 patched that with a **tag-convention check** (a `prompt`-tagged task must assemble onto a Sonnet implementation base).

Three real prompt-tagged tasks later (001 booked it; 003 ran three — the categorizer prompt, the skill-builder prompt, the deck-prep template), the honest fix is **promotion**, per §6's own rule: *a tag that gates the fixed core has earned promotion to the fixed core.* `prompt` was gating assignment. So it becomes a **boolean modifier**, `runtime_consumed`, orthogonal to `type` exactly as `preserves_behavior` is (the OQ1 modifier-over-type precedent, §2.3):

> **`runtime_consumed` is true when the file the task delivers is *loaded or rendered by an agent at runtime*** — a system prompt some session later dispatches (a categorizer / skill-builder / council-member / chairman / deck-prep template), a prompt fragment an agent renders, or any asset consumed by a model at run time rather than only read by a human. Otherwise `false`.
>
> **Derivation (categorizer, §categorizer-prompt):** *path/consumption heuristics* — a `*-prompt.md` / deck template / dispatched-system-prompt path — **with a tag fallback**: a task carrying the legacy `prompt` free tag sets `runtime_consumed: true`. The `prompt` tag survives as a *detection hint and a tag-selection signal*, no longer as the gate.

**Structural consequences (why this is a modifier, not a note):**

1. **The docs-only model exemption (§3) is inapplicable.** A `runtime_consumed: true` task is implementation work regardless of its mechanical `docs` type — authoring a dispatched prompt is `ai-agents` implementation wearing a `docs` type. It runs an **implementation specialist under the D18 Sonnet floor**, never a docs-exempt non-Sonnet base.
2. **The D18 Sonnet floor self-enforces.** The guard is now *the modifier's* enforcement, not a tag convention: the assembler (`assemble.py` / `agent-library-schema.md` §4) rejects a `runtime_consumed: true` task assembled onto a non-Sonnet base. This is the old D48 guard, re-homed on the modifier — **D48 becomes this modifier's enforcement** (`assemble.py` retired the `"prompt" in tags` check for the `runtime_consumed` check).
3. **It injects no skill and does not touch the assembly cap.** Unlike `preserves_behavior` (which force-injects `refactor-discipline`, §2.3), `runtime_consumed` only pins the model floor. It changes *which base is legal*, never *what is injected*.

Like `type` and `preserves_behavior`, it belongs to the mechanical axis — path convention + the tag fallback decide it, so it costs the categorizer nothing beyond setting one more boolean correctly.

## 3. Implementation types

`agent-library-schema.md` §4 enforces `model: sonnet` for base specialists that accept **implementation types**. Those are the 7:

```
scaffold · data-model · service · endpoint · ui · test · infra
```

i.e. everything but `docs`. A `docs`-only specialist may take any model D18 permits — **with one carve-out (v1, D65 §2.4): a `runtime_consumed: true` task never routes to a non-Sonnet docs specialist.** Even though such a task is mechanically `type: docs`, the file it delivers is consumed by an agent at runtime, so it is implementation work and holds the D18 Sonnet floor (the re-homed D48 guard). The `docs`-model exemption applies only to genuinely human-read documentation — `runtime_consumed: false` docs.

`preserves_behavior: true` does not change this. A behavior-preserving `service` task is still an implementation task on the `service` base specialist — it merely arrives with the `refactor-discipline` skill injected (§2.3).

## 4. Specialization — 10 values (+ 1 escape hatch)

Exactly one per task: *the expertise that dominates*. Not the only expertise involved.

| `specialization` | Lane |
|---|---|
| `frontend-web` | Browsers, DOM, component frameworks, client state |
| `mobile` | iOS, Android, React Native, Flutter |
| `backend-service` | Server-side application logic, frameworks, request lifecycle |
| `data-persistence` | Databases, ORMs, migrations, query performance |
| `infra-platform` | Cloud, containers, IaC, CI/CD |
| `security` | AuthN/AuthZ, crypto, secrets, attack surface |
| `performance` | Profiling, caching, concurrency, memory |
| `ai-agents` | LLMs, prompts, agent orchestration, MCP |
| `devtools-cli` | CLIs, build tooling, codegen, editor/agent extensions |
| `qa-automation` | Test harnesses, fixtures, e2e drivers |
| `general` | **Escape hatch.** No lane dominates. Guarantees no base-specialist match → routes to the skill builder. **Capped — see below.** |

### The `general` cap (OQ3 — upheld with a cap, D42; floor adopted v1, D65 verdict 9)

`general` is the honest answer when no lane dominates, and it stays. But it is also the answer a lazy categorizer gives to everything, so it is bounded:

> **At most `max(1, ⌊0.2·n⌋)` of a feature's `n` tasks may be specialized `general`. A categorization that exceeds the cap FAILS and must be redone with better evidence.**
>
> Formally: `count(general) ≤ max(1, ⌊0.2 × count(tasks)⌋)`.

Failure is not a warning. `categorization.md` is not written, the phase does not complete, and — by the resumability rule (`artifact-layout.md` §3) — the pipeline stops at categorize until a run produces a conforming artifact. The cap is a floor on evidence, not a style preference: a feature whose tasks genuinely resist classification is telling you the plan is underspecified, and that is worth stopping for.

**The one-task floor (adopted v1, D65 verdict 9).** For a feature with `n ≥ 5`, `⌊0.2·n⌋ ≥ 1` and the `max(1, …)` is inert — the cap is the same 20% it always was (001 ran `general` 0/23, 003 ran 0/32; both far under). The floor changes exactly one case: a feature with **fewer than 5 tasks**, where `⌊0.2·n⌋ = 0`. Under v0's literal 20% cap (D44) that admitted **zero** `general` tasks — a formal absurdity (a 3-task feature with one genuinely-cross-cutting task would be forced to mis-specialize it or fail). v0 recorded `max(1, ⌊0.2·n⌋)` as an *unadopted* candidate pending real small-feature data; the v1 review **adopts it on evidence** (the two large dogfood features never approached the cap, so the floor costs the cap nothing where it bites, and it deletes the absurdity before M4 — an S-sized feature — meets the edge). A ≤4-task feature now admits **exactly one** `general` task, no more: `general ≤ 1` there, and `general ≤ ⌊0.2·n⌋` everywhere `n ≥ 5`.

`validate-categorization.py` computes this by exact integer arithmetic — `limit = max(1, total // 5)`, breach iff `count(general) > limit` — so there is no floating-point boundary drift, and the n<5 floor falls out directly.

Deliberately **not** specializations, because they duplicate a type: `api-contract` (that is `type: endpoint`), `technical-writing` (that is `type: docs`), `testing` (that is `type: test`). A specialization that names the same thing as a type collapses the two axes and makes the matching key a single axis wearing two hats.

`qa-automation` survives that test because it means *harness expertise*, not *writing tests*: `(scaffold × qa-automation)` = "stand up Playwright" is real, and distinct from `(test × backend-service)` = "unit-test the search service."

## 5. Worked example — graphify's own `tasks.md`

Every task from `extensions/graphify/examples/tasks-with-waves.example.md`, tagged. This is the draft's evidence: the taxonomy was fitted to real output, not to intuition.

| Task | Description | `type` | `specialization` | `tags` |
|---|---|---|---|---|
| T001 | `saved_searches` table + migration | `data-model` | `data-persistence` | `sql`, `migration` |
| T002 | `SavedSearch` type in `types/search.ts` | `data-model` | `backend-service` | `typescript` |
| T003 | Extend `services/search.ts` | `service` | `backend-service` | `typescript` |
| T010 | Unit tests for `saveSearch` | `test` | `backend-service` | `unit`, `typescript` |
| T011 | `POST /searches` wiring | `endpoint` | `backend-service` | `http`, `rest` |
| T012 | "Save this search" button | `ui` | `frontend-web` | `react`, `tsx` |
| T020 | Unit tests for `listSavedSearches` | `test` | `backend-service` | `unit`, `typescript` |
| T021 | `GET /searches` wiring | `endpoint` | `backend-service` | `http`, `rest` |
| T022 | Saved-search dropdown | `ui` | `frontend-web` | `react`, `tsx` |
| T030 | Integration test, save → list | `test` | `qa-automation` | `integration`, `e2e` |

Every task above has `preserves_behavior: false` — all ten create new surface — and `runtime_consumed: false` (§2.4): none delivers a dispatched-at-runtime prompt asset. Both modifiers are unexercised here; see the risk note below.

Observations worth keeping:

- **Every task tagged unambiguously**, with one exception (T030), settled by OQ4 and re-opened at v0→v1.
- The example exercises **5 of 8 types** and **4 of 11 specializations**. `scaffold`, `docs`, `infra`, seven specializations, and both modifier `true` branches (`preserves_behavior`, `runtime_consumed`) are unexercised by it. They are argued from the derivation rules, not demonstrated. **That remains the taxonomy's chief risk** — an unexercised enum value is a guess, and blessing does not make it evidence. (v1 update: the three dogfood features exercised `docs`/`scaffold`/`infra` and, for `runtime_consumed`, three real prompt-asset tasks in 003 — but `preserves_behavior: true` is *still* unexercised; §7 OQ1/verdict 4.)
- The `(type, specialization)` pairs cluster hard: 4 of 10 tasks are `× backend-service`. Under D40 this matters more, not less: a base specialist covers a lane, and skills cover the variation *within* it. This table is the first evidence that a small set of lanes plus composable skills covers a typical feature.
- `T011`/`T021` share a type *and* a specialization *and* a file. They assemble to the same base specialist and are still serialized. Taxonomy and scheduling stayed orthogonal, as §2.1 claimed.

## 6. Free tags (D16)

Lowercase kebab-case, unbounded, unvalidated. They carry the nuance the fixed core deliberately drops: language, framework, protocol, sub-domain. Under D40 they do **three** jobs and no others:

1. **Rank** candidate skill modules (Jaccard overlap — `agent-library-schema.md` §3).
2. **Brief** the skill builder when matching returns ∅ — a task tagged `python, fastapi, rate-limiting` tells the builder far more than `(endpoint, backend-service)` ever could.
3. **Select** the skill modules injected onto the base specialist at assembly time (D40, `skill-module.md`). *This is the third job, added by the review memo (§3.1).*

Job 3 is what recovers the cross-cutting signal OQ2 gave up. "Add rate limiting to `POST /searches`" is still `(endpoint, backend-service)` — one specialization, matching stays deterministic — but its `rate-limiting` and `security` tags inject the skills that carry the security knowledge. **The signal was never lost; it moved from the matching key to the assembly.**

Tags **never** widen or narrow the *base* match. If a tag ever needs to, it has earned promotion to the fixed core, and that is a schema change with a D-row.

## 7. Open questions — **all six resolved**

Resolved by Babu, 2026-07-09. The normative record is `docs/reviews/2026-07-09-taxonomy-v0-review.md` §2; the verdicts are logged as **D42**. **v1 dispositions** (the three-feature review, `docs/reviews/2026-07-12-taxonomy-v1-review.md`, logged as **D65**) are appended inline below to the rows they touch — OQ4 (verdict 1), OQ6 (verdict 2), OQ1/`preserves_behavior` (verdict 4), OQ3 (verdict 9, the cap floor).

| # | Question | Verdict | Where it landed |
|---|---|---|---|
| **OQ1** | Is `refactor` a type, or a modifier? | **OVERRULED** — modifier | `refactor` deleted from the type enum (9 → **8 types**); `preserves_behavior` added as a boolean carrying the old derivation rule verbatim, auto-injecting the `refactor-discipline` skill (§2.3, D40). **v1 (D65 verdict 4): `preserves_behavior` retained as a marked hypothesis** — zero refactor tasks across three greenfield dogfood features (003 is 32/32 `false`), so the `true` branch and its `refactor-discipline` auto-injection remain unexercised on real output; ships on argument, revisited when a refactor-heavy feature lands. |
| **OQ2** | One specialization, or `primary` + `secondary[]`? | **Upheld** — exactly one | Cross-cutting signal recovered by tag→skill injection (§6 job 3), not by `secondary[]`. Matching stays deterministic (D40) |
| **OQ3** | Does `general` defeat the point? | **Upheld, cap adopted** | `general` stays; capped, over-cap categorization **fails** (§4). **v1 (D65 verdict 9): the cap gains a one-task floor** — `count(general) ≤ max(1, ⌊0.2·n⌋)`, adopting v0's recorded candidate on evidence (§4). Inert for `n ≥ 5`; admits exactly one `general` for a <5-task feature. |
| **OQ4** | Is `T030` `qa-automation` or `backend-service`? | **Upheld** — `qa-automation` | Scope-based boundary accepted for v0; re-examined at v0→v1. **v1 (D65 verdict 1): upheld unchanged** — the scope-based `test × qa-automation` vs `test × backend-service` boundary was applied consistently across all three features (both sides exercised); the "softest boundary" concern never materialized. Note: every v0→v1 call was a *human* hand-categorization; the first *machine* (categorizer-session) test of the boundary is M4+. |
| **OQ5** | Merge `scaffold` and `infra`? | **Upheld** — separate | Composability removed the cost that motivated merging: near-empty *skill* lanes are cheap; near-empty *agent* lanes were not (D40) |
| **OQ6** | Do `ai-agents` / `devtools-cli` belong in a general taxonomy? | **Upheld** — both stay | Dogfooding is decisive; the per-repo library (D17) contains the overfit; v0→v1 re-tests it. **v1 (D65 verdict 2): retained, caveat carried** — dogfood evidence *cannot* acquit the overfit (all three features ARE SpecSeyal's own tooling, so `devtools-cli`/`ai-agents` dominate by construction); explicitly **untested until the first non-SpecSeyal install** (post-α). The per-repo library (D17) still contains the risk. |

**Resulting cardinality: 8 types × 11 specializations**, `general` capped (with the v1 one-task floor, §4). v1 adds a **second boolean modifier** — `runtime_consumed` (§2.4) beside `preserves_behavior` (§2.3) — both orthogonal to the `(type, specialization)` matching key.

The draft argued OQ1 and OQ2 were the hardest to change after M3 because `agent-library-schema.md` §3 hard-coded their shape. OQ1 was overruled *before* M3, at zero cost. OQ2 was upheld — but D40 changed the reason it holds: determinism survives not because one specialization is enough to describe a task, but because the parts it cannot describe now live in the skills, where they compose.

## 8. Change process

This file is a closed enum with two hard consumers (`agent-library-schema.md` §3 matching, §6 rule 5 validation). Changing it is therefore not an edit:

1. Adding a value → a D-row in docs/90, plus a derivation rule (types) or a lane definition (specializations).
2. Removing or renaming a value → a **major** version bump on every library entry that used it (`agent-library-schema.md` §2), because those entries now match different tasks.
3. Promoting a free tag to the fixed core → §6's rule. A D-row. **First exercised at v1 (D65 verdict 10):** the `prompt` free tag, having gated assignment through the D48 guard, was promoted to the `runtime_consumed` boolean modifier (§2.4) — the textbook case this rule anticipated.

**v0 → v1 is done (2026-07-12, D65).** The trigger — the first three real dogfood features categorized (001/002/003), the enum tested against work that isn't graphify's own example — was met, and the review (`docs/reviews/2026-07-12-taxonomy-v1-review.md`) blessed v1 with the amendments applied throughout this file.

**v1 → v2 trigger (set by D65 §8):** the **first non-SpecSeyal repo categorized, or M5 close, whichever comes first.** The rationale is verdict 2's caveat: the whole v0→v1 window was SpecSeyal's own tooling, so the two axes' overfit risk (`ai-agents`/`devtools-cli`, OQ6) and the categorizer-session-vs-human boundary questions (OQ4) can only be falsified by a repo that isn't this one — or, failing that, by the M5 milestone boundary, whichever arrives first. Until then, every value still unexercised on non-dogfood work remains a hypothesis, honestly labeled.

**Carried items — dispositions after the v0→v1 review (D65):**

| # | Item | v1 disposition |
|---|---|---|
| 1 | **OQ4** — the `test × qa-automation` vs `test × backend-service` boundary, decided by test *scope* (memo §2) | **Upheld unchanged** (verdict 1) — applied consistently ×3; carried to v2 only as "first *machine*-drawn boundary is M4+". |
| 2 | **OQ6** — whether `ai-agents` / `devtools-cli` survive a repo that is not SpecSeyal (memo §2) | **Retained, caveat carried** (verdict 2) — untestable on dogfood; re-tested at the v1→v2 trigger (first non-SpecSeyal repo). |
| 3 | **Small-feature `general`-cap edge (Flag 2, D44).** v0's literal 20% cap admits **zero** `general` for `n < 5`. | **Resolved — floor adopted** (verdict 9): `count(general) ≤ max(1, ⌊0.2·n⌋)` (§4). |
| 4 | `preserves_behavior: true` unexercised by §5's worked example — `refactor-discipline` auto-injection never fired on real output | **Retained as a marked hypothesis** (verdict 4) — still 0 exercise three features in (003 is 32/32 `false`); ships on argument, revisited when a refactor-heavy feature lands. |
| 5 | Whether the assembly cap of 3 injected skills (D40) binds in practice, and what the assignment step drops | **Retained** — the cap was *reached* once (003 T008: exactly 3 injected, 0 dropped); the trim path stays exercised only by the SC-004 golden fixture. Carried; no change. |
| 6 | **Prompt-asset type question** (D48 — a `prompt-asset` type vs a runtime-consumed `docs` carve-out) | **Resolved — modifier** (verdict 10): promoted the `prompt` tag to the `runtime_consumed` modifier (§2.4); no new type. |
| 7 | **`docs × devtools-cli` empty lane** (I-15 — no seed base accepts `docs` in the `devtools-cli` lane) | **Resolved — widen the base** (verdict 7): `agt_devtools_cli` now accepts `docs` (base config edit authorized by this D-row; D17/Flag-3). |
