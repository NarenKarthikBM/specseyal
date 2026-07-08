# Contract — Task Taxonomy v0 · **DRAFT, AWAITING REVIEW**

> **Status:** 0.1 — **DRAFT. Not normative until Babu blesses it** (docs/95, M0 exit criteria).
> **Implements:** D16 (hybrid: fixed core + free tags), D36.
> **Blocks:** M3 (categorize + agent creator). `agent-library-schema.md` §6 rule 5 treats these as closed enums.
> **Grounded in:** graphify's `speckit-tasks-graph` skill and its `examples/tasks-with-waves.example.md`, both now at `extensions/graphify/`.

Every task carries exactly one `type`, exactly one `specialization`, and any number of free `tags`. The pair `(type, specialization)` is the deterministic matching key against the agent library; `tags` rank the candidates and brief the gap generator (D16, `agent-library-schema.md` §3).

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

## 2. Type — 9 values

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
| `refactor` | Behavior-preserving change to existing code | **every** file in `files=` already exists in the graph (`mutates=` has no `(new)`) **and** the task adds no new public surface |

**Every rule keys off something graphify actually emits.** That is the acceptance test for a type: if you cannot write its derivation rule against `files=` / `deps=` / `mutates=` / phase / TDD position, it is not a type.

### 2.1 Why there is no `integration` type

The obvious tenth candidate — "wire the new unit into the shared manifest" — is deliberately absent. `speckit-implement-parallel` (step 4) assigns that work to the **orchestrator**, not to a subagent:

> *"Integrate any shared-file edits the wave implies … this is legitimate orchestrator glue and must happen in the orchestrator, never in two parallel subagents."*

Pure shared-manifest wiring is therefore **not a task**, and a type that no task can hold is dead schema. It would also have quietly broken the library: an `integration` specialist would be a specialist for work no subagent is ever dispatched to do.

The near miss is instructive. In graphify's own example, `T011 POST /searches endpoint wiring in src/api/routes.ts` has `files=src/api/routes.ts` and mutates a shared file — yet it *is* a task, because it delivers a handler, not merely a registration. It is `type: endpoint`, scheduled serially. **Type describes the deliverable; scheduling describes the collision risk.** Keeping them apart is what lets `[P]` stay a graph property.

### 2.2 What is *not* taxonomy

`[P]`, wave membership, and `mutates=` are **scheduling**, not classification. They never enter the matching key. They do constrain the roster in one way — a task whose `mutates=` hits the shared/mutable list can only be assigned an agent, never inlined as orchestrator glue, and vice versa — but that is an assignment guard (M3), not a taxonomy key.

## 3. Implementation types

`agent-library-schema.md` §4 enforces `model: sonnet` for library specialists that accept **implementation types**. Those are:

```
scaffold · data-model · service · endpoint · ui · test · infra · refactor
```

i.e. everything but `docs`. A `docs`-only specialist may take any model D18 permits.

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
| `general` | **Escape hatch.** No lane dominates. Guarantees no library match → routes to the gap generator. |

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

Observations worth the reviewer's attention:

- **Every task tagged unambiguously**, with one exception argued in OQ4 below (T030).
- The example exercises **5 of 9 types** and **4 of 11 specializations**. `scaffold`, `docs`, `infra`, `refactor` and six specializations are unexercised by it. They are argued from the derivation rules, not demonstrated. **That is the draft's chief risk** — an unexercised enum value is a guess.
- The `(type, specialization)` pairs cluster hard: 4 of 10 tasks are `× backend-service`. A seed library of 5–6 specialists (docs/05, M3) therefore covers a typical feature — which is the assumption M3's whole cost model rests on, and this table is the first evidence for it.
- `T011`/`T021` share a type *and* a specialization *and* a file. They get the same specialist and are still serialized. Taxonomy and scheduling stayed orthogonal, as §2.1 claimed.

## 6. Free tags (D16)

Lowercase kebab-case, unbounded, unvalidated. They carry the nuance the fixed core deliberately drops: language, framework, protocol, sub-domain. They do two jobs and no others:

1. **Rank** tied library candidates (Jaccard overlap — `agent-library-schema.md` §3).
2. **Brief** the gap generator when matching returns ∅ — a task tagged `python, fastapi, rate-limiting` tells the generator far more than `(endpoint, backend-service)` ever could.

Tags **never** widen or narrow a match. If a tag ever needs to, it has earned promotion to the fixed core, and that is a schema change with a D-row.

## 7. Open questions for review

The six places I made a call that could reasonably go the other way. **OQ1 and OQ2 are the ones I would most like overruled if you disagree** — they are the hardest to change after M3 ships, because `agent-library-schema.md` §3 hard-codes their shape.

| # | Question | My call | The case against |
|---|---|---|---|
| **OQ1** | Is `refactor` a **type**, or a **modifier** orthogonal to type? | Type. Its derivation rule is crisp (`mutates=` all non-new, no new surface) and it needs a genuinely different agent — one disciplined about blast radius and adding no public surface. | "Refactor the search service" has an obvious type already: `service`. Making it a type means the pair `(refactor, backend-service)` loses the information that it *is* service work. The alternative: drop `refactor`, add a boolean `preserves_behavior`. **8 types instead of 9.** |
| **OQ2** | One specialization per task, or `primary` + `secondary[]`? | Exactly one. Determinism is the reason the fixed core exists at all. | "Add rate limiting to `POST /searches`" is honestly `security` *and* `backend-service`. Forcing one loses real signal — though `tags: [rate-limiting]` recovers most of it, and set-overlap matching is a strictly bigger change than it looks. |
| **OQ3** | Does `general` defeat the point? | Keep it. Every task must be taggable, and `general` is an *honest* "no lane dominates" that routes straight to the gap generator (D2) rather than forcing a bad match. | It is an invitation to a lazy categorizer. Mitigation if you want one: cap `general` at, say, 20% of a feature's tasks and fail categorization above that. |
| **OQ4** | `T030` — is a cross-cutting integration test `qa-automation` or `backend-service`? | `qa-automation`. Unit tests need domain knowledge; e2e tests need harness knowledge. | The boundary is the softest in the table, and it is decided by test *scope*, not by anything graphify emits — so it violates §1's "type is mechanical" spirit, one axis over. |
| **OQ5** | Merge `scaffold` and `infra`? | Keep separate. Adding a `tsconfig` path and authoring a GitHub Actions matrix are different jobs for different agents. | Both are "config files nobody wants to write." Merging gives **8 types** and one fewer near-empty library lane. |
| **OQ6** | Do `ai-agents` and `devtools-cli` belong in a *general* taxonomy? | Keep. SpecSeyal dogfoods on itself from M1 (CLAUDE.md), so **its own tasks** are overwhelmingly `(service|docs|test) × (ai-agents|devtools-cli)`. Without these two, the very first real run tags everything `general`. | They are here because of *this* repo, not because of a survey of repos. That is a legitimate charge of overfitting — mitigated only by the fact that the library is per-repo (D17) and the taxonomy is v0. |

Cardinality if you take every "against": **8 types × 10 specializations**. Cardinality as drafted: **9 × 11**.

## 8. Change process

This file is a closed enum with two hard consumers (`agent-library-schema.md` §3 matching, §6 rule 5 validation). Changing it is therefore not an edit:

1. Adding a value → a D-row in docs/90, plus a derivation rule (types) or a lane definition (specializations).
2. Removing or renaming a value → a **major** version bump on every library entry that used it (`agent-library-schema.md` §2), because those entries now match different tasks.
3. Promoting a free tag to the fixed core → §6's rule. A D-row.

v0 → v1 happens when the first three real dogfood features are categorized and the enum has been tested against work that isn't graphify's own example. Until then, every value not exercised in §5 is a hypothesis.
