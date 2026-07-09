# Per-Feature Git Lifecycle Extension

Automates the git side of the Spec Kit pipeline — branch birth, phase-tagged commits, gate↔SHA
bindings, and the completion tag anchor — as **mechanical git, zero AI**: no model calls, no
`traces.jsonl` records (FR-007, D25). See `../README.md` for the full picture; this file covers
what lives in this payload directory.

## Provides

Four primitives (`extension.yml` declares them; `commands/` holds one provenance-stub markdown
file per primitive — dots become hyphens on install, Spec Kit's usual naming convention — and
`scripts/` holds the actual POSIX `sh` each stub documents):

- `speckit.git.commit <phase> <summary>` — the phase-tagged commit; no-op on a clean tree.
- `speckit.git.sha <artifact-path>` — read-only: the SHA of the commit that last touched an artifact.
- `speckit.git.verify-gate <gate>` — `gate ∈ {council, workforce}`; compares `gates.yml`'s
  recorded binding against the current SHA, working-tree-aware and fail-closed.
- `speckit.git.cleanup` — the one **human-facing** command, also installed as a skill to
  `.claude/skills/speckit-git-cleanup/`: integrate → tag `complete/<spec-id>` → delete branch.

Only `cleanup` is meant to be invoked directly by a person; `commit`/`sha`/`verify-gate` are
called by the hooks below and by `speckit-council-approve` / `speckit-implement-parallel` at the
two boundaries with no stock hook slot.

## Hooks (registered in `.specify/extensions.yml`)

| Hook | Action |
| --- | --- |
| `after_specify` | ensure the feature branch (create from `feature.json`'s spec ID if absent), commit `spec(<id>): …` |
| `after_clarify` | commit `spec(<id>): clarify` |
| `after_plan` | commit `plan(<id>): …` |
| `after_analyze` | commit `analyze(<id>): …` |
| `after_council_approve` | write `plan.md @ <sha>` into `gates.yml` |
| `before_tasks` | verify-gate `council` — hard-block if stale |
| `after_tasks` | commit `tasks(<id>): …` |
| `before_implement` | verify-gate `workforce` — hard-block if stale (re-checked every wave) |
| `after_implement` | commit `impl(<id>): …` (backstop) |

All registered `optional: false`. In v1 that's a registration fact, not a mechanical guarantee:
enforcement is prose-level — the invoking phase's own skill stops on a non-zero hook exit; a
code-enforced `HookExecutor` is deferred to M6 (D53).

## Files here

- `extension.yml` — the extension manifest: id `git`, the hooks table above, the four primitives.
- `git-config.yml` — `base_branch`, the commit-message grammar, the branch-name pattern (incl.
  timestamp-mode), and the tag/merge policy (`ff` permitted; mandatory `complete/<spec-id>` tag).
- `commands/` — one provenance-stub `.md` per primitive (`speckit.git.commit.md`,
  `speckit.git.sha.md`, `speckit.git.verify-gate.md`, `speckit.git.cleanup.md`).
- `scripts/` — the mechanical git itself, POSIX `sh`: `branch.sh`, `commit.sh`, `sha.sh`,
  `gates.sh` (reads/writes `specs/NNN/gates.yml`), `verify-gate.sh`, `cleanup.sh`.

## Requirements

- Git ≥ 2.20. Local only — no remote/push/PR in v1.
- `.specify/feature.json` present (the spec-ID resolver, D45) — this extension reads the spec ID
  from it, never derives one itself.
