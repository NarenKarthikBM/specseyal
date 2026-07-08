# SpecSeyal — Spec-Driven Development Orchestrator

Extended SDD workflow on GitHub Spec Kit + graphify: governed pipeline from spec → council-defended plan → specialized parallel implementation → testing, with an Agent SDK-native platform layer to come.

## Source of truth — read before working

- `docs/00-VISION-AND-ARCHITECTURE.md` — the north star. Read first, always.
- `docs/05-IMPLEMENTATION-PLAN.md` — milestones M0–M7. Check which milestone is active.
- `docs/10-COUNCIL-EXTENSION-SPEC.md` — council extension design (0.2, buildable).
- `docs/90-DECISIONS-AND-IDEAS.md` — decision log (D1–D28+), open questions, parking lot.

**Log discipline (non-negotiable):** any decision made in a session gets a D-row in docs/90 *in that same session*, and the session log gets an entry. Ideas go in as I-rows immediately, one line each.

## Principles digest (full text in docs/00 §2)

1. **Artifacts are the contract** — every phase reads artifacts in, writes exactly one artifact out. CLI and platform share this interface.
2. **Context hygiene** — main thread stays lean; heavy work runs in separate sessions returning compact artifacts.
3. **Resumability** — every phase idempotent, resumable from artifacts alone.
4. **Observability** — every session leaves a trace (role, model, tokens, duration).
5. **Subscription-only billing (D28)** — NEVER set or rely on `ANTHROPIC_API_KEY`. All work runs on Claude subscription; M6+ programmatic sessions use the plan's Agent SDK credit.

## Model policy (D18)

- Main thread / orchestration: **Opus, xhigh effort**
- Implementation agents: **Sonnet**
- Judgment roles (council chairman, analyze/triage): **Opus**
- Mechanical roles (deck prep, categorizer, council members): **Sonnet**
- Haiku: unused in v1

## Repo layout

```
extensions/        # pipeline extensions (graphify, council, git, categorize, agents, testing)
platform/          # manager + GUI + orchestrator (empty until M5)
docs/              # the doc set above + contracts/
specs/             # per-feature SDD artifacts: specs/NNN-feature/...
```

## Conventions

- Feature artifacts: `specs/NNN-feature/` — spec.md, plan.md, council/, tasks.md, reports (full layout in docs/contracts/)
- Git (D25): branch before plan, branch name from spec ID, phase-tagged commits, cleanup on completion
- Autonomy profiles: `profile.yaml` per feature — gates `council` and `workforce`, each `human` | `auto`; full-auto must be explicit
- License: MIT (D27)

## Dogfooding rule

From M1 onward, the pipeline builds itself: each milestone gets a spec, and the council reviews the plan for building the next milestone. M0 is the only milestone built in a plain session.
