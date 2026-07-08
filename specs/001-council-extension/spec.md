# Feature Specification: speckit-ext-council — Plan Defense Council

**Feature Branch**: `001-council-extension`

**Created**: 2026-07-09

**Status**: Draft

**Input**: User description: "speckit-ext-council: force every plan through an adversarial council defense before task breakdown — defense-deck prep, an independent llm-council review with a graphify-grounded member bench, one-round convergence with a chairman delta check, a human gate, and an append-only decision record (per docs/10)"

> **Reading note.** This feature is a pipeline extension — developer tooling — so its "users" are the engineer driving the SDD pipeline and, at the gate, any stakeholder reading the plan. The requirements below describe the council's **observable behavior and artifacts**; the *how* (subagent wiring, member prompts, exact tool plumbing) is deferred to `/speckit-plan`. Decisions already ratified in `docs/90` (D3, D9–D15, D18, D28, D38, D40–D44) and the M0 contracts appear under **Constraints & Assumptions** as givens, not open choices — this is a dogfood build of a designed component (`docs/10`), not a greenfield product.

## Clarifications

### Session 2026-07-09

- Q: v1 council member count (independent members besides the chairman)? → A: **5** (chairman + 5 Sonnet members). Richer opinion diversity, closer to classic llm-council size; trimmable later once SC-002 gives real cost data. *(Diverges from the 000-sample fixture's 3 — the fixture is illustrative, not normative.)*
- Q: Council behavior when no graphify graph exists? → A: **Degrade, don't block** — the council runs deck-only, and the reduced-grounding condition is surfaced as an explicit flag in `suggestions.md` and the decision record, visible at the human gate (FR-019). Grounding (D10) enhances review quality but is not a precondition for reviewing a plan; a degraded review is never presented as fully grounded.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A plan is adversarially critiqued before any code is written (Priority: P1)

After `/speckit-plan` produces `plan.md`, and before `/speckit-tasks` breaks it into work, the plan is turned into a defense deck and submitted to an independent council that returns one synthesized, classified set of suggestions. The plan is not merely generated — it is *justified*, critiqued by multiple independent reviewers, and returned as actionable feedback while changing it is still cheap (no code exists yet).

**Why this priority**: This is the reason the extension exists (principle 2 — "plans must survive an adversarial defense before code exists"). Without the review round there is no council; every other story builds on this one.

**Independent Test**: Run the council on a completed `plan.md`; verify it produces `council/round-1/suggestions.md` in which every suggestion is classified `blocking` / `strong` / `consider` with a stable ID, that the deck exists under `council/defense-deck/`, and that only `suggestions.md` is surfaced to the main thread.

**Acceptance Scenarios**:

1. **Given** a completed `plan.md` and `spec.md`, **When** the council command runs, **Then** a technical deck and a one-page non-technical overview are written to `council/defense-deck/`, the council + chairman review them in three stages (independent opinions → anonymized peer review → chairman synthesis), and `council/round-1/suggestions.md` is produced with classified, ID'd suggestions.
2. **Given** the council has produced suggestions, **When** control returns to the main thread, **Then** only `suggestions.md` has crossed the session boundary — `opinions/` and `peer/` remain unread by the main thread.

---

### User Story 2 - The human approves at a readable gate and remains the final arbiter (Priority: P1)

After triage, the engineer reviews the one-page non-technical overview, the classified suggestions, and the decision record, then either approves — unlocking `/speckit-tasks` — or rejects with notes, sending the plan back for one more revision round. The human is always the backstop (D3, D9).

**Why this priority**: The council advises; the human decides. Approval is the event that permits token-spending work to begin, so the gate is load-bearing for both correctness and autonomy posture. A council with no gate would violate the founding principle that human review is the final arbiter.

**Independent Test**: With a human-gate profile, verify `/speckit-tasks` is blocked until an approval section is appended to `decision-record.md`, and that a non-technical reader can decide from the overview alone.

**Acceptance Scenarios**:

1. **Given** a triaged plan with a written decision record, **When** the engineer approves at the gate, **Then** a `## Human Gate` section (reviewer, decision, reviewed artifacts) is appended to `decision-record.md` and `/speckit-tasks` is unlocked.
2. **Given** the engineer rejects at the gate, **When** the decision is recorded, **Then** the plan returns for exactly one more revision round rather than proceeding to tasks.
3. **Given** only the one-page overview (not the technical deck), **When** a non-technical reader reads it, **Then** they can make an approve/reject decision — it states what is being built, what could go wrong, what it costs, and what "done" looks like.

---

### User Story 3 - Every suggestion has an auditable disposition; nothing is silently dropped (Priority: P2)

Triage records every suggestion the council raised with exactly one disposition — `accepted`, `rejected`, or `deferred` — and every non-acceptance carries written reasoning. A suggestion may be rejected; it may not be silently dropped (D13.5).

**Why this priority**: The decision record is the council's audit value and the input `/speckit-tasks` reads. Rejection-with-reasoning is what makes a defended plan defensible months later and is the one rule the whole record exists to enforce.

**Independent Test**: Verify `decision-record.md` conforms to its contract (rules R1–R7): each suggestion appears exactly once with a disposition; every `rejected`/`deferred` carries non-empty rationale; an accepted `blocking` item names the commit that applied it.

**Acceptance Scenarios**:

1. **Given** `suggestions.md` with a rejected suggestion, **When** triage runs, **Then** the record contains that suggestion with disposition `rejected` and a non-empty rationale.
2. **Given** an accepted `blocking` suggestion, **When** triage applies it, **Then** the record row names the plan delta as `<file> §<section> @ <commit-sha>`.
3. **Given** a deferred suggestion, **When** triage records it, **Then** the rationale names where it will resurface (an `I-` row in `docs/90` or a follow-up spec) — a `deferred` with nowhere to resurface is invalid.

---

### User Story 4 - Blocking issues force exactly one cheap revision cycle (Priority: P2)

The chairman classifies each suggestion. Zero `blocking` items → straight to the human gate. Any `blocking` items → the plan is revised once and re-checked by the chairman alone — a cheap delta check, no full council re-convene — then the human gate. v1 runs at most one full round.

**Why this priority**: Convergence must be bounded (cost is the M1 risk) yet must never ship a plan with a known blocking flaw. The chairman-only delta check is the cost control that makes one-round convergence safe (D13), backed by the always-on human gate.

**Independent Test**: Inject a blocking issue into a plan; verify exactly one revision and one chairman delta check occur — not a full second council — and that the delta check is recorded in the round's `### Chairman delta check` subsection.

**Acceptance Scenarios**:

1. **Given** a council round with zero `blocking` suggestions, **When** triage completes, **Then** no revision cycle runs and the flow proceeds directly to the human gate.
2. **Given** at least one `blocking` suggestion, **When** triage completes, **Then** the plan is revised once, a chairman-only delta check runs, and a `### Chairman delta check` subsection is recorded for that round.
3. **Given** a revised plan the chairman still finds `blocking` after the delta check, **When** the round limit is reached, **Then** the issue is escalated to the human gate — never looped again automatically.

---

### User Story 5 - Reviewers can check receipts against the real dependency graph (Priority: P3)

Council members are not confined to the deck: they hold read access to `spec.md` and a graphify query tool, so a member can verify a claimed blast radius or dependency against the actual graph instead of trusting the deck's word (D10). This is what makes even a faithful-llm-council v1 development-flavored.

**Why this priority**: Receipts-checking is the differentiator over vanilla llm-council and the M1 risk note protects it ("trim member count before trimming member tooling"). But the loop functions without it, so it is P3, not P1.

**Independent Test**: Give a member a deck asserting a blast radius; verify the member can issue a graphify `query`/`explain`/`path` and reference the graph result in its opinion.

**Acceptance Scenarios**:

1. **Given** a built graphify graph, **When** a member reviews the deck, **Then** the member can query the graph on demand and ground a critique in a real dependency edge.
2. **Given** a deck claim that contradicts the graph, **When** a member checks it, **Then** the discrepancy can surface as a classified suggestion.

---

### Edge Cases

- **No graphify graph present** — the council still runs deck-only, rather than blocking, and the reduced-grounding condition is flagged in `suggestions.md` and the decision record so it is visible at the human gate (FR-019). *(Ratified at clarification.)* Hard-requiring a graph would make the council brittle in ungraphed repos, and the graph is an enhancement to review quality, not a precondition for review.
- **Zero blocking suggestions** — no revision cycle; the flow goes straight to the human gate.
- **Blocking remains after the one revision + delta check** — escalate to the human gate at the round limit; never an unbounded loop (v1 = one full round).
- **A suggestion the plan author rejects** — must be logged with reasoning; a `deferred` with nowhere to resurface is a `rejected` wearing a nicer word and is invalid.
- **Deck regenerated on a revision round** — `defense-deck/` is overwritten in place (git on the feature branch holds prior versions, D38); `round-N/` artifacts are never overwritten.
- **Council gate under `gates.council.mode: auto`** — triage writes the gate section itself (`reviewer: auto`); `blocking` still forces one revision cycle. Autonomy changes *who signs*, never *what runs*.
- **A defended plan is reopened (D14)** — tiered review: `delta` by default (the council sees only the plan diff + the triggering finding as its context package), `full` rerun only if the patch changes the chosen approach or architecture; the tier is proposed at triage and is human-overridable. In v1 this is a **manually-invoked** interface on `/speckit-council` (FR-017); the **automated** trigger from a severe `/speckit-analyze` finding (D11) ships later, with analyze integration.
- **Any read of `opinions/` from the main thread** — forbidden. `suggestions.md` is the sole compression boundary; a tool that pulls `opinions/` into the main thread breaks context hygiene.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After `/speckit-plan` and before `/speckit-tasks`, the system MUST prepare a defense deck from `plan.md`, `spec.md`, and a graph summary, in two versions — a **technical** deck for council members and a **one-page non-technical overview** for the human gate — written under `council/defense-deck/`.
- **FR-002**: The technical deck MUST contain: problem restatement; chosen approach **and rejected alternatives with reasons**; dependency/graph impact; a risk register; a cost/complexity estimate; and a testability claim. The overview MUST state what is being built and why, what could go wrong, what it costs, and what "done" looks like, in one page.
- **FR-003**: The system MUST convene a council of multiple **independent** members (v1: **5**) plus **one chairman**, run as Claude subagents (Claude-only bench, D12), with a deliberately **thin member interface** — a member is anything that receives `(deck, plan, tools)` and returns a review file — so a future multi-provider or role-critic swap is a prompt/config change, not an architecture change.
- **FR-004**: Council review MUST run three stages: (1) **independent opinions** — each member reviews the deck + plan alone; (2) **anonymized peer review** — members critique each other's reviews; (3) **chairman synthesis** — one consolidated `round-N/suggestions.md`.
- **FR-005**: Council members MUST have read access to `spec.md` and an on-demand **graphify query tool** for codebase grounding (D10). When no graph is available the review proceeds deck-only and the reduced-grounding condition is flagged per FR-019.
- **FR-006**: Members MUST be anonymized as `A` / `B` / `C` … in `opinions/` (stage 1) and `opinions/peer/` (stage 2); the letter→member mapping MUST NOT be persisted.
- **FR-007**: Only `suggestions.md` returns to the main thread. `opinions/` and `opinions/peer/` are chairman-only and MUST NOT be read by the main thread (context hygiene, principle 1).
- **FR-008**: The chairman MUST classify each suggestion as `blocking` / `strong` / `consider` and assign stable IDs `R<round>-S<nn>`, never renumbered.
- **FR-009**: Triage MUST apply accepted suggestions to `plan.md` on the feature branch and record **every** suggestion's disposition (`accepted` / `rejected` / `deferred`) in `decision-record.md`; `rejected` and `deferred` MUST carry non-empty reasoning (D13.5); an accepted `blocking` item MUST name its applying commit.
- **FR-010**: Convergence MUST be: zero `blocking` → human gate; ≥1 `blocking` → exactly one revision cycle (plan revised → **chairman-only delta check**) → human gate. v1 MUST run at most one full round; a residual `blocking` after the delta check escalates to the human gate.
- **FR-011**: The human gate MUST record the reviewer's decision (`approved` / `approved-with-notes` / `rejected`) as an appended `## Human Gate` section in `decision-record.md`. `approved` unlocks `/speckit-tasks`; `rejected` returns the plan for one more revision round.
- **FR-012**: The system MUST expose three commands: **`/speckit-council`** (deck prep + council round → suggestions summary to the main thread), **`/speckit-council-triage`** (apply accepted suggestions, log the decision record), **`/speckit-council-approve`** (record the human-gate decision, unlock `/speckit-tasks`).
- **FR-013**: Deck prep, the council round, and triage MUST honor the session-boundary rule: each runs with only its declared context-in and emits exactly one artifact-out (deck-prep → `defense-deck/`; council → `round-N/suggestions.md`; triage → revised `plan.md` + a `decision-record.md` entry).
- **FR-014**: All council artifacts MUST live under `specs/NNN-feature/council/` and conform to `artifact-layout.md` and `decision-record.md`. `round-N/` artifacts are never overwritten; `defense-deck/` is overwritten in place on revision, versioned by git (D38).
- **FR-015**: Every council session — deck-prep, each council member, the chairman, and triage — MUST append exactly one record to `traces.jsonl` conforming to `trace-schema.md`, populating **every** field including `skills` and `elevated_grants` (both `[]` for these non-implementer roles), `role`, the **exact model ID**, `effort`, `tokens` (all four), `duration_ms`, `outcome`, and `artifact`.
- **FR-016**: Role→model assignment MUST follow D18: **chairman = Opus (xhigh)**; **council members and deck-prep = Sonnet**; **triage (main thread) = Opus**. A record whose `(role, model)` contradicts this is valid but flagged (the trace is evidence, not an enforcer).
- **FR-017**: The system MUST support **reopened-plan review as a manually-invoked interface** (D14, D46): `/speckit-council` accepts a reopen invocation in one of two tiers — **`delta`** (the context package is the plan diff + the triggering finding; the council reviews only that) or **`full`** (a complete council rerun). A `## Reopen` section is appended to `decision-record.md` naming the tier; `delta` is the default, `full` iff the patch changes the chosen approach/architecture; the tier is proposed at triage and is human-overridable. **Out of v1 scope (ships with analyze integration):** *automated* severity routing that triggers a reopen from a `/speckit-analyze` finding (D11) — v1 provides the mechanism, the automated trigger is wired later.
- **FR-018**: The council gate MUST respect the autonomy profile (`profile.yaml`): default `human` (D9, P1/P4); under `gates.council.mode: auto` (valid only within `full_auto: true`), triage writes the gate section itself with `reviewer: auto` — `auto` skips the human, never the council or the revision cycle.
- **FR-019**: When the council runs **without graph grounding** (no `graph.json`), the reduced-grounding condition MUST surface as an explicit flag in `suggestions.md` (written by the chairman) and be propagated into `decision-record.md` by triage, so it is visible to the human at the gate (D46). A degraded review MUST NOT be presented as fully grounded.

### Key Entities

- **Defense deck** — the plan's argument in two renderings: `technical.md` (for members) and `overview.md` (one page, non-technical, for the gate). Not round-scoped; overwritten on revision (D38). Markdown (D15).
- **Council member** — an independent reviewer (Claude subagent, Sonnet); anonymized to a single letter; holds `(deck, plan, spec read, graphify query tool)`; returns one opinion file. Interface kept thin for later swaps.
- **Chairman** — the synthesizer (Claude subagent, Opus, xhigh); reads all opinions and peer reviews, classifies suggestions, writes `suggestions.md`; also performs the cheap delta check after a revision.
- **Opinion** — a member's stage-1 independent review (`opinions/A.md`) or stage-2 peer review (`opinions/peer/A.md`). Chairman-only; never crosses to the main thread.
- **Suggestions** — the chairman's synthesized, classified output (`round-N/suggestions.md`); the compression boundary and the only council artifact the main thread reads.
- **Decision record** — the append-per-round audit trail (`decision-record.md`): dispositions with reasoning, chairman delta checks, reopen sections, human-gate decisions, and carried constraints consumed by `/speckit-tasks`.
- **Trace record** — one observability line per council session in `traces.jsonl`; the basis for the M1 exit measurement (council token spend per feature).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A real feature's plan completes the full loop **deck → council → triage → human gate** end-to-end, with all council artifacts committed on the feature branch. *(The M1 exit condition.)*
- **SC-002**: **Council token spend per feature is measured, with the token capture method recorded** — `council_spend = phase_spend(council) + phase_spend(deck-prep)` computed from `traces.jsonl` per `trace-schema.md` §5, reported alongside the count of `capture_method: unavailable` records so completeness is visible (D47). Exact per-session capture is **best-effort in interactive sessions** (a Phase-4 spike attempts transcript-based capture) and **guaranteed once the SDK drives sessions (M6)**. This is the first observability datapoint and the number the M1 cost-risk decision is made against.
- **SC-003**: 100% of the suggestions the council raises receive exactly one disposition in the decision record, and 100% of `rejected`/`deferred` dispositions carry non-empty reasoning — **zero silent drops**.
- **SC-004**: When a plan carries ≥1 `blocking` suggestion, **exactly one** revision cycle runs before the gate; when it carries zero, **zero** revision cycles run. No run performs a second full council round in v1.
- **SC-005**: The main thread never ingests member opinions. Two-part check (context hygiene): **(a)** a search for the `opinions/` path anywhere under the feature directory outside `council/` returns nothing; **(b)** subagent returns are **status-only** and all opinion content is file-mediated (members write `opinions/`, only the chairman reads them), so the orchestrator's own session carries **zero opinion content** — the invariant extends to the orchestrator transcript (S2).
- **SC-006**: Every council session leaves a conforming trace record — deck-prep, each member, the chairman, and triage are all present and validate against `trace-schema.md`.
- **SC-007**: A reviewer can reach an approve/reject decision from the one-page overview alone, without opening the technical deck (non-technical UX, principle 8).
- **SC-008**: A council run performed without a graph is visibly flagged as **reduced-grounding** at the human gate — present in both `suggestions.md` and the decision record — and is never presented as fully grounded (D46).

## Constraints & Assumptions

*Ratified decisions and M0 contracts, treated as givens for this dogfood build. **Standing rule (D46): every entry here cites a D-row; anything that cannot is a design choice and belongs in the plan, not the spec.***

- **Billing (D28)**: subscription-only; `ANTHROPIC_API_KEY` stays unset. No external API keys, ever.
- **Provider (D12)**: Claude-only member bench in v1 (mixed Opus/Sonnet per D18); multi-provider comes later, following Spec Kit's agent-agnostic pattern. The thin member interface (FR-003) is the one v1 concession to that future.
- **Council is faithful llm-council in v1, not role critics (D3)**: members are general-purpose reviewers differentiated by varied prompts (D18); the v2 role-specialized critics (architect / security / cost / testability / delivery-risk) are a later prompt/config change (D3). *(The prompt-variation mechanism is a `/speckit-plan` decision, deliberately not fixed here.)*
- **Deck format (D15)**: markdown v1; presentational rendering is a later GUI concern.
- **Convergence (D13)**: exactly one full round in v1; a second full round is a later profile option, not a v1 capability.
- **Model policy (D18)**: the role→model map (FR-016) is global policy, not per-feature; a different model for a role is a D18 amendment, not a profile edit.
- **Scope — plan-only, CLI-only, cost-measured (D3, D21, D6)**: the council reviews the **plan** only, never implementation output (D3; the "review implementation" idea I-5 is parked, not adopted); there is no GUI — the gate is a CLI interaction until the platform layer (D21); there is no automated cost budgeting — cost is measured, not governed (D6).
- **Artifacts are the contract (D4)**: every council artifact conforms to the M0-blessed schemas (`artifact-layout.md`, `decision-record.md`, `trace-schema.md`, `profile-schema.md`).
- **Graph grounding is optional (D10)**: FR-005's receipts-checking assumes a graphify graph; its absence degrades gracefully with a reduced-grounding flag (FR-019; see `## Clarifications`), it does not block.
- **Build-phase tracing (D46)**: this feature's own interactive build sessions (specify / clarify / plan / tasks / implement) predate the tracing capability the council extension introduces, so they write **no** `traces.jsonl` records and are **not** backfilled — a bootstrap fact, not a conformance gap. The first real trace records are the council's first *live* run — M2's plan review — which is simultaneously SC-002's first measurement and M1's exit test.
- **Dogfooding boundary (D9, D45)**: the extension is built in M1 but its first *live* exercise is M2's plan; for this feature's own plan the human acts as the council (bootstrap — human gate only, D9; M1 tooling/sequencing, D45). There is no council yet to review the council's own plan.
