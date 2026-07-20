# Violation — missing section

**Contract:** `docs/contracts/decision-record.md` §5 (Sections table).

**What's broken:** `council/decision-record.md`'s trailing `## Carried Constraints` section is
omitted entirely. §5 lists it as cardinality "1, last, yes (may be empty)" — it may say nothing,
but the heading itself may never be absent. Every other required section (`## Metadata`,
`## Round 1`, `## Human Gate`) is present, correctly ordered, and unchanged from `conformant/`.

**Everything else in this directory is byte-identical to `conformant/`** (mechanical
`feature:`/path substitution aside).

**Expected checker message:**

```
council/decision-record.md · decision-record.md §5: required section '## Carried Constraints'
is missing (cardinality 1, last, required — may be empty but never absent)
```
