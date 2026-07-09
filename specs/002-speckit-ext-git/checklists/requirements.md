# Specification Quality Checklist: speckit-ext-git — Per-Feature Git Lifecycle

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-09
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs) — *git mechanics (branch, commit, SHA, merge-commit, worktree) are the **subject matter** of a git-lifecycle extension, not implementation leakage — the same stance 001 took with "subagents/Sonnet/opinions". The `--no-ff`/fast-forward and SHA-binding mentions are the **positions the description required the spec to take**, stated as observable outcomes + rationale; exact git commands, hook wiring, and message grammar are explicitly deferred to `/speckit-plan` (Reading note).*
- [x] Focused on user value and business needs — *zero-touch lifecycle, wave-resumability, approval integrity, trail preservation.*
- [x] Written for non-technical stakeholders — *the "stakeholder" is the engineer driving the pipeline (developer tooling; Reading note); each user story leads with plain-language value.*
- [x] All mandatory sections completed — *User Scenarios & Testing, Requirements, Success Criteria; plus the repo-convention Constraints & Assumptions.*

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain — *0; all four contested points resolved to explicit positions (FR-001, FR-005/006, FR-008/009, FR-011).*
- [x] Requirements are testable and unambiguous — *each FR names an observable git outcome; two positions (FR-001, FR-011) carry an explicit "refines/standardizes X — flagged for ratification" note so the reviewer sees what is being changed.*
- [x] Success criteria are measurable — *100% / exactly-one / zero / within-timebox thresholds throughout.*
- [x] Success criteria are technology-agnostic — *within the constraint that git IS this feature's domain; SCs describe git-state outcomes (branch exists, commit reachable, SHA recorded, branch ref removed), never code or tooling internals.*
- [x] All acceptance scenarios are defined — *every user story has Given/When/Then scenarios.*
- [x] Edge cases are identified — *8 edge cases incl. base-advanced merge, idempotent re-specify, empty-boundary, stale approval, auto-gate binding, abandoned branch, feature.json↔branch divergence, convention drift.*
- [x] Scope is clearly bounded — *in-scope = D25 v1 (branch/commit/gate-SHA/cleanup); out-of-scope = remote/PR/push (local-git only), AI behavior, automated analyze routing; worktrees = firewalled P3 spike.*
- [x] Dependencies and assumptions identified — *Constraints & Assumptions section; every entry cites a D-row (D46 standing rule).*

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria — *via the mapped user-story scenarios and SC-001…SC-008.*
- [x] User scenarios cover primary flows — *US1 lifecycle (P1), US2 wave-resume (P1), US3 gate-SHA (P2), US4 completion (P2), US5 spike (P3).*
- [x] Feature meets measurable outcomes defined in Success Criteria — *SC-001 is the M2 exit condition verbatim (docs/05 M2).*
- [x] No implementation details leak into specification — *per the Content-Quality note: git domain terms only; the "how" is deferred to plan.*

## Notes

- **All items pass. Spec APPROVED at review (D51).**
- **Two positions ratified (D51)**: FR-001 (branch co-incident with `specify`) is applied to `artifact-layout.md` §2 (contract → 1.2); FR-011 is strengthened to **unconditional `--no-ff`** — the merge commit is the feature's D19/M5 completion anchor, so it must exist even when history is linear (no fast-forward exception; M1's ff grandfathered). FR-008/009 amended: stale-approval re-approval routes by gate type.
- **Standing rule honored (D46)**: the Constraints & Assumptions section carries only D-row-cited givens; the four contested positions live in Functional Requirements (observable behavior), not Constraints.
