# Implementation Plan: Pre-Public Maintenance & Adopter Experience

**Branch**: `008-pre-public-maintenance` | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-pre-public-maintenance/spec.md`

## Summary

A six-item, pre-public maintenance sweep — the `docs/90` "Actionable-now cluster" (D84) — that removes the remaining rough edges before the D73 visibility flip. Every item is **additive, bounded, independently testable, and touches no gate _semantics_** (FR-015, the deliberate contrast with `007`). Two items carry weight — a **clone-free one-command install** (US1/I-32) and a **contract conformance checker** (US2/I-11) — and four are **latent-defect hardenings** (US3: I-23 git-ext manual-fallback, I-26 augment inline-comment strip, I-29 council apparatus provenance, I-31 implement-parallel trace guard).

**Technical approach**: All work is bash + Python-3-stdlib, matching the repo's existing zero-third-party-dependency tool precedent (`validate-profile.py`, `validate-categorization.py`, `validate-skill.py`) and its installer-hygiene / golden-fixture disciplines. The clone-free install is a **new root-level `bootstrap.sh` that wraps — never replaces — each extension's existing `install.sh`** (D45-additive): it fetches only `extensions/<name>/` from the pinned repo ref into a temp dir, then delegates to that extension's own local installer. The conformance checker is a **new pure-stdlib `check-conformance.py`** that validates a `specs/NNN-feature/` directory against the `docs/contracts/` schema set, **delegating** to the three existing per-artifact validators (composition, not duplication — FR-008) and covering the remaining contracts directly. The four hardenings are surgical edits at graph-confirmed sites (see `graphify-context.md`), each landing with a both-branch committed fixture.

## Technical Context

**Language/Version**: Bash (POSIX `sh`-compatible, matching existing `install.sh`/`run.sh`) + Python 3 (stdlib only, matching existing validators — no PyYAML/third-party imports)

**Primary Dependencies**: None new. Reuses: existing per-extension `install.sh` (delegation target for I-32), the three `validate-*.py` validators (delegation targets for I-11), `git` (provenance/rev-parse for I-29, tracked-state probe for I-31), and the graphify `augment_merge.py` line-based parser (I-26)

**Storage**: Files in the repo — no database, no state file (Constitution III). New/edited files only: `bootstrap.sh` (new, root), `check-conformance.py` + its fixtures (new), edits to `extensions/git/install.sh`, `extensions/git/test/run.sh`, `extensions/graphify/extension/scripts/augment_merge.py` + fixture, council skills, implement-parallel skill

**Testing**: The repo's per-extension `test/run.sh` harness (ok/bad assertion style) + committed golden/regression fixtures. Both-branch coverage per FR-009: conformant passes, each injected violation fails naming the cause

**Target Platform**: Developer/CI shell (macOS + Linux); the I-23 fallback path specifically targets a bare host with **neither PyYAML nor `uv`**

**Project Type**: CLI / developer-tooling monorepo (`extensions/*` + `docs/contracts/` + `specs/`) — no web/mobile surface

**Performance Goals**: N/A (mechanical validators + installers; each runs in well under a second on a feature dir). Determinism is the hard requirement, not speed (FR-007/SC-005)

**Constraints**: Zero third-party dependencies (closed contracts); every change additive and gate-semantics-neutral (FR-015); idempotent + reinstall-safe (FR-003, installer-hygiene); deterministic verdicts (FR-007); no `traces.jsonl` schema change (I-31 only nulls a field value, never adds one)

**Scale/Scope**: 6 items across 5 owner piles; ~2 new files (`bootstrap.sh`, `check-conformance.py`) + ~1 fixture tree + 5 surgical edit sites + the `docs/90` close-out. Bounded by design

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Verdict | Notes |
|-----------|---------|-------|
| **I. Artifacts Are the Contract** | ✅ PASS | No new pipeline phase. The conformance checker *reads* artifacts and contracts and emits a verdict to stdout — it writes no pipeline artifact and mutates none. I-31 changes a *value* written into the existing `traces.jsonl` record, not its shape (no second writer). |
| **II. Context Hygiene** | ✅ PASS | No new session roles; the checker and installer are mechanical (no model), like the existing validators. No offloaded-session context crosses to main. |
| **III. Resumability** | ✅ PASS | No state file added (D32 honored). Every deliverable is a file whose presence/validity is self-describing. Installers are idempotent (FR-003); the checker is a pure function of its input dir. |
| **IV. Observability** | ✅ PASS | Mechanical tools invoke no model and write **no** `traces.jsonl` record (the `validate-profile.py`/`cleanup.sh` precedent). I-31 *strengthens* trace fidelity (nulls a gitignored path) — trace-schema §-compliant, no field added/removed. |
| **V. Subscription-Only Billing** | ✅ PASS | No model calls in any deliverable; `ANTHROPIC_API_KEY` never referenced. The clone-free install fetches source files only — no auth token of any kind baked in. |
| **Model Policy (D18)** | ✅ PASS | This plan authored on main thread (Opus/xhigh). Implementation is mechanical bash/Python — no agent-model contradiction possible. |
| **Autonomy & Gates (D9)** | ✅ PASS | **FR-015 is the load-bearing invariant**: no item alters council/workforce gate *semantics*. I-29 records council *apparatus provenance* (an additive metadata line), I-23 hardens the *record-gate hook's manual declaration* — neither changes who signs or what runs. |

**Result**: PASS, no violations → Complexity Tracking left empty. The single principle worth watching through design — **Artifacts Are the Contract** — is satisfied because the conformance checker is a *consumer/validator*, not a phase, and I-31 edits a value not a schema.

## Project Structure

### Documentation (this feature)

```text
specs/008-pre-public-maintenance/
├── plan.md              # This file (/speckit-plan output)
├── research.md          # Phase 0 — I-32 transport + I-11 composition decisions
├── data-model.md        # Phase 1 — the 7 entities + contract-set map
├── quickstart.md        # Phase 1 — per-item runnable validation walkthrough
├── contracts/           # Phase 1 — CLI/behavioral contracts (below)
│   ├── bootstrap-install-command.md     # I-32 one-command install CLI contract
│   ├── conformance-checker-command.md   # I-11 checker CLI contract
│   └── hardening-invariants.md          # I-23/I-26/I-29/I-31 behavioral contracts
├── graphify-context.md  # Pre-hook output (blast radius, collision watch)
└── tasks.md             # Phase 2 (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
bootstrap.sh                                    # NEW (I-32) — root clone-free installer; wraps per-ext install.sh

extensions/
├── git/
│   ├── install.sh                              # EDIT (I-23) — print_manual_block: add after_complete/after_testing
│   ├── extension/extension.yml                 # (source-of-truth for the I-23 divergence guard; comment-carrier for I-26)
│   └── test/run.sh                             # EDIT (I-23) — generalize the manifest↔manual-block divergence grep
├── graphify/
│   ├── extension/scripts/augment_merge.py      # EDIT (I-26) — parse_hook_commands: strip trailing inline comment
│   ├── test/run.sh                             # EDIT (I-26) — fixture case: inline-comment whitespace variants
│   └── skills/speckit-implement-parallel/SKILL.md  # EDIT (I-31) — trace artifact: null on gitignored-only output
├── council/
│   └── skills/
│       ├── speckit-council/SKILL.md            # EDIT (I-29) — suggestions.md provenance: council-apparatus HEAD
│       └── speckit-council-triage/SKILL.md     # EDIT (I-29) — decision-record §5 Metadata: council-apparatus HEAD
└── workforce/
    ├── extension/scripts/check-conformance.py  # NEW (I-11) — contract conformance checker (delegates to validate-*.py)
    └── test/run.sh                             # EDIT (I-11) — both-branch fixture invocation

specs/008-pre-public-maintenance/fixtures/      # NEW (I-11) — conformant + injected-violation feature dirs (both-branch)

README.md                                       # EDIT (I-32/FR-002) — quickstart: documented one-command install
docs/90-DECISIONS-AND-IDEAS.md                  # EDIT (FR-016) — resolve I-32/I-11/I-23/I-26/I-29/I-31 rows on close
```

**Structure Decision**: No new top-level directory. The clone-free installer is a single root `bootstrap.sh` (the natural home for a repo-wide entry point, mirroring how `install.sh .` is each extension's own root entry). The conformance checker lives in **`extensions/workforce/extension/scripts/`** beside the three validators it delegates to — a *runtime shell-out* to their installed copies (data/composition, not a source dependency), consistent with the D57 cross-extension-seam rule that already governs `implement-parallel`. Each hardening edits exactly its graph-confirmed site (see `graphify-context.md` blast radius) with a co-located fixture. See `research.md` for the ownership rationale and the alternative considered.

## Complexity Tracking

> No Constitution Check violations — this section intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _(none)_  | —          | —                                    |

## Phase Notes

- **Phase 0 (research.md)**: resolves the two genuine design unknowns the spec deferred to planning — the I-32 **fetch transport / security posture** (Edge: "safe fetch mechanism … is a planning/council concern") and the I-11 **checker composition + coverage scope** (Edge: "the exact composition is resolved at planning"; carve-out honoring; historical-vs-new scope). The four hardenings carry no open unknowns — their sites and fixes are graph-confirmed.
- **Phase 1 (data-model.md, contracts/, quickstart.md)**: entities from spec §Key Entities; CLI contracts for the two new commands + behavioral contracts for the four hardenings; a per-item runnable validation walkthrough binding every SC/FR to a concrete check.
- **Agent context**: this fork has no `update-agent-context.sh`; its codebase-grounding mechanism is `graphify-context.md`, generated by the `before_plan` graphify hook (already written this session). That step is satisfied.
- **Next gate**: `/speckit-council` (tier `standard`, both gates `human` per D73 — profile.yaml sets no autonomy override). The transport decision (I-32) is the primary thing to defend.
