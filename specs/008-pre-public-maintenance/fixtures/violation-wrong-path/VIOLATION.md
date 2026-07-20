# Violation — wrong path

**Contract:** `docs/contracts/artifact-layout.md` §1 (directory layout) / §7 rule 2 ("Every artifact
present validates against its contract" — includes being *at* the path the layout names).

**What's broken:** `council/defense-deck/technical.md` is missing from its required layout path.
The bytes exist — unchanged from `conformant/`'s copy — but they sit at `council/technical.md`
instead, missing the `defense-deck/` nesting `artifact-layout.md` §1 requires. `overview.md`
stays correctly placed at `council/defense-deck/overview.md`, so this is a single misplaced file,
not a missing subtree.

**Everything else in this directory is byte-identical to `conformant/`** (mechanical
`feature:`/path substitution aside) — `council/decision-record.md`, `completion-report.md`,
`testing.md`, `traces.jsonl`, and `agents/assignment.md` are all otherwise-valid.

**Expected checker message (shape: `<artifact> · <rule>`, per
`conformance-checker-command.md` C5):**

```
council/defense-deck/technical.md · artifact-layout.md §1: required artifact not found at its
layout path (found instead at council/technical.md, missing the defense-deck/ subdirectory)
```

**Why this file, not another:** `defense-deck/` has no sibling `docs/contracts/*.md` schema of
its own (unlike `council/decision-record.md`, `completion-report.md`, `testing.md`, or
`traces.jsonl`, each owned by one of the other five directly-checked contracts). Misplacing it
therefore can't be misread as a second contract's violation — the fault traces to exactly one
rule, in exactly one contract.
