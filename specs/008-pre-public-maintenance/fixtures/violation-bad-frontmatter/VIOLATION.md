# Violation — bad frontmatter

**Contract:** `docs/contracts/completion-report.md` §6 rule 1.

**What's broken:** `completion-report.md`'s frontmatter carries `status: done`. The contract's
closed enum is `success | partial | failed` (never `aborted` — completion-report.md §1: an
aborted `complete`-phase session by definition never reaches the point of writing this file) —
`done` is not a member. All six core sections are present, correctly ordered, and unchanged from
`conformant/`; only the one frontmatter field is wrong.

**Everything else in this directory is byte-identical to `conformant/`** (mechanical
`feature:`/path substitution aside).

**Expected checker message:**

```
completion-report.md · completion-report.md §6 rule 1: frontmatter 'status' = 'done' is not one
of {success, partial, failed}
```
