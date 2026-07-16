# Implementation Plan: OSS Front Door + Profile Contract Validator

**Branch**: `007-oss-docs` | **Date**: 2026-07-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/007-oss-docs/spec.md`

## Summary

Two independently-valuable arms make the repo ready to go public. **Arm A (US1/US2, FR-001…012):** author the OSS front door — a root `README.md`, `CONTRIBUTING`, `CODE_OF_CONDUCT`, `SECURITY`, and `.github/` issue/PR templates — every cited path/command/extension resolving at authoring time (FR-010/SC-003) and no private-context leakage (FR-011/SC-004). **Arm B (US3, FR-013…019):** build `validate-profile.py`, a dependency-free general contract validator for `profile.yaml`, enforcing `docs/contracts/profile-schema.md` v1.2 exactly (closed enums, required keys, unknown-key-is-error, the machine-enforceable `full_auto` P2∧P3 handshake), making `specs/000-sample/profile.yaml` executable (FR-015/SC-008), catching the `council_tier: standrad` silent-degrade *class* — the I-27/D79(2) illustrative example, reproduced as the SC-009 out-of-enum fixture rather than a present-tense live defect (the repo's own committed history carries no `standrad` profile value) — and **subsuming** `006`'s scoped `deck_render` check by pinning its `DECK_RENDER_ENUM` as the single source of truth via a committed equivalence test, with no divergent copy (FR-018; mechanism resolved at D-d).

**Technical approach.** The validator mirrors the repo's two existing general contract validators (`validate-categorization.py`, `validate-skill.py`) in home, structure, and the stdlib-only / runtime-discovered-PyYAML posture, reusing `006`'s interpreter-ladder YAML probe (`profile_key.py`) — the profile is a *closed contract*, so no third-party YAML dependency is warranted (FR-016/SC-010). Two decisions the `standard`-tier council defends (spec FR-019, D79(2)): **(1) the enforcement point** — recommended: a fail-closed mandatory `before_plan` hook so no autonomy-governed phase ever acts on a malformed profile, with a standalone-only alternative presented; and **(2) the schema reconciliation** — enforce `reopen_tier` and `max_rounds` exactly as the contract writes them (do not prune the I-27-flagged dead/duplicated keys — that is a schema amendment out of this feature's scope). The docs arm carries no code blast radius; its only constraints are reference-accuracy and no-leakage.

## Technical Context

**Language/Version**: Python 3 (stdlib only) for the validator — matches `validate-skill.py` / `validate-categorization.py` / `profile_key.py`. Markdown for the OSS docs. Bash for the test harness (`extensions/workforce/test/run.sh` family).

**Primary Dependencies**: **None (hard requirement, FR-016).** PyYAML is *discovered at runtime* via `profile_key.py`'s interpreter ladder (current interpreter → `graphify`/`specify` shebang interpreter → `python3` → `python` → `uv run --with pyyaml`); no `requirements.txt`, no vendored parser. The final `uv run --with pyyaml` rung is bounded by an explicit short timeout and treated as fail-fast non-zero on timeout, so an offline/restricted host cannot hang on a package fetch — preserving both the loud-non-zero guarantee and SC-010's <2s bound (R1-S06). Cross-module: consumes `DECK_RENDER_ENUM` from `extensions/deck-render/extension/scripts/profile_key.py` as the single deck_render enum SSOT (FR-018).

**Storage**: Files only — `profile.yaml` (input), the OSS docs, committed test fixtures. No database, no state file (constitution III).

**Testing**: Bash-driven golden/regression harness under `extensions/workforce/test/` (mirrors `test_categorize.sh` / `test_skill_builder.sh`); one conformant fixture passes, one fixture per targeted malformed class fails (FR-017/SC-007); a committed equivalence test pins the deck_render enum to `profile_key.DECK_RENDER_ENUM` (FR-018). Council-pinned coverage: at least one fixture asserts on **stderr message content** — it must name the offending key, never surface a raw parser traceback — not exit code alone (R1-S10); unknown-key coverage includes **both** a top-level unknown key **and** one nested inside a mapping such as `gates.council`, so a recursive-validation bug can't pass one depth while failing the other (R1-S19); a distinct **absent-optional-key defaulting** fixture exercises the default path (omitting `council_tier` ⇒ `full`; omitting `max_rounds`/`reopen_tier` ⇒ `1`/`auto`), kept separate from wrong-value fixtures (R1-S22); and `test_profile.sh` carries a **committed wall-clock <2s assertion** so SC-010's timing bound is executed, not left quickstart-only (R1-S18). The *no-PyYAML-capable-interpreter-reachable* branch is an environment property, not a file, so it is forced by **PATH/interpreter shadowing inside the harness** (a shim dir prepended to `PATH` so the ladder finds no YAML-capable interpreter) — a mechanism the harness introduces, since `test_categorize.sh` / `test_skill_builder.sh` / `test_frontmatter.py` set no precedent for it (R1-S09). Docs (Arm A) are validated by a mechanical reference-resolution + leakage grep (FR-010/FR-011) **committed as a standalone, re-runnable script** (no CI wiring, matching this feature's scope) so SC-003/SC-004 stay re-verifiable as the front door drifts (R1-S20), not a unit test. A post-merge `graphify` graph refresh is booked as a housekeeping task so FR-018's cross-extension coupling stays graph-checkable rather than resting on the stale graph plus the equivalence test alone (R1-S13).

**Target Platform**: The repo's standard developer toolchain (macOS/Linux, the same interpreters `profile_key.py` already probes). No new platform surface.

**Project Type**: Monorepo pipeline-extension + docs feature — not a `src/`+`tests/` application. Real homes below.

**Performance Goals**: Validator completes on a single profile in **under 2 seconds** (SC-010) — trivially met by a stdlib parse; the only cost is the one-time interpreter-ladder probe when the running interpreter lacks PyYAML.

**Constraints**: FR-010/SC-003 — 100% of cited paths/commands/extensions resolve at authoring. FR-011/SC-004 — zero private/internal leakage (no machine-specific absolute paths such as `/Users/<name>/…`; no personal data beyond the author name already public in `LICENSE`). FR-016 — no third-party deps. D79(2) — the enforcement wiring must not over-couple a docs feature to gate-correctness; kept separable and council-defended.

**Scale/Scope**: 5 OSS doc artifacts + 1 validator (~1 source file + 1 committed install copy) + test harness + fixtures + 1 enforcement-wiring task (council-cuttable) + this feature's own `profile.yaml`. Validator subject set: the 6 present + 2 absent committed profiles (`specs/00{0..7}`), all of which must validate correctly.

## Constitution Check

*GATE: evaluated against `.specify/memory/constitution.md` v1.0.0. Re-checked post-design (below).*

| Principle | Verdict | Note |
|---|---|---|
| I. Artifacts Are the Contract | **PASS** | The validator writes no artifact; like `verify-gate`/`cleanup.sh` it is a mechanical pass/fail on an existing artifact (`profile.yaml`). No phase is made to write two artifacts. |
| II. Context Hygiene | **PASS** | No new offloaded session. The validator is inline, mechanical, model-free. Docs are authored by dispatched implementation agents returning their file (normal). |
| III. Resumability (NON-NEGOTIABLE) | **PASS** | No state file (D32). The validator is a pure function of `profile.yaml` → exit code; the FR-019 hook adds no state, only a fail-closed check. |
| IV. Observability | **PASS** | The validator is model-free, so like `speckit-git-cleanup`/`verify-gate` it writes **no** `traces.jsonl` record. Docs-authoring sessions trace as normal implementation agents. |
| V. Subscription-Only Billing (NON-NEGOTIABLE) | **PASS — reinforced** | Validator is stdlib, no network, no API key. FR-005 makes the README *document* the `ANTHROPIC_API_KEY`-unset stance (D28). |
| Model Policy (D18) | **PASS** | Validator = mechanical (no model). Docs = Sonnet implementation agents. Council chairman = Opus. No `(role, model)` contradiction introduced. |
| Autonomy & Gates (D9) | **PASS — with a council-defended tension** | **No third gate is added.** The validator enforces the profile that *configures* the two existing gates; wiring it (FR-019) does not create a gate, it prevents a malformed profile from silently mis-configuring one — reinforcing D9's `full_auto` handshake. The D79(2) coupling concern (a docs feature touching the council gate's correctness guard) is a **proportionality** question for the council, recorded in Complexity Tracking — not a constitution violation. |

**Result: PASS (no unjustified violations).** One design tension (FR-019 enforcement proportionality, D79(2)) is booked in Complexity Tracking and carried to the council per the spec.

## Project Structure

### Documentation (this feature)

```text
specs/007-oss-docs/
├── spec.md                     # complete (US1-3, FR-001..019, SC-001..011)
├── plan.md                     # this file
├── research.md                 # Phase 0 — decisions D-a..D-f below
├── data-model.md               # Phase 1 — the 4 entities + validation rules
├── quickstart.md               # Phase 1 — runnable validation scenarios (SC-mapped)
├── contracts/
│   └── validate-profile.md      # Phase 1 — the validator's CLI + verdict contract
├── graphify-context.md         # grounding (already generated)
└── profile.yaml                # NEW — 007's own profile (standard tier, both human)
```

### Source Code (repository root)

```text
# Arm B — the profile validator (mirrors the two existing general validators)
extensions/workforce/extension/scripts/
├── validate-profile.py          # NEW — the general profile.yaml contract validator
├── validate-categorization.py   # exists — structural exemplar (ValidationResult, main())
└── validate-skill.py            # exists — structural exemplar (check_* predicates, self-test, fixtures)
.specify/extensions/workforce/scripts/
└── validate-profile.py          # NEW — committed installed copy (both trees are tracked)

extensions/deck-render/extension/scripts/
└── profile_key.py               # UNCHANGED — DECK_RENDER_ENUM SSOT + render-time scoped check (FR-018 consumes its enum)

extensions/workforce/test/
├── run.sh                        # exists — register the new test here
├── test_profile.sh              # NEW — both-branch golden/regression + 000-sample-passes + enum-equivalence
└── fixtures/profile/            # NEW — conformant + pass-branch + defaulting + 1-per-malformed-class + enum-equivalence pin
    ├── conformant.yaml
    ├── full-auto-satisfied.yaml   # PASS branch — full_auto: true + both gates auto ⇒ VALID (P2∧P3, R1-S01)
    ├── defaults-omitted.yaml      # PASS branch — optional keys absent ⇒ council_tier=full, max_rounds=1, reopen_tier=auto (R1-S22)
    ├── out-of-enum.yaml           # council_tier: standrad — the SC-009 illustrative-class fixture
    ├── unknown-key.yaml           # top-level unknown key
    ├── unknown-key-nested.yaml    # unknown key nested under gates.council (R1-S19)
    ├── schema-version-mismatch.yaml  # schema_version: "2.0" ⇒ fail — value-checked, not presence-only (R1-S04)
    ├── full-auto-unsatisfied.yaml
    └── ...                        # gate-scalar, feature-mismatch, max_rounds>1, bad-YAML, deck_render-out-of-enum

# FR-019 enforcement wiring (SEPARABLE — council may cut to standalone-only)
.specify/extensions.yml           # + a mandatory fail-closed validate-profile hook at PRIORITY 1 (matching the two existing priority-1 verify-gate hooks; the before_plan graphify hook sits at 5), re-validating at the actual consumption points — before_plan AND before_tasks/before_implement — not before_plan alone (R1-S03, R1-S21)
<owner-ext>/skills/speckit-validate-profile/   # thin skill wrapper (cli-command-wrapper pattern): resolve profile path → shell out → hard-block on non-zero. Wiring task carries an explicit dependency edge on validate-profile.py + a green test_profile.sh suite, so a parallel wave cannot register the fail-closed hook before the script is hardened (R1-S11)

# Arm A — the OSS front door (all NEW; LICENSE already exists, referenced not recreated)
README.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SECURITY.md
.github/
├── ISSUE_TEMPLATE/
│   ├── bug_report.md             # prompts: repro, affected artifact/phase
│   └── feature_request.md
└── PULL_REQUEST_TEMPLATE.md      # prompts: phase-tagged commit, matching D-row/I-row
```

**Structure Decision**: The validator lives with the repo's two existing general contract validators in `extensions/workforce/extension/scripts/` (+ its tracked install mirror), tested by the existing `extensions/workforce/test/` harness — the lowest-surprise home and the pattern I-27 named ("one stdlib `validate-profile.py`, the `frontmatter.py` no-PyYAML precedent"). `profile_key.py` is **not** edited; the general validator consumes its `DECK_RENDER_ENUM` export. The OSS docs sit at the repo root and under `.github/` per GitHub community-health conventions. The FR-019 hook wiring is isolated to `.specify/extensions.yml` + one thin skill so the council can excise it without touching Arm B's validator. Source↔install-mirror sync (`extensions/workforce/extension/scripts/validate-profile.py` ↔ `.specify/extensions/workforce/scripts/validate-profile.py`) is guaranteed by the repo's existing extension install/reinstall mechanism (the installer copies the source tree into `.specify/…`); the plan adds no second sync path, and the drift check rides the install-idempotency coverage the workforce extension already carries — no unguarded drift copy (R1-S15). Arm A (docs) and Arm B (validator) share no code and have disjoint testability, so `/speckit-tasks` sequences them as two **independent task sequences** within this one feature — a stall in one arm's review or implementation must not block the other (R1-S17; a sequencing split only — D82 keeps them a single feature, not a scope re-split).

## Complexity Tracking

> The Constitution Check passes; this row records the one design tension the spec explicitly routes to the council (D79(2)), not a constitution violation.

| Tension | Why it is in this feature | Simpler alternative & why it is presented, not chosen |
|---|---|---|
| **FR-019 enforcement wiring couples a docs feature to the council gate's correctness guard** (a malformed profile blocking a phase changes gate-adjacent behavior — D79(2)). | The owner folded I-27 into `007` (D82); FR-019 requires a malformed profile be *mechanically rejected before the pipeline acts on it*, which a purely on-demand tool cannot guarantee. Recommended: a fail-closed `before_plan` hook — validating at the pipeline's front means **no gate ever reasons about an invalid profile**, so gate internals are untouched; only well-formed profiles reach the council/workforce gates. | **Standalone-only** (script + optional command, no hook): fully decouples the docs feature from gate-correctness per D79(2)'s original caution, but downgrades FR-019's "before the pipeline acts on it" MUST to a convention someone must remember to run. Presented to the council as the conservative option; the wiring is a separable task so it can be cut without disturbing the validator. |

**Enforcement point — decision (R1-S03).** The recommended hook is **not** `before_plan`-only. A single point-in-time `before_plan` check cannot uphold "no gate ever reasons about an invalid profile," because `profile.yaml` stays mutable and is never SHA-pinned into `gates.yml`: an edit made *after* the check still reaches `/speckit-council`'s `council_tier` read or `before_implement`'s `gates.workforce` read unvalidated. So the validator re-runs at the **actual consumption points**, mirroring the repo's existing priority-1 `verify-gate` pattern — `before_plan`, `before_tasks`, **and** `before_implement` — rather than trusting one early check. (This supersedes the plan's earlier `before_plan`-only recommendation; standalone-only remains the council-cuttable conservative fallback.)

**Adoption pre-flight (R1-S05).** Before the fail-closed hook is wired live, a one-time task runs `validate-profile.py` against every currently-committed `specs/*/profile.yaml`, so adoption day cannot retroactively hard-block an in-flight feature's `plan` phase on a profile that predates the validator — the "all `specs/00{0..7}` must validate" claim is *executed*, not merely asserted plan-time.

**Compound blast-radius risk + bypass (R1-S08).** Wiring the fail-closed check into every feature's mandatory `plan`/`tasks`/`implement` boundary promotes `profile_key.py`'s interpreter probe from gating one optional feature (deck-render) to gating the whole pipeline: a validator false-positive on an untested-but-legitimate profile, or a host with no reachable PyYAML-capable interpreter, becomes a repo-wide planning outage whose exit code is indistinguishable from a genuinely malformed profile. **Decision: no silent bypass exists, by design** — a fail-open escape hatch would reintroduce exactly the silent mis-configuration this feature closes. The residual is bounded instead by (a) the interpreter-ladder timeout (R1-S06) turning the unreachable-interpreter case into a fast, clearly-messaged failure, (b) the stderr-content assertion (R1-S10) making a validator bug legible rather than a bare traceback, and (c) the adoption pre-flight (R1-S05) catching legitimate-profile false-positives before the hook goes live. A human unblocks only by correcting the profile or, deliberately and out-of-band, editing the hook registration.

## Phase 0 — Research (decisions)

Resolved decisions consolidated in [research.md](./research.md): **D-a** validator home & structure (mirror the two existing general validators); **D-b** dependency-free YAML strategy (reuse `profile_key.py`'s runtime interpreter ladder); **D-c** the exact rule set enforced (profile-schema.md v1.2, machine-enforceable subset of P1–P5) — including a **value** check on `schema_version` (exact-match `1.2`, not presence/type only), so a typo'd or wrong version (`2.0`, `1.O`) fails with one clear version-mismatch message instead of a pile of unknown-key errors at the next schema bump, pinned by a `schema-version-mismatch.yaml` fixture (R1-S04); **D-d** FR-018 subsumption mechanism — **resolved (R1-S07): a pinned local `DECK_RENDER_ENUM` constant in `validate-profile.py` guarded by a committed equivalence test against `profile_key.DECK_RENDER_ENUM`, not a runtime cross-extension import**. The two scripts sit in different, package-less extension `scripts/` trees, so a runtime import would need fragile `sys.path` surgery across trees; the equivalence test delivers the same single-source-of-truth guarantee (drift fails the suite loudly) without that fragility, and is exactly what "no divergent copy" means here; **D-e** schema reconciliation (enforce `reopen_tier`/`max_rounds` as written — do not prune), **distinguishing the two (R1-S12)**: `reopen_tier` is *not* a dead key — `profile-schema.md` gives it live triage behavior today (`auto` ⇒ triage proposes / human confirms; `delta`/`full` pin the tier and skip the proposal), whereas `max_rounds` is genuinely inert (validators reject `>1`); the closed-enum check catches a typo in either, but the plan must not frame both as dead; **D-f** FR-019 enforcement point (recommend fail-closed `before_plan` hook; council-defended). No open NEEDS CLARIFICATION remain.

## Phase 1 — Design & Contracts

- [data-model.md](./data-model.md) — the four entities (OSS doc set, profile validator, profile contract, `profile.yaml`) with the validator's full field/enum/handshake rule table and verdict states.
- [contracts/validate-profile.md](./contracts/validate-profile.md) — the validator's CLI surface, exit-code contract (0 = valid incl. absent; non-zero = a named failure class), message shape, and the FR-018 enum-consumption contract.
- [quickstart.md](./quickstart.md) — runnable validation scenarios binding every SC and both doc-arm and validator-arm acceptance tests to a concrete command/check.

> **Residual drift risk (R1-S16):** only the `deck_render` enum gets an equivalence guard; the broader prose-vs-code contract (`profile-schema.md`'s required keys / enums / P1–P5 handshake vs `validate-profile.py`'s hardcoded rules) has no automated guard, so the schema and its enforcer could drift — the same prose-vs-enforcement gap this feature closes for `profile.yaml`, one level up. This feature **accepts** that residual (a full schema-conformance test is out of scope) and flags it explicitly for the future schema amendment D-e already anticipates, rather than leaving it silent.

## Phase 2 — (out of scope for /speckit-plan)

`/speckit-tasks` generates `tasks.md`. Council defense (`/speckit-council`) runs first at `standard` tier per this feature's profile; the council weighs the two defense points above (FR-019 enforcement, schema reconciliation) before tasks.
