# Graphify Context — 004-testing-completion

_Generated 2026-07-12 from `graphify-out/graph.json` (1343 nodes, 2177 edges, scope: repo). Fresh taxonomy-v1 baseline (D59 pattern, this session). Stale after large merges — regenerate with `/speckit-graphify-context`._

## Graph scope
- Repo graph: `/Users/narenkarthikbm/Coding/specseyal/graphify-out/graph.json`
- Merged stack graph: n/a (single-repo feature)
- This run used: **repo**

## Honest grounding note (I-13)
The two concerns edit **shell scripts** (`verify-gate.sh`, `commit.sh`) and a YAML manifest. graphify's AST layer captures each `.sh` file's internal `defines` (die/usage/mark_stale) but almost no cross-file edges — shell has no import graph — so `explain` returns low-degree leaf nodes (verify-gate.sh deg 4, commit.sh deg 3) and `path "verify-gate.sh" → "implement-parallel"` finds **no edge** even though implement-parallel calls verify-gate every wave. That relationship is real but graph-invisible (I-13, carried to the graphify backlog). **Code-layer grounding for the `.sh`/`.yml` edits leans on direct source reads, not graph edges.** The graph's value here is the rich **concept/rationale** layer (436 concept + 213 rationale nodes) — the requirements, decisions, contracts, and the two artifacts' relationships, which it grounds well (below).

## Relevant existing modules
- `extensions/git/extension/scripts/verify-gate.sh` — the **I-17 fix target**. The gate-freshness hard-block: a workforce binding is fresh iff, for every bound artifact, recorded-SHA == current committed SHA (via `sha.sh`) **and** the working tree is clean (`git diff [--cached] --quiet`). Fail-closed. Fired by `before_implement` (gate=workforce) and per-wave by implement-parallel.
- `extensions/git/extension/scripts/commit.sh` — the **testing-seam target**. Phase-tagged commit primitive; phase enum = `spec plan council gate tasks categorize analyze agents impl complete` (**no `testing`, no `after_complete` hook uses it yet**). Grammar `<phase>(<spec-id>): <summary>`; no-op on clean scope; staging scoped to `specs/<id>/**` + extra paths.
- `extensions/git/extension/scripts/gates.sh` + `on-gate-approve.sh` — the workforce **binding writer**: `after_workforce_approve` records `tasks.md @ <sha>` + `agents/assignment.md @ <sha>` into git-ext-owned `gates.yml`. (`on-gate-approve.sh` is the D58/S02 gate-agnostic generalization — the precedent for extending git-ext gate machinery in its own source.)
- `extensions/git/extension/extension.yml` — git-ext hook manifest. Has `after_specify/clarify/plan/analyze/tasks/implement`, `after_council_approve`, `after_workforce_approve`, `before_tasks`, `before_implement`. **Missing: `after_testing`, `after_complete`.**
- `extensions/git/test/run.sh` — git-ext test harness; **§3 is the reinstall-survival-regression model** FR-015 cites (the S17 class).
- `specs/003-workforce/completion-report.md` — the **ad-hoc completion report to finalize**. The graph confirms the link: `Finalized completion-report contract --references--> 003 Completion Report`, `--conceptually_related_to--> D19 phase.completed envelope`, `--implements--> FR-004 (normative core sections)`.
- `docs/contracts/artifact-layout.md` — defines the `complete` + `testing` phase-table rows (§2), the resumability/validation rule (§3), ownership (§6), and the §9 cross-extension seam convention (D57).
- `docs/contracts/trace-schema.md` — §6 D19 `phase.completed` envelope (completion-report is its `artifact.body`); §2 `role: tester` (Sonnet); §1 `outcome` (aligns to the machine-readable status).
- Testing extension `extensions/testing/` — **(not in graph — new code)**. The `tester` Sonnet role, the `testing` phase command, and the completion/testing contracts are this feature's deliverables.

## Blast radius (per anchor)
- **verify-gate.sh** (`extensions/git/extension/scripts/verify-gate.sh`)
  - defines: `die()`, `usage()`, `mark_stale()` (the stale-report accumulator — the natural hook for a classification branch)
  - composes: `gates.sh read <gate>` (bindings), `sha.sh <artifact>` (current SHA) — never reimplements either
  - consumed by (graph-invisible, I-13): `before_implement` hook + per-wave `speckit-implement-parallel`
  - follow the pattern in: its own fail-closed structure — any new "admissible staleness" branch must stay fail-closed and mechanical (zero AI, FR-007)
- **commit.sh** (`extensions/git/extension/scripts/commit.sh`)
  - the phase enum `case "$phase"` (L89-92) is the single edit point for `testing`
  - follow the pattern in: the existing `after_*` hooks in `extension.yml` (each maps a boundary → `commit.sh <phase>`)
- **on-gate-approve.sh / gates.sh** — the re-bind path a "refresh on machinery wave commit" design would touch; `gates.yml` is git-ext's sole-owned record.

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never two in the same parallel wave.
- `extensions/git/extension/scripts/commit.sh` **and** `verify-gate.sh` — **two owned-source edits to the same extension** (testing seam + I-17 fix), redeployed together by git-ext's one `install.sh`. Coordinate; the I-17 fix must land wave-1/pre-wave (FR-016/SC-010).
- `extensions/git/extension/extension.yml` — two new hook entries (`after_testing`, `after_complete`) in one manifest.
- `extensions/git/test/run.sh` — both the testing-seam survival test and the I-17 survival-regression append here.
- `.specify/extensions.yml` — the installed hook registry every extension's `install.sh` merges into (the classic 002/003 shared/mutable file); the testing-ext install + git-ext reinstall both touch it.

## Patterns to follow
- **The 002 seam pattern** (owned-source enum edit + `after_*` hook): add `testing` to `commit.sh`'s enum + an `after_testing` hook in git-ext's `extension.yml`. Exemplar: every existing `after_<phase>` hook.
- **D57 / S17 reinstall-survival**: any git-ext source edit is redeployed by its own `install.sh` and covered by an `extensions/git/test/run.sh` §3-style survival regression (the FR-013/FR-015 requirement).
- **Gate-machinery extension in git-ext source** (D58/S02): `on-gate-approve.sh`'s council→gate-agnostic generalization is the precedent for the I-17 verify-gate change living in git-ext's own source.
- **Extension packaging**: mirror graphify/council/workforce `install.sh` — extension tree → `.specify/extensions/testing/`, skills → `.claude/skills/`, hooks merged into `.specify/extensions.yml`.
- **Completion-report finalization**: the normative core is the finalize of 003's ad-hoc `completion-report.md` structure; the dogfood milestone-close material rides as an appendix outside the validated core (FR-004).
