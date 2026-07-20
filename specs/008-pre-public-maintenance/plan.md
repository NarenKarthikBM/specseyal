# Implementation Plan: Pre-Public Maintenance & Adopter Experience

**Branch**: `008-pre-public-maintenance` | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-pre-public-maintenance/spec.md`

## Summary

A six-item, pre-public maintenance sweep — the `docs/90` "Actionable-now cluster" (D84) — that removes the remaining rough edges before the D73 visibility flip. Every item is **additive, bounded, independently testable, and touches no gate _semantics_** (FR-015, the deliberate contrast with `007`). Two items carry weight — a **clone-free one-command install** (US1/I-32) and a **contract conformance checker** (US2/I-11) — and four are **latent-defect hardenings** (US3: I-23 git-ext manual-fallback, I-26 augment inline-comment strip, I-29 council apparatus provenance, I-31 implement-parallel trace guard).

**Technical approach**: All work is bash + Python-3-stdlib, matching the repo's existing zero-third-party-dependency tool precedent (`validate-profile.py`, `validate-categorization.py`, `validate-skill.py`) and its installer-hygiene / golden-fixture disciplines. The clone-free install is a **new root-level `bootstrap.sh` that wraps — never replaces — each extension's existing `install.sh`** (D45-additive): it fetches only `extensions/<name>/` from a **pinned released tag** into a temp dir, then delegates to that extension's own local installer. `--ref` defaults to a concrete release tag, never a moving branch — an undecided or moving default would contradict R1's own pinned-posture rationale (R1-S05). Both `--ref` and `<target-repo-dir>` are validated and escaped before any interpolation into `git clone` / `sparse-checkout` (a ref beginning with `-` is a known git argument-injection vector), and `<extension-name>` is constrained to the bootstrap-install contract's closed enum (surfaced in the §3/E1 contract). On a mid-install failure — step 3, delegating to the extension's `install.sh` — `bootstrap.sh` propagates the non-zero exit and removes the temp dir via a trap-based `EXIT` handler, leaving the target repo in a named, documented state rather than a half-populated one inherited-by-assumption from `install.sh`'s idempotency (R1-S24). The conformance checker is a **new pure-stdlib `check-conformance.py`** that validates a `specs/NNN-feature/` directory against the `docs/contracts/` schema set, **delegating** to the three existing per-artifact validators (composition, not duplication — FR-008) and covering the remaining contracts directly; its definition of done is deliberately **detectable-on-demand** (R1-S14) — a maintainer or CI runs it explicitly, exactly like `/speckit-validate-profile`, and it is **not** wired into any `before_*`/`after_*` hook in this feature, because wiring an enforcement point would touch the gate/phase semantics FR-015 forbids. The four hardenings are surgical edits at graph-confirmed sites (see `graphify-context.md`). Fixture coverage is stated honestly, per what a `run.sh` can actually exercise (R1-S15): **I-23** lands a both-branch committed fixture; **I-26** is partial (the primary `dequote()` fix plus its other two callers, `parse_shell` / `resolve_target`); **I-29/I-31** edit LLM-interpreted `SKILL.md` prose that no `run.sh` can drive, so they carry **no** both-branch `run.sh` fixture and are instead pinned by a hand-authored violating/clean fixture folded into `check-conformance.py` (e.g. I-31's trace-schema rule) — three of the four hardenings carry a real coverage gap, not "two minor exceptions." `bootstrap.sh`'s fetch (the bundle's largest branch-count increase, in its least-tested item) additionally gets a minimal **automated smoke test exercising both** the sparse-partial-clone path and the codeload-tarball fallback, not the manual quickstart alone (R1-S08).

## Technical Context

**Language/Version**: Bash (POSIX `sh`-compatible, matching existing `install.sh`/`run.sh`) + Python 3 (stdlib only, matching existing validators — no PyYAML/third-party imports)

**Primary Dependencies**: None new. Reuses: existing per-extension `install.sh` (delegation target for I-32), the three `validate-*.py` validators (delegation targets for I-11), `git` (provenance/rev-parse for I-29, tracked-state probe for I-31), and the graphify `augment_merge.py` line-based parser (I-26)

**Storage**: Files in the repo — no database, no state file (Constitution III). New/edited files only: `bootstrap.sh` (new, root), `check-conformance.py` + its fixtures (new), edits to `extensions/git/install.sh`, `extensions/git/test/run.sh`, `extensions/graphify/extension/scripts/augment_merge.py` + fixture, council skills, implement-parallel skill

**Testing**: The repo's per-extension `test/run.sh` harness (ok/bad assertion style) + committed golden/regression fixtures. Both-branch coverage per FR-009: conformant passes, each injected violation fails naming the cause. Council-round-1 hardenings:
- **Fixture per preserved invariant, not just per primary fix** (R1-S03): I-26 adds cases exercising `dequote()`'s other two callers (`parse_shell`, `resolve_target`) in graphify's `run.sh`, not only the inline-comment strip; I-29/I-31 — which no `run.sh` can drive — name their alternate closure (I-31's trace-schema rule folded into `check-conformance.py` against a hand-authored violating/clean fixture) rather than leaving the invariant unproven.
- **`check-conformance.py` violation-fixture coverage is explicit** (R1-S16): the injected-violation fixture dirs must exercise **all six** directly-checked contracts (`artifact-layout`, `decision-record`, `completion-report`, `testing-doc`, `trace-schema`, `agent-library-schema`); any contract left without an injected-violation case is called out, never silently uncovered (FR-009).
- **Composition-not-duplication is mechanically guarded** (R1-S22): a static check asserts `check-conformance.py`'s source contains no source-level `import` of the three validators (only `subprocess`/shell-out calls), turning FR-008's no-duplication property from an assertion into a caught regression.
- **Checker self-check** (R1-S19): `check-conformance.py` carries a lightweight self-test asserting the section headers / field names it parses still exist in each `docs/contracts/*.md`, so a future contract-doc edit fails loudly instead of silently desyncing the only code kept in sync with that prose.
- **SC-005 determinism is automated** (R1-S21): a double-run byte-diff assertion folded into `extensions/workforce/test/run.sh` replaces the manual re-run-and-eyeball step, moving SC-005 from partial/manual to code-verified.
- **Manual-only SCs have a named executor** (R1-S09): the six manual-only success criteria (SC-001/002/003, SC-008/009/010) are bound to the `quickstart-integration-gate` discipline, run before `/speckit-complete` — `/speckit-testing` is doc-only (`executed: none`), so the walkthrough owner and timing are stated, not left implicit.
- **Provisional manual sign-off** (R1-S06): SC-001/002/003's quickstart sign-off is **provisional** — run pre-D73 by an authenticated maintainer against a still-private repo, it cannot exercise the unauthenticated true-outsider path, so it is **re-confirmed against the real public repo immediately after the D73 visibility flip**.
- **Disclosed coverage gaps are tracked as risks** (R1-S04): the I-29/I-31 zero-fixture gap (strictly worse than the I-26 partial gap, which already has a row) and the aggregate 6-of-10-manual-SC tally are promoted to first-class tracked risks here, not left as testability-table footnotes

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
| **Autonomy & Gates (D9)** | ✅ PASS | **FR-015 is the load-bearing invariant**: no item alters council/workforce gate *semantics*. I-29 records council *apparatus provenance* (an additive metadata line), I-23 hardens the *record-gate hook's manual declaration* — neither changes who signs or what runs. **FR-015 is verified, not merely asserted (R1-S01):** a committed check runs `git diff --name-only $(git merge-base <base_branch> HEAD)..HEAD` and **fails** if any changed path falls outside the feature's declared allowlist — the six edit sites: `bootstrap.sh`; `extensions/workforce/extension/scripts/check-conformance.py` + its `specs/008-pre-public-maintenance/fixtures/`; `extensions/git/install.sh` + `extensions/git/test/run.sh`; `extensions/graphify/extension/scripts/augment_merge.py` + `extensions/graphify/test/run.sh`; `extensions/council/skills/speckit-council/SKILL.md` + `speckit-council-triage/SKILL.md`; `extensions/workforce/test/run.sh`; `README.md`; `docs/90-DECISIONS-AND-IDEAS.md` — so a stray edit to any gate-schema or gate-semantics file breaks the build. It is backed at the human gate by an explicit sign-off line confirming no gate-schema/semantics file changed — **distinct from** SC-010's `docs/90` I-code grep, which only proves close-out bookkeeping, not non-interference. |

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
│   ├── install.sh                              # EDIT (I-23) — print_manual_block: add after_complete/after_testing (GIT'S COPY ONLY; 1 of 5 identical copies — see Structure Decision)
│   ├── extension/
│   │   └── extension.yml                       # (nested under extension/, NOT a sibling of install.sh/test/ — R1-S02; source-of-truth for the I-23 divergence guard; comment-carrier for I-26)
│   └── test/
│       └── run.sh                              # EDIT (I-23) — generalize the divergence grep, SCOPED to `extensions/git/install.sh` specifically (R1-S10: a bare print_manual_block name match is satisfiable by any of the 5 identical copies). I-23 is ONE lock-step task in fixed sub-order (R1-S11): generalize guard → run & witness it FAIL against the current pre-fix manifest/block → apply the extension.yml/install.sh fix → re-run & witness it PASS (H1/SC-006)
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

**Structure Decision**: No new top-level directory. The clone-free installer is a single root `bootstrap.sh` (the natural home for a repo-wide entry point, mirroring how `install.sh .` is each extension's own root entry). The conformance checker lives in **`extensions/workforce/extension/scripts/`** beside the three validators it delegates to — a *runtime read* of those validators' installed copies (it shells out and consumes their stdout / exit code; data/composition, not a source dependency). This is governed by the plain "a read is not a write" seam rule (R1-S17), **not** by D57 — D57 concerns *not patching* another extension's installer-overwritten source, a different case; the earlier D57 citation is dropped as inapt. Each hardening edits exactly its graph-confirmed site (see `graphify-context.md` blast radius) with a co-located fixture. See `research.md` for the ownership rationale and the alternative considered.

**Collision & sequencing constraints for `/speckit-tasks(-graph)`:**
- **Five identical `print_manual_block()` nodes** (R1-S07): the graph holds five structurally-identical `print_manual_block()` definitions — `deck-render`, `git`, `graphify`, `testing`, `workforce` (confirmed by `grep -rl` and `graphify explain`). I-23 is correctly scoped to **git's copy only**; the other four are equally susceptible to the same manifest↔manual-block drift, so I-23 does **not** close the pattern repo-wide (a note, not extra scope for 008).
- **Explicit depends-on edges, not prose** (R1-S12): the four collision-watch constraints — `docs/90`, git's `extension.yml`+`install.sh` pair, `README.md`, and the `.specify/extensions.yml` mirror resync — must be encoded as explicit `depends-on` edges when `tasks.md` is generated, not left as deck/plan prose a graph-driven wave builder won't read.
- **Mirror resync ordered before the guard** (R1-S23): if the I-23 edit triggers a reinstall, the `.specify/extensions.yml` source→mirror resync is sequenced **strictly before** `extensions/git/test/run.sh`'s guard runs (not as an independently-ordered separate commit), so the guard never validates a stale installed mirror.

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
- **I-29 self-reference** (R1-S13): I-29 edits `speckit-council/SKILL.md` and `speckit-council-triage/SKILL.md` — the very files this 008 council round runs under. The provenance line I-29 adds is **generation-time additive metadata**: this round's own `suggestions.md` / `decision-record.md` were produced **before** I-29 ships, so they do **not** retroactively carry it, and no back-fill of already-written round artifacts is implied. I-29 governs council/triage runs that happen **after** it lands — the dogfooding rule applies forward, not retroactively.
- **FR-016 close-out sequencing** (R1-S20): the same-session, all-six `docs/90` I-code close-out is the **final serialized step**, gated on the other five owner piles completing — not a flat parallel wave (the collision watch above makes a single flat wave unlikely). SC-010's post-hoc I-code grep proves presence, not order, so the ordering is pinned here explicitly rather than inferred.
