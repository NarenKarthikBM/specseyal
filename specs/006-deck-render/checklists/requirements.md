# Specification Quality Checklist: Optional pptx Render of the Defense Deck

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-14
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Validation run — 2026-07-14 (re-run after `/speckit-clarify`)

**FR↔SC coverage (mechanical, not by eye):** all **16** FRs (FR-001…FR-016) are cited by at least one of the **10** SCs (SC-001…SC-010). Verified by extracting both ID sets and the FR references inside the Measurable Outcomes block. *(Was 13 FRs pre-clarify; clarify added FR-014/015/016.)*

**[NEEDS CLARIFICATION] markers:** 0. **Clarification bullets recorded:** 5 (the session quota).

**Contradiction resolved at clarify:** the trigger ruling (on-demand command) exposed a real inconsistency — Constraints require `006`'s own profile to be `deck_render: none` (bootstrap: the renderer does not exist when its own council convenes), while **SC-009** requires rendering `006`'s own deck as the exit test. Had `deck_render` been a hard gate, **SC-009 would have been unsatisfiable by construction.** Resolved by FR-016 (default selection, not a hard gate); SC-001 and SC-009 updated accordingly. Caught during clarify, not left for the council.

**House-rule checks:**

- **D46 rule 3 (spec-hygiene)** — every `Constraints & Assumptions` entry cites a D-row or an M0 contract. Entries that *resolve* an open point are explicitly marked **[position taken]** rather than presented as givens: (1) absent ⇒ `none`; (2) mechanical renderer ⇒ no trace record; (3) rendered output is a derived build product, not committed. All three are reviewable at clarify / spec review.
- **Rule 5 (`artifact-layout.md` §7 / D50)** — **fixed during validation.** The first draft's "not a meta-feature" bullet named the council's per-member opinion subtree literally, which would itself have tripped the rule-5 grep from a file outside `council/`. Reworded; the spec now never names that subtree, so the grep is clean and **no exemption marker is needed or claimed**.
- **Not a "no implementation details" violation:** `pptx` appears as the *output format* named by the owner ruling (D73(3)), not as a tooling choice. The FRs say "presentation format"; no library, language, or renderer is named — those are plan-level.

## Notes

- All three pre-clarify **[position taken]** items are now resolved: committed-vs-derived → **ratified gitignored** (FR-014); mechanical-no-trace → stands (FR-011); absent-⇒-off → stands (FR-006).
- FR-012's no-source-edit-into-council/graphify constraint is what keeps this feature disjoint from the concurrently-open `005-graphify-context`. Clarify **reinforced** it: the trigger question found that no registered hook can serve the gate (`after_plan` fires before the deck exists; `after_council_approve` fires after the human signs), so auto-firing would have required a source edit into the council extension — exactly where `005` is working. The on-demand command (FR-008) avoids that entirely.
- See the spec's **Sequencing note** for the one coupling that runs the *other* way (005 books its arm-4 after-measurement to 006's council round) — flagged for the owner, deliberately not resolved here.
- **Open for spec review, not resolved here:** a git-ext defect found while running this feature's own `after_specify` hook — `branch.sh` assumes `.git` is a directory and cannot acquire its `mkdir` mutex inside a git worktree (where `.git` is a file). Latent until now because the I-4 worktree spike was abandoned (D54). Not fixed in this session; it is a git-ext source edit deserving its own review. **I-row candidate.**
