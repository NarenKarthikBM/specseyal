# `conformant/` — the both-branch PASS fixture

**This is not a feature.** It is one directory, authored to `docs/contracts/`'s current
(post-M4) shape, that a conformance checker (`check-conformance.py`, T008–T010) must PASS in
full — every one of the six directly-checked contracts (`artifact-layout`, `decision-record`,
`completion-report`, `testing-doc`, `trace-schema`, `agent-library-schema`), plus the three
delegated ones (`profile-schema` via `validate-profile.py`, `taxonomy` via
`validate-categorization.py`).

See the parent directory's `fixtures/README.md` for the full coverage table, the six
violation-dir siblings (each a copy of this tree with exactly one deliberate fault), and design
notes for whoever wires this fixture into `check-conformance.py` / `extensions/workforce/test/
run.sh`.

Unlike `specs/000-sample/`, this fixture ships no nested `.claude/agents/` or `.claude/skills/`
— `agent-library-schema.md`'s directly-checked surface here is `agents/assignment.md`'s roster
shape only (`specs/008-pre-public-maintenance/data-model.md` E3), not the base/skill library
file formats, which stay out of this feature's scope.
