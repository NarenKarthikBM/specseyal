# Graphify Context — saved-searches

_Generated 2026-06-22T10:14:03Z from `/repo/graphify-out/graph.json` (412 nodes, 1,083 edges, scope: repo). Stale after large merges — regenerate with `/speckit-graphify-context`._

> This is an illustrative example of what `/speckit-graphify-context` produces. Paths and numbers are made up.

## Graph scope
- Repo graph: `/repo/graphify-out/graph.json`
- Merged stack graph: `/stack/graphify-out/graph.json` (use for cross-repo features)
- This run used: **repo**

## Relevant existing modules
- `src/api/routes.ts` — central route manifest; every endpoint is registered here
- `src/services/search.ts` — full-text search service the new feature extends
- `src/db/schema.ts` — table definitions; shared by all data-access code
- `src/services/users.ts` — owns the current-user lookup the feature needs
- `src/components/SearchBar.tsx` — existing UI the saved-search dropdown attaches to

## Blast radius (per anchor)
- **search.ts** (`src/services/search.ts`)
  - depends on: `src/db/schema.ts`, `src/db/client.ts`
  - depended on by: `src/api/routes.ts`, `src/components/SearchBar.tsx`
  - follow the pattern in: `src/services/users.ts` (service shape, error handling)
- **schema.ts** (`src/db/schema.ts`)
  - depends on: `src/db/client.ts`
  - depended on by: `src/services/search.ts`, `src/services/users.ts`, `src/services/notes.ts`
  - follow the pattern in: existing table blocks in the same file

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never put two of them in the same parallel wave.
- `src/api/routes.ts` — route manifest; any task adding an endpoint edits it
- `src/db/schema.ts` — adding the `saved_searches` table mutates shared schema
- (migrations dir `src/db/migrations/` — new migration file is additive but ordering matters)

## Patterns to follow
- Services export a class with async methods + a typed error union — see `src/services/users.ts`
- Endpoints are thin: validate input (zod), call the service, map errors — see existing handlers in `routes.ts`
- New tables get a paired migration in `src/db/migrations/NNNN_*.sql`
