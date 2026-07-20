# Violation — coverage gap

**Contract:** `docs/contracts/testing-doc.md` §6 rule 3 ("a full bijection: no id in `spec.md` is
missing a row, and no row references an id absent from `spec.md`").

**What's broken:** `spec.md` is unchanged from `conformant/` and still declares `FR-002`
("Every trace record in `traces.jsonl` MUST validate against `trace-schema.md` §1/§7"). But
`testing.md`'s `## Coverage map` table is missing the row for `FR-002` — the bijection `spec.md`
IDs ↔ coverage-map rows is broken for exactly that one id. `FR-001`, `SC-001`, and `SC-002` all
still have rows; the frontmatter (`executed: none`) and the second required section
(`## Verified by reading vs. would-execute in v2`) are unchanged.

**Everything else in this directory is byte-identical to `conformant/`** (mechanical
`feature:`/path substitution aside).

**Expected checker message:**

```
testing.md · testing-doc.md §6 rule 3: 'FR-002' appears in spec.md but has no '## Coverage map'
row (bijection broken)
```
