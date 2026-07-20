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
