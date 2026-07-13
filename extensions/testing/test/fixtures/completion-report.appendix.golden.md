---
feature: 004-testing-completion    # spec ID, string
phase: complete                    # literal -- always "complete"
status: success                    # success | partial | failed
---

## Implementation Complete — speckit-ext-testing

**Waves run: 6** (widest parallel wave: **6** subagents — Wave 4). **Roster:** Sonnet
implementation subagents for the authoring/logic/test tasks; orchestrator glue for the
pre-flight git-ext bundle and the tree scaffold.

### Completed (19/19)

| Wave | Tasks | Outcome |
|---|---|---|
| 0 (pre-flight) | T003-T008 | I-17 checkbox-delta fix + testing commit-seam, bundled, single reinstall (46/0) |
| 1 | T001 | `extensions/testing/` tree scaffold |
| 2 | T002 | manifest + config |
| 3 | T009, T012, T017 | the two contracts + artifact-layout ownership rows |
| 4 | T010, T011, T013, T014, T015, T016 | commands, templates, the SC/FR coverage validator + goldens + round-trip |
| 5 | T018 | install + full harness green |
| 6 | T019 | quickstart SC-map validation |

### Partial/Degraded

None.

### Failed

None.

### Integration status

- The `complete`/`testing` phase commits fire from git-ext's own `after_complete`/`after_testing`
  hooks and survive a git-ext reinstall (`extensions/git/test/run.sh` §7).
- `completion-report.md` and `testing.md` each validate against their `docs/contracts/` schema
  (`extensions/testing/test/run.sh`).
- The I-17 workforce-freshness fix lands pre-wave; waves 2+ pass `verify-gate workforce` with
  zero hand assistance (`extensions/git/test/run.sh` §6).

### Key results

- All 19 tasks landed; the coverage validator fails on any SC/FR gap (code-enforced, not
  prompt-enforced) and the install/uninstall round-trip is byte-identical.

<!-- Everything below this line is the OPTIONAL appendix — outside the validated core. A
     generic, non-dogfood feature omits it entirely; this contract validates identically with
     or without it present (SC-005). -->

## Milestone-close context

### M4 "Done when" (docs/05) — status

Met: M4's own run ends with a validated `completion-report.md` and a validated `testing.md`,
each phase-tagged-committed (SC-009).

### Findings adjudicated

- I-17 ruled in-scope (D68) and fixed pre-wave, not grandfathered — the general
  `[X]`-marking-stales-the-binding defect no longer bites future features.

### Deferred / carried

- The M5 D19 `phase.completed` push itself (this feature only makes the artifact body conform).

### Next steps

1. `/speckit-git-cleanup` for `004-testing-completion`.
2. M5 (platform layer) starts fresh.

## Decisions & log

D68 (I-17 ruled in-scope), D69 (pre-flight sequencing), D71 (roster gap-seeding) recorded across
triage/gate/implement; the M4-CLOSED mark lands in `docs/90` / `docs/05` at close-out.
