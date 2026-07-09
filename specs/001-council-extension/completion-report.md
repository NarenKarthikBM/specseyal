# Completion Report — 001-council-extension (`speckit-ext-council`)

> The `complete`-phase artifact for the M1 dogfood build. Format: dev-orchestrator completion report
> (`speckit-implement-parallel`) + milestone-close context. No trace is written for this phase
> (interactive build session predates the tracing capability — D46).

## Implementation Complete — speckit-ext-council

**Waves run: 8** (widest parallel wave: **3** agents — the three command skills, Wave 5).
**Roster:** 13 Sonnet implementation agents (max 3 parallel, **zero elevated grants**) + 4 orchestrator-glue tasks. Committed at every wave boundary (`c990682` … `6bb913c`).

### Completed (20 / 20)

| Wave | Tasks | Outcome |
|---|---|---|
| 1 | T001 | Installer + uninstaller (mirror graphify, no hook-merge; idempotent) |
| 2 | T002–T004 | `extension.yml` (3 commands, no hooks), `council-config.yml` (5 members + lenses + D18 map), 2 READMEs |
| 3 | T005 | **Token-capture spike — SUCCESS** (`capture_method: transcript` feasible) |
| 4 | T006–T011 | 6 templates: trace-fragment (1.2), deck-technical, deck-overview, member-prompt (`{{lens}}`), chairman-prompt (synthesis + delta-check), suggestions |
| 5 | T012, T014, T016 | The 3 command skills: `/speckit-council`, `-triage`, `-approve` |
| 6 | T013, T015, T017 | 3 command provenance stubs |
| 7 | T018 | Installer verification (idempotent install / clean uninstall vs synthetic target) |
| 8 | T019, T020 | Static conformance + quickstart/README finalize (SC-002 reporting shape) |

### Partial / Degraded
None.

### Failed
None.

### Integration status
- **Installer**: install → re-install (idempotent) → uninstall (clean), `.specify/` preserved (T018). ✅
- **Manifest ↔ stubs ↔ skills** consistent: `extension.yml` `file:` refs match the 3 provenance stubs and the 3 skill dirs. ✅
- **Cross-skill contracts** consistent: the reopen split (council *invokes*; triage writes `## Reopen`) and the `auto`-mode assignment (triage writes the gate; approve verify-only) agree across skills. ✅
- **Context hygiene** (SC-005) enforced in code: members/chairman return status-only; the orchestrator reads only `suggestions.md`. ✅
- **Contract shapes** (static): `decision-record.md` (SC-003) and `trace-fragment.md` (SC-006, trace-schema 1.2) conform. ✅
- No `ANTHROPIC_API_KEY` usage anywhere; the one mention is a D28 guard. ✅

### Key results
- **Spike (R1/S1) resolved on the good side**: interactive transcripts expose per-subagent usage (4 token fields + `isSidechain`) → SC-002 can be an **exact** interactive measurement (`capture_method: transcript`), with `sdk` at M6 and `unavailable`+null only on attribution failure.
- **All Phase-5 deliverables present**: 3 commands · technical + non-technical decks (D15) · Claude-only bench, 5 Sonnet lensed members + Opus chairman (D12/D18) · graphify receipts tool in members (D10) · one-round convergence + chairman delta-check (D13) · decision-record writer (R1–R7) · per-session traces with `skills`/`elevated_grants`/`capture_method`.

## Milestone-close context

### M1 "Done when" (docs/05) — status
docs/05's exit criterion — *"a real feature's plan survives deck → council → triage → human gate end-to-end, artifacts committed, and council token spend per feature is measured"* — is by design the **M2 exit test**: the council's **first live review is M2's plan** (the dogfooding rule; the human was the council for 001's own bootstrap plan). At M1 the extension is **built and verified-installable**; the live loop + measured `council_spend` (SC-001/002/004, live SC-006/008) run at M2.

### One M2-setup step
`bash extensions/council/install.sh .` — installs the 3 command skills into the repo, going live (not done in M1 to avoid duplicating source into `.claude/`/`.specify/` prematurely).

### Deferred / carried
- **Dynamic conformance** (SC-001/002/004, live traces & reduced-grounding) → M2's first live run.
- **I-11** conformance checker must exempt the council's own feature from rule-5's `opinions/` grep (meta-feature false positive).
- **I-12** workforce-gate record format is undefined in the contracts (bootstrap gate recorded as a flagged addendum).
- **D48** M3 assignment guard: `prompt`-tagged tasks keep the D18 Sonnet floor.

### Next steps
1. **Human review** of this exit posture (in progress).
2. **M2** (`speckit-ext-git`): build it through the pipeline — and its plan becomes the council's **first live review** (M1's true exit test), producing the first measured `council_spend`.
3. Fold M1's evidence into the taxonomy §8 v0→v1 review (first non-graphify feature categorized; `ai-agents`/`devtools-cli` exercised; `endpoint`/service and prompt-type frictions).

## Decisions & log
D45–D48 recorded; I-12 filed; I-11 refined; per-phase session-log rows in `docs/90`. This report is the `complete` phase output; `testing.md` (M4) is out of M1 scope.
