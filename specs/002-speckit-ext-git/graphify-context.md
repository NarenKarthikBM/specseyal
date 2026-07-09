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

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never two in one parallel wave.
- `.specify/extensions.yml` — the single shared/mutable file. 002's installer **merges** hooks in (append, never overwrite — it already holds graphify's three `before_*` hooks). This is the one true collision point; the merge is orchestrator glue, never a parallel subagent's job.
- `.specify/feature.json` — gitignored/transient (D45); the branch hook reads the spec ID from here but must not couple downstream phases to the branch (FR-013).
- (All other 002 files are new and disjoint → freely parallelizable.)

## Patterns to follow
- **Installer**: mirror `extensions/council/install.sh` (payload + skills copy, `bold/ok/warn/die` UI, `rm -rf` + `cp -R` for idempotency) **plus** graphify's `extensions.yml` hook-merge; ship a matching `uninstall.sh` that removes only what it added (FR-014).
- **Hooks are optional, priority-ordered**: graphify's entries are `optional: true, priority: N`; 002's commit hooks should follow the same schema so they compose (the git commit hook runs *after* graphify's context hook at a shared boundary).
- **Command grammar**: phase-tagged commits `<phase>(<spec-id>): …` / `impl(<spec-id>) wave K/N: …` are already the de-facto convention across the M1 trail (`git log` on `main`) — the extension formalizes what those commits already look like (FR-006).
- **No new state file** (D32): branch state = the git ref; gate-SHA bindings live in `decision-record.md` / `assignment.md` sections — never a sidecar (FR-007/FR-008).
