# Completion Report — 002-speckit-ext-git (`speckit-ext-git`)

> The `complete`-phase artifact for the M2 dogfood build. Format: dev-orchestrator completion report
> (`speckit-implement-parallel`) + milestone-close context. **No trace is written for this phase** — the
> git extension is mechanical git and its build sessions are non-council bootstrap phases (D46/D35); the
> only live traces of `002` are its **council** round (M1's exit test, `council_spend` 5,249,858 tok).

## Implementation Complete — speckit-ext-git

**Waves run: 14** (widest parallel wave: **4** agents — Wave 6). **Roster:** Sonnet implementation agents (width-4 as approved at the workforce gate, **zero elevated grants**) for the new-file/skill tasks; orchestrator glue for the shared-registry, spike, doc-reconciliation, and test/validation work. Committed at **every** wave boundary (`e2533a1` … `b7bd56f`), commit-before-`[X]` and by-hand gate-freshness at each wave (workforce-gate note 3 — the last manual performance of the rituals this feature automates).

### Completed (23 / 23)

| Wave | Tasks | Outcome |
|---|---|---|
| 1 | T001 | `extensions/git/` skeleton (glue) |
| 2 | T002–T004 | `git-config.yml`, 4 command stubs, 2 READMEs (3 Sonnet) |
| 3 | T005 | `extension.yml` manifest, 9 hooks `optional:false` (subagent stalled on infra watchdog → hand-authored) |
| 4 | T006 | **`install.sh` hook-merge — the budgeted S15 task** (glue; 6/6 scratch assertions, S07 order, idempotent) |
| 5 | T007 | `uninstall.sh` deregister-first S26a (glue; install→uninstall round-trip **byte-identical**, FR-014) |
| 6 | T008, T011, T015, T016 | `branch.sh` (flock+mkdir-fallback, S13), `sha.sh`, stop-on-nonzero (S02), `cleanup.sh` (4 Sonnet) |
| 7 | T009, T012, T017 | `commit.sh` (self-heal S12, scoped-staging S11), `gates.sh` (fail-closed S10), cleanup skill (3 Sonnet) |
| 8 | T013, T014 | `verify-gate.sh` (wt-aware S05), `on-council-approve.sh` (2 Sonnet) — **US3 integration smoke SC-004 green** |
| 9 | T010 | `implement-parallel` per-wave commit-before-`[X]` (S06) + gate re-verify (S23) (1 Sonnet) |
| 10 | T018, T019 | **wave-worktree spike → ABANDON** (D54); `graphify-context.md` reconciled (glue) |
| 11 | T020 | stale `before_specify` assertions → `after_specify` (S16, glue) |
| 12 | T021 | `test/run.sh` CI harness (glue; **15/15**) + **reinstall-survival fix** (see Key results) |
| 13 | T022 | `before_specify` drift lint (S29/D50, glue) |
| 14 | T023 | quickstart SC validation — **15/15 existence proofs** (glue) |

### Partial / Degraded
None. Two items handled mid-run without residual debt: T005's subagent **stalled** on an infra watchdog (600s) → authored by the orchestrator (clean tree; **Finding-5** honesty check below); T010's edit needed relocation to survive reinstall (**Finding-1**, fixed).

### Failed
None.

### Integration status
- **Installer**: install (scratch) merges 9 git hooks append-only, `verify-gate` ahead of graphify on both `before_*` (S07); install→uninstall round-trip byte-identical (FR-014). ✅
- **Primitive chain** (US3) end-to-end: `gates.sh`→`verify-gate.sh`→`sha.sh` compose — fresh verifies, uncommitted edit blocks (S05), SHA-mismatch blocks, missing binding fails closed (S10). ✅
- **Reinstall-survival regression** green: T010's per-wave edit survives a graphify reinstall (now in graphify **source**); T014's `after_council_approve` hook survives a council reinstall (git-ext-owned). ✅
- **Principle I** held: `on-council-approve.sh` writes only `gates.yml` — `decision-record.md` checksum unchanged (**Finding-2**). ✅
- **Zero AI** by construction (SC-007): no `extensions/git/**` path invokes a model/Agent or writes `traces.jsonl`. ✅
- All 6 primitive scripts + install/uninstall + `test/run.sh` pass `sh -n`/`dash -n`/`bash -n`. ✅

### Key results
- **SC-001–008 all proven** as existence proofs (S29), 15/15 (`implement.log.md` §Quickstart validation). SC-004 shows the stale hard-block on **both** a committed and an uncommitted edit (S05).
- **The reinstall-survival test earned its keep (Finding-1).** graphify *ships* `speckit-implement-parallel`, so T010's per-wave edit — applied only to the installed copy — was silently wiped by a graphify reinstall. The regression caught it; fixed by relocating the edit into graphify's **source**. Exactly the S04 hazard R1-S17 exists for.
- **Wave-worktree spike → ABANDON (D54).** Worktree-per-wave adds cost on disjoint waves (all `[P]` allows) and *reintroduces* the shared-file merge conflict the DAG serialization prevents by construction; `002`'s own 9 collision-free waves are the existence proof. Firewall held (SC-008). Resolves I-4.

## Milestone-close context

### M2 "Done when" (docs/05) — status
docs/05's exit criterion — *"a full pipeline run happens on an auto-created branch with phase-tagged commits"* — is **met**: `002` itself ran specify→plan→council→tasks→analyze→categorize→gate→implement on the `002-speckit-ext-git` branch with a phase-tagged commit at every boundary (the trail this report closes), and SC-001/002/003 are validated existence proofs. The extension's **first live act** (installing on `main` and running `/speckit-git-cleanup` to cut `complete/002-speckit-ext-git`) is the close-out step that retires the manual branch ritual `002` exercised one last time.

### Findings adjudicated (owner, M2 close)
- **Finding-2 → D55 (upheld).** FR-008's "the gate section carries a one-line reference to `gates.yml`" is satisfied by **well-known-path convention** (`specs/NNN/gates.yml`), not a git-ext co-write. **Ownership is inverted:** writing the pointer into the `## Human Gate` section is the **gate command's** job (it owns `decision-record.md`) — `speckit-council-approve` adds it on its **next touch** (the M3 update to `001`'s council flow), keeping principle I clean. The git ext writes only its own `gates.yml`.
- **Finding-1 → I-14 (booked).** A **cross-extension seam convention**: prefer **hook points over source edits** for cross-extension coupling. The `after_council_approve` hook is the model; the `implement-parallel` per-wave call is the exception (no per-wave hook vocabulary) and is reinstall-surviving only because it lives in graphify's source. The convention must be **established before M3 wires in** further coupling.
- **D54 (spike-abandon).** Rationale recorded above and in `implement.log.md`; a null result is a success (D25) — the spike's deliverable is the knowledge that worktree-per-wave is the wrong isolation layer.
- **Finding-5 (trace honesty check, T005).** The stalled subagent was replaced by an orchestrator hand-authoring — this leaves **no phantom trace and no model artifact**: git-ext build phases write no `traces.jsonl` (D46), and the extension's runtime remains zero-AI (SC-007). The stall is an infra event, not a coverage or trace gap.

### Deferred / carried (each with owning milestone)
- **FR-010 auto-mode SHA-record trigger** — the `after_council_approve` action is signer-agnostic, but the **auto-mode auto-trigger wiring** (no human `approve` event) is booked for **M3** (with the assigner/auto-gate work).
- **D50 conformance checker build** — still **open** (I-11); the `before_specify` drift lint is homed in `test/run.sh` as the v1 vehicle meanwhile (S29) and relocates into the checker when it ships.
- **Mechanical `HookExecutor`** — enforcement is prose-level in v1; the code-enforced dispatcher is **M6** (D53).
- **M3/M4 phase-commit paths** — `categorize` / `agent-assign` commit hooks await their skills (**M3**); the `complete`-phase commit path awaits **M4**. FR-003 coverage map in `tasks.md` §Notes.

### Next steps
1. **Merge `002` → `main`** by hand (ff, D52) — the final manual performance.
2. **Install on `main`** (`bash extensions/git/install.sh .`) — first live install, committed as repo infrastructure (M1 phase-0 precedent).
3. **Run `/speckit-git-cleanup` for `002`** — the extension's first live act; cuts `complete/002-speckit-ext-git`, the first annotated anchor (D52).
4. **M3** (`speckit-ext-categorize` + agent creator) starts in a fresh session — carrying D55, I-14, FR-010 auto-trigger, and the M3/M4 commit paths.

## Decisions & log
D55 (Finding-2) and I-14 (Finding-1) recorded at close; D54 (spike) stands; per-wave session-log rows and the M2-closed mark land in `docs/90` / `docs/05` at close-out. This report is the `complete` phase output; `testing.md` (M4) is out of M2 scope.
