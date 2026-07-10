# Graphify Context — 003-workforce (the workforce pair)

_Generated 2026-07-10 from `graphify-out/graph.json` (497 nodes, 888 edges, scope: repo). This is the committed **tiered-council baseline** (D59; snapshot at `specs/003-workforce/graph-baseline.json`). Stale after large merges — regenerate with `/speckit-graphify-context`._

## Graph scope
- Repo graph: `/Users/narenkarthikbm/Coding/specseyal/graphify-out/graph.json`
- Merged stack graph: n/a (single-repo feature)
- This run used: **repo**

## What this feature is (from the graph)
The pair is **two new pipeline extensions** delivered as one feature — both resolve as `concept` nodes sourced in `specs/003-workforce/spec.md`, **not yet wired into the repo** (`graphify path` finds no edge from either to `.specify/extensions.yml`): this is **new code**, grounded on the three existing extensions as exemplars.
- **`speckit-ext-categorize`** (`spec.md` FR-001..FR-005) → writes `categorization.md`, enforces the 20% `general` cap (FR-004), targets the blessed taxonomy v0.
- **`speckit-ext-agents`** (`spec.md` FR-006..FR-016) → the **skill builder** (∅-match authorship, the D24 flywheel) + the **assembler/assigner** (writes `agents/assignment.md`).

## Relevant existing modules (exemplars + consumed contracts)

**Extension packaging exemplars** (how a new pipeline extension is built — mirror these):
- `.specify/extensions/git/extension.yml` — manifest pattern: README → `extension.yml` → commands; references the graphify manifest (**install ordering matters**). The git ext is the closest analog (a new extension with commands + hooks + a config yml + install/uninstall + a test harness).
- `extensions/council/`, `extensions/git/`, `extensions/graphify/` — the `extensions/<name>/` **source** tree that each `install.sh` copies into `.specify/extensions/<name>/` + `.claude/skills/` (the D57 rule: edits live in source, survive reinstall).

**Contracts the pair consumes** (community 6, tightly cross-referenced — the council will check receipts here):
- `docs/contracts/taxonomy-v0.md` — **BLESSED** closed enums (8 types × 11 specializations); categorizer targets it.
- `docs/contracts/agent-library-schema.md` — base-specialist format + §3 matching/assembly algorithm + §4 model policy; references taxonomy, skill-module, trace-schema, D18.
- `docs/contracts/skill-module.md` — `SKILL.md` format, additive-only S1–S3, grants (D41); references taxonomy + agent-library-schema.
- `docs/contracts/artifact-layout.md` — §2 phase table (analyze→categorize→assign→workforce-gate, D58), §6 ownership, §8 `## Workforce Gate` format, §9 cross-extension seams.
- `docs/contracts/trace-schema.md` — §1 `skills[]`/`elevated_grants[]` (D43), §5 flywheel `skill_success` rollup.

**Artifact ownership** (single-writer, §6):
- `categorization.md` (`spec.md` Key Entities) — `shares_data_with` the Assembler; **categorize ext owns it, writes nothing else** (D37).
- `agents/assignment.md` (`spec.md` FR-010/FR-017) — the Assembler writes it; carries the `## Workforce Gate` roster.

## Blast radius (per anchor)
- **`speckit-ext-categorize`** (`specs/003-workforce/spec.md`, not in graph as code — new)
  - reads: `tasks.md`, `plan.md`; writes: `categorization.md`
  - follow the pattern in: `extensions/git/` (new extension scaffold), a **separate-session** command like `speckit-tasks-graph`
- **`speckit-ext-agents`** (skill builder + assembler; new)
  - reads: `categorization.md`, `.claude/agents/`, `.claude/skills/`; writes: `agents/assignment.md` + new `SKILL.md` files (flywheel)
  - follow the pattern in: `extensions/council/` (multi-command extension); assembly algorithm is `agent-library-schema.md` §3 verbatim
- **`.claude/agents/` + `.claude/skills/` (the seed library)** — new curated files; bases follow `agent-library-schema.md` §1.1, skills follow `skill-module.md`; `refactor-discipline` already exists as the seed skill (`specs/000-sample/.claude/skills/refactor-discipline/SKILL.md`).

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never put two in the same parallel wave.
- **`.specify/extensions.yml`** — the hook registry, **degree 15** (every pipeline command references it). The categorize + agents extensions register their hooks here; like git-ext, this is an **installer hook-merge**, not a source overwrite. **The single highest-collision file in the repo.**
- **`.claude/skills/`** — the skill-builder **writes** new `SKILL.md`s here at runtime (flywheel). This is the exact directory installers `rm -rf` on reinstall (the 002 reinstall-survival hazard, I-14/D57) — the generated-skill persistence path must not collide with an extension's installed tree.
- `.specify/extensions/<name>/` + `.claude/skills/speckit-*` — installer-overwritten trees (D57 S2): any cross-extension coupling is a **hook point**, never a source edit into a foreign extension.

## Patterns to follow
- **Sibling-of-graphify/git packaging** (community 8/29): `extensions/<name>/` source → `install.sh` copies to `.specify/extensions/<name>/` + `.claude/skills/`; `uninstall.sh` deregisters first; a `test/run.sh` covers reinstall-survival.
- **Hook points over source edits** (D57 §9): couple `categorize` → `agent-assign` at an `extension.yml` hook, never by patching another extension's installed file.
- **Single-writer artifacts** (§6, D37): categorize writes only `categorization.md`; agents writes only `agents/assignment.md`; neither mutates `tasks.md`.
- **Separate-session commands** (§2 session-boundary): categorizer and assembler each run as their own session (FR-001/FR-010), appending one `traces.jsonl` record.
- **Deterministic assembly** (`agent-library-schema.md` §3 step 4): total-order the skill ranking so the roster is byte-reproducible on gap-free runs (FR-015/SC-005).
