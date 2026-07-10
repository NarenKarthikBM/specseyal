# Agent Assignment — 003-workforce

> **By-hand bootstrap (grandfathered, S28).** `003` *builds* the assembler (`assemble.py`), the
> `/speckit-agent-assign` + `/speckit-workforce-approve` commands, and git-ext's `on-gate-approve.sh`
> generalization — none of which exist yet to assemble or bind `003` itself. So this roster is
> **hand-assembled** against **taxonomy v0** + the plan's **proposed seed library** (7 bases + 5 skills,
> plan § Seed Library — not yet on disk; built by T006/T007), and the gate below is **hand-written and
> grandfathered**: the FR-008 `gates.yml` workforce binding this feature designs **does not apply
> retroactively to the feature that designs it** — exactly as `002`'s council gate was left unbound
> (R1-S28, like M1's fast-forward). The last manual pass; the feature builds its replacement.
>
> **Inputs:** `categorization.md` (32 tasks) ⇐ `tasks.md @ d37a846` (S14). **Library snapshot (S18):**
> the proposed seed set — `agt_ai_agents · agt_devtools_cli · agt_security · agt_qa_automation ·
> agt_backend_service* · agt_data_persistence* · agt_generic` + `skl_orchestration · skl_shell_scripting ·
> skl_yaml_hooks · skl_installer_hygiene · skl_refactor_discipline`, all seed `@1.0` (*`provisional`). A
> real `assemble.py` run stamps a content-hash here once the library is on disk.
>
> **Gap-free:** this hand pass authored **no** skills (the skill-builder is what `003` builds and does
> not yet exist) — every injected skill is **`library`**, zero **`built`** → the roster is byte-reproducible
> per SC-005/FR-022.

## Workforce Gate — PENDING (awaiting human signature)

| Field | Value |
|---|---|
| reviewer | *pending — Naren Karthik B M* |
| decision | *pending* (`approved` \| `approved-with-notes` \| `rejected`) |
| reviewed | `tasks.md`, `categorization.md`, `assignment.md` (this roster) |

### Roster approved

> One row per assembled agent (base + its ≤3 injected skills, W1); each task in exactly one row. Model =
> Sonnet on every row (every base declares `model: sonnet`, D18). Skills marked **`library`** (present in
> the proposed seed set) — zero **`built`** (FR-022). Elevated grants = union of injected skills' grants
> (FR-013), `none` unless a row builds the `web_search`-declaring skill-builder (D60 — see ★).

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
| T001, T005, T011, T014 | `agt_devtools_cli` | Sonnet | *(none — base suffices)* | none |
| T002, T003, T004, T017, T019 | `agt_devtools_cli` | Sonnet | `skl_yaml_hooks@1.0` *(library)* | none |
| T008 | `agt_devtools_cli` | Sonnet | `skl_installer_hygiene@1.0`, `skl_shell_scripting@1.0`, `skl_yaml_hooks@1.0` *(library ×3 — cap 3, none dropped)* | none |
| T009 | `agt_devtools_cli` | Sonnet | `skl_installer_hygiene@1.0`, `skl_shell_scripting@1.0` *(library)* | none |
| T006, T007, T010, T015, T023, T030 | `agt_ai_agents` | Sonnet | *(none — base suffices)* | none |
| T012, T016, T027 | `agt_ai_agents` | Sonnet | `skl_orchestration@1.0` *(library)* | none |
| **T022** ★ | `agt_ai_agents` | Sonnet | *(none)* | **`web_search`** |
| **T025** ★ | `agt_ai_agents` | Sonnet | `skl_orchestration@1.0` *(library)* | **`web_search`** |
| T018 | `agt_security` | Sonnet | `skl_shell_scripting@1.0` *(library)* | none |
| T024 | `agt_security` | Sonnet | *(none — base suffices)* | none |
| T013, T021, T026, T028 | `agt_qa_automation` | Sonnet | `skl_shell_scripting@1.0` *(library)* | none |
| T020, T029 | `agt_qa_automation` | Sonnet | `skl_installer_hygiene@1.0`, `skl_shell_scripting@1.0` *(library)* | none |
| T032 | `agt_qa_automation` | Sonnet | *(none — base suffices)* | none |
| T031 | `agt_generic` ⚠ **empty lane** | Sonnet | *(none)* | none |

**★ The `web_search` grant — the system's FIRST elevated grant a human signs (D60).** Rows **T022** and
**T025** are the **builder path**: T022 authors `skill-builder-prompt.md`, which declares
`grants: [web_search]` in its skill-module frontmatter (A-2); T025 wires the `/speckit-agent-assign` gap
handoff that *dispatches* that builder. Per D60 the grant is **surfaced on the builder-path rows so this
gate is where it becomes visible and approvable** — approving this roster **is** approving the first
network reach in the system (D41). *Mechanics note for the reviewer:* the seed library is **100%
`grants: []`**, so under a strict FR-013 union every row would read `none`; `web_search` appears here
because **`003` introduces the `web_search`-declaring skill-builder** (T022) — it is a grant this feature
*creates*, surfaced at the moment of its creation, not one injected from an existing skill. The
runtime-trace side (T027) *records* `elevated_grants: ["web_search"]` when a builder dispatch searched
(D43) but does not itself hold the grant → `none`. The S17 `provenance.stale_risk` flag ships as a
complement (D60).

**⚠ Empty lane (FR-016):** **T031** (README, `docs × devtools-cli`) matches no base lane — the only
`docs`-accepting seed base is `agt_ai_agents` (`ai-agents`), so `(docs, devtools-cli)` falls to
`agt_generic` + this reported empty lane, **by design** (it earns the lane its first v0→v1 evidence,
S16). Not a silent fallback.

**Notes (for the reviewer):**
- **Cap check:** `general 0/32` ≤ `0.20 × 32 = 6` → PASS. Every lane evidence-backed; no escape-hatch use.
- **D48 guard — checked:** the three `prompt`-tagged tasks (T010 categorizer-prompt, T022 skill-builder-prompt, T030 deck-prep) are mechanically `docs` but implementation prompt-authoring, so each holds the Sonnet floor — all route to **`agt_ai_agents` (Sonnet)**, never a docs-exempt non-Sonnet base. No non-Sonnet base exists in the seed set (the guard's error branch is exercised only by the SC-006 synthetic fixture, T021/S03).
- **Bases exercised:** 5 of 7 — `agt_devtools_cli` (11 tasks), `agt_ai_agents` (11), `agt_qa_automation` (7), `agt_security` (2), `agt_generic` (1, empty lane). The two **`provisional`** bases (`agt_backend_service`, `agt_data_persistence`, S11) went **unexercised** — expected: `003` has no `data-model`/persistence work; booked as v0→v1 evidence.
- **`refactor-discipline`:** injected on **zero** rows — every task is `preserves_behavior: false` (a build, not a refactor). Correct.
- **Reproducibility:** gap-free (zero `built`); two hand passes over the same categorization + seed set yield this same roster (SC-005).

**Overrides:** *(pending — the human's, at signature)*
