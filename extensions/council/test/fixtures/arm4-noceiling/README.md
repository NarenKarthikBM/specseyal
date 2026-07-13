# arm4-noceiling

Golden fixture for arm 4's **query-ceiling disclosure, quiet-path branch** (T025,
005-graphify-context) — the S18 inverse of the sibling `arm4-ceiling` fixture (T024): "a check
that can only ever fire proves nothing about its quiet path" (plan.md Arm 4). Where
`arm4-ceiling` drives a member's query loop *to* the ceiling and asserts the reduced-grounding
disclosure fires, this fixture drives an ORDINARY round — 8 queries against the `standard`
tier's `query_ceiling: 15` (`council-config.yml`), 8 being this round's near-max per D77 (the
measured baseline was A=8 B=7 C=9 D=2 E=6, actual max 9, so 8 is close to but not the max, and
well under the ceiling) — and asserts the disclosure stays silent: `cmd.sh` invokes
`extensions/council/extension/scripts/ceiling-check.sh standard 8` and the golden
(`expected.txt`) is exactly one line, `ceiling_hit: false`, and NOTHING else — no `>
**Reduced grounding** —` line (the FR-019/D74 disclosure lineage), ever, on a round that never
hit its cap. This is SC-008's crying-wolf guarantee made concrete: a disclosure that can only
ever be observed firing (`arm4-ceiling`'s `ceiling_hit: true` case) proves nothing about
whether it stays quiet when it shouldn't fire — pairing both fixtures is what proves the guard
is *selective*, not merely *present*. Until `ceiling-check.sh` (a later wave — not authored by
this fixture) exists, `cmd.sh` invokes a path that does not yet exist and fails with "No such
file or directory" — the intended TDD red-for-the-right-reason (see `test/run.sh`'s own
fixture-discovery convention: a script-under-test that doesn't exist yet is expected to fail,
not a malformed fixture); once `ceiling-check.sh` lands conforming to the pinned interface
(`<tier> <query-count>` on argv; stdout's first line always `ceiling_hit: true|false`; a second
line, the disclosure, iff hit; nothing else when not hit or the tier's ceiling is `null`/unset),
this file goes green with no edits required.
