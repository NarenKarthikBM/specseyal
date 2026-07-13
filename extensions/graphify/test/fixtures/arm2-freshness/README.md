# arm2-freshness

Golden fixture for arm 2's staleness guard (T011, 005-graphify-context), proving **(a)
stale-positive** and **(b) stale-negative / no-false-alarm** as the two branches of the *same*
guard rather than two unrelated cases (S18, plan.md: "a check that can only ever fire proves
nothing about its quiet path" — a detector proven only on input that already trips it says
nothing about whether it stays quiet on input that shouldn't). `cmd.sh` builds one throwaway git
repo in a `mktemp` scratch (cleaned up on exit via `trap`; never this repo) with two tracked
source files, a `.gitignore`'d `graphify-out/` (mirrors D45 — the graph artifact is never itself
tracked source), a small valid `graph.json` (schema verified against
`specs/005-graphify-context/graph-baseline.json`: `directed, multigraph, graph, nodes, links,
hyperedges, built_at_commit`; 2 nodes + 1 edge), and a `product.md` carrying the shared-provenance
header (T004, `extensions/graphify/skills/speckit-graphify-context/SKILL.md` "Shared-provenance
header") whose `generation-id` is independently recomputed via that contract's own documented
canonicalization recipe (parse JSON, drop `built_at_commit`, sort keys, compact separators,
SHA-256) and whose `source-fingerprint: git-commit:<sha>` is the repo's real, reachable HEAD
commit. It then forks that repo into two copies via `cp -R` (including `.git`, not a fresh `git
init`, so both copies stay pinned to the identical commit SHA): **(a)** mutates a tracked source
file, uncommitted, without touching `graph.json` — isolating the failure to freshness.sh's check 2
(source-fingerprint vs. worktree) alone, leaving check 1 (graph-vs-product) passing, verified
directly during authoring against a throwaway reference implementation — and **(b)** is left
byte-for-byte untouched, so both of freshness.sh's checks must pass. `cmd.sh` runs
`extensions/graphify/extension/scripts/freshness.sh <product.md>` (T015, a later wave — not yet
implemented) against each copy and prints a combined, deterministic two-line result
(`expected.txt`). Today, with `freshness.sh` absent, both lines report `NOT-EXECUTABLE` — the
intended red-for-the-right-reason TDD state (see `test/run.sh`'s fixture-discovery convention),
not a malformed fixture — and once T015 lands a contract-conforming implementation this file goes
green with no edits required.
