# Research — 007-oss-docs

Phase 0 output. Every NEEDS CLARIFICATION resolved. Grounded in [graphify-context.md](./graphify-context.md), `docs/contracts/profile-schema.md` v1.2, `extensions/deck-render/extension/scripts/profile_key.py`, the two existing validators, and decision rows I-27 / D45 / D73 / D79 / D82.

---

## D-a — Validator home and structure

**Decision.** `validate-profile.py` lives at `extensions/workforce/extension/scripts/validate-profile.py` with a tracked installed copy at `.specify/extensions/workforce/scripts/validate-profile.py` (both trees are committed for this extension). It mirrors the structure of its two siblings: a `main()` returning a non-zero exit on failure, small single-purpose `check_*` / `validate_*` functions, a `ValidationResult`-style accumulator, a shape-error exception, and an embedded self-test + committed fixtures.

**Rationale.** These are the repo's only two general contract validators (`validate-categorization.py`, `validate-skill.py`) and they already live here; I-27 names exactly this file ("one stdlib `validate-profile.py`"). Co-locating keeps all general contract validators in one place and lets the existing `extensions/workforce/test/` harness cover it.

**Alternatives considered.** *A new "core/contracts" extension* — rejected: none exists and creating one to host a single validator is disproportionate for an S/M feature. *Inside `extensions/deck-render/`* (where the only existing profile code lives) — rejected: a *general* profile validator does not belong in the deck-specific extension; naming/ownership smell. **This home choice is a council-reviewable point** (workforce owns only one of the two gates the profile configures), but pattern-consistency is decisive.

---

## D-b — Dependency-free YAML strategy

**Decision.** Reuse `profile_key.py`'s posture verbatim: no hard `import yaml`, no `requirements.txt`. Try PyYAML in the running interpreter; if absent, walk the interpreter ladder (`graphify`/`specify` shebang interpreter → `python3` → `python` → `uv run --with pyyaml python`) and parse out-of-process. If **no** PyYAML-capable interpreter is reachable, **fail loud** (non-zero) — never treat an unparseable/unreadable profile as "said nothing."

**Rationale.** FR-016/SC-010 forbid third-party deps; the profile is a *closed contract*, not arbitrary YAML, so full YAML-library generality is unnecessary. `profile_key.py` already solved this exact problem in this repo — the general validator generalizes its `_probe_yaml` from "extract `deck_render`" to "return the whole mapping," keeping the ladder and the loud-failure semantics (branch 3).

**Alternatives considered.** *Vendoring a mini-YAML parser* — rejected: the profile can contain comments/strings/nested maps a naive parser would mishandle; correctness beats zero-subprocess. *Requiring PyYAML* — rejected by FR-016.

---

## D-c — The exact rule set enforced (profile-schema.md v1.2)

**Decision.** The validator enforces the contract as written:

- **Required keys:** `schema_version` (string), `feature` (string, **must equal the containing directory name** — catches copy-paste), `full_auto` (bool), `gates` (mapping), `gates.council` (mapping), `gates.council.mode` (`human`|`auto`), `gates.workforce` (mapping), `gates.workforce.mode` (`human`|`auto`).
- **Gate blocks are mappings, not scalars:** `council: human` is invalid; only `council: {mode: …}` is valid (§1).
- **Closed enums:** `council_tier` ∈ {`full`,`standard`} (default `full`); `deck_render` ∈ `DECK_RENDER_ENUM` (default `none` — see D-d); `mode` ∈ {`human`,`auto`}; `reopen_tier` ∈ {`auto`,`delta`,`full`} (default `auto`).
- **`max_rounds`:** optional int, **must be `1`** in v1 (reject `>1`).
- **Unknown keys are a validation *error*, not a warning** (§3) — a typo'd `gates.counsel` or a stray top-level key FAILs.
- **The `full_auto` handshake — the machine-enforceable subset of P1–P5:**
  - **P1** — an **absent** `profile.yaml` is **VALID** (resolves to both-gates-`human`); the validator returns 0, never an error, when handed a missing file (matches `profile_key.py` branch 1; two committed profiles — `002`, `007` before this feature — are absent).
  - **P2** — `gates.council.mode: auto` is invalid unless `full_auto: true`.
  - **P3** — `full_auto: true` is invalid unless **both** `gates.council.mode` and `gates.workforce.mode` are `auto`.
  - **P4** — `gates.workforce.mode: auto` alone with `full_auto: false` is **valid** (economic guard, not protected).
  - **P5** — the mandatory top-of-file *why* comment for `full_auto: true` is **NOT machine-enforced** (the contract says so: "Enforced by the person reviewing the diff"); the validator does not attempt it.
- **Malformed YAML / no parser reachable ⇒ loud non-zero failure** (never folded into the absent branch).

**Rationale.** FR-013 says the validator enforces *the contract*; the contract (`profile-schema.md`) is the SSOT. Every present committed profile (`000`,`001`,`003`,`004`,`005`,`006`) was checked and conforms to exactly these rules, so enforcing them cleanly passes all real profiles and fails only genuine defects.

---

## D-d — FR-018 subsumption of 006's scoped deck_render check

**Decision.** The general validator treats `deck_render` as governed by the **single existing SSOT**, `DECK_RENDER_ENUM` in `profile_key.py`, with a **committed equivalence test** guaranteeing the validator's accepted set never diverges from that export. The validator thereby checks `deck_render` at *profile-author / validate time* — earlier than `006`'s render-time-only check — which **closes the honest limit `profile-schema.md` §8 records** ("caught at render time, not at profile-author time"). `profile_key.py` is **left unchanged**: it remains the enum SSOT and the render-time scoped resolver; it now has a general owner (the validator) that subsumes its check.

**Rationale.** FR-018: subsume "without conflict or duplication," "so the scoped check has a general owner to defer to." One authoritative enum definition (`profile_key.py`) + a test that pins the validator to it = no divergent copy and no conflict. `profile_key.py`'s docstring says it was "deliberately shaped so a general one can absorb it" (I-27) — this is that absorption.

**Mechanism note (implement-phase detail, council-reviewable).** Preferred: a runtime import of `DECK_RENDER_ENUM` when the deck-render scripts dir is importable; where cross-install import is not robust, the validator holds the enum as a module constant that the committed equivalence test asserts equals `profile_key.DECK_RENDER_ENUM` (the same test-time cross-boundary assertion `006` T026 uses for contract docs). Either way there is exactly one authority and a mechanical guard against drift; an out-of-enum `deck_render` (e.g. `sparkle`) FAILs, matching `profile_key.py` branch 2.

**Alternatives considered.** *Re-declaring the four literals independently* — rejected (FR-018 "without duplication"). *Editing `profile_key.py` to import from the general validator* — rejected: needlessly mutates `006`'s shipped code and reverses the dependency for no gain.

---

## D-e — Schema reconciliation of the I-27-flagged keys

**Decision.** Enforce `gates.council.reopen_tier` and `gates.council.max_rounds` **exactly as `profile-schema.md` v1.2 defines them** (`reopen_tier` ∈ {auto,delta,full}; `max_rounds` == 1). **Do not prune either key.** The I-27 observations — `reopen_tier` has zero runtime consumers ("a dead key"); the convergence limit is read from `council-config.yml`, not the profile's `max_rounds` — are recorded but **not acted on** in this feature.

**Rationale.** The spec is explicit (Assumptions): "the validator enforces the contract as reconciled … it does not redesign the schema in this spec." Removing a key is a *contract amendment* (a `profile-schema.md` edit + a D-row) — out of scope. Keeping the keys valid costs nothing and is *actively correct*: validating a "dead" key still catches a typo in it (`reopen_tier: fulll`), which is exactly the silent-degrade defect class I-27 exists to close. A dead-but-valid key that silently accepts garbage would reintroduce the bug.

**Carried to the council / future.** Whether to prune `reopen_tier` or wire `max_rounds` to its real consumer is a standalone schema-reconciliation decision (a future D-row); this feature enforces the contract as it stands and flags the tension. **A D-row recording this reconciliation stance is written this session** (log discipline).

---

## D-f — FR-019 enforcement point (the council-defended decision)

**Decision (recommended, for the council to ratify or amend).** Wire the validator as a **mandatory, fail-closed `before_plan` hook**: a malformed `profile.yaml` hard-blocks before any autonomy-governed phase runs. The validator is *also* runnable standalone (like its siblings, invoked as a script). The hook wiring is a **separable task**.

**Rationale.** FR-019 requires a malformed profile be "mechanically rejected before the pipeline acts on it." The profile is first *materially* acted upon at the council phase (`council_tier`) and the council gate (`mode`/`full_auto` — the correctness guard). Validating at the pipeline's **front** (`before_plan`, well ahead of council) means **no gate ever reasons about an invalid profile** — gate internals are wholly unchanged; only well-formed profiles reach them. An absent profile passes (P1), so features without a profile (`002`-style) are never spuriously blocked. `before_tasks`/`verify-gate` is **too late** (the council gate is already signed by then).

**Alternative (presented to the council).** *Standalone-only* — script + optional command, no hook. Fully honors D79(2)'s caution about coupling a docs feature to gate-correctness, but weakens FR-019's MUST to a convention. Because the wiring is a separate task, the council can select this by cutting one task with no impact on the validator itself.

**Ownership note.** The hook's thin-skill wrapper follows the `cli-command-wrapper` pattern (resolve the feature's profile path → shell out to `validate-profile.py` → hard-block on non-zero, exactly as `verify-gate` hard-blocks). Which extension owns the hook (git's gate-enforcement family vs. workforce, alongside the validator) is a secondary, council-reviewable placement choice; the recommendation is the git extension, mirroring `verify-gate`.

---

## Cross-cutting: OSS docs accuracy & no-leakage (FR-010/FR-011)

**Decision.** Treat reference-accuracy and no-leakage as mechanical acceptance checks, not prose promises: (1) every path/command/extension cited across the OSS docs is grep-verified to resolve at authoring; (2) a leakage grep asserts no machine-specific absolute path (`/Users/…`, `/home/…`) and no personal data beyond the author name already in `LICENSE`. The authoritative pipeline sequence the README presents (FR-002) is the committed command surface: **specify → clarify → plan → council → tasks → analyze → categorize → agents → parallel-implement → complete → testing** (verified against `.claude/skills/speckit-*`). The quickstart's first command and prerequisites follow the real D45 install (Claude Code + subscription auth, **no `ANTHROPIC_API_KEY`** per FR-005/D28; build the graph with `/graphify`; start a feature with `/speckit-specify`). graphify's in-repo home is `extensions/graphify/`; its engine is the upstream `graphifyy` pip package (D75) — FR-012.

**Rationale.** FR-010/FR-011 are *measurable* (SC-003/SC-004: 100% resolve, zero leakage). Making them grep-checkable in the quickstart turns the success criteria into executable gates rather than reviewer judgment.
