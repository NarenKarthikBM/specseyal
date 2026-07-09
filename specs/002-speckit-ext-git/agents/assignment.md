# Agent Assignment — speckit-ext-git

> **Manual pass (agent-assign phase run by hand).** The agents extension (assigner + skill builder) ships in M3; until then the roster is assembled by hand from `categorization.md`, exactly as `001` did (artifact-layout §8 bootstrap note). **Owner**: agents extension — `agents/assignment.md` only. The `## Workforce Gate` section below is the **human's** decision artifact (D32): **`approved-with-notes`** (Babu, 2026-07-09) — Phase 4 implement proceeds under the **four binding notes** recorded below.

## Roster derivation

Each task's `(type, specialization)` from `categorization.md` selects one **base specialist**; tasks sharing a base assemble to one agent (§8 W1). **No skills are injected**: the per-repo skill library and its builder are M3 (D17/D40), so v1 agents are **base specialists only** — the `tags` in `categorization.md` are recorded for future injection but select nothing yet (same posture as `001`'s M1 build). **Models per D18**: the 7 implementation types (`scaffold/service/endpoint/infra/test`; `data-model/ui` unused) sit on the **mandatory Sonnet floor** (agent-library-schema §4); the `docs` tasks take **Sonnet** too under D18's generative-role rule — so **every dispatched agent is Sonnet**. The main-thread orchestrator (`/speckit-implement-parallel`) is **Opus** (D18), but it is the driver, not an assembled subagent, so it is not a roster row. **D48 prompt-tag guard: not engaged** — `categorization.md` assigns the `prompt` tag to zero tasks (zero-AI extension, no LLM-rendered templates), so no docs-typed task can escape the Sonnet floor.

## Concurrency & serialization (from `tasks.md` ## Execution Waves)

- **Widest parallel wave = 4** (Wave 6: T008/T011/T015/T016; Wave 7: T009/T012/T014/T017). Proposed dispatch cap: **≤4 concurrent** (the human may tighten to `001`'s **max-3** discipline as an override).
- **Shared/mutable — orchestrator glue, never a parallel subagent** (graphify-context.md collision list): `.specify/extensions.yml` (T006/T007), `specs/002-.../graphify-context.md` (T019/T020), `extensions/git/test/run.sh` (T021/T022). All pinned serial in the DAG.

---

## Workforce Gate — 2026-07-09T15:57:50Z

| Field | Value |
|---|---|
| reviewer | Babu |
| decision | `approved-with-notes` |
| reviewed | `tasks.md`, `assignment.md` (roster) |

### Roster approved

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
| T001, T002, T005 | `scaffold × devtools-cli` specialist | Sonnet | none *(no M3 library)* | none |
| T003, T004, T019, T020 | `docs × devtools-cli` specialist | Sonnet | none | none |
| T006, T007 | `infra × devtools-cli` specialist | Sonnet | none | none |
| T008 | `service × devtools-cli` specialist | Sonnet | none | none |
| T009, T011, T015, T016, T017 | `endpoint × devtools-cli` specialist | Sonnet | none | none |
| T010 | `endpoint × ai-agents` specialist | Sonnet | none | none |
| T012, T014 | `service × security` specialist | Sonnet | none | none |
| T013 | `endpoint × security` specialist | Sonnet | none | none |
| T018 | `infra × ai-agents` specialist | Sonnet | none | none |
| T021, T022, T023 | `test × qa-automation` specialist | Sonnet | none | none |

*10 assembled base agents · 23 tasks · every task in exactly one row (§8 W1) · **elevated grants: none** across the whole roster (§8 W2 — the core toolset `{Read, Write, Edit, Bash, Glob, Grep}` covers all shell/git/file work; no task needs `web_search`, network, or any grant beyond core).*

**Notes:** *(binding on Phase 4 implement)*

1. **Spike timebox confirmed** — T018 hard-capped at **≤2h**; outcome recorded either way per D25 — a spike concluding "worktrees don't pay" is a **success, not a failure**. Timebox D-row booked at gate-close (**D54**).
2. **Width-4 approved, no cap-down to `001`'s max-3.** Rationale for the record: `[P]` rests on the file-disjointness fallback here (I-13 — no graph nodes for `.sh`/`.yml`), but **disjoint NEW-file sets are the strong case** of that fallback: new files cannot collide with anything existing. The genuinely collision-prone surfaces (`.specify/extensions.yml`, `test/run.sh`) are already serialized as orchestrator glue per taxonomy §2.1 — where the actual risk lived.
3. **Bootstrap discipline binding on this build** — `002` implements commit-before-`[X]` (T010/S06) and wave-boundary gate-freshness (S23); **until its own waves land those mechanisms, the orchestrator performs both BY HAND at every wave.** The last manual performance of the rituals this feature automates.
4. **Gate-close hygiene precedes Wave 1** — the `docs/90` session-log row for Phase 3 and the spike-timebox D-row (D54) are committed as part of the `gate(002)` boundary, not deferred past it.

**Overrides:** none.
