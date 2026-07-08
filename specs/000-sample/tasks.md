# Tasks — 000-sample

> Fixture. Stock spec-kit checklist format (so `/speckit-analyze` still works) plus the
> `## Execution Waves` section appended by `/speckit-tasks-graph`.
> **No task here is ever implemented.** `000-sample` produces no code.

## Phase 1 — Setup
- [X] T001 Create the fixture directory skeleton under `specs/000-sample/`

## Phase 2 — Foundational
- [X] T002 Author `profile.yaml` against `docs/contracts/profile-schema.md`

## Phase 3 — User Story 1 (the fixture validates)
- [X] T003 [P] Author `traces.jsonl` against `docs/contracts/trace-schema.md`
- [X] T004 [P] Author `README.md` explaining the fixture's two deliberate oddities

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries,
> [P] markers, TDD ordering, and graphify dependency edges. Tasks within one parallel
> wave have all dependencies satisfied by earlier waves and disjoint mutable-file sets.
> Setup and Foundational phases are serial barriers; parallelism is cross-story.

- Wave 1 [serial]   : T001                # Phase 1 Setup (directory skeleton)
- Wave 2 [serial]   : T002                # Phase 2 Foundational (profile gates everything)
- Wave 3 [parallel] : T003, T004          # disjoint files, no shared mutable state

### Task annotations
- T001  files=specs/000-sample/                    deps=-      mutates=(new)
- T002  files=specs/000-sample/profile.yaml        deps=T001   mutates=(new)
- T003  files=specs/000-sample/traces.jsonl        deps=T002   mutates=(new)
- T004  files=specs/000-sample/README.md           deps=T001   mutates=(new)

### Shared-file serialization
- (none found — every task's `files=` set is disjoint and brand-new)
