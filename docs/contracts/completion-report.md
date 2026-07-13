# Contract — Completion Report (`completion-report.md`)

> **Status:** 1.0 (M4, 2026-07-13). Normative.
> **Implements:** FR-002, FR-003, FR-004, FR-005 (`004-testing-completion`); **D19** (the `phase.completed` envelope, `trace-schema.md` §6); **D32** (resumability rule, `artifact-layout.md` §3); **D46 rule 3** (an un-ratified format choice belongs in the plan, not the spec — why one-file-versus-two was decided at plan time, ratified **R1-S16**).
> **Location:** `specs/<id>/completion-report.md` — the sole output of the `complete` phase (`artifact-layout.md` §2), one per feature.
> **Consumed by:** the `testing` phase (`testing.md`'s coverage map grounds on `### Integration status`, FR-008, `docs/contracts/testing-doc.md`), M5's D19 `phase.completed` push (`trace-schema.md` §6, §5 below), the git extension's `complete(<id>)` phase-tagged commit (D25; FR-012) — which fires once this artifact exists and validates.

The completion report is the `complete` phase's sole output: the main-thread orchestrator's account of what an `implement` run did, read from `tasks.md` + `implement.log.md` and written here in a **finalized, normative format** — rather than the ad-hoc shape `001`/`002`/`003` each improvised in turn. It finalizes `003`'s hand-built `completion-report.md` (the precedent this contract normalizes) into something that *validates*: under the resumability rule (`artifact-layout.md` §3), an absent or malformed report leaves the `complete` phase incomplete, exactly like every other artifact this directory governs.

Its format has two parts, and keeping them cleanly separate is the whole point (§2, §3): a **normative core** every feature needs (FR-004), and an **optional appendix** that only a dogfood / milestone-close build carries. The contract validates the core alone; the appendix, present or absent, never changes the answer (SC-005).

---

## 1. Format

```markdown
---
feature: 004-testing-completion    # spec ID, string
phase: complete                    # literal — always "complete"
status: success                    # success | partial | failed (FR-003) — machine-readable,
                                    # derivable without reading prose; aligns to
                                    # trace-schema.md §1 `outcome` and IS the D19
                                    # phase.completed event's `status` field (§5)
---

## Implementation Complete — <name>

### Completed (N/N)

### Partial/Degraded

### Failed

### Integration status

### Key results

<!-- Everything below this line is the OPTIONAL appendix (§3) — outside the
     validated core. A generic, non-dogfood feature omits it entirely; this
     contract validates identically with or without it present (SC-005). -->

## Milestone-close context

## Decisions & log
```

The **normative core** (FR-004) is the frontmatter `status` field plus the six sections above — nothing more, nothing less. `<name>` is the feature or extension name the report describes; it need not equal frontmatter `feature` verbatim (precedent: `003`'s report titles this heading `speckit-ext-workforce`, the extension it built, not the spec ID `003-workforce`) — either is valid so long as `<name>` is non-empty. `N/N` is `<completed>/<total>`: two non-negative integers, `completed ≤ total`, no space around the slash (e.g. `### Completed (12/19)`) — a placeholder token, exactly like `<name>`, never a literal string.

`status` aligns to, but is a strict **subset** of, `trace-schema.md` §1 `outcome` (`success | partial | failed | aborted`): there is no `aborted` here, because an aborted `complete`-phase session by definition never reaches the point of writing this file — at the report layer, "aborted" looks like the artifact's own absence, which the resumability rule already treats as an incomplete phase. Nothing in this contract needs a fourth value.

## 2. Core sections (validated)

The exact, ordered heading list a conforming report's core MUST contain — greppable, and the list `extensions/testing/test/run.sh` (R1-S19, §6) derives its golden assertions from:

- `## Implementation Complete — <name>`
- `### Completed (N/N)`
- `### Partial/Degraded`
- `### Failed`
- `### Integration status`
- `### Key results`

The first is a level-2 (`##`) heading; the remaining five are level-3 (`###`) headings nested beneath it — there is exactly one `##` heading in the core (§6 rule 5).

| Section | Required content |
|---|---|
| `## Implementation Complete — <name>` | The run's shape: waves run, widest parallel wave, and a roster summary — which specialists/skills executed (FR-004). |
| `### Completed (N/N)` | The completed-task record: `N` of `N` tasks done, with enough detail (typically a table) to see which. |
| `### Partial/Degraded` | Detail for any task that finished partial or degraded. **Present even when there are none** — the body may simply say so; the heading itself is never omitted (§6 rule 3). |
| `### Failed` | Detail for any failed task. **Present even when there are none**, same rule. |
| `### Integration status` | The end-to-end / integration claims this run makes — the section `testing.md`'s coverage map grounds on (FR-008, `docs/contracts/testing-doc.md`). The most load-bearing section for the downstream phase. |
| `### Key results` | The headline outcomes worth surfacing without reading the rest of the report. |

## 3. Optional appendix (not validated)

The **only** additional top-level sections a completion report may carry, and only a dogfood / milestone-close build (a feature that closes out a `docs/05` milestone) needs them — a generic feature has no milestone to close and omits both (edge case, spec.md):

- `## Milestone-close context`
- `## Decisions & log`

Nothing inside them is checked by this contract — their internal structure is free-form. Precedent (`specs/003-workforce/completion-report.md`) nested `### <M-N "Done when">`, `### Findings adjudicated`, `### Deferred / carried`, `### Next steps` under the first, and closing prose under the second; that shape is illustrative, not mandated. A future contract revision may normalize it if a second dogfood build needs the same structure enforced — not this version.

Presence is optional in both directions: a report may carry neither, one, or both — validation (§6) does not change.

## 4. Two contract files, not one (R1-S16)

This is **one of two** separate sibling schema files — the other is `docs/contracts/testing-doc.md`, the `testing` phase's `testing.md` contract. They are **not merged**: `docs/contracts/` holds one schema per file (this is the eighth such file; `testing-doc.md` is the ninth), and a combined file would be the first exception to that convention across all of them. The coupling between the two artifacts — the `testing` phase reads this report (`artifact-layout.md` §2) and grounds its coverage map in `### Integration status` (FR-008) — is carried by this cross-reference, a pointer, not by co-locating both schemas in one file (D46 rule 3; ratified by council, `council/decision-record.md` R1-S16).

## 5. Relationship to the D19 envelope (FR-005)

This file — frontmatter and body, core and any appendix, exactly as written to disk — **is** the `artifact.body` of the `complete`-phase `phase.completed` event (`trace-schema.md` §6), with **no reshaping**. The frontmatter `status` is that event's `status` field, unmodified. The event is idempotent on `artifact.sha256` — this file's own bytes — so re-sending it is safe by construction; nothing in this format may make identical `tasks.md` / `implement.log.md` inputs produce different bytes on a re-run (a wall-clock timestamp embedded in prose is fine; anything that would defeat sha256-idempotency is not). Building the M5 MCP push itself is out of scope here (M5); this contract is what makes the body well-formed and replayable now.

## 6. Validation

A completion report conforms iff:

1. Frontmatter parses as YAML; `feature`, `phase`, `status` are all present. `phase == "complete"`. `status ∈ {success, partial, failed}` — exact, lowercase, no other value (FR-003) — and is never `success` when any task in the run finished partial or failed (spec.md US1 scenario 2).
2. All six §2 core sections are present, spelled exactly as §2 lists them, in that exact top-to-bottom order (SC-001).
3. `### Partial/Degraded` and `### Failed` are present even when the underlying condition is empty — omitting the heading is a validation failure regardless of whether the condition it describes is empty.
4. The document validates **identically with or without** the §3 appendix present (SC-005): a report with neither appendix section, and a report with both, pass the same check.
5. The **only** top-level (`##`) headings permitted anywhere in the document are the one core heading (`## Implementation Complete — <name>`) plus zero, one, or both of the §3 appendix headings. Any other `##` heading is a validation failure — this is the mechanism that keeps the core **exactly** the set FR-004 names.
6. `status == "partial"` ⟹ `### Partial/Degraded` is non-empty (some body text beyond the heading); `status == "failed"` ⟹ `### Failed` is non-empty — the section carries the detail the status claims exists (spec.md US1 scenario 2). The converse does not hold: `status == "success"` does not forbid a non-empty `Partial/Degraded` or `Failed` section — a run can succeed overall while still narrating handled partial hiccups (`003`'s own precedent).
7. Nothing inside `## Milestone-close context` or `## Decisions & log` is checked (§3).

**Machine-checkability (R1-S19).** §2's and §3's bulleted heading lists above are the **only** place this contract's section set is stated. `extensions/testing/test/run.sh`'s golden assertions are derived by reading those two lists directly out of this file — never hand-copied into a parallel list inside the validator's own source — so the contract and its validator cannot silently diverge. An edit to the section set is made here first; the validator picks it up on its next run.

## 7. Non-goals (v1)

- **No test execution or pass/fail results.** This report is the `implement` phase's account of what ran; whether it was later *verified* is `testing.md`'s job — a separate contract (§4), doc-only in v1 (I-3).
- **No relaxation of the resumability rule.** This contract adds structure; it does not change `artifact-layout.md` §3 — the report still must exist **and** validate for the `complete` phase to read as done.
- **No schema for the appendix's internal structure.** Free-form by design (§3).
- **No cross-feature aggregation.** One report per feature (`artifact-layout.md` §2); a rollup across features is a central-manager (M5) concern, not this contract's.
