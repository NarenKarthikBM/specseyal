# Contract — Testing Doc (`testing.md`)

> **Status:** 1.0 (M4, 2026-07-13). Normative.
> **Implements:** FR-007, FR-008, FR-009, FR-010, FR-011 (`004-testing-completion`); SC-002, SC-004; **D32** (resumability rule, `artifact-layout.md` §3); **D46 rule 3** (an un-ratified format choice belongs in the plan, not the spec — why one-file-versus-two was decided at plan time, ratified **R1-S16**); **R1-S03** (mechanical SC/FR coverage validator — validation fails on any gap); **R1-S05** (report-claimed/log-verified evidence-source marking); **R1-S19** (golden section assertions derived from this file's own section list); **D10** (the on-demand-grounding "reviewers that can check receipts" pattern, applied here to a lazy `implement.log.md` read).
> **Location:** `specs/<id>/testing.md` — the sole output of the `testing` phase (`artifact-layout.md` §2), one per feature.
> **Consumed by:** the human who reads `testing.md` before signing off on a feature's completion; `extensions/testing/test/run.sh`'s SC/FR coverage validator (§6 below, R1-S03/S19); a v2 test-executing tester (out of scope, I-3) that would start from this same coverage map.

The testing doc is the `testing` phase's sole output: a separate-session Sonnet `tester`'s coverage assessment, produced from `completion-report.md` + `spec.md` and written here in a **normative format** so it *validates* under the resumability rule (`artifact-layout.md` §3) — an absent or malformed `testing.md` leaves the `testing` phase incomplete, exactly like every other artifact this directory governs. Where `001`/`002`/`003` left this step ad hoc or absent, this contract is the finalization deliverable (FR-007) that gives it a schema.

Its defining boundary is **doc-only**: the tester asserts what should be tested and how — it never executes a test and never reports a pass/fail of its own (FR-009). `executed: none` makes that boundary a machine-checkable fact of the document itself, not a claim resting on prose (FR-010). Its other defining discipline is honesty about gaps: every Success Criterion **and** Functional Requirement in `spec.md` gets a coverage-map row, and an item the completion report does not evidence is marked an explicit `GAP` — never a fabricated `covered` (SC-002/004; the honesty ethos of 001-FR-019 and I-13). Like its sibling `docs/contracts/completion-report.md`, this is one of two separate contract files (§5) — not merged.

---

## 1. Format

```markdown
---
feature: 004-testing-completion   # spec ID, string
phase: testing                    # literal — always "testing"
executed: none                    # FIXED literal — FR-009/010, the doc-only boundary,
                                    # legible in the document itself
---

## Coverage map

| id | approach | grounding | evidence-source | status |
|---|---|---|---|---|
| SC-004 | e.g., contract-validate `testing.md` against §6 below; inspect the coverage map for full id coverage. | `### Integration status` | report-claimed | covered |
| FR-013 | e.g., run `extensions/git/test/run.sh` and confirm the reinstall-survival case passes. | `### Integration status` | log-verified | covered |
| SC-010 | — | — | — | **GAP** |

## Verified by reading vs. would-execute in v2

<prose: which rows above were confirmed by reading (report-claimed / log-verified),
and what a future v2 tester would run instead of read>
```

The frontmatter is fixed exactly as shown: `phase: testing` and `executed: none` are **literal values**, not placeholders — `feature` alone takes the real spec ID. `executed: none` is the **only** conforming value under this contract version; any other value (e.g. a future `partial`/`full` reported by a test-*executing* v2 tester) is non-conforming here and is explicitly out of scope (§7, I-3) — this contract governs the doc-only tester and no other.

The table rows above are **illustrative of the format only**, not a claim about any feature's actual coverage — the real `testing.md` is produced by a separate `tester` session reading the real `completion-report.md` (§5).

## 2. Required sections (validated)

The exact, ordered heading list a conforming `testing.md` MUST contain — greppable, and the list `extensions/testing/test/run.sh` (R1-S19, §6) derives its golden section assertions from:

- `## Coverage map`
- `## Verified by reading vs. would-execute in v2`

Both are level-2 (`##`) headings, in that exact top-to-bottom order. Per §6 rule 2, **no other top-level heading is permitted** — this contract defines no optional appendix (§7; contrast `completion-report.md` §3, which does).

| Section | Required content |
|---|---|
| `## Coverage map` | One row per every `SC-\d+` id and every `FR-\d+` id in `spec.md` (§3) — the coverage table. |
| `## Verified by reading vs. would-execute in v2` | The honest split (§4): what the tester confirmed by reading versus what a future v2 tester would execute. |

## 3. Coverage map — required per-row fields

Every row in `## Coverage map` MUST carry exactly these fields, in this order — greppable, and (with §2's list) the only place this contract's structure is stated (R1-S19, §6):

- `id`
- `approach`
- `grounding`
- `evidence-source`
- `status`

| Field | Rule |
|---|---|
| `id` | The exact `SC-\d+` or `FR-\d+` token, copied verbatim from `spec.md` (e.g. `SC-004`, `FR-011`). One row per id; no id repeated, none omitted (§6 rule 3). |
| `approach` | The **verification approach** (Clarifications 2026-07-12, FR-008): the kind of check, how to perform it, and what evidence confirms it — manual steps and citations to existing automated tests are both valid. Concrete test cases (inputs/expected outputs) are a v2 concern (I-3) and are **not** required here. A `GAP` row carries `—`: there is no approach to state, which is precisely what makes it a gap. |
| `grounding` | The `completion-report.md` claim or section the approach rests on — typically `### Integration status` (`docs/contracts/completion-report.md` §2), the section that report names as "the most load-bearing section for the downstream phase." A `GAP` row carries `—`: there is nothing in the report to cite. |
| `evidence-source` | ∈ **{`report-claimed`, `log-verified`}** (R1-S05) — exact, lowercase, hyphenated. `report-claimed`: the row's confidence rests on `completion-report.md`'s own prose alone. `log-verified`: the tester additionally, lazily, read `implement.log.md` on doubt — the D10 on-demand-grounding pattern ("reviewers that can check receipts"), applied here to a lazy cross-check rather than a graphify query — and the row's evidence reflects what the log itself shows. A `GAP` row carries `—`: there is no evidence to source. |
| `status` | ∈ **{`covered`, `GAP`}** — exact casing (lowercase `covered`; all-caps `GAP`). `covered` requires a non-`—` `approach` and `grounding`. `GAP` is any id the completion report does not evidence — **never** relabeled `covered` to make the count look whole (SC-002/004; the honesty ethos of 001-FR-019 and I-13). |

## 4. Verified by reading vs. would-execute in v2

The doc-only boundary (FR-009) is legible only if the document itself states, in prose beneath this heading, which coverage-map rows were **verified by reading** — grounded in `completion-report.md` prose (`report-claimed`) or corroborated against `implement.log.md` (`log-verified`) — and which would require an actual test **run** to confirm, deferred to a test-executing v2 tester (FR-010, I-3; the honesty ethos of 001-FR-019 and I-13). This is a **narrative** section, not a second table: it names the split plainly enough that a reader never mistakes a `covered` coverage-map row for "the tester ran this and it passed" — nothing in this document ever reports a pass/fail of the tester's own (FR-009).

A conforming `testing.md` need not restate every row individually; naming the general boundary once ("the coverage map above records what was read and against what; nothing here was executed") satisfies this section, provided the section is not left empty (§6 rule 6).

## 5. Two contract files, not one (R1-S16)

This is **one of two** separate sibling schema files — the other is `docs/contracts/completion-report.md`, the `complete` phase's contract. They are **not merged**: `docs/contracts/` holds one schema per file, and this is the **ninth** such file (`completion-report.md`, authored alongside it, is the eighth) — a combined file would be the first exception to that convention across all of them. The coupling between the two artifacts — the `testing` phase reads the completion report (`artifact-layout.md` §2) and grounds every coverage-map row's `grounding` field (§3) against its `### Integration status` section (FR-008, `docs/contracts/completion-report.md` §2) — is carried by this cross-reference, a pointer, not by co-locating both schemas in one file (D46 rule 3; ratified by council, `council/decision-record.md` R1-S16).

## 6. Validation

A testing doc conforms iff:

1. Frontmatter parses as YAML; `feature`, `phase`, `executed` are all present. `phase == "testing"`. `executed == "none"` — exact, lowercase, literal (FR-009/010) — **the only conforming value under this contract version**; any other value is non-conforming here (§7, I-3).
2. Both §2 sections are present, spelled exactly as §2 lists them, in that exact top-to-bottom order. **No other top-level (`##`) heading is permitted** — this document defines no optional appendix (§7; contrast `completion-report.md` §3).
3. `## Coverage map` contains **exactly one row per** `SC-\d+` id and **exactly one row per** `FR-\d+` id appearing in `spec.md` — a full bijection: no id in `spec.md` is missing a row, and no row references an id absent from `spec.md` (SC-004's "100%", made a structural fact rather than an attempted target).
4. Every row carries all five §3 fields (`id`, `approach`, `grounding`, `evidence-source`, `status`); `evidence-source ∈ {report-claimed, log-verified}` and `status ∈ {covered, GAP}`, exact spelling, no other value, for every non-`—` field.
5. No row is `covered` without a genuine (non-`—`) `approach` and `grounding` (§3) — an id the completion report does not evidence is `GAP`, **never** relabeled `covered` (SC-002/004; the gap-honesty rule this contract exists to hold the tester to).
6. `## Verified by reading vs. would-execute in v2` is **non-empty** (some body text beyond the bare heading) — the doc-only boundary must be legible in prose, not merely implied by the frontmatter (FR-010).

**Machine-checkability (R1-S03, R1-S19).** §2's and §3's bulleted lists above are the **only** place this contract's structure is stated. `extensions/testing/test/run.sh` derives two things directly from this file, never from a hand-maintained parallel copy: **(a)** the coverage check — it greps every `SC-\d+` and `FR-\d+` id out of `spec.md` and asserts each appears as a `## Coverage map` row (rule 3) — validation **fails on any gap in the mapping**, not merely on a malformed row (the 003 categorization-completeness-validator precedent); and **(b)** the golden section assertions — read straight out of §2's bulleted list, exactly as `completion-report.md` §6 does for its own sibling, so the two contracts and their shared validator move together and cannot silently diverge.

## 7. Non-goals (v1)

- **No test execution, no pass/fail of its own.** `executed: none` is fixed for this contract version (FR-009); a test-executing v2 tester would need a new `executed` enum and new result fields — a future contract revision, not this one (I-3).
- **No concrete test cases.** Inputs/expected-outputs belong to a v2 tester that actually runs something; a verification *approach* (§3) is the ceiling here (Clarifications 2026-07-12).
- **No optional appendix.** Unlike its sibling `completion-report.md` (§3 there), this contract defines no additional, unvalidated top-level section — the whole document is core (§6 rule 2).
- **No enforcement of the session-boundary/context-hygiene claim (SC-003).** That a `testing` session read only `completion-report.md` + `spec.md` is a runtime fact no static file check can attest to from `testing.md`'s bytes alone; the auditable record is the tester's trace `context_in` field (`trace-schema.md`, R1-S06), not this contract.
- **No relaxation of the resumability rule.** This contract adds structure; `testing.md` still must exist **and** validate for the `testing` phase to read as done (`artifact-layout.md` §3).
- **No cross-feature aggregation.** One testing doc per feature (`artifact-layout.md` §2); a rollup across features is a central-manager (M5) concern, not this contract's.
