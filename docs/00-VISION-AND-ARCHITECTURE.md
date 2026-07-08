# SpecSeyal — Vision & Architecture

> **SpecSeyal** (செயல் — *seyal*, "action"): spec → action. Named 2026-07-08 (D30); GitHub and npm namespaces verified clean.
> **Status:** Living document. Last updated 2026-07-08.
> **Owner:** Babu · **Foundation:** [speckit-graphifyy](https://github.com/NarenKarthikBM/speckit-graphifyy) v0.1.0

---

## 1. What this is

A custom spec-driven development (SDD) workflow built on GitHub Spec Kit + a custom graphify layer, extended into a full governed pipeline — from spec to parallel implementation to testing — orchestrated eventually by an **Agent SDK-native GUI** for internal use.

Two layers, one contract:

| Layer | What it is | Interface |
|---|---|---|
| **Pipeline layer** | Speckit extensions running in Claude Code (CLI) | Slash commands + skills |
| **Platform layer** | Agent SDK orchestrator + web GUI + central manager | Spawns/drives sessions programmatically |
| **The contract** | **Artifacts** (spec.md, plan.md, suggestions.md, tasks.md, graph, reports) | Files in the repo — both layers read/write the same artifacts |

Because the Agent SDK can load the same skills and slash commands from `.claude/`, everything built CLI-first is directly reusable by the orchestrator. Nothing gets thrown away.

**Audience trajectory (D7):** built for Babu first, but deliberately headed to **work delivery teams and open source simultaneously**. The central manager tracks local changes across devices and users — which makes auth and multi-tenancy a platform-layer requirement (Q10), and makes decision records and docs public-grade artifacts from day one.

---

## 2. Core ideology

### Pipeline principles

1. **Context hygiene is a first-class design principle.** The main thread stays a lean orchestration spine. Heavy work — council review, task categorization, agent creation — runs in *separate sessions* and returns only compact artifacts to the main thread. (Already proven in `speckit-implement-parallel`'s wave-review pattern.)

2. **Plans must survive an adversarial defense before code exists.** After `/speckit-plan`, an agent prepares a presentation deck defending the plan (technical + non-technical versions), submits it to a **council** (llm-council methodology), collects synthesized suggestions, and loops back to revise. Human review is the final gate.

3. **Tasks aren't just parallelizable — they're specialized.** Beyond graph-verified `[P]` markers, tasks get categorized by *type × specialization*, feeding a **hybrid agent creator**: match against a library of specialists, generate bespoke agents for the gaps, persist good ones back (library flywheel).

4. **The loop doesn't end at implementation.** Implement → completion report → testing doc. A testing agent produces the doc now; runs tests later.

5. **Git is woven in, not bolted on.** A git extension branches *before* plan and manages the git lifecycle per feature. Plan revisions from council rounds live on the feature branch.

### Platform principles (added Round 1, 2026-07-08)

6. **Resumability.** Every phase is idempotent and resumable from artifacts. Kill the orchestrator mid-council; on restart it picks up where the artifacts say it stopped. Designed in from day one — never retrofitted.

7. **Observability.** Every session leaves a trace — transcript, token spend, duration, model used — synced to the central manager. The platform becomes a place to *learn* which agents and models earn their keep (feeds Q6 with real data). Cost stays a tracked metric inside observability, deliberately not a governing principle (D6).

8. **Non-technical-friendly UX.** The GUI must be usable by non-technical users — watching pipelines, reading non-technical decks, approving gates. UX is a principle, not a polish pass.

9. **Self-evolving, reproducible setup.** Setup is modular, reproducible, and AI-driven. **Year-one boundary (D24): the agent library is the only self-evolving component** — the flywheel. Self-tuning extension config and a self-regenerating wizard are explicitly out of scope until the library flywheel proves the pattern.

---

## 3. The extended workflow

```
                        MAIN THREAD                    SEPARATE SESSIONS
                        ───────────                    ─────────────────
  /speckit-specify ─┐
  /speckit-clarify  ├─ stock spec-kit
  git branch        │  (branch BEFORE plan)
  /speckit-plan ────┘
        │
        ▼
  ┌─ COUNCIL GATE ──────────────────────► deck prep session
  │   suggestions.md returned              council session (3-stage)
  │   ↻ loop to plan (max N rounds)        (see 10-COUNCIL-EXTENSION-SPEC.md)
  │   human review = final arbiter
  └───────┬──────────
          ▼
  /speckit-tasks ──────────────────────► categorization session
          │                                (type × specialization tags)
          ▼
  /speckit-analyze → remediation
          │   (severe findings reopen plan — D11)
          ▼
  agent assignment ────────────────────► agent-creator session
          │                                (library match + gap generation)
          ▼
  ┌─ WORKFORCE GATE ────────────────────  human approves tasks + agents
  │   gate-capable (D9), profile-controlled
  └───────┬──────────
          ▼
  /speckit-implement-parallel
    (graph-verified waves, per-wave review — EXISTS in v0.1.0)
          │
          ▼
  completion report → testing doc ─────► testing-agent session
                                           (doc-only for now)
```

**Session boundary rule:** each offloaded phase receives a minimal context package (the artifacts it needs) and returns exactly one artifact. The main thread never inherits an offloaded session's context.

**Autonomy profiles (D8):** every gate in the pipeline is configurable per feature — a feature declares its profile (which checkpoints require a human, which auto-proceed).

**Gate-capable checkpoints, v1 (D9):** exactly two — the **council gate** (post-plan) and the **workforce gate** (post-tasks + agent assignment, before implementation spends tokens). The council gate is default-on in every profile; skipping it requires an explicit full-auto profile. Spec/clarify and post-implement checkpoints are not gate-capable in v1.

**Remediation loop-back (D11):** severity-based. Routine `/speckit-analyze` findings patch tasks.md; **severe findings reopen the plan** — and since the plan was council-defended, a reopened plan raises the delta-review question (Q12, Round 3).

---

## 4. Component map

### 4.1 Pipeline extensions (CLI layer — build these first)

| Extension | Purpose | Status |
|---|---|---|
| `speckit-ext-graphify` | Dependency graph, verified `[P]`, execution waves | ✅ v0.1.0 shipped |
| `speckit-ext-council` | Plan defense deck + llm-council review + suggestion loop | 🔴 Priority #1 — spec in doc 10 |
| `speckit-ext-git` | Branch before plan, per-feature git lifecycle | 🟡 Small, prereq for council loop |
| `speckit-ext-categorize` | Task tagging by type × specialization | ⚪ Feeds agent creator |
| `speckit-ext-agents` | Hybrid agent creator/assigner (library + generated) | ⚪ Pairs with categorize |
| `speckit-ext-testing` | Testing agent → testing doc (doc-only v1) | ⚪ |

### 4.2 Platform layer (Agent SDK — the two "Big Tasks")

| Component | Purpose |
|---|---|
| **Orchestrator core** | Agent SDK app running the pipeline as a state machine. Each phase = a session spec (prompt, tools, model, context-in, artifact-out). Spawns and drives sessions — the GUI is not a passive wrapper. |
| **Central task/spec manager** | Website tracking specs done locally across repos, connected via MCP. **Sync model (D19):** phase-completion events carry the full artifact + status + observability trace; mid-phase, lightweight status heartbeats only (no artifact bodies); GUI pulls on demand for freshness. **Auth (D20):** single-user token v1 → GitHub OAuth later. **Hosting (D22):** claude.narenwebworks.in EC2 (t4g.large) initially. |
| **Spec-tracking view** | Full flow UI: select codebase → write spec → follow it through every phase. **MVP slice (D21): observe + approve** — read-only tracking plus the two D9 gates rendered in the browser (non-technical deck at the council gate, task/agent roster at the workforce gate). Drive capability (starting/steering pipelines from the GUI) comes after. |
| **Project setup wizard** | **Full scope (D23):** init a project locally, set up graphify + spec-kit, dev server if needed, bootstrap the agent library, register MCP with the central manager, configure autonomy profiles. Ships last — it packages everything. |

### 4.3 Agent layer

**Agents are assembled, not stored (D40).** The library's unit of storage is the *skill*; an agent is what the assignment step composes at dispatch time:

```
agent = base model (Sonnet, per D18)
      + base specialist config   selected by (type, specialization)   ← fixed core
      + injected skill modules   selected by tags                     ← free tags
      + tool grants              aggregated from those skills         ← D41
```

- **Taxonomy (D16, D42):** hybrid — a fixed core (**8 types × 11 specializations**, `general` capped at 20% of a feature's tasks) keeps base selection deterministic; free tags carry the nuance, and do three jobs: rank skills, brief the skill builder, and **select the skills injected at assembly**. A boolean `preserves_behavior` modifier replaces what was almost a `refactor` type, auto-injecting the `refactor-discipline` skill.
- **Skill library (D17, D40):** per-repo — base specialists in `.claude/agents/`, skill modules in `.claude/skills/`. **Central *skill registry* later, exposed via MCP** (I-10). Entries carry stable IDs + version metadata from day one so central sync is lift-and-shift.
- **Skill builder (was: gap generator) (D2, D40):** on a tag with no covering skill, it authors one `SKILL.md` module — not a whole bespoke agent. The library grows in composable parts rather than in near-empty lanes.
- **Guardrails (D40):** **assembly cap of 3** injected skills per dispatch (trim by tag-rank, log what was dropped); **additive-only** — a skill may forbid more, never permit more, so injecting three sight-unseen can never make an agent less safe than its base.
- **Tool grants (D41):** every base carries the same immutable core toolset; everything beyond it — **web search first among them** — is a per-skill declared grant, and the assembled agent's grants are their union. **The workforce-gate roster displays every agent's grant set**: approving the roster is approving network access. Binds M3 (roster artifact) and M5 (gate view).
- **Flywheel (D24):** good generated **skills** get persisted back into the library with their stats. Still the only self-evolving component in year one.
- **Model policy (D18):** two-plane — **Sonnet default for implementation agents; Opus (xhigh effort) for the main thread.** Judgment roles (chairman, analyze/triage) take Opus; mechanical/generative roles (deck prep, categorizer, skill builder, members) take Sonnet; Haiku unused in v1. Only base specialists declare a model — a skill is not a dispatch target. Graph-scored assignment deferred until observability (principle 7) produces real data — Q6 revisits then.

Contracts: `docs/contracts/agent-library-schema.md`, `docs/contracts/skill-module.md`, `docs/contracts/taxonomy-v0.md`.

---

## 5. Build order & rationale

1. **Council extension** — self-contained, artifact-based, highest priority, no platform dependency.
2. **Git extension** — small; branch-before-plan makes council loop revisions clean.
3. **Categorize + agent creator** — a pair; categorization output is the creator's input.
4. **Testing agent (doc-only)** — cheap to add once completion report exists.
5. **Better graphify integration throughout** — continuous, as each extension lands.
6. **Platform layer** — Agent SDK orchestrator + central manager + tracking view, built against *stable* artifact contracts.
7. **Setup wizard** — last; it packages everything above.

**Why this order holds even with the GUI decision made:** artifacts are the interface. The SDK orchestrator automates invoking the same extensions and rendering their artifacts — so pipeline-first sequencing carries zero rework risk.

---

## 6. Current state (v0.1.0 baseline)

`speckit-graphifyy` ships: graph-grounded plan context, verified `[P]` task markers, execution wave construction, parallel implementation with wave review. Everything in this document builds outward from that foundation.

---

## 7. Doc set

| Doc | Role | Change frequency |
|---|---|---|
| `00-VISION-AND-ARCHITECTURE.md` | North star (this doc) | Rare |
| `05-IMPLEMENTATION-PLAN.md` | Grounded build sequence, milestones M0–M7 | Per milestone |
| `10-COUNCIL-EXTENSION-SPEC.md` | Deep dive: priority #1 (at 0.2 — buildable) | Active |
| `contracts/` | The M0 schemas: artifact layout, decision record, profile, agent library, **skill module**, trace, taxonomy | Rare (each change needs a D-row) |
| `reviews/` | Normative review memos (e.g. the 2026-07-09 taxonomy blessing) | Per review |
| `90-DECISIONS-AND-IDEAS.md` | Decision log, open questions, idea parking lot | Every session |
| `95-M0-KICKOFF.md` | Claude Code handoff: pre-flight + M0 prompt | One-shot (archive after M0) |

Future deep-dives slot into the gaps: `20-AGENT-CREATOR-SPEC.md`, `30-PLATFORM-ORCHESTRATOR-SPEC.md`, `40-CENTRAL-MANAGER-SPEC.md`, etc.
