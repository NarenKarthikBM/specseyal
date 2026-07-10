# Implementation Plan: The Workforce Pair — Task Categorization & Agent Assembly

**Branch**: `003-workforce` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-workforce/spec.md`

**Grounding**: [graphify-context.md](./graphify-context.md) (fresh D59 baseline, 497 nodes / 888 edges).

## Summary

Build the M3 workforce pair as **two new pipeline extensions** delivered together (D40 makes them one composable system): **`speckit-ext-categorize`** (the categorizer) and **`speckit-ext-agents`** (the skill builder + the assembler). The categorizer is a Sonnet session that tags every task with the blessed taxonomy v0 and writes `categorization.md`, guarded by a **code** cap-check that fails the phase if `general > 20%`. The assembler is a **deterministic script** (`assemble`) implementing `agent-library-schema.md` §3 verbatim — base lookup by `(type, specialization)`, tag-ranked skill injection (cap 3), grant union, and the D48 Sonnet-floor guard — so the roster is byte-reproducible on gap-free runs (FR-015/SC-005). On a ∅-match the script hands off to a Sonnet **skill builder** that authors one additive-only `SKILL.md`, persists it to the library (the D24 flywheel), and re-runs assembly. The roster lands in `agents/assignment.md`'s `## Workforce Gate` section (D49/§8) with mandatory Model + Elevated-grants columns; the human signs; `/speckit-implement-parallel` consumes it and every dispatch trace carries the assembly (D43).

The technical approach splits the LLM work from the deterministic work by design: **categorization = inference (Sonnet), assembly = code, skill-building = inference (Sonnet).** That split is what lets one artifact (`categorization.md`) be a non-reproducible LLM product while the roster built from it is byte-reproducible.

## Technical Context

**Language/Version**: Bash (installers, hooks, config — mirrors git-ext) + **Python 3** (the deterministic `assemble` matcher and the `skill-module` validator — YAML-frontmatter parsing + Jaccard set math want a real language, and graphify already establishes Python 3 as the repo's scripting runtime). No new runtime dependency beyond what graphify installs; frontmatter parsing uses a **minimal stdlib parser** over the `specseyal:` block (no PyYAML hard-dependency — see research.md R2).

**Primary Dependencies**: the five M0 contracts the pair consumes — `taxonomy-v0.md` (BLESSED), `agent-library-schema.md` §3/§4, `skill-module.md`, `artifact-layout.md` §2/§6/§8/§9, `trace-schema.md` §1/§5. Claude Code's native `.claude/agents/` (subagent) + `.claude/skills/` (skill) loaders. The three existing extensions as packaging exemplars (graphify-context.md).

**Storage**: repo files only — `categorization.md`, `agents/assignment.md` (feature tree); `.claude/agents/*.md` + `.claude/skills/*/SKILL.md` (the per-repo library, D17). No database (Resumability III).

**Testing**: per-extension `test/run.sh` (the git-ext model, D57 S3): install → reinstall-survival → deterministic-assembly golden test → validator unit checks. Dogfood exit test = SC-009 on `003` itself.

**Target Platform**: Claude Code CLI (interactive, subscription-only, D28); M6 Agent SDK later — no change to these artifacts.

**Project Type**: two pipeline extensions (`extensions/categorize/`, `extensions/agents/`) + a seed library — the `extensions/<name>/` sibling pattern (D26 monorepo layout).

**Performance Goals**: assembly is O(tasks × skills) Jaccard — trivial at pipeline scale (tens of tasks, tens of skills). No perf concern; **determinism, not speed, is the property that matters** (SC-005).

**Constraints**: subscription-only (V/D28, no `ANTHROPIC_API_KEY`); Sonnet floor for the categorizer, skill builder, and every base (D18); additive-only skills (D40.4); assembly cap 3 (D40); single-writer artifacts (§6/D37).

**Scale/Scope**: 2 extensions + **7 seed base specialists + 5 seed skills** (§ Seed Library). Indicative task count ~20–26 (comparable to 001's 20 / 002's 23), across categorizer · skill-builder · assembler · seed-library · install/test.

## Constitution Check

*GATE: evaluated before Phase 0 and re-checked after design. PASSES (no violations).*

| Principle | Verdict | How this plan honors it |
|---|---|---|
| **I. Artifacts Are the Contract** | ✅ | `categorize` writes **only** `categorization.md` (D37, never mutates `tasks.md`); `agents` writes **only** `agents/assignment.md`. The skill builder's `SKILL.md` persistence writes to the repo-root **library** (`.claude/skills/`), *outside* the feature tree — a shared-infrastructure mutation (the D24 flywheel), not a second feature artifact and not another phase's artifact. Documented, not a violation (see note ★). |
| **II. Context Hygiene** | ✅ | Categorizer, skill builder, and (when a gap fires) the assembler's builder each run as **separate Sonnet sessions** returning one compact artifact. The deterministic `assemble` matcher is a script — it adds no context to the main thread. |
| **III. Resumability (NON-NEGOTIABLE)** | ✅ | Phase state inferred from artifacts: `categorization.md` valid ⇒ categorize complete; `assignment.md` with a roster ⇒ assign complete; the `## Workforce Gate` section ⇒ gate complete (D32). No state file. Determinism (FR-015) makes a re-run idempotent. |
| **IV. Observability** | ✅ | Categorizer (`categorizer`) and skill builder (`agent-creator`) append one `traces.jsonl` record each; implement dispatches carry `skills[]` + `elevated_grants[]` (D43, FR-021). Note ★★ on the gap-free assembly trace. |
| **V. Subscription-Only (NON-NEGOTIABLE)** | ✅ | Categorizer + skill builder run on subscription (Sonnet); no key. The `assemble`/validator scripts are zero-AI (like git-ext). |
| **Model Policy (D18)** | ✅ | Categorizer + skill builder = Sonnet (mechanical/generative). Every seed base declares `model: sonnet` (all accept ≥1 implementation type; `agent-library-schema.md` §4 enforced). The D48 guard holds the Sonnet floor for `prompt`-tagged tasks **in code**. |
| **Autonomy & Gates (D9)** | ✅ | The workforce gate: categorizer + assembler **PROPOSE**, human **signs** (`gates.workforce.mode: human`, this feature's profile). `auto` only under `full_auto` (§8 W4). |

★ **The flywheel write is not a principle-I violation.** Principle I governs *feature-tree* artifacts (one per phase in `specs/NNN/`). The generated `SKILL.md` lands in the repo-root library `.claude/skills/` — shared infrastructure the whole pipeline reads, explicitly sanctioned as the year-one self-evolving component (D24, `agent-library-schema.md` §5). It is the D40.2 replacement for "author a bespoke agent," not a second output of the *feature*. Recorded here so the boundary is deliberate, not smuggled.

★★ **Gap-free assembly may legitimately run no model session** (see Risk R2) — the deterministic `assemble` matcher is mechanical (git-ext precedent: "zero-AI, no trace"). The `agent-creator` trace appears when the skill builder fires. Flagged for the council rather than forced.

## Project Structure

### Documentation (this feature)

```text
specs/003-workforce/
├── plan.md              # this file
├── research.md          # Phase 0 — the deferred design choices resolved
├── data-model.md        # Phase 1 — categorization.md format, library entry shapes, roster
├── quickstart.md        # Phase 1 — SC-001..SC-009 validation scenarios
├── contracts/
│   └── commands.md      # Phase 1 — the /speckit-categorize + /speckit-agent-assign command contracts
├── graph-baseline.json  # committed D59 council baseline (already present)
└── tasks.md             # Phase 3 (/speckit-tasks-graph) — NOT created here
```

### Source Code (repository root)

```text
extensions/categorize/                     # speckit-ext-categorize (new; mirrors extensions/git/)
├── install.sh · uninstall.sh              # copy source → .specify/extensions/categorize/ + .claude/skills/; deregister-first
├── extension/
│   ├── extension.yml                      # registers the categorize command; no cross-ext source edits (D57)
│   ├── categorize-config.yml              # cap=0.20, taxonomy path, model=sonnet
│   ├── commands/speckit.categorize.md
│   ├── scripts/validate-categorization.py # CODE cap-check + enum/coverage validation (FR-004/SC-002)
│   └── templates/categorizer-prompt.md · categorization.template.md
├── skills/speckit-categorize/SKILL.md
└── test/run.sh

extensions/agents/                         # speckit-ext-agents (new)
├── install.sh · uninstall.sh
├── extension/
│   ├── extension.yml
│   ├── agents-config.yml                  # assembly_cap=3, model=sonnet, seed-library manifest, web_search decision (§ below)
│   ├── commands/speckit.agent-assign.md
│   ├── scripts/assemble.py                # DETERMINISTIC §3 matcher: base lookup, tag-Jaccard rank, cap-3, grant union, D48 guard, FR-022 library|built marks
│   ├── scripts/validate-skill.py          # skill-module.md validator: S1-S3 additive-only, skl_ id, semver, grants⊄core
│   └── templates/skill-builder-prompt.md · assignment.template.md · skill-module.template.md
├── seed/                                   # the SEED LIBRARY (installed additively to repo-root .claude/)
│   ├── agents/agt-*.md                     # 7 base specialists (§ Seed Library)
│   └── skills/*/SKILL.md                   # 5 seed skills incl. refactor-discipline
├── skills/speckit-agent-assign/SKILL.md
└── test/run.sh

.claude/agents/  ·  .claude/skills/         # the live per-repo library (D17) — seeded by extensions/agents/install.sh
```

**Structure Decision**: two `extensions/<name>/` trees on the git/council sibling pattern (graphify-context.md "Patterns to follow"). The **deterministic core is a script** (`assemble.py`), not the LLM — the single most important structural decision, and the one that makes SC-005 real. Cross-`categorize`↔`agents` coupling is a **hook point**, never a source edit (D57 §9).

## Architecture & data flow

```
tasks.md + plan.md ──▶ [categorize: Sonnet session] ──▶ categorization.md
                          └─ validate-categorization.py (CODE): general≤20% else FAIL, no write (FR-004)
categorization.md + library ──▶ [agent-assign command]
   1. assemble.py (CODE, deterministic §3) ──▶ roster + ∅-match gap list
   2. if gaps: [skill-builder: Sonnet subagent] ──▶ new SKILL.md (additive-only) ──▶ .claude/skills/  (flywheel, D24)
   3. assemble.py re-run (now gap-free) ──▶ final roster with FR-022 library|built marks
   4. write agents/assignment.md ## Workforce Gate (Model + Elevated-grants mandatory)
[human signs] ──▶ /speckit-implement-parallel dispatches each assembled agent ──▶ trace carries skills[]+elevated_grants[] (FR-021/D43)
```

The **categorizer** derives `type` + `preserves_behavior` from the graphify signals already in `tasks.md` (`files=`/`deps=`/`mutates=`/TDD position — the mechanical axis) and `specialization` from `plan.md`'s stack + spec domain (the interpretive axis) — the two-evidence-source split that justifies a Sonnet categorizer (taxonomy §1). The **assembler** never guesses: its base lookup, ranking (Jaccard → success_rate → version → id total order, §3 step 4), cap trim, grant union, and D48 guard are all in `assemble.py`.

## Seed Library (proposed — the council reviews this set)

The library seed is **deferred to the plan** (spec Key Entities); docs/05's "5–6 specialists" is indicative. Proposed from the empirically-exercised lanes of the two real dogfood features to date (001 categorization: `ai-agents`×10 + `devtools-cli`×9; 002: `devtools-cli`×15, `security`×3, `qa-automation`×3, `ai-agents`×2) plus the taxonomy worked-example's `backend-service`/`data-persistence` cluster. **Bases are curated-static (D44); skills alone evolve (D24).**

### Base specialists — 7 (`.claude/agents/agt-*.md`, all `model: sonnet`)

| `id` | Specialization | Accepts `type` | Lane rationale (evidence) |
|---|---|---|---|
| `agt_ai_agents` | `ai-agents` | service, endpoint, scaffold, test, **docs** | LLM/prompt/agent/MCP work — 001's dominant lane. Accepts `docs` so a `prompt`-tagged (`docs × ai-agents`) task lands on a **Sonnet** base, satisfying the D48 floor by construction. |
| `agt_devtools_cli` | `devtools-cli` | scaffold, service, endpoint, test, infra | CLIs/build tooling/extensions — the lane that *builds the pipeline itself* (001+002 dominant). |
| `agt_security` | `security` | service, endpoint, test | AuthZ / gate-integrity / secrets — 002's gate-integrity trio. |
| `agt_qa_automation` | `qa-automation` | test, scaffold | Harness/fixture/e2e expertise (distinct from writing tests — taxonomy §4). |
| `agt_backend_service` | `backend-service` | data-model, service, endpoint, test | The taxonomy worked-example's dominant lane; the canonical server lane. |
| `agt_data_persistence` | `data-persistence` | data-model, service | Schema/migration/ORM/query lane. |
| `agt_generic` | `general` | *(all 7 implementation types)* | The FR-016 **fallback base** for any unmatched `(type, specialization)` and every `general`-specialized task; the empty lane is reported on the roster. Skills still compose on top. |

Every lane is unique (`agent-library-schema.md` §6 rule 5). Absent lanes (`frontend-web`, `mobile`, `infra-platform`, `performance`) are **deliberately unseeded** — no dogfood evidence yet; a task hitting them falls to `agt_generic` + a reported empty lane (honest, and it earns the lane its first real evidence for v0→v1). Bases carry lane-level discipline only, **no framework knowledge** (§1.1) — that lives in skills.

### Seed skills — 5 (`.claude/skills/*/SKILL.md`)

| `id` | `origin` | `tags` | `grants` | Why seeded |
|---|---|---|---|---|
| `skl_refactor_discipline` | seed | refactor, blast-radius, behavior-preserving | `[]` | **Exists** (`skill-module.md` §5); auto-injected on `preserves_behavior: true` (FR-012). The reason OQ1 could be overruled. |
| `skl_orchestration` | seed | orchestration, subagent, dispatch, parallel, wave | `[]` | 001 tagged all three command skills `orchestration`; the pipeline's dominant cross-cutting skill. |
| `skl_shell_scripting` | seed | bash, shell, sh, posix, install | `[]` | 002 (git-ext) is entirely shell; the extension-building tag. |
| `skl_yaml_hooks` | seed | yaml, config, manifest, hooks, extension-yml | `[]` | Hook-registry / `extension.yml` work — the shared-registry lane both 001/002 exercised. |
| `skl_installer_hygiene` | seed | install, uninstall, idempotent, reinstall, reinstall-survival | `[]` | 002's reinstall-survival discipline (I-14/D57) — every extension needs it. |

**All seed skills declare `grants: []`** — none needs elevation. This keeps the seed library entirely inside the core toolset, so the *first* elevated grant in the whole system is a deliberate, gate-visible event (the `web_search` question below), never a seed default. `skl_refactor_discipline` is relocated from the `000-sample` fixture into the live library at repo root.

## The `web_search` grant question — both options costed (spec OPEN item; D58-5d)

The spec poses it and defers the answer to the plan for the council to decide: **does the skill-builder *role* declare `web_search`** — the system's first elevated grant (D41)? The builder authors `SKILL.md`s that may themselves declare `web_search`; to author them well it may want to consult current library/dependency docs. This is distinct from a *library skill* (e.g. a future `dep-version-lookup`) declaring `web_search` — that is uncontroversial and unaffected by this decision. The question is only about the **builder session's own tool access while authoring**.

**Plan's recommendation: Option A (NO web_search for the builder in v1).** Costed both ways:

| | **Option A — builder has NO `web_search` (recommended)** | **Option B — builder declares `web_search`** |
|---|---|---|
| **What the builder loses / gains** | Loses live doc lookup: it authors `SKILL.md` bodies from the task's `tags` + the spec/plan/graph context it already holds, and from Claude's own knowledge. A skill needing *current* dependency facts is authored as a stub declaring `grants: [web_search]` **for the implementer to use**, rather than the builder resolving them at authoring time. | Gains live doc lookup while authoring — richer first-draft skill bodies for fast-moving libraries; fewer "author a stub, resolve later" cases. |
| **Grant machinery exercised** | **None at the builder.** The system's first elevated grant stays a *skill* declaration surfaced at the workforce gate — the exact audit path D41 designed. `elevated_grants` on traces still exercises via any library skill that declares it. | Exercises the grant machinery **at a new site** — a role-level (not skill-level) grant. That is precisely the "not an agent-level default" A-2/D44 warned against: a session-level network reach that **does not appear on any workforce-gate roster** (the builder runs at assign time, before the gate). |
| **Audit / safety** | Network reach in the system remains **100% skill-declared and gate-visible**. No un-gated network session exists. | Introduces the *one* network reach that is **not** gate-visible (the builder authors before the human signs). Would need its own audit story (a builder-run trace flag), i.e. new machinery to stay honest. |
| **Subscription/D28** | Unaffected. | Unaffected (web_search is a Claude Code tool, not an API key). |
| **Reversibility** | Trivially add later if authoring quality demands it (a config flag + a gate-surfaced builder-grant note). | Harder to walk back once skills are authored assuming live lookup. |

**Recommendation rationale:** the first elevated grant in the system should be **skill-declared and gate-visible** (D41's whole thesis), not a role-level default on a session that runs *before* the gate. Option A keeps the audit invariant intact ("a grant that reaches an agent without appearing on the roster is a contract violation" — `skill-module.md` §4) and is trivially reversible. The council decides; if it prefers B, the plan's fallback is B **plus** a mandatory builder-run trace flag + a `## Skill Builder` note on the roster so the reach stays auditable.

## Plan-time verifications (D58-5; report, do NOT reopen the spec)

The D58 spec-approval booked four items to *verify at plan time*. Confirmed against the design:

- **(a) FR-004 / SC-002 — the 20% `general` cap is an FR with failure behavior, not prose.** ✅ Verified and made **code**: `validate-categorization.py` counts `general` and, when `count(general) > 0.20 × count(tasks)`, exits non-zero → the command writes **no** `categorization.md` and the phase does not complete (FR-004 exactly; taxonomy §4 "failure is not a warning"). SC-002 is measured by that script's exit, not the LLM's self-report. Small-`n` edge (`⌊0.2n⌋=0` for `n<5`, D44) stands for v0.
- **(b) FR-014 / SC-006 — the D48 Sonnet-floor guard is enforced by code.** ✅ Verified: `assemble.py` carries the guard — for any task with the `prompt` tag, it asserts the selected base is a Sonnet implementation specialist (never a `docs`-exempt non-Sonnet base) and **errors** otherwise. With the seed library (every base Sonnet, `agt_ai_agents` accepting `docs`), a `prompt × docs × ai-agents` task provably lands on Sonnet. SC-006 is a golden test over such a task.
- **(c) FR-007 / FR-011 / SC-004 — assembly cap ≤3 + additive-only are testable constraints.** ✅ Verified: the cap is `assemble.py` injecting `first 3 of (forced ++ ranked)` and **logging** `dropped` (never silent — FR-011/SC-004); a >3-candidate golden test asserts exactly 3 injected + the rest logged. Additive-only (FR-007) is enforced by `validate-skill.py` rejecting S1–S3 violations (negation/override/relaxation, model/dispatch keys) on every generated `SKILL.md` — a unit-testable validator, the `skill-module.md` §3 table made executable.

## Risks flagged for the council

- **R1 — Determinism boundary vs. an LLM in the loop.** SC-005's byte-reproducibility rests entirely on `assemble.py` being the sole authority for matching — if any matching judgment leaks into the `agent-creator` Sonnet session, determinism breaks. Mitigation: the session **only** dispatches skill-building and writes the artifact; it never ranks or selects. The council should pressure-test whether the command prose can truly hold that line (the 002 lesson: prose-level enforcement is only as good as the model following it, D53).
- **R2 — Gap-free assign may leave no `agent-creator` trace.** The deterministic matcher is mechanical; on a gap-free run no model session runs in the assign phase (git-ext precedent). Is `agent-assign` a *model phase* (expects a trace, artifact-layout §2) or a *mechanical phase* (like `branch`/git)? Recommendation: mechanical — the honest reading — with the skill-builder trace appearing only on gaps. Council to ratify (touches trace-schema rule 9 / §2's "separate session" label).
- **R3 — Seed-library overfit (OQ6).** `ai-agents` + `devtools-cli` are SpecSeyal-shaped lanes; the seed is fitted to two features that both *build this pipeline*. The v0→v1 review (taxonomy §8) re-tests them against a non-SpecSeyal repo. Bounded by D17 (per-repo library) — noted, not blocking.
- **R4 — `web_search` decision (above).** The council's to decide; the plan recommends A and provides a B-fallback with an audit flag.
- **R5 — Flywheel write path vs. reinstall (I-14/D57).** The skill builder persists `SKILL.md` into `.claude/skills/` — the exact tree installers `rm -rf`. The generated-skill path must be the **live** library, never an extension's installed copy, and `agents/install.sh` must seed additively (never clobber a generated skill). `test/run.sh` reinstall-survival covers it.

## Complexity Tracking

*No unjustified constitution violations.* The one nuance worth naming (★ above) — the flywheel writing `SKILL.md` outside the feature tree — is a **sanctioned** D24 behavior, not a violation, and is recorded in the Constitution Check rather than smuggled here.

| Item | Why needed | Simpler alternative rejected because |
|---|---|---|
| Python for `assemble.py` (not pure Bash) | Deterministic YAML-frontmatter parse + Jaccard set math + total-order tie-break (§3 step 4) must be exact and testable | Bash + `yq`/`awk` ranking is fragile on the tie-break total order; a non-deterministic sort silently breaks SC-005 — the one property the whole feature exists to guarantee |
