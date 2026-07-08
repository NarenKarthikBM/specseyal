# Decisions & Ideas — Working Log

> The scratchpad. Jot here first; promote to specs when ripe.
> Convention: **D** = decision made · **Q** = open question · **I** = idea in the parking lot.

---

## Decisions made

| # | Date | Decision | Notes |
|---|---|---|---|
| D1 | 2026-07-08 | GUI is **Agent SDK-native** — it drives sessions, not a wrapper over CLI | Resolves the "Agent-SDK or UI interfaces" note. GUI = control plane. |
| D2 | 2026-07-08 | Agent creator is **hybrid**: specialist library + generated gaps | Persist good generated agents back → library flywheel. |
| D3 | 2026-07-08 | Council v1 uses **llm-council methodology** as-is; evolves to development-oriented critics in v2; **human review always happens** | Human gate is final arbiter. |
| D4 | 2026-07-08 | **Artifacts are the contract** between pipeline layer and platform layer | *Proposed by Claude, tacitly accepted — flag if you disagree.* Enables CLI-first build with zero rework. |
| D5 | 2026-07-08 | Build order: council → git ext → categorize+agents → testing → platform → wizard | Per priority page + D4 rationale. |
| D6 | 2026-07-08 | Principles expanded: + **Resumability**, **Observability**, **Non-technical UX**, **Self-evolving setup**. Cost-awareness deliberately NOT a principle | Cost lives inside observability as a tracked metric. Round 1. |
| D7 | 2026-07-08 | Audience: **Me → work teams + open source, simultaneously**. Central manager tracks local changes across devices/users | Supersedes I-7's "decide later". Forces multi-user auth (Q10). |
| D8 | 2026-07-08 | Automation posture: **configurable per feature** — autonomy profiles declare which gates are human vs auto | Tension with D3 ("human review always happens" at council) — resolved in Round 2. |
| D9 | 2026-07-08 | v1 gate-capable checkpoints: **council gate + workforce gate** (post-tasks + agent assignment). Council gate default-on in every profile; skipping requires explicit full-auto profile | Resolves D3/D8 tension. Spec/clarify and post-implement: not gate-capable in v1. |
| D10 | 2026-07-08 | Council reviews the **plan**, but members hold spec read-access + **graphify query tool** for on-demand codebase grounding | "Reviewers that can check receipts." Session B needs graphify as a tool, not just files. |
| D11 | 2026-07-08 | Remediation is **severity-based**: routine findings patch tasks.md, severe findings reopen the plan | Reopened post-council plan → delta-review question (Q12). |
| D12 | 2026-07-08 | Council v1 is **Claude-only** (mixed Opus/Sonnet/Haiku subagent bench); multi-provider later, Spec Kit-style agent-agnostic | Keep member interface thin so the backend swap is mechanical. |
| D13 | 2026-07-08 | Convergence, v1-simple: **one full round**, chairman classifies (`blocking`/`strong`/`consider`); blocking → one revision + chairman-only delta check → human gate | Claude's recommendation, adopted. Safe because the gate is default-on (D9). |
| D14 | 2026-07-08 | Reopened plans: **tiered** — delta review by default, full rerun if the patch changes approach/architecture; human can override the tier | |
| D15 | 2026-07-08 | Defense deck format: **markdown v1**; presentational rendering deferred to GUI | Adopted by default, no objection raised. |
| D16 | 2026-07-08 | Categorization taxonomy: **hybrid** — fixed core (type × specialization enums) + free tags | Fixed core = deterministic library matching; tags = nuance for gap generator. |
| D17 | 2026-07-08 | Agent library: **per-repo now** (`.claude/agents/`), **central library later via central-library MCP** (I-10) | Entries carry stable IDs + version metadata from day one → central migration is lift-and-shift. |
| D18 | 2026-07-08 | Model policy, two-plane: **Sonnet default for implementation agents; Opus xhigh effort for main thread.** Judgment roles (chairman, analyze/triage) → Opus; mechanical roles (deck prep, categorizer, members) → Sonnet; Haiku unused v1 | Role map **confirmed by default** (review requested Round 4, no corrections). Amendable anytime. Graph-scoring deferred to observability data. |
| D19 | 2026-07-08 | MCP sync: **phase-completion events carry full artifact + status + trace**; mid-phase = status heartbeats only (no artifact bodies); on-demand pull for GUI freshness | Claude's recommendation per Babu's delegation ("phase completion for sure; artifact writes if sustainable"). Sustainable because artifacts are small markdown pushed at boundaries only. |
| D20 | 2026-07-08 | Central manager auth: **single-user token v1, GitHub OAuth later** | OAuth chosen as the designed target — one mechanism serves personal, team, and OSS self-hosters. |
| D21 | 2026-07-08 | GUI MVP: **observe + approve gates first** — read-only tracking + the two D9 gates in the browser; drive capability later | Principle 8 made real: council gate approvable from a phone via the non-technical deck. |
| D22 | 2026-07-08 | Central manager hosting: **claude.narenwebworks.in EC2 (t4g.large)** initially; revisit on load/work adoption | Adopted by default, no objection raised. |
| D23 | 2026-07-08 | Setup wizard: **full scope** — init + graphify/spec-kit + dev server + agent library bootstrap + MCP registration + autonomy profiles | Ships last in build order; packages everything. |
| D24 | 2026-07-08 | Self-evolving setup, year-one boundary: **agent library only** (the flywheel) | Self-tuning config and self-regenerating wizard out of scope until the flywheel proves the pattern. |
| D25 | 2026-07-08 | Git extension v1: **branch-before-plan + per-feature lifecycle** (branch naming from spec ID, phase commit conventions, cleanup). Worktrees-per-wave (I-4) = timeboxed spike, not committed scope | Adopted by default, no objection raised. |
| D26 | 2026-07-08 | The system lives in a **brand-new repo** (A1 revised). **Migration confirmed:** graphify moves into `extensions/graphify/` (monorepo: `extensions/` + `platform/` + `docs/`); `speckit-graphifyy` archived with pointer **at checkpoint α** (D29) | Naming (Q4) needed for repo creation; working name OK, GitHub redirects renames. |
| D27 | 2026-07-08 | License: **MIT** confirmed (A2) | |
| D28 | 2026-07-08 | Billing/auth: **subscription-only through M7.** M0–M5 = interactive Claude Code (plan usage) + no-AI manager service; M6+ programmatic sessions on the **Agent SDK monthly credit** (Pro/Max, covers Agent SDK + `claude -p`, separate from interactive limits) — no API keys | Keep `ANTHROPIC_API_KEY` unset on build machines (it overrides subscription auth). API keys only if work-team production automation demands them later. |
| D29 | 2026-07-08 | New repo visibility: **private until checkpoint α**, public when the full CLI pipeline demonstrably runs (end of M4) | Best-first-impression launch. If migrating (D26), old repo archival waits for α too — archiving earlier would remove graphify's only public home. |
| D30 | 2026-07-08 | Name: **SpecSeyal** (செயல் *seyal* = action; spec → action) | Babu's own candidate. GitHub: zero repos; npm: free — fully virgin namespace, verified 2026-07-08. |

## Open questions

| # | Question | Options | Current lean |
|---|---|---|---|
| Q1 | Council provider strategy | (a) multi-provider via API keys/OpenRouter — true diversity · (b) Claude-only Opus/Sonnet/Haiku subagents — no keys, cheaper, fits sessions | ✅ **Resolved → D12** |
| Q2 | Convergence rule details | Round limit (2?); who classifies suggestions as `blocking` — chairman or human? | ✅ **Resolved → D13** |
| Q3 | Defense deck format | markdown · HTML · pptx | ✅ **Resolved → D15** |
| Q4 | Naming the overall system | "SDD Orchestrator" is a placeholder | ✅ **Resolved → D30: SpecSeyal** |
| Q5 | MCP syncing rules granularity | Sync on every artifact write? Phase completion only? Batched? | ✅ **Resolved → D19** |
| Q6 | Model assignment heuristics | Graph fan-in/out, file count, task type weights — exact policy? | ✅ **Resolved → D18** (graph-scoring deferred; revisit with observability data) |
| Q7 | Setup wizard scope | Just init + graphify/spec-kit, or also agent library bootstrap + MCP registration? | ✅ **Resolved → D23** (full scope) |
| Q8 | Central manager hosting | claude.narenwebworks.in EC2 (t4g.large) vs elsewhere? Auth model for internal use? | ✅ **Resolved → D22** |
| Q9 | Illegible notebook items | (a) the scribbled word before "Assign/creating agents" on the Ideas page; (b) first sub-bullet under Setup wizard ("init with …?") | ✅ **Closed** — (a) strike-off, nothing meaningful; (b) "if needed" / superseded by D23's explicit wizard scope |
| Q10 | Central manager auth & multi-tenancy | Single-user token · team SSO · GitHub OAuth (OSS-friendly) | ✅ **Resolved → D20** |
| Q11 | "Self-evolving setup" concrete scope | Agent library only · + extension config · + wizard regenerating itself | ✅ **Resolved → D24** (library only, year one) |
| Q12 | A severe finding reopens a council-defended plan — what review does the patched plan get? | Delta council (focused single round) · full rerun · decision record + human gate only · severity-tiered | ✅ **Resolved → D14** |

## Idea parking lot

| # | Idea | Origin | Ripeness |
|---|---|---|---|
| I-1 | **Library flywheel**: generated agents that perform well get persisted into the specialist library with usage stats | Agent creator discussion | Ready to fold into `20-AGENT-CREATOR-SPEC.md` |
| I-2 | **Graph-driven complexity scoring** for model assignment (fan-in/out, file count as proxies) | Graphify already computes the graph | Needs Q6 |
| I-3 | **Testing agent v2**: actually run tests, not just produce the doc; feed failures back as remediation tasks | Notes: "for now, creates a testing doc" | Post-v1 |
| I-4 | **Git worktrees per implementation wave** — parallel subagents each get an isolated worktree, merged per wave | Some llm-council variants use worktrees per member | **Spike scheduled** in implementation plan Milestone 2 (D25) |
| I-5 | **Council reviews implementation too** — a post-implement council round on the completion report, not just the plan | Natural symmetry | Parked (council spec non-goal v1) |
| I-6 | **Non-technical deck doubles as stakeholder artifact** — reusable in work contexts (e.g., AI-First Delivery program demos) | Deck has technical/non-technical split anyway | Free byproduct |
| I-7 | **Open-source the orchestrator** — Agent SDK-native Spec Kit orchestration appears to be an unoccupied niche | Earlier research found no existing GUI orchestration layer on Spec Kit | **Promoted by D7** — OSS confirmed, simultaneous with work adoption. Remaining: licensing & packaging (Round 5/6) |
| I-8 | **Suggestion classification taxonomy** (`blocking`/`strong`/`consider`) could generalize to analyze/remediation findings too | Council spec §5 | Cheap consistency win — D11's severity routing could reuse it |
| I-9 | **Domain critics for work contexts** — e.g., a compliance/HIPAA critic auto-added to the council v2 roster for health-insurance repos; roster composition per repo/domain | Round 3 framing | Fits v2's prompt-config-only evolution |
| I-10 | **Central-library MCP** — an MCP server exposing the shared agent bench; repos pull/contribute specialists across devices and teams | Babu, Round 4 | Named future component; D17 preps for it via stable IDs |

## Session log

| Date | What happened |
|---|---|
| 2026-07-08 | Notebook pages transcribed & reconstructed into workflow. D1–D5 recorded. Doc set created (00, 10, 90). Council spec drafted to 0.1. |
| 2026-07-08 | **Brainstorm Round 1 (ideology):** D6–D8 recorded. Principles 6–9 added to doc 00 (resumability, observability, non-technical UX, self-evolving setup). Audience = personal → work + OSS simultaneously. Autonomy profiles introduced. Q10–Q11 opened. |
| 2026-07-08 | **Brainstorm Round 2 (workflow):** D9–D11 recorded. Workforce gate added to pipeline. Council gains graphify query tooling. Severity-based remediation routing. Q12 opened. |
| 2026-07-08 | **Brainstorm Round 3 (council):** D12–D15 recorded. Q1/Q2/Q3/Q12 all resolved. **Council spec promoted to 0.2 — buildable.** |
| 2026-07-08 | **Brainstorm Round 4 (tasks & agents):** D16–D18 recorded. Q6 resolved. Two-plane model policy (Sonnet workers / Opus-xhigh spine); role map pending confirmation. I-10 central-library MCP named. |
| 2026-07-08 | **Brainstorm Round 5 (platform):** D19–D22 recorded. Q5/Q8/Q10 resolved. Sync = phase events with artifacts + heartbeats. Token auth v1 → OAuth. GUI MVP = observe + approve. EC2 hosting. |
| 2026-07-08 | **Brainstorm Round 6 (edges):** D23–D25 recorded. Q7/Q11 resolved; Q4 assigned to Babu. D18 confirmed by default. **Brainstorm complete: 25 decisions, 10 of 12 questions closed.** Implementation plan created as doc 05. |
| 2026-07-08 | **Post-brainstorm:** D26 (new repo, monorepo default with graphify migration), D27 (MIT confirmed), D28 (subscription-only billing end to end — Agent SDK monthly credit covers M6+ programmatic sessions, no API keys). Plan doc updated. |
| 2026-07-08 | **Handoff:** CLAUDE.md seed + 95-M0-KICKOFF.md created (pre-flight checklist + paste-ready M0 prompt). Awaiting: working name, migration/public-repo default confirmations, Q9 disposition. |
| 2026-07-08 | **Final inputs closed:** Q9 closed (strike-off / superseded). D26 migration confirmed. D29 private-until-α. **D30: named SpecSeyal** (namespace verified clean). All 12 questions resolved, 30 decisions. Docs stamped. **Handoff complete — pre-flight is the only step left.** |

## How we work

1. New raw idea → add an **I** row here, one line, don't over-specify.
2. Idea gets discussed → gains options/lean → becomes a **Q**.
3. Q gets answered → becomes a **D**, and the relevant spec doc gets updated in the same session.
4. When a component accumulates 3+ related D/I items → it earns its own numbered spec doc.
