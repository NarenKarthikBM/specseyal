# Decision Record — 003-workforce

> Append-only. Rounds are appended, never edited. Rejection requires reasoning (D13.5).

## Metadata

| Field | Value |
|---|---|
| feature | `003-workforce` |
| spec-id | `003-workforce` |
| profile | `gates.council=human, gates.workforce=human` |
| rounds-run | 1 |
| schema-version | `1.0` |

---

## Round 1 — 2026-07-10T17:48:11Z

**Verdict:** 2 blocking · 13 strong · 10 consider
**Deck reviewed:** `council/defense-deck/technical.md` @ `6f5c298` (round-1; committed with this record)
**Plan reviewed:** `plan.md` @ `6f5c298`

*Tier: `standard` (D56), first live run — `council_spend` 2,830,593 billable tok (`transcript`, 0 unavailable) vs the 5.25M `full` baseline (−46.1%). All 25 accepted; both blocking resolved in one revision + delta-check. Owner rulings recorded as D60/D61/D62.*

| ID | Class | Suggestion | Disposition | Rationale | Plan delta |
|---|---|---|---|---|---|
| R1-S01 | blocking | Total-order every set-typed intermediate (grant union above all) before serialization; SC-005 golden test asserts grant *order*, not membership — CPython `set` iteration is `PYTHONHASHSEED`-dependent. | **accepted** | The determinism hazard the plan invoked to reject Bash, biting Python's own `set` — a real defect in the feature's headline guarantee. Applied. | `plan.md` §Architecture & data flow, §Plan-time verifications @ `5ca7957` |
| R1-S02 | blocking | Nothing records the `workforce` binding into `gates.yml`; git-ext's `record-gate` hook is council-only and `verify-gate` fails closed → `before_implement` unreachable. Add a workforce gate-write path in git-ext source + reinstall. | **accepted** | Real completeness defect verified by 3 sources reading the installed scripts. Resolved via the S10/S13 cluster (below): git-ext generalizes `on-council-approve.sh` → gate-agnostic `on-gate-approve.sh` (own source, D57 S2; `gates.yml` stays git-ext-owned per Q1); the `workforce` extension's approve command fires `after_workforce_approve`. Reinstall + survival regression proves the wiring. | `plan.md` §Project Structure, §Architecture & data flow (step 4) @ `5ca7957` |
| R1-S03 | strong | Add a synthetic non-Sonnet fixture base so SC-006 exercises the D48 guard's `else: hard-error` branch (every seed base is Sonnet). | **accepted** | A guard whose else-branch never executes is an untested guard (D48). | `plan.md` §Plan-time verifications (SC-006 row) @ `5ca7957` |
| R1-S04 | strong | Require a generated `SKILL.md`'s tags to intersect the triggering task's tags; define behavior for a task still gapped after one build pass. | **accepted** | Else a structurally-valid skill can leave the gap provably open. Added to `validate-skill.py`. | `plan.md` §Architecture & data flow @ `5ca7957` |
| R1-S05 | strong | Pin SC-001's enforcement status explicitly (enum-closure + field-coverage code-validated, as SC-002/006 are). | **accepted** | Removes ambiguity before `assemble.py` trusts `categorization.md`'s enum values. | `plan.md` §Plan-time verifications (SC-001 row) @ `5ca7957` |
| R1-S06 | strong | Correct the "`.specify/extensions.yml` degree 15" claim (graph says degree 1); refocus the risk on the lock-free YAML merge (install order / lock / atomic rename). | **accepted** | Not a graph-computed figure (D10 receipts); the real concern is the lock-free read-modify-write. `flock`/atomic-rename + defined install order added. | `plan.md` §Project Structure @ `5ca7957` |
| R1-S07 | strong | Make the library live outside the install `rm -rf` payload; builder checks live `.claude/skills/` before naming and hard-fails/renames on collision (not a silent skip). | **accepted** | Flywheel data is user data, not extension payload — so no self/foreign reinstall clobbers a generated skill. | `plan.md` §Risks (R5), §Project Structure @ `5ca7957` |
| R1-S08 | strong | `assemble.py` itself writes the Workforce Gate table (tool-permission fact, not prose); plus a committed skill-builder integration test. | **accepted** | Converts R1's prose promise into a mechanism (the D53 lesson) and catches ranking influence. | `plan.md` §Risks (R1), §Plan-time verifications @ `5ca7957` |
| R1-S09 | strong | Add a grant-union *correctness* test with ≥2 grant-declaring skills (not just column-presence). | **accepted** | D41 stakes: assert no grant silently dropped/mis-merged. | `plan.md` §Plan-time verifications (SC-003 row) @ `5ca7957` |
| R1-S10 | strong | Fold the two extensions into one `workforce` extension exposing the commands (mirror `extensions/council/`). | **accepted** | Removes doubled install/uninstall/test surface + the cross-extension hook coupling; the natural home for S02's gate-write + S13's approve command. Clustered with S02/S13. | `plan.md` §Project Structure, §Complexity Tracking @ `5ca7957` |
| R1-S11 | strong | `agt_backend_service`/`agt_data_persistence` either meet the seeding bar or carry `provisional: true` — uneven evidence must be visible. | **accepted** | Seeded on the worked-example only, not dogfood evidence. `provisional: true` library-metadata flag added. | `plan.md` §Seed Library @ `5ca7957` |
| R1-S12 | strong | Per-SC test-coverage decision: mechanical-existence-proof SCs get committed tests; judgment-SCs documented as manual with named procedure. | **accepted (scoped)** | Only SC-004/005/006 were committed-tested; the per-SC map now states each explicitly. | `plan.md` §Plan-time verifications @ `5ca7957` |
| R1-S13 | strong | Add a dedicated workforce-approve command/event mirroring `speckit-council-approve` (the gate-write must key on the signature, not the roster draft). | **accepted** | Binding against a pre-signature draft defeats the economic guard. `/speckit-workforce-approve` added. Clustered with S02/S10. | `plan.md` §Architecture & data flow, §Project Structure @ `5ca7957` |
| R1-S14 | strong | Bind `categorization.md` freshness to `tasks.md` SHA; stale ⇒ hard-warn + re-categorize path. | **accepted** | Closes the prose-only phase-order risk for sequencing itself. | `plan.md` §Architecture & data flow @ `5ca7957` |
| R1-S15 | strong | Gap-triggered re-runs are STABLE — only the gap task's roster changes; unrelated assemblies byte-identical (FR-022 makes it checkable). Golden fixture ≥2 tasks, one gap. | **accepted** | Confirms the reshuffle is bounded; the round-1→round-2 delta is now specified + fixtured. | `plan.md` §Architecture & data flow @ `5ca7957` |
| R1-S16 | consider | Document the base type-coverage matrix; uncovered lanes route to the builder/generic by design, stated. | **accepted** | Verifies no type is unintentionally reachable only via the fallback. Matrix added. | `plan.md` §Seed Library @ `5ca7957` |
| R1-S17 | consider | Builder stamps a stale-knowledge flag (model cutoff vs target framework); pairs with the web_search decision either way. | **accepted** | S1–S3 validation is structural, not factual — a stale claim passes silently. `provenance.stale_risk` flag added; complements D60. | `plan.md` §The web_search grant @ `5ca7957` |
| R1-S18 | consider | Stamp a content-hash of the consulted base+skill set into `agents/assignment.md`. | **accepted** | Cheap, no new trace writer; makes SC-005 checkable in one line (addresses R2's no-record gap). | `plan.md` §Architecture & data flow, §Risks (R2) @ `5ca7957` |
| R1-S19 | consider | Drop the "Python introduced as a second scripting runtime" cost line — graphify already establishes Python 3. | **accepted** | Double-counting an already-installed dependency inflates the cost bar. Dropped. | `plan.md` §Technical Context, §Complexity Tracking @ `5ca7957` |
| R1-S20 | consider | `web_search` for the skill builder — owner call. | **accepted (owner ruling → D60)** | Owner GRANTS `web_search` to the builder — the system's first elevated grant: skill-declared (A-2), roster-visible (§8 W2), trace-recorded (D43); S17 stale-flag ships as complement. Retires the plan's Option-A recommendation. | `plan.md` §The web_search grant @ `5ca7957` |
| R1-S21 | consider | One shared, unit-tested `specseyal:` frontmatter-parser module used by both `assemble.py` and `validate-skill.py`. | **accepted** | A second hand-rolled parser is the same silent-divergence risk that motivated rejecting Bash. `frontmatter.py` added. | `plan.md` §Technical Context @ `5ca7957` |
| R1-S22 | consider | SC-002's test asserts file-absence (or unchanged-dir diff) directly, not just the exit code. | **accepted** | The SC is a conjunction (non-zero exit *and* no write); the write-gating half was untested prose. | `plan.md` §Plan-time verifications (SC-002 row) @ `5ca7957` |
| R1-S23 | consider | A committed script mechanically diffs each dispatch trace's `skills[]`/`elevated_grants[]` against its roster row for SC-008. | **accepted** | Replaces human inspection for a roster that could carry dozens of rows. | `plan.md` §Plan-time verifications (SC-008 row) @ `5ca7957` |
| R1-S24 | consider | Extend the SC-007 fixture to two tasks sharing one novel tag (dedup vs one-per-task). | **accepted** | The single-tag fixture can't distinguish "exactly one" from "one per task." | `plan.md` §Plan-time verifications (SC-007 row) @ `5ca7957` |
| R1-S25 | consider | Name where the self-hook-check that fires `after_categorize`/`after_agent-assign` lives (don't assume it "just works"). | **accepted** | The `after_council_approve` precedent is invoked from the registry, not its command file. Registered in `workforce/extension.yml`, dispatched by the installed registry. | `plan.md` §Project Structure @ `5ca7957` |

### Chairman delta check — 2026-07-10T17:48:11.000Z

- R1-S01 — RESOLVED — The revised plan directs `assemble.py` to total-order every set-typed intermediate — the injected-skill grant union above all — before serialization, and the SC-005 golden test now asserts a byte-identical roster including grant *order* (not just membership), closing the `PYTHONHASHSEED`-dependent iteration leak (§Architecture & data flow; §Plan-time verifications, SC-005 row).
- R1-S02 — RESOLVED — The revised plan generalizes git-ext's own-source `on-council-approve.sh` into a gate-agnostic `on-gate-approve.sh` that records `tasks.md`+`assignment.md@sha` into `gates.yml`, registers `after_workforce_approve`, and mandates a git-ext reinstall — fired by the new `/speckit-workforce-approve` command (S13) inside the single `workforce` extension (S10) — so `before_implement`/`/speckit-implement-parallel` are now reachable (§Project Structure; §Architecture & data flow, step 4).

**Delta verdict:** all clear, ready for the gate.

---

## Human Gate — 2026-07-10T18:17:25Z

| Field | Value |
|---|---|
| reviewer | Naren Karthik B M |
| decision | `approved` |
| reviewed | `defense-deck/overview.md`, `round-1/suggestions.md`, this record |

**Notes:** none.

**Overrides:** none.

**Binding:** plan↔SHA binding recorded at `specs/003-workforce/gates.yml` (git-ext-owned; FR-008/D55).

---

## Carried Constraints

> `/speckit-tasks` reads this section and nothing else from this file. One bullet per accepted suggestion — the constraints tasks.md must honor.

- `R1-S01` — `assemble.py` MUST total-order every set (grant union first) before serialization; SC-005 golden test asserts grant order.
- `R1-S02` — git-ext gets a gate-agnostic `on-gate-approve.sh` (own source) + `after_workforce_approve` hook; reinstall + survival-test the workforce gate-write path.
- `R1-S03` — SC-006 test includes a synthetic non-Sonnet fixture base so the D48 guard's error branch executes.
- `R1-S04` — `validate-skill.py` requires a generated skill's tags to intersect the triggering task's tags; define still-gapped-after-one-pass behavior.
- `R1-S05` — `validate-categorization.py` code-validates enum-closure + field-coverage (SC-001), stated as such.
- `R1-S06` — installer YAML hook-merge uses `flock`/atomic-rename + a defined install order (git before workforce); drop the "degree 15" framing.
- `R1-S07` — the library lives outside the install `rm -rf` payload; builder checks live `.claude/skills/` before naming, hard-fails/renames on collision.
- `R1-S08` — `assemble.py` itself writes the Workforce Gate table; add a real-skill-builder integration test on a gap fixture.
- `R1-S09` — grant-union correctness test with ≥2 grant-declaring skills.
- `R1-S10` — one `extensions/workforce/` tree exposing categorize + agent-assign + approve.
- `R1-S11` — `agt_backend_service`/`agt_data_persistence` carry `provisional: true` in library metadata.
- `R1-S12` — every mechanical-existence-proof SC gets a committed test; judgment-SCs documented manual with a named procedure.
- `R1-S13` — `/speckit-workforce-approve` command records the signature and fires the gate-write.
- `R1-S14` — `categorization.md` records its source `tasks.md` SHA; stale ⇒ hard-warn + re-categorize.
- `R1-S15` — gap-rerun stability: only the gap task's row may change; ≥2-task one-gap golden fixture.
- `R1-S16` — publish the base type-coverage matrix; uncovered lanes → `agt_generic` by design.
- `R1-S17` — builder stamps `provenance.stale_risk: true` when authoring post-cutoff without searching.
- `R1-S18` — `assemble.py` stamps a library-snapshot content-hash into the roster.
- `R1-S19` — no Python "new runtime" cost line (already a graphify dependency).
- `R1-S20` — the skill builder declares `grants: [web_search]` (D60); surfaces on the roster, recorded in traces.
- `R1-S21` — one shared, unit-tested `frontmatter.py` consumed by both scripts.
- `R1-S22` — SC-002 test asserts file-absence directly.
- `R1-S23` — a committed script diffs dispatch traces against roster rows (SC-008).
- `R1-S24` — SC-007 fixture: two tasks sharing one novel tag.
- `R1-S25` — the `after_*` self-hook-check is registered in `workforce/extension.yml`, dispatched by the installed registry.
- `D62` — add the deck-prep-improvement task (mine member transcripts for pulled `plan.md` sections; enrich the deck-prep template in council source; reinstall).
