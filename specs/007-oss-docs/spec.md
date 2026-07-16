# Feature Specification: OSS Front Door + Profile Contract Validator

**Feature Branch**: `007-oss-docs`

**Created**: 2026-07-16

**Status**: Draft

**Input**: User description: "for 007" — the final α-polish feature (D73): the OSS-ready front door the repo needs before it goes public, with the I-27 `profile.yaml` contract validator folded in per owner scope decision (2026-07-16).

## User Scenarios & Testing *(mandatory)*

This feature has one goal — **make the repository ready to go public** — served by two independently-valuable arms: one makes the repo *presentable* (the OSS front door), one makes its central config contract *actually enforced* rather than prose-only (the profile validator). Feature `007` is the last α-polish feature; when it closes, a single "visibility commit" flips the repo public and archives `speckit-graphifyy` with a pointer (D73, out of scope here — `007` produces only the docs that commit reveals).

### User Story 1 - A newcomer understands what SpecSeyal is and how to run it (Priority: P1)

A developer arriving at the public repository (with no prior context) opens the root README and, without reading source or opening other files, learns what SpecSeyal is, the problem it solves, the shape of its spec → … → testing pipeline, how to get it running on a first feature, and where the canonical docs live.

**Why this priority**: This is the literal reason the feature exists — the README *is* the front door the visibility commit reveals. Without it the repo cannot go public (D73: "a README-less front door costs more than a three-feature delay"). It is the irreducible MVP: shipping only US1 already produces a non-embarrassing public repo.

**Independent Test**: Hand the README alone to a reader unfamiliar with the project; verify they can correctly state (a) what SpecSeyal does, (b) the pipeline phase sequence, (c) the first command to run, and (d) the location of the three canonical docs — without opening any other file.

**Acceptance Scenarios**:

1. **Given** a fresh clone and only the README open, **When** a newcomer reads it top to bottom, **Then** they can state in one sentence what SpecSeyal is and name the pipeline's phase sequence.
2. **Given** the README's quickstart, **When** a newcomer follows only its documented steps, **Then** they reach a runnable pipeline (can invoke the first phase) with no undocumented step required.
3. **Given** the README, **When** a reader looks for deeper detail, **Then** every link to a canonical doc (vision, plan, decisions) and every cited repo path resolves to a file that exists.

---

### User Story 2 - A prospective contributor knows how to contribute correctly (Priority: P2)

A developer who wants to contribute finds a contribution guide and standard community-health files that tell them how the project works (the non-negotiable log discipline, the dogfooding rule, the artifact-is-the-contract principle), how to open an issue or PR, the expected commit/branch conventions, how to report a security vulnerability, and the behavioral norms.

**Why this priority**: A public repo without contribution and community-health docs invites malformed contributions and gives no private channel for vulnerability reports. Second only to the README on the "ready to go public" critical path. Independently shippable on top of US1.

**Independent Test**: Hand the CONTRIBUTING guide, CODE_OF_CONDUCT, SECURITY policy, and issue/PR templates to a would-be contributor; verify they can (a) produce a correctly phase-tagged commit and the matching D-row per the log-discipline rule, (b) locate how to file an issue and open a PR, and (c) find the private vulnerability-reporting channel — without reading source.

**Acceptance Scenarios**:

1. **Given** CONTRIBUTING alone, **When** a contributor prepares a change, **Then** they can follow the log-discipline rule (decision → D-row same session; idea → I-row) and the phase-tagged commit / branch-from-spec-ID convention correctly.
2. **Given** the `.github/` templates, **When** a contributor opens an issue or a pull request, **Then** they are prompted for the context the project needs (repro / affected artifact / phase).
3. **Given** SECURITY, **When** someone discovers a vulnerability, **Then** they find a documented private reporting channel and the supported scope.

---

### User Story 3 - A malformed profile.yaml fails mechanically instead of degrading silently (Priority: P3)

A contributor or the pipeline itself encounters a `profile.yaml` that violates the profile contract — an out-of-enum value (e.g. the real `council_tier: standrad` typo that degrades silently today), an unknown key, or a `full_auto: true` that does not satisfy the P1–P5 handshake. A mechanical validator rejects it with a clear message naming the offending key/value, rather than the contract being "enforced" only by prose and by a model reading the file (I-27). The M0 contract fixture `specs/000-sample/profile.yaml` becomes executable — a test finally reads it.

**Why this priority**: Independently-shippable correctness arm, folded in per the owner's 2026-07-16 scope decision. It is the "cheapest real win in the maintenance pile" (I-27) and closes a live silent-degrade defect, but sits lower on the *public-front-door* critical path than the docs. Because a profile validator touches the `full_auto` handshake — the council gate's correctness guard — its enforcement wiring carries gate-semantics weight (D79(2)) and is defended at council.

**Independent Test**: Run the validator against a fixture set covering both branches — conformant profiles pass; each malformed class (out-of-enum, unknown key, unsatisfied `full_auto` handshake) fails with a non-zero result and a message naming the cause — and confirm `specs/000-sample/profile.yaml` passes.

**Acceptance Scenarios**:

1. **Given** a profile with `council_tier: standrad`, **When** the validator runs, **Then** it FAILS with a message identifying the out-of-enum value — the defect no longer degrades silently.
2. **Given** a profile containing a key absent from the profile contract, **When** the validator runs, **Then** it FAILS (unknown keys are a validation *error*, not a warning — profile-schema §3).
3. **Given** `specs/000-sample/profile.yaml`, **When** the validator runs, **Then** it PASSES — the contract fixture is now executable (artifact-layout §7's "any conformance checker built later must pass it").
4. **Given** a profile that sets `deck_render` (the key `006` shipped a scoped validator for), **When** the general validator runs, **Then** it validates that key too and does not conflict with or duplicate `006`'s scoped check — the general validator subsumes it (I-27: "deliberately shaped so a general one can absorb it").

---

### Edge Cases

- **Doc staleness after authoring**: a doc references a path/command/extension that later moves or is renamed. In scope: docs MUST be accurate *at authoring* (no aspirational or broken references). Out of scope: an automated docs-freshness / link-check mechanism (noted as a future concern).
- **Private-context leakage**: an OSS doc must not embed machine-specific absolute paths, personal data beyond the already-public author name in LICENSE, or internal-only session detail.
- **Reader arriving from the old project**: a developer who knew `speckit-graphifyy` needs to find graphify's new home (`extensions/graphify/`). The README orients them; the archive-with-pointer on the *old* repo is the visibility commit's job, not `007`'s (D26/D73).
- **Profile validator — gate-semantics boundary**: if the validator is wired into the council/workforce gate, a malformed profile now BLOCKS that gate, changing gate behavior (D79(2)). The exact enforcement point and its blast radius are resolved at plan and defended at council; the spec requires that a malformed profile be rejected before it is acted upon, not that it be wired at a specific point.
- **Schema-content gaps surfaced by I-27**: `reopen_tier` has zero consumers ("a dead key") and `max_rounds` is read from `council-config.yml`, not the profile. Reconciling whether such keys stay valid, get a consumer, or are removed is a schema-reconciliation concern for planning — the validator enforces the contract as reconciled, it does not redesign the schema in this spec.
- **Missing required key / malformed YAML structure**: the validator must fail clearly rather than raising an opaque parser error.

## Requirements *(mandatory)*

### Functional Requirements

**OSS front door (US1, US2)**

- **FR-001**: A root `README.md` MUST exist stating, for a reader with no prior context, what SpecSeyal is (a one-paragraph elevator pitch), the problem it solves, and its relationship to GitHub Spec Kit and graphify.
- **FR-002**: The README MUST present the end-to-end pipeline phase sequence (specify → clarify → plan → council → tasks → analyze → categorize → agents → parallel-implement → complete → testing) so a reader grasps the workflow shape.
- **FR-003**: The README MUST provide a quickstart a newcomer can follow to run the pipeline on a first feature — prerequisites, install, and the first command — consistent with the actually-installed tooling (D45).
- **FR-004**: The README MUST document the repo layout (`extensions/`, `platform/`, `docs/`, `specs/`) and link to the canonical docs: the vision (docs/00), the implementation plan (docs/05), and the decision log (docs/90).
- **FR-005**: The README MUST state the license (MIT, D27) and the subscription-only billing stance (D28 — the project never sets or relies on `ANTHROPIC_API_KEY`) so a user does not wire up an API key.
- **FR-006**: A `CONTRIBUTING` guide MUST exist documenting the non-negotiable log discipline (every decision → a D-row in the same session; every idea → an I-row), the dogfooding rule (the pipeline builds itself, each milestone through the pipeline), the artifact-is-the-contract principle, and the commit/branch conventions (phase-tagged commits; branch named from the spec ID, D25).
- **FR-007**: A `CODE_OF_CONDUCT` MUST exist.
- **FR-008**: A `SECURITY` policy MUST exist stating how to report a vulnerability privately and the supported scope.
- **FR-009**: Issue and pull-request templates MUST exist under `.github/`, guiding a reporter/contributor to supply the context the project needs (repro, affected artifact/phase).
- **FR-010**: Every file path, command, doc reference, and extension name cited in any OSS doc MUST resolve to something that exists in the repo at authoring time — no aspirational or broken references.
- **FR-011**: The OSS docs MUST NOT leak private or internal-only context (machine-specific absolute paths, personal data beyond the already-public author name in LICENSE, or internal session detail).
- **FR-012**: The README MUST explain graphify's incorporation into this monorepo (`extensions/graphify/`) so a reader arriving from `speckit-graphifyy` finds its new home (supporting the D26/D73 archive-with-pointer performed at the later visibility commit).

**Profile contract validator (US3)**

- **FR-013**: A mechanical validator MUST exist that checks a `profile.yaml` against the profile-schema contract — closed enums, required keys, and the `full_auto` P1–P5 handshake — and treats an unknown key as a validation *error*, not a warning (profile-schema §3).
- **FR-014**: The validator MUST FAIL (non-zero) on each malformed class it targets — an out-of-enum value (e.g. `council_tier: standrad`), an unknown key, and an unsatisfied `full_auto` handshake — and MUST PASS on a conformant profile, in each case producing a clear, human-readable message naming the offending key/value.
- **FR-015**: The validator MUST pass on `specs/000-sample/profile.yaml`, making that M0 contract fixture executable (a test reads it), closing artifact-layout §7's "aspirational" gap.
- **FR-016**: The validator MUST run with no third-party dependencies and on the repo's standard toolchain, matching the portability of the repo's existing contract validators — the profile is a closed contract, so full YAML-library generality is not required.
- **FR-017**: The validator MUST be covered by committed tests exercising both branches — a conformant profile passes; each targeted failure class fails — following the repo's golden/regression fixture discipline.
- **FR-018**: The general validator MUST subsume `006`'s scoped `deck_render` validation (accepting its enum without conflict or duplication), so the scoped check has a general owner to defer to (I-27; D79(2): "deliberately shaped so a general one can absorb it").
- **FR-019**: A `profile.yaml` MUST be mechanically rejected before the pipeline acts on it, rather than degrading silently — retiring the "circular deferral to an upstream owner that does not exist" that I-27 documents. The exact enforcement point and its impact on council/workforce gate semantics (D79(2)) are resolved during planning and defended at council.

### Key Entities *(include if feature involves data)*

- **OSS doc set**: the public-facing files — root `README.md`, `CONTRIBUTING`, `CODE_OF_CONDUCT`, `SECURITY`, and `.github/` issue/PR templates. The presentable front door.
- **Profile validator**: the mechanical checker that enforces the profile contract; a dependency-free checker alongside the repo's existing contract validators (`validate-categorization`, `validate-skill`).
- **Profile contract**: `docs/contracts/profile-schema.md` — the closed contract (enums, required keys, `full_auto` handshake, "unknown key is an error") the validator enforces.
- **profile.yaml**: the per-feature autonomy config being validated; `specs/000-sample/profile.yaml` is the M0 fixture the validator must make executable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time reader can, from the README alone, correctly state what SpecSeyal does, name the pipeline phase sequence, identify the first command to run, and locate the three canonical docs — without opening any other file.
- **SC-002**: A newcomer following only the README quickstart reaches a runnable pipeline (can invoke the first phase) with zero undocumented steps.
- **SC-003**: 100% of file paths, commands, doc references, and extension names cited across the OSS docs resolve to something that exists in the repo (zero broken/aspirational references).
- **SC-004**: The OSS docs contain zero private/internal-only leakage (no machine-specific absolute paths; no personal data beyond the author name already public in LICENSE).
- **SC-005**: A prospective contributor can, from CONTRIBUTING alone, produce a correctly phase-tagged commit and the matching log-discipline entry (D-row / I-row) that conforms to the repo's existing convention.
- **SC-006**: A contributor can locate how to report a vulnerability (SECURITY) and how to file an issue and a PR (`.github/` templates) without reading source.
- **SC-007**: Across a fixture set covering both branches, the validator returns a correct verdict on 100% of cases — every conformant profile passes; every targeted malformed class (out-of-enum, unknown key, unsatisfied `full_auto` handshake) fails.
- **SC-008**: `specs/000-sample/profile.yaml` passes the validator — the M0 contract fixture is executable (a committed test reads it).
- **SC-009**: The specific live defect I-27 names is caught: a profile with `council_tier: standrad` is rejected rather than degrading silently.
- **SC-010**: The validator runs with no third-party dependencies on the repo's standard toolchain and completes on a single profile in under two seconds.
- **SC-011**: On feature close, the repo is in an OSS-publishable state — the visibility commit (public flip + `speckit-graphifyy` archive-with-pointer, D73) can proceed with no further doc authoring and no blocking front-door gap.

## Assumptions

- **LICENSE already exists** (MIT, D27) and is not re-created; the README references it. (D27)
- **The visibility commit is out of scope**: flipping the repo public and archiving `speckit-graphifyy` with a pointer is a single manual step *after* `007` closes (D73, amending D29); `007` produces only the docs that commit reveals. (D73/D29/D26)
- **graphify's engine is upstream**: the `graphifyy` extractor is an upstream pip package (D75); the OSS docs describe the in-repo graphify *extension* (`extensions/graphify/`), not the upstream engine. (D75)
- **Docs are accurate as of authoring**; an automated docs-freshness / link-check mechanism is out of scope (scope boundary — a future concern, not a design choice deferred to the plan).
- **The validator enforces the profile contract as reconciled during planning**; whether schema-content gaps I-27 names (`reopen_tier` dead key; `max_rounds` sourced from `council-config.yml`) are removed, given a consumer, or left valid is a schema-reconciliation decision for the plan, not new schema design in this spec. (I-27, D79(2))
- **The validator carries no third-party dependencies** because the profile is a closed contract (not arbitrary YAML), following the repo's existing no-extra-dependency validator precedent. (I-27)
- **This feature runs at `standard` tier with both council and workforce gates `human`** — no `full_auto` (D73(2)); the feature's own `profile.yaml` therefore sets no autonomy override.
- **Folding I-27 into a docs feature couples a non-technical doc concern with a gate-correctness-touching validator** (D79(2) flagged this coupling when it declined to build the general validator inside `006`); this is the owner's explicit 2026-07-16 scope decision, and the council weighs whether the enforcement wiring (FR-019) belongs in this feature or should remain a standalone command. (I-27, D79(2), owner ruling 2026-07-16)
- **Every Constraints & Assumptions entry above cites a D-row or is an explicit scope boundary**, per the standing spec-hygiene rule (D46(3)).
