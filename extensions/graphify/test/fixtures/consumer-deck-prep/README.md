# consumer-deck-prep — consumer fixture 6 (T033, US3)

Non-regression guard on the sixth of `plan.md`'s six named live consumers: deck-prep must go
on reading the **receipts diet** (`graphify-receipts.md`) unbroken. T021 lockstep-edited the
real production template `extensions/council/extension/templates/deck-technical.md` so Stage-0
deck-prep names `graphify-receipts.md` in its `**Sources**` line and mines its two sections
(`## Concept / rationale receipts`, `## Contracts cited`) — the D62 concept/rationale
enrichment source, distinct from and complementary to `graphify-context.md`'s blast-radius
grounding. This fixture reads that real template directly (never a copy — the point is to
catch a regression *in* the production file) plus a minimal, self-contained exemplar diet
committed under `input/`, and asserts, mechanically and with no LLM: (a) the template still
names and instructs mining of `graphify-receipts.md`, and (b) the exemplar diet a real
generator run would hand deck-prep actually carries both sections the instruction points at.
Verified to discriminate both ways: reverting `deck-technical.md` to its pre-T021 state flips
checks (a1)-(a4) to FAIL while (b1)-(b2) stay green (they test the fixture's own exemplar, not
the template); truncating the exemplar to drop a heading flips the matching (b) check to FAIL
while all (a) checks stay green — each half fails for its own reason, never masked by the
other.
