---
feature: 004-testing-completion   # spec ID, string
phase: testing                    # literal -- always "testing"
executed: none                    # FIXED literal -- FR-009/010, the doc-only boundary
---

## Coverage map

| id | approach | grounding | evidence-source | status |
|---|---|---|---|---|
| FR-001 | Inspect `/speckit-complete`'s command definition (main-thread, no subagent dispatch) and confirm a real `complete` run's git diff touches only `completion-report.md`. | `### Integration status` | report-claimed | covered |
| FR-002 | Contract-validate `completion-report.md` against `docs/contracts/completion-report.md` via `extensions/testing/test/run.sh` section 2. | `### Integration status` | log-verified | covered |
| FR-003 | Grep the frontmatter `status:` field and confirm it is exactly one of success/partial/failed. | `### Integration status` | report-claimed | covered |
| FR-004 | Diff `completion-report.md`'s heading list against `docs/contracts/completion-report.md` section 2's six-section list. | `### Integration status` | report-claimed | covered |
| FR-005 | Confirm the report is plain markdown + frontmatter bytes with no reshaping required; re-sending is idempotent on `artifact.sha256` by construction. | `### Integration status` | report-claimed | covered |
| FR-006 | Inspect the tester's one trace record's `context_in` field and confirm no other artifact was written this phase. | `### Integration status` | log-verified | covered |
| FR-007 | Contract-validate this document against `docs/contracts/testing-doc.md` via `extensions/testing/test/run.sh` section 3. | `### Integration status` | log-verified | covered |
| FR-008 | This Coverage map is the evidence: every row here carries a non-em-dash approach, or is honestly marked GAP. | `### Integration status` | report-claimed | covered |
| FR-009 | Confirm frontmatter `executed: none` and that no row or prose in this document reports a pass/fail of its own. | `### Integration status` | report-claimed | covered |
| FR-010 | Read "Verified by reading vs. would-execute in v2" below for the explicit read/execute split. | `### Integration status` | report-claimed | covered |
| FR-011 | Inspect `traces.jsonl` for exactly one `role: tester` record at `model: claude-sonnet-5`. | `### Integration status` | log-verified | covered |
| FR-012 | `git log` shows a `complete(004-testing-completion)` and a `testing(004-testing-completion)` commit. | `### Integration status` | log-verified | covered |
| FR-013 | Run `extensions/git/test/run.sh` section 7 and confirm the commit seam survives a git-ext reinstall and a foreign-extension reinstall. | `### Integration status` | log-verified | covered |
| FR-014 | Run `extensions/git/test/run.sh` section 6 (the checkbox-delta regression) and confirm the forward-flip PASS case. | `### Integration status` | log-verified | covered |
| FR-015 | Same section 6 regression, re-checked after a git-ext reinstall and a foreign reinstall. | `### Integration status` | log-verified | covered |
| FR-016 | Read `implement.log.md`'s pre-flight entry, confirming the fix landed before Wave 1 started. | `### Integration status` | log-verified | covered |
| FR-017 | Read `council/decision-record.md` for the gate-integrity finding on the `verify-gate.sh` design. | `### Integration status` | report-claimed | covered |
| SC-001 | Run `extensions/testing/test/run.sh` section 2's completion-report validator against the real report. | `### Integration status` | log-verified | covered |
| SC-002 | Run the same harness's section 3 testing-doc validator against this document. | `### Integration status` | log-verified | covered |
| SC-003 | Inspect the trace record's context_in/context_out and confirm no completion-report or spec body was re-imported to main. | `### Integration status` | log-verified | covered |
| SC-004 | Count this Coverage map's rows (27) and cross-check the id set against `spec.md`'s own SC/FR tokens. | `### Integration status` | report-claimed | covered |
| SC-005 | Run the two-golden completion-report check (`extensions/testing/test/run.sh` section 2): an appendix-bearing and an appendix-free report both pass identically. | `### Integration status` | log-verified | covered |
| SC-006 | `git log` confirms both the complete(<id>) and testing(<id>) boundaries (same evidence as FR-012). | `### Integration status` | log-verified | covered |
| SC-007 | Grep `traces.jsonl` for the role enum (one new tester role) and grep the built extension for any ANTHROPIC_API_KEY reference. | `### Integration status` | report-claimed | covered |
| SC-008 | `extensions/git/test/run.sh` section 7's reinstall-survival assertions (git-ext reinstall + foreign-extension reinstall). | `### Integration status` | log-verified | covered |
| SC-009 | — | — | — | **GAP** |
| SC-010 | Same as FR-014/015: `extensions/git/test/run.sh` section 6 green, plus `implement.log.md`'s wave-by-wave record showing no hand assistance from wave 2 on. | `### Integration status` | log-verified | covered |

## Verified by reading vs. would-execute in v2

Every `report-claimed` row above rests on `completion-report.md`'s own prose in `### Integration
status` — read once, not independently re-derived. Every `log-verified` row was additionally,
lazily cross-checked against a concrete artifact or test run the report cites
(`extensions/git/test/run.sh`, `traces.jsonl`, `implement.log.md`, or `git log` itself) — the D10
on-demand-grounding pattern, applied here to a lazy read rather than a graphify query.

**SC-009 is the one honest GAP.** It is the M4 exit criterion that both this document and
`completion-report.md` be validated *and* committed — a fact about events that happen at and
after this document's own authoring. No read performed while writing this file can attest to
its own future commit, so it is left an explicit gap for the human sign-off (`quickstart.md`
T019) to close, never fabricated `covered`.

Nothing above was executed: this tester ran no test suite and reports no pass/fail of its own.
A future v2, test-executing tester would actually *run* `extensions/testing/test/run.sh`,
`extensions/git/test/run.sh`, and the quickstart's own validation scenarios, rather than reading
their last recorded outcome.
