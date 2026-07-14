# consumer-plan

Consumer-named fixture (T029, 005-graphify-context) proving the FR-013 non-regression
guarantee that `/speckit-plan` — and, identically, `/speckit-tasks-graph` and
`/speckit-implement-parallel` — can keep reading `graphify-context.md`'s blast-radius diet
unchanged even after arm 3 (T020) grew the generator from one product to three. Where
`arm3-products` (T018) checks the FR-013 shape against a fixture-local, hand-authored stand-in
for one generator run, this fixture checks the two **live, committed** sources of truth
directly, so an edit to either one trips it with no regenerated exemplar as an intermediary:
(1) the `## Output template — \`graphify-context.md\`` fenced block inside the generator's own
`extensions/graphify/skills/speckit-graphify-context/SKILL.md` (isolated from the two newer
diet templates that follow it in the same file via an `awk` range extraction, so a heading that
only ever appears in a *later* template or in surrounding prose can never false-positive this
check), and (2) the committed worked example,
`extensions/graphify/examples/graphify-context.example.md`. For each source independently,
`cmd.sh` asserts the source file exists, that each of the 5 section headings (`## Graph scope`,
`## Relevant existing modules`, `## Blast radius (per anchor)`, `## Shared / mutable files
(collision watch)`, `## Patterns to follow`) is present as its own line, and that all 5 appear
in that exact relative order — the order check catches a pure reorder that leaves every heading
present and unrenamed, a regression the 5 presence checks alone cannot see — for 14 checks
total, each printing its own deterministic `PASS`/`FAIL` line naming exactly which source and
which heading regressed, followed by a summary line (`expected.txt`). Verified during authoring
to discriminate on all three manufactured-failure classes it claims to catch: a renamed heading,
a dropped heading, and a pure two-heading reorder, each exercised against a scratch copy of the
relevant source (never this repo's own tracked files) and each flipping only the check(s) that
specific mutation should flip while every other check stayed green.
