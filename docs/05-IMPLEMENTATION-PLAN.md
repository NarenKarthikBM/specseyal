# Implementation Plan — Grounded Build Sequence (v1.0)

> Derived from brainstorm decisions D1–D25 (2026-07-08). Effort in T-shirt sizes — the calendar is shared with thesis, Clubcaddy, and work, so sizes matter more than dates.
> **Every milestone ends with a dogfood run on a real feature and a doc update.**

---

## Ground rules & assumptions

- **A1 (repo layout — D26, confirmed):** the system lives in the new **`specseyal`** repo (D30). Monorepo layout: `extensions/` (pipeline), `platform/` (manager + GUI + orchestrator, from M5), `docs/` (this doc set). The graphify extension migrates into `extensions/graphify/`; `speckit-graphifyy` gets archived with a pointer **after `007` closes, bundled into the public-flip visibility commit** (D29 as amended by **D73** — moved from "at α" so the repo goes public only behind an OSS-ready front door).
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
| Fixed-core taxonomy (D16) | Type × specialization enums + 2 boolean modifiers (`preserves_behavior`, `runtime_consumed`) — v0 drafted M0, **v1 BLESSED 2026-07-12** (D65, `docs/contracts/taxonomy.md`) after the three-feature review |

**Done when:** schemas documented in `/docs`, one sample feature folder committed.

## Milestone 1 — `speckit-ext-council` · **M**

Builds council spec 0.2 exactly. Deliverables: `/speckit-council`, `/speckit-council-triage`, `/speckit-council-approve`; markdown deck templates, technical + non-technical (D15); Claude-only bench — Sonnet members with varied prompts, Opus chairman (D12, D18); graphify query tool wired into member sessions (D10); one-round convergence with chairman delta check (D13); decision-record writer.

**Done when:** a real feature's plan survives deck → council → triage → human gate end-to-end, artifacts committed, and **council token spend per feature is measured** — the first observability datapoint.
**Risk:** council cost unknown. If heavy, trim member count before trimming member tooling — receipts-checking (D10) is the differentiator.

## Milestone 2 — `speckit-ext-git` · **S**

Branch-before-plan (naming from spec ID), phase-tagged commit conventions, feature cleanup (D25). Plus a **timeboxed spike** on worktrees-per-wave (I-4) — outcome recorded in the log either way.

**Done when:** a full pipeline run happens on an auto-created branch with phase-tagged commits.

**✅ CLOSED (2026-07-10).** Built through the pipeline (14 waves, 23/23 tasks), council-defended (first live council, 5.25M tok), merged to `main` by hand (ff, D52) — the last manual branch ritual — installed live (`bash extensions/git/install.sh .`, 9 hooks, verify-gate ahead of graphify), and `/speckit-git-cleanup` cut the first `complete/002-speckit-ext-git` anchor. Exit criterion met: `002` itself ran on its own auto-created branch with a phase-tagged commit at every boundary; SC-001–008 are validated existence proofs. The wave-worktree spike (I-4) concluded **abandon** (D54). See `specs/002-speckit-ext-git/completion-report.md`. Carried to M3: D55, I-14, FR-010 auto-trigger, HookExecutor→M6 (D53).

## Milestone 3 — categorize + agent creator · **M/L**

The pair (they share the taxonomy as their interface, D16): categorizer session emitting fixed-core keys + free tags; seed library of 5–6 specialists in `.claude/agents/` with schema metadata; gap generator producing bespoke definitions; assignment-proposal artifact rendered at the **workforce gate** (D9); D18 model map enforced; flywheel persistence for good generated agents (D24 — the one self-evolving component).

**Done when:** a feature's tasks get categorized, agents matched/generated, human approves the roster at the workforce gate, and `implement-parallel` consumes the assignments.

**✅ CLOSED (2026-07-12).** Built through the full pipeline as **one `workforce` extension** (S10 — the council folded the drafted pair; 3 commands, **10 waves, 32/32 tasks**, ~30 Sonnet subagents), council-defended (the **first `standard`-tier live council** — 2.83M tok, −46% vs the `full` baseline, the basis for D61's default flip), merged to `main` (ff, D52) + tagged `complete/003-workforce` by the **`002` machinery's first full-lifecycle run on a sibling feature**, installed live (`bash extensions/workforce/install.sh .`; `test/run.sh` **12/0**). Exit met: `003` itself ran `categorize → assign → workforce-gate → implement`, roster consumed — the gate was `approved-with-notes`, the **first elevated grant (`web_search`) a human signed, and the first he corrected** (D63: capability authorization ≠ dispatch approval). Determinism (SC-005) proven **byte-identical on the real `categorization.md`**. Seed library: 7 bases + 5 skills; the flywheel (skill-builder) is built + tested but **unfired** on `003`'s gap-free build (14 ∅-match gaps flagged — a v0→v1 signal). The workforce freshness machinery was **grandfathered** for `003`'s own implement (D64/Option A); the S02 gate-write it builds is correct + live (26/26 survival). See `specs/003-workforce/completion-report.md`. **Carried to M4:** I-16/I-17 (git-ext workforce-freshness), I-19 (FR-020↔P4 ruling), the **v0→v1 evidence dossier** (`docs/reviews/taxonomy-v0-evidence.md` — the three-feature trigger is now met). **M3's exit *test* is M4.**

> **✅ Taxonomy v1 IN FORCE (2026-07-12).** The v0→v1 review the M3 close-out set up is **complete and blessed** — `docs/reviews/2026-07-12-taxonomy-v1-review.md`, applied as **D65** (verdicts 1–10: §1 derivability honesty, the `runtime_consumed` modifier, the floor'd `general` cap, `agt_devtools_cli` accepts `docs`), **D66** (gap-batching economics), **D67** (standalone workforce-auto + grant tripwire). `docs/contracts/taxonomy.md` (renamed from `taxonomy-v0.md`) is now **v1.0 — BLESSED, normative**; the workforce extension is landed on `main` and reinstalled under v1 (commits `d7da3a2` + `0924986`; `test/run.sh` 12/0 against the installed scripts). **M4 builds on taxonomy v1.** **v1→v2 trigger:** first non-SpecSeyal repo categorized, or M5 close, whichever first. Resolved: I-15 (docs×devtools-cli lane, → D65), I-19 (workforce auto-mode drift, → D67). Still carried, out of taxonomy scope: I-16/I-17 (git-ext workforce-freshness), I-13 (graphify `.sh`/`.yml`/`.md` coverage).

## Milestone 4 — testing agent + completion report · **S**

Doc-only testing agent (per your notes: "for now, creates a testing doc"); completion report format finalized — it becomes a phase-event payload in M5.

**Done when:** every pipeline run ends with a completion report + testing doc.

**✅ CLOSED (2026-07-13).** Built through the full pipeline as the **4th extension** (`speckit-ext-testing`) — the pipeline's **first fully-unassisted run** (every upstream station live machinery, no grandfather, unlike `003`). **6 waves / 19/19 tasks**, preceded by a **pre-flight** (D69 — the I-17 workforce-freshness fix provisioned *before* wave 1, never a wave node: *machinery that gates the waves is never itself a wave*); council-defended by the D62-enriched `standard` council (synthesis spend −8.1% vs `003`). The **two new commands got their first live run on `004` itself**: `/speckit-complete` (main-thread orchestrator authoring — **no new model role**, FR-001) → a contract-validated `completion-report.md` (the D19 `phase.completed` `artifact.body`); `/speckit-testing` (one Sonnet `tester`, doc-only, `executed: none`) → `testing.md`, a **27/27 SC+FR bijection with 1 honest GAP** (FR-017, genuinely satisfied *upstream* at council — the tester correctly declined to fabricate coverage). Merged to `main` (ff, D52) + tagged `complete/004-testing-completion`; testing-ext installed live (`test/run.sh` **43/0**), git-ext reinstalled carrying the I-17 fix + testing seam (**46/0**). **Exit met: SC-001…010 all validated** — headline **SC-010** proven live on the dogfood run itself (waves 2–6 each cleared `verify-gate workforce` via the checkbox-delta branch, **zero hand assistance**, with durable audit lines; a content edit still BLOCKS). Findings **F1–F6 adjudicated** (F1→D71, F2→I-22, F3→I-23, F4 in-run, **F5→D72** — `trace-schema.md` → 1.3 admitting the tester `context_in`; F6 = gap-honesty confirmed as designed). See `specs/004-testing-completion/completion-report.md`. **This is the last milestone before the platform.**

---

### ★ Checkpoint α — the entire notebook pipeline runs, CLI-only

Everything from the Ideas page is now real: specify → clarify → plan → council → tasks → analysis → agents → parallel implement → completion → testing doc. Full value with zero platform. Everything after this is leverage, not function.

**★ REACHED (2026-07-13).** M4's close-out is the checkpoint: the entire notebook pipeline now runs **CLI-only, end to end**, every station live machinery dogfooded on its own build across `001`–`004` (spec → clarify → plan → council → tasks → analyze → categorize → agents → parallel implement → **complete → testing**). Four extensions ship (`graphify`, `git`, `workforce`, `testing`); the four `complete/00N` completion anchors tag the arc. **Full value, zero platform hours spent** — exactly the bet A-checkpoint made. **The α-acts are now scoped as three `standard`-tier α-polish features** (**D73**): **`005-graphify-context` (M) → `006-deck-render` (S) → `007-oss-docs` (S/M)**, each dogfooding the full pipeline once more; then a single **visibility commit** flips the repo public **and** archives `speckit-graphifyy` with a pointer (D29 as amended by D73 — the public flip moved from α to *after `007`*, since a README-less front door costs more than a three-feature delay). `006` renders decks to pptx only where a per-deck profile asks (default `none`); markdown stays the artifact of record (D15 unamended). Everything after α is leverage, not function — the α-polish trio is that leverage, and **M5 (platform observe + approve) follows.**

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
