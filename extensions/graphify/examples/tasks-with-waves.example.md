# Tasks — saved-searches

> Illustrative excerpt of a `tasks.md` produced by `/speckit-tasks-graph`. The top half is the stock
> spec-kit format (unchanged, so `/speckit-analyze` still works); the `## Execution Waves` section at
> the bottom is what the graph-aware command appends.

## Phase 1 — Setup
- [ ] T001 Add `saved_searches` table to `src/db/schema.ts` and a migration
- [ ] T002 Add the `SavedSearch` type to `src/types/search.ts`

## Phase 2 — Foundational
- [ ] T003 Extend `src/services/search.ts` with `saveSearch` / `listSavedSearches`

## Phase 3 — User Story 1 (save a search)
- [ ] T010 [P] Unit tests for `saveSearch` in `tests/services/search.save.test.ts`
- [ ] T011 `POST /searches` endpoint wiring in `src/api/routes.ts`
- [ ] T012 [P] "Save this search" button in `src/components/SearchBar.tsx`

## Phase 3 — User Story 2 (list saved searches)
- [ ] T020 [P] Unit tests for `listSavedSearches` in `tests/services/search.list.test.ts`
- [ ] T021 `GET /searches` endpoint wiring in `src/api/routes.ts`
- [ ] T022 [P] Saved-search dropdown in `src/components/SavedSearchMenu.tsx`

## Phase 4 — Polish
- [ ] T030 Integration test covering save → list round-trip

---

## Execution Waves

> Machine-readable DAG for /speckit-implement-parallel. Derived from phase boundaries,
> [P] markers, TDD ordering, and graphify dependency edges. Tasks within one parallel
> wave have all dependencies satisfied by earlier waves and disjoint mutable-file sets.
> Setup and Foundational phases are serial barriers; parallelism is cross-story.

- Wave 1 [serial]   : T001, T002                 # Phase 1 Setup (schema + types — shared scaffolding)
- Wave 2 [serial]   : T003                        # Phase 2 Foundational (blocks both stories)
- Wave 3 [parallel] : T010 [US1], T020 [US2]      # independent story tests (disjoint test files)
- Wave 4 [parallel] : T012 [US1], T022 [US2]      # independent UI (disjoint component files)
- Wave 5 [serial]   : T011, T021                   # both edit src/api/routes.ts → serialized
- Wave 6 [serial]   : T030                          # integration polish

### Task annotations
- T001  files=src/db/schema.ts,src/db/migrations/0007_saved_searches.sql  deps=-          mutates=src/db/schema.ts
- T002  files=src/types/search.ts                                          deps=-          mutates=(new)
- T003  files=src/services/search.ts                                       deps=T001,T002  mutates=src/services/search.ts
- T010  files=tests/services/search.save.test.ts                           deps=T003       mutates=(new)
- T011  files=src/api/routes.ts                                            deps=T003,T010  mutates=src/api/routes.ts
- T012  files=src/components/SearchBar.tsx                                  deps=T003       mutates=src/components/SearchBar.tsx
- T020  files=tests/services/search.list.test.ts                           deps=T003       mutates=(new)
- T021  files=src/api/routes.ts                                            deps=T003,T020  mutates=src/api/routes.ts
- T022  files=src/components/SavedSearchMenu.tsx                            deps=T003       mutates=(new)
- T030  files=tests/integration/saved-searches.test.ts                     deps=T011,T021  mutates=(new)

### Shared-file serialization
- `src/api/routes.ts` touched by T011, T021 → both pinned to a serial wave; never co-scheduled.
- `src/db/schema.ts` touched by T001 only → no conflict, but it's a Setup barrier anyway.

> Note: T011 originally carried `[P]` from naive generation. `speckit-tasks-graph` stripped it —
> T011 and T021 both mutate `src/api/routes.ts`, so they can't run in the same wave.
