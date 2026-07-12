# Implement Log — 004-testing-completion (`/speckit-implement-parallel`)

> Append-only wave ledger. One line per wave; the pre-flight is recorded above the wave loop
> because per D69 it is **not a wave** (machinery that gates the waves is never itself a wave).
> Orchestrator: main thread (Opus, xhigh). Dispatches: Sonnet assembled agents per the approved
> roster (`agents/assignment.md`, workforce gate `5a7f705`, bound in `gates.yml`).

## Pre-flight (D69/R1-S01) — the bundled git-ext change, provisioned BEFORE Wave 1

The pre-flight is a serial unit (T003→T004→T005→T006→T007→T008): one git-ext source change
(verify-gate.sh checkbox-delta + commit.sh `testing` enum + after_testing/after_complete hooks)
→ one reinstall → one survival regression. `implement-parallel` **refuses to enter Wave 1 until
T008 reports both survival regressions green** (SC-010 provisioning).

- `2026-07-12T19:47Z` | before_implement verify-gate workforce | tasks.md @ 9601bcd (pristine, just-bound) + agents/assignment.md @ 5a7f705 | **exit 0 (PASS)** — R1-S11 non-circularity first-firing: the gate passes on a pristine tasks.md PRE-FIX (exact-match fast path, no audit line). Wave 1's own `[X]`-mark is the sole hazard; this window is safe.
- `2026-07-12T19:47Z` | **pre-flight gate CLOSED → Wave 1 REFUSED** | reason: T008 not done (the bundled git-ext change is not yet built/reinstalled/survival-verified). This refusal is the first half of the SC-010 evidence pair (refuse-then-release); the second half is the wave-2+ freshness checks passing unassisted after the fix goes live.
- `2026-07-12T20:03Z` | pre-flight T003 (agt_security) | verify-gate.sh checkbox-delta classifier authored + **orchestrator-verified 13/13 adversarial cases** (forward-flip PASS+audit; reverse-flip `[X]`→`[ ]` BLOCK — R1-S18; unpaired insert/delete BLOCK — R1-S04; edited-suffix BLOCK; scope guard holds — dirty assignment.md/plan.md still BLOCK via untouched strict path). Direction asymmetry confirmed load-bearing.
- `2026-07-12T20:05Z` | pre-flight T004 (agt_devtools_cli) | commit.sh phase enum `+testing` (enum L90 + die text + header) — `complete` intact, `sh -n` clean.
- `2026-07-12T20:05Z` | pre-flight T005 (agt_devtools_cli) | extension.yml `+after_complete(phase:complete)` `+after_testing(phase:testing)`, optional:false — YAML valid, siblings intact (12 hooks).
- `2026-07-12T20:20Z` | pre-flight T006 (agt_qa_automation) | run.sh §6 I-17 checkbox-delta survival regression (7 cases + reinstall×2 survival). Suite 37→ green.
- `2026-07-12T20:27Z` | pre-flight T007 (agt_qa_automation) | run.sh §7 SC-008 seam survival regression (`complete(id)`/`testing(id)` commits + hook routing + reinstall×2 survival). Suite → **46 passed, 0 failed**.
- `2026-07-12T20:31Z` | pre-flight T008 (agt_qa_automation) | **single bundled reinstall** `bash extensions/git/install.sh .` → deployed all three source edits into `.specify/extensions/git/` (byte-identical), auto-merged `after_complete`/`after_testing` into the installed registry (append-only, idempotent on 2nd install), suite **46/0**, pristine `verify-gate workforce` exit 0 silent. **Both survival regressions green.**
- `2026-07-12T20:33Z` | **pre-flight gate OPEN → Wave 1 RELEASED** | orchestrator-independently reconfirmed: suite 46/0, deploy byte-identical, checkbox-delta branch live in installed copy, tasks.md still pristine @ 9601bcd. This release is the **second half of the SC-010 refuse-then-release evidence pair**. Note (R1-S11): tasks.md is intentionally kept pristine THROUGH the pre-flight — the pre-flight commit carries git-ext source + installed tree + this log only, NO `[X]` marks — so Wave 1's gate check still sees the exact-match fast path, and the FIRST checkbox-delta PASS lands at Wave 2's check (after Wave 1's own `[X]`-mark, the "sole hazard").

## Wave loop (the testing-extension build)

