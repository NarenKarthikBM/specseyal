# speckit-ext-council — Design Spec (0.2)

> **Status:** Design decisions resolved (D12–D15). Ready for implementation planning.
> **Position in pipeline:** After `/speckit-plan`, before `/speckit-tasks`. The gate no code passes without.
> **Lineage:** Karpathy llm-council methodology (independent opinions → anonymized peer review → chairman synthesis), evolving toward development-oriented role critics. Human review is the final arbiter.

---

## 1. Purpose

Force every plan to survive an adversarial defense before task breakdown begins. The plan is not merely generated — it is *justified*, critiqued by multiple independent reviewers, revised, and approved by a human.

## 2. The flow

```
plan.md (from /speckit-plan)
   │
   ▼
[SESSION A: Deck preparation]  ── separate session
   reads: plan.md, spec.md, graphify graph
   produces: defense-deck/  (technical + non-technical versions)
   │
   ▼
[SESSION B: Council review]  ── separate session
   Stage 1  Independent opinions — each member reviews the deck + plan alone
   Stage 2  Anonymized peer review — members rank/critique each other's reviews
   Stage 3  Chairman synthesis — one consolidated verdict
   produces: council/round-N/suggestions.md
   │
   ▼
[MAIN THREAD: Triage]
   suggestions.md is the ONLY thing that returns to the main thread
   ├─ suggestions accepted → revise plan.md (on feature branch) → loop to SESSION A
   ├─ round limit hit (see §5) → escalate to human gate
   └─ council satisfied → human gate
   │
   ▼
[HUMAN GATE]
   Babu reviews: non-technical deck + final suggestions + decision record
   approve → /speckit-tasks   |   reject with notes → one more revision round
   │
   ▼
council/decision-record.md  (what was challenged, what changed, what was accepted as-is and why)
```

## 3. Artifacts

All artifacts live under `specs/NNN-feature/council/`:

| Artifact | Produced by | Consumed by |
|---|---|---|
| `defense-deck/technical.md` | Session A | Council members |
| `defense-deck/overview.md` (non-technical) | Session A | Human gate, stakeholders |
| `round-N/opinions/` (per-member, anonymized as A/B/C…) | Session B stage 1–2 | Chairman only — never main thread |
| `round-N/suggestions.md` | Session B stage 3 (chairman) | Main thread triage |
| `decision-record.md` | Main thread, appended per round | Permanent audit trail; input to `/speckit-tasks` context |

**Deck contents (technical version):** problem restatement, chosen approach + *rejected alternatives with reasons*, dependency/graph impact (from graphify), risk register, cost/complexity estimate, testability claim.

**Deck contents (non-technical version):** what we're building and why, what could go wrong, what it costs, what "done" looks like. One page.

**Deck format (D15 — decided): markdown v1.** Simple, diffable, session-friendly; presentational rendering becomes a GUI concern later.

## 4. Council composition

**v1 — faithful llm-council:** N general-purpose members + 1 chairman, per the existing skill methodology. Members are not confined to the deck: they hold read access to spec.md and a **graphify query tool** for on-demand codebase grounding (D10) — reviewers that can check receipts. This makes even v1 development-flavored: a member can verify a claimed blast radius against the actual dependency graph instead of taking the deck's word for it.

**Provider strategy (D12 — decided):** v1 prototypes **Claude-only** — a mixed Opus/Sonnet/Haiku member bench running as subagents. No external keys, and trivially compatible with the graphify query tool. Multi-provider comes later, following Spec Kit's own agent-agnostic pattern. The one v1 concession to that future: keep the **member interface thin** — a member is anything that receives (deck, plan, tools) and returns a review file — so the backend swap is mechanical, not surgical.

**v2 — development-oriented council:** members become role-specialized critics reviewing the same deck from assigned angles:

| Critic | Angle |
|---|---|
| Architect | Structural soundness, coupling, graph impact |
| Security | Attack surface, data handling, authz |
| Cost/Perf | Complexity, runtime cost, model spend |
| Testability | Can this plan's claims be verified? |
| Delivery risk | Sequencing, hidden dependencies, estimate realism |

v1 → v2 is a prompt/config change, not an architecture change — design the member interface accordingly.

## 5. Convergence rule (D13 — decided, deliberately simple for v1)

v1 runs **exactly one full council round**:

1. Council round → chairman classifies each suggestion: `blocking` / `strong` / `consider`.
2. No `blocking` items → straight to the human gate.
3. `blocking` items → **one** revision cycle: plan revised → **chairman-only delta check** (cheap — no full council re-convene) → human gate.
4. Chairman holding classification power is safe because the human gate is default-on (D9): the human is always the backstop and can reclassify anything.
5. A suggestion the plan author *rejects* must be logged in `decision-record.md` with reasoning — rejection is allowed, silent dropping is not.

Profiles may later allow a second full round; v1 does not.

### Reopened plans (D14 — tiered)

When a severe `/speckit-analyze` finding reopens a defended plan (D11): **delta review by default** — the council sees only the plan diff plus the finding that caused it. **Full rerun** only if the patch changes the plan's chosen approach or architecture. The tier is proposed at triage; the human gate can override in either direction.

## 6. Session boundaries & context packages

| Session | Context in (nothing more) | Artifact out |
|---|---|---|
| A: Deck prep | plan.md, spec.md, graph summary | defense-deck/ |
| B: Council | defense-deck/, plan.md, spec.md (read), **graphify query tool** (on-demand codebase grounding, D10) | round-N/suggestions.md |
| Main thread triage | suggestions.md only | revised plan.md + decision-record entry |

Main thread never sees member opinions or peer reviews — chairman synthesis is the compression boundary. This is principle #1 (context hygiene) applied.

## 7. Command surface (proposal)

- `/speckit-council` — runs deck prep + council round, returns suggestions summary to main thread
- `/speckit-council-triage` — walks suggestions, applies accepted ones to plan.md, logs decision record
- `/speckit-council-approve` — records human gate decision, unlocks `/speckit-tasks`

## 8. Non-goals (v1)

- Council does NOT review implementation output (idea parked — see parking lot I-5)
- No GUI — the human gate is a CLI interaction until the platform layer exists
- No automated cost budgeting for council runs

## 9. Open questions rolled up

All previously open items resolved: `[Q1]`→D12 · `[Q2]`→D13 · `[Q3]`→D15 · `[Q12]`→D14. **This spec is at 0.2 — ready for a buildable task breakdown in the implementation plan.**
