# Decision Record — 004-testing-completion

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).

## Metadata

| Field | Value |
|---|---|
| feature | `004-testing-completion` |
| spec-id | `004-testing-completion` |
| profile | `gates.council=human, gates.workforce=human` |
| rounds-run | 1 |
| schema-version | `1.0` |

---

## Round 1 — 2026-07-12T17:23:46Z

**Verdict:** 1 blocking · 12 strong · 9 consider
**Deck reviewed:** `council/defense-deck/technical.md` @ `063d57b` (round-1; committed in the round commit)
**Plan reviewed:** `plan.md` @ `a809d79`

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | blocking | Pin the I-17 fix (verify-gate.sh edit + git-ext reinstall + survival regression) to wave-1/pre-wave **mechanically**, not as prose the tasks.md wave-DAG may violate. | accepted | **Cluster ruling (S01+S11+S12+S13+S21).** The fix runs **pre-wave, outside the tasks.md wave loop entirely** (S12 adopted as the resolution); `implement-parallel`'s pre-flight refuses wave 1 until the change + reinstall + survival regression are done. Invariant → D-row: *machinery that gates the waves is never itself a wave*. The five-lens, graph-receipted catch is exactly what D10's receipts-checking exists to surface. | plan.md §2.3 @ `9f018ad` |
| R1-S02 | strong | `/speckit-complete` re-reads tasks.md + implement.log.md from disk every invocation, not from assumed context. | accepted | Resumability (Constitution III) beats context retention — always; the assumption breaks across compaction/resume. | plan.md §1.2 @ `9f018ad` |
| R1-S03 | strong | Mechanical SC/FR-coverage validator; fail contract validation on any gap. | accepted | "100% mapped" (SC-004) becomes code, not prompt — the 003 categorization-completeness-validator precedent. | plan.md §1.3 @ `9f018ad` |
| R1-S04 | strong | Regression fixture for the unpaired insertion/deletion (task added/removed) BLOCK shape §2.2 names. | accepted | A named BLOCK case with no fixture is an untested guard (the S03/002 lesson). | plan.md §2.3 @ `9f018ad` |
| R1-S05 | strong | Mitigate the tester's second-hand-evidence mode: implement.log.md as a lazy cross-check; testing.md labels evidence source. | accepted | Report-claimed vs log-verified marking, log read on doubt (D10 pattern). Stays doc-only; gains honesty about *what* it verified. | plan.md §1.3 @ `9f018ad` |
| R1-S06 | strong | Add a context-in field to the tester trace so an SC-003 violation is auditable, or soften R2. | accepted | Strengthen the trace (context_in, D43 spirit) rather than soften the claim; R2 stands as written. | plan.md §1.3 @ `9f018ad` |
| R1-S07 | strong | Errored/empty after_complete/after_testing invocation is phase-halting. | accepted | Symmetric with `complete`'s own INCOMPLETE guarantee; 002 stop-on-nonzero lineage; no silent no-op passes SC-006/SC-009. | plan.md §1.4 @ `9f018ad` |
| R1-S08 | strong | Specify the SC-008 testing-seam reinstall-survival regression at I-17-fixture detail. | accepted | SC-006 and FR-013 both ride on this test; a "§3 model" citation is not a spec. | plan.md §1.4 @ `9f018ad` |
| R1-S09 | strong | Durable audit signal when the checkbox-delta branch produces the workforce-gate PASS. | accepted | SC-010's "zero hand assistance" leaves independently-auditable evidence — a wave-2 pass alone can't distinguish the fix from a human workaround. | plan.md §2.2 @ `9f018ad` |
| R1-S10 | strong | Two-branch golden: appendix-bearing + appendix-free completion-report, both contract-validated. | accepted | Gives SC-005's with/without-appendix claim a genuine two-branch test. | plan.md Tech Ctx (Testing) @ `9f018ad` |
| R1-S11 | strong | Add the non-circularity sentence: verify-gate's first firing checks a pristine just-bound tasks.md; wave 1's own commit is the hazard. | accepted | Folded into the cluster ruling — documented in §2.3; makes the pre-wave window provably safe. | plan.md §2.3 @ `9f018ad` |
| R1-S12 | strong | Resolve "wave 1 (or pre-wave)" to one mechanism, preferring pre-wave (outside the wave loop). | accepted | Adopted as the cluster ruling itself — pre-wave sidesteps the wave-DAG-authoring risk of S01 entirely. | plan.md §2.3 @ `9f018ad` |
| R1-S13 | strong | Both concerns' git-ext edits land in the same wave-1/pre-wave reinstall. | accepted | Folded into the cluster: one pre-wave git-ext change → one reinstall → one survival pass; bundling costs nothing. | plan.md §2.3 @ `9f018ad` |
| R1-S14 | consider | Confirm the reverse-flip `[x]`→`[ ]` BLOCK is intentional; name the recovery path. | accepted | Confirmed intentional; recovery = full re-gate (the I-16 escape stays ruled out). The direction invariant is load-bearing (see S18). | plan.md §2.2 @ `9f018ad` |
| R1-S15 | consider | Restate the I-17 rule direction-explicitly (and with the foreign-reinstall clause) wherever compressed text is trusted alone. | accepted | Wording-parity confirmation; the arrow encodes direction. | plan.md §2.2 @ `9f018ad` |
| R1-S16 | consider | Ratify the two-separate-contract-files position over merging. | accepted | **RATIFIED**: a combined file would be the first exception to the 1:1 schema-per-file convention across the seven siblings; the pointer gives cheap coupling. | plan.md §Project Structure @ `9f018ad` |
| R1-S17 | consider | Ratify `/speckit-complete` as a real command over orchestrator-inline. | accepted | **RATIFIED**: the M5 after_complete push needs a command boundary (the D68 lean confirmed); every other phase is already a `/speckit-*` command. | plan.md §1.2 @ `9f018ad` |
| R1-S18 | consider | Evaluate (with the contest noted) swapping the diff-classifier for a canonicalized-checkbox hash. | accepted | **Swap REJECTED** — peer review proved the hash direction-blind (a reverse flip would PASS), erasing the S14 invariant. The diff-classifier stays; the guard-note is recorded: **any future simplification MUST preserve the direction asymmetry** (the check's load-bearing property). | plan.md §2.2 @ `9f018ad` |
| R1-S19 | consider | Derive the testing-ext golden assertions from the contracts' own section lists. | accepted | Contract and validator cannot silently diverge — a compounding cost since these contracts are pipeline-wide. | plan.md Tech Ctx (Testing) @ `9f018ad` |
| R1-S20 | consider | Reconcile the two sequencing shapes (staged R4 vs bundled §4) for the git-ext file pair. | accepted | Reconciled to **bundled/simultaneous**, consistent with S13 (one pre-wave reinstall). | plan.md §2.3 @ `9f018ad` |
| R1-S21 | consider | Name a recovery path for a wave-DAG scheduling miss (I-17 task lands in wave 2+). | **rejected** | **MOOT by the S01/S12 cluster ruling** — the fix runs pre-wave, outside the tasks.md wave loop, so a wave-DAG scheduling miss cannot occur; there is nothing to recover from and no recovery path is needed. | — |
| R1-S22 | consider | Add docs/contracts/artifact-layout.md to the shared/mutable collision-watch set. | accepted | The plan commits a §6-ownership edit to it — you watch what you touch. | plan.md §Project Structure @ `9f018ad` |

### Chairman delta check — 2026-07-12T17:20:29Z

- R1-S01 — RESOLVED — §2.3 relocates the I-17 fix out of the `tasks.md` wave loop entirely — invoking the D-row invariant "machinery that gates the waves is never itself a wave" so it is no longer a wave-DAG node that could be misordered — and makes provisioning mechanical via `implement-parallel`'s pre-flight, which refuses to enter wave 1 until the single bundled git-ext change, reinstall, and survival-regression report are done, so the wave-2 hard-block the finding named cannot recur.

**Delta verdict:** all clear, ready for the gate

---

## Human Gate — 2026-07-12T17:43:52Z

| Field | Value |
|---|---|
| reviewer | Naren Karthik B M |
| decision | `approved` |
| reviewed | `defense-deck/overview.md`, `round-1/suggestions.md`, this record |

**Notes:** none.

**Overrides:** none.

**Binding:** plan↔SHA binding recorded at `specs/004-testing-completion/gates.yml` (git-ext-owned; FR-008/D55).

---

## Carried Constraints

> `/speckit-tasks` reads this section and nothing else from this file. One bullet per accepted suggestion — the constraints tasks.md must honor.

- `R1-S01` — the I-17 fix **and** Concern-1's git-ext seam edits are a **PRE-WAVE** unit (outside the tasks.md wave loop): one git-ext source change (verify-gate.sh checkbox-delta + commit.sh `testing` enum + after_testing/after_complete hooks) → one reinstall → one survival regression; `implement-parallel`'s pre-flight blocks wave 1 until it reports done. *Machinery that gates the waves is never itself a wave.*
- `R1-S02` — `/speckit-complete` MUST re-read tasks.md + implement.log.md from disk on every invocation.
- `R1-S03` — the testing-doc validator MUST grep every `SC-\d+`/`FR-\d+` from spec.md and fail on any coverage-map gap.
- `R1-S04` — the I-17 survival regression MUST include an unpaired insertion/deletion (task added/removed) BLOCK fixture.
- `R1-S05` — the tester MAY lazily read implement.log.md as a cross-check; testing.md MUST mark each item `report-claimed` vs `log-verified`.
- `R1-S06` — the `tester` trace MUST carry a `context_in` field (files read).
- `R1-S07` — an errored/empty after_complete/after_testing invocation MUST halt the phase (no silent no-op).
- `R1-S08` — the SC-008 seam regression MUST dispatch fixture complete/testing, assert both phase-tagged commits, and re-assert after git-ext + foreign reinstall.
- `R1-S09` — verify-gate.sh MUST emit a durable audit line when the checkbox-delta branch produces the PASS.
- `R1-S10` — the golden set MUST hold two completion-reports (appendix-bearing + appendix-free), each validated.
- `R1-S11` — §2.3's non-circularity argument (pristine first-firing) is the design's safety proof; keep it.
- `R1-S12` — the fix is pre-wave (the ruling); see R1-S01.
- `R1-S13` — both concerns' git-ext edits land in **one** pre-wave reinstall + one survival pass.
- `R1-S14` — a reverse checkbox flip `[x]`→`[ ]` MUST BLOCK; recovery is a full re-gate.
- `R1-S15` — the I-17 rule MUST be stated direction-explicitly in compressed contexts.
- `R1-S16` — two contract files (`completion-report.md`, `testing-doc.md`); no combined file.
- `R1-S17` — the `complete` phase is a real `/speckit-complete` command (the after_complete hook boundary).
- `R1-S18` — the checkbox-delta diff-classifier stays; any future simplification MUST preserve the direction asymmetry.
- `R1-S19` — the testing-ext golden assertions MUST be derived from the docs/contracts section lists.
- `R1-S20` — the git-ext sequencing is bundled/simultaneous (one pre-wave reinstall), per R1-S13.
- `R1-S22` — `docs/contracts/artifact-layout.md` is in the collision-watch set — serialize tasks touching it.

---
