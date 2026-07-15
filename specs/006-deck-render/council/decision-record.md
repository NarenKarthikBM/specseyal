# Decision Record — 006-deck-render

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).

## Metadata

| Field | Value |
|---|---|
| feature | `006-deck-render` |
| spec-id | `006-deck-render` |
| profile | `gates.council=human, gates.workforce=human` |
| rounds-run | 1 |
| schema-version | `1.0` |

---

## Round 1 — 2026-07-15T07:01:19Z

> ⚠ Reduced grounding: no graph

**Verdict:** 5 blocking · 9 strong · 3 consider
**Deck reviewed:** `council/defense-deck/technical.md` @ `bc49fa7`
**Plan reviewed:** `plan.md` @ `17f4405`

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | blocking | Split the "unreadable/unparseable `profile.yaml`" case out of the silent-`none` branch — it must fail loudly, not resolve to `none`; the spec authorized only absent⇒`none` and out-of-enum⇒fail, and routing the worse malformed-input signal to the quieter outcome is what SC-008 forbids. | accepted | Real defect, 4/5 members + peer, checkable against committed text. Applied as invariant **I-B1** (three-branch resolution; unreadable ⇒ loud non-`none` exit, writes nothing) + `contracts/commands.md §1` amendment + a distinct `profiles/unreadable.yaml` fixture in Phase C. Delta-check: RESOLVED. | `plan.md §Implementation approach (Phase B)` @ `f98781d` |
| R1-S02 | blocking | Commit an asymmetric good-deck+broken-deck fixture under `deck_render: both` to assert the exit-2 partial-failure branch mechanically, not "verify by hand once". | accepted | Unanimous (5/5 + peer); the enum guard already gets an adversarial fixture, so a branch central to O3/SC-004 must too. Applied as a Phase C asymmetric-`both` fixture (render-good / fail-broken / disclose-both / exit-2) + a `deck-broken/` fixture dir in Project Structure. Delta-check: RESOLVED. | `plan.md §Implementation approach (Phase C)` @ `f98781d` |
| R1-S03 | blocking | Name the per-deck loop's isolation guarantee among the invariants: an exception on deck N must not prevent deck N+1 from being attempted and disclosed — today only implied by "for each selected deck, in order". | accepted | Exit-2 and O2 both silently depend on it; a first-deck failure aborting the loop would collapse exit 2 into exit 4 by omission. Applied as invariant **I-B2**. Delta-check: RESOLVED. | `plan.md §Implementation approach (Phase B)` @ `f98781d` |
| R1-S04 | blocking | Make the render write atomic (temp file in target dir, `os.replace()` on full success) and add a fixture forcing failure *during* the transform/write, not just at the pre-write import check — O5 promises "never a partial file" but the described mechanism streams the zip straight to the final path after deleting the prior render. | accepted | A crash/SIGKILL/disk-full mid-write leaves a truncated `.pptx` where the human reads next, prior good render already gone; the one forced-failure test trips before the write. Applied as invariant **I-B3** (atomic `os.replace`) + a Phase C mid-write failure test asserting no partial file / prior render untouched. Delta-check: RESOLVED. | `plan.md §Implementation approach (Phase B)` @ `f98781d` |
| R1-S05 | blocking | Make the exit-code table exhaustive over `deck_render: both` — the contract maps only 3 of 6 per-deck-pair outcomes; `rendered+skipped` and `failed+skipped` are unmapped, leaving observable spec-bound behavior to whatever `render.py` happens to do. | accepted | Directly verifiable from contract text, no grounding needed. Applied as invariant **I-B4** mapping all six outcomes, pinning `rendered+skipped ⇒ 0` and `failed+skipped ⇒ 2` in `contracts/commands.md §4`. Delta-check: RESOLVED. | `plan.md §Implementation approach (Phase B)` @ `f98781d` |
| R1-S06 | strong | Have SC-003's fidelity check assert block *sequence*, not just presence — substring/containment tests can't catch a content-present-but-reordered defect, though T5/T10 promise source order. | accepted | A real hole in an otherwise-strong independent-extractor design (member + peer). Applied to the Phase C SC-003 bullet: assert extracted blocks appear in source order, with an explicit "ordering rests on code review" fallback only if mechanically impractical. | `plan.md §Implementation approach (Phase C)` @ `f98781d` |
| R1-S07 | strong | Resolve SC-007's committed-suite status now — commit the staleness check to `test/run.sh` (fully mechanizable: recompute sha256, assert mismatch) or state why it's excluded. | accepted | Staleness visibility is load-bearing for FR-003/FR-008 and needs no human judgment. Applied: Phase C commits the SC-007 staleness check (recompute sha256, assert mismatch, assert the `STALE` verdict fires). | `plan.md §Implementation approach (Phase C)` @ `f98781d` |
| R1-S08 | strong | Confirm (or make) the frozen fixture deck actually exceed T7's line budget so the `(cont.)` continuation branch is forced by a committed fixture — the risk register rates table-cell overflow High and names T7 as the mitigation. | accepted | The mitigation for the register's highest-likelihood risk was asserted but not demonstrably reachable. Applied: Phase C confirms the fixture exceeds T7's budget (a cell is extended until it does) with provenance recorded. | `plan.md §Implementation approach (Phase C)` @ `f98781d` |
| R1-S09 | strong | Specify the footer stamp's SHA length and confirm SC-007 works from it — data-model.md defines an abbreviated stamp but never bounds it, and truncating to a git-abbreviation-like 7–8 hex reintroduces the exact confusion research.md R3 exists to prevent. | accepted | R3's whole sha256-over-commit-SHA argument rests on length-distinguishability. Applied as invariant **I-B5** (full 64-hex sha256, never truncated; SC-007 operates on it) + a Summary clarification. | `plan.md §Implementation approach (Phase B)` @ `f98781d` |
| R1-S10 | strong | State what the committed suite does when `python-pptx` is absent on the host running it — research.md R2 confirms it absent on the dev host and there's no CI, so a silent no-op would make "SC-003 is committed" true in name only. | accepted | Raised only in peer review; no member caught it — the mirror image of the well-covered SC-004 arm. Applied to Technical Context (Testing): the SC-003 arm hard-fails with an install demand + non-zero exit when the library is missing, never a silent exit 0. | `plan.md §Technical Context` @ `f98781d` |
| R1-S11 | strong | Add a minimal co-install/reinstall test against a realistic `005`-plus-`006` `.specify/extensions.yml` state — both extensions merge into the same `installed:` list, a collision the deck names as un-instrumented and SC-010's matrix doesn't target. | accepted | Cheap; converts a disclosed risk into an asserted one. Applied to Phase C SC-010: a combined `005+006` manifest, asserting install/uninstall round-trips it byte-identically without disturbing `005`'s entries. | `plan.md §Implementation approach (Phase C)` @ `f98781d` |
| R1-S12 | strong | Name one canonical source of truth for the closed enum `{none, technical, overview, both}` — today it lives independently in `profile-schema.md` prose and in `profile_key.py`, with nothing naming which is authoritative (the same drift shape as `council_tier: standrad` degrading silently). | accepted | Structurally the very precedent the plan cites as cautionary. Applied to Project Structure: the enum is defined once in `profile_key.py` and exported; contract docs are generated-from/asserted-against it, with a Phase C drift fixture. | `plan.md §Project Structure` @ `f98781d` |
| R1-S13 | strong | Give SC-007's staleness signal a form the feature's persona can use — a reader on a phone or projecting in a meeting can't eyeball-compare two 64-char hex strings; a rendered STALE/FRESH verdict would close it. | accepted | Even where the check is performed, the disclosure is unusable by the audience it was built for. Applied as invariant **I-B6** (`render.py` emits a `FRESH`/`STALE` stdout verdict, stateless read-and-compare) + a Summary note. | `plan.md §Summary` @ `f98781d` |
| R1-S14 | strong | Name, in the risk register, that `006`'s council round cannot serve as `005`'s arm-4 measurement instrument this round — spec.md books arm-4's after-measurement onto this round, but `graphify-out/graph.json` is confirmed absent for it. | accepted | The round's one genuinely original synthesis point (peer, medium); sharper than risk row 5's "scheduling matter". Applied as a new Risks row: arm-4's measurement must be scheduled onto a round that actually has a graph, which this one does not. | `plan.md §Risks` @ `f98781d` |
| R1-S15 | consider | Reconcile the two characterizations of the shared `.specify/extensions.yml` merge point, or drop the claim of contradiction (one member read §4's "un-instrumented collision risk" as contradicting the register's "no file-level dependency exists"). | rejected | Peer already rebutted the contradiction in review: the two lines answer different questions — the register's is about `006`'s *source tree* not depending on `005`'s rewrite (lifted from spec.md's Sequencing note), not about the manifest merge target — so neither is false on its own terms, and there is nothing to reconcile. The actionable half of the concern (instrument the shared `installed:`-list merge) is **R1-S11**, which is accepted and applied; adding a plan edit here would duplicate S11 or manufacture a contradiction the peer round found absent. | — |
| R1-S16 | consider | Record which commit of `extensions/council/` produced this round's mechanics alongside the round artifacts, so a mid-round rewrite of the reviewing apparatus (if `005` merges council internals in-flight) is detectable by a later reader. | deferred | Cross-cutting beyond `006`'s own source tree — it is a council-extension change (stamp the `extensions/council/` HEAD into `decision-record.md`/`suggestions.md`), not a `plan.md` edit, so it does not belong in this feature's plan. The suggestion itself invites triage to book it as an idea. Filed as **I-29** in `docs/90-DECISIONS-AND-IDEAS.md` (council-ext follow-up pile), where it resurfaces — especially live while `005` rewrites council concurrently with `006`'s rounds. | — |
| R1-S17 | consider | Fix the script count: Scale/Scope says "~2 scripts" while Project Structure lists three (`render.py`, `deck_md.py`, `profile_key.py`). | accepted | Minor, but Scale/Scope is the line asking the council to weigh scope, so it must match the tree it summarizes. Applied: Scale/Scope now reads "3 scripts". | `plan.md §Technical Context` @ `f98781d` |

### Chairman delta check — 2026-07-15T06:58:15Z

- R1-S01 — RESOLVED — I-B1 makes the unreadable/unparseable `profile.yaml` its own third branch (loud non-`none` exit, writes nothing), amends `contracts/commands.md §1`, and Phase C commits a distinct `profiles/unreadable.yaml` fixture.
- R1-S02 — RESOLVED — Phase C commits an asymmetric good+broken `both` fixture (`deck-broken/`) that mechanically asserts render-good / fail-broken / disclose-both / exit-2, replacing the "verify by hand once" check.
- R1-S03 — RESOLVED — I-B2 states the per-deck isolation invariant explicitly: an exception rendering deck N must not prevent deck N+1 from being attempted and disclosed, closing the exit-2-collapses-to-exit-4 gap.
- R1-S04 — RESOLVED — I-B3 mandates a temp-file + `os.replace()`-on-success atomic write and Phase C forces a failure *during* the transform, asserting no partial `.pptx` is left and any prior good render is untouched.
- R1-S05 — RESOLVED — I-B4 maps all six `both` per-deck-pair outcomes, pinning the two previously-unmapped pairs (`rendered+skipped ⇒ 0`, `failed+skipped ⇒ 2`) in `contracts/commands.md §4`.

**Delta verdict:** all clear, ready for the gate.

---

## Carried Constraints

*Rebuilt from every round's accepted rows; `/speckit-tasks` reads this section and nothing else from this file.*

- `R1-S01` — `profile_key.py` must resolve `deck_render` in exactly three branches: absent ⇒ `none`, out-of-enum ⇒ fail (exit 3), unreadable/unparseable ⇒ loud non-`none` failure; never fold unreadable into silent `none`. Commit a `profiles/unreadable.yaml` fixture; amend `contracts/commands.md §1`.
- `R1-S02` — Commit an asymmetric good+broken deck fixture (`test/fixtures/deck-broken/`) and a `both`-mode test asserting render-good / fail-broken / disclose-both / exit-2 mechanically.
- `R1-S03` — Implement and test the per-deck isolation invariant (I-B2): an exception rendering one selected deck must not prevent the next from being attempted and disclosed.
- `R1-S04` — Write renders atomically (temp file + `os.replace()` on success, I-B3); commit a test forcing failure *during* the transform/write and asserting no partial `.pptx` remains and any prior render is untouched.
- `R1-S05` — Map all six `deck_render: both` per-deck-pair outcomes in `contracts/commands.md §4`, including `rendered+skipped ⇒ 0` and `failed+skipped ⇒ 2`.
- `R1-S06` — SC-003's fidelity check must assert block *sequence* (source order), not just presence; state explicitly if any ordering aspect rests on code review.
- `R1-S07` — Commit the SC-007 staleness check to `test/run.sh` (recompute source sha256, assert mismatch against a stale render's stamp, assert the `STALE` verdict fires), or state in place why excluded.
- `R1-S08` — Ensure the frozen fixture deck exceeds T7's per-slide line budget so the `(cont.)` continuation branch is exercised by a committed fixture; record the provenance.
- `R1-S09` — The footer stamp is the full 64-hex sha256, never truncated (I-B5); SC-007's check operates on the full-length stamp.
- `R1-S10` — `test/run.sh`'s SC-003 fidelity arm must hard-fail with an install demand + non-zero exit when `python-pptx` is absent on the host — never a silent exit 0.
- `R1-S11` — Add a co-install/reinstall test against a combined `005`+`006` `.specify/extensions.yml`, asserting install/uninstall round-trips it byte-identically without disturbing `005`'s entries.
- `R1-S12` — Define the `{none, technical, overview, both}` enum once in `profile_key.py` and export it; generate/assert the contract docs' copies against it, with a drift fixture. No second authoritative copy.
- `R1-S13` — `render.py` emits a human-readable `FRESH`/`STALE` verdict to stdout when a prior render exists (I-B6), stateless read-and-compare — the staleness signal must be usable by the phone/meeting persona.
- `R1-S14` — Keep the Risks-register row stating `006`'s round cannot be `005`'s arm-4 measurement instrument (no graph present); arm-4's after-measurement must be scheduled onto a round with a graph.
- `R1-S17` — Scale/Scope must state the correct script count (3: `render.py`, `deck_md.py`, `profile_key.py`).
