---
feature: violation-bad-frontmatter
phase: testing
executed: none
---

## Coverage map

| id | approach | grounding | evidence-source | status |
|---|---|---|---|---|
| FR-001 | Inspect the committed tree against `artifact-layout.md` §2; every completed-phase artifact is present. | ### Integration status | report-claimed | covered |
| FR-002 | Read `traces.jsonl` and confirm every record's fields against `trace-schema.md` §1/§7. | ### Integration status | log-verified | covered |
| SC-001 | Run `check-conformance.py <this-dir>` (once T008 lands) and confirm exit `0`. | ### Integration status | report-claimed | covered |
| SC-002 | Same as SC-001 — a `0` exit IS "every artifact validates". | ### Integration status | report-claimed | covered |

## Verified by reading vs. would-execute in v2

Every row above was verified by reading `completion-report.md`'s `### Integration status`
section (`report-claimed`); the `log-verified` row(s) additionally, lazily, cross-checked
`implement.log.md` per the D10 on-demand-grounding pattern. A v2, test-executing tester would
instead run `check-conformance.py <this-dir>` itself rather than reading a claim about it.
