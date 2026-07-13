# arm2-survivors

S01 negative-path fixture for arm 2's stale-survivor guard (plan.md "Arm 2", case (d);
contracts/commands.md `refresh.sh`) — the guard exercised on the branch that FAILS, not
only the 0-survivor path already covered by `arm2-equiv` (T012, case c). `input/graph.json`
models `demo/changed.sh` (a file node + functions `alpha/beta/gamma/delta`) and an
unrelated, untouched `demo/stable.sh` (a file node + `watcher()`, which calls `gamma()`
across files); `input/fresh-extraction.json` is the ground-truth fresh extraction of
`demo/changed.sh` after an edit that keeps `alpha`, drops `beta`/`gamma`/`delta`, and adds
a new `epsilon` — so the scenario manufactures **exactly 3 stale survivors** (nodes
attributed to the changed file that persist absent from its fresh extraction — the M3
86-node incident, in miniature). `cmd.sh` asserts both branches: detection (refresh.sh's
own contracted `stale_survivors: 3`) and recovery (an independent follow-up read of the
post-refresh `graphify-out/graph.json` — never just refresh.sh's self-report — confirming
none of the 3 manufactured ids remain, printed as `survivors_after_recovery: 0`; it fails
loudly instead, naming the offending ids, if recovery either leaves a survivor behind or
over-reaches into `demo/stable.sh`'s untouched nodes, the S02 guarantee that recovery is a
targeted, scoped re-extract, never a whole-corpus sweep, for a bounded change). RED today
by design (TDD): `refresh.sh` is T016 (a later wave) and does not exist yet, so invoking it
fails naturally (no such file) rather than any part of this fixture being malformed;
`cmd.sh`'s header comment documents the exact test-seam contract — invocation shape, the
three input files, and why `fresh-extraction.json` is consumed directly rather than via a
live AST re-extraction — that T016 must satisfy to turn this fixture green.
