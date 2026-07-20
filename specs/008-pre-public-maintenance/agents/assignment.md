# Agent Assignment — 008-pre-public-maintenance

> Format: `artifact-layout.md` §8 (D49, resolving I-12) + `data-model.md` §5. Written by
> `/speckit-agent-assign` — `assemble.py` (zero-AI, deterministic; `agent-library-schema.md` §3) plus a
> Sonnet `skill-builder` session per ∅-match gap (D2/D40.2) — then signed by `/speckit-workforce-approve`
> (S13). The signed `## Workforce Gate` decision is what unlocks `/speckit-implement-parallel`; the
> roster below it is a proposal until then.
>
> **Inputs:** `categorization.md` (18 tasks) ⇐ `tasks.md @ b13ee42` (S14 freshness
> binding — a stale SHA hard-warns and routes back to re-categorize rather than assembling against it).
> **Library snapshot (S18):** content-hash `4de25acff6710ad09782b9020d10da948037b82a6d0986832a97ff65c86cd73f` — the base+skill set on disk when
> this run started, stamped so SC-005 ("gap-free ⇒ byte-identical roster") is checkable in one line.
>
> **Write boundary within this one file (principle 1):** `assemble.py` writes everything from here down
> through the `### Roster approved` table — base/skill selection, the `library`/`built` marks (FR-022),
> the elevated-grant union (FR-013, total-ordered per S01), the empty-lane / dropped-skill notes
> (FR-016 / FR-011), and (v1) the gap-cluster notes (FR-006/SC-007, D66) and the grant-tripwire notice
> (D67). It never writes the gate timestamp or the `reviewer` / `decision` / `reviewed` / `Notes:` /
> `Overrides:` fields below — those five are **`/speckit-workforce-approve`'s alone** (S13), and hold the
> literal `[PENDING — …]` marker until a human signs (or, under `gates.workforce.mode: auto` — **valid
> standalone**, `profile-schema.md` P4 / D67 verdict 12, no longer only within `full_auto` — the assigner
> resolves them itself in the same write, **unless the grant tripwire below is ENGAGED**, which forces a
> human signature regardless of profile — FR-020/W4; the pending state shown here is the `human`-mode
> default).

## Workforce Gate — 2026-07-20T08:43:13Z

| Field | Value |
|---|---|
| reviewer | Naren Karthik B M |
| decision | `approved` |
| reviewed | `tasks.md`, `assignment.md` (roster) |

### Roster approved

> One row per assembled agent — a base plus its ≤3 injected skills (W1); every task appears in exactly
> one row's `Task(s)` cell. Each `Skills` entry is marked **`library`** (present in the library at this
> run's start) or **`built`** (authored by the skill builder during *this* run) — FR-022; a **gap-free**
> roster (SC-005) carries zero `built` marks. **`Elevated grants` is mandatory on every row and is never
> omitted** — write `none` when the union is empty (W2/FR-018); the core toolset (`Read, Write, Edit,
> Bash, Glob, Grep`) is assumed and never listed (D44). A task matching no `(type, specialization)` lane
> assembles onto `agt_generic` and its row carries an **empty-lane** annotation (FR-016) — never a silent
> fallback. Whenever the 3-skill cap trims a candidate, the drop is recorded below the table, never
> silently discarded (FR-011/SC-004).

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
| T001 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_baseline_capture@1.0.0` (built) | none |
| T002 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_shell_scripting@1.0.0` (library), `skl_decision_log_close_out@1.0.0` (built) | none |
| T003, T005 | `agt_devtools_cli` | Sonnet | `skl_shell_scripting@1.0.0` (library), `skl_installer_hygiene@1.0.0` (library) | none |
| T004 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_shell_scripting@1.0.0` (library), `skl_installer_hygiene@1.0.0` (library) | none |
| T006 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_extension_tree_scaffold@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T007 | `agt_qa_automation` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (library), `skl_docs_contract_authoring@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T008 | `agt_devtools_cli` | Sonnet | `skl_cli_command_wrapper@1.0.0` (library), `skl_docs_contract_authoring@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T009 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_docs_contract_authoring@1.0.0` (library), `skl_cli_command_wrapper@1.0.0` (library) | none |
| T010 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_cli_command_wrapper@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T011 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (library), `skl_shell_scripting@1.0.0` (library) | none |
| T012 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_installer_hygiene@1.0.0` (library), `skl_shell_scripting@1.0.0` (library) | none |
| T013 | `agt_ai_agents` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_dispatched_prompt_authoring@1.0.0` (library), `skl_cli_command_wrapper@1.0.0` (library) | none |
| T014 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_yaml_hooks@1.0.0` (library), `skl_baseline_capture@1.0.0` (built) | none |
| T015 | `agt_ai_agents` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_orchestration@1.0.0` (library), `skl_dispatched_prompt_authoring@1.0.0` (library) | none |
| T016 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T017 | `agt_generic` ⚠ **empty lane** | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_decision_log_close_out@1.0.0` (built) | none |
| T018 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_shell_scripting@1.0.0` (library), `skl_baseline_capture@1.0.0` (built) | none |

**Empty lane(s) (FR-016):**

- T017 — `docs × general` matched no base lane; assembled onto `agt_generic`.

**Dropped skills (cap=3, FR-011/SC-004):**

- T009 — 4 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_quickstart_integration_gate@1.0.0`.
- T011 — 5 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_baseline_capture@1.0.0`, `skl_quickstart_integration_gate@1.0.0`.
- T012 — 4 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_yaml_hooks@1.0.0`.
- T013 — 4 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_golden_fixture_discipline@1.0.0`.
- T014 — 6 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_cli_command_wrapper@1.0.0`, `skl_quickstart_integration_gate@1.0.0`, `skl_golden_fixture_discipline@1.0.0`.
- T015 — 4 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_cli_command_wrapper@1.0.0`.
- T018 — 4 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_decision_log_close_out@1.0.0`.

**Gap clusters (FR-006/SC-007, D66):** none — every task matched at least one skill (or carries no tags). Gap-free; nothing for the skill-builder to author.

**Grant tripwire (D67):** clear — no elevated grants in this roster. `gates.workforce.mode: auto` may auto-approve (profile-schema.md P4).

**Notes:** none.

**Overrides:** T017 empty-lane fallback (FR-016) — surfaced at the gate and approved as assembled; `docs × general` matches no base lane, so the task runs on `agt_generic`. No D-row opened.
