# Implementation Plan: The Workforce Pair — Task Categorization & Agent Assembly

**Branch**: `003-workforce` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-workforce/spec.md`

**Grounding**: [graphify-context.md](./graphify-context.md) (fresh D59 baseline, 497 nodes / 888 edges).

> **Round-1 council triage revision (2026-07-10).** This plan folds all **25 accepted** suggestions (R1-S01…R1-S25) and three owner rulings: **D60** (grant `web_search` to the skill builder — the system's first elevated grant), **D61** (`council_tier` default flips to `standard`), **D62** (deck-prep improvement task). Both blocking items resolved here — **S01** (total-order every set before serialization) and **S02** (the workforce gate-*write* path, clustered with **S10**+**S13**: the pair becomes **one `workforce` extension** with a dedicated approve command, and git-ext generalizes its gate-record hook). Dispositions + reasoning: [council/decision-record.md](./council/decision-record.md).

## Summary

Build the M3 workforce pair as **one pipeline extension — `speckit-ext-workforce`** (S10: a single `extensions/workforce/` tree echoing `extensions/council/`'s one-directory/multi-command shape) exposing **three commands**: `/speckit-categorize` (the categorizer), `/speckit-agent-assign` (the skill builder + the assembler), and `/speckit-workforce-approve` (the dedicated workforce-gate approval, mirroring `/speckit-council-approve`). The categorizer is a Sonnet session that tags every task with the blessed taxonomy v0 and writes `categorization.md`, guarded by a **code** validator that fails the phase on an over-cap or out-of-enum categorization. The assembler is a **deterministic script** (`assemble.py`) implementing `agent-library-schema.md` §3 verbatim — base lookup, tag-ranked skill injection (cap 3), grant union, the D48 Sonnet-floor guard — and **it writes the roster table itself** (S08: a tool-permission fact, not a prose promise). Every set-typed intermediate is **total-ordered before serialization** (S01), so the roster is byte-reproducible on gap-free runs (FR-015/SC-005). On a ∅-match the script hands off to a Sonnet **skill builder** — now holding a **declared `web_search` grant** (D60) — that authors one additive-only `SKILL.md` whose tags must intersect the triggering task's (S04), persists it (the D24 flywheel), and re-runs assembly. The roster lands in `agents/assignment.md`'s `## Workforce Gate`; **`/speckit-workforce-approve` records the human's signature and fires git-ext's generalized `on-gate-approve` hook** to bind `tasks.md`+`assignment.md` into git-ext-owned `gates.yml` (S02/S13); `/speckit-implement-parallel` then consumes the roster and every dispatch trace carries the assembly (D43).

The technical approach splits the LLM work from the deterministic work by design: **categorization = inference (Sonnet), assembly = code, skill-building = inference (Sonnet)**. That split is what lets one artifact (`categorization.md`) be a non-reproducible LLM product while the roster built from it is byte-reproducible.

## Technical Context

**Language/Version**: Bash (installers, hooks, config — mirrors git-ext) + **Python 3** (the deterministic `assemble.py` matcher and the `skill-module` validator). Python 3 is **already established** by graphify (Technical Context adds **no new runtime dependency**, S19). Frontmatter parsing uses **one shared, independently unit-tested `frontmatter.py` module** (S21) consumed by both `assemble.py` and `validate-skill.py` — never two hand-rolled copies (a second parser is the same silent-divergence hazard that motivated rejecting Bash for the matcher). It parses only the closed `specseyal:` shape (`agent-library-schema.md` §1.1 / `skill-module.md` §1); `body_sha256` uses the §2 reference definition.

**Primary Dependencies**: the five M0 contracts the pair consumes — `taxonomy-v0.md` (BLESSED), `agent-library-schema.md` §3/§4, `skill-module.md`, `artifact-layout.md` §2/§6/§8/§9, `trace-schema.md` §1/§5. Claude Code's native `.claude/agents/` + `.claude/skills/` loaders. The git extension (its generalized `on-gate-approve` action + the `before_implement` workforce `verify-gate` hook) — an install-order dependency (S25/sequencing). The three existing extensions as packaging exemplars.

**Storage**: repo files only — `categorization.md`, `agents/assignment.md` (feature tree); `.claude/agents/*.md` + `.claude/skills/*/SKILL.md` (the per-repo library, D17). No database (Resumability III).

**Testing**: one `extensions/workforce/test/run.sh` (the git-ext model, D57 S3): install → reinstall-survival → the deterministic-assembly golden test → validator unit checks → the committed per-SC tests (see § Plan-time verifications, S12). Dogfood exit test = SC-009 on `003` itself.

**Target Platform**: Claude Code CLI (interactive, subscription-only, D28); M6 Agent SDK later — no change to these artifacts.

**Project Type**: **one** pipeline extension (`extensions/workforce/`, S10) + a seed library — the `extensions/<name>/` sibling pattern (D26 monorepo layout).

**Performance Goals**: assembly is O(tasks × skills) Jaccard — trivial at pipeline scale. **Determinism, not speed, is the property that matters** (SC-005).

**Constraints**: subscription-only (V/D28, no `ANTHROPIC_API_KEY`); Sonnet floor for the categorizer, skill builder, and every base (D18); additive-only skills (D40.4); assembly cap 3 (D40); single-writer artifacts (§6/D37); the skill builder's **one declared elevated grant is `web_search`** (D60) — every other role is core-toolset-only.

**Scale/Scope**: 1 extension (3 commands) + **7 seed base specialists + 5 seed skills** + the deck-prep improvement task (D62). Indicative task count ~24–30, across categorizer · skill-builder · assembler · approve-command · seed-library · git-ext-generalization · install/test.

## Constitution Check

*GATE: evaluated before Phase 0 and re-checked after design + after Round-1 revision. PASSES (no violations).*

| Principle | Verdict | How this plan honors it |
|---|---|---|
| **I. Artifacts Are the Contract** | ✅ | `categorize` writes **only** `categorization.md` (D37); `agent-assign` writes **only** `agents/assignment.md`; `workforce-approve` writes **only** the `## Workforce Gate` section (mirroring `/speckit-council-approve`). The skill builder's `SKILL.md` persistence writes to the repo-root **library** (`.claude/skills/`), *outside* the feature tree — the sanctioned D24 flywheel (note ★). One extension, three single-writer commands. |
| **II. Context Hygiene** | ✅ | Categorizer, skill builder, and (on a gap) the builder each run as **separate Sonnet sessions** returning one compact artifact. The deterministic `assemble.py` matcher is a script — no main-thread context. |
| **III. Resumability (NON-NEGOTIABLE)** | ✅ | Phase state inferred from artifacts (D32). Determinism (FR-015, now with total-ordered serialization S01) makes a re-run idempotent; a **library-snapshot hash stamped in the roster** (S18) makes the reproducibility claim machine-checkable. |
| **IV. Observability** | ✅ | Categorizer (`categorizer`) and skill builder (`agent-creator`) append one `traces.jsonl` record each; the builder's dispatch records `elevated_grants: ["web_search"]` when it searched (D60/D43); implement dispatches carry `skills[]` + `elevated_grants[]` (FR-021). Note ★★ on the gap-free assembly trace. |
| **V. Subscription-Only (NON-NEGOTIABLE)** | ✅ | Categorizer + skill builder run on subscription (Sonnet); `web_search` is a Claude Code tool, **not** an API key — no `ANTHROPIC_API_KEY`. The `assemble.py`/validator scripts are zero-AI. |
| **Model Policy (D18)** | ✅ | Categorizer + skill builder = Sonnet. Every seed base declares `model: sonnet`. The D48 guard holds the Sonnet floor for `prompt`-tagged tasks **in code**, and SC-006 now exercises the guard's `else` branch against a synthetic non-Sonnet fixture base (S03). |
| **Autonomy & Gates (D9)** | ✅ | The workforce gate: categorizer + assembler **PROPOSE**, human **signs via `/speckit-workforce-approve`** (`gates.workforce.mode: human`). `auto` only under `full_auto` (§8 W4), in which case the assigner writes the section — the approve command's auto codepath mirrors `/speckit-council-triage`'s. |

★ **The flywheel write is not a principle-I violation.** The generated `SKILL.md` lands in the repo-root library `.claude/skills/` — shared infrastructure, the sanctioned D24 self-evolving component, and (S07) it lives **outside** any extension's `rm -rf` install payload: the library is **user/flywheel data, not extension payload**, so no reinstall (self or foreign) can clobber it.

★★ **Gap-free assembly may legitimately run no model session** (Risk R2) — the deterministic matcher is mechanical (git-ext precedent). The `agent-creator` trace appears when the skill builder fires. Flagged for ratification, not forced.

## Project Structure

### Documentation (this feature)

```text
specs/003-workforce/
├── plan.md · research.md · data-model.md · quickstart.md · contracts/commands.md
├── graphify-context.md · graph-baseline.json (committed D59 council baseline)
└── council/  (defense-deck/, round-1/{opinions/,suggestions.md}, decision-record.md)
```

### Source Code (repository root)

```text
extensions/workforce/                       # speckit-ext-workforce — ONE extension (S10; mirrors extensions/council/)
├── install.sh · uninstall.sh               # copy source → .specify/extensions/workforce/ + .claude/skills/; SEED library additively; deregister-first
├── extension/
│   ├── extension.yml                        # registers 3 commands + the after_categorize / after_agent-assign / after_workforce_approve hook points (S25)
│   ├── workforce-config.yml                 # general_cap 0.20, assembly_cap 3, model sonnet, seed-library manifest, skill_builder.web_search: true (D60)
│   ├── commands/
│   │   ├── speckit.categorize.md
│   │   ├── speckit.agent-assign.md
│   │   └── speckit.workforce-approve.md      # NEW (S13) — records the human signature, fires git-ext on-gate-approve
│   ├── scripts/
│   │   ├── frontmatter.py                    # SHARED closed-shape parser (S21), unit-tested; imported by the two below
│   │   ├── assemble.py                       # DETERMINISTIC §3 matcher; TOTAL-ORDERS every set before serialize (S01); WRITES the roster table itself (S08); stamps library-snapshot hash (S18) + FR-022 library|built marks
│   │   ├── validate-categorization.py        # cap + enum + coverage check; asserts no-write on breach (FR-004/SC-001/SC-002)
│   │   └── validate-skill.py                 # skill-module S1-S3 + tag-intersection with triggering task (S04)
│   └── templates/categorizer-prompt.md · skill-builder-prompt.md · assignment.template.md · skill-module.template.md
├── seed/agents/agt-*.md  ·  seed/skills/*/SKILL.md   # 7 bases + 5 skills (§ Seed Library)
├── skills/speckit-categorize/ · speckit-agent-assign/ · speckit-workforce-approve/ (SKILL.md each)
└── test/run.sh

# git extension — own-source generalization (D57 S2; git owns gates.yml, D55/Q1):
extensions/git/extension/scripts/on-council-approve.sh  →  on-gate-approve.sh   # gate-agnostic (S02): takes a {council|workforce} gate arg, records plan.md@sha OR tasks.md+assignment.md@sha into gates.yml
extensions/git/extension/extension.yml                                          # after_council_approve + NEW after_workforce_approve → on-gate-approve.sh <gate>
# reinstall git-ext after this edit; the S07/S17 reinstall-survival regression proves both gate wirings fire.

.claude/agents/  ·  .claude/skills/          # the live per-repo library (D17), seeded additively; OUTSIDE the install rm -rf payload (S07)
```

**Structure Decision**: **one `extensions/workforce/` tree** (S10) — the packaging echo of the one-feature ruling; a dedicated `/speckit-workforce-approve` command (S13) is the natural home for the gate signature and the gate-write trigger. The **deterministic core is a script** (`assemble.py`) that **writes its own output artifact** (S08) — the decision that makes SC-005 real *by mechanism*, not prose. The **`.specify/extensions.yml` hook-merge** is the one shared/mutable file both new-extension installs touch; S06 corrects the earlier "degree 15" framing — three `graphify explain` runs return **degree 1** (one inbound edge), so it is **not** a graph-computed hub. The real concern is that the YAML merge is a **lock-free read-modify-write**: `install.sh` performs the merge under a **`flock` (or atomic write-to-temp + `mv` rename)** and a defined install order (git before workforce, so the `verify-gate`/`on-gate-approve` hooks exist first). Cross-extension coupling is a **hook point**, never a foreign source edit (D57 §9); the one unavoidable source edit — generalizing git-ext's gate-record action — lives in **git-ext's own source** (S02, D57 S2). The **self-hook-check** that fires `after_categorize`/`after_agent-assign`/`after_workforce_approve` is registered in `workforce/extension.yml` and invoked by the installed-registry dispatch (S25 — named explicitly, not assumed to "just work" by analogy; the `after_council_approve` precedent is invoked from the registry, not its command file).

## Architecture & data flow

```
tasks.md + plan.md ──▶ [categorize: Sonnet] ──▶ categorization.md
     └─ validate-categorization.py (CODE): coverage+enum (SC-001) AND general≤20% (FR-004) else FAIL + NO WRITE (asserted, S22)
categorization.md (+ its tasks.md SHA binding, S14) + library ──▶ [agent-assign command]
   1. assemble.py (CODE, deterministic §3): base lookup; tag-Jaccard rank; force refactor-discipline if preserves_behavior; inject first-3 + LOG dropped;
      grant union — TOTAL-ORDERED before serialize (S01); D48 guard (prompt⇒Sonnet else hard-error); mark library|built (FR-022); stamp library-snapshot hash (S18).
      assemble.py ITSELF writes agents/assignment.md's Workforce Gate table (S08) ──▶ roster + ∅-match gap list.
   2. if gaps: [skill-builder: Sonnet, grant web_search (D60)] ──▶ new SKILL.md (additive-only; tags MUST ∩ triggering task's tags, S04; stale-knowledge flag if it did NOT search, S17) ──▶ validate-skill.py ──▶ .claude/skills/ (flywheel, D24)
   3. assemble.py re-run — STABLE (S15): only the gap task's row may change; every already-matched task's row is byte-identical (checkable via FR-022 marks + the snapshot hash).
   4. [workforce-approve command] records the human decision in ## Workforce Gate; fires git-ext after_workforce_approve → on-gate-approve.sh workforce ──▶ binds tasks.md+assignment.md@sha into gates.yml (S02/S13).
[before_implement verify-gate (git, workforce)] ──▶ /speckit-implement-parallel dispatches each assembled agent ──▶ trace carries skills[]+elevated_grants[] (FR-021/D43)
```

- **Categorization freshness (S14):** `categorization.md` records the `tasks.md` SHA it was derived from; if `assemble.py` sees `tasks.md` has moved, it **hard-warns and routes to re-categorize** rather than assembling against stale classification — closing the prose-only phase-order risk R1 flagged for sequencing itself.
- **Determinism, three reinforcements (S01/S08/S18):** total-ordered serialization (no `PYTHONHASHSEED` leak), the script (not an LLM) writing the artifact, and a library-snapshot hash stamped in the roster so SC-005 is checkable in one line.
- **Gap-rerun stability (S15):** the re-run recomputes every task, but a newly built skill can only *win* on the gap task; unrelated rows are proven identical by their unchanged FR-022 marks + snapshot hash. A ≥2-task, one-gap golden fixture asserts it.

## Seed Library (proposed — council-reviewed, R1-S11/S16 applied)

Fitted to the empirically-exercised lanes of the two real dogfood features (001: `ai-agents`×10 + `devtools-cli`×9; 002: `devtools-cli`×15, `security`×3, `qa-automation`×3, `ai-agents`×2). **Bases curated-static (D44); skills alone evolve (D24).**

### Base specialists — 7 (`.claude/agents/agt-*.md`, all `model: sonnet`)

| `id` | Specialization | Accepts `type` | Evidence tier |
|---|---|---|---|
| `agt_ai_agents` | `ai-agents` | service, endpoint, scaffold, test, **docs** | ✅ dogfood (001). Accepts `docs` so a `prompt`-tagged (`docs × ai-agents`) task lands on a **Sonnet** base (D48 floor by construction). |
| `agt_devtools_cli` | `devtools-cli` | scaffold, service, endpoint, test, infra | ✅ dogfood (001+002 dominant). |
| `agt_security` | `security` | service, endpoint, test | ✅ dogfood (002 gate-integrity trio). |
| `agt_qa_automation` | `qa-automation` | test, scaffold | ✅ dogfood (002). |
| `agt_backend_service` | `backend-service` | data-model, service, endpoint, test | ⚠ **`provisional: true`** (S11) — seeded on the taxonomy worked-example only, **not** dogfood evidence; the metadata flag makes the weaker basis visible, not silent. |
| `agt_data_persistence` | `data-persistence` | data-model, service | ⚠ **`provisional: true`** (S11) — same worked-example-only basis. |
| `agt_generic` | `general` | *(all 7 implementation types)* | The FR-016 fallback for any unmatched `(type, specialization)` + every `general` task; empty lane reported on the roster. |

**Type-coverage matrix (S16):** the seven bases' `taxonomy.type` lists jointly cover **all 7 implementation types** across their lanes; `docs` is covered (via `agt_ai_agents`, D48). Any `(type, specialization)` whose specialization is one of the four **unseeded** lanes (`frontend-web`, `mobile`, `infra-platform`, `performance`) routes to `agt_generic` + a **reported** empty lane **by design** — stated, not accidental; it earns each lane its first dogfood evidence for v0→v1. `provisional: true` is a library-metadata field (ignored by matching; surfaced in the roster + v0→v1 review).

### Seed skills — 5 (`.claude/skills/*/SKILL.md`)

`skl_refactor_discipline` (seed, exists; auto-inject on `preserves_behavior`, `grants: []`) · `skl_orchestration` (orchestration/subagent/dispatch/parallel, `[]`) · `skl_shell_scripting` (bash/shell/posix/install, `[]`) · `skl_yaml_hooks` (yaml/config/manifest/hooks, `[]`) · `skl_installer_hygiene` (install/uninstall/idempotent/reinstall, `[]`). **All seed skills `grants: []`** — the first elevated grant in the system is the skill builder's `web_search` (D60), a deliberate, gate-visible event, never a seed default. `skl_refactor_discipline` relocates from the `000-sample` fixture into the live repo-root library.

## The `web_search` grant — GRANTED to the skill builder (owner ruling D60; R1-S20)

The spec's OPEN item is **resolved by the owner: the skill-builder role declares `web_search`** — the system's **first elevated grant** (D41). Conditions, all mechanical:
- **Declared in the builder's skill-module frontmatter** (`grants: [web_search]`, per A-2) — not a role-level ambient default; it reaches a dispatch only via that declaration.
- **Surfaces on every roster** whose assembly includes the builder path — **003's own workforce gate displays it: the first elevated grant a human approves** (D41/§8 W2).
- **Recorded in traces** `elevated_grants: ["web_search"]` on any builder dispatch that searched (D43).
- **The S17 stale-knowledge flag ships anyway** as a complement: when the builder authors a module for a framework past its training cutoff and **chose not to search**, it stamps a `provenance.stale_risk: true` flag — so a confidently-stale module is visible even with the grant available. *(D60 rationale: a builder authoring skills for post-cutoff frameworks without search produces confidently-stale modules — the exact failure A-2's grant machinery exists to make visible and governable; granting search + flagging non-search is the honest resolution.)*

This retires the plan's earlier Option-A recommendation. The audit invariant holds: the grant is skill-declared, gate-visible, and trace-recorded — network reach in the system is still 100% accounted for.

## Plan-time verifications & per-SC test coverage (D58-5 + R1-S03/05/09/12/22/23/24)

Every SC with a mechanical existence-proof gets a **committed test** in `test/run.sh`; judgment-SCs are documented manual checks with a named procedure (S12). The full map:

| SC | Enforcement | Committed test? |
|---|---|---|
| SC-001 (coverage + closed enums) | **CODE** — `validate-categorization.py` checks all four fields + enum membership before write (S05: enforcement pinned, no longer "manual") | ✅ fixture: a malformed categorization → non-zero exit |
| SC-002 (over-cap fails, no write) | **CODE** — cap check; test asserts **both** non-zero exit **and** file-absence / unchanged-dir diff (S22) | ✅ over-cap fixture |
| SC-003 (roster completeness) | roster columns mandatory; **plus a grant-union correctness test** with **≥2 grant-declaring skills** asserting no grant dropped/mis-merged (S09) | ✅ multi-grant fixture |
| SC-004 (cap ≤3 + logged drops) | `assemble.py` injects first-3, logs remainder | ✅ >3-candidate fixture |
| SC-005 (gap-free determinism) | total-order (S01) + script-writes-artifact (S08) + snapshot hash (S18); golden test asserts **byte-identical roster incl. grant ORDER** | ✅ double-run diff |
| SC-006 (Sonnet floor) | `assemble.py` D48 guard; **synthetic non-Sonnet fixture base** added to the frozen snapshot so the guard's `else: hard-error` branch actually executes (S03) | ✅ prompt-task + non-Sonnet-base fixture |
| SC-007 (∅-match → one SKILL.md) | builder authors one; **dedup fixture: two tasks sharing one novel tag** → assert exactly one persisted, not one-per-task (S24) | ✅ shared-novel-tag fixture |
| SC-008 (traces carry assembly) | **a committed script** diffs each dispatch trace's `skills[]`/`elevated_grants[]` against its approved roster row (S23 — not human inspection) | ✅ trace↔roster diff script |
| SC-009 (M3 exit) | dogfood chain on 003 itself | manual (documented procedure) |
| S9 additive-only | `validate-skill.py` rejects S1–S3 violations | ✅ negation/override fixture |

**R1 determinism-boundary mitigation (S08), both axes:** (1) `assemble.py` **itself** is the tool-call writer of the Workforce Gate table — the session structurally cannot hand-transcribe or re-rank (the D53 prose→mechanism lesson); (2) a committed integration test runs the **real skill-builder** on a gap fixture and asserts the roster reflects only `assemble.py`'s algorithm (catches ranking influence).

## Risks flagged for the council → dispositions applied

- **R1 — Determinism boundary.** Mitigated by S01 (total order) + S08 (script writes the artifact + integration test). Residual: none blocking.
- **R2 — Gap-free assign may leave no `agent-creator` trace.** Recommendation stands (mechanical phase, git-ext precedent); **S18** stamps a snapshot hash so even a trace-less run leaves a machine-checkable record. Council to ratify the trace-schema §2 reading.
- **R3 — Seed-library overfit (OQ6).** Now **visible**: the two worked-example-only bases carry `provisional: true` (S11); v0→v1 (taxonomy §8) re-tests all lanes. Per-repo library (D17) bounds it.
- **R5 — Flywheel write vs. reinstall.** Resolved (S07): the library lives **outside** the install `rm -rf` payload (user/flywheel data), so neither a foreign nor a **self** reinstall clobbers a generated skill; the builder checks the live `.claude/skills/` listing before naming and **hard-fails (or warns+renames)** on a collision — never a silent skip. `test/run.sh` reinstall-survival covers both.
- **R6 — `web_search`.** Resolved by owner ruling D60 (granted, above).

## Complexity Tracking

*No unjustified constitution violations.* The one nuance (★) — the flywheel writing `SKILL.md` outside the feature tree — is sanctioned D24 behavior, recorded in the Constitution Check.

| Item | Why needed | Simpler alternative rejected because |
|---|---|---|
| Python for `assemble.py` (not Bash) | Deterministic frontmatter parse + Jaccard + total-order tie-break (§3 step 4) must be exact/testable; **total-ordered serialization** (S01) is trivial in Python, fragile in shell sort | Bash+`yq` ranking breaks the total order silently → breaks SC-005, the one property the feature exists to guarantee. *(Python is already a repo dependency via graphify — no new-runtime cost, S19.)* |
| One `workforce` extension, three commands | S10: packaging echo of the one-feature ruling; S13's dedicated approve command + S02's gate-write hook share one natural home | Two independent extensions double install/uninstall/test/packaging and force cross-extension `after_*`→`git.commit` hook coupling for an internal two-step sequence |

## Round-1 revision task addendum (D62 — deck-prep improvement)

Add to `tasks.md`: **mine this round's five member transcripts** for which `plan.md` sections the four plan-readers actually pulled (read-rate was 4/5 plan · 1/5 spec · 3/5 graph), then **enrich the deck-prep template** (`extensions/council/` **own source**, D57 S2; reinstall after) so those high-demand sections ride in the technical deck by default. **After-metric:** the `plan.md` read-rate at the *next* council run — target: the deck trusted by a majority of the bench (fewer members needing to open `plan.md`).
