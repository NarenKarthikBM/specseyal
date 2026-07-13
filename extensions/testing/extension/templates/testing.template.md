---
# TEMPLATE — the emitted skeleton for `testing.md` (docs/contracts/testing-doc.md). Resolve
# `<id>` to the real spec ID and strip every `#` / `<!-- -->` guidance comment (plus the two
# illustrative rows under `## Coverage map`) before writing the final file -- a real testing.md
# carries none of this scaffolding. Unlike `completion-report.md`'s `status` field, `phase` and
# `executed` below are FIXED literals, not placeholder grammar (contract §1) -- copy them verbatim,
# never substitute another value. Keep every other character of the two required headings below
# byte-identical to the contract's §2 list (R1-S19) -- never paraphrase or reorder them.
feature: <id>                      # spec ID this testing doc describes, string (contract §1)
phase: testing                     # literal -- always "testing"; never substituted, never omitted
executed: none                     # FIXED literal -- FR-009/010, the doc-only boundary, made a
                                    # machine-checkable fact of the document itself (contract §1).
                                    # The ONLY conforming value under this contract version -- never
                                    # a real pass/fail of the tester's own (contract §7, I-3).
---

## Coverage map

<!-- Required content (contract §2/§3): EXACTLY one row per every `SC-\d+` id and every `FR-\d+`
     id appearing in spec.md -- a full bijection (contract §6 rule 3): no id in spec.md missing a
     row, no row referencing an id absent from spec.md. Columns, in this exact order (contract §3):
     id | approach | grounding | evidence-source | status.
       - `approach`: the verification approach -- kind of check + how to perform it + what evidence
         confirms it (manual steps and citations to existing automated tests are both valid;
         concrete test cases are a v2 concern, out of scope here). `--` on a GAP row.
       - `grounding`: the completion-report.md claim/section the approach rests on -- typically
         `### Integration status`. `--` on a GAP row.
       - `evidence-source` ∈ {report-claimed, log-verified} (R1-S05, exact/lowercase/hyphenated) --
         report-claimed rests on completion-report.md's own prose alone; log-verified additionally,
         lazily cross-checked implement.log.md on doubt (the D10 on-demand-grounding pattern). `--`
         on a GAP row.
       - `status` ∈ {covered, GAP} (exact casing: lowercase `covered`, all-caps `GAP`).
     A `covered` row REQUIRES a genuine (non-`--`) `approach` and `grounding`. An id the completion
     report does not evidence is an honest `GAP` -- NEVER relabeled `covered` to make the count look
     whole (SC-002/004; contract §3, §6 rule 5).
     Delete this comment and both illustrative rows below once every real id from spec.md has its
     own row; the rows below are illustrative of the FORMAT only, not a claim about any feature's
     actual coverage (contract §1). -->

| id | approach | grounding | evidence-source | status |
|---|---|---|---|---|
| <SC-xxx or FR-xxx> | <the verification approach: kind of check + how to perform it + confirming evidence> | <the completion-report.md claim/section this rests on, e.g. `### Integration status`> | <report-claimed \| log-verified> | <covered \| GAP> |
| <SC-xxx or FR-xxx> | — | — | — | **GAP** |

## Verified by reading vs. would-execute in v2

<!-- Required content (contract §4/§6 rule 6): NON-EMPTY prose -- the honest split that keeps the
     doc-only boundary (FR-009) legible beyond the frontmatter. Name which coverage-map rows above
     were verified by READING -- report-claimed (completion-report.md's prose alone) or log-verified
     (additionally corroborated against implement.log.md) -- and which would need an actual test RUN
     to confirm, deferred to a future v2 test-executing tester (FR-010, I-3). One general sentence
     naming the boundary once ("the coverage map above records what was read and against what;
     nothing here was executed") satisfies this section -- it need not restate every row
     individually. Never leave this heading followed by nothing: an empty section fails contract §6
     rule 6, and nothing written here may report a pass/fail of the tester's own (FR-009). -->

<prose: name the report-claimed/log-verified split above, and what a v2 tester would run instead of read>
