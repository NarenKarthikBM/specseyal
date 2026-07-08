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
