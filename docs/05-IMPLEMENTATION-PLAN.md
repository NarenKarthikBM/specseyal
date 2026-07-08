# Implementation Plan — Grounded Build Sequence (v1.0)

> Derived from brainstorm decisions D1–D25 (2026-07-08). Effort in T-shirt sizes — the calendar is shared with thesis, Clubcaddy, and work, so sizes matter more than dates.
> **Every milestone ends with a dogfood run on a real feature and a doc update.**

---

## Ground rules & assumptions

- **A1 (repo layout — D26, confirmed):** the system lives in the new **`specseyal`** repo (D30). Monorepo layout: `extensions/` (pipeline), `platform/` (manager + GUI + orchestrator, from M5), `docs/` (this doc set). The graphify extension migrates into `extensions/graphify/`; `speckit-graphifyy` gets archived with a pointer at checkpoint α (D29).
- **A2 (license):** MIT. **Confirmed (D27).**
- **A3 (billing/auth — D28): subscription-only, end to end.** M0–M5 run entirely in interactive Claude Code sessions (normal plan usage); the manager service contains zero AI calls. M6's programmatic sessions run on the **Agent SDK monthly credit** included with Pro/Max plans (covers Agent SDK + `claude -p`, separate from interactive limits) — no API key. Keep `ANTHROPIC_API_KEY` unset on build machines so billing never silently routes to the API (check `/status` if in doubt). API keys enter only if/when work-team production automation demands them.
- **Dogfooding rule:** from Milestone 1 onward, the workflow builds itself — the council reviews the plan for building the next milestone. Free testing, and the observability data starts accumulating immediately.
- **D18 model policy applies to build sessions too:** Opus xhigh on the main thread, Sonnet on implementation.

---

## Milestone 0 — Contracts & scaffolding · **S**

The schemas everything else depends on. No behavior, just contracts.

| Deliverable | Notes |
|---|---|
| Artifact directory convention | `specs/NNN-feature/council/…` per council spec §3 |
| `decision-record.md` format | Append-per-round; rejection-with-reasoning mandatory (D13.5) |
| Autonomy profile file (`profile.yaml`) | Two gates: `council`, `workforce` — each `human` \| `auto`; full-auto must be explicit (D9) |
| Agent library entry schema | Stable ID + version + taxonomy keys + model + prompt (D17 — central-sync-ready from day one) |
| Observability trace schema | session id, role, model, tokens, duration (rides D19 events later) |
| Fixed-core taxonomy v0 (D16) | Type × specialization enums — draft list, iterate through use |

**Done when:** schemas documented in `/docs`, one sample feature folder committed.

## Milestone 1 — `speckit-ext-council` · **M**

Builds council spec 0.2 exactly. Deliverables: `/speckit-council`, `/speckit-council-triage`, `/speckit-council-approve`; markdown deck templates, technical + non-technical (D15); Claude-only bench — Sonnet members with varied prompts, Opus chairman (D12, D18); graphify query tool wired into member sessions (D10); one-round convergence with chairman delta check (D13); decision-record writer.

**Done when:** a real feature's plan survives deck → council → triage → human gate end-to-end, artifacts committed, and **council token spend per feature is measured** — the first observability datapoint.
**Risk:** council cost unknown. If heavy, trim member count before trimming member tooling — receipts-checking (D10) is the differentiator.

## Milestone 2 — `speckit-ext-git` · **S**

Branch-before-plan (naming from spec ID), phase-tagged commit conventions, feature cleanup (D25). Plus a **timeboxed spike** on worktrees-per-wave (I-4) — outcome recorded in the log either way.

**Done when:** a full pipeline run happens on an auto-created branch with phase-tagged commits.

## Milestone 3 — categorize + agent creator · **M/L**

The pair (they share the taxonomy as their interface, D16): categorizer session emitting fixed-core keys + free tags; seed library of 5–6 specialists in `.claude/agents/` with schema metadata; gap generator producing bespoke definitions; assignment-proposal artifact rendered at the **workforce gate** (D9); D18 model map enforced; flywheel persistence for good generated agents (D24 — the one self-evolving component).

**Done when:** a feature's tasks get categorized, agents matched/generated, human approves the roster at the workforce gate, and `implement-parallel` consumes the assignments.

## Milestone 4 — testing agent + completion report · **S**

Doc-only testing agent (per your notes: "for now, creates a testing doc"); completion report format finalized — it becomes a phase-event payload in M5.

**Done when:** every pipeline run ends with a completion report + testing doc.

---

### ★ Checkpoint α — the entire notebook pipeline runs, CLI-only

Everything from the Ideas page is now real: specify → clarify → plan → council → tasks → analysis → agents → parallel implement → completion → testing doc. Full value with zero platform. Everything after this is leverage, not function.

---

## Milestone 5 — Platform MVP: observe + approve · **L**

**The key sequencing insight: the MVP needs no Agent SDK orchestrator — and no API keys.** The AI brain remains your interactive Claude Code session (subscription, as today); it pushes phase events (D19: full artifact + status + trace at phase boundaries, heartbeats between) to the central manager via MCP and *polls for gate decisions* — so gates approved in the browser flow back into the running CLI session. The manager itself is a plain no-AI web service: storage + rendering, zero Claude calls.

Deliverables: manager backend on the EC2 (D22) with token auth (D20); MCP server (event ingest + gate-decision endpoint); tracking view (read-only, D21); council gate view rendering the non-technical deck; workforce gate view rendering the roster.

**Done when:** you approve a council gate from your phone.

## Milestone 6 — Agent SDK orchestrator: drive · **L**

The GUI starts and steers pipelines. Sessions spawned via the SDK loading the same `.claude/` commands — the D4 payoff, everything from M1–M4 reused verbatim. Resumability (principle 6) proven the honest way. **Auth (D28):** programmatic sessions run on the plan's Agent SDK monthly credit — separate from interactive limits, no API key, sized for exactly this individual-automation phase.

**Done when:** a feature runs end-to-end started from the browser, surviving one deliberate mid-run kill and resuming from artifacts.

## Milestone 7 — Setup wizard, full scope · **M**

D23 in full: init, graphify + spec-kit, dev server, agent library bootstrap, MCP registration, autonomy profile config.

**Done when:** a fresh repo on a fresh machine reaches a complete pipeline run through the wizard alone.

---

## Continuous tracks (start at M1, never stop)

- **Observability:** traces from every dogfood run; dashboards once M5 exists; revisit Q6 (graph-scored model assignment) when the data can actually answer it.
- **OSS hygiene:** README, MIT license, contribution docs from M1 — D7 says open source is simultaneous, not eventual. **Naming (Q4) blocks public promotion only — your court.**
- **Library flywheel:** every generated agent that performs gets persisted with its stats (D24).

## Sequencing logic in one paragraph

Council first because it's self-contained, artifact-based, and your #1 priority (D5). Git second because it's small and makes every later dogfood cleaner. The workforce pair third because it completes the pipeline's brain. Checkpoint α proves the CLI-only system earns its keep before a single platform hour is spent. Platform lands in two bites — observe/approve needs only MCP plumbing, drive needs the SDK — and the wizard ships last because it can only package what exists.

## Carried open items

All closed. D18 (role map) remains amendable anytime — as does everything else, via docs/90. That's what the log is for.
