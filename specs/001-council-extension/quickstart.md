# Quickstart — validating speckit-ext-council

Runnable validation scenarios that prove the feature works end-to-end. Implementation detail lives in `tasks.md`; this is the run/verify guide.

## Prerequisites

- Spec-kit + graphify installed in the repo (already true here, D45).
- A feature with a completed `plan.md` (the live target is **M2's plan**, per the dogfooding boundary).
- `ANTHROPIC_API_KEY` unset (D28) — verify with `echo $ANTHROPIC_API_KEY` (empty).

## Install

```sh
bash extensions/council/install.sh .
# expect: 3 skills → .claude/skills/{speckit-council,speckit-council-triage,speckit-council-approve}/
#         extension → .specify/extensions/council/
#         idempotent: re-run is a no-op; uninstall.sh removes cleanly
```

## Scenario 1 — happy path (SC-001, SC-002)

```sh
/speckit-council            # on a feature whose plan.md exists
```
**Expect**: `council/defense-deck/{technical,overview}.md`, `council/round-1/opinions/{A..E}.md` + `peer/{A..E}.md`, `council/round-1/suggestions.md` (classified, ID'd). Then:
```sh
/speckit-council-triage     # applies accepted; writes decision-record.md
/speckit-council-approve approved
```
**Verify**:
- `decision-record.md` has a Round-1 table (every suggestion dispositioned) + a `## Human Gate` section → `/speckit-tasks` unlocked.
- **SC-002**: `council_spend = phase_spend(council) + phase_spend(deck-prep)` computed from `traces.jsonl` — the first observability datapoint. *(See Risk R1: exact tokens depend on the Agent-tool usage metadata.)*

## Scenario 2 — context hygiene (SC-005)

```sh
grep -rl "opinions/" specs/NNN-feature --include="*.md" | grep -v "/council/"
# expect: NO output (only council/ files may name the opinions/ path)
```

## Scenario 3 — blocking → one revision cycle (SC-004)

Seed a plan with a deliberate blocking flaw (e.g., a bundled migration + schema change). Run `/speckit-council` → `/speckit-council-triage`.
**Expect**: chairman classes ≥1 suggestion `blocking`; triage runs **exactly one** revision + a `### Chairman delta check` (not a second full council); the decision record shows the delta check.

## Scenario 4 — reduced grounding (FR-019, SC-008)

```sh
mv graphify-out graphify-out.bak && /speckit-council ; mv graphify-out.bak graphify-out
```
**Expect**: the run still completes; `suggestions.md` opens with `> ⚠ Reduced grounding: no graph`; the decision record's round header carries the same flag — visible at the gate.

## Scenario 5 — decision-record conformance (SC-003, US3)

Run the contract verifier (I-11) against `decision-record.md`:
**Expect**: every suggestion id appears once with one disposition; every `rejected`/`deferred` has non-empty rationale; accepted `blocking` names its commit. Zero silent drops.

## Scenario 6 — reopen interface (FR-017)

```sh
/speckit-council --reopen delta      # context = plan diff + a supplied finding
```
**Expect**: a `## Reopen` section (tier=delta) in the decision record; the round reviews only the diff + finding.

## Done when

- [ ] Scenarios 1–6 pass on M2's plan (the live exercise).
- [ ] `council_spend` is a real number in the completion report (M1 exit).
- [ ] All `council/` artifacts validate against the M0 contracts.

## M1 conformance status (static — the extension is built; the live run is M2)

Verified at M1 build time (Wave 8, static — no council has *run* yet; the human was the council for 001's own plan):

- **Extension inventory complete** — installer + uninstaller + 3 command skills + 5 templates + trace-fragment + config + manifest + 3 provenance stubs + spike doc + 2 READMEs (19 files). Installer verified idempotent + clean uninstall against a synthetic target (T018).
- **SC-003 shape** — 001's `council/decision-record.md` carries every required section (Metadata, Round, Human Gate, Carried Constraints) and validates against `decision-record.md`.
- **SC-006 shape** — `trace-fragment.md` conforms to `trace-schema.md` 1.2 (`capture_method`, exact-or-null, serial append).
- **SC-005 — meta-feature caveat.** The blunt rule-5 grep (`opinions/` outside `council/`) trips on 001's *own* spec / plan / data-model / contracts / tasks / quickstart — because 001 **is** the council extension and necessarily *describes* the `opinions/` mechanism. That is a design description, **not** a runtime leak of opinion *content*; the runtime invariant (status-only returns; no opinion bodies in the main thread) is enforced by `speckit-council/SKILL.md`. A normal processed feature's spec never mentions `opinions/`. **The I-11 conformance checker should exempt the council's own feature** (or distinguish "describes the path" from "leaks content").

Deferred to **M2's exit test** (the first live council run, on M2's plan): SC-001 (full loop end-to-end), SC-002 (measured `council_spend`), SC-004 (one-revision convergence), SC-006 live traces, SC-008 live reduced-grounding.

### SC-002 reporting shape (D47)

The completion report / observability MUST print, per feature:

```
council_spend = <tokens_billable over the council + deck-prep phases>   (capture_method: unavailable × <n> records)
```

— the count of `unavailable`-token records reported **alongside** the sum, so an interactive measurement states its own completeness rather than presenting a lower bound as the whole (D47). The spike (T005) found `capture_method: transcript` is feasible interactively, so this count should be 0 for a well-behaved run.
