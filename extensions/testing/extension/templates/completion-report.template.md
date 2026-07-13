---
# TEMPLATE — the emitted skeleton for `completion-report.md` (docs/contracts/completion-report.md).
# Resolve every placeholder token below and strip every `#` / `<!-- -->` guidance comment before
# writing the final file — a real completion report carries none of this scaffolding. `<id>`,
# `<success|partial|failed>`, `<name>`, and `N/N` are the contract's OWN placeholder grammar (§1);
# resolve those too, but keep every other character of the six core headings below byte-identical
# to the contract's §2 list (SC-001) — never paraphrase or reorder them.
feature: <id>                       # spec ID this report describes, string (contract §1)
phase: complete                     # literal — always "complete"; never substituted, never omitted
status: <success|partial|failed>    # exact enum member, lowercase, no other value (FR-003) — never
                                     # "success" when any task in this run finished partial or failed
                                     # (spec.md US1 scenario 2; contract §6 rule 1). Aligns to
                                     # trace-schema.md §1 `outcome` and IS the D19 phase.completed
                                     # event's own `status` field, unmodified (contract §5).
---

## Implementation Complete — <name>

<!-- Required content (contract §2): the run's shape — waves run, widest parallel wave, and a
     roster summary of which specialists/skills executed (FR-004). `<name>` is the feature or
     extension name this report describes; it need not equal frontmatter `feature` verbatim
     (precedent: 003's report titled this heading with the extension it built, `speckit-ext-workforce`,
     not its spec ID `003-workforce`) — either is valid so long as `<name>` is non-empty. -->

### Completed (N/N)

<!-- Required content (contract §2): the completed-task record — N of N tasks done, with enough
     detail (typically a table) to see which. `N/N` is `<completed>/<total>`: two non-negative
     integers, completed ≤ total, no space around the slash — e.g. "### Completed (12/19)". Never
     leave the literal string "N/N" in the final file; it is a placeholder token, exactly like
     `<name>`. -->

### Partial/Degraded

<!-- Required content (contract §2): detail for any task that finished partial or degraded. PRESENT
     EVEN WHEN THERE ARE NONE — never omit this heading; when there are none, the body may simply
     say "None." (contract §6 rule 3). If frontmatter `status: partial` above, this section MUST be
     non-empty — some body text beyond the heading (contract §6 rule 6). -->

### Failed

<!-- Required content (contract §2): detail for any failed task. PRESENT EVEN WHEN THERE ARE NONE —
     never omit this heading; when there are none, the body may simply say "None." (contract §6
     rule 3). If frontmatter `status: failed` above, this section MUST be non-empty — some body text
     beyond the heading (contract §6 rule 6). -->

### Integration status

<!-- Required content (contract §2): the end-to-end / integration claims this run makes — the
     section the `testing` phase's coverage map grounds on (FR-008, docs/contracts/testing-doc.md).
     The most load-bearing section for the downstream phase; do not leave this thin. -->

### Key results

<!-- Required content (contract §2): the headline outcomes worth surfacing without reading the rest
     of the report. -->

<!-- Everything below this line is the OPTIONAL appendix (contract §3) — outside the validated
     core. A generic, non-dogfood feature omits it entirely; this contract validates identically
     with or without it present (SC-005). Only a dogfood / milestone-close build (a feature that
     closes out a docs/05 milestone) needs either heading below — do not add them otherwise. -->

## Milestone-close context

<!-- OPTIONAL (contract §3) — omit this whole section, heading included, unless this run closes a
     docs/05 milestone. Free-form internal structure; nothing inside is checked (contract §6 rule
     7). Precedent (specs/003-workforce/completion-report.md) nested a "<M-N Done when>" status,
     findings adjudicated, deferred/carried items, and next steps here — illustrative, not mandated. -->

## Decisions & log

<!-- OPTIONAL (contract §3) — omit this whole section, heading included, unless this run closes a
     docs/05 milestone. Free-form internal structure; nothing inside is checked (contract §6 rule
     7). -->
