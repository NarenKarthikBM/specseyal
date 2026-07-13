# Feature Specification: Optional pptx Render of the Defense Deck

**Feature Branch**: `006-deck-render`

**Created**: 2026-07-14

**Status**: Draft

**Input**: User description: "006-deck-render — an OPTIONAL, config-flagged pptx render of the council defense deck, as a downstream add-on for human review. Implements D73(3); D15 stays unamended (this is D15's deferral clause landing early, not a change to what is authoritative)."

> ## The boundary, in one line
>
> **The markdown is the artifact of record. The pptx is a derived render — never reviewed, never gate-bound, never traced, never an input to any phase.**
>
> That line is this feature's `executed: none` (the `004` precedent, D68): one declarative statement a reader cannot misread, restated **inside every rendered file** (FR-003) so that a stakeholder holding only the pptx cannot mistake it for the thing the council reviewed.

> **Reading note.** This is the second feature of the D73 α-polish trio (`005` → **`006`** → `007` → the visibility commit). It is **S**-sized and it adds **no pipeline function**: it takes the defense deck the council extension already writes as markdown (`council/defense-deck/technical.md` + `overview.md`, D15/D38) and — *only when a feature's profile asks for it* — emits a presentation-format copy for a human to read.
>
> **D15 is unamended.** D15 fixed the deck format as *markdown v1* and deferred "presentational rendering" to the GUI. This feature does not reopen that: it lands D15's **deferral clause** early, in the CLI, without changing what is authoritative. Nothing the council reads, nothing a gate binds, and nothing a trace records changes.
>
> **Interim by design.** The M5 platform GUI is the designed home for presentational rendering (D15) and for approving the council gate from a phone via the non-technical deck (D21). This feature is the **CLI-era precursor to that gate view**, and it is expected to be *superseded in its gate-review role* when M5 ships. It is therefore specified to stay small, additive, default-off, and cheaply removable (FR-013) — an honest stopgap, not a permanent surface.
>
> Decisions already ratified in `docs/90` and the M0 contracts appear under **Constraints & Assumptions** as givens citing their D-row (D46 spec-hygiene rule), not as open choices. Where this spec *resolves* something the D-rows left open, it says so as a **[position taken]** — reviewable at clarify and at spec review, not smuggled in.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A human reviews the council gate from a presentable overview deck (Priority: P1)

The owner reaches the council gate. Today the decision artifact is `council/defense-deck/overview.md` — a one-page non-technical markdown file (001-FR-001, 001-SC-007) read in a terminal or a git diff. With `deck_render: overview` set in the feature's profile, that same overview is *also* available as a presentation file: openable, projectable, readable on a phone, and — critically — **stamped on its face as a derived render whose source of truth is the markdown**.

The human still approves against the markdown. The render changes how the argument is *read*, never what is *reviewed*.

**Why this priority**: This is the feature's reason to exist, and it is the I-6 lineage — the non-technical overview is the natural stakeholder artifact. It is also the artifact D21 named: the council gate, approvable from a phone via the non-technical deck. If only this ships, the feature has delivered its value.

**Independent Test**: Take any completed feature's `council/defense-deck/overview.md`, set `deck_render: overview`, run the render → a presentation file opens in a standard viewer, carries every claim the markdown makes and no others, and displays the derived-render stamp naming its source path and that source's SHA.

**Acceptance Scenarios**:

1. **Given** a feature whose profile sets `deck_render: overview` and whose deck exists, **When** the render runs, **Then** a rendered overview deck is produced, it is content-faithful to `overview.md`, and it carries the derived-render stamp (source path + source SHA).
2. **Given** the rendered overview deck, **When** a non-technical reader reads *only* it, **Then** they can reach an approve/reject decision (the 001-SC-007 property, preserved through the render) **and** they can see from the file itself that the markdown — not this file — is what the council reviewed and what the gate binds.
3. **Given** the human gate, **When** the reviewer approves, **Then** the approval binds `plan.md`'s markdown SHA exactly as before: no rendered file appears in `gates.yml`, in any trace record, or in any council session's context-in.

---

### User Story 2 - Rendering is off unless a feature explicitly asks for it, per deck (Priority: P1)

A feature's `profile.yaml` selects which decks render: `none` (the default), `technical`, `overview`, or `both`. A feature that says nothing gets nothing rendered — no file, no spend, no behavior change, no new failure mode.

**Why this priority**: P1 alongside US1 because the *default-off* half is what makes the feature safe to add at all. A renderer that fired unasked would drop a derived binary beside every council artifact in the repo and hand every future reader a second thing that looks authoritative. Default-`none` is what keeps D15's invariant true in practice rather than only in prose.

**Independent Test**: Run a full council phase on a feature with no `deck_render` key (and again with `deck_render: none`) → zero rendered files, zero new trace records, and a `council/` subtree byte-identical to what the pre-006 pipeline produces.

**Acceptance Scenarios**:

1. **Given** a profile with no `deck_render` key, **When** the council phase runs, **Then** nothing is rendered and the pipeline behaves exactly as it did before this feature existed.
2. **Given** `deck_render: both`, **When** the council phase runs, **Then** both the technical and the overview decks are rendered.
3. **Given** `deck_render: sparkle` (not in the enum), **When** the profile is validated, **Then** validation **fails** — the value set is closed, and a typo must not silently degrade to a default that happens to be safe today (the `profile-schema.md` §3 ethos).

---

### User Story 3 - A render failure never blocks the gate (Priority: P1)

The render fails: the toolchain is missing on this machine, the markdown has a structure the renderer cannot lay out, the disk is full. The council gate stays reachable and approvable, every markdown artifact is untouched, the council phase does not fail — and the human is **told** the render failed rather than left to notice its absence.

**Why this priority**: P1 because it is the invariant that makes the feature *safe*, and the one most easily got wrong. The markdown is the artifact of record; a convenience add-on that can halt a governance gate has inverted the hierarchy this feature exists to protect. **Degrade and disclose — never halt.**

**Independent Test**: Force a render failure (make the renderer unavailable) on a feature with `deck_render: overview` → the council phase completes, the gate is reachable and approvable, every `.md` under `council/` is byte-identical, and a disclosed failure notice reaches the human.

**Acceptance Scenarios**:

1. **Given** `deck_render: overview` and a renderer that fails, **When** the council phase runs, **Then** the phase does **not** fail, the gate is reachable, and no markdown artifact is modified.
2. **Given** that failure, **When** the human reaches the gate, **Then** the failure is **disclosed** — the human learns a render was requested and did not happen, and proceeds on the markdown. Silence is not an acceptable degradation.
3. **Given** a render failure, **When** the pipeline continues, **Then** no rendered file from a *previous* run is presented as if it were current — a stale render is never a silent substitute for a failed one.

---

### Edge Cases

- **The deck is regenerated on a revision round** (D38 — `defense-deck/` is overwritten in place when a blocking suggestion forces a plan revision). The render MUST re-derive from the new markdown or be removed. A render whose stamped source-SHA no longer matches its source markdown is **stale**, must be detectable as such from its own face (FR-003), and must never be presented at the gate as current.
- **Rendering enabled, no deck present** (the council phase has not run) → no-op, not an error. There is nothing to render yet.
- **Rendering enabled on an `auto`-gated council** (`gates.council.mode: auto` — no human reads the gate) → the render still fires if configured. Render config and gate mode are deliberately **not coupled**: the render's audience may be a stakeholder outside the gate (the I-6 lineage), not only the gate reader. Configuration means configuration.
- **A rendered file is hand-edited** → it is a derived output; the next render overwrites it. Hand-editing a render is editing a copy, and the stamp on its face says so.
- **Malformed or unrenderable markdown** → degrade + disclose (US3). The renderer never "fixes" the markdown to make it render — it transforms, it never authors (FR-002).

## Requirements *(mandatory)*

### Functional Requirements

**The boundary (the load-bearing group).**

- **FR-001**: The markdown deck MUST remain the artifact of record. A rendered deck MUST NOT be read by any council session, MUST NOT be bound by any gate (`gates.yml` binds `.md` SHAs only), MUST NOT be an input to any pipeline phase, and MUST NOT appear in `traces.jsonl` as a phase artifact. *(D15 unamended; D73(3).)*
- **FR-002**: The renderer MUST be **content-faithful**: every claim and section present in the source markdown appears in the render, and the render introduces **no** claim, section, or wording absent from the source. **The renderer transforms; it never authors.** *(A render that could re-word the argument could make the pptx say what the reviewed markdown does not — the precise failure FR-001 exists to prevent.)*
- **FR-003**: Every rendered deck MUST carry, on its own face, a legible **derived-render stamp**: a declaration that it is a derived render and not the artifact of record, naming its source markdown path and that source's SHA. *(The in-file restatement of this spec's boundary line — and what makes staleness detectable, SC-007.)*

**Configuration.**

- **FR-004**: The system MUST be able to render a defense deck's markdown into a presentation format, selectable **per deck type** (technical, overview).
- **FR-005**: Render selection MUST live in the feature's `profile.yaml` as a single closed-enum key — **`deck_render` ∈ {`none`, `technical`, `overview`, `both`}** — because the choice is per-feature (D73(3): "profile-configurable per deck") and `profile.yaml` is the per-feature configuration artifact. *(Shape follows the `council_tier` precedent — a flat enum scalar, not a mapping: it is one closed knob, and `profile-schema.md` §1 reserves mapping shape for the gate blocks.)*
- **FR-006**: **Absent ⇒ `none`.** A profile naming no `deck_render` renders nothing. An out-of-enum value MUST **fail validation**, never fall back to a default (`profile-schema.md` §3 — unknown keys are a validation error, not a warning).
- **FR-007**: With `deck_render` absent or `none`, the pipeline MUST be unchanged: no rendered file, no new trace record, no new failure mode, and no observable difference in the council phase's behavior or artifacts.

**Trigger and failure semantics.**

- **FR-008**: The rendered deck MUST be available to the human **at the council gate**, and MUST correspond to the deck version that human is reading. When the deck is regenerated (D38 revision round), any previously rendered deck MUST be re-derived or removed.
- **FR-009**: A render failure MUST NOT block or fail the council gate, the council phase, or any other pipeline phase, and MUST NOT modify any markdown artifact. **Degrade, never halt.**
- **FR-010**: A render failure MUST be **disclosed** to the human at the gate — never silent. *(The FR-019 reduced-grounding lineage, D46(4): a degraded state is surfaced where the decision is made, never presented as whole.)*

**Cost, seam, and reversibility.**

- **FR-011**: The renderer MUST be a **deterministic, mechanical transform — it MUST NOT invoke a model.** It therefore adds no AI role, no token spend, and **no `traces.jsonl` record** (the `/speckit-git-cleanup` FR-007 class: mechanical, model-free steps leave no trace record — traces record *sessions*).
- **FR-012**: The render MUST attach at a hook/seam and MUST NOT make source edits into the council or graphify extensions (D57 / `artifact-layout.md` §9 — cross-extension coupling attaches at a hook point, never a source edit into another extension's installer-overwritten tree). The seam MUST survive a reinstall of its own extension **and** of a foreign extension (the S17 reinstall-survival class).
- **FR-013**: The feature MUST be **cheaply removable**: with it absent or disabled, the council/gate pipeline is byte-identical to its pre-006 behavior — the honest design consequence of being interim-by-design (D15/D21; superseded in its gate role by M5).

### Key Entities

- **Defense deck (markdown)** — **the artifact of record.** `council/defense-deck/technical.md` (for council members) and `overview.md` (one page, non-technical, for the human gate). Written by deck-prep; not round-scoped; overwritten in place on revision, with git as its version store (D15, D38, 001-FR-001).
- **Rendered deck (presentation file)** — a **derived render** of one markdown deck. Optional, default-absent, per-deck. Never reviewed, never gate-bound, never traced, never an input to any phase. Carries a derived-render stamp naming its source path and source SHA.
- **`deck_render` (profile key)** — the per-feature, closed-enum selector `{none, technical, overview, both}`, default `none`, admitted into `profile-schema.md` by amendment.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** (**the default path is untouched**): With `deck_render` absent or `none`, a full council phase produces **zero** rendered files, **zero** new trace records, and a `council/` subtree byte-identical to the pre-006 pipeline's (FR-007, FR-013).
- **SC-002**: With `deck_render: overview`, a council run produces a rendered overview deck that opens in a standard presentation viewer and displays the derived-render stamp — source path + source SHA (FR-004, FR-003).
- **SC-003** (**fidelity**): Against a committed fixture deck, **100%** of the source markdown's claims and sections appear in the render, and the render introduces **zero** claims absent from the source (FR-002 — verified mechanically, not by eye).
- **SC-004** (**degrade, never halt**): Under a forced render failure, the council phase completes, the gate is reachable and approvable, **every** `.md` under `council/` is byte-identical, and a failure notice reaches the human (FR-009 **and** FR-010 together — the phase survives *and* the human is told).
- **SC-005** (**the boundary holds mechanically**): Across a rendered run, no rendered file appears in `gates.yml`, in any `traces.jsonl` record, or in any council session's context-in. *(The falsifiable form of FR-001 — grep-able, not asserted.)*
- **SC-006** (**free**): A rendered run's `council_spend` is **identical** to an unrendered run's — the render adds zero model calls and zero tokens (FR-011).
- **SC-007** (**staleness is visible**): When a deck's markdown changes after a render, the stale render is detectable from its own stamp — stamped source SHA ≠ current source SHA (FR-003, FR-008).
- **SC-008**: A `profile.yaml` carrying an out-of-enum `deck_render` value **fails validation** (closed enum, FR-005/FR-006).
- **SC-009** (**006 exit, dogfood**): After implement, running the renderer against **006's own** committed `council/defense-deck/overview.md` produces a valid, stamped, content-faithful rendered deck. *(006's own council necessarily runs with `deck_render: none` — the renderer does not exist when its own plan is defended. See Constraints. `007` is the first feature that can enable the flag at council time.)*
- **SC-010** (**the seam is clean and survives reinstall**): No file under the council or graphify extensions' source trees is modified by this feature (grep-able, FR-012), and the render seam still fires after a reinstall of its own extension **and** after a foreign-extension reinstall (the S17 survival-regression class, D57 / `artifact-layout.md` §9).

## Constraints & Assumptions

Every entry is a ratified given — a `docs/90` D-row or an M0 contract — per the D46 spec-hygiene rule, not an open choice. Items this spec *resolves* are marked **[position taken]** and are reviewable at clarify and at spec review.

- **Markdown is the artifact of record; D15 is unamended** (D15, D73(3)): D15 fixed the deck as markdown v1 and deferred presentational rendering. This feature lands that **deferral clause** early in the CLI; it changes nothing about what is authoritative. The council reads `.md`; gates bind `.md` SHAs; triage and the decision record reference `.md`.
- **The pptx is never reviewed and never gate-bound** (D73(3)): stated by the owner ruling that scoped this feature. It is output, not artifact.
- **The deck is not round-scoped** (D38): `defense-deck/` is overwritten in place on a revision round; git on the feature branch is its version store. This is *why* FR-008 requires re-derivation and FR-007 requires a source-SHA stamp — the source it renders is a file that legitimately changes underneath it.
- **Config is per-feature** (D73(3), "profile-configurable per deck"): the selector belongs in `profile.yaml`, the per-feature configuration artifact (`profile-schema.md`), not in a repo-global config.
- **Admitting `deck_render` is a contract amendment** (`profile-schema.md` §3 — unknown keys are a **validation error**, not a warning): the key must be added to the contract (→ **1.2**) before any profile may carry it, and the canonical fixture `specs/000-sample/profile.yaml` gains `deck_render: none` **in the same commit** (contract-change discipline — the D47/D59 precedent).
- **Absent ⇒ the state that changes nothing** (the `profile-schema.md` P1/T1 ethos): for a *gate*, absent means the most review; for an *optional derived output*, it means off. Both are the same rule — a missing key never buys you something you did not ask for. **[position taken]** — the direction inverts relative to `council_tier` (where absent ⇒ *more* ceremony), and it is stated here rather than left for a reader to trip over.
- **Cross-extension coupling attaches at a hook point** (D57 / `artifact-layout.md` §9): the render is wired at a seam, never as a source edit into the council extension's installer-overwritten tree. *(This is also what keeps `006` disjoint from `005-graphify-context`, which is concurrently rewriting council and graphify internals — see the Sequencing note.)*
- **Degrade and disclose, never halt** (the FR-019 / D46(4) reduced-grounding lineage): the council already degrades rather than blocking when the graph is absent, and *surfaces* that degradation where the decision is made. A failed render is the same shape of event and gets the same treatment.
- **Mechanical ⇒ no trace record** (D35 + principle 4; the `/speckit-git-cleanup` FR-007 precedent): traces record *sessions*; a deterministic, model-free transform is not a session and leaves no record. **[position taken]** — the renderer could have been a model session that "lays the slides out nicely"; it deliberately is not, because a model in this path would become a **second author** of the deck's content and could make the pptx say what the reviewed markdown does not (FR-002).
- **Rendered output is a derived build product, not a committed artifact** (the D45/D59 precedent — the working graph is gitignored, and only a scoped, reasoned snapshot was ever committed): renders are regenerable from the markdown at any time, so committing them would place a stale binary receipt in the history where a reader could mistake it for the record — the exact hazard D59 named. **[position taken]** — this is the most contestable call in the spec (it trades repo hygiene against a teammate getting the deck on clone) and it is flagged for clarify.
- **Interim by design** (D15, "presentational rendering deferred to GUI"; D21, GUI MVP = observe + approve gates, council gate approvable from a phone via the non-technical deck): this feature is the CLI-era precursor to the M5 platform gate view and is expected to be superseded **in its gate-review role** when M5 ships. FR-013 (cheap removability) is the design consequence of saying so honestly.
- **I-6 is the lineage, not the scope**: the non-technical overview is the natural stakeholder artifact, reusable in work contexts (e.g. AI-First Delivery program demos). This feature makes that reuse *possible* by producing a self-contained, shareable overview deck. It does **not** build for it: **branding/templating, an export pipeline, redaction, and any work-context adaptation are explicitly OUT OF SCOPE** — a later feature, if the reuse proves real. The door is held open; nothing walks through it here.
- **`profile.yaml` — `council_tier: standard`** (D61): `006` is **S**-sized (D73(2)) and not architecture-changing, so the cost-controlled standard tier applies.
- **`profile.yaml` — both gates `human`** (D33): the explicit safest profile. The roster is expected grant-free (a mechanical, model-free renderer reaches no network), so the D67 grant tripwire is expected clear.
- **`profile.yaml` — `deck_render: none` for `006` itself** (a bootstrap fact, the D46(2) class): the renderer does not exist when `006`'s own council convenes, so `006`'s council necessarily runs unrendered. This is a bootstrap fact, not a conformance gap. `007-oss-docs` is the first feature that can set the flag at council time. *(The profile is authored at plan time — the `004` precedent — with these choices recorded here as Constraints.)*
- **Not a meta-feature** (`artifact-layout.md` §7 / D50): this feature renders the *deck* and never touches the council's per-member opinion subtree, so it carries **no** rule-5 exemption marker — and this spec is deliberately written so that it never names that subtree, keeping the rule-5 grep clean rather than earning an exemption it does not need.

## Sequencing note — `005-graphify-context` is open

`005` is unmerged and is concurrently rewriting graphify and council internals. This spec was authored on a branch cut from `main` and takes **no dependency on any `005` change**:

- What `006` consumes is the deck's **markdown output** (`council/defense-deck/*.md`), which `005` does not alter.
- What `006` writes is a derived render plus a `profile.yaml` key — neither is touched by `005`.
- FR-012 (hook-seam; no source edits into council/graphify — D57) keeps the two features disjoint at the file level **by construction, not by luck**.

**One coupling exists, and it runs in the other direction** — flagged here rather than resolved: `005` books the after-measurement of its arm-4 query ceiling to the *next* council round, which is `006`'s. That makes `006`'s council round a measurement instrument for `005` — an argument for `005` merging before `006`'s council convenes, but **not** a dependency of this spec. It is a scheduling matter for the owner, not a spec change.
