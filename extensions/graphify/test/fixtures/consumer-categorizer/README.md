# consumer-categorizer fixture (T032, consumer 5)

This is a **non-regression guard**, not a red-then-green TDD fixture: T022 already lockstep-updated
`extensions/workforce/extension/templates/categorizer-prompt.md` to read the per-file type-signal
diet (`graphify-type-signal.md`, T020's generator output) as a **corroborating signal for its own
`type` derivation — never a substitute for it**, since the diet's `file_type` enum (`code |
document | paper | image | rationale | concept`) is a coarser, different axis than the
categorizer's own 8-value `type` table and can only back the docs-vs-everything-else split.
`cmd.sh` asserts that property stays true with **no script-under-test invoked** — a static
content/shape check against a real, already-committed template plus a fixture-local exemplar,
exactly like `arm3-products`' shape-conformance half — split into two parts: (a) the real,
committed `categorizer-prompt.md` still names `graphify-type-signal.md`, still carries the
"corroborating signal, never a substitute/replacement" framing verbatim, still carries its own
8-value `type` derivation table intact (header row plus all 8 enum values, matched as literal
`| \`<value>\` |` table cells so a mention of the same word in running prose elsewhere in the file
can never satisfy the check), and still cites the diet's own `## Path-convention fallback (not in
graph)` section (checked against a whitespace-flattened copy of the prompt, since that citation
word-wraps across a line break in the committed source and a raw-line search would otherwise miss
it); (b) this fixture's own minimal `input/graphify-type-signal.md` exemplar — the diet shape
T020's generator (`extensions/graphify/skills/speckit-graphify-context/SKILL.md`) defines — carries
both of its required sections, `## Per-file type signal (graph-grounded)` and `## Path-convention
fallback (not in graph)`. Every one of the 7 checks was verified, against scratch-mutated copies of
the real files (the repo tree itself was never touched), to flip to FAIL exactly when its own
targeted content is stripped or reworded and to stay PASS otherwise, before this fixture was
committed GREEN.
