# Phase 1 Data Model — 008 Pre-Public Maintenance

This feature is tooling/maintenance, not a data-bearing service — its "entities" are the artifacts, scripts, and record fields the six items create or touch. Each maps to a spec §Key Entities row and the contract it must satisfy.

## E1 — Clone-free installer (`bootstrap.sh`) · US1/I-32

| Aspect | Detail |
|--------|--------|
| **Kind** | New root-level POSIX `sh` script |
| **Inputs** | `<extension-name>` (one of `git`/`graphify`/`council`/`workforce`/`testing`/`deck-render`), `<target-repo-dir>` (default `.`), optional pinned ref |
| **Behavior** | Fetch `extensions/<name>/` from the pinned repo ref into a temp dir → delegate to that extension's own `install.sh <target>` → clean up temp dir |
| **State transitions** | `absent → acquired (temp) → installed (target) → temp cleaned` |
| **Invariants** | Idempotent + reinstall-safe (FR-003); **additive** — never removes/breaks the local `install.sh` route (D45); no acquisition step left undocumented in README (FR-002) |
| **Validation** | Acceptance §US1 1–3; SC-001/002/003 |

## E2 — Contract conformance checker (`check-conformance.py`) · US2/I-11

| Aspect | Detail |
|--------|--------|
| **Kind** | New pure-stdlib Python 3 script in `extensions/workforce/extension/scripts/` |
| **Inputs** | A `specs/NNN-feature/` directory path |
| **Behavior** | Delegate to `validate-{profile,categorization,skill}.py` for their artifacts (FR-008); check remaining `docs/contracts/` schemas directly; honor D50 carve-outs; emit per-nonconformance `<artifact> · <rule>` lines |
| **Output** | Deterministic verdict to stdout; exit `0` = conform, non-zero = drift (with named causes) |
| **Invariants** | Single CI command, deterministic, zero third-party deps (FR-007/SC-005); PASSES `specs/000-sample` (FR-006); embeds `_self_test()` |
| **Validation** | Acceptance §US2 1–4; SC-004/005 |

## E3 — `docs/contracts/` schema set (the checker's ruleset)

The closed set E2 enforces. `specs/000-sample` is the executable fixture it must pass (FR-006).

| Contract | Coverage in E2 | Governing artifact |
|----------|----------------|--------------------|
| `artifact-layout.md` | **direct** — required-file presence + layout paths | the feature dir tree |
| `profile-schema.md` | **delegate** → `validate-profile.py` (007/I-27) | `profile.yaml` |
| `taxonomy.md` | **delegate** → `validate-categorization.py` | `categorization.md` |
| `skill-module.md` | **delegate** → `validate-skill.py` | generated skills |
| `decision-record.md` | **direct** — required sections/frontmatter | `council/decision-record.md` |
| `completion-report.md` | **direct** — status enum + ordered core sections | `completion-report.md` |
| `testing-doc.md` | **direct** — SC/FR mapping shape | `testing.md` |
| `trace-schema.md` | **direct** — every field present, per line | `traces.jsonl` |
| `agent-library-schema.md` | **direct** — roster shape | `agents/assignment.md` |

## E4 — git-ext manual-fallback block + divergence guard · US3/I-23

| Aspect | Detail |
|--------|--------|
| **Kind** | Edit to `print_manual_block()` (`extensions/git/install.sh`) + generalized grep in `extensions/git/test/run.sh` |
| **Rule** | Manual block MUST declare 100% of `extension.yml`-registered hooks — including the `after_complete`/`after_testing` commit seams (currently missing) |
| **Guard invariant** | Static check FAILS iff a manifest hook is absent from the manual block (FR-011) — a guard that passes on real divergence is not a guard (Edge) |
| **Validation** | Acceptance §US3-1; SC-006 |

## E5 — augment hook-command parser · US3/I-26

| Aspect | Detail |
|--------|--------|
| **Kind** | Edit to `parse_hook_commands()` (`augment_merge.py`), staying line-based/PyYAML-free |
| **Rule** | Strip a whitespace-preceded trailing inline comment (` # …`) before minting the command-node id; `dequote()` and its other callers unaffected |
| **Input variants** | `#x`, `  #  x`, tab-separated — all strip cleanly (Edge) |
| **Validation** | Acceptance §US3-2; SC-007; committed fixture case |

## E6 — council round provenance · US3/I-29

| Aspect | Detail |
|--------|--------|
| **Kind** | Additive metadata line in `suggestions.md` (via `speckit-council`) and `decision-record.md` §5 Metadata (via `speckit-council-triage`) |
| **New field** | `Council apparatus: extensions/council/ @ <git rev-parse HEAD -- extensions/council/>` alongside existing plan + deck SHAs |
| **Dirty-tree rule** | When `extensions/council/` has uncommitted edits, note/flag the dirty tree so the sha's completeness is honest (Edge) |
| **Invariant** | Additive only — **no gate-semantics change** (FR-015) |
| **Validation** | Acceptance §US3-3; SC-008 |

## E7 — implement-parallel trace writer · US3/I-31

| Aspect | Detail |
|--------|--------|
| **Kind** | Rule added to `speckit-implement-parallel/SKILL.md` trace-writing step |
| **Rule** | A task whose **sole** output is gitignored/untracked writes `artifact: null` — never the ignored path (probe tracked-state via `git`) |
| **Relationship** | Root-cause generalization of `006`'s SC-005 (one-off → guard) |
| **Invariant** | `trace-schema.md`-compliant — a *value* change, no field added/removed |
| **Validation** | Acceptance §US3-4; SC-009 |

## E8 — `docs/90` close-out ledger · FR-016 (all six)

| Aspect | Detail |
|--------|--------|
| **Kind** | Status update to the six I-rows (I-32, I-11, I-23, I-26, I-29, I-31) in `docs/90-DECISIONS-AND-IDEAS.md`, same session as close |
| **Invariant** | Log discipline (constitution) — leaves the repo one bounded step from the D73 visibility flip; no gate-semantics change across the feature (SC-010) |
| **Collision note** | Single shared append target — serialize the close-out (see `graphify-context.md` collision watch) |

## Cross-entity invariants

- **FR-015 (gate-semantics-neutral)** holds across E1–E8: no entity changes who signs or what the council/workforce gates run.
- **Zero third-party deps** across E1, E2, E4, E5 — bash + Python-3-stdlib only (closed contracts).
- **Both-branch fixture discipline** applies to E2 (conformant + injected violations), E4 (guard fails on divergence), E5 (whitespace variants) per FR-009/golden-fixture rule.
