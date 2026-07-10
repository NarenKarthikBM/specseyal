# Defense Deck — Technical

**Feature**: `003-workforce`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

After `/speckit-tasks` and `/speckit-analyze` produce a feature's final `tasks.md`, nothing yet says *who* should build each task or *what tools* they are allowed to touch while doing it. M1 and M2 improvised this by hand each time. M3 must make the assignment systematic, auditable, and gated before implementation spends tokens — this is the "workforce pair," delivered as one feature (D40): **`speckit-ext-categorize`** (the categorizer) and **`speckit-ext-agents`** (the skill builder + the assembler).

Two things are missing, in priority order. **(1)** A classification of every task against the blessed taxonomy v0 — one `type`, one `specialization`, a `preserves_behavior` boolean, and free `tags` — because categorization is the assembler's only input; without it no principled assignment is possible (US1, P1). **(2)** An assembled roster — one specialized agent per task, its skills and its tool grants named explicitly — that a human signs before implementation runs, because approving the roster *is* approving network/tool access (US2, P1, D9/D41) and *is* the economic guard before tokens are spent. A third, lower-priority need closes the system's only self-evolving loop: when a task's tags match no existing skill, the library should grow itself rather than someone hand-authoring a bespoke agent each time (US3, P2, the D24 flywheel) — and every implementation dispatch must leave an auditable trace of which skills and grants were actually active, closing the loop back to the approved roster (US4, P2). Unlike `002` (git-ext, zero-AI), this pair **does AI work at runtime**: two of its three roles are inference, so subscription/model policy (D28/D18) governs both its build and its runtime.

---

## 2. Chosen Approach & Rejected Alternatives

**Chosen approach**

The pair's spine is a three-way split of labor by what kind of work each step actually is — **categorization = inference (Sonnet), assembly = code, skill-building = inference (Sonnet)**:

```
tasks.md + plan.md ──▶ [categorizer: Sonnet] ──▶ categorization.md
                          └─ validate-categorization.py (CODE): general > 20% ⇒ FAIL, no write
categorization.md + library ──▶ [agent-assign]
   1. assemble.py (CODE, deterministic §3) ──▶ roster + ∅-match gap list
   2. if gaps: [skill-builder: Sonnet] ──▶ new SKILL.md (additive-only) ──▶ .claude/skills/ (flywheel, D24)
   3. assemble.py re-run (gap-free) ──▶ final roster, FR-022 library|built marks
   4. write agents/assignment.md ## Workforce Gate (Model + Elevated-grants mandatory)
[human signs] ──▶ /speckit-implement-parallel dispatches ──▶ trace carries skills[]+elevated_grants[] (D43)
```

- **Categorization is inference.** A Sonnet `categorizer` session reads `tasks.md` + `plan.md` and tags every task `(type, specialization, preserves_behavior, tags)`. `type` and `preserves_behavior` are derived **mechanically** from graphify's signals already sitting in `tasks.md` (`files=`/`deps=`/`mutates=`/TDD position); `specialization` is derived **interpretively** from `plan.md`'s declared stack + the spec's domain — this mechanical/interpretive split across two axes is what justifies a Sonnet categorizer instead of a pure script (taxonomy §1).
- **Assembly is code, not inference.** `assemble.py` implements `agent-library-schema.md` §3 verbatim: base lookup by `(type, specialization)`, candidate skills by tag intersection, rank by Jaccard → `success_rate` → `version` → `id` (total order, no ties), inject `first 3 of (forced ++ ranked)`, grant union, the D48 Sonnet-floor guard, and FR-022 `library`/`built` marks. **No model runs inside it.** This is the single most load-bearing structural decision in the whole feature: it is what lets `categorization.md` be a non-reproducible LLM product while the roster built from it is byte-reproducible (SC-005).
- **Skill-building is inference, dispatched only on a gap.** On a ∅-match, a Sonnet `skill-builder` subagent authors exactly ONE additive-only `SKILL.md` (not a bespoke agent — D40.2), which `validate-skill.py` (code) checks against S1–S3 before it is persisted into the repo-root library with provenance (`origin: generated`, `source_feature`) — the D24 flywheel. `assemble.py` then re-runs, now gap-free, for the final roster.

The roster lands in `agents/assignment.md`'s `## Workforce Gate` section (D49/§8) with mandatory Model + Elevated-grants columns; the human signs; `/speckit-implement-parallel` consumes it and every dispatch trace carries the assembly (D43).

**Seed library — 7 bases + 5 skills (the plan's proposal; the council reviews this set)**

Bases are curated-static; skills alone evolve (D44). The seed is fitted to the only real evidence that exists: 001's categorization (`ai-agents`×10, `devtools-cli`×9), 002's (`devtools-cli`×15, `security`×3, `qa-automation`×3, `ai-agents`×2), and the taxonomy worked-example's `backend-service`/`data-persistence` cluster.

| Base (`agt_…`) | Specialization | Evidence |
|---|---|---|
| `agt_ai_agents` | `ai-agents` | 001's dominant lane; accepts `docs` so a `prompt`-tagged task lands on Sonnet by construction (D48). |
| `agt_devtools_cli` | `devtools-cli` | 001+002's dominant lane — the lane that builds the pipeline itself. |
| `agt_security` | `security` | 002's gate-integrity trio. |
| `agt_qa_automation` | `qa-automation` | Harness/fixture/e2e expertise, distinct from writing tests (taxonomy §4). |
| `agt_backend_service` | `backend-service` | Taxonomy's worked-example dominant lane. |
| `agt_data_persistence` | `data-persistence` | Schema/migration/ORM/query lane. |
| `agt_generic` | `general` (fallback) | FR-016's fallback for any unmatched lane; the empty lane is reported on the roster, never silent. |

Four specializations (`frontend-web`, `mobile`, `infra-platform`, `performance`) are **deliberately unseeded** — no dogfood evidence yet; a task hitting them falls to `agt_generic` + a reported empty lane. Five seed skills, all `grants: []` (so the *first* elevated grant in the system stays a deliberate, gate-visible event, never a seed default): `skl_refactor_discipline` (auto-injected on `preserves_behavior: true`, FR-012 — relocated from `000-sample`), `skl_orchestration` (001's dominant cross-cutting skill), `skl_shell_scripting` (002 is entirely shell), `skl_yaml_hooks` (hook-registry/`extension.yml` work), `skl_installer_hygiene` (002's reinstall-survival discipline, I-14/D57).

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| LLM performs the matching/ranking itself | Fails SC-005 outright — an LLM ranking is not byte-reproducible; this is the load-bearing risk the whole feature is built to avoid (research R1). |
| Pure Bash + `yq`/`awk` for `assemble.py` | The §3 step-4 total-order tie-break (`id` ascending, no ties) is fragile in shell sort pipelines; a locale- or flag-dependent sort would silently break determinism. Python's stable `sorted(key=...)` is exact and unit-testable (R1). |
| A PyYAML dependency for frontmatter parsing | A real third-party dependency for a closed, contract-defined shape (`agent-library-schema.md` §1.1 / `skill-module.md` §1); rejected on subscription-only build hygiene (R2). |
| A fully scripted categorizer (no LLM) | `specialization` cannot be derived from graphify's mechanical signals — the very asymmetry that justifies two axes and requires inference (R3). |
| The LLM self-enforces the 20% `general` cap | A lazy/over-`general` run could self-certify; the cap is a hard evidentiary floor and must be mechanical, never policed by the model that produced the categorization (R3, D58-5a). |
| Skill builder authors a whole bespoke agent on a gap | The pre-D40 design; grows near-empty single-use lanes instead of composable skill parts (R4, D40.2). |
| Persist a generated skill without validation | A non-conforming skill could break assembly determinism or leak a grant past the additive-only guarantee (R4). |
| Seed only `refactor-discipline` (docs/05's stated minimum) | Leaves every 001/002-style task on `agt_generic`, defeating the point of having base specialists at all (R5). |
| Seed all 11 specializations | Invents 5 lanes with zero dogfood evidence — contradicts "an unexercised enum value is a guess" (taxonomy §5); the OQ6 overfit risk (R5, see §4 R3 below). |
| Skill-builder role declares `web_search` by default (Option B) | Introduces the system's one network reach that is **not** gate-visible — a role-level grant on a session that runs before the human signs. Costed in full below. |
| Edit the git extension's source to add `after_categorize`/`after_agent-assign` hooks | A source edit into a foreign extension when a hook point suffices; D57 S1 prefers an extension-registered hook over patching another extension's installed file (R7). |
| A new gate-freshness binding record owned by the `agents` extension | Duplicates D55's existing `gates.yml` design and adds a second writer to it (R8). |

**Open decision for the council: the `web_search` grant question (spec's OPEN item)**

Does the skill-builder *role* itself declare `web_search` — the system's first elevated grant (D41)? This is distinct from a *library skill* declaring `web_search` (uncontroversial); the question is only the builder session's own tool access while authoring `SKILL.md`s.

| | **Option A — no `web_search` for the builder (plan's recommendation)** | **Option B — builder declares `web_search`** |
|---|---|---|
| What's lost / gained | Builder authors from `tags` + the spec/plan/graph context it already holds + Claude's own knowledge; a skill needing *current* dependency facts is authored as a stub declaring `grants: [web_search]` **for the implementer**, not resolved at authoring time. | Richer first-draft skill bodies for fast-moving libraries; fewer stub-then-resolve cases. |
| Grant machinery exercised | **None at the builder.** The system's first elevated grant stays a *skill* declaration, gate-visible — exactly the audit path D41 designed. | Exercises the grant machinery at a **new, ungated site** — a role-level grant on a session that runs at assign time, *before* the human signs, so it appears on no workforce-gate roster (the A-2/D44 warning). |
| Audit / safety | Network reach stays 100% skill-declared and gate-visible; no un-gated network session exists. | Introduces the one network reach that is not gate-visible; would need new machinery (a builder-run trace flag) to stay honest. |
| Reversibility | Trivially added later (a config flag + a gate-surfaced builder-grant note). | Harder to walk back once skills are authored assuming live lookup. |

**Recommendation rationale:** the first elevated grant in the system should be skill-declared and gate-visible (D41's whole thesis), not a role-level default on a pre-gate session. Option A keeps the audit invariant intact ("a grant that reaches an agent without appearing on the roster is a contract violation" — `skill-module.md` §4) and is trivially reversible. **If the council prefers Option B**, the plan's fallback is B **plus** a mandatory builder-run trace flag + a `## Skill Builder` roster note, so the reach stays auditable.

---

## 3. Dependency / Graph Impact

Grounded in the committed D59 tiered-council baseline (`specs/003-workforce/graph-baseline.json`, regenerated 2026-07-10: **497 nodes / 888 edges**, 44 communities, repo scope). This is a fresh, one-time-committed snapshot (D59) — not a stale artifact — captured specifically for this council round.

**Both extensions are new code.** `speckit-ext-categorize` and `speckit-ext-agents` resolve as `concept` nodes sourced in `spec.md`; `graphify path` finds no edge from either to `.specify/extensions.yml` — neither is wired into the repo yet. What the graph grounds is the *pattern* to mirror and the *contracts* to satisfy:

- **Packaging exemplars**: `.specify/extensions/git/extension.yml` is the closest analog (commands + hooks + a config yml + install/uninstall + a test harness) for both new extensions; `extensions/council/` is additionally the multi-command pattern `agents` should mirror (it ships more than one command-adjacent role, like council's member/chairman split).
- **Contracts consumed** (community 6, tightly cross-referenced — the council will check receipts against these): `docs/contracts/taxonomy-v0.md` (**BLESSED**), `agent-library-schema.md` (base format + §3 matching algorithm + §4 model policy), `skill-module.md` (`SKILL.md` format, S1–S3, grants), `artifact-layout.md` §2/§6/§8/§9, `trace-schema.md` §1/§5.
- **Artifact ownership** (single-writer, §6/D37): `categorization.md` — `categorize` owns it, writes nothing else; `agents/assignment.md` — `agents` owns it, writes nothing else in the feature tree (the generated `SKILL.md` write is a sanctioned exception — see Constitution Check ★ in `plan.md`).

**Blast radius per anchor:**
- `speckit-ext-categorize` — reads `tasks.md`, `plan.md`; writes `categorization.md`; follows the git-ext scaffold + a separate-session command like `speckit-tasks-graph`.
- `speckit-ext-agents` — reads `categorization.md`, `.claude/agents/`, `.claude/skills/`; writes `agents/assignment.md` **and** new `SKILL.md` files (the flywheel write, outside the feature tree); follows `extensions/council/`'s multi-command pattern; the assembly algorithm is `agent-library-schema.md` §3 verbatim.
- The seed library (`.claude/agents/` + `.claude/skills/`) — new curated files; `refactor-discipline` already exists at `specs/000-sample/.claude/skills/refactor-discipline/SKILL.md` and is **relocated**, not duplicated, into the live repo-root library.

**Shared / mutable files (collision watch)** — serialize, never parallelize, across these:

- **`.specify/extensions.yml`** — the hook registry, **degree 15** (every pipeline command references it) — **the single highest-collision file in the repo**. Both new extensions register hooks here via an installer merge (never a source overwrite), the same discipline git-ext and council already follow.
- **`.claude/skills/`** — the skill-builder **writes** new `SKILL.md`s here at *runtime*, not install time. This is the exact directory installers `rm -rf` on reinstall — the 002 reinstall-survival hazard (I-14/D57). The generated-skill persistence path must never collide with, or be clobbered by, an extension's installed tree.
- `.specify/extensions/<name>/` + `.claude/skills/speckit-*` — installer-overwritten trees (D57 S2): any `categorize`↔`agents` coupling must be a hook point, never a source edit into the other extension.

---

## 4. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| **R1** | Determinism boundary vs. an LLM in the loop — SC-005's byte-reproducibility rests entirely on `assemble.py` being the *sole* authority for matching. If any matching judgment leaks into the `agent-creator` Sonnet session (e.g. it starts "helpfully" re-ranking), determinism breaks silently. | Med — the 002 lesson (D53) is that prose-level enforcement is only as good as the model following it, and this design leans on command prose to hold the session to "dispatch + write only." | High — SC-005 is the property the entire feature exists to guarantee; if it breaks, the pair's core defensible claim fails. | The session **only** dispatches skill-building and writes the artifact; it never ranks or selects — enforced by the golden test (frozen fixture, two runs, byte-diff) in `extensions/agents/test/run.sh`. **Explicitly flagged for the council** to pressure-test whether command prose can truly hold this line. |
| **R2** | A gap-free assign run may leave **no** `agent-creator` trace at all — the deterministic matcher is mechanical, so on a gap-free run no model session runs in the assign phase (git-ext precedent: zero-AI, no trace). Raises a schema question: is `agent-assign` a *model phase* (expects a trace, `artifact-layout.md` §2) or a *mechanical phase* (like `branch`)? | High — this is the *expected*, common-case outcome once the seed library has real coverage, not an edge case. | Low–Med — a definitional/observability gap (touches `trace-schema.md` rule 9 / §2's "separate session" label), not a data-loss or correctness risk. | Plan recommends the **mechanical** reading (the honest one) — the skill-builder trace appears only on gaps. **Council to ratify.** |
| **R3** | Seed-library overfit (OQ6) — `ai-agents` + `devtools-cli` are SpecSeyal-shaped lanes; the seed is fitted to the two features that both *build this pipeline*, not to a general codebase. | Med — the evidence base is genuinely thin (2 features). | Low — bounded by D17 (library is per-repo, not shared cross-project); an absent lane fails honestly (`agt_generic` + reported empty lane) rather than silently. | The taxonomy §8 v0→v1 review re-tests the seed against a non-SpecSeyal repo. Noted, not blocking. |
| **R4** | The `web_search` grant question (§2 above) is a live council decision, not a settled design choice — if the council prefers Option B without the plan's proposed fallback, the system gains an ungated network reach. | Low — the plan pre-costs both options and proposes a concrete fallback if B is chosen. | Med — directly affects the D41 audit invariant ("a grant that reaches an agent without appearing on the roster is a contract violation") if adopted without the fallback. | Plan recommends Option A; if the council prefers B, ships **with** a mandatory builder-run trace flag + a `## Skill Builder` roster note so the reach stays auditable. **Council decides.** |
| **R5** | Flywheel write path vs. reinstall (I-14/D57) — the skill builder persists `SKILL.md` into `.claude/skills/`, the *exact* tree installers `rm -rf` on reinstall. A naive installer could clobber a previously generated skill. | Low — the pattern (additive seed, never clobber) is already proven by 002's reinstall-survival discipline. | High if it occurred — silently destroying flywheel state (a generated skill and its accumulated `stats`) is not recoverable and would be discovered late. | The generated-skill path is the **live** library, never an extension's installed copy; `agents/install.sh` seeds additively (never clobbers); `test/run.sh` reinstall-survival (quickstart S11) asserts a prior `built` skill survives a foreign-extension reinstall. |

---

## 5. Cost / Complexity Estimate

**This council round** (`council_tier: standard`, D56, `profile.yaml` confirmed): 1 deck-prep Sonnet session (this one) + 5 stage-1 Sonnet member opinions + 1 consolidated Sonnet peer-critique session + 1 Opus-xhigh chairman synthesis = **8 sessions**, versus the `full`-tier 12-session baseline that cost 002's round 5,249,858 billable tokens. Triage folds into the Opus main thread (judgment role, D18) rather than a separate dispatch, per 002's precedent.

**Build-side** (implementation, not yet task-broken-out — `tasks.md` doesn't exist until after this round clears triage): `plan.md`'s Scale/Scope estimates **~20–26 tasks**, comparable to 001's 20 and 002's 23, spanning categorizer · skill-builder · assembler · seed-library · install/test work across two extensions delivered as one feature. Implementation sessions run Sonnet per D18 (every seed base, the categorizer, and the skill builder are all Sonnet).

**Runtime cost, once built** — unlike `002` (git-ext), which is zero-AI by design (`git_ext_spend = 0`), this pair is **not** zero-cost at runtime: two of its three roles are inference. Per future feature that runs it: 1 Sonnet `categorizer` session (always) + `assemble.py` (zero-AI, always) + 1 Sonnet `skill-builder` session **per gap batch** (zero on a gap-free run, per R2).

**What drives complexity up**, per `plan.md`'s Complexity Tracking table and Constitution Check: (1) **two extensions delivered as one feature** — a doubled install/uninstall/test/packaging surface versus a single-extension build; (2) **Python introduced as a second scripting runtime** alongside Bash — justified because deterministic YAML-frontmatter parsing + Jaccard set math + a total-order tie-break must be exact and testable, and a Bash+`yq`/`awk` ranking risks a locale- or flag-dependent sort silently breaking SC-005 (the one property the feature exists to guarantee — no simpler alternative survives that bar); (3) **cross-extension hook coupling** — `categorize`'s `after_categorize` and `agents`' `after_agent-assign` both register hooks into `speckit.git.commit` (R7), plus the `categorize → agent-assign` phase coupling itself; (4) the **seed library** (7 bases + 5 skills) is a substantive curation deliverable the council must review on its evidence, not boilerplate; (5) the **`web_search` decision** (§2/R4) is an open branch-point requiring council judgment, with a costed fallback path.

---

## 6. Testability Claim

**Plan-time verifications rendered as code (D58-5)** — the spec-approval booked four items to verify at plan time; each is enforced in code, not prose:

**(a) FR-004 / SC-002 — the 20% `general` cap.**
```
count(general) > 0.20 × count(tasks)
    → validate-categorization.py exits non-zero
    → command writes NO categorization.md
    → phase does not complete
```
SC-002 is measured by the script's exit code, not the LLM's self-report. Small-`n` edge (`⌊0.2n⌋ = 0` for `n < 5`, D44) stands for v0.

**(b) FR-014 / SC-006 — the D48 Sonnet-floor guard, in `assemble.py`.**
```
for task in categorized_tasks:
    if "prompt" in task.tags:
        assert selected_base.model == "sonnet"   # else: hard error, no roster row
```
With the seed library (every base `model: sonnet`; `agt_ai_agents` accepts `docs`), a `prompt × docs × ai-agents` task provably lands on Sonnet. SC-006 is a golden test over exactly such a task.

**(c) FR-007 / FR-011 / SC-004 — assembly cap ≤3 + additive-only.**
```
injected = (forced ++ ranked)[:3]     # forced = refactor-discipline if preserves_behavior
dropped  = (forced ++ ranked)[3:]     # never silently discarded
log(dropped)                          # FR-011 / SC-004
```
and, on every generated `SKILL.md`:
```
validate-skill.py:
    reject if body violates S1 (negation) | S2 (model/dispatch keys) | S3 (relaxed obligation)
```
A >3-candidate golden test asserts exactly 3 injected + the remainder logged; additive-only is a unit-testable validator, the `skill-module.md` §3 table made executable.

**FR/SC → verification method (full mapping):**

| SC | Claim | Verification method |
|---|---|---|
| SC-001 | 100% task coverage, all four fields, closed-enum values, or the run fails. | Quickstart S1 — real `tasks.md` run, inspect `categorization.md`. |
| SC-002 | `general` cap holds; over-cap produces no `categorization.md`. | Quickstart S2 — engineered over-`general` fixture; `validate-categorization.py` exit code (code-level, D58-5a). |
| SC-003 | Every task in exactly one roster row; grants column never omitted. | Quickstart S4 — inspect `agents/assignment.md`'s `## Workforce Gate` table. |
| SC-004 | No agent exceeds `base + 3` skills; drops are logged. | Quickstart S5 + the deterministic-assembly golden test (>3-candidate fixture, `extensions/agents/test/run.sh`). |
| SC-005 | Byte-identical rosters on gap-free runs; "gap-free" is verifiable (zero `built` marks), not asserted. | Quickstart S6 (double-run diff) + the golden test (frozen `categorization.fixture.md` + library snapshot, zero-AI, CI-runnable without a model). |
| SC-006 | No `prompt`-tagged task assembled below the Sonnet floor. | Quickstart S7 + the D48 guard's code assertion in `assemble.py` (golden test). |
| SC-007 | A novel tag yields exactly one persisted `SKILL.md`, `origin: generated`, source feature recorded. | Quickstart S8 — genuinely novel-tag fixture. |
| SC-008 | Every dispatch trace carries the injected skills + elevated grants matching its approved roster row. | Quickstart S10 — run `/speckit-implement-parallel` on an approved roster, inspect `traces.jsonl`. |
| SC-009 (**M3 exit**) | Full chain — categorize → assign → workforce-gate (human approves) → implement-parallel — runs end-to-end on a real feature. | Quickstart S12, dogfooded on `003-workforce` itself. |

Additionally, quickstart S9 (additive-only rejection) and S11 (reinstall-survival, D57 S3) are structural tests not tied to a numbered SC but load-bearing for FR-007 and R5 respectively — both zero-AI and CI-runnable.
