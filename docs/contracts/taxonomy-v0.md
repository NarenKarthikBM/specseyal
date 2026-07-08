# Contract — Task Taxonomy · **v0 — BLESSED (normative), 2026-07-09**

> **Status:** v0 — **BLESSED (normative), 2026-07-09.** Reviewed and amended per `docs/reviews/2026-07-09-taxonomy-v0-review.md`. The M0 exit criterion "taxonomy v0 reviewed and blessed by Babu" (docs/95 Part 3) is satisfied.
> **Implements:** D16 (hybrid: fixed core + free tags), D36, **D40** (composability), **D41** (tool grants), **D42** (OQ verdicts, 8×11 cardinality, `general` cap).
> **Blocks:** M3 (categorize + skill builder). `agent-library-schema.md` §6 rule 5 treats these as closed enums.
> **Grounded in:** graphify's `speckit-tasks-graph` skill and its `examples/tasks-with-waves.example.md`, both now at `extensions/graphify/`.

Every task carries exactly one `type`, exactly one `specialization`, the boolean modifier `preserves_behavior` (§2.3), and any number of free `tags`. The pair `(type, specialization)` deterministically selects the **base specialist**; `tags` rank and select the **skill modules** injected on top of it (D40, `agent-library-schema.md` §3).

---

## 1. Why two axes — the asymmetry that justifies them

`speckit-tasks-graph` annotates every task with exactly this, and nothing more:

```
- T014  files=src/services/svc.ts   deps=T012,T013   mutates=src/services/svc.ts
```

plus its phase (`Setup` / `Foundational` / `User Story N` / `Polish`), its story, its `[P]` marker, and its position in the TDD chain (*tests → models → services → endpoints*).

Read that list carefully and a hard fact falls out:

> **`type` is derivable from what graphify emits. `specialization` is not — graphify's task model is stack-agnostic.**

A `files=src/services/svc.ts` with `deps=` on a data-model task is a **service** task in any language on earth. Nothing in graphify's output says whether it is Python or Go, whether it touches auth, or whether it needs someone who understands query planners. That knowledge lives in `plan.md` (the declared stack) and in the spec's domain.

So the two axes are not a tidy 2×2 imposed on the problem. They are the two *sources of evidence* the categorizer has:

| Axis | Derived from | Character |
|---|---|---|
| `type` | graphify's `files=` / `deps=` / `mutates=` / phase / TDD position | mechanical, verifiable, cheap |
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

## 3. Implementation types

`agent-library-schema.md` §4 enforces `model: sonnet` for base specialists that accept **implementation types**. Those are the 7:

```
scaffold · data-model · service · endpoint · ui · test · infra
```

i.e. everything but `docs`. A `docs`-only specialist may take any model D18 permits.

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

### The `general` cap (OQ3 — upheld with a cap, D42)

`general` is the honest answer when no lane dominates, and it stays. But it is also the answer a lazy categorizer gives to everything, so it is bounded:

> **At most 20% of a feature's tasks may be specialized `general`. A categorization that exceeds the cap FAILS and must be redone with better evidence.**
>
> Formally: `count(general) ≤ 0.20 × count(tasks)`.

Failure is not a warning. `categorization.md` is not written, the phase does not complete, and — by the resumability rule (`artifact-layout.md` §3) — the pipeline stops at categorize until a run produces a conforming artifact. The cap is a floor on evidence, not a style preference: a feature whose tasks genuinely resist classification is telling you the plan is underspecified, and that is worth stopping for.

**Edge case, adjudicated (D44).** For a feature with fewer than 5 tasks, `0.20 × n < 1`, so the cap permits **zero** `general` tasks. This was flagged during application and ruled on: **the literal 20% cap stands for v0.** A one-task floor — `count(general) ≤ max(1, ⌊0.2·n⌋)` — is recorded as an *unadopted* v1 candidate in §8, to be decided against real small-feature data rather than invented now.

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

Every task above has `preserves_behavior: false` — all ten create new surface. The modifier is unexercised here; see the risk note below.

Observations worth keeping:

- **Every task tagged unambiguously**, with one exception (T030), settled by OQ4 and re-opened at v0→v1.
- The example exercises **5 of 8 types** and **4 of 11 specializations**. `scaffold`, `docs`, `infra`, seven specializations, and the `preserves_behavior: true` branch are unexercised by it. They are argued from the derivation rules, not demonstrated. **That remains the taxonomy's chief risk** — an unexercised enum value is a guess, and blessing does not make it evidence.
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

Resolved by Babu, 2026-07-09. The normative record is `docs/reviews/2026-07-09-taxonomy-v0-review.md` §2; the verdicts are logged as **D42**.

| # | Question | Verdict | Where it landed |
|---|---|---|---|
| **OQ1** | Is `refactor` a type, or a modifier? | **OVERRULED** — modifier | `refactor` deleted from the type enum (9 → **8 types**); `preserves_behavior` added as a boolean carrying the old derivation rule verbatim, auto-injecting the `refactor-discipline` skill (§2.3, D40) |
| **OQ2** | One specialization, or `primary` + `secondary[]`? | **Upheld** — exactly one | Cross-cutting signal recovered by tag→skill injection (§6 job 3), not by `secondary[]`. Matching stays deterministic (D40) |
| **OQ3** | Does `general` defeat the point? | **Upheld, cap adopted** | `general` stays; capped at 20% of a feature's tasks, over-cap categorization **fails** (§4) |
| **OQ4** | Is `T030` `qa-automation` or `backend-service`? | **Upheld** — `qa-automation` | Scope-based boundary accepted for v0; **explicitly re-examined at the v0→v1 three-feature review** (§8) |
| **OQ5** | Merge `scaffold` and `infra`? | **Upheld** — separate | Composability removed the cost that motivated merging: near-empty *skill* lanes are cheap; near-empty *agent* lanes were not (D40) |
| **OQ6** | Do `ai-agents` / `devtools-cli` belong in a general taxonomy? | **Upheld** — both stay | Dogfooding is decisive; the per-repo library (D17) contains the overfit; v0→v1 re-tests it (§8) |

**Resulting cardinality: 8 types × 11 specializations**, `general` capped.

The draft argued OQ1 and OQ2 were the hardest to change after M3 because `agent-library-schema.md` §3 hard-coded their shape. OQ1 was overruled *before* M3, at zero cost. OQ2 was upheld — but D40 changed the reason it holds: determinism survives not because one specialization is enough to describe a task, but because the parts it cannot describe now live in the skills, where they compose.

## 8. Change process

This file is a closed enum with two hard consumers (`agent-library-schema.md` §3 matching, §6 rule 5 validation). Changing it is therefore not an edit:

1. Adding a value → a D-row in docs/90, plus a derivation rule (types) or a lane definition (specializations).
2. Removing or renaming a value → a **major** version bump on every library entry that used it (`agent-library-schema.md` §2), because those entries now match different tasks.
3. Promoting a free tag to the fixed core → §6's rule. A D-row.

v0 → v1 happens when the first three real dogfood features are categorized and the enum has been tested against work that isn't graphify's own example. Until then, every value not exercised in §5 is a hypothesis.

**Carried to the v0→v1 review** (each booked by the 2026-07-09 memo or by applying it):

| # | Item |
|---|---|
| 1 | **OQ4** — the `test × qa-automation` vs `test × backend-service` boundary, decided by test *scope* rather than by anything graphify emits (memo §2) |
| 2 | **OQ6** — whether `ai-agents` and `devtools-cli` survive contact with a repo that is not SpecSeyal (memo §2) |
| 3 | **Small-feature edge (Flag 2, adjudicated D44).** The literal 20% cap admits **zero** `general` tasks when a feature has fewer than 5 (`0.20 × n < 1`, §4). The literal cap **stands for v0.** Candidate for v1, noted but **unadopted**: `count(general) ≤ max(1, ⌊0.2·n⌋)` — a one-task floor. Decide against real small-feature data, not in the abstract. |
| 4 | `preserves_behavior: true` is unexercised by §5's worked example, so the `refactor-discipline` auto-injection has never fired against real output |
| 5 | Whether the assembly cap of 3 injected skills (D40) binds in practice, and what the assignment step drops when it does |
