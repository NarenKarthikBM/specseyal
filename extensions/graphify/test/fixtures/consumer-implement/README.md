# consumer-implement — /speckit-implement-parallel's per-task blast-radius (T031)

FR-013 tripwire for `/speckit-implement-parallel`'s consumption of the `graphify-context.md`
blast-radius diet (`extensions/graphify/skills/speckit-implement-parallel/SKILL.md`), sibling
to `consumer-plan` (T029) and `consumer-tasks-graph` (T030), which guard the other two named
readers of the same diet. `cmd.sh` reads the real, live committed files under `$REPO` — never
a fixture-local stand-in — and checks three things together: (1) the generator's Output
template (`extensions/graphify/skills/speckit-graphify-context/SKILL.md`) still emits a
`## Blast radius (per anchor)` section carrying its three per-anchor relations, in order —
depends on / depended on by / follow the pattern in — plus the literal FR-013
"unchanged-shape" marker; (2) the worked example
(`extensions/graphify/examples/graphify-context.example.md`) still *realizes* that grammar
with concrete, non-placeholder file paths rather than only documenting it in the abstract; and
(3) `speckit-implement-parallel/SKILL.md` still reads `graphify-context.md` specifically for
grounding (Pre-Execution) and its "Subagent task prompt template"'s
`### Graphify blast radius` section still surfaces the identical three relations, in the same
order, each sourced from `graphify-context.md`. A final cross-file check extracts each side's
ordered relation sequence and diffs them structurally (not just "both mention the phrase
somewhere"), which is what actually catches a silent reorder or rename on either side of the
producer/consumer boundary — verified by hand-mutating scratch copies of both files (reordered
relations, a renamed heading, a dropped field, drifted FR-013 wording, an example regressed to
placeholders, and the consumer pointed at the wrong product file) and confirming each mutation
flips exactly the check(s) that name it, never a vacuous all-green. This fixture depends on no
not-yet-built script — both sides of the contract are already-committed prose — so, per the
task brief, it is **GREEN now** and only breaks the day the per-task blast-radius shape
actually regresses on either side.
