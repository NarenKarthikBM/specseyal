# speckit-ext-council

**Force every `plan.md` through an adversarial defense before a single line of code exists.**

Spec-kit produces a plan and hands it straight to task breakdown — nothing checks whether the
plan is any good before implementation spend begins. `speckit-ext-council` inserts a defense
round in between: your `plan.md` becomes a defense deck, an independent council of Claude
reviewers picks it apart, a chairman synthesizes and classifies the findings, at most one cheap
revision cycle resolves anything blocking, and a human — always — makes the final call at a gate.
Every suggestion's fate lands in an append-only decision record. Nothing is silently dropped.

```
                     ┌──────────────────────────────────────────────┐
   plan.md   ──▶     │  defense deck — technical.md + overview.md   │
                     └────────────────────┬───────────────────────────┘
                                          │  5×Sonnet members ▶ opinions ▶ peer review
                                          │  ▶ 1×Opus chairman synthesizes + classifies
                                          ▼
                     ┌──────────────────────────────────────────────┐
                     │  round-N/suggestions.md                       │
                     │  (blocking / strong / consider, stable IDs)   │
                     └────────────────────┬───────────────────────────┘
                                          │  ≥1 blocking? one revision + chairman delta-check
                                          │  0 blocking?  straight through
                                          ▼
                     ┌──────────────────────────────────────────────┐
                     │  decision-record.md — every suggestion        │
                     │  dispositioned, then the human gate           │
                     └────────────────────┬───────────────────────────┘
                                          │  approved
                                          ▼
                                   /speckit-tasks
```

It's a **gate**, not a rubber stamp: the council can force one revision cycle, but the human is
always the final arbiter — nothing reaches `/speckit-tasks` without an explicit approval recorded
in the decision record.

---

## Provides

Three command skills:

| Command | What it does |
| --- | --- |
| `/speckit-council` | Preps the defense deck from `plan.md` + `spec.md`, convenes the council — independent opinions → anonymized peer review → chairman synthesis — and returns classified `suggestions.md` to the main thread. |
| `/speckit-council-triage` | Applies accepted suggestions to `plan.md` and logs **every** suggestion's disposition (`accepted` / `rejected` / `deferred`), with reasoning, in `decision-record.md`. |
| `/speckit-council-approve` | Records the human's gate decision (`approved` / `approved-with-notes` / `rejected`) in `decision-record.md`. Approval unlocks `/speckit-tasks`; rejection sends the plan back for one more revision round. |

---

## The loop

```text
/speckit-plan  →  /speckit-council  →  /speckit-council-triage  →  /speckit-council-approve  →  /speckit-tasks
```

Run it after `/speckit-plan` produces a plan and before `/speckit-tasks` breaks it into work.
Zero `blocking` suggestions go straight to the human gate; any `blocking` suggestion triggers
exactly one revision cycle (plan revised, then a cheap chairman-only delta check) before the gate
— v1 runs at most one full round.

---

## Install

```bash
bash extensions/council/install.sh .
```

Copies `extension/` → `.specify/extensions/council/` and the three command skills →
`.claude/skills/`. Idempotent — re-run any time to update. Unlike graphify, the council registers
no `before_*` pipeline hooks (it's command-invoked, not hook-invoked), so there's nothing to merge
into `.specify/extensions.yml`. Run `bash extensions/council/uninstall.sh .` to remove it cleanly.

---

## Requirements

- A **completed `plan.md`** — the council reviews plans, not specs or code (v1 scope is plan-only).
- A **graphify graph** (`graphify-out/graph.json`) is *optional*. When present, members hold a
  `graphify query`/`explain`/`path` tool and can check a deck's claimed blast radius or dependency
  against the real graph instead of trusting its word. When absent, the council still runs —
  deck-only — and flags the reduced-grounding condition in `suggestions.md` and the decision
  record so it's visible at the human gate. Grounding sharpens the review; it's never a
  precondition for one.

---

## Configuration

`extensions/council/extension/council-config.yml`:

```yaml
member_count: 5                # independent council members (v1). The M1 cost lever —
                                # trim this before trimming member tooling.
member_lenses: [correctness, risk, simplicity, testability, sequencing]
models:
  chairman: opus                # D18 role → model policy
  member: sonnet
  deck_prep: sonnet
max_rounds: 1                  # exactly one full round in v1
```

`member_count` is the cost lever: one round costs roughly `2 × member_count + 3` sessions
(deck-prep + members × 2 stages + chairman + triage), so trimming it is a one-line edit, not a
code change.

---

## Billing

Runs entirely on **Claude subscription auth**. `ANTHROPIC_API_KEY` is never set or relied upon —
deck-prep, every member session, the chairman, and triage all run as Claude subagents against
your subscription, same as the rest of the pipeline.

---

## License

MIT — see [`LICENSE`](../../LICENSE).
