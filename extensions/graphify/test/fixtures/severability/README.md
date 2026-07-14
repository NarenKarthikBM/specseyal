# severability

Detached-configuration fixture for **S12 — detachability follows fallback, not
importance** (plan.md "Detach order (D74-2)", T034, 005-graphify-context). plan.md states
the severability picture as a 1-vs-3 asymmetry (S15): only arm 1 (`.sh`/`.yml` coverage —
`augment.sh`, `augment_merge.py`, `explain-guard.sh`) has a working fallback and is
genuinely detachable, degrading gracefully to the labeled-assertion/file-disjointness path
every feature 002-004 already shipped on honestly; arms 2 (`refresh.sh`/`freshness.sh`), 3
(`provenance.sh` + the graphify-context generator), and 4 (council's `ceiling-check.sh`)
are core — "never detach", because none has a fallback — so S12 demands the claim be
"realized as a test", not left as rationale-only prose. `cmd.sh` assembles a real
arm-1-detached scripts directory in a `mktemp` scratch by **copying** only the arm-2/3
scripts (`refresh.sh`, `refresh_merge.py`, `freshness.sh`, `provenance.sh`) out of
`extensions/graphify/extension/scripts/` — never the three arm-1 files, and it asserts
their absence as a defense-in-depth check before proceeding — then exercises that dir for
real: **arm 2** runs `refresh.sh` against a manufactured refresh scenario (a changed
`demo/util.sh` whose sole function is renamed, plus an untouched `demo/other.sh`) and
asserts it exits `0`, reports `stale_survivors: 0`, and — the genuine-absence proof, not
merely "it happened not to crash" — that refresh.sh's own stderr names the
`augment.sh absent (arm 1 detached)` branch it took, per the note already documented at
the end of `extensions/graphify/extension/scripts/refresh.sh`; **arm 3** then runs
`provenance.sh generation-id` on that same now-refreshed graph (a small 2-then-3
composition, since `provenance.sh` has no sibling-script dependency to sever in the first
place) and asserts the result matches `sha256:<64 lowercase hex>` exactly; **arm 4** runs
`extensions/council/extension/scripts/ceiling-check.sh standard 8` straight from the real
repo, with no scratch assembly at all, because it lives in an entirely separate extension
and has never depended on anything under `extensions/graphify/` — asserting the quiet
`ceiling_hit: false` path (`tiers.standard.query_ceiling` is 15; 8 stays under it). Each
arm prints its own `armN_without_arm1: ok` line only after its assertions pass; any
failure prints a named diagnostic to stderr and exits before printing that line, so a
regression here fails loudly and says which arm and which check broke, not just that
`expected.txt` stopped matching. All three merge-correctness and ceiling-math claims
themselves are already independently proven by `arm2-equiv`/`arm2-survivors` (T012/T013)
and `arm4-ceiling`/`arm4-noceiling` (T024/T025) respectively — this fixture's only job is
proving arm 1's absence changes none of it.
