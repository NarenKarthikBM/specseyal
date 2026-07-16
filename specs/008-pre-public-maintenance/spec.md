# Feature Specification: Pre-Public Maintenance & Adopter Experience

**Feature Branch**: `008-pre-public-maintenance`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "008" — the pre-public maintenance + adopter-experience feature the decision log frames as the "Actionable-now cluster" (docs/90, grouped 2026-07-17). All six ripe, unblocked items are in scope per the owner's `/speckit-specify` scope decision (2026-07-17): **I-32** (clone-free one-command install), **I-11** (contract conformance checker), **I-23** (git-ext manual-fallback block fix), **I-26** (augment inline-comment strip), **I-29** (council-round apparatus provenance), **I-31** (implement-parallel trace guard).

## User Scenarios & Testing *(mandatory)*

This is the pre-public maintenance sweep the repo needs *after* `007`'s OSS front door and *before* the D73 visibility commit flips it public. It bundles six ripe items across five owner piles (docs/90 Actionable-now cluster) — every one **additive, bounded, independently testable, and none touching gate _semantics_** (the deliberate contrast with `007`, whose profile validator did carry gate-semantics weight). One arm is **adopter-facing** (a clone-free one-command install); one is **contributor/maintainer-facing** (a machine that catches contract drift instead of relying on review); four are **latent-defect fixes** that would otherwise silently mislead an outside adopter, contributor, or auditor once the repo is public. Scope (all six) was set by the owner at `/speckit-specify` per the cluster's explicit hand-off ("which of the six are in is the owner's to set").

### User Story 1 - An adopter installs SpecSeyal with one command, no manual clone (Priority: P1)

A developer who wants to try SpecSeyal — or add one of its extensions to their own repo — runs a **single documented command** that acquires and installs the chosen extension into their target repo, without first manually cloning the whole `specseyal` repository. Today every `extensions/*/install.sh` is a pure local `cp -R` from its own checkout and there is **no root-level bootstrap**, so an adopter must obtain the entire `extensions/` tree first — the acquisition step `007`'s README quickstart silently omitted because it was written from the maintainer's in-repo `install.sh .` vantage (I-32).

**Why this priority**: This is the public-facing win and the anchor of the cluster — it removes the one undocumented "obtain-the-files-first" step that makes `007`'s quickstart only half-runnable for a true outsider, and it pairs naturally with the pre-visibility-flip readiness. Shipping only US1 already delivers the highest adopter value on its own.

**Independent Test**: From a machine that has *only* the one documented command (no prior clone of `specseyal`), run it against a throwaway target repo and confirm the chosen extension installs (its skills land in `.claude/`, its hooks register in `.specify/`) with no separate manual clone/download step, and that a second run is idempotent.

**Acceptance Scenarios**:

1. **Given** a target repo and no local clone of `specseyal`, **When** the adopter runs the single documented bootstrap command, **Then** the extension's files are acquired and installed with no separate manual clone/download step.
2. **Given** the bootstrap install has already run once, **When** it is run again, **Then** it is idempotent — the re-install is safe and leaves a consistent state (the repo's installer-hygiene precedent).
3. **Given** the README quickstart, **When** a true outsider follows only its documented install steps, **Then** no omitted acquisition step remains — closing the exact I-32 gap `007`'s quickstart exposed.

---

### User Story 2 - A maintainer catches contract drift by machine, not by review (Priority: P2)

A maintainer who edits a contract under `docs/contracts/`, or a contributor who authors a new feature's artifacts, wants a **machine to tell them whether a `specs/NNN-feature/` directory still conforms to the contract schemas** — rather than relying on human review to catch drift. Today the only validators are per-artifact (`validate-categorization`, `validate-skill`, and `007`'s profile validator); there is no checker that validates a feature directory against the artifact-layout and record-format contracts as a whole. The M0 era had a throwaway, fixture-coupled verifier (`R1-S04`, deferred); this rewrites it **from the contracts alone** (I-11).

**Why this priority**: OSS-hygiene plus contract-drift-by-machine is the second item on the pre-public path after the install win, and it makes `specs/000-sample/`'s "executable statement of the contract" (artifact-layout §7) finally true — a test at last reads it. Independently shippable on top of US1.

**Independent Test**: Run the checker against `specs/000-sample` (the executable contract statement) — it passes; inject a contract violation into a copy — it fails, naming the offending artifact and rule; run it twice on the same input — identical verdict; invoke it as a single CI-style command.

**Acceptance Scenarios**:

1. **Given** `specs/000-sample`, **When** the conformance checker runs, **Then** it PASSES — the M0 contract fixture is finally machine-validated (artifact-layout §7's "any conformance checker built later must pass it").
2. **Given** a feature directory whose artifact violates a `docs/contracts/` schema (a record missing a required section, malformed frontmatter, a wrong layout path), **When** the checker runs, **Then** it FAILS naming the offending artifact and the rule it broke.
3. **Given** the same feature directory twice, **When** the checker runs, **Then** the verdict is identical (deterministic) and the checker runs as a single command suitable for CI, with no third-party dependencies.
4. **Given** a feature that legitimately invokes a documented meta-feature carve-out (D50 conformance rule-5), **When** the checker validates it, **Then** the carve-out is honored, not reported as drift.

---

### User Story 3 - Latent defects are hardened before outside eyes (Priority: P3)

Four latent defects — each unhit or silently non-blocking today — would mislead someone once the project is public: an adopter installing git-ext on a bare host, an internal graph consumer, a council-round auditor, and the trace-conformance guarantee itself. This story fixes all four so no outside adopter, contributor, or auditor is silently mis-served (I-23, I-26, I-29, I-31).

**Why this priority**: Each is small, additive, and independently testable, but lower on the *public-front-door* critical path than the install win and the conformance checker. Grouped because they share one journey — "a latent defect that would silently bite once others run the pipeline" — and each is verifiable on its own.

**Independent Test**: Each fix has a standalone check — (I-23) a host with neither PyYAML nor `uv` gets a manual-fallback block that declares every registered hook, and a static grep fails on manifest/block divergence; (I-26) a hook command with a trailing inline comment parses to a clean node id, proven by a fixture; (I-29) a fresh council round records the `extensions/council/` HEAD in its provenance; (I-31) an implement-parallel run records `artifact: null` for a task whose sole output is gitignored.

**Acceptance Scenarios**:

1. **Given** a host with neither PyYAML nor `uv` (the manual-paste fallback path), **When** git-ext's `install.sh` prints its manual-fallback block, **Then** the block declares 100% of the extension's registered hooks — including the `after_complete`/`after_testing` seam hooks — so no `complete(<id>)`/`testing(<id>)` commit seam is silently dropped; **and** a static check FAILS if the manifest (`extension.yml`) and the hand-paste block ever diverge (I-23).
2. **Given** a hook entry carrying a trailing inline comment (e.g. `command: speckit.git.record-gate  # hook-internal action: …`), **When** graphify augment's hook-command parse runs, **Then** it strips the ` # …` and mints a clean command-node id — proven by a committed fixture case exercising inline-comment stripping (I-26).
3. **Given** a council round, **When** its `decision-record.md`/`suggestions.md` provenance is written, **Then** it records the `extensions/council/` HEAD (`git rev-parse HEAD -- extensions/council/`) alongside the existing plan and deck SHAs, so a mid-round change to the reviewing apparatus is detectable from the round's artifacts alone (I-29).
4. **Given** a task whose sole output is gitignored or untracked (e.g. a rendered `renders/*.pptx`), **When** `/speckit-implement-parallel` writes that task's trace, **Then** the record's `artifact` is `null` — never the gitignored path — generalizing `006`'s SC-005 rule as a root-cause guard, not a one-off data fix (I-31).

---

### Edge Cases

- **Clone-free install security posture**: a one-command remote install can invite blind `curl | bash`. In scope: the command must not require a prior manual clone. The *safe* fetch mechanism (checksum/pinning, a reviewable script vs opaque pipe-to-shell) is a planning/council concern — the spec fixes the capability, not the transport.
- **Offline / no-network adopter**: the clone-free path assumes network access to fetch the files; a fully-offline adopter still uses the existing local `cp -R` `install.sh` from a checkout. The new path is **additive** — it does not remove the in-checkout install route.
- **Conformance checker vs. real completed features**: some completed features carry documented carve-outs (D50 meta-feature rule-5). The checker must honor documented carve-outs, not treat them as drift; whether it validates historical features or only new ones is a planning boundary.
- **Checker overlap with existing validators**: `profile-schema` already has a validator (`007`/I-27); categorization and skill each have one. The conformance checker MUST NOT duplicate or conflict — it composes/delegates for those artifacts and covers the remaining contracts; the exact composition is resolved at planning.
- **Divergence guard must fail on real divergence**: the I-23 static grep is only useful if it FAILS when a *new* hook is added to the manifest but not the manual block — the exact hazard that shipped the `after_complete`/`after_testing` gap. A guard that passes on that divergence is not a guard.
- **augment inline-comment whitespace variants**: comments with varied spacing (`#x`, `  #  x`, tab-separated) must all strip cleanly; the fixture should exercise the whitespace variants, not a single canonical form.
- **Council provenance with a dirty `extensions/council/` tree mid-round**: recording HEAD while the council source has uncommitted edits records a sha that does not fully capture the apparatus; the provenance should note or account for a dirty working tree (planning detail).

## Requirements *(mandatory)*

### Functional Requirements

**Clone-free one-command install (US1 · I-32)**

- **FR-001**: A single documented command MUST install a chosen SpecSeyal extension into a target repo **without requiring the adopter to first manually clone the `specseyal` repository** — a root-level bootstrap that acquires the needed files, closing the gap that every `extensions/*/install.sh` today is a pure local `cp -R` with no acquisition step (I-32).
- **FR-002**: The one-command install path MUST be documented in the README quickstart such that a true outsider following only the documented steps reaches a runnable install with **no undocumented acquisition step** — the specific I-32 gap `007`'s quickstart exposed.
- **FR-003**: The clone-free install MUST be idempotent and reinstall-safe (the repo's installer-hygiene precedent), and MUST be **additive** — it does not remove or break the existing in-checkout local `install.sh` path (D45).

**Contract conformance checker (US2 · I-11)**

- **FR-004**: A conformance checker MUST exist that validates a `specs/NNN-feature/` directory against the `docs/contracts/` schemas (artifact layout, record formats, frontmatter), reporting each nonconformance with the offending artifact and the rule it broke (I-11).
- **FR-005**: The checker MUST be derived from the contracts themselves, **not coupled to the M0 council fixture** — a rewrite of the deferred `R1-S04` throwaway, not its revival.
- **FR-006**: The checker MUST PASS on `specs/000-sample`, making artifact-layout §7's "any conformance checker built later must pass it" real (the fixture is finally read by a test), and MUST honor documented meta-feature carve-outs (D50) rather than flagging them as drift.
- **FR-007**: The checker MUST be invocable as a **single command suitable for CI**, produce a **deterministic** verdict (same input → same result), and carry **no third-party dependencies**, matching the repo's existing validator precedent (`validate-categorization`, `validate-skill`, `007`'s profile validator).
- **FR-008**: The checker MUST NOT duplicate or conflict with the existing per-artifact validators (the `007` profile validator, categorization, skill); it composes/delegates for those artifacts and covers the remaining contracts — the exact composition resolved at planning.
- **FR-009**: The checker MUST be covered by committed both-branch tests — a conformant feature directory passes; each injected contract violation fails naming the cause — following the repo's golden/regression fixture discipline.

**Latent-defect hardening (US3)**

- **FR-010** (I-23): git-ext's `install.sh` manual-fallback block (`print_manual_block`, emitted only when a host has neither PyYAML nor `uv`) MUST declare 100% of the extension's registered hooks — including the `after_complete` and `after_testing` seam hooks — so a human pasting it on a fallback-only host does not silently drop the `complete(<id>)`/`testing(<id>)` commit seam.
- **FR-011** (I-23): A static check (the `run.sh` §4-style grep pattern) MUST assert that git-ext's manifest (`extension.yml`) and the hand-paste manual-fallback block cannot diverge — every hook the manifest registers is declared in the manual block, failing otherwise.
- **FR-012** (I-26): graphify augment's hook-command parse (`augment_merge.py` `parse_hook_commands`) MUST strip a trailing inline comment from a hook command entry (e.g. `speckit.git.record-gate  # …` → `speckit.git.record-gate`) so no malformed command-node id is minted, covered by a fixture case exercising inline-comment stripping.
- **FR-013** (I-29): A council round's provenance (`decision-record.md` / `suggestions.md`) MUST record the `extensions/council/` HEAD (`git rev-parse HEAD -- extensions/council/`) that produced the round's mechanics, alongside the existing plan and deck SHAs, so a mid-round change to the reviewing apparatus is detectable from the round's artifacts.
- **FR-014** (I-31): `/speckit-implement-parallel` MUST record `artifact: null` (never a gitignored/untracked path) in the trace for any task whose sole output is gitignored or untracked — the root-cause guard generalizing `006`'s SC-005, so no rendered/ignored path can appear in `traces.jsonl`.

**Scope invariants (all six items)**

- **FR-015**: No change in this feature MUST alter council- or workforce-gate **semantics** — every item is additive and bounded (the Actionable-now cluster invariant; the deliberate contrast with `007`'s gate-touching profile validator).
- **FR-016**: On feature close, each of the six ripe I-rows (I-32, I-11, I-23, I-26, I-29, I-31) MUST be resolved and its `docs/90` status updated in the same session (log discipline), leaving the repo one bounded step from the D73 visibility flip.

### Key Entities *(include if feature involves data)*

- **Clone-free installer**: the new root-level bootstrap that acquires + installs an extension in one command without a prior manual clone; additive to the existing per-extension `install.sh` local-copy path.
- **Contract conformance checker**: the machine that validates a `specs/NNN-feature/` directory against the `docs/contracts/` schema set; a dependency-free checker alongside the repo's existing per-artifact validators.
- **`docs/contracts/` schema set**: the contracts the checker enforces (artifact-layout, decision-record, completion-report, testing-doc, trace-schema, agent-library-schema, skill-module, taxonomy, profile-schema) — `specs/000-sample` is the executable fixture it must pass.
- **git-ext manual-fallback block + divergence guard**: `install.sh`'s `print_manual_block` hand-paste text and the static grep that keeps it in lock-step with `extension.yml`.
- **augment hook-command parser**: `augment_merge.py`'s `parse_hook_commands`, which must strip trailing inline comments before minting command-node ids.
- **council round provenance**: the `decision-record.md`/`suggestions.md` header fields that record which plan, deck, and now council-apparatus commit produced a round.
- **implement-parallel trace writer**: the `/speckit-implement-parallel` step that emits each task's trace record and must null out gitignored-only artifacts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An adopter installs a chosen SpecSeyal extension into a target repo with a **single documented command and zero manual clone/download step** (I-32).
- **SC-002**: The README quickstart's install path resolves end-to-end for a true outsider — **no undocumented acquisition step remains** (closing the gap `007`'s quickstart exposed).
- **SC-003**: The clone-free install is **idempotent** — running it twice leaves the same consistent state (no duplication, no breakage) — and the existing in-checkout local install path still works unchanged.
- **SC-004**: The conformance checker returns a correct verdict on **100% of a both-branch fixture set** — a conformant feature directory passes; each injected contract violation fails naming the offending artifact and rule — and it **passes on `specs/000-sample`**.
- **SC-005**: The conformance checker is a **single CI-invocable command** with a **deterministic** verdict and **no third-party dependencies**, and it does not duplicate or conflict with the existing per-artifact validators.
- **SC-006**: On a host with neither PyYAML nor `uv`, git-ext's manual-fallback install block declares **100% of the extension's registered hooks** (including the `after_complete`/`after_testing` seam), and the static divergence check **fails** if the manifest and the block ever diverge.
- **SC-007**: graphify augment parses a hook command carrying a **trailing inline comment** into a clean command-node id (zero ` # …` captured), proven by a committed fixture covering whitespace variants.
- **SC-008**: **Every new council round** records the `extensions/council/` HEAD sha in its provenance, so a mid-round apparatus change is detectable from the round's artifacts alone.
- **SC-009**: **Zero** task in a `/speckit-implement-parallel` run records a gitignored/untracked path as its trace `artifact` — a task whose sole output is ignored writes `artifact: null`.
- **SC-010**: On feature close, **all six ripe I-rows are resolved and their `docs/90` statuses updated**, **no change altered council/workforce gate semantics**, and the repo is one bounded step from the D73 visibility flip.

## Assumptions

- **This is the pre-public maintenance feature** the `docs/90` Actionable-now cluster (2026-07-17) frames as the natural `008`; **all six items are in scope** per the owner's `/speckit-specify` scope decision (2026-07-17). (docs/90 Actionable-now cluster; owner ruling 2026-07-17)
- **The visibility commit is out of scope**: flipping the repo public and archiving `speckit-graphifyy` with a pointer remains a single manual step *after* `008` (D73, amending D29/D26); this feature only removes remaining rough edges and blockers before it. (D73/D29/D26)
- **The four excluded items stay excluded**: I-24/I-25 (new graphify edge kinds) are booked-not-build until the recurring-evidence bar is met (D76/D66); I-21 (D47 token-attribution helper) is observability-track, better with M5 context; I-16 is obsolete and I-17 was fixed at M4. (docs/90 cluster exclusions; D66/D76/D47)
- **The profile half of the contract-conformance pile already shipped in `007`** (the I-27 profile validator); I-11 covers the *remaining* contracts and defers profile validation to the existing `007` validator rather than reimplementing it. (007/I-27; docs/90 cluster)
- **Validators and the conformance checker carry no third-party dependencies** because the contracts are closed, following the repo's existing no-extra-dependency validator precedent (`validate-categorization`, `validate-skill`, `007`'s profile validator). (I-11; repo precedent)
- **No item touches gate semantics** — every change is additive and bounded; this is the deliberate contrast with `007`'s gate-semantics-touching profile validator and the invariant the cluster asserts. (docs/90 cluster; scope boundary)
- **The clone-free installer is additive**, not a replacement: the existing local `cp -R` `install.sh` remains the offline/in-checkout install route (D45 established that path). (D45; scope boundary)
- **The safe fetch mechanism for the one-command install** (transport, checksum/pinning, avoiding opaque pipe-to-shell) is resolved during planning and defended at council; the spec requires the clone-free *capability*, not a specific transport. (scope boundary)
- **This feature runs at `standard` council tier with both council and workforce gates `human`** — no `full_auto`; its own `profile.yaml` sets no autonomy override, consistent with the α-polish trio. (D73)
- **Every Constraints & Assumptions entry above cites a D-row or is an explicit scope boundary**, per the standing spec-hygiene rule (D46(3)). (D46(3))
