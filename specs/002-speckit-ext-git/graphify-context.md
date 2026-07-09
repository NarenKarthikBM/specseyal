# Graphify Context — speckit-ext-git

_Generated 2026-07-09 from `graphify-out/graph.json` (1013 nodes, 917 edges, scope: repo). Deterministic AST extraction, no LLM. Stale after large merges — regenerate with `/speckit-graphify-context`._

## Graph scope
- Repo graph: `/Users/narenkarthikbm/Coding/specseyal/graphify-out/graph.json`
- This run used: **repo** (single-repo feature; no cross-repo stack).

## Relevant existing modules
The git extension is **almost entirely new code** (`extensions/git/` does not yet exist — `(not in graph — new code)`). What the graph grounds is the **sibling-extension pattern** it must mirror and the **one shared file** it must edit:

- `extensions/council/install.sh` (`council_install`, community 101) — the install exemplar: copies `extension/` → `.specify/extensions/<name>/`, copies `skills/*` → `.claude/skills/`, prints a `bold/ok/warn/die` helper UI. 002's installer mirrors this.
- `extensions/graphify/install.sh` — the **hook-registering** install variant: graphify's installer merges its `before_*` hooks into `.specify/extensions.yml`. 002 needs this variant (it registers `before_specify` + commit hooks), where council's installer did **not** (council is command-only). 002 = council's packaging + graphify's hook-merge.
- `.specify/extensions.yml` — the hook registry (currently only graphify's `before_plan`/`before_tasks`/`before_implement`). 002 **adds** its own hook entries here.
- `.specify/scripts/bash/create-new-feature.sh` — computes the next `NNN` + slug and writes `.specify/feature.json`; **branch-agnostic** (creates no git branch). 002's branch-at-`specify` hook coordinates the branch name with this script's spec ID (FR-001/FR-002).
- Contracts consumed (not code — `docs/contracts/`): `artifact-layout.md` §2 (branch co-incident with specify, D51), §8 (`## Workforce Gate` SHA fields), `decision-record.md` (council-gate `@ <sha>` fields, R4). 002 writes SHA bindings **into** these existing artifact sections (FR-008).

## Blast radius (per anchor)
- **install.sh** (`extensions/council/install.sh`)
  - contains → helper fns `bold()/ok()/warn()/die()` — cosmetic; copy the shape.
  - follow the pattern in: `extensions/graphify/install.sh` for the `extensions.yml` hook-merge step.
- **.specify/extensions.yml** (shared registry)
  - depended on by: every `/speckit-*` phase command reads it for `before_*`/`after_*` hooks — so a malformed edit breaks **all** phases, not just git.

> **These blast-radius claims are engineer assertion, re-derived by reading files — NOT graph fact (R1-S22 / I-13).** `graphify explain`/`path` return "No node matching" for `.sh`/`.yml`, so the graph emits nothing for this feature's file types. Treat the `install.sh`/`extensions.yml` wiring above as read-and-reasoned, not graph-grounded, until graphify's extractor covers shell + YAML (I-13).

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never two in one parallel wave.
- `.specify/extensions.yml` — the single graph-grounded shared/mutable collision point. 002's installer **merges** hooks in (append, never overwrite — it already holds graphify's three `before_*` hooks). Orchestrator glue, never a parallel subagent's job.
- `.specify/feature.json` — gitignored/transient (D45); the branch hook reads the spec ID from here but must not couple downstream phases to the branch (FR-013).

**Retraction (R1-S03).** The earlier "only `.specify/extensions.yml` is touched; all other 002 files are new and disjoint" manifest was **false** and would have let `/speckit-tasks` omit the seam. 002 **edits five existing files**, each its own task (each edited by exactly one task → parallelizable among themselves, but they are *source mutations*, not "all new"):
1. `.specify/extensions.yml` — installer hook-merge (the shared registry above).
2. `speckit-council-approve` behavior — via a reinstall-surviving **`after_council_approve` hook** (R1-S04), **not** a source edit.
3. `.claude/skills/speckit-implement-parallel/SKILL.md` — the per-wave commit-before-`[X]` + gate re-verify (R1-S06/S23).
4. `.claude/skills/speckit-tasks/SKILL.md` + `.claude/skills/speckit-implement/SKILL.md` — the stop-on-nonzero clause (R1-S02).
5. This file (`graphify-context.md`) — regenerated to match (R1-S03) + the `before_specify` correction (R1-S16).

All other `extensions/git/**` files are genuinely new and disjoint → freely parallelizable.

## Patterns to follow
- **Installer**: mirror `extensions/council/install.sh` (payload + skills copy, `bold/ok/warn/die` UI, `rm -rf` + `cp -R` for idempotency) **plus** graphify's `extensions.yml` hook-merge; ship a matching `uninstall.sh` that removes only what it added (FR-014).
- **Hooks compose by schema, ordered by `priority`**: graphify's entries are `optional: true`; 002's hard-block/commit hooks are **`optional: false`** (R1-S01). *(Corrected, R1-S07: the earlier "the git commit hook runs after graphify's context hook at a shared boundary" was **impossible** — every git commit hook is `after_*`, graphify is exclusively `before_*`, so they never share a boundary. The only shared keys are `before_tasks`/`before_implement`, where the installer inserts git's `verify-gate` **ahead of** graphify by giving it a lower `priority` — making `priority` live, not a zombie field.)*
- **Command grammar**: phase-tagged commits `<phase>(<spec-id>): …` / `impl(<spec-id>) wave K/N: …` are already the de-facto convention across the M1 trail (`git log` on `main`) — the extension formalizes what those commits already look like (FR-006).
- **No new state file** (D32): branch state = the git ref. *(Corrected, R1-S09/S20: gate-SHA bindings live in the **git-ext-owned `specs/NNN/gates.yml`** bindings record — **not** in `decision-record.md`/`assignment.md` sections, which would co-write a council/human-owned artifact. `gates.yml` is a bindings record, not phase state — the gate section's existence still marks the phase done. FR-008.)*
