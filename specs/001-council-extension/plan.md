# Implementation Plan: speckit-ext-council — Plan Defense Council

**Branch**: `001-council-extension` | **Date**: 2026-07-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-council-extension/spec.md`

## Summary

Build `speckit-ext-council`: a Spec Kit extension that convenes an adversarial council on every `plan.md` before task breakdown. It ships **three command skills** (`/speckit-council`, `/speckit-council-triage`, `/speckit-council-approve`), **markdown deck templates** (technical + one-page overview), a **Claude-only member bench** (5 Sonnet members + 1 Opus chairman) run as subagents, a **graphify query tool** wired into members for receipts-checking, **one-round convergence** with a chairman-only delta check, a **decision-record writer**, and **per-session trace emission**. It is packaged exactly like `extensions/graphify/` and dogfoods that extension's proven "orchestrator dispatches per-unit subagents, reviews compact returns" pattern (`speckit-implement-parallel`).

The technical spine is **the compression boundary**: the main thread coordinates the subagents but never ingests opinion bodies — only the chairman's `suggestions.md` returns as content. Everything else follows from the M0 contracts.

## Technical Context

**Language/Version**: Markdown skill/command definitions + POSIX `sh` installer. No compiled code. (Same class as `extensions/graphify/`.)
**Primary Dependencies**: Claude Code (subagents via the Agent tool; skills loader), Spec Kit ≥ 0.12 (`.specify/` structure, `check-prerequisites.sh`), the installed `graphify` CLI (member receipts-checking, `query`/`explain`/`path`).
**Storage**: Files in the repo — the `specs/NNN/council/` artifact subtree (`artifact-layout.md` §1). No database.
**Testing**: Contract-conformance checks (I-11 verifier) against `decision-record.md` / `trace-schema.md`; an end-to-end dogfood run (SC-001); a `grep` invariant for context hygiene (SC-005).
**Target Platform**: Claude Code CLI now; the same `.claude/` skills load unchanged under the Agent SDK orchestrator (M6, D4).
**Project Type**: Spec Kit pipeline extension (CLI layer) — sibling of `extensions/graphify/`.
**Performance Goals**: Not latency-bound. The governing metric is **token spend** — `council_spend` per feature (SC-002), the M1 exit datapoint.
**Constraints**: Subscription auth only, `ANTHROPIC_API_KEY` unset (D28); Claude-only bench (D12); markdown decks (D15); exactly one full round (D13); D18 model map; all artifacts conform to the M0 contracts.
**Scale/Scope**: One council round = 1 deck-prep + 10 member sessions (5 members × 2 stages) + 1 chairman + 1 triage = ~13 sessions. v1 targets a single feature's plan per run.

## Constitution Check

*GATE: must pass before Phase 0; re-checked after design. Ref `.specify/memory/constitution.md`.*

| Principle | How this plan satisfies it | Verdict |
|---|---|---|
| **I. Artifacts are the contract** | Each command writes exactly one artifact class: `/speckit-council` → `defense-deck/` + `round-N/suggestions.md`; triage → revised `plan.md` + `decision-record.md`; approve → `decision-record.md` gate section. No command mutates another's artifact. | ✅ PASS |
| **II. Context hygiene** | Deck-prep, each member, and the chairman are **subagents** (separate sessions). Members return compact statuses (a path + one-line outcome), never opinion bodies. Only the chairman's `suggestions.md` returns to the main thread as content — the compression boundary. | ✅ PASS |
| **III. Resumability** | Phase state is inferred from artifacts: deck exists → deck-prep done; `suggestions.md` exists → council done; `decision-record.md` has a `## Human Gate` → gate done. No state file. A killed run resumes by re-reading the tree. | ✅ PASS |
| **IV. Observability** | Every session (deck-prep, 10 member, chairman, triage) emits one trace record; the orchestrator assembles them serially into `traces.jsonl` (avoids the parallel-append race). `council_spend` is computed per `trace-schema.md` §5. | ✅ PASS (see Risk R1 on token capture) |
| **V. Subscription-only billing** | No API keys anywhere; the member bench is Claude subagents on subscription auth. `cost_usd` stays `null`. | ✅ PASS |
| **Model policy (D18)** | chairman = Opus (xhigh); members + deck-prep = Sonnet; triage = Opus (main thread). Encoded in `council-config.yml`; recorded in every trace. | ✅ PASS |
| **Autonomy & gates (D9)** | The council gate is `human` by default; `/speckit-council-approve` is the gate writer; `auto` mode (only under `full_auto`) has triage write the gate section — the council still convenes. | ✅ PASS |

**Result: PASS, no violations.** Complexity Tracking is therefore empty.

## Chosen Approach

### A. Packaging (mirror `extensions/graphify/`)

`extensions/council/` with an idempotent `install.sh` (copy `extension/` → `.specify/extensions/council/`, skills → `.claude/skills/`) and `uninstall.sh`. **Simpler than graphify's installer**: the council registers **no `before_*` hooks** (it is command-invoked, not a pipeline hook), so the PyYAML hook-merge machinery is dropped — only the `installed:` list is touched, if anything.

### B. The three command skills

| Command | Session(s) it drives | Reads | Writes |
|---|---|---|---|
| **`/speckit-council`** | deck-prep (1×Sonnet) → members stage 1 (5×Sonnet ∥) → members stage 2 (5×Sonnet ∥) → chairman (1×Opus) | `plan.md`, `spec.md`, `graphify-context.md`, graph | `council/defense-deck/{technical,overview}.md`, `council/round-N/opinions/*`, `round-N/suggestions.md` |
| **`/speckit-council-triage`** | main thread (Opus) | `round-N/suggestions.md` **only** | revised `plan.md`, `council/decision-record.md` |
| **`/speckit-council-approve`** | human (no session) | `overview.md`, `suggestions.md`, `decision-record.md` | `decision-record.md` `## Human Gate` section |

### C. The council orchestration (the hard part)

`/speckit-council` runs in the main thread as the **orchestrator** and dispatches subagents (the "separate sessions"), holding the stage barriers — modeled on `speckit-implement-parallel`'s wave loop:

1. **Deck prep** — one Sonnet subagent reads `plan.md` + `spec.md` + the graph summary and fills the two deck templates. Returns: "wrote defense-deck/" (status only).
2. **Stage 1 — independent opinions** — dispatch **5 Sonnet member subagents in one turn** (true parallel). Each receives `(deck, plan, spec-read, the graphify query tool)` and a **lens nudge** (see D). Each writes `round-N/opinions/<A–E>.md` and returns a one-line status. Barrier: wait for all 5.
3. **Stage 2 — anonymized peer review** — dispatch 5 member subagents again; each reads the *other four* anonymized stage-1 opinions and writes `round-N/opinions/peer/<A–E>.md`. Barrier.
4. **Stage 3 — chairman synthesis** — one Opus subagent reads **all** opinions + peer reviews (chairman-only), classifies each suggestion `blocking`/`strong`/`consider`, assigns IDs `R<n>-S<nn>`, and writes `round-N/suggestions.md` (+ a reduced-grounding flag if the graph was absent, FR-019). Returns the suggestions summary.
5. The orchestrator reads **only** `suggestions.md` and returns it to the main thread. It never reads `opinions/` — preserving SC-005.

**Reopen interface (FR-017, D46):** `/speckit-council --reopen delta|full`. `delta` packages `(plan diff, triggering finding)` as the sole context and runs stages 1–3 against that; `full` reruns the whole round. A `## Reopen` section is written to the decision record. Manually invoked in v1; the automated `/speckit-analyze` trigger is out of scope.

### D. Member differentiation — "varied prompts" (resolves the spec's deferred decision)

v1 members are **general-purpose reviewers** (faithful llm-council, D3) differentiated by a **soft analytical-lens nudge**, one per member: **A** correctness/logic · **B** risk & failure modes · **C** simplicity & rejected alternatives · **D** testability & verifiability · **E** dependencies & sequencing. These are *emphases layered on the same base reviewer prompt*, **not** the v2 role critics (which become formal specialized critics with role rubrics and a per-repo roster). This satisfies D18 ("varied prompts") and keeps v1→v2 a **prompt/config swap** of `member-prompt.md` — the thin member interface (FR-003).

### E. Graphify query tool wiring (D10)

Members are subagents with `Bash` access and instructions to ground claims with `graphify query/explain/path` against `graphify-out/graph.json`. No new tool is built — the installed `graphify` CLI *is* the tool. If `graph.json` is absent, members proceed deck-only and record it; the chairman raises the **reduced-grounding flag** in `suggestions.md`, which triage propagates to the decision record (FR-019/SC-008).

### F. Trace emission

Each subagent returns a **structured trace fragment** (role, model, effort, phase, timestamps, outcome, artifact, `skills:[]`, `elevated_grants:[]`, `cost_usd:null`, and token usage from the Agent-tool return metadata). The **orchestrator serially appends** these fragments to `specs/NNN/traces.jsonl` after each barrier — never a parallel append (avoids the JSONL corruption race). `council_spend` (SC-002) is `phase_spend(council) + phase_spend(deck-prep)` per `trace-schema.md` §5.

### G. Config (`extension/council-config.yml`, mirrors `graphify-config.yml`)

`member_count: 5`, `member_lenses: [correctness, risk, simplicity, testability, sequencing]`, `models: {chairman: opus, member: sonnet, deck_prep: sonnet}`, `max_rounds: 1`. **Trimming member count (the M1 risk lever) is a one-line config edit**, not a code change.

## Rejected Alternatives

- **One nested "council session" subagent that spawns members internally** (most literal reading of docs/10 "Session B"). Rejected: Claude Code subagents don't reliably spawn sub-subagents (nesting limits), and it hides the stage barriers from the resumable artifact tree. Main-thread coordination with subagent leaves is the graphify-proven pattern and keeps every stage's output an inspectable artifact. *(The nested form is the M6 SDK realization; the invariant — only `suggestions.md` returns as content — is identical.)*
- **Skip stage-2 peer review to halve member cost.** Rejected: peer review is core to the llm-council method (docs/10 §2) and is where members catch each other's misses. Cost is controlled by the member-count lever (config), not by deleting a stage.
- **A bespoke "graphify tool" wrapper for members.** Rejected: the `graphify` CLI already exists and is installed; wrapping it adds surface for no gain. Members call it directly via Bash.
- **Fixed role critics in v1** (architect/security/…). Rejected: docs/10 makes v1 faithful-llm-council and v2 the role critics; shipping roles now would pre-empt a v2 design decision and overfit the bench before any cost data exists.
- **Emit each subagent's trace by direct parallel append.** Rejected: concurrent JSONL appends interleave and corrupt lines. Orchestrator-serialized assembly is the fix.

## Project Structure

```text
extensions/council/
├── install.sh                     # idempotent; mirrors graphify (no before_* hook merge)
├── uninstall.sh
├── README.md
└── extension/
    ├── extension.yml              # id: council; provides 3 commands; hooks: none
    ├── README.md
    ├── council-config.yml         # member_count, lenses, model map, max_rounds
    ├── commands/                  # provenance stubs (dots→hyphens on install)
    │   ├── speckit.council.md
    │   ├── speckit.council.triage.md
    │   └── speckit.council.approve.md
    └── templates/
        ├── deck-technical.md      # D15 deck: problem, approach+rejected, graph impact, risk, cost, testability
        ├── deck-overview.md       # one page: what/why, what could go wrong, cost, "done"
        ├── member-prompt.md       # base reviewer prompt + {{lens}} slot (thin interface, FR-003)
        ├── chairman-prompt.md     # synthesis + classification + delta-check
        └── suggestions.md         # chairman output structure (classified, ID'd, reduced-grounding flag)

.claude/skills/                    # install destination (each command = one skill dir)
├── speckit-council/SKILL.md
├── speckit-council-triage/SKILL.md
└── speckit-council-approve/SKILL.md
```

**Structure Decision**: sibling-of-graphify layout. Command skills live in `.claude/skills/` (not edits to stock spec-kit skills) so a Spec Kit re-init never clobbers them — the same compatibility guarantee graphify documents.

## Dependency / graph impact

All-new code under `extensions/council/`; nothing existing is modified except the *addition* of three skills to `.claude/skills/`. No shared source file is mutated. The graph confirms the only structural precedent is `extensions/graphify/` (see `graphify-context.md`). Blast radius on the rest of the repo: none.

## Risk register

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| **R1** | **Per-session token capture in interactive CLI.** SC-002 needs real `tokens` per session; if the Agent-tool return doesn't expose usage, exact `council_spend` isn't computable until the SDK (M6). | Med | Design the trace-writer to read usage from the subagent return metadata; if unavailable, M2 emits structurally-valid traces with best-effort tokens and the exact measurement lands with the SDK. **Flagged for the council** — it touches the M1 exit. |
| **R2** | **Council cost heavier than expected** (13 sessions/round). | Med | The member-count lever is one config line (risk note: trim members before tooling). SC-002 makes the number visible on the first run. |
| **R3** | **Context-hygiene leak** — orchestrator or a tool reads `opinions/`. | Low | SC-005 grep invariant in the conformance check; the orchestrator is coded to read only `suggestions.md`; members return statuses, not bodies. |
| **R4** | **Parallel trace-append corruption.** | Low (mitigated) | Orchestrator-serialized assembly after each barrier (design F). |
| **R5** | **Deck/opinion quality from Sonnet members varies.** | Med | Peer-review stage + Opus chairman synthesis filter noise; the human gate is the backstop (D9). |

## Cost / complexity estimate

One round ≈ **13 sessions**: 1 deck-prep (Sonnet) + 10 member (Sonnet) + 1 chairman (Opus) + 1 triage (Opus). Member sessions dominate token count; chairman/triage dominate per-token cost (Opus). This is precisely what SC-002 measures on the first live run (M2). Complexity is *orchestration*, not algorithms — no novel code, just faithful subagent choreography over the graphify pattern.

## Testability claim

Every FR/SC is falsifiable: contract validators check `decision-record.md`/`traces.jsonl` conformance; a `grep` proves SC-005; an end-to-end run on M2's plan proves SC-001 and yields SC-002's number; injecting a `blocking` item proves SC-004's one-cycle convergence; removing `graph.json` proves FR-019/SC-008's reduced-grounding flag. See `quickstart.md`.

## Phase outputs

- **Phase 0** — [research.md](./research.md): resolved design decisions (member differentiation, subagent choreography, trace assembly, token-capture risk).
- **Phase 1** — [data-model.md](./data-model.md) (the `council/` artifact model + internal formats), [contracts/](./contracts/) (the three command I/O contracts), [quickstart.md](./quickstart.md) (end-to-end validation).

## Complexity Tracking

*No Constitution violations — section intentionally empty.*
