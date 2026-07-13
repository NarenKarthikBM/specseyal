# arm1-fallback

Golden fixture for arm 1's **SC-002 honesty / FR-004 fallback branch** (T006,
005-graphify-context). `input/repo/` is a small, self-contained repo slice carrying
exactly one genuine cross-file relationship whose *kind* — not its pattern-clarity — sits
outside everything `augment.sh` models: `scripts/render-plan-scaffold.sh` reads
`templates/plan-template.md`, a script consuming a Markdown scaffolding template. Plan.md
Arm 1 (D76) deliberately excludes this "template-read" kind from the three modeled edges
(`registers_hook`, `installs`, `invokes`), booking it as an evidence-backed follow-up
(I-24) rather than modeling it here. The reference itself is literal, unconditional, and
uncommented — not the ambiguous-pattern shape the sibling `arm1-messy` fixture covers —
so a compliant pass unambiguously *detects* it; because its kind is unmodeled, `augment.sh
--emit` must still surface it, as an `EDGE` row with relation `asserted` and confidence
`ASSERTED` (see `expected.txt` for the exact tab-separated bytes), never minted as a
confident `invokes` edge (its target is a `.md` document, not a `.sh` script) and never
simply absent from the projection — silence there is the exact SC-002 regression this
fixture exists to catch. Until `augment.sh` (T008, not yet implemented) exists, `cmd.sh`
is expected to fail in `test/run.sh` with an "augment.sh not found" / non-zero-exit
reason — that is the intended TDD red, not a malformed fixture.
