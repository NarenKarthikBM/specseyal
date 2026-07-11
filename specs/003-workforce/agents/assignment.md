# Agent Assignment — 003-workforce

> **By-hand bootstrap (grandfathered, S28) — the LAST hand-written workforce gate.** `003` *builds* the
> assembler (`assemble.py`), the `/speckit-agent-assign` + `/speckit-workforce-approve` commands, and
> git-ext's `on-gate-approve.sh` generalization — none of which exist yet to assemble or bind `003`
> itself. So this roster is **hand-assembled** against **taxonomy v0** + the plan's **proposed seed
> library** (7 bases + 5 skills, plan § Seed Library — not yet on disk; built by T006/T007), and the gate
> below is **hand-written and grandfathered**: the FR-008 `gates.yml` workforce binding this feature
> designs **does not apply retroactively to the feature that designs it** — as `002`'s council gate was
> left unbound (R1-S28, like M1's fast-forward). Once `003` ships, `/speckit-workforce-approve` writes
> every future workforce gate; **this is the last one written by hand.**
>
> **Inputs:** `categorization.md` (32 tasks) ⇐ `tasks.md @ d37a846` (S14). **Library snapshot (S18):**
> the proposed seed set — `agt_ai_agents · agt_devtools_cli · agt_security · agt_qa_automation ·
> agt_backend_service* · agt_data_persistence* · agt_generic` + `skl_orchestration · skl_shell_scripting ·
> skl_yaml_hooks · skl_installer_hygiene · skl_refactor_discipline`, all seed `@1.0` (*`provisional`). A
> real `assemble.py` run stamps a content-hash here once the library is on disk.
>
> **Gap-free:** this hand pass authored **no** skills (the skill-builder is what `003` builds and does
> not yet exist) — every injected skill is **`library`**, zero **`built`** → the roster is byte-reproducible
> per SC-005/FR-022. **Every row carries `elevated: none`** (the seed library is 100% `grants: []`, and no
> `003` build task's *work* reaches the network — see ★).

## Workforce Gate — 2026-07-11

| Field | Value |
|---|---|
| reviewer | Naren Karthik B M |
| decision | `approved-with-notes` |
| reviewed | `tasks.md`, `categorization.md`, `assignment.md` (this roster) |

### Roster approved

> One row per assembled agent (base + its ≤3 injected skills, W1); each task in exactly one row. Model =
> Sonnet on every row (every base declares `model: sonnet`, D18). Skills marked **`library`** (present in
> the proposed seed set) — zero **`built`** (FR-022). Elevated grants = union of injected skills' grants
> (FR-013) — **`none` on every row** (see ★).

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
| T001, T005, T011, T014 | `agt_devtools_cli` | Sonnet | *(none — base suffices)* | none |
| T002, T003, T004, T017, T019 | `agt_devtools_cli` | Sonnet | `skl_yaml_hooks@1.0` *(library)* | none |
| T008 | `agt_devtools_cli` | Sonnet | `skl_installer_hygiene@1.0`, `skl_shell_scripting@1.0`, `skl_yaml_hooks@1.0` *(library ×3 — cap 3, none dropped)* | none |
| T009 | `agt_devtools_cli` | Sonnet | `skl_installer_hygiene@1.0`, `skl_shell_scripting@1.0` *(library)* | none |
| T006, T007, T010, T015, **T022**, T023, T030 | `agt_ai_agents` | Sonnet | *(none — base suffices)* | none |
| T012, T016, **T025**, T027 | `agt_ai_agents` | Sonnet | `skl_orchestration@1.0` *(library)* | none |
| T018 | `agt_security` | Sonnet | `skl_shell_scripting@1.0` *(library)* | none |
| T024 | `agt_security` | Sonnet | *(none — base suffices)* | none |
| T013, T021, T026, T028 | `agt_qa_automation` | Sonnet | `skl_shell_scripting@1.0` *(library)* | none |
| T020, T029 | `agt_qa_automation` | Sonnet | `skl_installer_hygiene@1.0`, `skl_shell_scripting@1.0` *(library)* | none |
| T032 | `agt_qa_automation` | Sonnet | *(none — base suffices)* | none |
| T031 | `agt_generic` ⚠ **empty lane** | Sonnet | *(none)* | none |

**★ The `web_search` grant — corrected at the gate (D63; D60 stands).** An earlier draft of this roster
hand-attached `web_search` to the two **builder-path** rows — **T022** (authors `skill-builder-prompt.md`,
which *declares* `grants: [web_search]`) and **T025** (wires the `/speckit-agent-assign` gap handoff that
*dispatches* that builder). **The owner corrected this at the gate:** an A-2 grant derives **only** from a
skill declaration *injected into an assembly* (FR-013 — "nothing else grants anything"). Neither T022
(writes a prompt file) nor T025 (wires a handoff) injects a `web_search`-declaring skill, and neither
task's *work* touches the network → **both read `none`**, and they merge into their honest assemblies
(`agt_ai_agents` + none, and + `skl_orchestration`). **D60's authorization is untouched and stands:** the
skill-builder role *is* authorized to hold `web_search` (the declaration T022 authors). That grant reaches
a **roster** — and its **first human signature** — only at a **genuine builder dispatch**: a real gap
event on some future feature, or the **S08 integration test** that runs the real skill-builder on a gap
fixture. There, the builder's assembly injects the declaring module and the **A-2 union surfaces
`web_search` honestly** — the mechanism working, not a hand-attachment. **Capability authorization (D60)
and dispatch approval (a gate) are distinct acts** (D63).

**⚠ Empty lane (FR-016, by design):** **T031** (README, `docs × devtools-cli`) matches no base lane — the
only `docs`-accepting seed base is `agt_ai_agents` (`ai-agents`), so `(docs, devtools-cli)` falls to
`agt_generic` + this reported empty lane. Booked for the v0→v1 review (I-15).

**Notes (binding — the reviewer's):**
1. **Grant correction (→ D63).** `web_search` stripped from T022 and T025; both read `elevated: none`.
   Reasoning: A-2 grants derive from skill declarations in the assembly, and neither assembly declares
   any; neither task's work needs network. **D60 stands untouched** — the grant attaches to *builder
   dispatches* via the declaration T022 authors, and the first human-signed `web_search` occurs at the
   first genuine builder dispatch (a gap event or the S08 integration test), where the roster displays it
   through the A-2 union. Gates approve *dispatches* with the grants the *work* needs; capability
   authorization (D60) and dispatch approval are distinct acts.
2. **Empty-lane evidence (→ I-15).** Book `docs × devtools-cli` demand (T031) for the v0→v1 review —
   candidate: seed the lane or widen `agt_devtools_cli`'s accepted types to include `docs`. The
   `agt_generic` fallback + reporting behaved as designed.
3. **Provisional bases.** `agt_backend_service` / `agt_data_persistence` **stay `provisional`** —
   unexercised in `003` (no data-model work), correctly.
4. **No by-hand discipline this run.** `002`'s per-wave commit + gate-freshness machinery is **live** and
   governs Phase 4 — its first unassisted outing. If either hook misbehaves, that is a **`002` defect**:
   **stop and flag, don't compensate silently.**

**Overrides:** Note 1 — the reviewer **overrode** the proposed roster's `web_search` display on T022/T025
(→ `none`), recorded as **D63**. No other override.
