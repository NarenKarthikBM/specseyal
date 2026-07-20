# Implement Log — 008-pre-public-maintenance

> One line per wave, append-only. Prior lines are never edited.
> Written by `/speckit-implement-parallel`.

2026-07-20T08:47:06Z | wave 1 | tasks: T001 | agents: 1 | outcome: success

---

## Pre-change baseline (T001, wave 1)

Recorded so T012's R1-S11 "witness the guard FAIL" is distinguishable from a pre-existing
failure, and so T018 can confirm a green final result against a known prior state.

| harness | exit | passed | failed |
|---|---|---|---|
| `extensions/git/test/run.sh` | 0 | 61 | 0 |
| `extensions/graphify/test/run.sh` | 0 | 28 | 0 |
| `extensions/workforce/test/run.sh` | 0 | 13 | 0 |
| `extensions/testing/test/run.sh` | 0 | 43 | 0 |
| `extensions/deck-render/test/run.sh` | 1 | 92 | 8 |

**OVERALL: not green — 8 pre-existing failures, all confined to `deck-render`.** The four
harnesses this feature actually touches (git, graphify, workforce, testing) are fully green,
so every one of them is a clean "witness FAIL → witness PASS" reference.

### The 8 pre-existing `deck-render` failures

**7 of 8 — `python-pptx` absent on this host.** The suite's own section-0 banner predicts
them (`python-pptx: ABSENT (via python3) -- SC-003-class checks will FAIL loud`). Environmental,
not a code defect:

- `SC-003 fidelity (bidirectional containment + block sequence)`
- `SC-002 derived-render stamp`
- `T7 overflow / determinism (S08)`
- `FR-016 override renders a file`
- `partial-failure exit 2 (render-good / fail-broken / disclose-both)`
- `I-B3 atomic mid-write failure (no partial .pptx + prior good render untouched)`
- `SC-007 staleness detection (FRESH/STALE verdict)`

**1 of 8 — a genuine repo-state defect, NOT fixed by installing `python-pptx`:**

- `SC-005 not in git -- git ls-files tracks 1 .pptx file(s) anywhere in the repo, e.g.
  specs/008-pre-public-maintenance/council/defense-deck/008-defense-deck.pptx -- a rendered
  deck must never be tracked, regardless of path`

  Added on **this** branch by commit `0786e9f` (the council human-gate commit). Out of scope
  for 008 (the path is outside the FR-015 allowlist, and the defect is a council/deck-render
  concern) — carried forward to T017 as a new I-row rather than fixed here. See the wave-2
  scope note below.

---

2026-07-20T08:56:30Z | wave 2 | tasks: T002 | agents: 1 | outcome: success

## Scope note — the FR-015 allowlist carve-out (T002, wave 2)

`tasks.md`'s declared allowlist enumerates 13 **implementation edit sites**. Taken literally,
the guard it specifies was unimplementable: at wave 2 the branch diff already held **30 paths**,
of which only `docs/90-DECISIONS-AND-IDEAS.md` was allowlisted. The other 29 — 27 SDD artifacts
under `specs/008-pre-public-maintenance/` and 2 workforce-persisted skills under
`.claude/skills/` — were committed by the spec/plan/council/tasks/categorize/agents phases
**before implementation began**. A literal guard would have failed on all 29 and hard-blocked
every remaining task on the first wave that ran it.

**Resolution (human-approved, this run):** the guard's allowlist is the **union** of the 13
declared source sites and exactly two pipeline-output prefixes —
`specs/008-pre-public-maintenance/` and `.claude/skills/` — each enumerated and commented in
the source as output-not-source. FR-015 asserts *source* non-interference ("no gate-schema or
gate-semantics file changed"); the pipeline's own artifact writes are not source edits.

**The teeth are retained and were witnessed.** Any path under `extensions/**`, `docs/**`, or
the repo root outside the 13 declared sites still FAILs, and any *other* feature's `specs/`
directory is unexempted. Verified both branches: PASS 14/14 on the clean tree; FAIL naming
`extensions/testing/STRAY.txt` on a deliberately-introduced stray path.

**Known property (not a defect):** `git diff --name-only <merge-base>..HEAD` sees committed
history only, so an *uncommitted* working-tree stray is not caught. This matches `tasks.md`'s
literal specification of the diff command, and is harmless under this run's discipline — every
wave commits before its tasks are marked `[X]`, so by T018 the full branch is committed.

---

2026-07-20T09:20:10Z | wave 3 | tasks: T003, T007, T013, T015 | agents: 4 | outcome: success

## Findings carried to T017 (wave 3)

Two items surfaced by wave-3 agents that belong in the `docs/90` close-out, recorded here so
they are not lost between waves:

1. **`hardening-invariants.md` H3's site description is inaccurate** (surfaced by T013). H3
   names the edit sites as `suggestions.md` "alongside the existing plan/deck SHAs" and
   `decision-record.md` "§5 Metadata". Neither matches the files: `suggestions.md` carries no
   plan/deck SHA lines at all (only `Feature`/`Prepared by`/`Reads`), and `decision-record.md`'s
   `## Metadata` is a cardinality-1 section of five fixed fields per `docs/contracts/
   decision-record.md` §3 that holds no SHAs — the real plan/deck provenance lives in the
   per-round `## Round N` block. T013 placed the apparatus line in `## Round N` beside the
   actual `Deck reviewed:`/`Plan reviewed:` lines, and had the orchestrator post-insert into
   `suggestions.md` rather than edit out-of-scope templates. Additive and contract-clean, but a
   council-approved contract carries a wrong site description that survived the round.

2. **`bootstrap.sh`'s default `--ref` is a forward reference** (surfaced at wave-3 dispatch).
   There are no release tags in this repo — only `complete/<spec-id>` completion tags, latest
   `complete/007-oss-docs`. `bootstrap.sh` is introduced by 008, so it exists in no earlier tag;
   the only correct pinned default is `complete/008-pre-public-maintenance`, minted by this
   feature's own cleanup. Until that tag lands the documented one-command install fails unless
   the user passes `--ref` explicitly. This is a second, independent reason SC-001/002/003
   sign-off is provisional, beyond R1-S06's private-repo reason — T006 must state it in the
   README and T016 cannot validate the default path.

## Orchestrator integration patch (wave 3)

T015's rule said only "before writing a task's record, probe whether the path is tracked",
without pinning the probe relative to the wave commit. Read at the wrong moment every
brand-new file is untracked, so a trace written pre-commit would null out legitimate outputs.
Patched inline (not re-dispatched) with a clause pinning the probe to **after** step 4's
commit, matching this skill's own step 4 → step 5 ordering. Contract H4.1–H4.3 were already
satisfied by the agent's text; this closes a misread, not a contract gap.
