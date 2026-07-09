# speckit-ext-git — Per-Feature Git Lifecycle

**Turn the per-feature git lifecycle M0/M1 ran by hand into something the pipeline does for
you — mechanically, with zero AI.**

Spec Kit's phases produce artifacts, but nothing commits them, names a branch, or remembers
which approved SHA a gate signed off on. `speckit-ext-git` closes that gap: **branch birth**
(named from the spec ID, the moment `/speckit-specify` finishes), **phase-tagged commits** at
every phase boundary, **gate↔SHA binding** so a council or workforce approval is checked against
the *current* artifact rather than just trusted — with a **hard-block on a stale approval** —
and **completion cleanup** that integrates the branch, drops an immutable tag anchor, and
retires the ref while preserving the whole phase trail. **Mechanical git only — zero AI**: no
model calls, no `traces.jsonl` records (FR-007). Per D25.

Packaged like `extensions/graphify/` — a **hook-registering** installer (not command-only, like
`extensions/council/`): the payload lands at `.specify/extensions/git/`, its hooks are merged
into `.specify/extensions.yml`, and the one human-facing command, `/speckit-git-cleanup`, is
installed to `.claude/skills/`.

```text
/speckit-specify        after_specify                    ensure branch <spec-id>, commit spec(<id>): …
/speckit-clarify        after_clarify                    commit spec(<id>): clarify
/speckit-plan           after_plan                       commit plan(<id>): …
/speckit-analyze        after_analyze                    commit analyze(<id>): …
council approve         after_council_approve             gates.yml ← plan.md @ <sha>

/speckit-tasks          before_tasks                      verify-gate council — stale ⇒ HARD-BLOCK
                        after_tasks                       commit tasks(<id>): …
workforce gate          (gate command, no hook slot)      gates.yml ← tasks.md @ <sha>, assignment.md @ <sha>

/speckit-implement*     before_implement (+ each wave)    verify-gate workforce — stale ⇒ HARD-BLOCK
                        per wave                          commit impl(<id>) wave K/N: …
                        after_implement                   commit impl(<id>): …  (backstop)

/speckit-git-cleanup    human-invoked, never automatic    integrate → tag complete/<spec-id> → delete branch
```

---

## What it installs

| Into your repo | What it is |
| --- | --- |
| `.specify/extensions/git/` | The extension payload — `extension.yml` (declares the hooks below plus the `commit`/`sha`/`verify-gate`/`cleanup` primitives), `git-config.yml`, `commands/`, `scripts/`. |
| `.specify/extensions.yml` | Gets git's hook entries **merged in**, append-only — any hooks graphify (or another extension) already registered are left exactly as they were. |
| `.claude/skills/speckit-git-cleanup/` | The one human-facing skill: `/speckit-git-cleanup`. |

The stock `speckit-*` skills and `.specify/scripts/*` are never edited — only extended via hooks.

---

## Hooks (registered `optional: false`)

| Hook | Fires | Action |
| --- | --- | --- |
| `after_specify` | end of `/speckit-specify` | ensure the feature branch exists — create it from the spec ID in `feature.json` if absent — then commit `spec(<id>): …` |
| `after_clarify` | end of `/speckit-clarify` | commit `spec(<id>): clarify` |
| `after_plan` | end of `/speckit-plan` | commit `plan(<id>): …` |
| `after_analyze` | end of `/speckit-analyze` | commit `analyze(<id>): …` |
| `after_council_approve` | council gate recorded | write `plan.md @ <sha>` into `gates.yml`; `## Human Gate` carries a one-line reference |
| `before_tasks` | start of `/speckit-tasks` | verify the council gate binding is fresh — **hard-block if stale** |
| `after_tasks` | end of `/speckit-tasks` | commit `tasks(<id>): …` |
| `before_implement` | start of `/speckit-implement*`, and again at each wave | verify the workforce gate binding is fresh — **hard-block if stale** |
| `after_implement` | end of `/speckit-implement*` | commit `impl(<id>): …` — backstops the phase boundary |

Every commit hook is a no-op on a clean tree (FR-004); none of them ever calls a model.

**A note on enforcement.** `optional: false` is what marks a hook auto-invoked and hard-block
rather than merely announced (`optional: true`, graphify's style) — but v1 ships **no standalone
`HookExecutor`**. Enforcement is *prose-level*: the invoking phase's own skill (`speckit-tasks`,
`speckit-implement`, …) carries the pre-check clause that reads `extensions.yml`, runs the hook,
and stops on a non-zero exit. A mechanical, code-enforced dispatcher is deferred to M6 (D53).

---

## Primitives

Called by the hooks above, and directly by `speckit-council-approve` / `speckit-implement-parallel`
for the two boundaries with no stock hook slot:

| Primitive | In | Does | Out |
| --- | --- | --- | --- |
| `speckit.git.commit <phase> <summary>` | a phase label + summary (wave form: `impl "wave K/N …"`) | stages only `specs/NNN-feature/**` and the task's declared outputs — **never a repo-wide `git add -A`** — then commits with the phase-tagged grammar; no-op if the tree is clean | the new commit SHA on stdout (empty if no-op) |
| `speckit.git.sha <artifact-path>` | a repo-relative artifact path | prints the SHA of the HEAD commit that last touched it — read-only | a git SHA |
| `speckit.git.verify-gate <gate>` | `gate ∈ {council, workforce}` | compares `gates.yml`'s recorded `<artifact> @ <sha>` against the artifact's current SHA — working-tree-aware (a dirty approved file counts as stale) and fail-closed on anything unparseable | exit `0` (fresh), or non-zero + a human-readable mismatch on stderr (stale) |

None of the three write a `traces.jsonl` record.

---

## Human command

### `/speckit-git-cleanup`

Completion cleanup — always **human-invoked**, never automatic (retiring a branch is
consequential):

1. **Integrate** the feature branch into `base_branch` — fast-forward permitted; `git merge --no-ff`
   only if the base diverged.
2. **Tag** the integration commit `complete/<spec-id>` (annotated, mandatory) — the completion
   anchor, enumerable via `git for-each-ref refs/tags/complete/*`, independent of merge topology.
3. **Delete** the feature branch ref.

On a textual conflict: abort (`git merge --abort`) and surface it — never auto-resolve, never
delete an unmerged branch. Idempotent: re-running after a completed cleanup is a no-op (branch
already gone, tag already present).

---

## Install

```bash
bash extensions/git/install.sh .
```

Copies `extension/` → `.specify/extensions/git/`, installs `/speckit-git-cleanup` to
`.claude/skills/`, and **merges** git's hook entries into `.specify/extensions.yml` — append-only,
so any hooks another extension (e.g. graphify) already registered are left untouched. Idempotent
— re-run any time to update.

## Uninstall

```bash
bash extensions/git/uninstall.sh .
```

Deregisters git's hook entries from `.specify/extensions.yml` **first**, then removes the
installed payload and skill (FR-014) — and nothing else. No `specs/` artifact, no other
extension's hooks, no branch or tag is touched. If deregistration fails, uninstall fails hard
rather than leave a dangling `optional: false` hook pointing at scripts that no longer exist.

---

## Layout

```text
extensions/git/
├── install.sh                     # idempotent; merges git's hooks into .specify/extensions.yml
├── uninstall.sh                   # deregisters hooks first, then removes payload + skill
├── README.md                      # this file
├── extension/
│   ├── extension.yml               # id: git — declares hooks + the commit/sha/verify-gate/cleanup primitives
│   ├── README.md                   # payload-dir README
│   ├── git-config.yml              # base_branch, commit-message grammar, branch-name pattern, tag/merge policy
│   ├── commands/                   # provenance stubs (dots→hyphens on install)
│   │   ├── speckit.git.commit.md
│   │   ├── speckit.git.sha.md
│   │   ├── speckit.git.verify-gate.md
│   │   └── speckit.git.cleanup.md
│   └── scripts/                    # the actual mechanical git (POSIX sh)
│       ├── branch.sh               # ensure-branch-from-spec-id (idempotent)
│       ├── commit.sh               # phase-tagged commit; no-op if clean (FR-004/006)
│       ├── sha.sh                  # current SHA of an artifact
│       ├── gates.sh                # write/read specs/NNN/gates.yml (the gate↔SHA bindings)
│       ├── verify-gate.sh          # recorded-vs-current SHA compare (FR-009)
│       └── cleanup.sh              # integrate + complete/<spec-id> tag + branch delete (FR-011)
├── skills/
│   └── speckit-git-cleanup/SKILL.md   # the one human command (installed to .claude/skills/)
└── test/
    └── run.sh                       # unit tests + the reinstall-survival regression
```

---

## Zero AI

`git_ext_spend = 0`, always (SC-007). No hook or primitive ever calls a model — no Claude API, no
subagent, no `ANTHROPIC_API_KEY` — and none writes a `traces.jsonl` record: this extension is
mechanical git, not an AI session, exactly like a `branch`/gate row that runs no session and so
leaves no trace. It commits artifacts that *other* phases wrote and supplies SHA values that the
*gate command* records into its own gate section; the one artifact it owns outright is
`specs/NNN/gates.yml` (the gate↔SHA bindings) — it never co-writes into an artifact another phase
owns. Per D25.

---

## Requirements

- **Git ≥ 2.20**, locally — no remote, push, or PR operations in v1.
- A Spec Kit **`.specify/`** directory with `feature.json` (the spec-ID resolver, D45) — the git
  extension reads the spec ID from it; it never derives one itself.
- Composes with **graphify** (`before_*` hooks) and **council** (command-invoked) if installed —
  no conflict: at the shared `before_tasks` / `before_implement` keys, the installer orders git's
  `verify-gate` ahead of graphify's context generation, so a hard-block fires before any heavy
  regeneration runs.

---

## License

MIT — see [`LICENSE`](../../LICENSE).
